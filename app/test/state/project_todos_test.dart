import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/open_todos_sync.dart';
import 'package:godothub/state/project_todos.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

const _list = 'crateApiProjectTodosListProjectTodos';
const _save = 'crateApiProjectTodosSaveProjectTodos';

ProjectTodo todo(String id, {String? due}) => ProjectTodo(
  id: id,
  title: 'Todo $id',
  status: TodoStatus.todo,
  area: TodoArea.programming,
  dueDate: due,
  createdAt: '2026-01-01T00:00:00Z',
  checklist: const [],
);

void main() {
  late FakeRustApi rust;
  late Map<String, List<ProjectTodo>> server;
  late bool failSave;
  late int changes;

  setUp(() {
    rust = installFakeRust();
    server = {
      'p1': [todo('a')],
      'p2': [todo('b'), todo('c')],
    };
    failSave = false;
    changes = 0;
    AppSignals.on(todosChangedSignal).listen((_) => changes++);
    rust.on(_list, ({required String projectId}) async {
      if (projectId == 'broken') throw StateError('bad json');
      return server[projectId]!;
    });
    rust.on(_save, ({required String projectId, required List<ProjectTodo> todos}) async {
      if (failSave) throw StateError('read only');
      server[projectId] = [...todos, todo('server-added')];
      return server[projectId]!;
    });
  });

  test('loads the todos of each project and keeps the load error', () async {
    final container = createContainer([
      projectTodosProvider('p1'),
      projectTodosProvider('p2'),
      projectTodosProvider('broken'),
    ]);
    expect(container.read(projectTodosProvider('p1')).loading, isTrue);
    await settle();

    expect(container.read(projectTodosProvider('p1')).todos.map((t) => t.id), ['a']);
    expect(container.read(projectTodosProvider('p2')).todos.map((t) => t.id), ['b', 'c']);
    final broken = container.read(projectTodosProvider('broken'));
    expect(broken.loaded, isTrue);
    expect(broken.loading, isFalse);
    expect(broken.error, contains('bad json'));

    server['p1'] = [todo('z')];
    await container.read(projectTodosProvider('p1').notifier).refresh();
    expect(container.read(projectTodosProvider('p1')).todos.map((t) => t.id), ['z']);
  });

  test('saveTodos applies the saved list and announces the change', () async {
    final container = createContainer([projectTodosProvider('p1')]);
    await settle();
    final notifier = container.read(projectTodosProvider('p1').notifier);

    final saving = notifier.saveTodos([todo('a'), todo('new')]);
    expect(container.read(projectTodosProvider('p1')).saving, isTrue);
    expect(await saving, isTrue);
    final state = container.read(projectTodosProvider('p1'));
    expect(state.saving, isFalse);
    expect(state.saveError, isNull);
    expect(state.todos.map((t) => t.id), ['a', 'new', 'server-added']);
    expect(changes, 1);
  });

  test('a failed save keeps the error for retrySave, unless asked not to remember it', () async {
    final container = createContainer([projectTodosProvider('p1')]);
    await settle();
    final notifier = container.read(projectTodosProvider('p1').notifier);

    expect(await notifier.retrySave(), isFalse);

    failSave = true;
    expect(await notifier.saveTodos([todo('x')], rememberFailure: false), isFalse);
    expect(container.read(projectTodosProvider('p1')).saveError, isNull);
    expect(await notifier.retrySave(), isFalse);

    expect(await notifier.saveTodos([todo('x')]), isFalse);
    expect(container.read(projectTodosProvider('p1')).saveError, contains('read only'));
    expect(container.read(projectTodosProvider('p1')).todos.map((t) => t.id), ['a']);
    expect(changes, 0);

    failSave = false;
    expect(await notifier.retrySave(), isTrue);
    expect(container.read(projectTodosProvider('p1')).saveError, isNull);
    expect(container.read(projectTodosProvider('p1')).todos.map((t) => t.id), ['x', 'server-added']);
    expect(await notifier.retrySave(), isFalse);
    expect(changes, 1);
  });

  test('sync replaces the todos with the synced list and announces the change', () async {
    rust.on('crateApiTodoSyncSyncProjectTodos', ({required String projectId, required bool scanComments}) async {
      return TodoSyncResult(
        todos: [todo('synced')],
        scanned: scanComments,
        imported: BigInt.one,
        closed: BigInt.zero,
        reopened: BigInt.zero,
        updated: BigInt.zero,
        closedByCommits: BigInt.zero,
        gitAvailable: true,
      );
    });
    final container = createContainer([projectTodosProvider('p2')]);
    await settle();

    final result = await container.read(projectTodosProvider('p2').notifier).sync(true);
    expect(result.scanned, isTrue);
    expect(container.read(projectTodosProvider('p2')).todos.map((t) => t.id), ['synced']);
    expect(changes, 1);
  });
}
