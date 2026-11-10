import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/open_todos_sync.dart';
import 'package:godothub/state/projects.dart';
import 'package:godothub/state/settings.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

const _open = 'crateApiProjectTodosListOpenTodos';

OpenTodo open(String projectId, String id, {String? due}) => OpenTodo(
  projectId: projectId,
  projectName: 'Project $projectId',
  todo: ProjectTodo(
    id: id,
    title: 'Todo $id',
    status: TodoStatus.todo,
    area: TodoArea.programming,
    dueDate: due,
    createdAt: '2026-01-01T00:00:00Z',
    checklist: const [],
  ),
);

void main() {
  late FakeRustApi rust;
  late CoreBackend backend;
  late List<OpenTodo> server;
  late List<Project> projects;

  setUp(() {
    rust = installFakeRust();
    debugResetOpenTodos();
    useMemoryUiPrefs();
    backend = CoreBackend(rust, active: 'w1', settings: settingsWith(projectTodosEnabled: true));
    server = [open('p1', 'a')];
    projects = [project('p1')];
    rust.on(_open, () async => List<OpenTodo>.of(server));
    rust.on('crateApiProjectsListProjects', () async => List<Project>.of(projects));
  });

  test('stays cleared and idle while todos are disabled', () async {
    backend.settings = settingsWith();
    final container = createContainer([openTodosProvider]);
    await settle();
    expect(container.read(openTodosProvider).loaded, isFalse);
    expect(rust.callCount(_open), 0);

    AppSignals.emit(todosChangedSignal);
    await settle();
    expect(rust.callCount(_open), 0);
  });

  test('syncs once enabled, on todo changes and when the project list changes, and clears when disabled', () async {
    final container = createContainer([openTodosProvider]);
    await settle();
    expect(container.read(openTodosProvider).loaded, isTrue);
    expect(container.read(openTodosProvider).todos.map((o) => o.todo.id), ['a']);
    final afterLoad = rust.callCount(_open);

    server = [open('p1', 'a'), open('p1', 'b')];
    AppSignals.emit(todosChangedSignal);
    await settle();
    expect(rust.callCount(_open), afterLoad + 1);
    expect(container.read(openTodosProvider).todos, hasLength(2));

    await container.read(projectsProvider.notifier).refresh();
    await settle();
    expect(rust.callCount(_open), afterLoad + 1);

    projects = [project('p1'), project('p2')];
    await container.read(projectsProvider.notifier).refresh();
    await settle();
    expect(rust.callCount(_open), afterLoad + 2);

    await container.read(settingsProvider.notifier).save(settingsWith());
    await settle();
    expect(container.read(openTodosProvider).loaded, isFalse);
    expect(container.read(openTodosProvider).todos, isEmpty);
  });

  group('due notifications', () {
    Map<String, Object?> notified() =>
        jsonDecode(UiPrefsStore.instance.getItem(todoDueNotifiedKey) ?? 'null') as Map<String, Object?>? ?? const {};

    test('records due todos once per day and only when notifications are enabled', () async {
      final today = localDateValue();
      server = [
        open('p1', 'overdue', due: '2000-01-01'),
        open('p1', 'today', due: today),
        open('p1', 'later', due: '2999-01-01'),
        open('p1', 'none'),
      ];
      final container = createContainer([todoDueNotificationsProvider]);
      await settle();
      expect(UiPrefsStore.instance.getItem(todoDueNotifiedKey), isNull);

      await container.read(settingsProvider.notifier).save(
        settingsWith(projectTodosEnabled: true, desktopNotificationsEnabled: true),
      );
      await settle();
      expect(notified()['date'], today);
      expect(notified()['ids'], ['p1:overdue', 'p1:today']);

      server = [...server, open('p2', 'fresh', due: '2000-01-01')];
      AppSignals.emit(todosChangedSignal);
      await settle();
      expect(notified()['ids'], ['p1:overdue', 'p1:today', 'p2:fresh']);
    });

    test('a stale notified record from another day is ignored', () {
      UiPrefsStore.instance.setItem(todoDueNotifiedKey, jsonEncode({'date': '1999-01-01', 'ids': ['p1:a']}));
      checkDueTodos(OpenTodosSnapshot(todos: [open('p1', 'a', due: '2000-01-01')], loaded: true));
      expect(notified()['ids'], ['p1:a']);
      expect(notified()['date'], localDateValue());

      checkDueTodos(OpenTodosSnapshot(todos: [open('p1', 'a', due: '2000-01-01')], loaded: true));
      expect(notified()['ids'], ['p1:a']);
    });
  });
}
