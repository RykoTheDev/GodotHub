import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/project_todos.dart';
import '../logic/open_todos.dart';
import '../src/rust/api/types.dart';

@immutable
class ProjectTodosState {
  const ProjectTodosState({
    this.todos = const [],
    this.loaded = false,
    this.loading = true,
    this.error,
    this.saving = false,
    this.saveError,
  });

  final List<ProjectTodo> todos;
  final bool loaded;
  final bool loading;
  final String? error;
  final bool saving;
  final String? saveError;

  ProjectTodosState copyWith({
    List<ProjectTodo>? todos,
    bool? loaded,
    bool? loading,
    ValueGetter<String?>? error,
    bool? saving,
    ValueGetter<String?>? saveError,
  }) => ProjectTodosState(
    todos: todos ?? this.todos,
    loaded: loaded ?? this.loaded,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
    saving: saving ?? this.saving,
    saveError: saveError != null ? saveError() : this.saveError,
  );

  @override
  bool operator ==(Object other) =>
      other is ProjectTodosState &&
      identical(other.todos, todos) &&
      other.loaded == loaded &&
      other.loading == loading &&
      other.error == error &&
      other.saving == saving &&
      other.saveError == saveError;

  @override
  int get hashCode => Object.hash(identityHashCode(todos), loaded, loading, error, saving, saveError);
}

final projectTodosProvider = NotifierProvider.autoDispose
    .family<ProjectTodosNotifier, ProjectTodosState, String>(ProjectTodosNotifier.new);

class ProjectTodosNotifier extends Notifier<ProjectTodosState> {
  ProjectTodosNotifier(this.projectId);

  final String projectId;
  List<ProjectTodo>? _failedTodos;
  int _generation = 0;

  @override
  ProjectTodosState build() {
    final generation = ++_generation;
    scheduleMicrotask(() {
      if (generation == _generation && ref.mounted) unawaited(refresh());
    });
    return const ProjectTodosState();
  }

  void _set(ProjectTodosState Function(ProjectTodosState previous) update) {
    if (ref.mounted) state = update(state);
  }

  Future<void> refresh() async {
    final generation = _generation;
    _set((s) => s.copyWith(loading: true, error: () => null));
    try {
      final todos = await ProjectTodosApi.list(projectId);
      if (generation != _generation) return;
      _set((s) => s.copyWith(todos: todos, loaded: true, loading: false));
    } catch (error) {
      if (generation != _generation) return;
      _set((s) => s.copyWith(todos: const [], loaded: true, loading: false, error: () => '$error'));
    }
  }

  Future<bool> saveTodos(List<ProjectTodo> nextTodos, {bool rememberFailure = true}) async {
    _set((s) => rememberFailure ? s.copyWith(saving: true, saveError: () => null) : s.copyWith(saving: true));
    try {
      final saved = await ProjectTodosApi.save(projectId, nextTodos);
      _failedTodos = null;
      _set((s) => s.copyWith(todos: saved, saveError: () => null));
      notifyTodosChanged();
      return true;
    } catch (error) {
      if (rememberFailure) {
        _failedTodos = nextTodos;
        _set((s) => s.copyWith(saveError: () => '$error'));
      }
      return false;
    } finally {
      _set((s) => s.copyWith(saving: false));
    }
  }

  Future<TodoSyncResult> sync(bool scanComments) async {
    final result = await ProjectTodosApi.sync(projectId, scanComments);
    _set((s) => s.copyWith(todos: result.todos));
    notifyTodosChanged();
    return result;
  }

  Future<bool> retrySave() async {
    final failed = _failedTodos;
    if (failed == null) return false;
    return saveTodos(failed);
  }
}
