import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

class VaultTagEditor extends StatefulWidget {
  const VaultTagEditor({super.key, required this.tags, required this.onChanged});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<VaultTagEditor> createState() => _VaultTagEditorState();
}

class _VaultTagEditorState extends State<VaultTagEditor> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _node = FocusNode(debugLabel: 'VaultTagEditor input');

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _node.dispose();
    super.dispose();
  }

  void _add() {
    final tag = _input.text.trim();
    if (tag.isEmpty) return;
    _input.clear();
    _node.requestFocus();
    if (!widget.tags.contains(tag)) widget.onChanged([...widget.tags, tag]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final canAdd = _input.text.trim().isNotEmpty;
    final radius = BorderRadius.circular(theme.radiusItem);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: theme.space(2),
          children: [
            Expanded(
              child: GhTextInput(
                controller: _input,
                focusNode: _node,
                placeholder: ghTr('vault_tag_input_placeholder'),
                placeholderColor: theme.muted,
                size: GhTextSize.xs,
                onSubmitted: (_) => _add(),
                background: theme.raised,
                focusBorderColor: theme.accentDim,
                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
              ),
            ),
            GhPressable(
              onPressed: canAdd ? _add : null,
              disabledCursor: SystemMouseCursors.forbidden,
              borderRadius: radius,
              builder: (context, states) => GhAnimatedBox(
                alignment: Alignment.center,
                color: theme.accent.withValues(alpha: states.active ? 0.25 : 0.15),
                borderRadius: radius,
                border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.plus, size: theme.space(3), color: theme.accentBright),
                    Text(
                      ghTr('add_tag'),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.accentBright),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: theme.space(1.5),
            runSpacing: theme.space(1.5),
            children: [
              for (final tag in widget.tags)
                Container(
                  key: ValueKey(tag),
                  padding: EdgeInsetsDirectional.fromSTEB(theme.space(2.5), theme.space(1), theme.space(1.5), theme.space(1)),
                  decoration: BoxDecoration(
                    color: theme.raised,
                    borderRadius: BorderRadius.circular(theme.radiusTag),
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(1),
                    children: [
                      Text(
                        tag,
                        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.ink),
                      ),
                      GhPressable(
                        onPressed: () => widget.onChanged(widget.tags.where((x) => x != tag).toList()),
                        semanticLabel: ghTr('remove_tag'),
                        borderRadius: BorderRadius.circular(theme.radiusTag),
                        builder: (context, states) => GhAnimatedBox(
                          color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(theme.radiusTag),
                          padding: EdgeInsets.all(theme.space(0.5)),
                          child: GhIcon(
                            GhIcons.x,
                            size: theme.space(2.5),
                            color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
