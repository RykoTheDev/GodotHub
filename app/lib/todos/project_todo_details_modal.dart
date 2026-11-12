import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/project_todos.dart';
import '../design/design.dart';
import '../logic/last_opened.dart';
import '../logic/locale.dart';
import '../logic/open_todos.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/checkbox.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/modal_kit.dart';
import 'todo_logic.dart';
import '../ui/shell/smooth_scroll.dart';

class ProjectTodoDetailsModal extends StatefulWidget {
  const ProjectTodoDetailsModal({
    super.key,
    required this.projectId,
    required this.todo,
    required this.onOpenLink,
    required this.onUpdate,
    required this.onClose,
  });

  final String projectId;
  final ProjectTodo todo;
  final ValueChanged<ProjectTodo> onOpenLink;
  final ValueChanged<ProjectTodo> onUpdate;
  final VoidCallback onClose;

  @override
  State<ProjectTodoDetailsModal> createState() => _ProjectTodoDetailsModalState();
}

class _ProjectTodoDetailsModalState extends State<ProjectTodoDetailsModal> {
  TodoGitActivity? _activity;
  bool _activityLoading = false;

  @override
  void initState() {
    super.initState();
    final number = widget.todo.number;
    if (number == null) return;
    _activityLoading = true;
    ProjectTodosApi.activity(widget.projectId, number).then(
      (result) {
        if (mounted) {
          setState(() {
            _activity = result;
            _activityLoading = false;
          });
        }
      },
      onError: (Object _) {
        if (mounted) setState(() => _activityLoading = false);
      },
    );
  }

  Widget _section(GhTheme theme, String label, List<Widget> children, {String? suffix}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: theme.space(1.5),
    children: [
      GhFieldLabel(label, optional: suffix, inset: true),
      ...children,
    ],
  );

  Widget _tag(GhTheme theme, String label, {Color? background, Color? border}) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
    decoration: BoxDecoration(
      color: background ?? theme.raised,
      borderRadius: BorderRadius.circular(theme.radiusTag),
      border: Border.all(color: border ?? theme.outline.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
    ),
  );

  Widget _box(GhTheme theme, Widget child, {double? minHeight}) => Container(
    width: double.infinity,
    constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
    decoration: BoxDecoration(
      color: theme.overlay,
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
    ),
    child: child,
  );

  Widget _smallTag(
    GhTheme theme,
    String label, {
    required Color background,
    required Color border,
    required Color color,
    bool mono = false,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(mono ? 2 : 1.5), vertical: theme.space(0.5)),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(theme.radiusTag),
      border: Border.all(color: border),
    ),
    child: Text(
      label,
      textDirection: mono ? TextDirection.ltr : null,
      style: theme.text(size: GhTextSize.x3s, mono: mono, color: color),
    ),
  );

  Widget? _activityView(GhTheme theme, String reference) {
    final activity = _activity;
    final muted = theme.text(size: GhTextSize.xs, color: theme.muted);
    if (_activityLoading && activity == null) return Text(tt('git_activity_loading'), style: muted);
    if (activity == null || !activity.isRepo) return null;
    if (activity.branches.isEmpty && activity.commits.isEmpty) {
      return Text(tt('git_activity_empty', args: {'ref': reference}), style: muted);
    }
    return Container(
      padding: EdgeInsets.only(top: theme.space(2)),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          if (activity.branches.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: theme.space(1.5),
              runSpacing: theme.space(1.5),
              children: [
                Semantics(
                  label: tt('git_branches'),
                  child: GhIcon(GhIcons.gitBranch, size: theme.space(3), color: theme.muted),
                ),
                for (final branch in activity.branches)
                  _smallTag(
                    theme,
                    branch,
                    mono: true,
                    background: branch == activity.currentBranch ? theme.accent.withValues(alpha: 0.1) : theme.raised,
                    border: branch == activity.currentBranch ? theme.accent.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5),
                    color: branch == activity.currentBranch ? theme.accentBright : theme.ink,
                  ),
              ],
            ),
          for (final commit in activity.commits)
            Row(
              spacing: theme.space(2),
              children: [
                Text(
                  commit.shortHash,
                  textDirection: TextDirection.ltr,
                  style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
                ),
                Expanded(
                  child: GhTooltip(
                    message: '${commit.subject} · ${commit.author}',
                    child: Text(
                      commit.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.xs, color: theme.ink),
                    ),
                  ),
                ),
                if (commit.closes)
                  _smallTag(
                    theme,
                    tt('git_commit_closes'),
                    background: theme.mint.withValues(alpha: 0.15),
                    border: theme.mint.withValues(alpha: 0.3),
                    color: theme.mint,
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
    final todo = widget.todo;
    final today = localDateValue();
    final dueDate = todo.dueDate;
    final hasDue = dueDate != null && dueDate.isNotEmpty;
    final done = todo.status == TodoStatus.done;
    final overdue = hasDue && dueDate.compareTo(today) < 0 && !done;
    final dueLocal = hasDue ? todoLocalDate(dueDate) : null;
    final fullDue = dueLocal != null
        ? formatLocaleDate(dueLocal, const GhDateFormatOptions(day: GhDatePart.numeric, month: GhDatePart.long, year: GhDatePart.numeric))
        : tt('no_due_date');
    final dueContext = hasDue ? todoDueContext(today, dueDate, overdue: overdue) : null;
    final reference = todo.number != null ? '#todo-${todo.number}' : null;
    final link = todo.link;
    final linkLabel = link == null ? null : (link.line != null ? '${link.path}:${link.line}' : link.path);
    final closure = done ? todo.closedBy : null;
    final completedAt = done ? parseJsDate(todo.completedAt) : null;
    final status = todoStatusStyle(theme, todo.status);
    final priority = todo.priority;
    final checklist = todo.checklist;
    final note = theme.text(size: GhTextSize.xs, color: theme.muted);
    final viewport = MediaQuery.sizeOf(context).height;
    final activity = reference != null ? _activityView(theme, reference) : null;
    return GhModalShell(
      icon: GhIcon(GhIcons.checkCircle, size: theme.space(5), color: theme.accentBright),
      title: todo.title,
      titleMaxLines: 2,
      maxWidth: GhModalWidth.lg,
      panelHeight: math.min(720, viewport * 0.88),
      onClose: widget.onClose,
      rawFooter: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(5), theme.space(2), theme.space(5), theme.space(5)),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GhButton(onPressed: widget.onClose, label: ghTr('close'), variant: GhButtonVariant.outline),
        ),
      ),
      child: GhScrollView(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            _section(theme, tt('area'), [_tag(theme, todoAreaLabel(todo.area))]),
            if (priority != null) _section(theme, tt('priority'), [_tag(theme, todoPriorityLabel(priority))]),
            _section(theme, tt('status'), [
              _tag(theme, todoStatusLabel(todo.status), background: status.background, border: status.border),
              if (closure != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: theme.space(3)),
                  child: Text(
                    closure.kind == 'commit'
                        ? tt(
                            'closed_by_commit',
                            args: {
                              'hash': (closure.commit ?? '').substring(0, math.min(7, (closure.commit ?? '').length)),
                              'subject': closure.subject ?? '',
                            },
                          )
                        : tt('closed_by_comment_removed'),
                    style: note,
                  ),
                ),
              if (completedAt != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: theme.space(3)),
                  child: Text(
                    tt(
                      'completed_on_full',
                      args: {
                        'date': formatLocaleDateTime(
                          completedAt,
                          const GhDateFormatOptions(
                            year: GhDatePart.numeric,
                            month: GhDatePart.short,
                            day: GhDatePart.numeric,
                            hour: GhDatePart.numeric,
                            minute: GhDatePart.twoDigit,
                          ),
                        ),
                      },
                    ),
                    style: note,
                  ),
                ),
            ]),
            if (link != null && linkLabel != null)
              _section(theme, tt('linked_file'), [
                _box(
                  theme,
                  Row(
                    spacing: theme.space(3),
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GhTooltip(
                              message: linkLabel,
                              child: Text(
                                linkLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                              ),
                            ),
                            if (todo.source != null)
                              Padding(
                                padding: EdgeInsets.only(top: theme.space(0.5)),
                                child: Text(tt('source_comment', args: {'tag': todo.source!.tag}), style: note),
                              ),
                          ],
                        ),
                      ),
                      GhPressable(
                        onPressed: () => widget.onOpenLink(todo),
                        borderRadius: BorderRadius.circular(theme.radiusBtn),
                        builder: (context, states) => GhAnimatedBox(
                          color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(theme.radiusBtn),
                          border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(1.5),
                            children: [
                              GhIcon(GhIcons.externalLink, size: theme.space(3), color: states.active ? theme.ink : theme.muted),
                              Text(
                                tt('open_file'),
                                style: theme.text(
                                  size: GhTextSize.x2s,
                                  weight: GhWeight.medium,
                                  color: states.active ? theme.ink : theme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            _section(theme, ghTr('project_template_desc_label'), [
              _box(
                theme,
                minHeight: theme.space(20),
                Text(
                  (todo.description?.isNotEmpty ?? false) ? todo.description! : tt('no_description'),
                  style: theme.text(size: GhTextSize.sm, color: (todo.description?.isNotEmpty ?? false) ? theme.ink : theme.muted),
                ),
              ),
            ]),
            if (checklist.isNotEmpty)
              _section(
                theme,
                tt('checklist'),
                suffix: tt('checklist_progress', args: {'done': checklist.where((item) => item.done).length, 'total': checklist.length}),
                [
                  _box(
                    theme,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: theme.space(1),
                      children: [
                        for (final item in checklist)
                          GhCheckbox(
                            checked: item.done,
                            label: item.text,
                            onChanged: (value) => widget.onUpdate(
                              todo.copyWith(
                                checklist: [
                                  for (final entry in checklist)
                                    entry.id == item.id ? TodoChecklistItem(id: entry.id, text: entry.text, done: value) : entry,
                                ],
                              ),
                            ),
                            child: Text(
                              item.text,
                              style: theme
                                  .text(size: GhTextSize.sm, color: item.done ? theme.muted : theme.ink)
                                  .copyWith(decoration: item.done ? TextDecoration.lineThrough : null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            _section(theme, tt('due_date'), [
              _box(
                theme,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullDue,
                      style: theme.text(
                        size: GhTextSize.sm,
                        weight: GhWeight.medium,
                        color: !hasDue
                            ? theme.muted
                            : overdue
                            ? theme.danger
                            : theme.ink,
                      ),
                    ),
                    if (dueContext != null)
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(1)),
                        child: Text(
                          dueContext,
                          style: theme.text(size: GhTextSize.xs, color: overdue ? theme.danger.withValues(alpha: 0.8) : theme.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
            if (reference != null)
              _section(theme, tt('todo_reference'), [
                _box(
                  theme,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(2),
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: theme.space(2),
                        runSpacing: theme.space(2),
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                            decoration: BoxDecoration(
                              color: theme.raised,
                              borderRadius: BorderRadius.circular(theme.radiusTag),
                              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              reference,
                              textDirection: TextDirection.ltr,
                              style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                            ),
                          ),
                          Text(tt('todo_reference_hint', args: {'ref': reference}), style: note),
                        ],
                      ),
                      ?activity,
                    ],
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
