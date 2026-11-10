import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/godot_versions.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/workspaces.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

const _installed = 'crateApiGodotVersionsListInstalledGodotVersions';
const _templates = 'crateApiExportTemplatesGetExportTemplatesState';
const _current = 'crateApiCurrentVersionGetCurrentVersion';
const _aliases = 'crateApiCurrentVersionListVersionAliases';
const _available = 'crateApiGodotVersionsFetchAvailableGodotVersions';
const _mise = 'crateApiMiseMiseRefreshStatus';

InstalledGodotVersion installed(String tag, {String? managedBy, String? customName}) => InstalledGodotVersion(
  tag: tag,
  version: tag,
  executablePath: '/godot/$tag',
  isMono: false,
  installedAt: '2026-01-01',
  customName: customName,
  supportsConsole: true,
  managedBy: managedBy,
);

AliasInfo alias(String name) => AliasInfo(name: name, tag: '4.4', aliasPath: '/a/$name', aliasesDir: '/a', method: 'symlink');

CurrentVersionInfo currentInfo(String tag) => CurrentVersionInfo(tag: tag, aliasPath: '/a/godot', aliasesDir: '/a', method: 'symlink');

AppEvent event(AppEventKind kind, {String? text, DownloadProgress? progress, DownloadFailure? failure}) =>
    AppEvent(kind: kind, name: '', json: 'null', text: text, downloadProgress: progress, downloadFailure: failure);

void main() {
  late FakeRustApi rust;
  late CoreBackend backend;
  late List<InstalledGodotVersion> serverInstalled;
  late List<AliasInfo> serverAliases;
  late Map<String, List<GodotRelease>> releases;
  late List<String> calls;
  late bool miseAvailable;

  setUp(() {
    rust = installFakeRust();
    useMemoryUiPrefs();
    backend = CoreBackend(rust, active: 'w1');
    serverInstalled = [installed('4.3-stable')];
    serverAliases = [alias('godot4')];
    releases = {
      'github': [const GodotRelease(tag: 'gh-4.4', assets: [])],
      'archive': [const GodotRelease(tag: 'ar-3.6', assets: [])],
      'mise': [const GodotRelease(tag: 'mi-4.4', assets: [])],
    };
    calls = [];
    miseAvailable = true;
    rust.on(_installed, () async => List<InstalledGodotVersion>.of(serverInstalled));
    rust.on(_templates, () async => const ExportTemplatesState(defaultDir: '/t', versions: [], orphans: []));
    rust.on(_current, () async => currentInfo('4.3-stable'));
    rust.on(_aliases, () async => VersionAliases(aliases: List.of(serverAliases), aliasesDir: '/a'));
    rust.on(_available, ({required String source}) async {
      calls.add('available:$source');
      return releases[source]!;
    });
    rust.on(_mise, () async => MiseStatus(available: miseAvailable));
  });

  ProviderContainerHandle start() {
    final container = createContainer([godotVersionsProvider, versionScanProgressProvider]);
    return ProviderContainerHandle(container);
  }

  test('loads installed versions, templates, current, aliases, releases and mise status', () async {
    final handle = start();
    await settle();
    final state = handle.state;
    expect(state.installed.map((v) => v.tag), ['4.3-stable']);
    expect(state.exportTemplates?.defaultDir, '/t');
    expect(state.current?.tag, '4.3-stable');
    expect(state.aliases.single.name, 'godot4');
    expect(state.aliasesDir, '/a');
    expect(state.source, VersionSource.github);
    expect(state.available.single.tag, 'gh-4.4');
    expect(state.loadingAvailable, isFalse);
    expect(state.miseStatus?.available, isTrue);
  });

  test('restores the saved release source and persists changes to it', () async {
    UiPrefsStore.instance.setItem(versionSourceKey, 'archive');
    final handle = start();
    await settle();
    expect(handle.state.source, VersionSource.archive);
    expect(handle.state.available.single.tag, 'ar-3.6');

    await handle.notifier.refreshAvailable(VersionSource.github);
    expect(handle.state.available.single.tag, 'gh-4.4');
    expect(UiPrefsStore.instance.getItem(versionSourceKey), 'github');
  });

  test('a failed release fetch keeps the error and only the newest request wins', () async {
    final gate = Completer<List<GodotRelease>>();
    rust.on(_available, ({required String source}) {
      calls.add('available:$source');
      if (source == 'archive') return gate.future;
      if (source == 'mise') throw StateError('rate limited');
      return Future.value(releases[source]!);
    });
    final handle = start();
    await settle();

    final slow = handle.notifier.refreshAvailable(VersionSource.archive);
    await handle.notifier.refreshAvailable(VersionSource.github);
    gate.complete(releases['archive']!);
    await slow;
    expect(handle.state.available.single.tag, 'gh-4.4');

    await handle.notifier.refreshAvailable(VersionSource.mise);
    expect(handle.state.availableError, contains('rate limited'));
    expect(handle.state.loadingAvailable, isFalse);
  });

  test('backend events refresh installed versions, aliases and matching release lists', () async {
    final handle = start();
    await settle();
    final installedBefore = rust.callCount(_installed);

    serverInstalled = [installed('4.3-stable'), installed('4.4-stable')];
    rust.emit(fakeEvent(AppEventKind.versionScanDone));
    await settle();
    expect(rust.callCount(_installed), installedBefore + 1);
    expect(handle.state.installed.map((v) => v.tag), ['4.3-stable', '4.4-stable']);

    serverAliases = [alias('godot4'), alias('godot44')];
    rust.emit(fakeEvent(AppEventKind.versionsAliasesChanged));
    await settle();
    expect(handle.state.aliases.map((a) => a.name), ['godot4', 'godot44']);

    calls.clear();
    rust.emit(event(AppEventKind.versionsAvailableUpdated, text: 'archive'));
    await settle();
    expect(calls, isEmpty);
    releases['github'] = [const GodotRelease(tag: 'gh-4.5', assets: [])];
    rust.emit(event(AppEventKind.versionsAvailableUpdated, text: 'github'));
    await settle();
    expect(calls, ['available:github']);
    expect(handle.state.available.single.tag, 'gh-4.5');
  });

  test('switching workspaces refreshes installed versions and releases', () async {
    final handle = start();
    await settle();
    final before = rust.callCount(_installed);
    calls.clear();
    await handle.container.read(workspacesProvider.notifier).switchWorkspace('w2');
    await settle();
    expect(rust.callCount(_installed), before + 1);
    expect(calls, ['available:github']);
  });

  test('download lifecycle events track queued, progress, paused, canceled, error and complete', () async {
    backend.settings = settingsWith(desktopNotificationsEnabled: true);
    final handle = start();
    await settle();

    rust.emit(event(AppEventKind.godotDownloadQueued, text: '4.4-stable'));
    await settle();
    expect(handle.state.downloads['4.4-stable']?.status, DownloadStatus.queued);

    rust.emit(
      event(
        AppEventKind.godotDownloadProgress,
        progress: DownloadProgress(tag: '4.4-stable', downloaded: BigInt.from(5), total: BigInt.from(10)),
      ),
    );
    await settle();
    expect(handle.state.downloads['4.4-stable'], const DownloadState(tag: '4.4-stable', downloaded: 5, total: 10, status: DownloadStatus.downloading));

    rust.emit(event(AppEventKind.godotDownloadQueued, text: '4.4-stable'));
    await settle();
    expect(handle.state.downloads['4.4-stable'], const DownloadState(tag: '4.4-stable', downloaded: 5, total: 10, status: DownloadStatus.queued));

    rust.emit(event(AppEventKind.godotDownloadPaused, text: '4.4-stable'));
    rust.emit(event(AppEventKind.godotDownloadPaused, text: 'unknown'));
    await settle();
    expect(handle.state.downloads['4.4-stable']?.status, DownloadStatus.paused);
    expect(handle.state.downloads.containsKey('unknown'), isFalse);

    rust.emit(event(AppEventKind.godotDownloadCanceled, text: '4.4-stable'));
    await settle();
    expect(handle.state.downloads, isEmpty);

    rust.emit(event(AppEventKind.godotDownloadQueued, text: '4.5-beta1'));
    rust.emit(event(AppEventKind.godotDownloadError, failure: const DownloadFailure(tag: '4.5-beta1', message: 'checksum')));
    await settle();
    expect(handle.state.downloads, isEmpty);
    expect(handle.state.downloadError?.message, 'checksum');
    expect(handle.state.downloadError?.tag, '4.5-beta1');
    expect(handle.state.downloadError?.source, 'github');
    handle.notifier.dismissDownloadError();
    expect(handle.state.downloadError, isNull);

    final before = rust.callCount(_installed);
    rust.emit(event(AppEventKind.godotDownloadQueued, text: '4.4-stable'));
    rust.emit(event(AppEventKind.godotDownloadComplete, text: '4.4-stable'));
    await settle();
    expect(handle.state.downloads, isEmpty);
    expect(rust.callCount(_installed), before + 1);
  });

  test('scan progress events feed the version scan progress provider', () async {
    final handle = start();
    rust.emit(fakeEvent(AppEventKind.versionScanProgress, scanProgress: const ScanProgress(current: 2, total: 5)));
    await settle();
    expect(handle.container.read(versionScanProgressProvider), const ScanProgress(current: 2, total: 5));
  });

  test('downloads go through the backend and report failures with their parameters', () async {
    var failDownload = false;
    rust.on('crateApiGodotVersionsDownloadGodotVersion', ({
      required String tag,
      required String assetName,
      required String downloadUrl,
    }) async {
      calls.add('download:$tag:$assetName');
      if (failDownload) throw StateError('offline');
    });
    final handle = start();
    await settle();

    await handle.notifier.download('4.4-stable', 'Godot_v4.4-stable_mono_win64.zip', 'https://x/mono');
    expect(calls.last, 'download:4.4-stable:Godot_v4.4-stable_mono_win64.zip');
    expect(handle.state.downloads['4.4-stable-mono']?.status, DownloadStatus.queued);

    failDownload = true;
    await handle.notifier.download('4.3-stable', 'Godot_v4.3-stable_win64.zip', 'https://x/std');
    expect(handle.state.downloads.containsKey('4.3-stable'), isFalse);
    expect(handle.state.downloadError?.url, 'https://x/std');
    expect(handle.state.downloadError?.message, contains('offline'));

    failDownload = false;
    await handle.notifier.retryDownload();
    expect(handle.state.downloadError, isNull);
    expect(calls.last, 'download:4.3-stable:Godot_v4.3-stable_win64.zip');

    rust.emit(event(AppEventKind.godotDownloadError, failure: const DownloadFailure(tag: '4.3-stable', message: 'disk')));
    await settle();
    expect(handle.state.downloadError?.assetName, 'Godot_v4.3-stable_win64.zip');
    expect(handle.state.downloadError?.url, 'https://x/std');
  });

  test('downloads use mise when use_mise is on and mise is available, except for prereleases and mono builds', () async {
    final gate = Completer<List<InstalledGodotVersion>>();
    var failMise = false;
    rust.on('crateApiMiseMiseInstallGodotVersion', ({required String tag}) {
      calls.add('mise:$tag');
      if (failMise) return Future<List<InstalledGodotVersion>>.error(StateError('mise broke'));
      return gate.future;
    });
    rust.on('crateApiGodotVersionsDownloadGodotVersion', ({
      required String tag,
      required String assetName,
      required String downloadUrl,
    }) async {
      calls.add('download:$tag');
    });
    backend.settings = settingsWith(useMise: true);
    final handle = start();
    await settle();
    calls.clear();

    final installing = handle.notifier.download('4.4-stable', 'Godot_v4.4-stable_win64.zip', 'u');
    await settle();
    expect(handle.state.miseInstalls, {'4.4-stable': true});
    final before = rust.callCount(_installed);
    gate.complete(const []);
    await installing;
    expect(handle.state.miseInstalls, isEmpty);
    expect(rust.callCount(_installed), before + 1);

    await handle.notifier.download('4.5-beta1', 'Godot_v4.5-beta1_win64.zip', 'u');
    await handle.notifier.download('4.4-stable', 'Godot_v4.4-stable_mono_win64.zip', 'u');
    expect(calls, ['mise:4.4-stable', 'download:4.5-beta1', 'download:4.4-stable']);

    failMise = true;
    await handle.notifier.download('4.3-stable', 'Godot_v4.3-stable_win64.zip', 'u');
    expect(handle.state.downloadError?.source, 'mise');
    expect(handle.state.miseInstalls, isEmpty);
  });

  test('a mise source falls back to github once settings load with use_mise off', () async {
    UiPrefsStore.instance.setItem(versionSourceKey, 'mise');
    final handle = start();
    await settle();
    expect(handle.state.source, VersionSource.github);
    expect(calls, contains('available:github'));
    expect(UiPrefsStore.instance.getItem(versionSourceKey), 'github');
  });

  test('toggling use_mise refreshes the mise status', () async {
    final handle = start();
    await settle();
    final before = rust.callCount(_mise);
    miseAvailable = false;
    await handle.container.read(settingsProvider.notifier).save(settingsWith(useMise: true));
    await settle();
    expect(rust.callCount(_mise), before + 1);
    expect(handle.state.miseStatus?.available, isFalse);
  });

  test('cancel, remove, sync, rename, current and alias actions', () async {
    rust.on('crateApiGodotVersionsCancelDownload', ({required String key}) async => calls.add('cancel:$key'));
    rust.on('crateApiGodotVersionsDeleteGodotVersion', ({required String tag}) async => calls.add('delete:$tag'));
    rust.on('crateApiMiseMiseUninstallGodotVersion', ({required String tag}) async => calls.add('uninstall:$tag'));
    rust.on('crateApiMiseMiseSyncGodotVersions', () async {
      calls.add('sync');
      return const <InstalledGodotVersion>[];
    });
    rust.on('crateApiGodotVersionsRenameGodotVersion', ({required String tag, String? customName}) async {
      return installed(tag, customName: customName);
    });
    rust.on('crateApiCurrentVersionSetCurrentVersion', ({required String tag}) async => currentInfo(tag));
    rust.on('crateApiCurrentVersionClearCurrentVersion', () async => calls.add('clear'));
    rust.on('crateApiCurrentVersionCreateVersionAliases', ({required List<AliasRequest> entries}) async {
      serverAliases = [...serverAliases, for (final entry in entries) alias(entry.name)];
      return AliasBatchResult(created: [for (final entry in entries) alias(entry.name)], skipped: const []);
    });
    rust.on('crateApiCurrentVersionDeleteVersionAlias', ({required String name}) async {
      serverAliases = [for (final a in serverAliases) if (a.name != name) a];
    });
    serverInstalled = [installed('4.3-stable'), installed('4.4-stable', managedBy: 'mise')];
    final handle = start();
    await settle();
    final notifier = handle.notifier;
    calls.clear();

    rust.emit(event(AppEventKind.godotDownloadQueued, text: '4.5'));
    await settle();
    await notifier.cancel('4.5');
    expect(handle.state.downloads, isEmpty);

    await notifier.remove('4.3-stable');
    await notifier.remove('4.4-stable');
    await notifier.syncMise();
    expect(calls, ['cancel:4.5', 'delete:4.3-stable', 'uninstall:4.4-stable', 'sync']);

    final renamed = await notifier.rename('4.3-stable', 'Main');
    expect(renamed.customName, 'Main');
    expect(handle.state.installed.first.customName, 'Main');

    expect((await notifier.setCurrent('4.4-stable')).tag, '4.4-stable');
    expect(handle.state.current?.tag, '4.4-stable');
    await notifier.clearCurrent();
    expect(handle.state.current, isNull);

    final result = await notifier.createAliases(const [AliasRequest(name: 'g5', tag: '4.4-stable')]);
    expect(result.created.map((a) => a.name), ['g5']);
    expect(handle.state.aliases.map((a) => a.name), ['godot4', 'g5']);
    await notifier.deleteAlias('godot4');
    expect(handle.state.aliases.map((a) => a.name), ['g5']);
  });

  testWidgets('resuming the app shortly after a refresh does not refetch installed versions', (tester) async {
    final handle = start();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    final before = rust.callCount(_installed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(rust.callCount(_installed), before);
    expect(handle.state.installed, isNotEmpty);
  });
}

class ProviderContainerHandle {
  ProviderContainerHandle(this.container);

  final ProviderContainer container;

  GodotVersionsState get state => container.read(godotVersionsProvider);

  GodotVersionsNotifier get notifier => container.read(godotVersionsProvider.notifier);
}
