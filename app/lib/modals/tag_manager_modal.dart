import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/shell/smooth_scroll.dart';

class TagManagerModal extends StatefulWidget {
  const TagManagerModal({super.key, required this.project, required this.onClose, required this.onSaved, this.saveTags});

  final Project project;
  final VoidCallback onClose;
  final ValueChanged<Project> onSaved;
  final Future<Project> Function(String id, String path, List<String> tags)? saveTags;

  @override
  State<TagManagerModal> createState() => _TagManagerModalState();
}

class _TagManagerModalState extends State<TagManagerModal> {
  late List<String> _tags = List.of(widget.project.tags);
  final TextEditingController _newTag = TextEditingController();
  final TextEditingController _edit = TextEditingController();
  final FocusNode _input = FocusNode(debugLabel: 'TagManager input');
  final FocusNode _editNode = FocusNode(debugLabel: 'TagManager edit');
  int? _editing;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newTag.addListener(() => setState(() {}));
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) _input.requestFocus();
    });
  }

  @override
  void dispose() {
    _newTag.dispose();
    _edit.dispose();
    _input.dispose();
    _editNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final trimmed = _newTag.text.trim();
    if (trimmed.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      setState(() => _error = context.tr.common.tag_already_exists);
      return;
    }
    setState(() {
      _tags = [..._tags, trimmed];
      _error = null;
    });
    _newTag.clear();
    Timer(const Duration(milliseconds: 10), () {
      if (mounted) _input.requestFocus();
    });
  }

  void _removeTag(int index) {
    setState(() {
      _tags = [
        for (var i = 0; i < _tags.length; i++)
          if (i != index) _tags[i],
      ];
      if (_editing == index) {
        _editing = null;
        _edit.clear();
      }
    });
  }

  void _startEdit(int index) {
    setState(() => _editing = index);
    _edit.text = _tags[index];
    Timer(const Duration(milliseconds: 50), () {
      if (mounted) _editNode.requestFocus();
    });
  }

  void _saveEdit() {
    final index = _editing;
    if (index == null) return;
    final trimmed = _edit.text.trim();
    if (trimmed.isEmpty) {
      _removeTag(index);
      return;
    }
    if (_tags.asMap().entries.any((e) => e.key != index && e.value.toLowerCase() == trimmed.toLowerCase())) {
      setState(() => _error = context.tr.common.tag_already_exists);
      return;
    }
    setState(() {
      _tags = [for (var i = 0; i < _tags.length; i++) i == index ? trimmed : _tags[i]];
      _editing = null;
      _error = null;
    });
    _edit.clear();
  }

  void _cancelEdit() => setState(() {
    _editing = null;
    _edit.clear();
  });

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await (widget.saveTags ?? ProjectsApi.saveTags)(widget.project.id, widget.project.path, _tags);
      widget.onSaved(updated);
      widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  KeyEventResult _onModalKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_editing != null) {
        _cancelEdit();
      } else {
        widget.onClose();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final hasInput = _newTag.text.trim().isNotEmpty;
    final duplicate = _error == tr.tag_already_exists;
    return GhModalShell(
      icon: GhIcon(GhIcons.tags, size: theme.space(5), color: theme.accentBright),
      title: tr.manage_tags,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      showClose: false,
      onKeyEvent: _onModalKey,
      error: duplicate ? null : _error,
      footer: ghModalActions(
        trailing: [GhButton(onPressed: widget.onClose, label: tr.cancel)],
        primary: GhBusyButton(
          key: const ValueKey('tag-manager-save'),
          onPressed: _saving ? null : _save,
          busy: _saving,
          icon: GhIcons.check,
          label: _saving ? tr.saving : tr.save,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            Text(
              ghTr('tag_manager_intro', args: {'name': widget.project.name}),
              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.6),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Text(
                  ghTr('tag_new_label'),
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
                ),
                Row(
                  spacing: theme.space(2),
                  children: [
                    Expanded(
                      child: GhTextInput(
                        controller: _newTag,
                        focusNode: _input,
                        placeholder: tr.tag_input_placeholder,
                        semanticLabel: ghTr('tag_new_label'),
                        onSubmitted: (_) => _addTag(),
                        mono: true,
                        background: theme.base,
                        borderColor: duplicate ? theme.danger : theme.outline.withValues(alpha: 0.5),
                        focusBorderColor: duplicate ? theme.danger : theme.accentDim,
                        placeholderColor: theme.muted.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(theme.radiusBtn),
                        padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                      ),
                    ),
                    GhButton(
                      key: const ValueKey('tag-manager-add'),
                      onPressed: hasInput ? _addTag : null,
                      icon: GhIcons.plus,
                      label: tr.add,
                      variant: GhButtonVariant.outline,
                    ),
                  ],
                ),
                if (duplicate)
                  Text(
                    _error!,
                    style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr.bulk_tags,
                        style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
                      ),
                    ),
                    Text(
                      _tags.isEmpty ? tr.no_tags : tr.tag_count(count: _tags.length),
                      style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                    ),
                  ],
                ),
                Container(
                  constraints: BoxConstraints(minHeight: theme.space(16), maxHeight: theme.space(64)),
                  padding: EdgeInsets.all(theme.space(3)),
                  decoration: BoxDecoration(
                    color: theme.base.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: theme.line),
                  ),
                  child: _tags.isEmpty
                      ? Center(
                          child: Text(
                            tr.no_tags,
                            style: theme.text(size: GhTextSize.xs, color: theme.muted),
                          ),
                        )
                      : GhScrollView(
                          child: Wrap(
                            spacing: theme.space(2),
                            runSpacing: theme.space(2),
                            children: [for (var i = 0; i < _tags.length; i++) _chip(context, i)],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, int index) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final tag = _tags[index];
    final color = colorFromHex(tagColor(tag));
    final radius = BorderRadius.circular(999);
    if (_editing == index) {
      return SizedBox(
        key: ValueKey('edit-$tag-$index'),
        width: theme.space(48),
        child: GhTextInput(
          controller: _edit,
          focusNode: _editNode,
          autofocus: true,
          onSubmitted: (_) => _saveEdit(),
          onBlur: _saveEdit,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              _cancelEdit();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          mono: true,
          size: GhTextSize.xs,
          weight: GhWeight.medium,
          textColor: color,
          background: theme.base,
          borderColor: color.withValues(alpha: 0.5),
          focusBorderColor: color,
          borderRadius: radius,
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
        ),
      );
    }
    return Container(
      key: ValueKey('$tag-$index'),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: tr.tag_rename_hint,
            child: GhPressable(
              onPressed: () => _startEdit(index),
              semanticLabel: '${tr.tag_rename_aria}: $tag',
              borderRadius: radius,
              builder: (context, states) => Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(3), theme.space(1.5), theme.space(1), theme.space(1.5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    Container(
                      width: theme.space(2),
                      height: theme.space(2),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    Text(
                      tag,
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, mono: true, color: states.active ? theme.ink : color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(end: theme.space(1)),
            child: GhPressable(
              onPressed: () => _removeTag(index),
              semanticLabel: '${tr.remove_tag}: $tag',
              borderRadius: radius,
              builder: (context, states) => GhAnimatedBox(
                padding: EdgeInsets.all(theme.space(1)),
                color: states.active ? theme.danger.withValues(alpha: 0.15) : theme.danger.withValues(alpha: 0),
                borderRadius: radius,
                child: GhIcon(GhIcons.x, size: theme.space(2.5), color: states.active ? theme.danger : color.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
