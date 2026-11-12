import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/project_todos.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/overlays/date_picker.dart';
import '../ui/reusables/modal_kit.dart';
import 'todo_logic.dart';

class ProjectTodoModal extends StatefulWidget {
  const ProjectTodoModal({super.key, required this.projectId, required this.onClose, required this.onSubmit, this.todo});

  final String projectId;
  final VoidCallback onClose;
  final Future<bool> Function(ProjectTodo todo) onSubmit;
  final ProjectTodo? todo;

  @override
  State<ProjectTodoModal> createState() => _ProjectTodoModalState();
}

class _ProjectTodoModalState extends State<ProjectTodoModal> {
  late final TextEditingController _title = TextEditingController(text: widget.todo?.title ?? '');
  late final TextEditingController _description = TextEditingController(text: widget.todo?.description ?? '');
  late final TextEditingController _link = TextEditingController(text: widget.todo?.link?.path ?? '');
  final TextEditingController _newItem = TextEditingController();
  final FocusNode _linkNode = FocusNode(debugLabel: 'ProjectTodoModal link');
  final Map<String, TextEditingController> _itemControllers = {};
  late String _dueDate = widget.todo?.dueDate ?? '';
  late TodoStatus _status = widget.todo?.status ?? TodoStatus.todo;
  late TodoArea _area = widget.todo?.area ?? TodoArea.other;
  late TodoPriority? _priority = widget.todo?.priority;
  late List<TodoChecklistItem> _checklist = [...?widget.todo?.checklist];
  List<String> _resources = const [];
  bool _submitting = false;
  bool _submitError = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_title, _description, _link, _newItem]) {
      controller.addListener(_changed);
    }
    ProjectTodosApi.resources(widget.projectId).then((list) {
      if (mounted) setState(() => _resources = list);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    for (final controller in [_title, _description, _link, _newItem, ..._itemControllers.values]) {
      controller.dispose();
    }
    _linkNode.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  TextEditingController _itemController(TodoChecklistItem item) => _itemControllers.putIfAbsent(item.id, () {
    final controller = TextEditingController(text: item.text);
    controller.addListener(() {
      final text = controller.text;
      setState(() {
        _checklist = [
          for (final entry in _checklist) entry.id == item.id ? TodoChecklistItem(id: entry.id, text: text, done: entry.done) : entry,
        ];
      });
    });
    return controller;
  });

  void _addChecklistItem() {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    setState(() => _checklist = [..._checklist, TodoChecklistItem(id: newTodoId(), text: text, done: false)]);
    _newItem.clear();
  }

  void _removeChecklistItem(String id) {
    setState(
      () => _checklist = [
        for (final entry in _checklist)
          if (entry.id != id) entry,
      ],
    );
    final controller = _itemControllers.remove(id);
    if (controller != null) WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  String get _trimmedTitle => _title.text.trim();

  String get _trimmedLink => _link.text.trim();

  bool get _linkInvalid => _trimmedLink.isNotEmpty && !_trimmedLink.startsWith('res://');

  bool get _hasChanges {
    final todo = widget.todo;
    if (todo == null) return true;
    return _trimmedTitle != todo.title ||
        _description.text.trim() != (todo.description ?? '') ||
        _dueDate != (todo.dueDate ?? '') ||
        _status != todo.status ||
        _area != todo.area ||
        _trimmedLink != (todo.link?.path ?? '') ||
        _priority != todo.priority ||
        _newItem.text.trim().isNotEmpty ||
        !listEquals(_checklist, todo.checklist);
  }

  bool get _canSubmit => _trimmedTitle.isNotEmpty && _hasChanges && !_submitting && !_linkInvalid;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final todo = widget.todo;
    final link = _trimmedLink.isEmpty
        ? null
        : TodoLink(path: _trimmedLink, line: todo?.link?.path == _trimmedLink ? todo?.link?.line : null);
    final pending = _newItem.text.trim();
    final checklist = [
      for (final item in [..._checklist, if (pending.isNotEmpty) TodoChecklistItem(id: newTodoId(), text: pending, done: false)])
        if (item.text.trim().isNotEmpty) TodoChecklistItem(id: item.id, text: item.text.trim(), done: item.done),
    ];
    final description = _description.text.trim();
    final saved = ProjectTodo(
      id: todo?.id ?? newTodoId(),
      title: _trimmedTitle,
      status: _status,
      area: _area,
      dueDate: _dueDate.isEmpty ? null : _dueDate,
      description: description.isEmpty ? null : description,
      createdAt: todo?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
      number: todo?.number,
      link: link,
      source: todo?.source,
      closedBy: todo?.closedBy,
      priority: _priority,
      checklist: checklist,
      completedAt: todo?.completedAt,
    );
    setState(() {
      _submitting = true;
      _submitError = false;
    });
    final ok = await widget.onSubmit(saved);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      widget.onClose();
    } else {
      setState(() => _submitError = true);
    }
  }

  Widget _field(GhTheme theme, String label, Widget child, {bool optional = false, double gap = 0.5, List<Widget> extra = const []}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(gap),
        children: [
          GhFieldLabel(label, optional: optional ? ghTr('optional') : null, inset: true),
          child,
          ...extra,
        ],
      );

  Widget _chips(GhTheme theme, List<Widget> chips) => Wrap(spacing: theme.space(1.5), runSpacing: theme.space(1.5), children: chips);

  GhTextInput _input(
    GhTheme theme, {
    required TextEditingController controller,
    String? placeholder,
    bool mono = false,
    int maxLines = 1,
    FocusNode? focusNode,
    bool dashed = false,
    bool invalid = false,
    double py = 2.5,
    TextDirection? textDirection,
    ValueChanged<String>? onSubmitted,
  }) => GhTextInput(
    controller: controller,
    focusNode: focusNode,
    placeholder: placeholder,
    mono: mono,
    maxLines: maxLines,
    minLines: maxLines,
    dashed: dashed,
    textDirection: textDirection,
    onSubmitted: onSubmitted,
    background: theme.overlay,
    placeholderColor: theme.muted.withValues(alpha: 0.7),
    borderColor: invalid ? theme.danger.withValues(alpha: 0.5) : theme.outline.withValues(alpha: dashed ? 0.6 : 0.5),
    focusBorderColor: invalid ? theme.danger : theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusItem),
    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(py)),
  );

  Widget _linkField(GhTheme theme) => RawAutocomplete<String>(
    textEditingController: _link,
    focusNode: _linkNode,
    optionsBuilder: (value) {
      final query = value.text.trim().toLowerCase();
      if (query.isEmpty) return const Iterable<String>.empty();
      return _resources.where((r) => r.toLowerCase().contains(query) && r != value.text).take(8);
    },
    fieldViewBuilder: (context, controller, focusNode, onSubmitted) => _input(
      theme,
      controller: controller,
      focusNode: focusNode,
      placeholder: tt('linked_file_placeholder'),
      mono: true,
      invalid: _linkInvalid,
      textDirection: TextDirection.ltr,
      onSubmitted: (_) => onSubmitted(),
    ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: EdgeInsets.only(top: theme.space(1)),
        child: Container(
          constraints: BoxConstraints(maxWidth: theme.rem(28), maxHeight: theme.rem(14)),
          padding: EdgeInsets.all(theme.space(1)),
          decoration: BoxDecoration(
            color: theme.raised,
            borderRadius: BorderRadius.circular(theme.radiusDropdown),
            border: Border.all(color: theme.line),
            boxShadow: GhShadows.md(),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final option in options)
                GhPressable(
                  onPressed: () => onSelected(option),
                  borderRadius: BorderRadius.circular(theme.radiusDropdownBtn),
                  builder: (context, states) => GhAnimatedBox(
                    color: states.active ? theme.overlay : theme.overlay.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(theme.radiusDropdownBtn),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                    child: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final editing = widget.todo != null;
    return GhModalShell(
      icon: GhIcon(editing ? GhIcons.pencil : GhIcons.checkCircle, size: theme.space(5), color: theme.accentBright),
      title: editing ? tt('edit_task') : tt('new_task'),
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      rawFooter: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_submitError)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                  decoration: BoxDecoration(
                    color: theme.danger.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tt('save_task_failed'),
                    style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(theme.space(5), theme.space(2), theme.space(5), theme.space(5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: theme.space(2),
              children: [
                GhButton(onPressed: widget.onClose, label: ghTr('cancel'), variant: GhButtonVariant.outline),
                GhButton(
                  onPressed: _canSubmit ? _submit : null,
                  label: _submitting
                      ? ghTr('saving')
                      : editing
                      ? ghTr('save_changes')
                      : tt('add_task'),
                  variant: GhButtonVariant.primary,
                  weight: GhWeight.medium,
                ),
              ],
            ),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            _field(theme, tt('title'), _input(theme, controller: _title, placeholder: tt('title_placeholder'), mono: true)),
            _field(
              theme,
              tt('area'),
              gap: 2,
              _chips(theme, [
                for (final area in TodoArea.values)
                  GhChoiceChip(
                    label: todoAreaLabel(area),
                    active: _area == area,
                    showCheck: false,
                    paddingY: 2,
                    onPressed: () => setState(() => _area = area),
                  ),
              ]),
            ),
            _field(
              theme,
              tt('priority'),
              gap: 2,
              _chips(theme, [
                for (final priority in <TodoPriority?>[null, ...TodoPriority.values])
                  GhChoiceChip(
                    label: priority == null ? tt('priority_none') : todoPriorityLabel(priority),
                    active: _priority == priority,
                    showCheck: false,
                    paddingY: 2,
                    onPressed: () => setState(() => _priority = priority),
                  ),
              ]),
            ),
            _field(
              theme,
              tt('status'),
              gap: 2,
              _chips(theme, [
                for (final status in todoStatuses)
                  GhChoiceChip(
                    label: todoStatusLabel(status),
                    active: _status == status,
                    showCheck: false,
                    paddingY: 2,
                    onPressed: () => setState(() => _status = status),
                  ),
              ]),
            ),
            _field(
              theme,
              ghTr('project_template_desc_label'),
              optional: true,
              _input(theme, controller: _description, placeholder: tt('description_placeholder'), maxLines: 4),
            ),
            _field(
              theme,
              tt('checklist'),
              optional: true,
              gap: 1.5,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(1.5),
                children: [
                  for (final item in _checklist)
                    Container(
                      key: ValueKey(item.id),
                      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                      decoration: BoxDecoration(
                        color: theme.overlay,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        spacing: theme.space(2),
                        children: [
                          GhCheckbox(
                            checked: item.done,
                            label: item.text,
                            onChanged: (done) => setState(() {
                              _checklist = [
                                for (final entry in _checklist)
                                  entry.id == item.id ? TodoChecklistItem(id: entry.id, text: entry.text, done: done) : entry,
                              ];
                            }),
                          ),
                          Expanded(
                            child: GhTextInput(
                              controller: _itemController(item),
                              bordered: false,
                              focusRing: false,
                              padding: EdgeInsets.zero,
                              background: theme.overlay.withValues(alpha: 0),
                            ),
                          ),
                          GhPressable(
                            onPressed: () => _removeChecklistItem(item.id),
                            borderRadius: BorderRadius.circular(theme.radiusBtn),
                            semanticLabel: tt('checklist_remove'),
                            builder: (context, states) => GhAnimatedBox(
                              color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                              borderRadius: BorderRadius.circular(theme.radiusBtn),
                              padding: EdgeInsets.all(theme.space(1)),
                              child: GhIcon(GhIcons.x, size: theme.space(3), color: states.active ? theme.danger : theme.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _input(
                    theme,
                    controller: _newItem,
                    placeholder: tt('checklist_add_placeholder'),
                    dashed: true,
                    py: 2,
                    onSubmitted: (_) => _addChecklistItem(),
                  ),
                ],
              ),
            ),
            _field(
              theme,
              tt('due_date'),
              optional: true,
              GhDatePicker(
                value: _dueDate,
                onChanged: (value) => setState(() => _dueDate = value),
                placeholder: tt('no_due_date'),
                clearLabel: tt('remove_due_date'),
                markPastDates: true,
                pastDateMessage: tt('past_due_date'),
              ),
            ),
            _field(
              theme,
              tt('linked_file'),
              optional: true,
              _linkField(theme),
              extra: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: theme.space(3), top: theme.space(1)),
                  child: Text(
                    _linkInvalid ? tt('linked_file_invalid') : tt('linked_file_hint'),
                    style: theme.text(size: GhTextSize.x2s, color: _linkInvalid ? theme.danger : theme.muted.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
