import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/workspaces.dart';
import '../logic/pending_save.dart';
import '../src/rust/api/types.dart';

@immutable
class WorkspacesView {
  const WorkspacesView({this.workspaces = const [], this.activeId = '', this.loaded = false});

  final List<Workspace> workspaces;
  final String activeId;
  final bool loaded;

  WorkspacesView withState(WorkspacesState next) => WorkspacesView(workspaces: next.workspaces, activeId: next.activeId, loaded: loaded);

  @override
  bool operator ==(Object other) =>
      other is WorkspacesView && listEquals(other.workspaces, workspaces) && other.activeId == activeId && other.loaded == loaded;

  @override
  int get hashCode => Object.hash(Object.hashAll(workspaces), activeId, loaded);
}

final workspacesProvider = NotifierProvider<WorkspacesNotifier, WorkspacesView>(WorkspacesNotifier.new);

final activeWorkspaceIdProvider = Provider<String>((ref) => ref.watch(workspacesProvider.select((view) => view.activeId)));

class WorkspacesNotifier extends Notifier<WorkspacesView> {
  @override
  WorkspacesView build() {
    scheduleMicrotask(_load);
    return const WorkspacesView();
  }

  Future<void> _load() async {
    WorkspacesState? loaded;
    try {
      loaded = await WorkspacesApi.list();
    } catch (_) {}
    if (!ref.mounted) return;
    final base = loaded == null ? state : state.withState(loaded);
    state = WorkspacesView(workspaces: base.workspaces, activeId: base.activeId, loaded: true);
  }

  void _apply(WorkspacesState next) {
    if (ref.mounted) state = state.withState(next);
  }

  Future<void> refresh() async => _apply(await WorkspacesApi.list());

  Future<void> switchWorkspace(String id) async {
    if (id == state.activeId) return;
    await flushPendingSave();
    _apply(await WorkspacesApi.switchWorkspace(id));
  }

  Future<void> createWorkspace(String name, String icon, String color, [String? copySettingsFrom]) async {
    await flushPendingSave();
    _apply(await WorkspacesApi.create(name, icon, color, copySettingsFrom));
  }

  Future<void> renameWorkspace(String id, String name) async => _apply(await WorkspacesApi.update(id, name, null, null));

  Future<void> updateWorkspaceStyle(String id, String icon, String color) async =>
      _apply(await WorkspacesApi.update(id, null, icon, color));

  Future<void> deleteWorkspace(String id) async {
    await flushPendingSave();
    _apply(await WorkspacesApi.delete(id));
  }
}
