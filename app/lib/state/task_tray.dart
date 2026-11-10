import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/events.dart';
import '../api/versions.dart';
import '../i18n/i18n.dart';
import '../ui/feedback/toast.dart';
import 'api_data.dart';
import 'settings.dart';

enum TaskType {
  downloadGodot('download-godot'),
  downloadTemplates('download-templates'),
  downloadAsset('download-asset'),
  scanProjects('scan-projects'),
  scanVersions('scan-versions'),
  syncTemplates('sync-templates'),
  cloneRepo('clone-repo'),
  importProjects('import-projects'),
  importVersions('import-versions');

  const TaskType(this.id);

  final String id;
}

enum TaskStatus {
  queued,
  running,
  paused,
  completed,
  error;

  bool get active => this == queued || this == running;

  bool get dismissible => !active;
}

@immutable
class TaskProgress {
  const TaskProgress(this.current, this.total);

  final int current;
  final int total;

  double? get fraction => total > 0 ? (current / total).clamp(0, 1).toDouble() : null;

  @override
  bool operator ==(Object other) => other is TaskProgress && other.current == current && other.total == total;

  @override
  int get hashCode => Object.hash(current, total);

  @override
  String toString() => 'TaskProgress($current/$total)';
}

@immutable
class TrayTask {
  const TrayTask({
    required this.id,
    required this.type,
    required this.label,
    this.description,
    this.progress,
    required this.status,
    this.errorMessage,
  });

  final String id;
  final TaskType type;
  final String label;
  final String? description;
  final TaskProgress? progress;
  final TaskStatus status;
  final String? errorMessage;

  String? get downloadKey => type == TaskType.downloadGodot && id.startsWith('download-') ? id.substring(9) : null;

  String? get templateTag => type == TaskType.downloadTemplates && id.startsWith('templates-') ? id.substring(10) : null;

  TrayTask copyWith({
    String? label,
    String? description,
    TaskProgress? progress,
    TaskStatus? status,
    String? errorMessage,
  }) => TrayTask(
    id: id,
    type: type,
    label: label ?? this.label,
    description: description ?? this.description,
    progress: progress ?? this.progress,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  bool operator ==(Object other) =>
      other is TrayTask &&
      other.id == id &&
      other.type == type &&
      other.label == label &&
      other.description == description &&
      other.progress == progress &&
      other.status == status &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(id, type, label, description, progress, status, errorMessage);

  @override
  String toString() => 'TrayTask($id, ${status.name}, $label)';
}

const taskRemovalDelay = Duration(milliseconds: 4000);
const taskCompletedRemovalDelay = Duration(milliseconds: 3000);
const taskErrorRemovalDelay = Duration(milliseconds: 6000);
const taskTrayEmptyAutoClose = Duration(milliseconds: 2000);

String _mb(BigInt bytes) => (bytes.toDouble() / 1024 / 1024).toStringAsFixed(1);

int _pct(BigInt downloaded, BigInt total) => total > BigInt.zero ? (downloaded.toDouble() / total.toDouble() * 100).round() : 0;

String transferDescription(BigInt downloaded, BigInt total) => total > BigInt.zero
    ? '${_mb(downloaded)} / ${_mb(total)} MB (${_pct(downloaded, total)}%)'
    : '${_mb(downloaded)} MB';

TaskProgress? _transferProgress(BigInt downloaded, BigInt total) =>
    total > BigInt.zero ? TaskProgress(downloaded.toInt(), total.toInt()) : null;

String godotDownloadTaskId(String key) => 'download-$key';

String templatesTaskId(String tag) => 'templates-$tag';

String assetTaskId(String assetId) => 'download-asset-$assetId';

const _events = {
  AppEventKind.projectScanProgress,
  AppEventKind.versionScanProgress,
  AppEventKind.godotDownloadQueued,
  AppEventKind.godotDownloadProgress,
  AppEventKind.godotDownloadPaused,
  AppEventKind.godotDownloadCanceled,
  AppEventKind.godotDownloadQueue,
  AppEventKind.godotDownloadError,
  AppEventKind.godotDownloadComplete,
  AppEventKind.exportTemplatesQueued,
  AppEventKind.exportTemplatesProgress,
  AppEventKind.exportTemplatesStage,
  AppEventKind.exportTemplatesCanceled,
  AppEventKind.exportTemplatesError,
  AppEventKind.exportTemplatesComplete,
  AppEventKind.assetDownloadQueued,
  AppEventKind.assetDownloadProgress,
  AppEventKind.assetDownloadError,
  AppEventKind.assetDownloadComplete,
};

final taskTrayProvider = NotifierProvider<TaskTrayNotifier, List<TrayTask>>(TaskTrayNotifier.new);

final taskTrayActiveCountProvider = Provider<int>(
  (ref) => ref.watch(taskTrayProvider).where((task) => task.status.active).length,
);

final taskTrayDismissibleCountProvider = Provider<int>(
  (ref) => ref.watch(taskTrayProvider).where((task) => task.status.dismissible).length,
);

class TaskTrayNotifier extends Notifier<List<TrayTask>> {
  final Map<String, Timer> _timers = {};

  @override
  List<TrayTask> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    ref.listenAppEvents(_events, _onEvent);
    return const [];
  }

  int get activeCount => state.where((task) => task.status.active).length;

  void _clearTimer(String id) => _timers.remove(id)?.cancel();

  void scheduleRemoval(String id, [Duration delay = taskRemovalDelay]) {
    _clearTimer(id);
    _timers[id] = Timer(delay, () {
      _timers.remove(id);
      if (ref.mounted) state = state.where((task) => task.id != id).toList(growable: false);
    });
  }

  void registerTask(TrayTask task) {
    final exists = state.any((existing) => existing.id == task.id);
    state = exists
        ? [for (final existing in state) existing.id == task.id ? task : existing]
        : [...state, task];
  }

  void updateTask(
    String id, {
    String? label,
    String? description,
    TaskProgress? progress,
    TaskStatus? status,
    String? errorMessage,
  }) {
    state = [
      for (final task in state)
        task.id == id
            ? task.copyWith(
                label: label,
                description: description,
                progress: progress,
                status: status,
                errorMessage: errorMessage,
              )
            : task,
    ];
  }

  void unregisterTask(String id) {
    _clearTimer(id);
    state = state.where((task) => task.id != id).toList(growable: false);
  }

  void clearCompleted() {
    state = state.where((task) => task.status.active || task.status == TaskStatus.paused).toList(growable: false);
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void reorderQueue(List<String> keys) {
    final ordered = [for (final key in keys) godotDownloadTaskId(key)];
    final ids = ordered.toSet();
    final byId = {for (final task in state) task.id: task};
    final rest = [for (final task in state) if (!ids.contains(task.id)) task.id];
    state = [
      for (final id in [...ordered, ...rest])
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      reportError(error);
    }
  }

  Future<void> pauseDownload(String key) => _guard(() => VersionsApi.pauseDownload(key));

  Future<void> resumeDownload(String key) => _guard(() => VersionsApi.resumeDownload(key));

  Future<void> cancelDownload(String key) => _guard(() => VersionsApi.cancelDownload(key));

  Future<void> moveDownload(String key, int direction) => _guard(() => VersionsApi.reorderDownloadQueue(key, direction));

  Future<void> cancelTemplates(String tag) => _guard(() => VersionsApi.cancelExportTemplates(tag));

  void _scan(String id, TaskType type, String label, ScanProgress? progress) {
    if (progress == null) return;
    final current = progress.current;
    final total = progress.total;
    if (current < total) {
      registerTask(
        TrayTask(
          id: id,
          type: type,
          label: label,
          description: total > 0 ? '$current / $total' : null,
          progress: TaskProgress(current, total),
          status: TaskStatus.running,
        ),
      );
    } else if (total > 0) {
      updateTask(id, status: TaskStatus.completed, progress: TaskProgress(current, total));
      scheduleRemoval(id);
    }
  }

  String _godotLabel(String key) => t.common.downloading_version.args({'version': key});

  String _templateLabel(String tag) => t.common.downloading_export_templates.args({'tag': tag});

  String _assetLabel(String title) => t.common.downloading_asset.args({'title': title});

  void _onEvent(AppEvent event) {
    switch (event.kind) {
      case AppEventKind.projectScanProgress:
        _scan('scan-projects', TaskType.scanProjects, t.common.scanning_projects, event.scanProgress);
      case AppEventKind.versionScanProgress:
        _scan('scan-versions', TaskType.scanVersions, t.common.scanning_versions, event.scanProgress);
      case AppEventKind.godotDownloadQueued:
        final key = event.text;
        if (key == null) return;
        registerTask(
          TrayTask(
            id: godotDownloadTaskId(key),
            type: TaskType.downloadGodot,
            label: _godotLabel(key),
            description: t.common.queued,
            status: TaskStatus.queued,
          ),
        );
      case AppEventKind.godotDownloadProgress:
        final payload = event.downloadProgress;
        if (payload == null) return;
        registerTask(
          TrayTask(
            id: godotDownloadTaskId(payload.tag),
            type: TaskType.downloadGodot,
            label: _godotLabel(payload.tag),
            description: transferDescription(payload.downloaded, payload.total),
            progress: _transferProgress(payload.downloaded, payload.total),
            status: TaskStatus.running,
          ),
        );
      case AppEventKind.godotDownloadPaused:
        final key = event.text;
        if (key != null) updateTask(godotDownloadTaskId(key), status: TaskStatus.paused);
      case AppEventKind.godotDownloadCanceled:
        final key = event.text;
        if (key != null) unregisterTask(godotDownloadTaskId(key));
      case AppEventKind.godotDownloadQueue:
        final keys = event.queue;
        if (keys != null) reorderQueue(keys);
      case AppEventKind.godotDownloadError:
        final payload = event.downloadFailure;
        if (payload == null) return;
        final id = godotDownloadTaskId(payload.tag);
        updateTask(id, status: TaskStatus.error, errorMessage: payload.message);
        scheduleRemoval(id, taskErrorRemovalDelay);
      case AppEventKind.godotDownloadComplete:
        final key = event.text;
        if (key == null) return;
        final id = godotDownloadTaskId(key);
        updateTask(id, status: TaskStatus.completed);
        scheduleRemoval(id, taskCompletedRemovalDelay);
      case AppEventKind.exportTemplatesQueued:
        final tag = event.text;
        if (tag == null) return;
        registerTask(
          TrayTask(
            id: templatesTaskId(tag),
            type: TaskType.downloadTemplates,
            label: _templateLabel(tag),
            description: t.common.queued,
            status: TaskStatus.queued,
          ),
        );
      case AppEventKind.exportTemplatesProgress:
        final payload = event.exportTemplatesProgress;
        if (payload == null) return;
        final file = payload.file;
        registerTask(
          TrayTask(
            id: templatesTaskId(payload.tag),
            type: TaskType.downloadTemplates,
            label: _templateLabel(payload.tag),
            description: [
              if (payload.platforms.isNotEmpty) payload.platforms.join(', '),
              if (file != null && file.isNotEmpty) file,
              transferDescription(payload.downloaded, payload.total),
            ].join(' · '),
            progress: _transferProgress(payload.downloaded, payload.total),
            status: TaskStatus.running,
          ),
        );
      case AppEventKind.exportTemplatesStage:
        final payload = event.exportTemplatesStage;
        if (payload == null) return;
        updateTask(
          templatesTaskId(payload.tag),
          description: payload.stage == 'verifying' ? t.common.export_templates_verifying : t.common.export_templates_extracting,
        );
      case AppEventKind.exportTemplatesCanceled:
        final tag = event.text;
        if (tag != null) unregisterTask(templatesTaskId(tag));
      case AppEventKind.exportTemplatesError:
        final payload = event.exportTemplatesError;
        if (payload == null) return;
        final id = templatesTaskId(payload.tag);
        updateTask(id, status: TaskStatus.error, errorMessage: payload.message);
        scheduleRemoval(id, taskErrorRemovalDelay);
      case AppEventKind.exportTemplatesComplete:
        final tag = event.text;
        if (tag == null) return;
        final id = templatesTaskId(tag);
        updateTask(id, status: TaskStatus.completed);
        scheduleRemoval(id, taskCompletedRemovalDelay);
      case AppEventKind.assetDownloadQueued:
        final payload = event.assetDownloadProgress;
        if (payload == null) return;
        registerTask(
          TrayTask(
            id: assetTaskId(payload.assetId),
            type: TaskType.downloadAsset,
            label: _assetLabel(payload.title),
            description: t.common.queued,
            status: TaskStatus.queued,
          ),
        );
      case AppEventKind.assetDownloadProgress:
        final payload = event.assetDownloadProgress;
        if (payload == null) return;
        registerTask(
          TrayTask(
            id: assetTaskId(payload.assetId),
            type: TaskType.downloadAsset,
            label: _assetLabel(payload.title),
            description: transferDescription(payload.downloaded, payload.total),
            progress: _transferProgress(payload.downloaded, payload.total),
            status: TaskStatus.running,
          ),
        );
      case AppEventKind.assetDownloadError:
        final payload = event.assetDownloadError;
        if (payload == null) return;
        final id = assetTaskId(payload.assetId);
        registerTask(
          TrayTask(
            id: id,
            type: TaskType.downloadAsset,
            label: payload.title.isNotEmpty ? _assetLabel(payload.title) : t.common.asset_download_failed,
            status: TaskStatus.error,
            errorMessage: payload.message,
          ),
        );
        scheduleRemoval(id, taskErrorRemovalDelay);
      case AppEventKind.assetDownloadComplete:
        final payload = event.assetDownloadProgress;
        if (payload == null) return;
        final id = assetTaskId(payload.assetId);
        updateTask(id, status: TaskStatus.completed);
        scheduleRemoval(id, taskCompletedRemovalDelay);
        if (ref.read(settingsProvider).value?.desktopNotificationsEnabled ?? false) {
          Api.notify('GodotHub', t.common.notification_asset_installed.args({'title': payload.title})).catchError((Object _) {});
        }
      default:
        break;
    }
  }
}
