import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';

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
      _tags = [for (var i = 0; i < _tags.length; i++) if (i != index) _tags[i]];
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
    final mutedHint = theme.muted.withValues(alpha: 0.6);
    return GhModalShell(
      icon: GhIcon(GhIcons.tags, size: theme.space(5), color: theme.accentBright),
      title: tr.manage_tags,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      showClose: false,
      onKeyEvent: _onModalKey,
      footer: [
        Text(
          _tags.isEmpty ? tr.no_tags : tr.tag_count(count: _tags.length),
          style: theme.text(size: GhTextSize.xs, color: mutedHint),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2.5),
          children: [
            GhButton(onPressed: widget.onClose, label: tr.cancel),
            GhPressable(
              onPressed: _saving ? null : _save,
              disabledOpacity: 0.5,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              rippleColor: Colors.white,
              builder: (context, states) => GhAnimatedBox(
                color: states.active ? theme.accentBright : theme.accent,
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(2.5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    if (_saving)
                      SizedBox.square(
                        dimension: theme.space(3.5),
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white, backgroundColor: Color(0x4DFFFFFF)),
                      )
                    else
                      GhIcon(GhIcons.check, size: theme.space(3.5), color: Colors.white),
                    Text(
                      _saving ? tr.saving : tr.save,
                      style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            if (_error != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                  border: Border.all(color: theme.danger.withValues(alpha: 0.2)),
                ),
                child: Text(_error!, style: theme.text(size: GhTextSize.xs, color: theme.danger)),
              ),
            Row(
              spacing: theme.space(2),
              children: [
                Expanded(
                  child: GhTextInput(
                    controller: _newTag,
                    focusNode: _input,
                    placeholder: tr.tag_input_placeholder,
                    onSubmitted: (_) => _addTag(),
                    background: theme.raised,
                    borderColor: theme.line,
                    focusBorderColor: theme.accentDim,
                    borderRadius: BorderRadius.circular(theme.radiusLg),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                  ),
                ),
                GhPressable(
                  onPressed: _newTag.text.trim().isEmpty ? null : _addTag,
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                  rippleColor: Colors.white,
                  builder: (context, states) => GhAnimatedBox(
                    color: states.active ? theme.accentBright : theme.accent,
                    borderRadius: BorderRadius.circular(theme.radiusLg),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1.5),
                      children: [
                        GhIcon(GhIcons.plus, size: theme.space(3.5), color: Colors.white),
                        Text(tr.add, style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: theme.space(64)),
              child: _tags.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.space(8)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: theme.space(2),
                        children: [
                          Opacity(opacity: 0.4, child: GhIcon(GhIcons.tags, size: theme.space(8), color: mutedHint)),
                          Text(tr.no_tags, style: theme.text(size: GhTextSize.sm, color: mutedHint)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: theme.space(2),
                        children: [for (var i = 0; i < _tags.length; i++) _row(context, i)],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int index) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final tag = _tags[index];
    final color = colorFromHex(tagColor(tag));
    final editing = _editing == index;
    return _TagRow(
      key: ValueKey('$tag-$index'),
      builder: (hovered) => GhAnimatedBox(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusXl / 2),
        border: Border.all(color: hovered ? theme.accentDim.withValues(alpha: 0.4) : theme.line.withValues(alpha: 0.6)),
        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
        child: Row(
          spacing: theme.space(2),
          children: [
            Container(
              width: theme.space(2.5),
              height: theme.space(2.5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            Expanded(
              child: editing
                  ? GhTextInput(
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
                      weight: GhWeight.medium,
                      textColor: color,
                      background: theme.base,
                      borderColor: theme.accent.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(theme.radiusMd / 2),
                      padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
                    )
                  : MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _startEdit(index),
                        child: Tooltip(
                          message: tr.tag_rename_hint,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: theme.space(1)),
                            child: Text(
                              tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, mono: true, color: color),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            AnimatedOpacity(
              opacity: hovered ? 1 : 0,
              duration: GhDurations.interactive,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(1),
                children: [
                  if (!editing)
                    _SmallIconButton(
                      icon: GhIcons.pencil,
                      label: tr.tag_rename_aria,
                      hoverColor: theme.ink,
                      hoverBackground: theme.base,
                      onPressed: () => _startEdit(index),
                    ),
                  _SmallIconButton(
                    icon: GhIcons.x,
                    label: tr.remove_tag.args({'tag': tag}),
                    hoverColor: theme.danger,
                    hoverBackground: theme.danger.withValues(alpha: 0.1),
                    onPressed: () => _removeTag(index),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagRow extends StatefulWidget {
  const _TagRow({super.key, required this.builder});

  final Widget Function(bool hovered) builder;

  @override
  State<_TagRow> createState() => _TagRowState();
}

class _TagRowState extends State<_TagRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: widget.builder(_hovered),
  );
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.label,
    required this.hoverColor,
    required this.hoverBackground,
    required this.onPressed,
  });

  final FaIconData icon;
  final String label;
  final Color hoverColor;
  final Color hoverBackground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusMd / 2);
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? hoverBackground : hoverBackground.withValues(alpha: 0),
        borderRadius: radius,
        padding: EdgeInsets.all(theme.space(1.5)),
        child: GhIcon(icon, size: theme.space(3), color: states.active ? hoverColor : theme.muted.withValues(alpha: 0.5)),
      ),
    );
  }
}
