import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/project_todos.dart';
import '../design/design.dart';
import '../logic/last_opened.dart';
import '../logic/open_todos.dart';
import '../src/rust/api/types.dart';
import '../state/project_todos.dart';
import '../state/settings.dart';
import '../ui/controls/spin.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import 'project_todo_details_modal.dart';
import 'project_todo_list.dart';
import 'project_todo_modal.dart';
import 'todo_logic.dart';

class TodoBoard extends ChangeNotifier {
  TodoBoard(this.ref, this.projectId);

  final WidgetRef ref;
  final String projectId;
  final Map<String, TodoStatus> _previousStatus = {};
  TodoStatusSort? statusSort;
  TodoDueDateSort? dueDateSort = TodoDueDateSort.nearestFirst;
  String search = '';
  TodoArea? areaFilter;

  ProjectTodosState get state => ref.read(projectTodosProvider(projectId));

  ProjectTodosNotifier get notifier => ref.read(projectTodosProvider(projectId).notifier);

  List<ProjectTodo> get todos => state.todos;

  bool get manualOrder => statusSort == null && dueDateSort == null;

  Future<bool> addTodo(ProjectTodo todo) => notifier.saveTodos([...todos, todo], rememberFailure: false);

  Future<bool> updateTodo(ProjectTodo updated, {bool rememberFailure = true}) =>
      notifier.saveTodos([for (final todo in todos) todo.id == updated.id ? updated : todo], rememberFailure: rememberFailure);

  void setStatus(ProjectTodo todo, TodoStatus status) {
    _previousStatus.remove(todo.id);
    updateTodo(todo.copyWith(status: status));
  }

  void toggleCompleted(ProjectTodo todo) {
    if (todo.status == TodoStatus.done) {
      updateTodo(todo.copyWith(status: _previousStatus.remove(todo.id) ?? TodoStatus.todo));
      return;
    }
    _previousStatus[todo.id] = todo.status;
    updateTodo(todo.copyWith(status: TodoStatus.done));
  }

  void toggleStatusSort() {
    dueDateSort = null;
    statusSort = switch (statusSort) {
      null => TodoStatusSort.todoFirst,
      TodoStatusSort.todoFirst => TodoStatusSort.completedFirst,
      TodoStatusSort.completedFirst => null,
    };
    notifyListeners();
  }

  void toggleDueDateSort() {
    statusSort = null;
    dueDateSort = switch (dueDateSort) {
      null => TodoDueDateSort.nearestFirst,
      TodoDueDateSort.nearestFirst => TodoDueDateSort.farthestFirst,
      TodoDueDateSort.farthestFirst => null,
    };
    notifyListeners();
  }

  void reorder(String activeId, String overId) {
    final from = todos.indexWhere((todo) => todo.id == activeId);
    final to = todos.indexWhere((todo) => todo.id == overId);
    if (from < 0 || to < 0 || from == to) return;
    final next = [...todos];
    next.insert(to, next.removeAt(from));
    notifier.saveTodos(next);
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setAreaFilter(TodoArea? value) {
    areaFilter = value;
    notifyListeners();
  }

  void openLink(ProjectTodo todo) {
    final link = todo.link;
    if (link == null) return;
    ProjectTodosApi.openLink(projectId, link.path, link.line).catchError((Object error) => ghToasts.pushToast(GhToastType.error, '$error'));
  }

  Future<void> create(BuildContext context) => showGhModal<void>(
    context,
    (modal) => ProjectTodoModal(projectId: projectId, onClose: () => Navigator.of(modal).pop(), onSubmit: addTodo),
  );

  Future<void> edit(BuildContext context, ProjectTodo todo) => showGhModal<void>(
    context,
    (modal) => ProjectTodoModal(
      projectId: projectId,
      todo: todo,
      onClose: () => Navigator.of(modal).pop(),
      onSubmit: (saved) => updateTodo(saved, rememberFailure: false),
    ),
  );

  Future<void> view(BuildContext context, ProjectTodo todo) => showGhModal<void>(
    context,
    (modal) => Consumer(
      builder: (context, ref, _) {
        final live = ref.watch(projectTodosProvider(projectId)).todos.where((t) => t.id == todo.id).firstOrNull ?? todo;
        return ProjectTodoDetailsModal(
          projectId: projectId,
          todo: live,
          onOpenLink: openLink,
          onUpdate: (next) => updateTodo(next),
          onClose: () => Navigator.of(modal).pop(),
        );
      },
    ),
  );

  Future<void> delete(BuildContext context, ProjectTodo todo) async {
    final theme = GhTheme.of(context);
    final ok = await showGhConfirmDialog(
      context,
      title: tt('delete_task_title'),
      descriptionContent: Text.rich(
        TextSpan(
          children: ghTrans(
            tt('delete_task_description', args: {'title': todo.title}),
            tags: {
              'strong': (text, children) => TextSpan(
                children: children,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            },
          ),
        ),
        style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
      ),
      confirmLabel: ghTr('delete'),
      variant: GhConfirmVariant.danger,
    );
    if (ok) {
      await notifier.saveTodos([
        for (final entry in todos)
          if (entry.id != todo.id) entry,
      ]);
    }
  }

  Future<void> showAll(BuildContext context) =>
      showGhModal<void>(context, (modal) => ProjectTodoListModal(board: this, onClose: () => Navigator.of(modal).pop()));
}

class _AccentAction extends StatelessWidget {
  const _AccentAction({required this.label, required this.onPressed, this.large = false});

  final String label;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      disabledOpacity: 0.5,
      disabledCursor: SystemMouseCursors.forbidden,
      builder: (context, states) => GhAnimatedBox(
        color: theme.accent.withValues(alpha: states.active ? 0.2 : 0.1),
        borderRadius: radius,
        border: Border.all(color: theme.accent.withValues(alpha: states.active ? 0.5 : 0.3)),
        padding: EdgeInsets.symmetric(horizontal: theme.space(large ? 3 : 2.5), vertical: theme.space(1.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            Text(
              '+',
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.accentBright),
            ),
            Text(
              label,
              style: theme.text(size: large ? GhTextSize.x2s : GhTextSize.x3s, weight: GhWeight.medium, color: theme.accentBright),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = GhTextSize.x3s,
    this.px = 2.5,
    this.accentBorder = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final FaIconData? icon;
  final GhTextSize size;
  final double px;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      disabledOpacity: 0.5,
      disabledCursor: SystemMouseCursors.forbidden,
      builder: (context, states) {
        final color = states.active ? theme.ink : theme.muted;
        return GhAnimatedBox(
          color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          border: Border.all(color: states.active && accentBorder ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(px), vertical: theme.space(1.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              if (icon != null) GhIcon(icon!, size: theme.space(3), color: color),
              Text(
                label,
                style: theme.text(size: size, weight: icon != null ? GhWeight.medium : GhWeight.normal, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProjectTodoListModal extends ConsumerStatefulWidget {
  const ProjectTodoListModal({super.key, required this.board, required this.onClose});

  final TodoBoard board;
  final VoidCallback onClose;

  @override
  ConsumerState<ProjectTodoListModal> createState() => _ProjectTodoListModalState();
}

class _ProjectTodoListModalState extends ConsumerState<ProjectTodoListModal> {
  late final TextEditingController _search = TextEditingController(text: widget.board.search);

  @override
  void initState() {
    super.initState();
    widget.board.addListener(_changed);
  }

  @override
  void dispose() {
    widget.board.removeListener(_changed);
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final board = widget.board;
    final state = ref.watch(projectTodosProvider(board.projectId));
    final settings = ref.watch(settingsProvider).value;
    final todos = state.todos;
    final pending = todos.where((todo) => todo.status != TodoStatus.done).length;
    final sorted = sortProjectTodos(todos, board.statusSort, board.dueDateSort);
    final query = board.search.trim().toLowerCase();
    final area = board.areaFilter;
    final visible = [
      for (final todo in fullTodoOrder(todos, sorted))
        if ((area == null || todo.area == area) && todoMatchesSearch(todo, query)) todo,
    ];
    final radius = BorderRadius.circular(theme.radiusBtn);
    final count = theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted);
    return GhModalShell(
      icon: GhIcon(GhIcons.checkCircle, size: theme.space(5), color: theme.accentBright),
      title: tt('next_steps'),
      maxWidth: GhModalWidth.x6l,
      panelHeight: math.min(760, MediaQuery.sizeOf(context).height * 0.9),
      onClose: widget.onClose,
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: theme.space(4)),
              child: Row(
                spacing: theme.space(4),
                children: [
                  Text.rich(
                    TextSpan(
                      text: tt('pending_count', count: pending),
                      children: [
                        TextSpan(
                          text: '  •  ',
                          style: TextStyle(color: theme.muted.withValues(alpha: 0.4)),
                        ),
                        TextSpan(text: tt('completed_count', count: todos.length - pending)),
                      ],
                    ),
                    style: count,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: theme.space(2),
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: theme.space(64)),
                            child: GhTextInput(
                              controller: _search,
                              onChanged: board.setSearch,
                              placeholder: tt('search_tasks_placeholder'),
                              semanticLabel: tt('search_tasks_placeholder'),
                              size: GhTextSize.x2s,
                              background: theme.overlay,
                              placeholderColor: theme.muted.withValues(alpha: 0.6),
                              borderColor: theme.outline.withValues(alpha: 0.5),
                              focusBorderColor: theme.accentDim,
                              borderRadius: radius,
                              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                            ),
                          ),
                        ),
                        GhDropdown(
                          compact: true,
                          items: [
                            GhMenuItem(
                              id: 'all',
                              label: tt('all_areas'),
                              active: area == null,
                              onSelected: () => board.setAreaFilter(null),
                            ),
                            for (final option in TodoArea.values)
                              GhMenuItem(
                                id: option.name,
                                label: todoAreaLabel(option),
                                active: area == option,
                                onSelected: () => board.setAreaFilter(option),
                              ),
                          ],
                          trigger: (context, open, toggle) => GhPressable(
                            onPressed: toggle,
                            expanded: open,
                            borderRadius: radius,
                            builder: (context, states) => GhAnimatedBox(
                              color: theme.overlay,
                              borderRadius: radius,
                              border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: theme.space(1.5),
                                children: [
                                  Text(
                                    area == null ? tt('all_areas') : todoAreaLabel(area),
                                    style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.ink),
                                  ),
                                  GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _AccentAction(label: tt('new_task'), large: true, onPressed: state.saving ? null : () => board.create(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(end: theme.space(1)),
                child: visible.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: theme.space(10)),
                        child: Text(
                          tt('no_matching_tasks'),
                          textAlign: TextAlign.center,
                          style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                        ),
                      )
                    : ProjectTodoList(
                        todos: visible,
                        today: localDateValue(),
                        disabled: state.saving,
                        statusSort: board.statusSort,
                        dueDateSort: board.dueDateSort,
                        dateFormat: LastOpenedDateFormat.parse(settings?.lastOpenedDateFormat),
                        showArea: true,
                        onOpenLink: board.openLink,
                        reorderable: board.manualOrder && !state.saving,
                        onReorder: board.reorder,
                        onToggleStatusSort: board.toggleStatusSort,
                        onToggleDueDateSort: board.toggleDueDateSort,
                        onToggleCompleted: board.toggleCompleted,
                        onSetStatus: board.setStatus,
                        onUpdate: (todo) => board.updateTodo(todo),
                        onView: (todo) => board.view(context, todo),
                        onEdit: (todo) => board.edit(context, todo),
                        onDelete: (todo) => board.delete(context, todo),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectTodoPanel extends ConsumerStatefulWidget {
  const ProjectTodoPanel({super.key, required this.projectId, required this.onLoaded, required this.onClose});

  final String projectId;
  final VoidCallback onLoaded;
  final VoidCallback onClose;

  @override
  ConsumerState<ProjectTodoPanel> createState() => _ProjectTodoPanelState();
}

class _ProjectTodoPanelState extends ConsumerState<ProjectTodoPanel> {
  late final TodoBoard _board = TodoBoard(ref, widget.projectId)..addListener(_changed);
  final TextEditingController _quick = TextEditingController();
  bool _scanning = false;
  bool _autoSynced = false;
  bool _reportedLoaded = false;

  @override
  void dispose() {
    _board
      ..removeListener(_changed)
      ..dispose();
    _quick.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _commitToast(TodoSyncResult result) {
    final closed = result.closedByCommits.toInt();
    if (closed > 0) ghToasts.pushToast(GhToastType.success, tt('commit_closed', count: closed));
  }

  void _onState(ProjectTodosState state) {
    if (!state.loaded) return;
    if (!_reportedLoaded) {
      _reportedLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoaded();
      });
    }
    if (state.error != null || _autoSynced) return;
    _autoSynced = true;
    _board.notifier.sync(false).then(_commitToast, onError: (Object _) {});
  }

  Future<void> _scanCode() async {
    setState(() => _scanning = true);
    try {
      final result = await _board.notifier.sync(true);
      final imported = result.imported.toInt();
      final closed = result.closed.toInt();
      final reopened = result.reopened.toInt();
      ghToasts.pushToast(
        GhToastType.success,
        imported + closed + reopened == 0
            ? tt('comment_scan_none')
            : tt('comment_scan_summary', args: {'imported': imported, 'closed': closed, 'reopened': reopened}),
      );
      _commitToast(result);
    } catch (error) {
      ghToasts.pushToast(GhToastType.error, '$error');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _quickAdd() async {
    final title = _quick.text.trim();
    if (title.isEmpty || _board.state.saving) return;
    final added = await _board.addTodo(
      ProjectTodo(
        id: newTodoId(),
        title: title,
        status: TodoStatus.todo,
        area: TodoArea.other,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        checklist: const [],
      ),
    );
    if (added) {
      _quick.clear();
    } else {
      ghToasts.pushToast(GhToastType.error, tt('save_task_failed'));
    }
  }

  Widget _placeholder(
    GhTheme theme, {
    Color? tone,
    FaIconData? icon,
    String? title,
    required String text,
    Widget? action,
    String? tooltip,
    bool danger = false,
  }) {
    final box = Container(
      margin: EdgeInsets.fromLTRB(theme.space(3.5), 0, theme.space(3.5), theme.space(2)),
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(10)),
      decoration: BoxDecoration(
        color: danger ? theme.danger.withValues(alpha: 0.05) : null,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: danger ? theme.danger.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          if (icon != null && tone != null)
            Container(
              width: theme.space(9),
              height: theme.space(9),
              margin: EdgeInsets.only(bottom: theme.space(3)),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tone.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: GhIcon(icon, size: theme.space(4), color: tone),
            ),
          if (title != null)
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: danger ? theme.danger : theme.ink),
            ),
          Padding(
            padding: EdgeInsets.only(top: title != null ? theme.space(1) : 0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.text(size: GhTextSize.x2s, color: theme.muted),
            ),
          ),
          if (action != null)
            Padding(
              padding: EdgeInsets.only(top: theme.space(4)),
              child: action,
            ),
        ],
      ),
    );
    return tooltip != null ? GhTooltip(message: tooltip, child: box) : box;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final state = ref.watch(projectTodosProvider(widget.projectId));
    ref.listen(projectTodosProvider(widget.projectId), (_, next) => _onState(next));
    _onState(state);
    final settings = ref.watch(settingsProvider).value;
    final board = _board;
    final todos = state.todos;
    final saving = state.saving;
    final error = state.error;
    final saveError = state.saveError;
    final pending = todos.where((todo) => todo.status != TodoStatus.done).length;
    final sorted = sortProjectTodos(todos, board.statusSort, board.dueDateSort);
    final compact = sorted.where((todo) => todo.status != TodoStatus.done).take(5).toList();
    final gutter = EdgeInsets.fromLTRB(theme.space(3.5), 0, theme.space(3.5), theme.space(2));
    final Widget body;
    if (state.loading) {
      body = _placeholder(theme, text: tt('loading_tasks'));
    } else if (error != null) {
      body = _placeholder(
        theme,
        danger: true,
        tooltip: error,
        title: tt('load_tasks_failed'),
        text: tt('data_unchanged'),
        action: _QuietAction(label: ghTr('try_again'), size: GhTextSize.x2s, px: 3, accentBorder: false, onPressed: board.notifier.refresh),
      );
    } else if (todos.isEmpty) {
      body = _placeholder(
        theme,
        tone: theme.accentBright,
        icon: GhIcons.checkCircle,
        title: tt('empty_title'),
        text: tt('empty_description'),
        action: _AccentAction(label: tt('create_task'), large: true, onPressed: saving ? null : () => board.create(context)),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending == 0)
            _placeholder(
              theme,
              tone: theme.mint,
              icon: GhIcons.checkCircle,
              title: tt('all_completed_title'),
              text: tt('all_completed_description'),
            )
          else
            Padding(
              padding: gutter,
              child: ProjectTodoList(
                todos: compact,
                today: localDateValue(),
                disabled: saving,
                statusSort: board.statusSort,
                dueDateSort: board.dueDateSort,
                dateFormat: LastOpenedDateFormat.parse(settings?.lastOpenedDateFormat),
                onOpenLink: board.openLink,
                reorderable: board.manualOrder && !saving,
                onReorder: board.reorder,
                onToggleStatusSort: board.toggleStatusSort,
                onToggleDueDateSort: board.toggleDueDateSort,
                onToggleCompleted: board.toggleCompleted,
                onSetStatus: board.setStatus,
                onUpdate: (todo) => board.updateTodo(todo),
                onView: (todo) => board.view(context, todo),
                onEdit: (todo) => board.edit(context, todo),
                onDelete: (todo) => board.delete(context, todo),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(theme.space(3.5), 0, theme.space(3.5), theme.space(2.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: theme.space(3),
              children: [
                Flexible(
                  child: Text(
                    tt('footer_hint'),
                    style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                  ),
                ),
                _QuietAction(label: tt('view_all'), onPressed: () => board.showAll(context)),
              ],
            ),
          ),
        ],
      );
    }
    final side = BorderSide(color: theme.outline.withValues(alpha: 0.5));
    return Container(
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(theme.radiusItem)),
        border: Border(left: side, right: side, bottom: side),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tt('next_steps').toUpperCase(),
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.025),
                ),
                SizedBox(
                  width: theme.space(3),
                  height: theme.space(3),
                  child: saving
                      ? Semantics(
                          label: tt('saving_tasks'),
                          child: GhSpinning(
                            child: CircularProgressIndicator(
                              value: 0.25,
                              strokeWidth: 2,
                              color: theme.accentBright,
                              backgroundColor: theme.accentDim.withValues(alpha: 0.3),
                            ),
                          ),
                        )
                      : null,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(3),
                  children: [
                    Text(
                      tt('pending_count', count: pending),
                      style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted),
                    ),
                    GhTooltip(
                      message: tt('scan_code_hint'),
                      child: _QuietAction(
                        label: _scanning ? ghTr('scanning') : tt('scan_code'),
                        icon: GhIcons.code,
                        onPressed: saving || _scanning || !state.loaded || error != null ? null : _scanCode,
                      ),
                    ),
                    _AccentAction(label: tt('new_task'), onPressed: saving ? null : () => board.create(context)),
                    GhPressable(
                      onPressed: widget.onClose,
                      semanticLabel: tt('hide_next_steps'),
                      borderRadius: BorderRadius.circular(theme.radiusBtn),
                      builder: (context, states) => GhIcon(GhIcons.chevronUp, size: theme.space(3), color: theme.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (saveError != null)
            GhTooltip(
              message: saveError,
              child: Semantics(
                liveRegion: true,
                child: Container(
                  margin: gutter,
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                  decoration: BoxDecoration(
                    color: theme.danger.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: theme.space(3),
                    children: [
                      Flexible(
                        child: Text(
                          tt('save_changes_failed'),
                          style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                        ),
                      ),
                      GhPressable(
                        onPressed: saving ? null : () => board.notifier.retrySave(),
                        borderRadius: BorderRadius.circular(theme.radiusBtn),
                        disabledOpacity: 0.5,
                        disabledCursor: SystemMouseCursors.forbidden,
                        builder: (context, states) => GhAnimatedBox(
                          color: theme.danger.withValues(alpha: states.active ? 0.1 : 0),
                          borderRadius: BorderRadius.circular(theme.radiusBtn),
                          border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                          child: Text(
                            ghTr('try_again'),
                            style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (state.loaded && error == null)
            Padding(
              padding: gutter,
              child: GhTextInput(
                controller: _quick,
                enabled: !saving,
                dashed: true,
                onSubmitted: (_) => _quickAdd(),
                placeholder: tt('quick_add_placeholder'),
                semanticLabel: tt('quick_add_placeholder'),
                size: GhTextSize.x2s,
                background: theme.base.withValues(alpha: 0.4),
                placeholderColor: theme.muted.withValues(alpha: 0.6),
                borderColor: theme.outline.withValues(alpha: 0.6),
                focusBorderColor: theme.accentDim,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
              ),
            ),
          body,
        ],
      ),
    );
  }
}
