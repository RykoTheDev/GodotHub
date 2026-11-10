import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';

import '../support/fake_rust.dart';

const _method = 'crateApiProjectTodosListOpenTodos';

OpenTodo _open(String projectId, String id, {String? due, TodoPriority? priority}) => OpenTodo(
  projectId: projectId,
  projectName: 'Project $projectId',
  todo: ProjectTodo(
    id: id,
    title: 'Todo $id',
    status: TodoStatus.todo,
    area: TodoArea.programming,
    dueDate: due,
    createdAt: '2026-01-01T00:00:00Z',
    priority: priority,
    checklist: const [],
  ),
);

void main() {
  late FakeRustApi rust;

  setUp(() {
    rust = installFakeRust();
    debugResetOpenTodos();
  });

  group('open todos store', () {
    test('starts empty and not loaded', () {
      expect(openTodosSnapshot.todos, isEmpty);
      expect(openTodosSnapshot.loaded, isFalse);
    });

    test('refresh loads todos and notifies listeners', () async {
      final todos = [_open('p1', 'a')];
      rust.on(_method, () async => todos);
      var notified = 0;
      void listener() => notified++;
      openTodos.addListener(listener);
      addTearDown(() => openTodos.removeListener(listener));

      await refreshOpenTodos();

      expect(notified, 1);
      expect(openTodos.value.loaded, isTrue);
      expect(identical(openTodos.value.todos, todos), isTrue);
    });

    test('a refresh while one is in flight shares it and reruns once afterwards', () async {
      final gates = <Completer<List<OpenTodo>>>[];
      rust.on(_method, () {
        final gate = Completer<List<OpenTodo>>();
        gates.add(gate);
        return gate.future;
      });

      final first = refreshOpenTodos();
      final second = refreshOpenTodos();
      final third = refreshOpenTodos();
      expect(identical(first, second), isTrue);
      expect(identical(first, third), isTrue);
      expect(rust.callCount(_method), 1);

      gates[0].complete([_open('p1', 'a')]);
      await first;
      await pumpEventQueue();
      expect(rust.callCount(_method), 2);
      expect(openTodosSnapshot.todos.single.todo.id, 'a');

      gates[1].complete([_open('p1', 'b')]);
      await pumpEventQueue();
      expect(rust.callCount(_method), 2);
      expect(openTodosSnapshot.todos.single.todo.id, 'b');

      final fresh = refreshOpenTodos();
      expect(identical(fresh, first), isFalse);
      gates[2].complete(const []);
      await fresh;
      expect(openTodosSnapshot.todos, isEmpty);
    });

    test('failures are swallowed and keep the previous snapshot', () async {
      rust.on(_method, () async => [_open('p1', 'a')]);
      await refreshOpenTodos();
      final before = openTodosSnapshot;

      rust.on(_method, () async => throw StateError('offline'));
      await expectLater(refreshOpenTodos(), completes);
      expect(identical(openTodosSnapshot, before), isTrue);

      rust.on(_method, () => throw StateError('sync failure'));
      await expectLater(refreshOpenTodos(), completes);
      expect(identical(openTodosSnapshot, before), isTrue);
    });

    test('clear resets the snapshot and always notifies', () async {
      rust.on(_method, () async => [_open('p1', 'a')]);
      await refreshOpenTodos();
      var notified = 0;
      void listener() => notified++;
      openTodos.addListener(listener);
      addTearDown(() => openTodos.removeListener(listener));

      clearOpenTodos();
      clearOpenTodos();

      expect(notified, 2);
      expect(openTodosSnapshot.loaded, isFalse);
      expect(openTodosSnapshot.todos, isEmpty);
    });
  });

  group('projectTodoCounts', () {
    Future<void> load(List<OpenTodo> todos) async {
      rust.on(_method, () async => todos);
      await refreshOpenTodos();
    }

    test('counts open and overdue todos per project', () async {
      await load([
        _open('p1', 'a', due: '2026-03-01'),
        _open('p1', 'b', due: '2026-03-02'),
        _open('p1', 'c', due: '2026-03-03'),
        _open('p1', 'd'),
        _open('p1', 'e', due: ''),
        _open('p2', 'f', due: '2025-12-31'),
      ]);
      expect(projectTodoCounts('p1', '2026-03-03'), const TodoCounts(open: 5, overdue: 2));
      expect(projectTodoCounts('p2', '2026-03-03'), const TodoCounts(open: 1, overdue: 1));
      expect(projectTodoCounts('p3', '2026-03-03'), same(noTodos));
      expect(projectTodoCounts(null, '2026-03-03'), same(noTodos));
      expect(projectTodoCounts('', '2026-03-03'), same(noTodos));
    });

    test('overdue compares dates as strings', () async {
      await load([_open('p1', 'a', due: '2026-3-1'), _open('p1', 'b', due: '2026-03-10')]);
      expect(projectTodoCounts('p1', '2026-03-05'), const TodoCounts(open: 2, overdue: 0));
      expect(projectTodoCounts('p1', '2026-04'), const TodoCounts(open: 2, overdue: 1));
    });

    test('results are memoised per snapshot and day and reused when unchanged', () async {
      await load([_open('p1', 'a', due: '2026-03-01'), _open('p2', 'b')]);
      final p1 = projectTodoCounts('p1', '2026-03-05');
      final p2 = projectTodoCounts('p2', '2026-03-05');
      expect(projectTodoCounts('p1', '2026-03-05'), same(p1));

      await load([_open('p1', 'a', due: '2026-03-01'), _open('p2', 'b'), _open('p2', 'c')]);
      expect(projectTodoCounts('p1', '2026-03-05'), same(p1));
      final p2Next = projectTodoCounts('p2', '2026-03-05');
      expect(p2Next, isNot(same(p2)));
      expect(p2Next, const TodoCounts(open: 2, overdue: 0));

      final earlier = projectTodoCounts('p1', '2026-02-01');
      expect(earlier, const TodoCounts(open: 1, overdue: 0));
      expect(earlier, isNot(same(p1)));
    });

    test('clearing the store drops the counts', () async {
      await load([_open('p1', 'a')]);
      expect(projectTodoCounts('p1', '2026-03-05').open, 1);
      clearOpenTodos();
      expect(projectTodoCounts('p1', '2026-03-05'), same(noTodos));
    });
  });

  group('signals and focus', () {
    test('notifyTodosChanged emits app:todos-changed', () {
      final seen = <AppSignal>[];
      final sub = AppSignals.all.listen(seen.add);
      addTearDown(sub.cancel);
      notifyTodosChanged();
      expect(seen.single.name, 'app:todos-changed');
      expect(seen.single.detail, isNull);
    });

    test('requestTodoFocus emits the project id and is consumed once by that project', () {
      final seen = <AppSignal>[];
      final sub = AppSignals.on('app:show-project-todos').listen(seen.add);
      addTearDown(sub.cancel);

      requestTodoFocus('p1');
      expect(seen.single.detail, 'p1');
      expect(consumeTodoFocus('p2'), isFalse);
      expect(consumeTodoFocus('p1'), isTrue);
      expect(consumeTodoFocus('p1'), isFalse);

      requestTodoFocus('p1');
      requestTodoFocus('p2');
      expect(consumeTodoFocus('p1'), isFalse);
      expect(consumeTodoFocus('p2'), isTrue);
    });
  });

  group('date helpers', () {
    test('localDateValue formats local dates', () {
      expect(localDateValue(DateTime(2026, 3, 5)), '2026-03-05');
      expect(localDateValue(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
      expect(localDateValue(DateTime(999, 1, 1)), '999-01-01');
      final utc = DateTime.utc(2026, 6, 15, 12);
      final local = utc.toLocal();
      expect(
        localDateValue(utc),
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
      );
      final now = DateTime.now();
      expect(localDateValue(), localDateValue(now));
    });

    test('addDaysValue rolls over months, years and leap days', () {
      expect(addDaysValue('2024-02-28', 1), '2024-02-29');
      expect(addDaysValue('2024-02-28', 2), '2024-03-01');
      expect(addDaysValue('2023-02-28', 1), '2023-03-01');
      expect(addDaysValue('2023-12-31', 1), '2024-01-01');
      expect(addDaysValue('2024-01-01', -1), '2023-12-31');
      expect(addDaysValue('2026-03-05', 6), '2026-03-11');
      expect(addDaysValue('2026-03-29', 0), '2026-03-29');
      expect(addDaysValue('2026-10-25', 1), '2026-10-26');
      expect(addDaysValue('2024-01-01', 366), '2025-01-01');
    });

    test('addDaysValue normalises out of range parts like Date', () {
      expect(addDaysValue('2024-13-01', 0), '2025-01-01');
      expect(addDaysValue('2024-00-10', 0), '2023-12-10');
      expect(addDaysValue('2024-02-30', 0), '2024-03-01');
      expect(addDaysValue('2024-01-00', 0), '2023-12-31');
      expect(addDaysValue('2024-01-01', 1.9), '2024-01-02');
      expect(addDaysValue('2024-01-01', -0.5), '2023-12-31');
    });

    test('addDaysValue maps years 0 to 99 into the 1900s', () {
      expect(addDaysValue('0050-01-01', 1), '1950-01-02');
      expect(addDaysValue('0099-12-31', 1), '2000-01-01');
      expect(addDaysValue('0100-01-01', 0), '100-01-01');
    });

    test('addDaysValue parses parts with Number semantics', () {
      expect(addDaysValue(' 2024 - 1 - 2', 0), '2024-01-02');
      expect(addDaysValue('0x7E8-1-1', 0), '2024-01-01');
      expect(addDaysValue('1e3-1-1', 0), '1000-01-01');
      expect(addDaysValue('2024.0-1.5-2', 0), '2024-01-02');
      expect(addDaysValue('-2024-01-01', 0), '2068-08-01');
    });

    test('addDaysValue returns NaN parts for invalid input', () {
      expect(addDaysValue('bad', 1), 'NaN-NaN-NaN');
      expect(addDaysValue('', 1), 'NaN-NaN-NaN');
      expect(addDaysValue('2024-05', 1), 'NaN-NaN-NaN');
      expect(addDaysValue('2024-x-01', 1), 'NaN-NaN-NaN');
      expect(addDaysValue('Infinity-01-01', 1), 'NaN-NaN-NaN');
      expect(addDaysValue('275761-01-01', 0), 'NaN-NaN-NaN');
      expect(addDaysValue('2024-01-01', 1e12), 'NaN-NaN-NaN');
    });

    test('daysBetween counts whole UTC days', () {
      expect(daysBetween('2024-01-01', '2024-01-31'), 30);
      expect(daysBetween('2024-01-31', '2024-01-01'), -30);
      expect(daysBetween('2024-02-28', '2024-03-01'), 2);
      expect(daysBetween('2023-02-28', '2023-03-01'), 1);
      expect(daysBetween('2026-03-28', '2026-03-30'), 2);
      expect(daysBetween('2026-03-05', '2026-03-05'), 0);
      expect(daysBetween('1970-01-01', '2000-01-01'), 10957);
      expect(daysBetween('0050-01-01', '1950-01-01'), 0);
      expect(daysBetween('2024-01-01', '2024-01-01'), isA<int>());
    });

    test('daysBetween is NaN for invalid input', () {
      expect(daysBetween('bad', '2024-01-01'), isNaN);
      expect(daysBetween('2024-01-01', '2024-01'), isNaN);
      expect(daysBetween('2024-01-01', '275761-01-01'), isNaN);
    });
  });

  test('priority rank orders high, medium, none, low', () {
    expect(priorityRank, {TodoPriority.high: 0, TodoPriority.medium: 1, null: 2, TodoPriority.low: 3});
    expect(rankOf(TodoPriority.high), 0);
    expect(rankOf(TodoPriority.medium), 1);
    expect(rankOf(null), 2);
    expect(rankOf(TodoPriority.low), 3);
    final sorted = [TodoPriority.low, null, TodoPriority.high, TodoPriority.medium]..sort((a, b) => rankOf(a) - rankOf(b));
    expect(sorted, [TodoPriority.high, TodoPriority.medium, null, TodoPriority.low]);
  });
}
