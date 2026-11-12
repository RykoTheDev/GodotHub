import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/features.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/restore_progress_modal.dart';
import 'package:godothub/modals/theme_presets_modal.dart';
import 'package:godothub/onboarding/feature_setup_picker.dart';
import 'package:godothub/onboarding/onboarding_view.dart';
import 'package:godothub/onboarding/welcome_intro.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/src/ui_transition.dart';
import 'package:godothub/state/news.dart';
import 'package:godothub/state/onboarding.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/titlebar/providers.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/toast_host.dart';
import 'package:godothub/ui/reusables/dir_list.dart';

import '../projects/project_actions_test.dart' as base;
import '../projects/projects_view_test.dart' show project;
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show FakeRunningSource, FakeWindow, baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
late List<AppSettings> saved;
late List<String> calls;

Workspace workspace(String id, String name) => Workspace(id: id, name: name, icon: 'folder', color: '#457ff2', createdAt: '2026-01-01');

AppSettings onboardingSettings({List<String> projectDirs = const [], List<String> versionDirs = const []}) => copySettings(
  baseSettings,
  setupComplete: false,
  projectScanDirs: projectDirs,
  versionScanDirs: versionDirs,
  templateScanDir: () => null,
);

class _NoNews extends NewsBadgeNotifier {
  @override
  int build() => 0;
}

void backend({
  List<Workspace>? workspaces,
  List<DiscoveredProject> recent = const [],
  List<DiscoveredInstall> installs = const [],
  List<Project> projects = const [],
  String? username = 'Ryko',
}) {
  final list = workspaces ?? [workspace('w1', 'Main')];
  rust
    ..on('crateApiChangelogListChangelogEntries', () async => <ChangelogEntry>[])
    ..on('crateApiWorkspaceListWorkspaces', () async => WorkspacesState(workspaces: list, activeId: list.first.id))
    ..on('crateApiWorkspaceListWorkspaceScanDirs', () async => const <WorkspaceScanDirs>[])
    ..on('crateApiProjectsListProjects', () async => projects)
    ..on('crateApiCategoriesListCategories', () async => <Category>[])
    ..on('crateApiGodotVersionsListInstalledGodotVersions', () async => <InstalledGodotVersion>[])
    ..on('crateApiGodotVersionsFetchAvailableGodotVersions', ({String? source}) async => <GodotRelease>[])
    ..on('crateApiCurrentVersionGetCurrentVersion', () async => null)
    ..on('crateApiCurrentVersionListVersionAliases', () async => const VersionAliases(aliases: [], aliasesDir: 'C:/aliases'))
    ..on(
      'crateApiExportTemplatesGetExportTemplatesState',
      () async => const ExportTemplatesState(defaultDir: 'C:/t', versions: [], orphans: []),
    )
    ..on('crateApiMiseMiseRefreshStatus', () async => const MiseStatus(available: false))
    ..on('crateApiAppGetOsUsername', () async => username)
    ..on('crateApiGitAuthGetGitAuthState', () async => const GitAuthState(pats: []))
    ..on('crateApiDiscoveryScanGodotRecentProjects', () async => recent)
    ..on('crateApiDiscoveryDetectGodotInstalls', () async => installs)
    ..on('crateApiScanScanForProjects', ({required List<String> dirs, required int depth}) async {
      calls.add('scan-projects:${dirs.join(',')}');
      return <Project>[];
    })
    ..on('crateApiScanScanForVersions', ({required List<String> dirs, required int depth}) async {
      calls.add('scan-versions:${dirs.join(',')}');
      return <InstalledGodotVersion>[];
    })
    ..on('crateApiWatcherRestartWatchers', () async => calls.add('watchers'))
    ..on('crateApiSettingsRefreshTrayMenu', () async {});
}

Future<void> pumpOnboarding(WidgetTester tester, AppSettings settings, {Size size = const Size(1400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeSettings(
          () => settings,
          onSave: (next) {
            saved.add(next);
            return next;
          },
        ),
        titleBarWindowProvider.overrideWithValue(FakeWindow()),
        runningProjectsSourceProvider.overrideWithValue(FakeRunningSource().source),
        newsBadgeProvider.overrideWith(_NoNews.new),
      ],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: GhToastHost(
            child: Consumer(
              builder: (context, ref, _) {
                final current = ref.watch(settingsProvider).value;
                if (current == null) return const SizedBox.expand();
                return OnboardingView(settings: current, isMac: false);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await base.settle(tester);
}

Future<void> diveIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('welcome-dive-in')));
  await base.settle(tester, 20);
}

Finder stepButton(String id) => find.byKey(ValueKey('step:$id'));

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
  await base.settle(tester, 4);
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    GhUiTransition.reset();
    saved = [];
    calls = [];
  });

  testWidgets('the welcome intro greets the user and dives into the wizard', (tester) async {
    backend();
    await pumpOnboarding(tester, onboardingSettings());
    expect(find.byType(WelcomeIntro), findsOneWidget);
    expect(find.text(ghTr('onboarding:welcome_to_name', args: {'name': 'Ryko'}).toUpperCase()), findsOneWidget);
    await diveIn(tester);
    expect(find.byType(WelcomeIntro), findsNothing);
    expect(stepButton('workspace'), findsOneWidget);
    final total = onboardingSteps(onboardingSettings(), firstRun: true).length;
    expect(find.text(ghTr('onboarding:step_of', args: {'current': 1, 'total': total})), findsOneWidget);
    expect(find.text(ghTr('onboarding:first_workspace_title')), findsOneWidget);
  });

  testWidgets('steps advance and go back, and the setup step changes features', (tester) async {
    backend(workspaces: [workspace('w1', 'Main'), workspace('w2', 'Work')]);
    await pumpOnboarding(tester, onboardingSettings());
    expect(find.byType(WelcomeIntro), findsNothing);
    expect(stepButton('workspace'), findsNothing);
    expect(find.text(ghTr('onboarding:basics_title')), findsOneWidget);
    await next(tester);
    expect(find.byType(FeatureSetupPicker), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile:minimal')));
    await base.settle(tester, 3);
    expect(stepButton('templates'), findsNothing);
    expect(stepButton('categories'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('profile:complete')));
    await base.settle(tester, 3);
    expect(stepButton('templates'), findsOneWidget);
    await tester.tap(find.text(ghTr('settings:setup_profile_custom')));
    await base.settle(tester, 3);
    expect(find.text(GhFeatureId.vault.label()), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('onboarding-back')));
    await base.settle(tester, 3);
    expect(find.text(ghTr('onboarding:basics_title')), findsOneWidget);
  });

  testWidgets('skip setup on the first step saves only the language with setup complete', (tester) async {
    backend(workspaces: [workspace('w1', 'Main'), workspace('w2', 'Work')]);
    await pumpOnboarding(tester, onboardingSettings(projectDirs: ['C:/games']));
    await tester.tap(find.text(ghTr('skip_setup')));
    await base.settle(tester);
    expect(saved, hasLength(1));
    expect(saved.single.setupComplete, isTrue);
    expect(calls, containsAll(['scan-projects:C:/games', 'watchers']));
  });

  testWidgets('recent projects and detected installs can be imported', (tester) async {
    final imported = <String>[];
    backend(
      workspaces: [workspace('w1', 'Main'), workspace('w2', 'Work')],
      recent: const [DiscoveredProject(path: 'C:/games/jam', name: 'Jam', favorite: true, engine: '4.3')],
      installs: const [DiscoveredInstall(path: 'C:/godot/4.3', name: 'Godot 4.3', source: 'Steam', version: '4.3')],
    );
    rust
      ..on('crateApiProjectsImportProject', ({required String path, required String godotVersion, String? category}) async {
        imported.add(path);
        return project('jam', 'Jam');
      })
      ..on('crateApiDiscoveryImportDetectedInstall', ({required String path}) async {
        imported.add(path);
        return InstalledGodotVersion(
          tag: '4.3-stable',
          version: '4.3',
          executablePath: '$path/godot.exe',
          isMono: false,
          installedAt: '2026-01-01T00:00:00Z',
          supportsConsole: true,
        );
      });
    await pumpOnboarding(tester, onboardingSettings());
    await tester.tap(stepButton('projects'));
    await base.settle(tester, 4);
    expect(find.text('Jam'), findsOneWidget);
    expect(find.text(ghTr('onboarding:discovery_favorite')), findsOneWidget);
    await tester.tap(find.text(ghTr('onboarding:discovery_add_selected_count', count: 1)));
    await base.settle(tester, 4);
    expect(imported, ['C:/games/jam']);
    expect(find.text(ghTr('onboarding:discovery_add_selected')), findsOneWidget);
    await tester.tap(stepButton('versions'));
    await base.settle(tester, 4);
    expect(find.text('Steam'), findsOneWidget);
    await tester.tap(find.text(ghTr('onboarding:discovery_add_selected_count', count: 1)));
    await base.settle(tester, 4);
    expect(imported, ['C:/games/jam', 'C:/godot/4.3']);
    await base.drainToasts(tester);
  });

  testWidgets('the appearance step opens the presets modal and the summary reflects choices', (tester) async {
    backend(workspaces: [workspace('w1', 'Main'), workspace('w2', 'Work')]);
    await pumpOnboarding(tester, onboardingSettings(projectDirs: ['C:/games']));
    await tester.tap(stepButton('appearance'));
    await base.settle(tester, 4);
    await tester.tap(find.text(ghTr('settings:preset_dark_group')));
    await base.settle(tester, 6);
    expect(find.byType(ThemePresetsModal), findsOneWidget);
    final preset = darkThemePresets[1];
    await tester.tap(find.byKey(ValueKey(preset.id)));
    await base.settle(tester, 6);
    expect(find.byType(ThemePresetsModal), findsNothing);
    await tester.tap(find.text(ghTr('settings:theme_preset_custom')));
    await base.settle(tester, 4);
    await tester.tap(find.byKey(const ValueKey('theme-mode:light')));
    await base.settle(tester, 4);
    await tester.tap(stepButton('finish'));
    await base.settle(tester, 4);
    expect(find.text('${ghTr('settings:light')} · ${ghTr('settings:theme_preset_custom')}'), findsOneWidget);
    expect(find.text(ghTr('onboarding:project_folders')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('get started scans, celebrates and saves the draft', (tester) async {
    backend(workspaces: [workspace('w1', 'Main'), workspace('w2', 'Work')], projects: [project('a', 'Alpha'), project('b', 'Beta')]);
    await pumpOnboarding(tester, onboardingSettings(versionDirs: ['C:/godot']));
    await tester.tap(stepButton('finish'));
    await base.settle(tester, 4);
    await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
    await base.settle(tester, 6);
    expect(find.text(ghTr('onboarding:found_title')), findsOneWidget);
    expect(find.text('Alpha'), findsWidgets);
    await base.settle(tester, 60);
    expect(saved, hasLength(1));
    expect(saved.single.setupComplete, isTrue);
    expect(saved.single.versionScanDirs, ['C:/godot']);
    expect(calls, containsAll(['scan-versions:C:/godot', 'watchers']));
    expect(GhUiTransition.consumeShellIntroHandOff(), isTrue);
  });

  testWidgets('the categories step adds starter and custom categories', (tester) async {
    backend(workspaces: [workspace('w1', 'Main'), workspace('w2', 'Work')]);
    final categories = <Category>[];
    rust
      ..on('crateApiCategoriesListCategories', () async => categories)
      ..on('crateApiCategoriesCreateCategory', ({required String name, String? color}) async {
        final created = Category(id: name, name: name, sortOrder: categories.length, color: color ?? '', hidden: false, folders: const []);
        categories.add(created);
        return created;
      });
    await pumpOnboarding(tester, copySettings(onboardingSettings(), categoriesEnabled: true));
    await tester.tap(stepButton('categories'));
    await base.settle(tester, 4);
    final prototypes = ghTr('onboarding:prototypes');
    await tester.tap(find.text(prototypes));
    await base.settle(tester, 4);
    expect(categories.map((c) => c.name), [prototypes]);
    expect(categories.single.color, starterCategoryColors['Prototypes']);
    await tester.enterText(find.byType(EditableText), 'Tools');
    await base.settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('onboarding-add-category')));
    await base.settle(tester, 4);
    expect(categories.map((c) => c.name), [prototypes, 'Tools']);
    expect(find.text(ghTr('onboarding_your_categories').toUpperCase()), findsOneWidget);
    expect(find.text('Tools'), findsWidgets);
  });

  testWidgets('dir list adds, marks default and removes folders', (tester) async {
    var dirs = <String>['C:/a'];
    String? fallback;
    String? picked = 'C:/b';
    await base.pumpHost(
      tester,
      body: StatefulBuilder(
        builder: (context, setState) => GhDirList(
          dirs: dirs,
          onChanged: (next) => setState(() => dirs = next),
          emptyHint: 'hint',
          defaultDir: fallback,
          onSetDefault: (dir) => setState(() => fallback = dir),
          pickFolder: () async => picked,
        ),
      ),
    );
    await tester.tap(find.text(ghTr('add_folder')));
    await base.settle(tester, 2);
    expect(dirs, ['C:/a', 'C:/b']);
    await tester.tap(find.text(ghTr('make_this_default', args: {'label': ghTr('default_folder').toLowerCase()})).first);
    await base.settle(tester, 2);
    expect(fallback, 'C:/a');
    await tester.tap(find.bySemanticsLabel(ghTr('remove_folder')).first);
    await base.settle(tester, 2);
    expect(dirs, ['C:/b']);
    expect(fallback, isNull);
    picked = null;
    await tester.tap(find.text(ghTr('add_folder')));
    await base.settle(tester, 2);
    expect(dirs, ['C:/b']);
  });

  testWidgets('dir list shows an error toast when the picker is unavailable', (tester) async {
    await base.pumpHost(
      tester,
      body: GhDirList(
        dirs: const [],
        onChanged: (_) {},
        emptyHint: 'Pick a folder',
        pickFolder: () async => throw UnsupportedError('nope'),
      ),
    );
    expect(find.text('Pick a folder'), findsOneWidget);
    await tester.tap(find.text(ghTr('add_folder')));
    await base.settle(tester, 2);
    expect(find.textContaining('nope'), findsOneWidget);
    await base.drainToasts(tester);
  });

  testWidgets('restore modal previews the backup, applies it and relaunches', (tester) async {
    var relaunched = 0;
    rust
      ..on(
        'crateApiSyncGistSyncFetchBackup',
        () async => RestorePreview(
          workspaceCount: BigInt.two,
          workspaceNames: const ['Main', 'Work'],
          projectCount: BigInt.from(5),
          categoryCount: BigInt.one,
          templateCount: BigInt.zero,
          hasTimeStats: true,
          todoCount: BigInt.from(3),
          versionScanDirs: const [],
          projectScanDirs: const ['C:/games'],
        ),
      )
      ..on('crateApiSyncGistSyncPull', () async => baseSettings);
    await base.openModal(tester, (close) => RestoreProgressModal(onClose: close, relaunch: () async => relaunched++));
    expect(find.text('Work'), findsOneWidget);
    expect(find.text(ghTr('settings:restore_modal_todos', count: 3)), findsOneWidget);
    await tester.tap(find.text(ghTr('settings:restore_modal_apply_btn')));
    await base.settle(tester, 4);

    expect(find.text(ghTr('settings:restore_modal_done_title').toUpperCase()), findsOneWidget);
    await base.settle(tester, 10);
    expect(relaunched, 1);
  });

  testWidgets('restore modal shows errors and retries', (tester) async {
    var attempts = 0;
    rust.on('crateApiSyncGistSyncFetchBackup', () async {
      attempts++;
      throw StateError('no gist');
    });
    await base.openModal(tester, (close) => RestoreProgressModal(onClose: close));
    expect(find.textContaining('no gist'), findsOneWidget);
    await tester.tap(find.text(ghTr('retry')));
    await base.settle(tester, 4);
    expect(attempts, 2);
  });
}
