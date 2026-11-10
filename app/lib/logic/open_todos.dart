import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/project_todos.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';

class OpenTodosSnapshot {
  OpenTodosSnapshot({required this.todos, required this.loaded});

  final List<OpenTodo> todos;
  final bool loaded;

  @override
  String toString() => 'OpenTodosSnapshot(todos: ${todos.length}, loaded: $loaded)';
}

final ValueNotifier<OpenTodosSnapshot> _store = ValueNotifier(OpenTodosSnapshot(todos: const [], loaded: false));
Future<void>? _inflight;
bool _rerun = false;
String? _pendingFocusProjectId;

ValueListenable<OpenTodosSnapshot> get openTodos => _store;

OpenTodosSnapshot get openTodosSnapshot => _store.value;

Future<void> refreshOpenTodos() {
  final current = _inflight;
  if (current != null) {
    _rerun = true;

    return current;
  }

  final future = Future<List<OpenTodo>>.sync(ProjectTodosApi.open)
      .then((todos) {
        _store.value = OpenTodosSnapshot(todos: todos, loaded: true);
      })
      .catchError((Object _) {})
      .whenComplete(() {
        _inflight = null;

        if (_rerun) {
          _rerun = false;
          unawaited(refreshOpenTodos());
        }
      });
  _inflight = future;

  return future;
}

void clearOpenTodos() {
  _store.value = OpenTodosSnapshot(todos: const [], loaded: false);
}

@immutable
class TodoCounts {
  const TodoCounts({required this.open, required this.overdue});

  final int open;
  final int overdue;

  @override
  bool operator ==(Object other) => other is TodoCounts && other.open == open && other.overdue == overdue;

  @override
  int get hashCode => Object.hash(open, overdue);

  @override
  String toString() => 'TodoCounts(open: $open, overdue: $overdue)';
}

const TodoCounts noTodos = TodoCounts(open: 0, overdue: 0);

class _CountsCache {
  _CountsCache(this.snapshot, this.today, this.byProject);

  final OpenTodosSnapshot snapshot;
  final String today;
  final Map<String, TodoCounts> byProject;
}

_CountsCache? _countsCache;

TodoCounts _todoCountsFor(String projectId, String today) {
  final snapshot = _store.value;
  final cache = _countsCache;
  if (cache == null || !identical(cache.snapshot, snapshot) || cache.today != today) {
    final previous = cache?.byProject;
    final open = <String, int>{};
    final overdue = <String, int>{};
    for (final item in snapshot.todos) {
      open[item.projectId] = (open[item.projectId] ?? 0) + 1;
      overdue[item.projectId] ??= 0;
      final dueDate = item.todo.dueDate;
      if (dueDate != null && dueDate.isNotEmpty && dueDate.compareTo(today) < 0) {
        overdue[item.projectId] = overdue[item.projectId]! + 1;
      }
    }
    final byProject = <String, TodoCounts>{};
    for (final entry in open.entries) {
      final counts = TodoCounts(open: entry.value, overdue: overdue[entry.key]!);
      final prior = previous?[entry.key];
      byProject[entry.key] = prior != null && prior == counts ? prior : counts;
    }
    _countsCache = _CountsCache(snapshot, today, byProject);
  }
  return _countsCache!.byProject[projectId] ?? noTodos;
}

TodoCounts projectTodoCounts(String? projectId, String today) =>
    projectId != null && projectId.isNotEmpty ? _todoCountsFor(projectId, today) : noTodos;

void notifyTodosChanged() {
  AppSignals.emit('app:todos-changed');
}

void requestTodoFocus(String projectId) {
  _pendingFocusProjectId = projectId;
  AppSignals.emit('app:show-project-todos', projectId);
}

bool consumeTodoFocus(String projectId) {
  if (_pendingFocusProjectId != projectId) return false;

  _pendingFocusProjectId = null;

  return true;
}

@visibleForTesting
void debugResetOpenTodos() {
  _store.value = OpenTodosSnapshot(todos: const [], loaded: false);
  _inflight = null;
  _rerun = false;
  _pendingFocusProjectId = null;
  _countsCache = null;
}

String _pad2(int value) => value.toString().padLeft(2, '0');

const String _invalidDate = 'NaN-NaN-NaN';

String localDateValue([DateTime? date]) {
  final local = (date ?? DateTime.now()).toLocal();

  return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)}';
}

String addDaysValue(String value, num days) {
  final parts = value.split('-').map(_jsNumber).toList();
  double part(int index) => index < parts.length ? parts[index] : double.nan;
  final day = _jsMakeDay(_jsFullYear(part(0)), part(1) - 1, part(2) + days);
  if (!_inDateRange(day)) return _invalidDate;
  final civil = DateTime.utc(1970, 1, 1 + day.toInt());
  final DateTime local;
  try {
    local = DateTime(civil.year, civil.month, civil.day, 12);
  } on ArgumentError {
    return _invalidDate;
  }

  return localDateValue(local);
}

num daysBetween(String from, String to) {
  final f = from.split('-').map(_jsNumber).toList();
  final t = to.split('-').map(_jsNumber).toList();
  double at(List<double> parts, int index) => index < parts.length ? parts[index] : double.nan;
  final fromDay = _jsMakeDay(_jsFullYear(at(f, 0)), at(f, 1) - 1, at(f, 2));
  final toDay = _jsMakeDay(_jsFullYear(at(t, 0)), at(t, 1) - 1, at(t, 2));
  if (!_inDateRange(fromDay) || !_inDateRange(toDay)) return double.nan;

  return (toDay - fromDay).round();
}

const Map<TodoPriority?, int> priorityRank = {
  TodoPriority.high: 0,
  TodoPriority.medium: 1,
  null: 2,
  TodoPriority.low: 3,
};

int rankOf(TodoPriority? priority) => priorityRank[priority]!;

const double _maxEpochDays = 8.64e15 / 86400000;

bool _inDateRange(double day) => day.isFinite && day.abs() <= _maxEpochDays;

double _jsFullYear(double year) {
  if (year.isNaN) return year;
  final integer = year.isFinite ? year.truncateToDouble() : year;
  return integer >= 0 && integer <= 99 ? 1900 + integer : year;
}

double _floorDiv(double a, double b) => (a / b).floorToDouble();

double _jsMakeDay(double year, double month, double date) {
  if (!year.isFinite || !month.isFinite || !date.isFinite) return double.nan;
  final y = year.truncateToDouble();
  final m = month.truncateToDouble();
  final dt = date.truncateToDouble();
  final ym = y + _floorDiv(m, 12);
  if (!ym.isFinite) return double.nan;
  final mn = m - _floorDiv(m, 12) * 12;
  final civilMonth = mn + 1;
  final shiftedYear = civilMonth <= 2 ? ym - 1 : ym;
  final era = _floorDiv(shiftedYear, 400);
  final yoe = shiftedYear - era * 400;
  final mp = civilMonth > 2 ? civilMonth - 3 : civilMonth + 9;
  final doy = _floorDiv(153 * mp + 2, 5);
  final doe = yoe * 365 + _floorDiv(yoe, 4) - _floorDiv(yoe, 100) + doy;
  final firstOfMonth = era * 146097 + doe - 719468;

  return firstOfMonth + dt - 1;
}

final RegExp _jsWhitespace = RegExp(
  '^[\t\n\v\f\r    -     　﻿]+|[\t\n\v\f\r    -     　﻿]+\$',
);
final RegExp _jsDecimal = RegExp(r'^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$');
final RegExp _jsInfinity = RegExp(r'^([+-]?)Infinity$');
final RegExp _jsRadix = RegExp(r'^0(?:([xX])([0-9a-fA-F]+)|([bB])([01]+)|([oO])([0-7]+))$');

double _jsNumber(String input) {
  final text = input.replaceAll(_jsWhitespace, '');
  if (text.isEmpty) return 0;
  if (_jsDecimal.hasMatch(text)) return double.parse(text);
  final infinity = _jsInfinity.firstMatch(text);
  if (infinity != null) return infinity.group(1) == '-' ? double.negativeInfinity : double.infinity;
  final radix = _jsRadix.firstMatch(text);
  if (radix != null) {
    if (radix.group(2) != null) return BigInt.parse(radix.group(2)!, radix: 16).toDouble();
    if (radix.group(4) != null) return BigInt.parse(radix.group(4)!, radix: 2).toDouble();
    return BigInt.parse(radix.group(6)!, radix: 8).toDouble();
  }

  return double.nan;
}
