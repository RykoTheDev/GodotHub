import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/reusables/modal_kit.dart';

class VaultCancelButton extends StatelessWidget {
  const VaultCancelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
        child: Text(
          ghTr('cancel'),
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
        ),
      ),
    );
  }
}

class VaultPrimaryButton extends StatelessWidget {
  const VaultPrimaryButton({super.key, required this.label, required this.onPressed, this.danger = false});

  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      disabledOpacity: 0.5,
      disabledCursor: SystemMouseCursors.forbidden,
      borderRadius: radius,
      rippleColor: Colors.white,
      builder: (context, states) => GhAnimatedBox(
        alignment: Alignment.center,
        color: danger ? theme.danger.withValues(alpha: states.active ? 0.9 : 1) : (states.active ? theme.accentBright : theme.accent),
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
        child: Text(
          label,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: Colors.white),
        ),
      ),
    );
  }
}

class VaultField extends StatelessWidget {
  const VaultField({super.key, required this.label, required this.child, this.optional = false});

  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        GhFieldLabel(label, optional: optional ? ghTr('optional') : null),
        child,
      ],
    );
  }
}

GhTextInput vaultTextInput(
  GhTheme theme,
  TextEditingController controller, {
  String? placeholder,
  int lines = 1,
  bool autofocus = false,
  ValueChanged<String>? onSubmitted,
}) => GhTextInput(
  controller: controller,
  autofocus: autofocus,
  placeholder: placeholder,
  placeholderColor: theme.muted,
  size: GhTextSize.sm,
  maxLines: lines,
  minLines: lines,
  onSubmitted: onSubmitted,
  background: theme.raised,
  focusBorderColor: theme.accentDim,
  padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
);

class VaultTagChip extends StatelessWidget {
  const VaultTagChip(this.tag, {super.key, this.large = false});

  final String tag;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(large ? 2 : 1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        tag,
        style: theme.text(size: large ? GhTextSize.x2s : GhTextSize.x3s, mono: true, color: theme.muted),
      ),
    );
  }
}
