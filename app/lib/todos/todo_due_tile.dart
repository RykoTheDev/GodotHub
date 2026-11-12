import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../logic/open_todos.dart';
import '../src/rust/api/types.dart';
import '../state/open_todos_sync.dart';
import '../ui/core/interaction.dart';
import 'todo_logic.dart';

class TodoDueTile extends ConsumerWidget {
  const TodoDueTile({super.key, this.tall = false});

  final bool tall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final snapshot = ref.watch(openTodosProvider);
    final radius = BorderRadius.circular(theme.radiusItem);
    final border = Border.all(color: theme.outline.withValues(alpha: 0.5));
    if (!snapshot.loaded) {
      return Container(
        height: theme.space(16),
        decoration: BoxDecoration(color: theme.overlay, borderRadius: radius, border: border),
      );
    }
    final today = localDateValue();
    final weekEnd = addDaysValue(today, 6);
    final dated = [
      for (var i = 0; i < snapshot.todos.length; i++)
        if (snapshot.todos[i].todo.dueDate?.isNotEmpty ?? false) (open: snapshot.todos[i], index: i),
    ];
    dated.sort((a, b) {
      final date = a.open.todo.dueDate!.compareTo(b.open.todo.dueDate!);
      if (date != 0) return date;
      final rank = rankOf(a.open.todo.priority) - rankOf(b.open.todo.priority);
      return rank != 0 ? rank : a.index - b.index;
    });
    final overdue = <OpenTodo>[
      for (final e in dated)
        if (e.open.todo.dueDate!.compareTo(today) < 0) e.open,
    ];
    final soon = <OpenTodo>[
      for (final e in dated)
        if (e.open.todo.dueDate!.compareTo(today) >= 0 && e.open.todo.dueDate!.compareTo(weekEnd) <= 0) e.open,
    ];
    final rows = [...overdue, ...soon].take(tall ? 10 : 5).toList();
    final hidden = overdue.length + soon.length - rows.length;
    if (rows.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: theme.overlay, borderRadius: radius, border: border),
        child: Text(
          tt('tile_empty'),
          style: theme.text(size: GhTextSize.xs, color: theme.muted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: theme.space(2),
      children: [
        Text(
          tt('tile_summary', args: {'overdue': overdue.length, 'soon': soon.length}),
          style: theme.text(size: GhTextSize.x2s, color: theme.muted),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            for (final open in rows)
              GhPressable(
                key: ValueKey('${open.projectId}:${open.todo.id}'),
                onPressed: () => requestTodoFocus(open.projectId),
                borderRadius: radius,
                builder: (context, states) {
                  final late = open.todo.dueDate!.compareTo(today) < 0;
                  final priority = open.todo.priority;
                  return GhAnimatedBox(
                    color: states.active ? theme.raised : theme.overlay,
                    borderRadius: radius,
                    border: Border.all(
                      color: states.active ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                    child: Row(
                      spacing: theme.space(3),
                      children: [
                        if (priority != null)
                          Semantics(
                            label: todoPriorityLabel(priority),
                            child: Container(
                              width: theme.space(1.5),
                              height: theme.space(1.5),
                              decoration: BoxDecoration(color: todoPriorityColor(theme, priority), shape: BoxShape.circle),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                open.todo.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.sm, color: theme.ink),
                              ),
                              Text(
                                open.projectName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          todoDueLabel(today, open.todo.dueDate!),
                          style: theme
                              .text(
                                size: GhTextSize.x2s,
                                weight: late ? GhWeight.medium : GhWeight.normal,
                                color: late ? theme.danger : theme.muted,
                              )
                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        if (hidden > 0)
          Text(
            tt('due_notification_more', args: {'count': hidden}),
            style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.7)),
          ),
      ],
    );
  }
}
