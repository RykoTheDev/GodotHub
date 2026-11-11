import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../state/drag_sort.dart' show arrayMove;
import '../ui/controls/dashed_box.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/dnd/sortable.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/shell/color_swatch_picker.dart';

String normalizeCategoryName(String value) => value.trim().toLowerCase();

class CategoryManagerModal extends StatefulWidget {
  const CategoryManagerModal({
    super.key,
    required this.categories,
    required this.onClose,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onReorder,
    required this.onAssignFolder,
    required this.onUnassignFolder,
    this.projects = const [],
    this.pickFolder,
  });

  final List<Category> categories;
  final List<Project> projects;
  final VoidCallback onClose;
  final Future<Category> Function(String name, String color) onCreate;
  final Future<Category> Function(String id, String? name, String? color) onUpdate;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(List<String> orderedIds) onReorder;
  final Future<Category> Function(String id, String folder) onAssignFolder;
  final Future<Category> Function(String id, String folder) onUnassignFolder;
  final Future<String?> Function()? pickFolder;

  @override
  State<CategoryManagerModal> createState() => _CategoryManagerModalState();
}

class _CategoryManagerModalState extends State<CategoryManagerModal> {
  final TextEditingController _name = TextEditingController();
  String _color = categoryColors.first;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submitNew() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Category name is required.');
      return;
    }
    if (widget.categories.any((c) => normalizeCategoryName(c.name) == normalizeCategoryName(trimmed))) {
      setState(() => _error = 'A category with this name already exists.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCreate(trimmed, _color);
      _name.clear();
      if (mounted) setState(() => _color = categoryColors.first);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final count = widget.categories.length;
    final total = widget.projects.length;
    final addEnabled = !_busy && _name.text.trim().isNotEmpty;
    final radiusXl = BorderRadius.circular(theme.radiusXl / 2);
    return GhModalShell(
      icon: GhIcon(GhIcons.tags, size: theme.space(5), color: theme.accentBright),
      title: tr.manage_categories,
      maxWidth: GhModalWidth.x2l,
      onClose: widget.onClose,
      footer: [
        Text(
          count == 0
              ? tr.no_categories_yet
              : '$count ${count == 1 ? 'category' : 'categories'} · $total ${total == 1 ? 'project' : 'projects'}',
          style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.6)),
        ),
        const Spacer(),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            if (count > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                decoration: BoxDecoration(
                  color: theme.overlay.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.space(2.5),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(0.5)),
                      child: GhIcon(GhIcons.folder, size: theme.space(3.5), color: theme.muted.withValues(alpha: 0.6)),
                    ),
                    Expanded(
                      child: Text(
                        tr.category_folders_hint,
                        style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              spacing: theme.space(2.5),
              children: [
                Expanded(
                  child: _FocusWithinBox(
                    builder: (focused) => GhAnimatedBox(
                      color: theme.raised,
                      borderRadius: radiusXl,
                      border: Border.all(color: focused ? theme.accentDim : theme.line),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: theme.space(3)),
                            child: GhColorSwatchPicker(
                              value: _color,
                              onChanged: (value) => setState(() => _color = value),
                              presets: categoryColors,
                              trigger: (context, open, toggle) => GhPressable(
                                onPressed: toggle,
                                expanded: open,
                                semanticLabel: tr.color_label,
                                borderRadius: BorderRadius.circular(9999),
                                builder: (context, states) => AnimatedScale(
                                  scale: states.active ? 1.1 : 1,
                                  duration: GhDurations.interactive,
                                  child: Container(
                                    width: theme.space(6),
                                    height: theme.space(6),
                                    decoration: BoxDecoration(
                                      color: colorFromHex(_color),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GhTextInput(
                              controller: _name,
                              placeholder: tr.new_category_placeholder,
                              onSubmitted: (_) => _submitNew(),
                              bordered: false,
                              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GhPressable(
                  onPressed: addEnabled ? _submitNew : null,
                  disabledOpacity: 0.5,
                  disabledCursor: SystemMouseCursors.forbidden,
                  borderRadius: radiusXl,
                  rippleColor: Colors.white,
                  builder: (context, states) => GhAnimatedBox(
                    color: states.active ? theme.accentBright : theme.accent,
                    borderRadius: radiusXl,
                    padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(3)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(2),
                      children: [
                        GhIcon(GhIcons.plus, size: theme.space(4), color: Colors.white),
                        Text(
                          tr.add,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                  border: Border.all(color: theme.danger.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _error!,
                  style: theme.text(size: GhTextSize.xs, color: theme.danger),
                ),
              ),
            if (count == 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.space(12)),
                child: Column(
                  spacing: theme.space(3),
                  children: [
                    GhDashedCircleBox(
                      size: theme.space(14),
                      child: Opacity(
                        opacity: 0.4,
                        child: GhIcon(GhIcons.tags, size: theme.space(6), color: theme.muted.withValues(alpha: 0.5)),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          tr.no_categories_yet,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.7)),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: theme.space(1)),
                          child: Text(
                            tr.category_empty_hint,
                            style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.4)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              SortableCategoryList(
                categories: widget.categories,
                projects: widget.projects,
                onUpdate: widget.onUpdate,
                onDelete: widget.onDelete,
                onReorder: widget.onReorder,
                onAssignFolder: widget.onAssignFolder,
                onUnassignFolder: widget.onUnassignFolder,
                onError: (message) => setState(() => _error = message),
                pickFolder: widget.pickFolder,
              ),
          ],
        ),
      ),
    );
  }
}

class GhDashedCircleBox extends StatelessWidget {
  const GhDashedCircleBox({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhDashedBox(
      color: theme.outline.withValues(alpha: 0.4),
      radius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(16)),
        child: child,
      ),
    );
  }
}

class _FocusWithinBox extends StatefulWidget {
  const _FocusWithinBox({required this.builder});

  final Widget Function(bool focused) builder;

  @override
  State<_FocusWithinBox> createState() => _FocusWithinBoxState();
}

class _FocusWithinBoxState extends State<_FocusWithinBox> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (value) => setState(() => _focused = value),
    child: widget.builder(_focused),
  );
}

class SortableCategoryList extends StatefulWidget {
  const SortableCategoryList({
    super.key,
    required this.categories,
    required this.onUpdate,
    required this.onDelete,
    required this.onReorder,
    required this.onAssignFolder,
    required this.onUnassignFolder,
    required this.onError,
    this.projects = const [],
    this.pickFolder,
  });

  final List<Category> categories;
  final List<Project> projects;
  final Future<Category> Function(String id, String? name, String? color) onUpdate;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(List<String> orderedIds) onReorder;
  final Future<Category> Function(String id, String folder) onAssignFolder;
  final Future<Category> Function(String id, String folder) onUnassignFolder;
  final ValueChanged<String?> onError;
  final Future<String?> Function()? pickFolder;

  @override
  State<SortableCategoryList> createState() => _SortableCategoryListState();
}

class _SortableCategoryListState extends State<SortableCategoryList> {
  late List<Category> _ordered = widget.categories;
  bool _dragging = false;
  bool _busy = false;
  String? _folderBusyId;
  String? _editingId;
  final TextEditingController _editName = TextEditingController();
  String _editColor = '';

  @override
  void didUpdateWidget(SortableCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) _ordered = widget.categories;
  }

  @override
  void dispose() {
    _editName.dispose();
    super.dispose();
  }

  void _reorder(String activeId, String? overId) {
    setState(() => _dragging = false);
    if (overId == null || overId == activeId) return;
    final ids = [for (final c in _ordered) c.id];
    final from = ids.indexOf(activeId);
    final to = ids.indexOf(overId);
    if (from < 0 || to < 0) return;
    final next = arrayMove(ids, from, to);
    final previous = _ordered;
    final rank = {for (var i = 0; i < next.length; i++) next[i]: i};
    setState(() => _ordered = [..._ordered]..sort((a, b) => (rank[a.id] ?? 0).compareTo(rank[b.id] ?? 0)));
    widget.onReorder(next).catchError((Object e) {
      if (mounted) setState(() => _ordered = previous);
      widget.onError('$e');
    });
  }

  Future<void> _assignFolder(Category category) async {
    final folder = await (widget.pickFolder ?? ProjectsApi.pickFolder)().catchError((Object _) => null);
    if (folder == null) return;
    setState(() => _folderBusyId = category.id);
    widget.onError(null);
    try {
      await widget.onAssignFolder(category.id, folder);
    } catch (e) {
      widget.onError('$e');
    } finally {
      if (mounted) setState(() => _folderBusyId = null);
    }
  }

  Future<void> _removeFolder(Category category, String folder) async {
    setState(() => _folderBusyId = category.id);
    widget.onError(null);
    try {
      await widget.onUnassignFolder(category.id, folder);
    } catch (e) {
      widget.onError('$e');
    } finally {
      if (mounted) setState(() => _folderBusyId = null);
    }
  }

  void _startEdit(Category c) {
    setState(() {
      _editingId = c.id;
      _editColor = c.color;
    });
    _editName.text = c.name;
    widget.onError(null);
  }

  Future<void> _submitEdit(String id) async {
    final trimmed = _editName.text.trim();
    if (trimmed.isEmpty) {
      widget.onError('Category name is required.');
      return;
    }
    if (widget.categories.any((c) => c.id != id && normalizeCategoryName(c.name) == normalizeCategoryName(trimmed))) {
      widget.onError('A category with this name already exists.');
      return;
    }
    setState(() => _busy = true);
    widget.onError(null);
    try {
      Category? current;
      for (final c in widget.categories) {
        if (c.id == id) current = c;
      }
      await widget.onUpdate(id, trimmed != current?.name ? trimmed : null, _editColor != current?.color ? _editColor : null);
      if (mounted) setState(() => _editingId = null);
    } catch (e) {
      widget.onError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final tr = context.tr.common;
    final ok = await showGhConfirmDialog(
      context,
      title: tr.delete_category_title,
      description: tr.delete_category_desc.args({'name': category.name}),
      confirmLabel: tr.delete,
      variant: GhConfirmVariant.danger,
    );
    if (!ok || _busy) return;
    setState(() => _busy = true);
    widget.onError(null);
    try {
      await widget.onDelete(category.id);
    } catch (e) {
      widget.onError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(Category category) => _CategoryRow(
    category: category,
    projects: [
      for (final p in widget.projects)
        if (p.category == category.name) p,
    ],
    editing: _editingId == category.id,
    busy: _folderBusyId == category.id,
    editName: _editName,
    editColor: _editingId == category.id ? _editColor : '',
    onStartEdit: () => _startEdit(category),
    onSubmitEdit: () => _submitEdit(category.id),
    onCancelEdit: () => setState(() => _editingId = null),
    onEditColorChange: (value) => setState(() => _editColor = value),
    onConfirmDelete: () => _confirmDelete(category),
    onAssignFolder: () => _assignFolder(category),
    onRemoveFolder: (folder) => _removeFolder(category, folder),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhDndScope(
      onDragStart: (_) => setState(() => _dragging = true),
      onDragCancel: () => setState(() => _dragging = false),
      onDragEnd: _reorder,
      overlayBuilder: (context, id) {
        for (final c in _ordered) {
          if (c.id == id) return _row(c);
        }
        return const SizedBox.shrink();
      },
      child: GhSortableContext(
        items: [for (final c in _ordered) c.id],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2),
          children: [for (final c in _ordered) GhSortableItem(key: ValueKey(c.id), id: c.id, disabled: _editingId == c.id, child: _row(c))],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({
    required this.category,
    required this.projects,
    required this.editing,
    required this.busy,
    required this.editName,
    required this.editColor,
    required this.onStartEdit,
    required this.onSubmitEdit,
    required this.onCancelEdit,
    required this.onEditColorChange,
    required this.onConfirmDelete,
    required this.onAssignFolder,
    required this.onRemoveFolder,
  });

  final Category category;
  final List<Project> projects;
  final bool editing;
  final bool busy;
  final TextEditingController editName;
  final String editColor;
  final VoidCallback onStartEdit;
  final VoidCallback onSubmitEdit;
  final VoidCallback onCancelEdit;
  final ValueChanged<String> onEditColorChange;
  final VoidCallback onConfirmDelete;
  final VoidCallback onAssignFolder;
  final ValueChanged<String> onRemoveFolder;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hovered = false;

  Widget _icon(
    GhTheme theme,
    FaIconData icon,
    String label,
    VoidCallback onPressed, {
    Color? hoverColor,
    Color? hoverBackground,
    double size = 3.5,
    Color? color,
  }) {
    final radius = BorderRadius.circular(theme.radiusLg / 1.4);
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? (hoverBackground ?? theme.base) : (hoverBackground ?? theme.base).withValues(alpha: 0),
        borderRadius: radius,
        padding: EdgeInsets.all(theme.space(2)),
        child: GhIcon(icon, size: theme.space(size), color: color ?? (states.active ? (hoverColor ?? theme.ink) : theme.muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final category = widget.category;
    final color = colorFromHex(category.color);
    final projects = widget.projects;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: GhDurations.interactive,
        decoration: BoxDecoration(
          color: theme.raised,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: _hovered ? theme.accentDim.withValues(alpha: 0.5) : theme.outline.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
              child: widget.editing
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: theme.space(3),
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: theme.space(2.5),
                            children: [
                              GhTextInput(
                                controller: widget.editName,
                                autofocus: true,
                                onSubmitted: (_) => widget.onSubmitEdit(),
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                                    widget.onCancelEdit();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                background: theme.base,
                                borderColor: theme.accent.withValues(alpha: 0.4),
                                focusBorderColor: theme.accentDim,
                                borderRadius: BorderRadius.circular(theme.radiusLg),
                                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                              ),
                              GhColorSwatchPicker(
                                label: '',
                                value: widget.editColor,
                                onChanged: widget.onEditColorChange,
                                presets: categoryColors,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          spacing: theme.space(1.5),
                          children: [
                            _icon(
                              theme,
                              GhIcons.check,
                              tr.save,
                              widget.onSubmitEdit,
                              size: 4,
                              color: const Color(0xFF22C55E),
                              hoverBackground: const Color(0xFF22C55E).withValues(alpha: 0.1),
                            ),
                            _icon(theme, GhIcons.x, tr.cancel, widget.onCancelEdit, hoverBackground: theme.raised),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      spacing: theme.space(3),
                      children: [
                        Container(
                          width: theme.space(4),
                          height: theme.space(4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 2),
                            boxShadow: GhShadows.sm(),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                              ),
                              if (projects.isNotEmpty)
                                Text(
                                  '${projects.length} ${projects.length == 1 ? 'project' : 'projects'}',
                                  style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.6)),
                                ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _hovered ? 1 : 0,
                          duration: GhDurations.interactive,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(1),
                            children: [
                              _icon(theme, GhIcons.pencil, tr.edit_category.args({'name': category.name}), widget.onStartEdit),
                              _icon(
                                theme,
                                GhIcons.trash,
                                tr.delete_category.args({'name': category.name}),
                                widget.onConfirmDelete,
                                hoverColor: theme.danger,
                                hoverBackground: theme.danger.withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (!widget.editing)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: theme.space(11),
                  end: theme.space(4),
                  bottom: theme.space(projects.isNotEmpty ? 1 : 3),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: theme.space(1.5),
                  runSpacing: theme.space(1.5),
                  children: [for (final folder in category.folders) _folderChip(theme, folder), _assignButton(theme)],
                ),
              ),
            if (projects.isNotEmpty && !widget.editing)
              Padding(
                padding: EdgeInsetsDirectional.only(start: theme.space(11), end: theme.space(4), bottom: theme.space(3)),
                child: Wrap(
                  spacing: theme.space(1.5),
                  runSpacing: theme.space(1.5),
                  children: [
                    for (final p in projects.take(8))
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                          decoration: BoxDecoration(
                            color: theme.overlay.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(theme.radiusLg),
                            border: Border.all(color: theme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(1.5),
                            children: [
                              Container(
                                width: theme.space(2),
                                height: theme.space(2),
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              Flexible(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (projects.length > 8)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                        child: Text(
                          '+${projects.length - 8} more',
                          style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _folderChip(GhTheme theme, String folder) {
    final tr = context.tr.common;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: EdgeInsetsDirectional.only(start: theme.space(2.5), end: theme.space(1), top: theme.space(1), bottom: theme.space(1)),
        decoration: BoxDecoration(
          color: theme.base.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(theme.radiusLg),
          border: Border.all(color: theme.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            GhIcon(GhIcons.folder, size: theme.space(3), color: theme.muted.withValues(alpha: 0.6)),
            Flexible(
              child: Tooltip(
                message: folder,
                child: Text(
                  folder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                ),
              ),
            ),
            GhPressable(
              onPressed: widget.busy ? null : () => widget.onRemoveFolder(folder),
              semanticLabel: tr.unassign_folder_aria.args({'folder': folder}),
              borderRadius: BorderRadius.circular(6),
              builder: (context, states) => GhAnimatedBox(
                color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(6),
                padding: EdgeInsets.all(theme.space(1)),
                child: GhIcon(GhIcons.x, size: theme.space(2.5), color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignButton(GhTheme theme) {
    final tr = context.tr.common;
    final radius = BorderRadius.circular(theme.radiusLg);
    return GhPressable(
      onPressed: widget.busy ? null : widget.onAssignFolder,
      semanticLabel: tr.assign_folder_to_category.args({'name': widget.category.name}),
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        return GhDashedBox(
          color: hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5),
          radius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                GhIcon(GhIcons.folderPlus, size: theme.space(3), color: hover ? theme.accentBright : theme.muted),
                Text(
                  tr.assign_folder,
                  style: theme.text(size: GhTextSize.x2s, color: hover ? theme.accentBright : theme.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
