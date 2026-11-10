import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/events.dart';
import '../api/mise.dart';
import '../api/versions.dart';
import '../i18n/i18n.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import 'api_data.dart';
import 'app_lifecycle.dart';
import 'scan_progress.dart';
import 'settings.dart';
import 'workspaces.dart';

const String versionSourceKey = 'godothub_version_source';
const Duration installedRefreshInterval = Duration(seconds: 15);
const Duration availableRefreshInterval = Duration(minutes: 10);

enum VersionSource {
  github('github'),
  archive('archive'),
  mise('mise');

  const VersionSource(this.id);

  final String id;

  static VersionSource? fromId(String? id) {
    for (final source in values) {
      if (source.id == id) return source;
    }
    return null;
  }
}

enum DownloadStatus { queued, downloading, paused }

@immutable
class DownloadState {
  const DownloadState({required this.tag, required this.downloaded, required this.total, required this.status});

  final String tag;
  final int downloaded;
  final int total;
  final DownloadStatus status;

  DownloadState withStatus(DownloadStatus next) =>
      DownloadState(tag: tag, downloaded: downloaded, total: total, status: next);

  @override
  bool operator ==(Object other) =>
      other is DownloadState &&
      other.tag == tag &&
      other.downloaded == downloaded &&
      other.total == total &&
      other.status == status;

  @override
  int get hashCode => Object.hash(tag, downloaded, total, status);
}

@immutable
class DownloadErrorInfo {
  const DownloadErrorInfo({
    required this.key,
    required this.tag,
    required this.assetName,
    required this.url,
    required this.source,
    required this.message,
  });

  final String key;
  final String tag;
  final String assetName;
  final String url;
  final String source;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DownloadErrorInfo &&
      other.key == key &&
      other.tag == tag &&
      other.assetName == assetName &&
      other.url == url &&
      other.source == source &&
      other.message == message;

  @override
  int get hashCode => Object.hash(key, tag, assetName, url, source, message);
}

@immutable
class GodotVersionsState {
  const GodotVersionsState({
    this.installed = const [],
    this.current,
    this.aliases = const [],
    this.aliasesDir = '',
    this.exportTemplates,
    this.available = const [],
    this.loadingAvailable = false,
    this.availableError,
    this.source = VersionSource.github,
    this.miseStatus,
    this.miseInstalls = const {},
    this.downloads = const {},
    this.downloadError,
  });

  final List<InstalledGodotVersion> installed;
  final CurrentVersionInfo? current;
  final List<AliasInfo> aliases;
  final String aliasesDir;
  final ExportTemplatesState? exportTemplates;
  final List<GodotRelease> available;
  final bool loadingAvailable;
  final String? availableError;
  final VersionSource source;
  final MiseStatus? miseStatus;
  final Map<String, bool> miseInstalls;
  final Map<String, DownloadState> downloads;
  final DownloadErrorInfo? downloadError;

  GodotVersionsState copyWith({
    List<InstalledGodotVersion>? installed,
    ValueGetter<CurrentVersionInfo?>? current,
    List<AliasInfo>? aliases,
    String? aliasesDir,
    ValueGetter<ExportTemplatesState?>? exportTemplates,
    List<GodotRelease>? available,
    bool? loadingAvailable,
    ValueGetter<String?>? availableError,
    VersionSource? source,
    ValueGetter<MiseStatus?>? miseStatus,
    Map<String, bool>? miseInstalls,
    Map<String, DownloadState>? downloads,
    ValueGetter<DownloadErrorInfo?>? downloadError,
  }) => GodotVersionsState(
    installed: installed ?? this.installed,
    current: current != null ? current() : this.current,
    aliases: aliases ?? this.aliases,
    aliasesDir: aliasesDir ?? this.aliasesDir,
    exportTemplates: exportTemplates != null ? exportTemplates() : this.exportTemplates,
    available: available ?? this.available,
    loadingAvailable: loadingAvailable ?? this.loadingAvailable,
    availableError: availableError != null ? availableError() : this.availableError,
    source: source ?? this.source,
    miseStatus: miseStatus != null ? miseStatus() : this.miseStatus,
    miseInstalls: miseInstalls ?? this.miseInstalls,
    downloads: downloads ?? this.downloads,
    downloadError: downloadError != null ? downloadError() : this.downloadError,
  );
}

String downloadKeyOf(String tag, String assetName) => assetName.toLowerCase().contains('mono') ? '$tag-mono' : tag;

final RegExp _prereleaseTag = RegExp('(alpha|beta|rc|dev)', caseSensitive: false);

bool isPrereleaseTag(String tag) => _prereleaseTag.hasMatch(tag);

bool _sameTemplates(ExportTemplatesState? a, ExportTemplatesState b) =>
    a != null && a.defaultDir == b.defaultDir && listEquals(a.versions, b.versions) && listEquals(a.orphans, b.orphans);

typedef _DownloadParams = ({String tag, String assetName, String url, String source});

final godotVersionsProvider = NotifierProvider<GodotVersionsNotifier, GodotVersionsState>(GodotVersionsNotifier.new);

final versionScanProgressProvider = NotifierProvider<ScanProgressNotifier, ScanProgress?>(
  () => ScanProgressNotifier(AppEventKind.versionScanProgress),
);

class GodotVersionsNotifier extends Notifier<GodotVersionsState> {
  int _availableRequest = 0;
  final Map<String, _DownloadParams> _downloadParams = {};
  DateTime _lastInstalledRefresh = DateTime.now();
  DateTime _lastAvailableCheck = DateTime.now();

  @override
  GodotVersionsState build() {
    final source = VersionSource.fromId(UiPrefsStore.instance.getItem(versionSourceKey)) ?? VersionSource.github;
    _lastInstalledRefresh = DateTime.now();
    _lastAvailableCheck = DateTime.now();

    ref.listen(activeWorkspaceIdProvider, (_, _) {
      _lastInstalledRefresh = DateTime.now();
      refreshInstalled().ignore();
      unawaited(refreshAvailable());
    });
    ref.listen(settingsProvider.select((value) => value.value?.useMise ?? false), (_, _) {
      unawaited(refreshMiseStatus());
    });
    ref.listen(settingsProvider.select((value) => (loaded: value.hasValue, useMise: value.value?.useMise ?? false)), (
      _,
      next,
    ) {
      _fallbackFromMise(next.loaded, next.useMise);
    });
    ref.listenAppResumed(_onResumed);

    ref.listenAppEvent(AppEventKind.versionsAvailableUpdated, (event) {
      if (event.text == state.source.id) unawaited(_reloadAvailableQuietly());
    });
    ref.listenAppEvent(AppEventKind.versionScanDone, (_) => refreshInstalled().ignore());
    ref.listenAppEvent(AppEventKind.versionsAliasesChanged, (_) => unawaited(refreshAliases()));
    ref.listenAppEvent(AppEventKind.godotDownloadQueued, (event) {
      final key = event.text;
      if (key == null) return;
      final previous = state.downloads[key];
      _setDownloads({
        ...state.downloads,
        key: DownloadState(
          tag: key,
          downloaded: previous?.downloaded ?? 0,
          total: previous?.total ?? 0,
          status: DownloadStatus.queued,
        ),
      });
    });
    ref.listenAppEvent(AppEventKind.godotDownloadProgress, (event) {
      final progress = event.downloadProgress;
      if (progress == null) return;
      _setDownloads({
        ...state.downloads,
        progress.tag: DownloadState(
          tag: progress.tag,
          downloaded: progress.downloaded.toInt(),
          total: progress.total.toInt(),
          status: DownloadStatus.downloading,
        ),
      });
    });
    ref.listenAppEvent(AppEventKind.godotDownloadPaused, (event) {
      final previous = state.downloads[event.text];
      if (previous == null) return;
      _setDownloads({...state.downloads, event.text!: previous.withStatus(DownloadStatus.paused)});
    });
    ref.listenAppEvent(AppEventKind.godotDownloadCanceled, (event) {
      final key = event.text;
      if (key != null) _clearKey(key);
    });
    ref.listenAppEvent(AppEventKind.godotDownloadError, (event) {
      final failure = event.downloadFailure;
      if (failure == null) return;
      _clearKey(failure.tag);
      final params = _downloadParams[failure.tag];
      state = state.copyWith(
        downloadError: () => DownloadErrorInfo(
          key: failure.tag,
          tag: params?.tag ?? failure.tag,
          assetName: params?.assetName ?? '',
          url: params?.url ?? '',
          source: params?.source ?? state.source.id,
          message: failure.message,
        ),
      );
    });
    ref.listenAppEvent(AppEventKind.godotDownloadComplete, (event) {
      final key = event.text;
      if (key == null) return;
      _clearKey(key);
      refreshInstalled().ignore();
      if (ref.read(settingsProvider).value?.desktopNotificationsEnabled ?? defaultSettings.desktopNotificationsEnabled) {
        Api.notify('GodotHub', ghTr('common:notification_version_installed', args: {'tag': key})).ignore();
      }
    });

    scheduleMicrotask(() {
      if (!ref.mounted) return;
      refreshInstalled().ignore();
      unawaited(refreshAvailable());
      unawaited(refreshMiseStatus());
      final settings = ref.read(settingsProvider);
      _fallbackFromMise(settings.hasValue, settings.value?.useMise ?? false);
    });

    return GodotVersionsState(source: source);
  }

  void _set(GodotVersionsState Function(GodotVersionsState previous) update) {
    if (ref.mounted) state = update(state);
  }

  void _setDownloads(Map<String, DownloadState> downloads) => _set((s) => s.copyWith(downloads: downloads));

  void _clearKey(String key) {
    _set((s) => s.copyWith(downloads: {...s.downloads}..remove(key)));
  }

  void _setSource(VersionSource source) {
    _set((s) => s.copyWith(source: source));
    UiPrefsStore.instance.setItem(versionSourceKey, source.id);
  }

  void _fallbackFromMise(bool loaded, bool useMise) {
    if (loaded && state.source == VersionSource.mise && !useMise) {
      unawaited(refreshAvailable(VersionSource.github));
    }
  }

  void _onResumed() {
    final now = DateTime.now();
    if (now.difference(_lastInstalledRefresh) >= installedRefreshInterval) {
      _lastInstalledRefresh = now;
      refreshInstalled().ignore();
    }
    if (now.difference(_lastAvailableCheck) >= availableRefreshInterval) {
      _lastAvailableCheck = now;
      if (state.source != VersionSource.mise) unawaited(_reloadAvailableQuietly());
    }
  }

  Future<void> refreshCurrent() async {
    try {
      final next = await VersionsApi.getCurrent();
      _set((s) => s.current == next ? s : s.copyWith(current: () => next));
    } catch (_) {
      _set((s) => s.current == null ? s : s.copyWith(current: () => null));
    }
  }

  Future<void> refreshAliases() async {
    try {
      final next = await VersionsApi.listAliases();
      _set(
        (s) => s.copyWith(
          aliases: listEquals(s.aliases, next.aliases) ? s.aliases : next.aliases,
          aliasesDir: next.aliasesDir,
        ),
      );
    } catch (_) {
      _set((s) => s.aliases.isEmpty ? s : s.copyWith(aliases: const []));
    }
  }

  Future<void> refreshExportTemplates() async {
    try {
      final next = await VersionsApi.exportTemplatesState();
      _set((s) => _sameTemplates(s.exportTemplates, next) ? s : s.copyWith(exportTemplates: () => next));
    } catch (_) {}
  }

  Future<void> refreshInstalled() async {
    final installedRequest = VersionsApi.listInstalled();
    final templates = refreshExportTemplates();
    final next = await installedRequest;
    await templates;
    _set((s) => listEquals(s.installed, next) ? s : s.copyWith(installed: next));
    await Future.wait([refreshCurrent(), refreshAliases()]);
  }

  Future<void> refreshMiseStatus() async {
    try {
      final status = await MiseApi.refreshStatus();
      _set((s) => s.copyWith(miseStatus: () => status));
    } catch (_) {
      _set((s) => s.copyWith(miseStatus: () => null));
    }
  }

  Future<void> refreshAvailable([VersionSource? source]) async {
    final next = source ?? state.source;
    _setSource(next);
    final request = ++_availableRequest;
    _set((s) => s.copyWith(loadingAvailable: true, availableError: () => null));
    try {
      final list = await VersionsApi.fetchAvailable(next.id);
      if (request == _availableRequest) _set((s) => s.copyWith(available: list));
    } catch (error) {
      if (request == _availableRequest) _set((s) => s.copyWith(availableError: () => '$error'));
    } finally {
      if (request == _availableRequest) _set((s) => s.copyWith(loadingAvailable: false));
    }
  }

  Future<void> _reloadAvailableQuietly() async {
    final current = state.source;
    try {
      final releases = await VersionsApi.fetchAvailable(current.id);
      if (ref.mounted && state.source == current) _set((s) => s.copyWith(available: releases));
    } catch (_) {}
  }

  void _setError(DownloadErrorInfo info) => _set((s) => s.copyWith(downloadError: () => info));

  Future<void> download(String tag, String assetName, String url) async {
    final key = downloadKeyOf(tag, assetName);
    final useMise = ref.read(settingsProvider).value?.useMise ?? defaultSettings.useMise;
    final viaMise =
        !assetName.toLowerCase().contains('mono') &&
        (state.source == VersionSource.mise ||
            (useMise && (state.miseStatus?.available ?? false) && !isPrereleaseTag(tag)));

    if (viaMise) {
      _set((s) => s.copyWith(miseInstalls: {...s.miseInstalls, key: true}));
      try {
        await MiseApi.install(tag);
      } catch (error) {
        _setError(
          DownloadErrorInfo(key: key, tag: tag, assetName: assetName, url: url, source: 'mise', message: '$error'),
        );
        return;
      } finally {
        _set((s) => s.copyWith(miseInstalls: {...s.miseInstalls}..remove(key)));
      }
      await refreshInstalled();
      return;
    }

    _downloadParams[key] = (tag: tag, assetName: assetName, url: url, source: state.source.id);
    _setDownloads({
      ...state.downloads,
      key: DownloadState(tag: key, downloaded: 0, total: 0, status: DownloadStatus.queued),
    });
    try {
      await VersionsApi.download(tag, assetName, url);
    } catch (error) {
      _clearKey(key);
      _setError(
        DownloadErrorInfo(
          key: key,
          tag: tag,
          assetName: assetName,
          url: url,
          source: state.source.id,
          message: '$error',
        ),
      );
    }
  }

  void dismissDownloadError() => _set((s) => s.copyWith(downloadError: () => null));

  Future<void> retryDownload() async {
    final info = state.downloadError;
    if (info == null) return;
    dismissDownloadError();
    await download(info.tag, info.assetName, info.url);
  }

  Future<void> pause(String key) => VersionsApi.pauseDownload(key);

  Future<void> resume(String key) => VersionsApi.resumeDownload(key);

  Future<void> cancel(String key) async {
    await VersionsApi.cancelDownload(key);
    _clearKey(key);
  }

  Future<void> remove(String tag) async {
    InstalledGodotVersion? target;
    for (final version in state.installed) {
      if (version.tag == tag) {
        target = version;
        break;
      }
    }
    if (target?.managedBy == 'mise') {
      await MiseApi.uninstall(tag);
    } else {
      await VersionsApi.delete(tag);
    }
    await refreshInstalled();
  }

  Future<void> syncMise() async {
    await MiseApi.syncVersions();
    await refreshInstalled();
  }

  Future<InstalledGodotVersion> rename(String tag, String? customName) async {
    final updated = await VersionsApi.rename(tag, customName);
    _set((s) => s.copyWith(installed: [for (final v in s.installed) v.tag == tag ? updated : v]));
    return updated;
  }

  Future<CurrentVersionInfo> setCurrent(String tag) async {
    final info = await VersionsApi.setCurrent(tag);
    _set((s) => s.copyWith(current: () => info));
    return info;
  }

  Future<void> clearCurrent() async {
    await VersionsApi.clearCurrent();
    _set((s) => s.copyWith(current: () => null));
  }

  Future<AliasBatchResult> createAliases(List<AliasRequest> entries) async {
    final result = await VersionsApi.createAliases(entries);
    await refreshAliases();
    return result;
  }

  Future<void> deleteAlias(String name) async {
    await VersionsApi.deleteAlias(name);
    await refreshAliases();
  }
}
