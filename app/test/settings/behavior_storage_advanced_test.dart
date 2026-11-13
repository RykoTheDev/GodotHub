import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/settings/categories/advanced_settings.dart';
import 'package:godothub/settings/categories/behavior_settings.dart';
import 'package:godothub/settings/categories/cli_tool_section.dart';
import 'package:godothub/settings/categories/settings_option_controls.dart';
import 'package:godothub/settings/categories/storage_settings.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/section_search.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/toast_host.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
late List<AppSettings> saved;
late int loads;
late List<String> calls;

String ts(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

CliToolStatus cliStatus({required bool installed, String shim = 'C:/bin/godothub.cmd'}) => CliToolStatus(
  installed: installed,
  onPath: installed,
  binDir: 'C:/bin',
  shimPath: shim,
  platform: 'windows',
  needsNewTerminal: false,
);

Future<ProviderContainer> pump(WidgetTester tester, Widget body, {AppSettings? settings}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final initial = settings ?? copySettings(baseSettings, setupComplete: true);
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeSettings(
          () {
            loads++;
            return initial;
          },
          onSave: (next) {
            saved.add(next);
            return next;
          },
        ),
      ],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: GhToastHost(
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                ref.watch(sectionSearchProvider);
                ref.watch(settingsProvider);
                return SingleChildScrollView(
                  child: Padding(padding: const EdgeInsets.all(24), child: body),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await base.settle(tester, 4);
  return container;
}

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
    saved = [];
    loads = 0;
    calls = [];
    rust
      ..on('crateApiAppChannelIdentifier', ({required String channel}) => channel == 'beta' ? 'Ryko.GodotHub.Beta' : 'Ryko.GodotHub')
      ..on('crateApiWatcherRestartWatchers', () async => calls.add('watchers'))
      ..on('crateApiProjectsListProjects', () async {
        calls.add('projects');
        return const <Project>[];
      })
      ..on('crateApiCliShimCliToolStatus', () async => cliStatus(installed: false));
  });

  group('cli shim name', () {
    test('uses the channel shim from the core status', () {
      expect(cliShimName(cliStatus(installed: true)), 'godothub');
      expect(cliShimName(cliStatus(installed: true, shim: '/usr/local/bin/godothub-beta')), 'godothub-beta');
      expect(
        cliChannelMessage('run: godothub', cliStatus(installed: true, shim: r'C:\bin\godothub-beta.cmd')),
        'run: godothub-beta',
      );
      expect(cliChannelMessage('run: godothub', cliStatus(installed: true)), 'run: godothub');
    });
  });

  group('behavior', () {
    testWidgets('toggles, landing tab, naming convention and the reopen row', (tester) async {
      await pump(
        tester,
        const BehaviorSettings(isMacOverride: false),
        settings: copySettings(baseSettings, setupComplete: true, closeOnProjectOpen: true, minimizeToTray: false),
      );
      expect(find.text(ts('features_title')), findsOneWidget);
      expect(find.text(ts('minimize_tray_label')), findsOneWidget);
      expect(find.text(ts('reopen_label')), findsNothing);

      await tester.tap(find.bySemanticsLabel(ts('minimize_tray_label')).last);
      await base.settle(tester, 3);
      expect(saved.last.minimizeToTray, isTrue);
      expect(find.text(ts('reopen_label')), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(ts('launch_console_label')).last);
      await base.settle(tester, 3);
      expect(saved.last.launchWithConsole, !baseSettings.launchWithConsole);

      await tester.tap(find.widgetWithText(SettingsDropdownTrigger, ts('landing_projects')));
      await base.settle(tester, 3);
      await tester.tap(find.text(ts('landing_versions')).last);
      await base.settle(tester, 3);
      expect(saved.last.defaultLandingTab, 'versions');

      await tester.tap(find.widgetWithText(SettingsDropdownTrigger, ts('naming_keep')));
      await base.settle(tester, 3);
      await tester.tap(find.text(ts('naming_snake')).last);
      await base.settle(tester, 3);
      expect(saved.last.directoryNamingConvention, 'snake_case');
    });

    testWidgets('mac hides the tray toggle and shows reopen when closing on open', (tester) async {
      await pump(
        tester,
        const BehaviorSettings(isMacOverride: true),
        settings: copySettings(baseSettings, setupComplete: true, closeOnProjectOpen: true),
      );
      expect(find.text(ts('minimize_tray_label')), findsNothing);
      expect(find.text(ts('reopen_label')), findsOneWidget);
    });

    testWidgets('search hides subsections that do not match', (tester) async {
      final container = await pump(tester, const BehaviorSettings(isMacOverride: false));
      container.read(sectionSearchProvider.notifier).setQuery(ts('naming_convention_label'));
      await base.settle(tester, 3);
      expect(find.text(ts('behavior_projects_title')), findsOneWidget);
      expect(find.text(ts('features_title')), findsNothing);
      expect(find.text(ts('landing_tab_label')), findsNothing);
      expect(container.read(sectionSearchProvider).visible, {'behavior-projects'});
    });
  });

  group('storage', () {
    testWidgets('folders, sliders, watchers and scan now', (tester) async {
      rust
        ..on('crateApiScanScanForProjects', ({required List<String> dirs, required int depth}) async {
          calls.add('scan-projects:${dirs.join(',')}:$depth');
          return const <Project>[];
        })
        ..on('crateApiScanScanForVersions', ({required List<String> dirs, required int depth}) async {
          calls.add('scan-versions:${dirs.join(',')}:$depth');
          return const <InstalledGodotVersion>[];
        });
      await pump(
        tester,
        StorageSettings(pickFolder: () async => 'D:/games'),
        settings: copySettings(baseSettings, setupComplete: true, projectScanDirs: ['C:/projects'], versionScanDirs: ['C:/godot'], scanDepth: 3),
      );
      expect(find.text(ts('storage_title')), findsOneWidget);
      expect(find.text('C:/projects'), findsOneWidget);
      expect(find.text(ts('folders_deep', count: 3)), findsOneWidget);
      expect(find.text(ghTr('default_downloads_go_to', args: {'path': 'AppData/Ryko.GodotHub.Beta/godot-versions/'})), findsOneWidget);

      await tester.tap(find.text(ghTr('add_folder')).first);
      await base.settle(tester, 3);
      expect(saved.last.projectScanDirs, ['C:/projects', 'D:/games']);

      await tester.tap(find.bySemanticsLabel(ts('watch_versions_label')).last);
      await base.settle(tester, 3);
      expect(saved.last.autoWatchVersionDirs, !baseSettings.autoWatchVersionDirs);
      expect(calls, contains('watchers'));

      await tester.tap(find.text(ghTr('scan_now')));
      await base.settle(tester, 4);
      expect(calls, containsAll(['scan-projects:C:/projects,D:/games:3', 'scan-versions:C:/godot:3', 'projects']));
      expect(find.text(ts('scan_result', args: {'projects': 0, 'versions': 0})), findsOneWidget);
    });

    testWidgets('the template folder is a single directory', (tester) async {
      await pump(tester, StorageSettings(pickFolder: () async => 'E:/templates'));
      expect(find.text(ts('no_folder_set')), findsOneWidget);
      await tester.tap(find.text(ghTr('add_folder')).last);
      await base.settle(tester, 3);
      expect(saved.last.templateScanDir, 'E:/templates');
    });
  });

  group('advanced', () {
    testWidgets('setup, update and bug callbacks, reset and delete confirms', (tester) async {
      var updates = 0;
      var bugs = 0;
      rust
        ..on('crateApiSettingsResetSettings', () async {
          calls.add('reset');
          return baseSettings;
        })
        ..on('crateApiSettingsResetAppData', () async => calls.add('wipe'));
      await pump(tester, AdvancedSettings(onCheckUpdates: () => updates++, onReportBug: () => bugs++));

      await tester.tap(find.text(ts('open_setup')));
      await base.settle(tester, 3);
      expect(saved.last.setupComplete, isFalse);

      await tester.tap(find.text(ghTr('check_updates_title_modal')).last);
      await tester.tap(find.text(ghTr('report_bug')));
      expect((updates, bugs), (1, 1));

      await tester.tap(find.text(ghTr('reset')));
      await base.settle(tester, 4);
      expect(find.text(ts('reset_all_desc')), findsOneWidget);
      await tester.tap(find.text(ghTr('cancel')));
      await base.settle(tester, 4);
      expect(calls, isNot(contains('reset')));
      await tester.tap(find.text(ghTr('reset')));
      await base.settle(tester, 4);
      await tester.tap(find.text(ts('reset_settings')).last);
      await base.settle(tester, 4);
      expect(calls, contains('reset'));

      final loadsBefore = loads;
      await tester.tap(find.text(ts('delete_all')));
      await base.settle(tester, 4);
      expect(find.text(ts('delete_all_desc')), findsOneWidget);
      await tester.tap(find.text(ts('delete_app_data')).last);
      await base.settle(tester, 4);
      expect(calls, contains('wipe'));
      expect(loads, greaterThan(loadsBefore));
    });

    testWidgets('restart confirms and reports relaunch errors; defaults emit shell signals', (tester) async {
      final signals = <String>[];
      final sub = AppSignals.all.listen((s) => signals.add(s.name));
      addTearDown(sub.cancel);
      await pump(tester, const AdvancedSettings());
      await tester.tap(find.text(ghTr('report_bug')));
      await tester.tap(find.text(ghTr('check_updates_title_modal')).last);
      await tester.pump();
      expect(signals, containsAll([reportBugSignal, previewUpdateModalSignal]));

      await tester.tap(find.text(ts('restart_app')).last);
      await base.settle(tester, 4);
      expect(find.text(ts('restart_app_confirm_desc')), findsOneWidget);
      await tester.tap(find.text(ts('restart_app')).last);
      await base.settle(tester, 4);
      expect(find.textContaining('Relaunching needs the app window'), findsOneWidget);
      await base.drainToasts(tester);
    });
  });

  group('cli tool', () {
    testWidgets('installs with the channel shim name and uninstalls', (tester) async {
      rust
        ..on('crateApiCliShimInstallCliTool', () async => cliStatus(installed: true, shim: 'C:/bin/godothub-beta.cmd'))
        ..on('crateApiCliShimUninstallCliTool', () async => cliStatus(installed: false, shim: 'C:/bin/godothub-beta.cmd'));
      await pump(tester, const CliToolSection());
      expect(find.text(ts('cli_tool_title')), findsOneWidget);
      await tester.tap(find.text(ts('cli_tool_install')));
      await base.settle(tester, 3);
      final installedMessage = ts('cli_tool_installed_msg').replaceAll('godothub', 'godothub-beta');
      expect(find.text(installedMessage), findsOneWidget);
      await tester.tap(find.text(ghTr('version_uninstall_confirm')));
      await base.settle(tester, 3);
      expect(find.text(ts('cli_tool_uninstalled_msg').replaceAll('godothub', 'godothub-beta')), findsOneWidget);
      expect(find.text(ts('cli_tool_install')), findsOneWidget);
    });
  });
}
