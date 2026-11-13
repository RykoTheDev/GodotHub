import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/debug_mode.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/contributor_prs_modal.dart';
import 'package:godothub/settings/categories/credits_settings.dart';
import 'package:godothub/settings/categories/debug_settings.dart';
import 'package:godothub/settings/categories/experimental_settings.dart';
import 'package:godothub/src/rust/api/app.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/app_version.dart';
import 'package:godothub/state/contributors.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/state/update_available.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/toast.dart';
import 'package:godothub/ui/feedback/toast_host.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
final opened = <String>[];
final saved = <AppSettings>[];

Future<void> pumpBody(WidgetTester tester, Widget body, {AppSettings? settings, List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeSettings(
          () => settings ?? copySettings(baseSettings, setupComplete: true),
          onSave: (next) {
            saved.add(next);
            return next;
          },
        ),
        appVersionLoaderProvider.overrideWithValue(() async => '2.0.0'),
        contributorsFetcherProvider.overrideWithValue(
          () async => const [
            Contributor(login: 'RykoTheDev', avatarUrl: '', contributions: 90),
            Contributor(login: 'alice', avatarUrl: '', contributions: 5),
            Contributor(login: 'bob', avatarUrl: '', contributions: 2),
          ],
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: GhToastHost(child: SingleChildScrollView(child: body)),
        ),
      ),
    ),
  );
  await base.settle(tester, 4);
}

final _toastLog = <String>[];

List<String> toastTexts(WidgetTester tester) => List.of(_toastLog);

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    debugResetDebugMode();
    opened.clear();
    saved.clear();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
    _toastLog.clear();
    ghToasts.clear();
    final seen = <int>{};
    final unsubscribe = ghToasts.subscribe((toasts) {
      for (final t in toasts) {
        if (seen.add(t.id)) _toastLog.add(t.message);
      }
    });
    addTearDown(unsubscribe);
  });
  tearDown(() {
    OpenerApi.debugOpenUrl = null;
    DebugSettings.debugRelaunch = null;
  });

  testWidgets('experimental toggles are translated and save their settings', (tester) async {
    await pumpBody(tester, const ExperimentalSettings());
    expect(find.text(ghTr('settings:customize_view_label')), findsOneWidget);
    expect(find.text(ghTr('settings:project_todos_label')), findsOneWidget);
    final toggles = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'GhToggle');
    expect(toggles, findsNWidgets(2));
    await tester.tap(toggles.first);
    await base.settle(tester, 3);
    expect(saved.last.customizeViewEnabled, !baseSettings.customizeViewEnabled);
    await tester.tap(toggles.last);
    await base.settle(tester, 3);
    expect(saved.last.projectTodosEnabled, !baseSettings.projectTodosEnabled);
  });

  testWidgets('credits shows the developer, license and contributors and opens their PRs', (tester) async {
    await pumpBody(tester, const CreditsSettings());
    expect(find.text(ghTr('settings:credits')), findsOneWidget);
    expect(find.text('RykoTheDev'), findsOneWidget);
    expect(find.text(creditsLicense), findsOneWidget);
    expect(find.text(creditsBuiltWith), findsOneWidget);
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.text('RykoTheDev'));
    await base.settle(tester, 2);
    expect(opened, [creditsDeveloperUrl]);
    await tester.tap(find.text('alice'));
    await base.settle(tester);
    expect(find.byType(ContributorPrsModal), findsOneWidget);
    expect(tester.widget<ContributorPrsModal>(find.byType(ContributorPrsModal)).login, 'alice');
  });

  testWidgets('debug tab is English and runs its tools', (tester) async {
    setDebugUnlocked(true);
    final relaunched = <String>[];
    DebugSettings.debugRelaunch = () async => relaunched.add('relaunch');
    final calls = <String>[];
    rust
      ..on('crateApiWatcherRestartWatchers', () async => calls.add('watchers'))
      ..on('crateApiSettingsResetAppData', () async => calls.add('reset'));
    final signals = <String>[];
    final sub = AppSignals.all.listen((s) => signals.add(s.name));
    addTearDown(sub.cancel);
    await pumpBody(tester, const DebugSettings(channel: 'stable'));
    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('Danger zone'), findsOneWidget);
    expect(find.text('Re-import from GodotHub'), findsNothing);

    await tester.tap(find.text('Success'));
    await tester.tap(find.text('Info'));
    await tester.tap(find.text('Error'));
    await base.settle(tester, 2);
    expect(toastTexts(tester), containsAll(['This is a success toast', 'This is an info toast', 'This is an error toast']));

    await tester.tap(find.text('Clear'));
    await tester.tap(find.text('Restart').first);
    await base.settle(tester, 3);
    expect(calls, ['watchers']);
    expect(toastTexts(tester), containsAll(['Project icon and name cache cleared', 'File watchers restarted']));

    ghToasts.clear();

    await tester.pump();

    await tester.ensureVisible(find.text('Show').last);
    await tester.tap(find.text('Show').last);
    await base.settle(tester, 2);
    expect(signals, contains(showAnnouncementSignal));

    ghToasts.clear();

    await tester.pump();

    await tester.ensureVisible(find.text('Open'));
    await tester.tap(find.text('Open'));
    await base.settle(tester, 3);
    expect(saved.last.setupComplete, isFalse);

    ghToasts.clear();

    await tester.pump();

    await tester.ensureVisible(find.text('Wipe'));
    await tester.tap(find.text('Wipe'));
    await base.settle(tester, 2);
    await tester.tap(find.text('Cancel'));
    await base.settle(tester, 2);
    expect(find.text('Confirm wipe'), findsNothing);
    ghToasts.clear();
    await tester.pump();
    await tester.tap(find.text('Wipe'));
    await base.settle(tester, 2);
    await tester.tap(find.text('Confirm wipe'));
    await base.settle(tester, 3);
    expect(calls, ['watchers', 'reset']);
    expect(relaunched, ['relaunch']);

    ghToasts.clear();

    await tester.pump();

    await tester.ensureVisible(find.text('Hide'));
    await tester.tap(find.text('Hide'));
    await base.settle(tester, 2);
    expect(isDebugUnlocked, isFalse);
    await base.drainToasts(tester);
  });

  testWidgets('debug updater tools open the preview and fake the update badge', (tester) async {
    setDebugUnlocked(true);
    final signals = <String>[];
    final sub = AppSignals.all.listen((s) => signals.add(s.name));
    addTearDown(sub.cancel);
    late WidgetRef widgetRef;
    await pumpBody(
      tester,
      Consumer(
        builder: (context, ref, _) {
          widgetRef = ref;
          return const DebugSettings(channel: 'stable');
        },
      ),
    );
    expect(find.text('Updater'), findsOneWidget);
    expect(find.textContaining('APP_VERSION is not set'), findsOneWidget);

    await tester.ensureVisible(find.text('Preview'));
    await tester.tap(find.text('Preview'));
    await tester.pump();
    expect(signals, contains(previewUpdateModalSignal));

    expect(widgetRef.read(updateAvailableProvider).previewUpdate, isFalse);
    await tester.tap(find.text('Turn on'));
    await tester.pump();
    expect(widgetRef.read(updateAvailableProvider).previewUpdate, isTrue);
    expect(find.text('Turn off'), findsOneWidget);
    await tester.tap(find.text('Turn off'));
    await tester.pump();
    expect(widgetRef.read(updateAvailableProvider).previewUpdate, isFalse);
  });

  testWidgets('debug copy info writes settings JSON to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    rust.on('crateApiSettingsExportSettings', ({required String path}) async => File(path).writeAsStringSync('{"theme":"dark"}'));
    await pumpBody(tester, const DebugSettings(channel: 'stable'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Copy'));
      for (var i = 0; i < 20 && copied == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await base.settle(tester, 2);
    final info = jsonDecode(copied!) as Map<String, Object?>;
    expect(info['app_version'], '2.0.0');
    expect(info['settings'], {'theme': 'dark'});
    expect(info['window'], '1400x1100 @1x');
    expect(toastTexts(tester), contains('Debug info copied to clipboard'));
    await base.drainToasts(tester);
  });

  testWidgets('beta re-import asks to confirm, re-imports and restarts', (tester) async {
    final relaunched = <String>[];
    DebugSettings.debugRelaunch = () async => relaunched.add('relaunch');
    var imports = 0;
    await pumpBody(
      tester,
      DebugSettings(
        channel: 'beta',
        reimport: () async {
          imports++;
          return BetaImport(imported: true, copiedFiles: BigInt.from(12));
        },
      ),
    );
    final row = find.text('Re-import from GodotHub');
    expect(row, findsOneWidget);
    ghToasts.clear();
    await tester.pump();
    await tester.ensureVisible(find.text('Re-import'));
    await tester.tap(find.text('Re-import'));
    await base.settle(tester, 2);
    expect(imports, 0);
    ghToasts.clear();
    await tester.pump();
    await tester.tap(find.text('Confirm re-import'));
    await base.settle(tester, 3);
    expect(imports, 1);
    expect(relaunched, ['relaunch']);
    expect(toastTexts(tester), contains('Re-imported 12 files from GodotHub'));
    expect(find.text('Confirm re-import'), findsNothing);
    await base.drainToasts(tester);
  });

  testWidgets('beta re-import reports failures and restart problems', (tester) async {
    DebugSettings.debugRelaunch = () async => throw UnsupportedError('no relaunch');
    var fail = true;
    await pumpBody(
      tester,
      DebugSettings(
        channel: 'beta',
        reimport: () async {
          if (fail) throw StateError('locked');
          return BetaImport(imported: true, copiedFiles: BigInt.one);
        },
      ),
    );
    ghToasts.clear();
    await tester.pump();
    await tester.ensureVisible(find.text('Re-import'));
    await tester.tap(find.text('Re-import'));
    await base.settle(tester, 2);
    ghToasts.clear();
    await tester.pump();
    await tester.tap(find.text('Confirm re-import'));
    await base.settle(tester, 3);
    expect(toastTexts(tester).any((t) => t.startsWith('Could not re-import from GodotHub')), isTrue);
    expect(find.text('Confirm re-import'), findsOneWidget);
    fail = false;
    ghToasts.clear();
    await tester.pump();
    await tester.tap(find.text('Confirm re-import'));
    await base.settle(tester, 3);
    expect(toastTexts(tester), contains('Restart GodotHub Beta to load the imported data'));
    await base.drainToasts(tester);
  });

  testWidgets('debug crash throws a render error', (tester) async {
    await pumpBody(tester, const DebugSettings(channel: 'stable'));
    ghToasts.clear();
    await tester.pump();
    await tester.ensureVisible(find.text('Crash'));
    await tester.tap(find.text('Crash'));
    await tester.pump();
    expect(tester.takeException(), isA<StateError>());
  });
}
