import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/design.dart';
import '../logic/last_opened.dart';
import '../logic/locale.dart';
import '../logic/open_todos.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';

enum TodoStatusSort { todoFirst, completedFirst }

enum TodoDueDateSort { nearestFirst, farthestFirst }

const todoStatuses = [TodoStatus.todo, TodoStatus.paused, TodoStatus.inProgress, TodoStatus.done];

const _statusKey = {TodoStatus.todo: 'todo', TodoStatus.paused: 'paused', TodoStatus.inProgress: 'in_progress', TodoStatus.done: 'done'};

String tt(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('todos:$key', count: count, args: args);

String todoStatusLabel(TodoStatus status) => tt('status_${_statusKey[status]}');

String todoAreaLabel(TodoArea area) => tt('area_${area.name}');

String todoPriorityLabel(TodoPriority priority) => tt('priority_${priority.name}');

class TodoStatusStyle {
  const TodoStatusStyle({required this.background, required this.border, required this.dot});

  final Color background;
  final Color border;
  final Color dot;
}

TodoStatusStyle todoStatusStyle(GhTheme theme, TodoStatus status) => switch (status) {
  TodoStatus.todo => TodoStatusStyle(background: theme.raised, border: theme.outline.withValues(alpha: 0.4), dot: theme.muted),
  TodoStatus.paused => TodoStatusStyle(
    background: theme.amber.withValues(alpha: 0.2),
    border: theme.amber.withValues(alpha: 0.3),
    dot: theme.amber,
  ),
  TodoStatus.inProgress => TodoStatusStyle(
    background: theme.accent.withValues(alpha: 0.15),
    border: theme.accent.withValues(alpha: 0.3),
    dot: theme.accent,
  ),
  TodoStatus.done => TodoStatusStyle(
    background: theme.mint.withValues(alpha: 0.15),
    border: theme.mint.withValues(alpha: 0.3),
    dot: theme.mint,
  ),
};

Color todoPriorityColor(GhTheme theme, TodoPriority priority) => switch (priority) {
  TodoPriority.high => theme.danger,
  TodoPriority.medium => theme.amber,
  TodoPriority.low => theme.muted.withValues(alpha: 0.4),
};

extension ProjectTodoCopy on ProjectTodo {
  ProjectTodo copyWith({
    String? title,
    TodoStatus? status,
    TodoArea? area,
    ValueGetter<String?>? dueDate,
    ValueGetter<String?>? description,
    ValueGetter<TodoLink?>? link,
    ValueGetter<TodoPriority?>? priority,
    List<TodoChecklistItem>? checklist,
  }) => ProjectTodo(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    area: area ?? this.area,
    dueDate: dueDate != null ? dueDate() : this.dueDate,
    description: description != null ? description() : this.description,
    createdAt: createdAt,
    number: number,
    link: link != null ? link() : this.link,
    source: source,
    closedBy: closedBy,
    priority: priority != null ? priority() : this.priority,
    checklist: checklist ?? this.checklist,
    completedAt: completedAt,
  );
}

final math.Random _random = math.Random.secure();

String newTodoId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

const _statusOrder = {TodoStatus.todo: 0, TodoStatus.paused: 1, TodoStatus.inProgress: 2, TodoStatus.done: 3};

List<ProjectTodo> sortProjectTodos(List<ProjectTodo> todos, TodoStatusSort? statusSort, TodoDueDateSort? dueDateSort) {
  if (statusSort == null && dueDateSort == null) return todos;
  final indexed = [for (var i = 0; i < todos.length; i++) (todo: todos[i], index: i)];
  indexed.sort((a, b) {
    if (dueDateSort != null) {
      final aDate = a.todo.dueDate ?? '';
      final bDate = b.todo.dueDate ?? '';
      if (aDate.isNotEmpty && bDate.isNotEmpty) {
        final difference = aDate.compareTo(bDate);
        if (difference != 0) return dueDateSort == TodoDueDateSort.nearestFirst ? difference : -difference;
      } else if (aDate.isNotEmpty) {
        return -1;
      } else if (bDate.isNotEmpty) {
        return 1;
      }
    }
    if (statusSort != null) {
      final direction = statusSort == TodoStatusSort.completedFirst ? -1 : 1;
      final difference = (_statusOrder[a.todo.status]! - _statusOrder[b.todo.status]!) * direction;
      if (difference != 0) return difference;
    }
    final priority = rankOf(a.todo.priority) - rankOf(b.todo.priority);
    if (priority != 0) return priority;
    return a.index - b.index;
  });
  return [for (final entry in indexed) entry.todo];
}

List<ProjectTodo> fullTodoOrder(List<ProjectTodo> todos, List<ProjectTodo> sorted) {
  final done = [
    for (var i = 0; i < todos.length; i++)
      if (todos[i].status == TodoStatus.done) (todo: todos[i], index: i),
  ];
  done.sort((a, b) {
    final difference = (b.todo.completedAt ?? '').compareTo(a.todo.completedAt ?? '');
    return difference != 0 ? difference : a.index - b.index;
  });
  return [...sorted.where((todo) => todo.status != TodoStatus.done), for (final entry in done) entry.todo];
}

bool todoMatchesSearch(ProjectTodo todo, String query) {
  if (query.isEmpty) return true;
  return [
    todo.title,
    todo.description ?? '',
    todo.link?.path ?? '',
    todo.number != null ? '#todo-${todo.number}' : '',
    for (final item in todo.checklist) item.text,
  ].join('\n').toLowerCase().contains(query);
}

DateTime? todoLocalDate(String value) {
  final parts = value.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}

String formatTodoDueDate(String? dueDate, String today, LastOpenedDateFormat dateFormat) {
  if (dueDate == null || dueDate.isEmpty) return '-';
  final difference = daysBetween(today, dueDate);
  if (difference == 0) return ghTr('time_today');
  if (difference == 1) return tt('tomorrow');
  final date = todoLocalDate(dueDate);
  if (date == null) return dueDate;
  if (dueDate.length < 4 || today.length < 4 || dueDate.substring(0, 4) != today.substring(0, 4)) {
    return formatDate(date, dateFormat);
  }
  return formatLocaleDate(date, const GhDateFormatOptions(day: GhDatePart.numeric, month: GhDatePart.short));
}

String todoDueLabel(String today, String dueDate) {
  final difference = daysBetween(today, dueDate);
  if (difference < 0) return tt('overdue_days', count: -difference);
  if (difference == 0) return ghTr('time_today');
  if (difference == 1) return tt('tomorrow');
  return tt('due_in_days', count: difference);
}

String? todoDueContext(String today, String dueDate, {required bool overdue}) {
  final difference = daysBetween(today, dueDate);
  if (difference.isNaN) return null;
  if (difference == 0) return ghTr('time_today');
  if (difference == 1) return tt('tomorrow');
  if (difference > 1) return tt('due_in_days', count: difference);
  if (overdue && difference == -1) return tt('overdue_yesterday');
  if (overdue) return tt('overdue_days', count: difference.abs());
  return null;
}
