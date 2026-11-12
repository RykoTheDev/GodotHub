import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/restore_progress_modal.dart';
import 'package:godothub/settings/categories/cli_tool_section.dart';
import 'package:godothub/settings/categories/data_settings.dart';
import 'package:godothub/settings/categories/integrations_settings.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/section_search.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/ui/controls/toggle.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/versions/version_settings.dart';

import '../logic/logic_fixtures.dart';
import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
final calls = <String>[];
final opened = <String>[];

String ts(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

const _cli = CliToolStatus(installed: false, onPath: false, binDir: 'C:/bin', shimPath: 'C:/bin/godothub-beta', platform: 'windows', needsNewTerminal: false);

GitAuthState authState({bool github = false, List<GitPatInfo> pats = const []}) =>
    GitAuthState(github: github ? const GitAccountInfo(username: 'octo') : null, pats: pats);

void backend({GitAuthState? auth, GistSyncResult? gist, List<Project> projects = const []}) {
  var current = auth ?? authState();
  rust
    ..on('crateApiGitAuthGetGitAuthState', () async => current)
    ..on('crateApiGitAuthSaveGitPat', ({required String host, required String username, required String token}) async {
      calls.add('pat:$host:$username:$token');
      current = authState(github: current.github != null, pats: [...current.pats, GitPatInfo(host: host, username: username)]);
    })
    ..on('crateApiGitAuthRemoveGitPat', ({required String host}) async {
      calls.add('remove:$host');
      current = authState(github: current.github != null, pats: [for (final p in current.pats) if (p.host != host) p]);
    })
    ..on('crateApiGitAuthDisconnectGitAuth', ({required String provider}) async {
      calls.add('disconnect:$provider');
      current = authState(pats: current.pats);
    })
    ..on('crateApiSyncGistSyncGetInfo', () async => gist)
    ..on('crateApiSyncGistSyncPush', () async {
      calls.add('push');
      return const GistSyncResult(gistUrl: 'https://gist.github.com/abc', gistId: 'abc', pushedAt: '2026-03-01T10:00:00Z');
    })
    ..on('crateApiSyncGistSyncSaveGistUrl', ({required String gistUrl}) async => calls.add('save-url:$gistUrl'))
    ..on('crateApiSyncGistSyncFetchBackup', () async => throw 'offline')
    ..on('crateApiCliShimCliToolStatus', () async => _cli)
    ..on('crateApiCliShimInstallCliTool', () async {
      calls.add('cli-install');
      return const CliToolStatus(installed: true, onPath: true, binDir: 'C:/bin', shimPath: 'C:/bin/godothub-beta', platform: 'windows', needsNewTerminal: false);
    })
    ..on('crateApiCliShimUninstallCliTool', () async {
      calls.add('cli-uninstall');
      return _cli;
    })
    ..on('crateApiMiseMiseRefreshStatus', () async => const MiseStatus(available: false))
    ..on('crateApiWorkspaceListWorkspaces', () async => const WorkspacesState(workspaces: [], activeId: ''))
    ..on('crateApiProjectsListProjects', () async => projects)
    ..on('crateApiProjectsGetProjectName', ({required String path}) async => null)
    ..on('crateApiProjectsGetProjectIcon', ({required String path}) async => null)
    ..on('crateApiCategoriesListCategories', () async => <Category>[])
    ..on('crateApiSettingsExportSettings', ({required String path}) async => calls.add('export-settings:$path'))
    ..on('crateApiSettingsImportSettings', ({required String path}) async {
      calls.add('import-settings:$path');
      return copySettings(baseSettings, setupComplete: true, discordRpcEnabled: true);
    })
    ..on('crateApiBackupExportAppBackup', ({required String path}) async => calls.add('export-app:$path'))
    ..on('crateApiBackupImportAppBackup', ({required String path}) async {
      calls.add('import-app:$path');
      return copySettings(baseSettings, setupComplete: true);
    })
    ..on('crateApiProjectsImportProjectStats', ({required String path}) async => BigInt.from(4))
    ..on('crateApiSettingsResetSettings', () async {
      calls.add('reset-settings');
      return baseSettings;
    })
    ..on('crateApiSettingsResetAppData', () async => calls.add('reset-app-data'));
}

AppSettings readSettings(WidgetTester tester, Type type) =>
    ProviderScope.containerOf(tester.element(find.byType(type))).read(settingsProvider).value!;

Future<void> pumpCategory(WidgetTester tester, Widget child, {AppSettings? settings}) async {
  await base.pumpHost(
    tester,
    settings: settings,
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
  await base.settle(tester);
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
    calls.clear();
    opened.clear();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
    SettingsFilePickers.debugPickSavePath = null;
    SettingsFilePickers.debugPickDataFile = null;
  });
  tearDown(() {
    OpenerApi.debugOpenUrl = null;
    SettingsFilePickers.debugPickSavePath = null;
    SettingsFilePickers.debugPickDataFile = null;
  });

  group('data', () {
    testWidgets('exports and imports settings through the picked paths', (tester) async {
      backend();
      SettingsFilePickers.debugPickSavePath = (name) async => 'C:/out/$name';
      SettingsFilePickers.debugPickDataFile = () async => 'C:/in/settings.json';
      await pumpCategory(tester, const DataSettings());
      await tester.tap(find.text(ts('export_settings_btn')));
      await base.settle(tester);
      expect(calls, ['export-settings:C:/out/godothub-settings.json']);
      expect(find.text(ts('settings_exported')), findsOneWidget);
      await tester.tap(find.text(ts('import_settings_btn')));
      await base.settle(tester);
      expect(calls.last, 'import-settings:C:/in/settings.json');
      expect(find.text(ts('settings_imported')), findsOneWidget);
      expect(readSettings(tester, DataSettings).discordRpcEnabled, isTrue);
    });

    testWidgets('app backup restore refreshes data and templates; cancelled pickers do nothing', (tester) async {
      backend();
      final signals = <String>[];
      final sub = AppSignals.on(refreshTemplatesSignal).listen((s) => signals.add(s.name));
      addTearDown(sub.cancel);
      SettingsFilePickers.debugPickDataFile = () async => 'C:/in/full.json';
      SettingsFilePickers.debugPickSavePath = (_) async => null;
      await pumpCategory(tester, const DataSettings());
      await tester.tap(find.text(ts('app_backup_export_btn')));
      await base.settle(tester);
      expect(calls, isEmpty);
      await tester.tap(find.text(ts('app_backup_restore_btn')));
      await base.settle(tester);
      expect(calls, ['import-app:C:/in/full.json']);
      expect(find.text(ts('app_backup_imported')), findsOneWidget);
      expect(signals, [refreshTemplatesSignal]);
      await tester.tap(find.text(ts('import_stats_btn')));
      await base.settle(tester);
      expect(find.text('Imported stats for 4 projects.'), findsOneWidget);
    });

    testWidgets('picker errors show inline like React', (tester) async {
      backend();
      await pumpCategory(tester, const DataSettings());
      await tester.tap(find.text(ts('workspace_backup_export_btn')));
      await base.settle(tester);
      expect(find.textContaining('pickSavePath is not available'), findsOneWidget);
      expect(calls, isEmpty);
    });
  });

  group('integrations', () {
    testWidgets('signed out: token field, personal access tokens and the CLI section', (tester) async {
      backend();
      await pumpCategory(tester, const IntegrationsSettings());
      expect(find.byType(GithubTokenField), findsOneWidget);
      expect(find.text(ts('sync_title')), findsNothing);
      expect(find.text(ts('git_pat_empty')), findsOneWidget);
      await tester.tap(find.text(ts('git_pat_add')));
      await base.settle(tester);
      await tester.enterText(find.bySemanticsLabel(ts('git_pat_host_placeholder')), 'git.example.com');
      await tester.enterText(find.bySemanticsLabel(ts('git_pat_username')), 'me');
      await tester.enterText(find.bySemanticsLabel(ts('git_pat_token')), 'secret');
      await tester.tap(find.text(ts('git_pat_save')));
      await base.settle(tester);
      expect(calls, ['pat:git.example.com:me:secret']);
      expect(find.text('git.example.com'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ts('git_pat_remove')));
      await base.settle(tester);
      expect(calls.last, 'remove:git.example.com');
      expect(find.text(ts('git_pat_empty')), findsOneWidget);

      expect(find.byType(CliToolSection), findsOneWidget);
    });

    testWidgets('signed in: sync push, gist link, manual pull and disconnect', (tester) async {
      backend(auth: authState(github: true));
      await pumpCategory(tester, const IntegrationsSettings());
      expect(find.byType(GithubTokenField), findsNothing);
      expect(find.text(ts('git_connected_as', args: {'username': 'octo'})), findsOneWidget);
      await tester.tap(find.text(ts('sync_push_btn')));
      await base.settle(tester);
      expect(calls, ['push']);
      expect(find.text(ts('sync_push_done')), findsOneWidget);
      await tester.tap(find.text(ts('sync_open_gist')));
      await base.settle(tester);
      expect(opened, ['https://gist.github.com/abc']);

      await tester.enterText(find.bySemanticsLabel(ts('sync_manual_placeholder')), ' https://gist.github.com/xyz ');
      await base.settle(tester, 2);
      await tester.tap(find.text(ts('sync_manual_pull_btn')));
      await base.settle(tester);
      expect(calls.last, 'save-url:https://gist.github.com/xyz');
      expect(find.byType(RestoreProgressModal), findsOneWidget);
      Navigator.of(tester.element(find.byType(RestoreProgressModal))).pop();
      await base.settle(tester);

      await tester.tap(find.text(ts('git_disconnect')));
      await base.settle(tester);
      expect(calls.last, 'disconnect:github');
      expect(find.text(ts('sync_title')), findsNothing);
      expect(find.byType(GithubTokenField), findsOneWidget);
    });

    testWidgets('discord: toggle, exclude a project and custom presence', (tester) async {
      backend(projects: [project(id: 'a', name: 'Alpha'), project(id: 'b', name: 'Beta')]);
      await pumpCategory(tester, const IntegrationsSettings(), settings: copySettings(baseSettings, setupComplete: true));
      final toggle = find.byType(GhToggle).at(1);
      await tester.ensureVisible(toggle);
      final before = readSettings(tester, IntegrationsSettings).discordRpcShowProjects;
      await tester.tap(toggle);
      await base.settle(tester, 3);
      expect(readSettings(tester, IntegrationsSettings).discordRpcShowProjects, !before);

      expect(find.text(ts('discord_excluded_empty')), findsOneWidget);
      await tester.ensureVisible(find.text(ts('discord_exclude_project')).first);
      await tester.tap(find.text(ts('discord_exclude_project')).first);
      await base.settle(tester);
      await tester.tap(find.text('Alpha').last);
      await base.settle(tester);
      expect(readSettings(tester, IntegrationsSettings).discordRpcExcludedProjects, ['a']);
      expect(find.text(ts('discord_excluded_empty')), findsNothing);

      await tester.ensureVisible(find.text(ts('discord_custom_add')).last);
      await tester.tap(find.text(ts('discord_custom_add')).last);
      await base.settle(tester);
      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Beta').last);
      await base.settle(tester);
      await tester.enterText(find.bySemanticsLabel(ts('discord_custom_details_placeholder')), 'Making levels');
      await base.settle(tester, 2);
      final presence = readSettings(tester, IntegrationsSettings).discordRpcProjectPresences.single;
      expect(presence.id, 'b');
      expect(presence.details, 'Making levels');
      expect(presence.state, isNull);

      await tester.tap(find.bySemanticsLabel(ts('discord_excluded_remove')));
      await base.settle(tester);
      expect(readSettings(tester, IntegrationsSettings).discordRpcExcludedProjects, isEmpty);
    });

    testWidgets('search hides non-matching sections', (tester) async {
      backend();
      await pumpCategory(tester, const IntegrationsSettings());
      final container = ProviderScope.containerOf(tester.element(find.byType(IntegrationsSettings)));
      container.read(sectionSearchProvider.notifier).setQuery('mise');
      await base.settle(tester);
      expect(find.byType(MiseSetting), findsOneWidget);
      expect(find.text(ts('cli_tool_title')), findsNothing);
      expect(find.text(ts('onboarding_discord_rpc')), findsNothing);
      container.read(sectionSearchProvider.notifier).setQuery('zzzz');
      await base.settle(tester);
      expect(container.read(sectionSearchProvider).visible, isEmpty);
      expect(container.read(sectionSearchProvider).noResults, isTrue);
    });
  });
}
