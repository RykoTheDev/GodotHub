import 'package:flutter/material.dart';

import '../design/design.dart';
import '../logic/last_opened.dart';
import '../logic/locale.dart';
import '../logic/open_todos.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/dnd/sortable.dart';
import '../ui/overlays/date_picker.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import 'todo_logic.dart';
import '../ui/shell/smooth_scroll.dart';

class ProjectTodoList extends StatelessWidget {
  const ProjectTodoList({
    super.key,
    required this.todos,
    required this.today,
    required this.statusSort,
    required this.dueDateSort,
    required this.dateFormat,
    this.showArea = false,
    this.disabled = false,
    required this.onToggleStatusSort,
    required this.onToggleDueDateSort,
    required this.onToggleCompleted,
    required this.onSetStatus,
    required this.onUpdate,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.onOpenLink,
    this.reorderable = false,
    this.onReorder,
  });

  final List<ProjectTodo> todos;
  final String today;
  final TodoStatusSort? statusSort;
  final TodoDueDateSort? dueDateSort;
  final LastOpenedDateFormat dateFormat;
  final bool showArea;
  final bool disabled;
  final VoidCallback onToggleStatusSort;
  final VoidCallback onToggleDueDateSort;
  final ValueChanged<ProjectTodo> onToggleCompleted;
  final void Function(ProjectTodo todo, TodoStatus status) onSetStatus;
  final ValueChanged<ProjectTodo> onUpdate;
  final ValueChanged<ProjectTodo> onView;
  final ValueChanged<ProjectTodo> onEdit;
  final ValueChanged<ProjectTodo> onDelete;
  final ValueChanged<ProjectTodo>? onOpenLink;
  final bool reorderable;
  final void Function(String activeId, String overId)? onReorder;

  double _statusWidth(GhTheme theme) => showArea ? theme.space(28) : 88;

  double _dueWidth(GhTheme theme) => theme.space(showArea ? 28 : 24);

  String _due(String? dueDate) => formatTodoDueDate(dueDate, today, dateFormat);

  Widget _header(
    GhTheme theme, {
    required String label,
    required String arrow,
    required String tooltip,
    required double width,
    required VoidCallback onPressed,
  }) => GhTooltip(
    message: tooltip,
    child: GhPressable(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      builder: (context, states) => GhAnimatedBox(
        width: width,
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        alignment: Alignment.center,
        child: Text(
          '${label.toUpperCase()} $arrow',
          maxLines: 1,
          style: theme.text(
            size: GhTextSize.x4s,
            weight: GhWeight.medium,
            color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.6),
            letterSpacingEm: 0.025,
          ),
        ),
      ),
    ),
  );

  Widget _columnLabel(GhTheme theme, String label) => Text(
    label.toUpperCase(),
    style: theme.text(size: GhTextSize.x4s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.6), letterSpacingEm: 0.025),
  );

  Widget _statusControl(GhTheme theme, ProjectTodo todo) {
    final style = todoStatusStyle(theme, todo.status);
    final label = todoStatusLabel(todo.status);
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhDropdown(
      align: GhSide.right,
      compact: true,
      activeStyle: GhMenuActiveStyle.raised,
      menuMinWidth: theme.space(40),
      items: [
        for (final status in todoStatuses)
          GhMenuItem(
            id: status.name,
            label: todoStatusLabel(status),
            leading: Padding(
              padding: EdgeInsetsDirectional.only(end: theme.space(1)),
              child: Container(
                width: theme.space(2),
                height: theme.space(2),
                decoration: BoxDecoration(color: todoStatusStyle(theme, status).dot, shape: BoxShape.circle),
              ),
            ),
            shortcut: todo.status == status ? '✓' : null,
            active: todo.status == status,
            onSelected: () => onSetStatus(todo, status),
          ),
      ],
      trigger: (context, open, toggle) => GhPressable(
        onPressed: disabled ? null : toggle,
        expanded: open,
        borderRadius: radius,
        disabledOpacity: 0.5,
        disabledCursor: SystemMouseCursors.forbidden,
        semanticLabel: tt('change_status', args: {'status': label}),
        builder: (context, states) => GhAnimatedBox(
          width: showArea ? _statusWidth(theme) : null,
          constraints: showArea ? null : BoxConstraints(minWidth: _statusWidth(theme)),
          color: states.active ? Color.alphaBlend(Colors.black.withValues(alpha: 0.05), style.background) : style.background,
          borderRadius: radius,
          border: Border.all(color: open ? theme.accent.withValues(alpha: 0.4) : style.border),
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            style: theme.text(size: GhTextSize.x3s, color: theme.ink),
          ),
        ),
      ),
    );
  }

  Widget _dueControl(GhTheme theme, ProjectTodo todo, {required bool completed, required bool overdue}) {
    final width = _dueWidth(theme);
    if (completed) {
      final completedAt = parseJsDate(todo.completedAt);
      final text = Text(
        completedAt != null ? tt('completed_on', args: {'date': _due(localDateValue(completedAt))}) : '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.text(size: GhTextSize.x3s, color: theme.mint.withValues(alpha: 0.8)),
      );
      return SizedBox(
        width: width,
        child: completedAt != null ? GhTooltip(message: formatLocaleDateTime(completedAt), child: text) : text,
      );
    }
    final label = Text(
      _due(todo.dueDate),
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      style: overdue ? TextStyle(color: theme.danger, fontWeight: FontWeight.w500) : null,
    );
    return SizedBox(
      width: width,
      child: Align(
        child: GhDatePicker(
          value: todo.dueDate ?? '',
          clearLabel: tt('remove_due_date'),
          disabled: disabled,
          compact: true,
          markPastDates: true,
          onChanged: (dueDate) => onUpdate(todo.copyWith(dueDate: () => dueDate.isEmpty ? null : dueDate)),
          displayValue: overdue ? GhTooltip(message: tt('overdue'), child: label) : label,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ProjectTodo todo, {required bool last}) {
    final theme = GhTheme.of(context);
    final completed = todo.status == TodoStatus.done;
    final dueDate = todo.dueDate;
    final overdue = dueDate != null && dueDate.isNotEmpty && dueDate.compareTo(today) < 0 && !completed;
    final priority = todo.priority;
    final link = todo.link;
    final checklist = todo.checklist;
    final doneItems = checklist.where((item) => item.done).length;
    final statusControl = _statusControl(theme, todo);
    final dueControl = _dueControl(theme, todo, completed: completed, overdue: overdue);
    final small = BorderRadius.circular(theme.radiusBtn);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
      ),
      child: Row(
        spacing: theme.space(3),
        children: [
          GhPressable(
            onPressed: disabled ? null : () => onToggleCompleted(todo),
            borderRadius: small,
            disabledOpacity: 0.5,
            disabledCursor: SystemMouseCursors.forbidden,
            semanticLabel: completed ? tt('mark_not_completed') : tt('mark_completed'),
            builder: (context, states) => SizedBox(
              width: theme.space(5),
              height: theme.space(5),
              child: Center(
                child: completed
                    ? GhIcon(GhIcons.check, size: theme.space(3.5), color: theme.mint)
                    : GhAnimatedBox(
                        width: theme.space(3.5),
                        height: theme.space(3.5),
                        borderRadius: BorderRadius.circular(theme.rem(0.25)),
                        border: Border.all(color: states.hovered ? theme.mint : theme.outline),
                        child: const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
          if (priority != null)
            GhTooltip(
              message: tt('priority_label', args: {'priority': todoPriorityLabel(priority)}),
              child: Semantics(
                label: tt('priority_label', args: {'priority': todoPriorityLabel(priority)}),
                child: Container(
                  width: theme.space(1.5),
                  height: theme.space(1.5),
                  decoration: BoxDecoration(color: todoPriorityColor(theme, priority), shape: BoxShape.circle),
                ),
              ),
            ),
          if (todo.number != null)
            Text(
              '#${todo.number}',
              textDirection: TextDirection.ltr,
              style: theme.text(size: GhTextSize.x4s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
            ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GhTooltip(
                message: todo.title,
                child: GhPressable(
                  onPressed: () => onView(todo),
                  borderRadius: small,
                  semanticLabel: tt('view_task_details', args: {'title': todo.title}),
                  builder: (context, states) => AnimatedDefaultTextStyle(
                    duration: GhDurations.color,
                    style: theme
                        .text(
                          size: GhTextSize.x2s,
                          color: completed ? (states.active ? theme.ink : theme.muted) : (states.active ? theme.accentBright : theme.ink),
                        )
                        .copyWith(decoration: completed ? TextDecoration.lineThrough : null),
                    child: Text(todo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
          ),
          if (checklist.isNotEmpty)
            GhTooltip(
              message: tt('checklist_progress', args: {'done': doneItems, 'total': checklist.length}),
              child: Text(
                '$doneItems/${checklist.length}',
                style: theme.text(size: GhTextSize.x4s, mono: true, color: theme.muted),
              ),
            ),
          if (link != null && onOpenLink != null)
            GhTooltip(
              message: tt('open_linked_file', args: {'path': link.line != null ? '${link.path}:${link.line}' : link.path}),
              child: GhPressable(
                onPressed: () => onOpenLink!(todo),
                borderRadius: small,
                semanticLabel: tt('open_linked_file', args: {'path': link.path}),
                builder: (context, states) => GhAnimatedBox(
                  width: theme.space(5),
                  height: theme.space(5),
                  color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                  borderRadius: small,
                  alignment: Alignment.center,
                  child: GhIcon(GhIcons.code, size: theme.space(3), color: states.active ? theme.accentBright : theme.muted),
                ),
              ),
            ),
          if (showArea)
            Container(
              width: theme.space(28),
              padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.raised,
                borderRadius: BorderRadius.circular(theme.radiusTag),
                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              ),
              child: Text(
                todoAreaLabel(todo.area),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.ink),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(2),
            children: [
              if (showArea) ...[dueControl, statusControl] else ...[statusControl, dueControl],
              GhDropdown(
                align: GhSide.right,
                compact: true,
                items: [
                  GhMenuItem(id: 'edit', label: tt('edit'), icon: GhIcons.pencil, dividerAfter: true, onSelected: () => onEdit(todo)),
                  GhMenuItem(id: 'delete', label: ghTr('delete'), icon: GhIcons.trash, danger: true, onSelected: () => onDelete(todo)),
                ],
                trigger: (context, open, toggle) => GhPressable(
                  onPressed: disabled ? null : toggle,
                  expanded: open,
                  borderRadius: small,
                  disabledOpacity: 0.5,
                  disabledCursor: SystemMouseCursors.forbidden,
                  semanticLabel: tt('task_actions'),
                  builder: (context, states) {
                    final lit = open || states.active;
                    return GhAnimatedBox(
                      width: theme.space(6),
                      height: theme.space(6),
                      color: lit ? theme.raised : theme.raised.withValues(alpha: 0),
                      borderRadius: small,
                      alignment: Alignment.center,
                      child: GhIcon(GhIcons.more, size: theme.space(3.5), color: lit ? theme.ink : theme.muted),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final statusHeader = _header(
      theme,
      label: tt('status'),
      arrow: switch (statusSort) {
        TodoStatusSort.completedFirst => '↓',
        TodoStatusSort.todoFirst => '↑',
        null => '',
      },
      tooltip: tt('sort_by_status'),
      width: _statusWidth(theme),
      onPressed: onToggleStatusSort,
    );
    final dueHeader = _header(
      theme,
      label: tt('due_date'),
      arrow: switch (dueDateSort) {
        TodoDueDateSort.nearestFirst => '↑',
        TodoDueDateSort.farthestFirst => '↓',
        null => '',
      },
      tooltip: tt('sort_by_due_date'),
      width: _dueWidth(theme),
      onPressed: onToggleDueDateSort,
    );
    final list = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(theme.space(3)),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
            ),
            child: Row(
              spacing: theme.space(3),
              children: [
                SizedBox(width: theme.space(3.5)),
                Expanded(child: _columnLabel(theme, tt('task'))),
                if (showArea)
                  SizedBox(
                    width: theme.space(28),
                    child: Center(child: _columnLabel(theme, tt('area'))),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(2),
                  children: [
                    if (showArea) ...[dueHeader, statusHeader] else ...[statusHeader, dueHeader],
                    SizedBox(width: theme.space(6)),
                  ],
                ),
              ],
            ),
          ),
          GhDndScope(
            enabled: reorderable,
            onDragEnd: (activeId, overId) {
              if (overId != null && overId != activeId) onReorder?.call(activeId, overId);
            },
            overlayBuilder: (context, id) {
              final todo = todos.where((t) => t.id == id).firstOrNull;
              return todo == null ? const SizedBox.shrink() : ColoredBox(color: theme.overlay, child: _row(context, todo, last: true));
            },
            child: GhSortableContext(
              items: [for (final todo in todos) todo.id],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < todos.length; i++)
                    GhSortableItem(
                      key: ValueKey(todos[i].id),
                      id: todos[i].id,
                      semanticLabel: todos[i].title,
                      disabled: !reorderable,
                      child: _row(context, todos[i], last: i == todos.length - 1),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (!showArea) return list;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 640
          ? list
          : GhScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 640, child: list),
            ),
    );
  }
}
