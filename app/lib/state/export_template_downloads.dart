import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/versions.dart';
import '../i18n/i18n.dart';
import '../logic/export_template_catalog.dart';
import '../ui/feedback/toast.dart';
import 'api_data.dart';

@immutable
class ExportTemplateDownload {
  const ExportTemplateDownload({
    required this.downloaded,
    required this.total,
    required this.stage,
    this.file,
    this.platforms,
  });

  final int downloaded;
  final int total;
  final String stage;
  final String? file;
  final List<String>? platforms;

  ExportTemplateDownload withStage(String next) =>
      ExportTemplateDownload(downloaded: downloaded, total: total, stage: next, file: file, platforms: platforms);

  @override
  bool operator ==(Object other) =>
      other is ExportTemplateDownload &&
      other.downloaded == downloaded &&
      other.total == total &&
      other.stage == stage &&
      other.file == file &&
      listEquals(other.platforms, platforms);

  @override
  int get hashCode => Object.hash(downloaded, total, stage, file, platforms == null ? null : Object.hashAll(platforms!));
}

final exportTemplateDownloadsProvider =
    NotifierProvider<ExportTemplateDownloadsNotifier, Map<String, ExportTemplateDownload>>(
      ExportTemplateDownloadsNotifier.new,
    );

class ExportTemplateDownloadsNotifier extends Notifier<Map<String, ExportTemplateDownload>> {
  @override
  Map<String, ExportTemplateDownload> build() {
    ref.listenAppEvent(AppEventKind.exportTemplatesQueued, (event) {
      final tag = event.text;
      if (tag == null || state.containsKey(tag)) return;
      state = {...state, tag: const ExportTemplateDownload(downloaded: 0, total: 0, stage: 'downloading')};
    });
    ref.listenAppEvent(AppEventKind.exportTemplatesProgress, (event) {
      final payload = event.exportTemplatesProgress;
      if (payload == null) return;
      final previous = state[payload.tag];
      state = {
        ...state,
        payload.tag: ExportTemplateDownload(
          downloaded: payload.downloaded.toInt(),
          total: payload.total.toInt(),
          stage: 'downloading',
          file: payload.file,
          platforms: payload.platforms.isNotEmpty ? payload.platforms : previous?.platforms,
        ),
      };
    });
    ref.listenAppEvent(AppEventKind.exportTemplatesStage, (event) {
      final payload = event.exportTemplatesStage;
      if (payload == null) return;
      final previous = state[payload.tag];
      if (previous == null) return;
      state = {...state, payload.tag: previous.withStage(payload.stage)};
    });
    ref.listenAppEvents({AppEventKind.exportTemplatesComplete, AppEventKind.exportTemplatesCanceled}, (event) {
      final tag = event.text;
      if (tag != null) _clear(tag);
    });
    ref.listenAppEvent(AppEventKind.exportTemplatesError, (event) {
      final payload = event.exportTemplatesError;
      if (payload != null) _clear(payload.tag);
    });
    return const {};
  }

  void _clear(String tag) {
    if (!ref.mounted || !state.containsKey(tag)) return;
    state = {...state}..remove(tag);
  }

  Future<void> install(String tag, List<String> files, {Future<void> Function()? onInstalled}) async {
    state = {
      ...state,
      tag: ExportTemplateDownload(downloaded: 0, total: 0, stage: 'downloading', file: files.isEmpty ? null : files.first),
    };
    try {
      final result = await VersionsApi.installExportTemplates(tag, files);
      if (result != null) {
        setTemplateFilesInstalled(tag, files, true);
        pushToast(GhToastType.success, ghTr('versions:export_templates_installed_toast', args: {'tag': tag}));
        if (onInstalled != null) await onInstalled();
      }
    } catch (error) {
      pushToast(
        GhToastType.error,
        ghTr('versions:export_templates_install_failed', args: {'error': '$error'}),
        ttlMs: 6000,
      );
    } finally {
      _clear(tag);
    }
  }

  Future<void> cancel(String tag) async {
    try {
      await VersionsApi.cancelExportTemplates(tag);
    } catch (_) {}
  }
}
