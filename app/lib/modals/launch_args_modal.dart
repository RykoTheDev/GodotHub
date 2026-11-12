import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/modal_kit.dart';

const launchArgSuggestions = [
  'args_debug',
  'args_single_window',
  'args_opengl3',
  'args_vulkan',
  'args_headless',
  'args_verbose',
  'args_editor',
  'args_build_solutions',
  'args_gpu_index',
];

class LaunchArgsModal extends StatefulWidget {
  const LaunchArgsModal({super.key, required this.currentArgs, required this.onSave, required this.onClose});

  final String currentArgs;
  final ValueChanged<String> onSave;
  final VoidCallback onClose;

  @override
  State<LaunchArgsModal> createState() => _LaunchArgsModalState();
}

class _LaunchArgsModalState extends State<LaunchArgsModal> {
  late final TextEditingController _args = TextEditingController(text: widget.currentArgs);

  @override
  void dispose() {
    _args.dispose();
    super.dispose();
  }

  void _append(String flag) {
    final trimmed = _args.text.trim();
    final next = trimmed.isEmpty ? flag : '$trimmed $flag';
    _args.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final hint = theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.6));
    final chipRadius = BorderRadius.circular(theme.radiusMd / 2);
    return GhModalShell(
      icon: GhIcon(GhIcons.code, size: theme.space(5), color: theme.ink),
      title: tr.launch_arguments,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      footer: [
        const Spacer(),
        GhButton(onPressed: widget.onClose, label: tr.cancel),
        GhButton(onPressed: () => widget.onSave(_args.text.trim()), label: tr.save, variant: GhButtonVariant.primary),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(tr.args_label),
                GhTextInput(
                  controller: _args,
                  placeholder: tr.args_placeholder,
                  mono: true,
                  background: theme.raised,
                  borderColor: theme.line,
                  focusBorderColor: theme.accentDim,
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${tr.args_desc_separate_prefix} '),
                      TextSpan(
                        text: '--rendering-driver opengl3',
                        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                      ),
                      TextSpan(text: ' ${tr.args_desc_separate_suffix}'),
                    ],
                  ),
                  style: hint,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: theme.space(1.5),
              children: [
                GhFieldLabel(tr.args_suggestions),
                Wrap(
                  spacing: theme.space(1.5),
                  runSpacing: theme.space(1.5),
                  children: [
                    for (final key in launchArgSuggestions)
                      GhPressable(
                        onPressed: () => _append(ghTr(key)),
                        tooltip: ghTr('${key}_desc'),
                        borderRadius: chipRadius,
                        builder: (context, states) => GhAnimatedBox(
                          color: theme.raised,
                          borderRadius: chipRadius,
                          border: Border.all(color: states.active ? theme.accentDim : theme.line),
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                          child: Text(
                            ghTr(key),
                            style: theme.text(size: GhTextSize.x2s, mono: true, color: states.active ? theme.ink : theme.muted),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
