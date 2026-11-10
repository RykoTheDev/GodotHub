import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/design/palette.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/categories.dart';
import 'package:godothub/state/discord_rpc.dart';
import 'package:godothub/state/news.dart';
import 'package:godothub/state/onboarding.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/workspaces.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../ui/i18n_setup.dart';

Workspace workspace(String id) => Workspace(id: id, name: id, icon: 'folder', color: '#fff', createdAt: '2026-01-01');

class FakeCategories extends CategoriesNotifier {
  final created = <(String, String?)>[];
  List<Category> list = [];

  @override
  Future<List<Category>> fetch() async => list;

  @override
  void setup() {}

  @override
  Future<Category> create(String name, [String? color]) async {
    created.add((name, color));
    final category = Category(id: name, name: name, sortOrder: 0, color: color ?? '', hidden: false, folders: const []);
    list = [...list, category];
    setData((_) => list);
    return category;
  }
}

void main() {
  late FakeRustApi rust;
  late List<AppSettings> saved;
  late List<String> calls;
  late FakeCategories categories;

  setUp(() {
    setUpTestI18n();
    rust = installFakeRust();
    saved = [];
    calls = [];
    categories = FakeCategories();
    rust.on('crateApiWorkspaceListWorkspaceScanDirs', () async => const [
      WorkspaceScanDirs(workspaceId: 'w1', workspaceName: 'Main', projectScanDirs: ['/p/a'], versionScanDirs: ['/v'], templateScanDir: '/t'),
      WorkspaceScanDirs(workspaceId: 'w2', workspaceName: 'Work', projectScanDirs: ['/p/b', '/p/c'], versionScanDirs: ['/v'], templateScanDir: '/t'),
      WorkspaceScanDirs(workspaceId: 'w3', workspaceName: 'Old', projectScanDirs: ['/p/b'], versionScanDirs: ['/v2'], templateScanDir: null),
    ]);
    rust.on('crateApiScanScanForProjects', ({required List<String> dirs, required int depth}) async {
      calls.add('projects ${dirs.join(',')} $depth');
      return <Project>[];
    });
    rust.on('crateApiScanScanForVersions', ({required List<String> dirs, required int depth}) async {
      calls.add('versions ${dirs.join(',')} $depth');
      return <InstalledGodotVersion>[];
    });
    rust.on('crateApiTemplatesSyncTemplatesWithScanDir', () async {
      calls.add('templates');
      throw StateError('ignored');
    });
    rust.on('crateApiWatcherRestartWatchers', () async => calls.add('watchers'));
  });

  Future<ProviderContainer> start({List<Workspace>? workspaces, AppSettings? settings}) async {
    final list = workspaces ?? [workspace('w1')];
    rust.on('crateApiWorkspaceListWorkspaces', () async => WorkspacesState(workspaces: list, activeId: 'w1'));
    final c = ProviderContainer(
      overrides: [
        fakeSettings(() => settings ?? defaultSettings, onSave: (next) {
          saved.add(next);
          return next;
        }),
        categoriesProvider.overrideWith(() => categories),
      ],
    );
    addTearDown(c.dispose);
    c.listen(workspacesProvider, (_, _) {});
    c.listen(categoriesProvider, (_, _) {});
    await pumpEventQueue();
    await c.read(settingsProvider.future);
    c.listen(onboardingProvider, (_, _) {});
    await pumpEventQueue();
    return c;
  }

  test('steps depend on first run and the enabled features', () async {
    var c = await start();
    var state = c.read(onboardingProvider);
    expect(state.steps.map((s) => s.id), OnboardingStepId.values);
    expect(state.step.id, OnboardingStepId.workspace);
    expect(onboardingStepLabel(OnboardingStepId.appearance), t.settings.appearance);
    expect(onboardingStepLabel(OnboardingStepId.categories), t.common.categories);

    c.read(onboardingProvider.notifier).setDraft(
      (d) => copySettings(d, disabledFeatures: const ['templates'], categoriesEnabled: false),
    );
    expect(c.read(onboardingProvider).steps.map((s) => s.id), isNot(contains(OnboardingStepId.templates)));
    expect(c.read(onboardingProvider).steps.map((s) => s.id), isNot(contains(OnboardingStepId.categories)));

    c = await start(workspaces: [workspace('w1'), workspace('w2')]);
    state = c.read(onboardingProvider);
    expect(state.firstRun, isFalse);
    expect(state.steps.first.id, OnboardingStepId.welcome);
    expect(state.step.id, OnboardingStepId.welcome);
  });

  test('navigation clamps to the visible steps', () async {
    final c = await start();
    final onboarding = c.read(onboardingProvider.notifier);
    onboarding.goBack();
    expect(c.read(onboardingProvider).stepIndex, 0);
    onboarding.goNext();
    onboarding.goNext();
    expect(c.read(onboardingProvider).step.id, OnboardingStepId.setup);
    onboarding.jumpTo(99);
    expect(c.read(onboardingProvider).step.id, OnboardingStepId.finish);
  });

  test('suggestions come from other workspaces, deduped, and pending templates skip the draft dir', () async {
    final c = await start();
    final state = c.read(onboardingProvider);
    expect(state.projectSuggestions, const [PathSuggestion('/p/b', 'Work'), PathSuggestion('/p/c', 'Work')]);
    expect(state.versionSuggestions, const [PathSuggestion('/v', 'Work'), PathSuggestion('/v2', 'Old')]);
    expect(state.pendingTemplateSuggestions, const [PathSuggestion('/t', 'Work')]);
    c.read(onboardingProvider.notifier).setDraft((d) => copySettings(d, templateScanDir: () => '/t'));
    expect(c.read(onboardingProvider).pendingTemplateSuggestions, isEmpty);
  });

  test('scan progress events are tracked and the view and discord draft are announced', () async {
    final views = <Object?>[];
    AppSignals.on(viewChangedSignal).listen((s) => views.add(s.detail));
    final c = await start();
    expect(views, ['onboarding']);
    expect(c.read(discordRpcDraftProvider), c.read(onboardingProvider).draft);

    rust.emit(fakeEvent(AppEventKind.projectScanProgress, scanProgress: const ScanProgress(current: 1, total: 4)));
    rust.emit(fakeEvent(AppEventKind.versionScanProgress, scanProgress: const ScanProgress(current: 2, total: 2)));
    await pumpEventQueue();
    expect(c.read(onboardingProvider).projectScan, const ScanProgress(current: 1, total: 4));
    expect(c.read(onboardingProvider).versionScan, const ScanProgress(current: 2, total: 2));

    c.read(onboardingProvider.notifier).setDraft((d) => copySettings(d, discordRpcEnabled: false));
    expect(c.read(discordRpcDraftProvider)?.discordRpcEnabled, isFalse);
  });

  test('theme setters update the draft and the live preview', () async {
    final c = await start(settings: copySettings(defaultSettings, themeMode: 'dark', backgroundColor: '#101010'));
    final onboarding = c.read(onboardingProvider.notifier);
    expect(c.read(themePreviewProvider), isNull);

    final preset = themePresets.firstWhere((p) => p.mode == GhThemeMode.light);
    onboarding.selectPreset(preset.id);
    var draft = c.read(onboardingProvider).draft;
    expect(draft.themePreset, preset.id);
    expect(draft.themeMode, 'light');
    expect(c.read(onboardingProvider).presetActive, isTrue);
    expect(c.read(themePreviewProvider), draft);

    onboarding.selectPreset('custom');
    draft = c.read(onboardingProvider).draft;
    expect(draft.themePreset, 'custom');
    expect(draft.accentColor, defaultAccent);
    expect(draft.backgroundColor, defaultBackgroundLight);

    onboarding.setThemeMode('dark');
    expect(c.read(onboardingProvider).draft.backgroundColor, defaultBackground);
    onboarding.setBackgroundColor('#202020');
    onboarding.setThemeMode('dark');
    expect(c.read(onboardingProvider).draft.backgroundColor, '#202020');
    onboarding.setAccentColor('#ff0000');
    onboarding.setCornerRadius(4);
    draft = c.read(onboardingProvider).draft;
    expect(draft.accentColor, '#ff0000');
    expect(draft.cornerRadius, 4);
    expect(c.read(themePreviewProvider), draft);
  });

  test('starter and custom categories are created once', () async {
    final c = await start();
    final onboarding = c.read(onboardingProvider.notifier);
    await onboarding.addStarterCategory('In Progress');
    await onboarding.addStarterCategory('In Progress');
    expect(categories.created, [(t.onboarding.in_progress, categoryColors[0])]);
    expect(onboarding.isStarterCategoryAdded('In Progress'), isTrue);
    expect(onboarding.isStarterCategoryAdded('Finished'), isFalse);

    onboarding.setCategoryDraft('   ');
    await onboarding.addCustomCategory();
    onboarding.setCategoryDraft(' Jam ');
    onboarding.setCategoryColor(categoryColors[4]);
    await onboarding.addCustomCategory();
    expect(categories.created.last, ('Jam', categoryColors[4]));
    expect(c.read(onboardingProvider).categoryDraft, '');
    expect(c.read(onboardingProvider).categoryColor, categoryColors.first);
    expect(c.read(onboardingProvider).categoryBusy, isFalse);
  });

  test('finishing scans the draft dirs, saves setup_complete and restarts watchers', () async {
    final c = await start();
    final onboarding = c.read(onboardingProvider.notifier);
    onboarding.setDraft(
      (d) => copySettings(d, projectScanDirs: const ['/p'], versionScanDirs: const ['/v'], templateScanDir: () => '/t', scanDepth: 3),
    );
    onboarding.setAccentColor('#00ff00');
    final order = <String>[];
    await onboarding.finish(false, beforeComplete: () async => order.add('before'), afterComplete: () async => order.add('after'));
    expect(calls, ['projects /p 3', 'versions /v 3', 'templates', 'watchers']);
    expect(order, ['before', 'after']);
    expect(saved.single.setupComplete, isTrue);
    expect(saved.single.accentColor, '#00ff00');
    expect(c.read(onboardingProvider).finishing, isFalse);
    expect(c.read(themePreviewProvider), isNull);
  });

  test('skipping keeps the saved settings except the language', () async {
    final c = await start();
    final onboarding = c.read(onboardingProvider.notifier);
    onboarding.setDraft((d) => copySettings(d, language: 'fr-FR', projectScanDirs: const ['/ignored'], accentColor: '#123456'));
    var before = 0;
    await onboarding.finish(true, beforeComplete: () async => before++);
    expect(before, 0);
    expect(calls, ['watchers']);
    expect(saved.single.language, 'fr-FR');
    expect(saved.single.accentColor, defaultSettings.accentColor);
    expect(saved.single.setupComplete, isTrue);
    expect(listEquals(saved.single.projectScanDirs, defaultSettings.projectScanDirs), isTrue);
  });

  test('disposing clears the discord draft and theme preview', () async {
    final c = await start();
    c.read(onboardingProvider.notifier).setCornerRadius(3);
    expect(c.read(themePreviewProvider), isNotNull);
    final keep = c.listen(themePreviewProvider, (_, _) {});
    addTearDown(keep.close);
    c.invalidate(onboardingProvider);
    await pumpEventQueue();
    c.read(onboardingProvider);
    await pumpEventQueue();
    expect(c.read(themePreviewProvider), isNull);
    expect(c.read(discordRpcDraftProvider), c.read(onboardingProvider).draft);
  });
}
