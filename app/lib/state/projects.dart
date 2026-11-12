import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/projects.dart';
import '../api/settings.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';
import 'scan_progress.dart';
import 'workspaces.dart';

const String projectHealthChangedSignal = 'app:project-health-changed';

final projectsProvider = NotifierProvider<ProjectsNotifier, ApiData<List<Project>>>(ProjectsNotifier.new);

final projectScanProgressProvider = NotifierProvider<ScanProgressNotifier, ScanProgress?>(
  () => ScanProgressNotifier(AppEventKind.projectScanProgress),
);

Project copyProject(
  Project p, {
  String? Function()? category,
  bool? pinned,
  int? sortOrder,
  List<String>? tags,
  String? godotVersion,
  String? path,
}) => Project(
  id: p.id,
  name: p.name,
  path: path ?? p.path,
  godotVersion: godotVersion ?? p.godotVersion,
  createdAt: p.createdAt,
  lastOpened: p.lastOpened,
  category: category != null ? category() : p.category,
  pinned: pinned ?? p.pinned,
  sortOrder: sortOrder ?? p.sortOrder,
  launchArguments: p.launchArguments,
  tags: tags ?? p.tags,
  totalTimeSeconds: p.totalTimeSeconds,
  sessionStartedAtMs: p.sessionStartedAtMs,
  timeTodaySeconds: p.timeTodaySeconds,
  timeWeekSeconds: p.timeWeekSeconds,
);

void _refreshTrayMenu() {
  Future<void>.sync(SettingsApi.refreshTrayMenu).ignore();
}

class ProjectsNotifier extends ApiDataNotifier<List<Project>> {
  @override
  List<Project> get initial => const [];

  @override
  bool get keepsError => true;

  @override
  Future<List<Project>> fetch() async {
    final list = await ProjectsApi.list();
    _refreshTrayMenu();
    return list;
  }

  @override
  void setup() {
    ref.watch(activeWorkspaceIdProvider);
    ref.listenSignal(projectHealthChangedSignal, (_) => unawaited(refresh()));
    ref.listenAppEvents({AppEventKind.projectScanDone, AppEventKind.godotDownloadComplete}, (_) => unawaited(refresh()));
  }

  List<Project> get projects => state.data;

  Future<T> _rollback<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      await refresh();
      rethrow;
    }
  }

  Future<void> remove(String id, bool deleteFiles) {
    setData((prev) => [for (final p in prev) if (p.id != id) p]);
    return _rollback(() => ProjectsApi.remove(id, deleteFiles));
  }

  Future<void> updateVersion(String id, String godotVersion) async {
    await ProjectsApi.update(id, ProjectUpdate(godotVersion: godotVersion));
    await refresh();
  }

  Future<void> setPinned(String id, bool pinned) {
    setData((prev) => [for (final p in prev) p.id == id ? copyProject(p, pinned: pinned) : p]);
    return _rollback(() => ProjectsApi.update(id, ProjectUpdate(pinned: pinned)));
  }

  Future<void> updateTags(String id, List<String> tags) async {
    setData((prev) => [for (final p in prev) p.id == id ? copyProject(p, tags: tags) : p]);
  }

  Future<void> setCategory(String id, String category) {
    setData(
      (prev) => [for (final p in prev) p.id == id ? copyProject(p, category: () => category.isEmpty ? null : category) : p],
    );
    return _rollback(() => ProjectsApi.update(id, ProjectUpdate(category: category)));
  }

  Future<void> moveProjects(List<String> ids, String category, List<String> destOrderedIds) async {
    if (ids.isEmpty) return;
    final moving = ids.toSet();
    final snapshot = List<Project>.of(state.data);
    final rank = {for (var i = 0; i < destOrderedIds.length; i++) destOrderedIds[i]: i};
    setData(
      (prev) => [
        for (final p in prev)
          if (moving.contains(p.id))
            copyProject(p, category: () => category.isEmpty ? null : category, sortOrder: rank[p.id] ?? p.sortOrder)
          else if (rank.containsKey(p.id))
            copyProject(p, sortOrder: rank[p.id])
          else
            p,
      ],
    );
    try {
      for (final id in ids) {
        await ProjectsApi.update(id, ProjectUpdate(category: category));
      }
      await ProjectsApi.reorder(destOrderedIds);
    } catch (_) {
      if (ref.mounted) setData((_) => snapshot);
      await refresh();
      rethrow;
    }
  }

  Future<void> reorder(List<String> orderedIds) {
    final rank = {for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i};
    setData((prev) => [for (final p in prev) rank.containsKey(p.id) ? copyProject(p, sortOrder: rank[p.id]) : p]);
    return _rollback(() => ProjectsApi.reorder(orderedIds));
  }
}
