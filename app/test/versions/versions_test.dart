import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/logic/export_template_catalog.dart';
import 'package:godothub/logic/last_opened.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/current_version_modal.dart';
import 'package:godothub/modals/download_error_modal.dart';
import 'package:godothub/modals/export_templates_modal.dart';
import 'package:godothub/modals/version_aliases_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/godot_versions.dart';
import 'package:godothub/state/task_tray.dart';
import 'package:godothub/titlebar/task_tray.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/versions/installed_version_card.dart';
import 'package:godothub/versions/version_logic.dart';
import 'package:godothub/versions/version_settings.dart';
import 'package:godothub/versions/versions_view.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
final opened = <String>[];

String tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

InstalledGodotVersion installed(
  String tag, {
  bool mono = false,
  String? name,
  String installedAt = '2026-01-01T00:00:00Z',
  String? managedBy,
}) => InstalledGodotVersion(
  tag: tag,
  version: tag.split('-').first,
  executablePath: 'C:/godot/$tag/godot.exe',
  isMono: mono,
  installedAt: installedAt,
  customName: name,
  supportsConsole: true,
  managedBy: managedBy,
);

GodotRelease release(String tag, {bool mono = false}) => GodotRelease(
  tag: tag,
  assets: [
    GodotReleaseAsset(
      name: 'Godot_v${tag}_win64.zip',
      downloadUrl: 'https://x/$tag.zip',
      size: BigInt.from(80 * 1024 * 1024),
      isMono: false,
    ),
    if (mono)
      GodotReleaseAsset(
        name: 'Godot_v${tag}_mono_win64.zip',
        downloadUrl: 'https://x/$tag-mono.zip',
        size: BigInt.from(90 * 1024 * 1024),
        isMono: true,
      ),
  ],
);

class VersionsBackend {
  List<InstalledGodotVersion> installedList = [installed('4.3-stable')];
  List<GodotRelease> available = [release('4.3-stable', mono: true), release('4.4-stable'), release('4.4-beta1')];
  Object? availableError;
  ExportTemplatesState templates = const ExportTemplatesState(defaultDir: 'C:/t', versions: [], orphans: []);
  final calls = <String>[];

  void install(FakeRustApi rust) {
    rust
      ..on('crateApiGodotVersionsListInstalledGodotVersions', () async => installedList)
      ..on('crateApiGodotVersionsFetchAvailableGodotVersions', ({String? source}) async {
        calls.add('fetch:$source');
        if (availableError != null) throw availableError!;
        return available;
      })
      ..on('crateApiCurrentVersionGetCurrentVersion', () async => null)
      ..on('crateApiCurrentVersionListVersionAliases', () async => const VersionAliases(aliases: [], aliasesDir: 'C:/aliases'))
      ..on('crateApiExportTemplatesGetExportTemplatesState', () async => templates)
      ..on('crateApiMiseMiseRefreshStatus', () async => const MiseStatus(available: false))
      ..on('crateApiGodotVersionsDownloadGodotVersion', ({
        required String tag,
        required String assetName,
        required String downloadUrl,
      }) async {
        calls.add('download:$tag:$assetName');
      })
      ..on('crateApiGodotVersionsPauseDownload', ({required String key}) async => calls.add('pause:$key'))
      ..on('crateApiGodotVersionsCancelDownload', ({required String key}) async => calls.add('cancel:$key'))
      ..on(
        'crateApiGodotVersionsReorderDownloadQueue',
        ({required String key, required int direction}) async => calls.add('move:$key:$direction'),
      )
      ..on(
        'crateApiExportTemplatesDeleteExportTemplates',
        ({required String folder, String? root}) async => calls.add('delete-templates:$folder'),
      )
      ..on('crateApiCurrentVersionSetCurrentVersion', ({required String tag}) async {
        calls.add('current:$tag');
        return CurrentVersionInfo(tag: tag, aliasPath: 'C:/aliases/godot.cmd', aliasesDir: 'C:/aliases', method: 'shim');
      })
      ..on('crateApiGodotVersionsRenameGodotVersion', ({required String tag, String? customName}) async {
        calls.add('rename:$tag:$customName');
        return installed(tag, name: customName);
      });
  }
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
    debugResetOpenTodos();
    clearTemplateCatalog();
    opened.clear();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
  });
  tearDown(() => OpenerApi.debugOpenUrl = null);

  group('logic', () {
    test('natural sort, version cores and groups', () {
      expect(naturalCompare('4.10-stable', '4.9-stable'), greaterThan(0));
      expect(naturalCompare('v2', 'v10'), lessThan(0));
      expect(versionCore('v4.3.0-stable'), '4.3.0-stable');
      expect(versionCore('4.4'), '4.4-stable');
      expect(minorGroup('v4.3.1-rc2'), '4.3');
      expect(minorGroup('nightly'), 'Other');
      final releases = [release('4.2-stable'), release('4.3-stable', mono: true), release('4.3-beta1')];
      final latest = groupAvailable(releases, '', const VersionFilters(), VersionSort.latest);
      expect([for (final g in latest) g.$1], ['4.3', '4.2']);
      final stableMono = groupAvailable(
        releases,
        '',
        const VersionFilters(buildType: BuildTypeFilter.mono, channel: ChannelFilter.stable),
        VersionSort.latest,
      );
      expect(stableMono.single.$2.single.asset.isMono, isTrue);
      final oldest = groupAvailable(releases, '', const VersionFilters(), VersionSort.oldest);
      expect([for (final g in oldest) g.$1], ['4.2', '4.3']);
      expect([for (final r in oldest.last.$2) r.tag], ['4.3-beta1', '4.3-stable', '4.3-stable']);
      expect(groupAvailable(releases, '4.2', const VersionFilters(), VersionSort.latest).single.$1, '4.2');
    });

    test('installed sorting, filters, urls and reports', () {
      final list = [
        installed('4.2-stable', installedAt: '2026-03-01T00:00:00Z'),
        installed('4.10-stable', name: 'Zed', installedAt: '2026-01-01T00:00:00Z'),
        installed('4.3-stable', name: 'Alpha', installedAt: '2026-02-01T00:00:00Z'),
      ];
      expect([for (final v in filterAndSortInstalled(list, '', VersionSort.latest)) v.tag], ['4.10-stable', '4.3-stable', '4.2-stable']);
      expect([for (final v in filterAndSortInstalled(list, '', VersionSort.nameAsc)) v.tag].first, '4.2-stable');
      expect([for (final v in filterAndSortInstalled(list, '', VersionSort.recentlyInstalled)) v.tag].first, '4.2-stable');
      expect(filterAndSortInstalled(list, 'zed', VersionSort.latest).single.tag, '4.10-stable');
      expect(VersionSort.parse('recently_installed', installed: false), VersionSort.latest);
      final filters = const VersionFilters(buildType: BuildTypeFilter.mono, channel: ChannelFilter.stable);
      expect(VersionFilters.decode(filters.encode()), filters);
      expect(VersionFilters.decode('garbage'), const VersionFilters());
      expect(sourcePageUrl(VersionSource.archive, '4.3-stable'), 'https://godotengine.org/download/archive/4.3-stable/');
      expect(sourcePageUrl(VersionSource.mise, '4.3', 'https://github.com/x/y/releases/'), 'https://github.com/x/y/releases/tag/4.3');
      expect(isRateLimited(VersionSource.github, 'API rate limit exceeded'), isTrue);
      expect(isRateLimited(VersionSource.archive, 'API rate limit exceeded'), isFalse);
      expect(isAvailableInstalled([installed('v4.3-stable')], '4.3-stable', false), isTrue);
      const error = DownloadErrorInfo(key: 'k', tag: '4.3', assetName: 'a.zip', url: 'https://u', source: 'archive', message: 'boom');
      final report = downloadReport(error, appVersion: '1.0', os: 'Windows', platform: 'x');
      expect(report, contains('Source:   Godot Archive'));
      expect(report, endsWith('boom'));
      final url = Uri.parse(downloadIssueUrl(error, report));
      expect(url.queryParameters['title'], 'Download failed: 4.3');
      expect(installFolderOf(r'C:\godot\4.3\godot.exe'), r'C:\godot\4.3');
      final info = RateLimitInfo(remaining: BigInt.from(4999), limit: BigInt.from(5000), resetAt: 600, usedToken: true);
      final described = describeRateLimit(info, nowSeconds: 0);
      expect(described.state, TokenTestState.success);
      expect(described.message, contains('4999/5000'));
    });
  });

  group('versions view', () {
    testWidgets('lists installed and available versions and installs one', (tester) async {
      final backend = VersionsBackend()..install(rust);
      await base.pumpHost(tester, body: const VersionsView());
      await base.settle(tester);
      expect(find.text('4.3-stable'), findsWidgets);
      expect(find.text(tv('installed_label')), findsOneWidget);
      expect(find.text('.NET'), findsOneWidget);
      expect(find.text('4.4-stable'), findsOneWidget);
      await tester.tap(find.text(tv('install')).first);
      await base.settle(tester);
      expect(backend.calls, contains('download:4.4-stable:Godot_v4.4-stable_win64.zip'));
      rust.emit(
        AppEvent(
          kind: AppEventKind.godotDownloadProgress,
          name: 'godot-download-progress',
          json: 'null',
          downloadProgress: DownloadProgress(
            tag: '4.4-stable',
            downloaded: BigInt.from(10 * 1024 * 1024),
            total: BigInt.from(40 * 1024 * 1024),
          ),
        ),
      );
      await base.settle(tester, 3);
      expect(find.text('10.0 MB / 40.0 MB'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(tv('pause_download')));
      await base.settle(tester, 3);
      expect(backend.calls, contains('pause:4.4-stable'));
      await tester.tap(find.bySemanticsLabel(tv('cancel_download')));
      await base.settle(tester, 3);
      expect(backend.calls, contains('cancel:4.4-stable'));
      await base.drainToasts(tester);
    });

    testWidgets('a rate limited GitHub fetch offers the archive', (tester) async {
      final backend = VersionsBackend()..availableError = 'API rate limit exceeded';
      backend.install(rust);
      await base.pumpHost(tester, body: const VersionsView());
      await base.settle(tester);
      expect(find.text(tv('fetch_error')), findsOneWidget);
      backend.availableError = null;
      await tester.tap(find.text(tv('switch_to_archive')));
      await base.settle(tester);
      expect(backend.calls.last, 'fetch:archive');
      expect(find.text('4.4-stable'), findsOneWidget);
    });

    testWidgets('orphaned templates can be deleted and the search narrows lists', (tester) async {
      final backend = VersionsBackend()
        ..templates = ExportTemplatesState(
          defaultDir: 'C:/t',
          versions: const [],
          orphans: [
            ExportTemplatesOrphan(
              folder: '3.5.stable',
              path: 'C:/t/3.5.stable',
              root: 'C:/t',
              sizeBytes: BigInt.from(2048),
              fileCount: BigInt.one,
            ),
          ],
        );
      backend.install(rust);
      await base.pumpHost(tester, body: const VersionsView());
      await base.settle(tester);
      expect(find.text('3.5.stable'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(tv('export_templates_orphan_delete')));
      await base.settle(tester);
      await tester.tap(find.text(tv('export_templates_orphan_delete')).last);
      await base.settle(tester);
      expect(backend.calls, contains('delete-templates:3.5.stable'));
      await tester.enterText(find.byType(TextField).first, 'zzz');
      await base.settle(tester, 3);
      expect(find.textContaining(tv('no_versions_match')), findsOneWidget);
      await base.drainToasts(tester);
    });

    testWidgets('a download error opens the report dialog with retry', (tester) async {
      final backend = VersionsBackend()..install(rust);
      rust.on('crateApiAppAppVersion', () => '2.0.0');
      await base.pumpHost(tester, body: const VersionsView());
      await base.settle(tester);
      await tester.tap(find.text(tv('install')).first);
      await base.settle(tester);
      rust.emit(
        AppEvent(
          kind: AppEventKind.godotDownloadError,
          name: 'godot-download-error',
          json: 'null',
          downloadFailure: const DownloadFailure(tag: '4.4-stable', message: 'checksum mismatch'),
        ),
      );
      await base.settle(tester);
      expect(find.byType(DownloadErrorModal), findsOneWidget);
      expect(find.text('checksum mismatch'), findsOneWidget);
      await tester.tap(find.text(ghTr('retry')));
      await base.settle(tester);
      expect(find.byType(DownloadErrorModal), findsNothing);
      expect(backend.calls.where((c) => c.startsWith('download:4.4-stable')).length, 2);
    });
  });

  group('installed card and modals', () {
    testWidgets('rename, set current and template chip', (tester) async {
      final backend = VersionsBackend()..install(rust);
      String? renamed;
      await base.pumpHost(
        tester,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: InstalledVersionCard(
            version: installed('4.3-stable'),
            isCurrent: false,
            onOpen: (_) {},
            onRename: (name) => renamed = name,
            onSetCurrent: () async =>
                CurrentVersionInfo(tag: '4.3-stable', aliasPath: 'C:/aliases/godot.cmd', aliasesDir: 'C:/aliases', method: 'shim'),
            onClearCurrent: () async {},
            onManageAliases: () {},
            onUninstall: () {},
            onInstallTemplates: (_) {},
          ),
        ),
      );
      expect(find.text(tv('export_templates_missing')), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ghTr('version_rename_aria')));
      await base.settle(tester, 3);
      await tester.enterText(find.byType(TextField), 'Main');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await base.settle(tester, 3);
      expect(renamed, 'Main');
      await tester.tap(find.bySemanticsLabel(tv('more_editor_launch_options')));
      await base.settle(tester, 4);
      await tester.tap(find.text(tv('set_as_current')));
      await base.settle(tester);
      expect(find.byType(CurrentVersionModal), findsOneWidget);
      expect(find.text('C:/aliases/godot.cmd'), findsOneWidget);
      expect(find.text(tv('current_shim_note')), findsOneWidget);
      expect(backend.calls, isEmpty);
    });

    testWidgets('export templates modal selects, uninstalls and downloads', (tester) async {
      List<String>? downloaded;
      final removed = <String>[];
      rust.on(
        'crateApiExportTemplatesUninstallExportTemplateFiles',
        ({required String tag, required List<String> files}) async => removed.addAll(files),
      );
      TemplateFile file(String name, {bool installed = false}) =>
          TemplateFile(name: name, sizeBytes: BigInt.from(2048), downloadBytes: BigInt.from(1024), installed: installed);
      final options = [
        TemplateOption(
          id: 'windows',
          label: 'Windows',
          files: [file('windows_debug_x86_64.exe'), file('windows_release_x86_64.exe', installed: true)],
          sizeBytes: BigInt.from(4096),
          downloadBytes: BigInt.from(2048),
          installed: false,
        ),
        TemplateOption(
          id: 'android',
          label: 'Android',
          files: [file('android_debug.apk')],
          sizeBytes: BigInt.from(2048),
          downloadBytes: BigInt.from(1024),
          installed: false,
        ),
      ];
      await base.openModal(
        tester,
        (close) => ExportTemplatesModal(
          tag: '4.3-stable',
          onClose: close,
          onDownload: (files) => downloaded = files,
          fetch: (tag, refresh) async => options,
        ),
      );
      expect(find.text(tv('export_templates_category_desktop')), findsOneWidget);
      expect(find.text('Windows'), findsOneWidget);
      await tester.tap(find.text(tv('export_templates_select_all')));
      await base.settle(tester, 3);
      expect(find.text(tv('export_templates_selected', count: 2)), findsOneWidget);
      await tester.tap(find.text('Windows'));
      await base.settle(tester, 6);
      await tester.tap(find.bySemanticsLabel(tv('export_templates_uninstall_named', args: {'name': 'Windows'})).first);
      await base.settle(tester);
      expect(removed, ['windows_release_x86_64.exe']);
      await tester.tap(find.text(tv('export_templates_download_selected')));
      await base.settle(tester, 3);
      expect(downloaded, unorderedEquals(['windows_debug_x86_64.exe', 'android_debug.apk']));
      await base.drainToasts(tester);
    });

    testWidgets('aliases modal queues, rejects duplicates and creates', (tester) async {
      List<AliasRequest>? created;
      await base.openModal(
        tester,
        (close) => VersionAliasesModal(
          versions: [installed('4.3-stable', mono: true)],
          aliases: const [AliasInfo(name: 'godot', tag: '4.3-stable', aliasPath: 'C:/a/godot.cmd', aliasesDir: 'C:/a', method: 'shim')],
          aliasesDir: 'C:/a',
          windows: true,
          onClose: close,
          onCreateMany: (entries) async {
            created = entries;
            return const AliasBatchResult(
              created: [],
              skipped: [AliasSkip(name: 'g4', tag: '4.3-stable', reason: 'exists')],
            );
          },
          onDelete: (_) async {},
        ),
      );
      expect(find.text('C:/a/godot.cmd'), findsOneWidget);
      expect(find.text(tv('alias_mono_script_note')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'g4');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await base.settle(tester, 3);
      await tester.enterText(find.byType(TextField), 'G4');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await base.settle(tester, 3);
      expect(find.text(tv('alias_queue_duplicate', args: {'name': 'G4'})), findsOneWidget);
      await tester.tap(find.text(tv('alias_create_all', count: 1)));
      await base.settle(tester);
      expect(created?.single.name, 'g4');
      expect(find.text(tv('aliases_batch_skipped', count: 1)), findsOneWidget);
      expect(find.text('g4 - exists'), findsOneWidget);
    });

    testWidgets('download error modal copies a report and opens an issue', (tester) async {
      rust.on('crateApiAppAppVersion', () => '2.0.0');
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      var retried = 0;
      await base.openModal(
        tester,
        (close) => DownloadErrorModal(
          error: const DownloadErrorInfo(key: 'k', tag: '4.3', assetName: 'a.zip', url: 'https://u', source: 'github', message: 'boom'),
          onRetry: () => retried++,
          onClose: close,
        ),
      );
      await tester.tap(find.text(tv('download_failed_copy')));
      await base.settle(tester, 3);
      expect(copied, contains('Version:  4.3'));
      expect(copied, contains('App:      2.0.0'));
      await tester.tap(find.text(ghTr('bug_report_open_github')));
      await base.settle(tester, 3);
      expect(opened.single, startsWith('https://github.com/RykoTheDev/GodotHub/issues/new?'));
      await tester.tap(find.text(ghTr('retry')));
      expect(retried, 1);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('tray and settings pieces', () {
    testWidgets('task tray lists downloads with queue and pause controls', (tester) async {
      final backend = VersionsBackend()..install(rust);
      final container = ProviderContainer(overrides: [fakeSettingsOverride()]);
      addTearDown(container.dispose);
      final tray = container.read(taskTrayProvider.notifier);
      tray.registerTask(
        TrayTask(
          id: godotDownloadTaskId('4.3'),
          type: TaskType.downloadGodot,
          label: 'Downloading 4.3',
          status: TaskStatus.running,
          progress: const TaskProgress(5, 10),
        ),
      );
      tray.registerTask(
        TrayTask(id: godotDownloadTaskId('4.4'), type: TaskType.downloadGodot, label: 'Downloading 4.4', status: TaskStatus.queued),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Align(alignment: Alignment.topRight, child: TaskTray()),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('task-tray-trigger')));
      await tester.pumpAndSettle();
      expect(find.text('Downloading 4.3'), findsOneWidget);
      expect(find.text('Downloading 4.4'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ghTr('download_queue_move_up')).last);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(tv('pause_download')));
      await tester.pump();
      expect(backend.calls, containsAll(['move:4.4:-1', 'pause:4.3']));
    });

    testWidgets('github token field reports the rate limit', (tester) async {
      await base.pumpHost(
        tester,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: GithubTokenField(
            test: () async => RateLimitInfo(remaining: BigInt.zero, limit: BigInt.from(60), resetAt: 0, usedToken: false),
          ),
        ),
      );
      await tester.tap(find.text(ghTr('settings:test')));
      await base.settle(tester, 3);
      expect(find.text(ghTr('settings:token_valid', args: {'status': '0/60'})), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.text(ghTr('settings:token_valid', args: {'status': '0/60'})), findsNothing);
    });

    test('detected installs import the selected ones', () async {
      final imported = <String>[];
      VersionsBackend().install(rust);
      rust
        ..on(
          'crateApiDiscoveryDetectGodotInstalls',
          () async => const [
            DiscoveredInstall(path: 'C:/a/godot.exe', name: 'Godot A', source: 'steam', version: '4.3'),
            DiscoveredInstall(path: 'C:/b/godot.exe', name: 'Godot B', source: 'itch'),
          ],
        )
        ..on('crateApiDiscoveryImportDetectedInstall', ({required String path}) async {
          imported.add(path);
          return installed('4.3-stable');
        });
      final container = ProviderContainer(overrides: [fakeSettingsOverride()]);
      addTearDown(container.dispose);
      container.listen(detectedInstallsProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(detectedInstallsProvider).selected.length, 2);
      container.read(detectedInstallsProvider.notifier).toggle('C:/b/godot.exe');
      expect(await container.read(detectedInstallsProvider.notifier).importSelected(), 1);
      expect(imported, ['C:/a/godot.exe']);
      expect(container.read(detectedInstallsProvider).imported, {'C:/a/godot.exe'});
      expect(await container.read(detectedInstallsProvider.notifier).importSelected(), 0);
    });
  });

  test('last opened date format still parses', () => expect(LastOpenedDateFormat.parse(null), LastOpenedDateFormat.ddMmYyyy));
}

Override fakeSettingsOverride() => fakeSettings(() => copySettings(baseSettings, setupComplete: true));
