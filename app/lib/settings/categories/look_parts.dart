import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../ui/core/i18n.dart';
import '../../ui/core/interaction.dart';

String lts(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

TextStyle lookLabelStyle(GhTheme theme) => theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted);

TextStyle lookValueStyle(GhTheme theme, {bool mono = false}) =>
    theme.text(size: GhTextSize.xs, weight: mono ? GhWeight.normal : GhWeight.medium, mono: mono, color: theme.ink);

String formatSettingNumber(num value) => value == value.roundToDouble() ? '${value.round()}' : '$value';

class LookGhostButton extends StatelessWidget {
  const LookGhostButton({super.key, required this.label, required this.onPressed, this.icon, this.semanticLabel});

  final String label;
  final FaIconData? icon;
  final String? semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: semanticLabel ?? label,
      builder: (context, states) {
        final color = states.highlighted ? theme.ink : theme.muted;
        return GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
          color: states.highlighted ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              if (icon != null) GhIcon(icon!, size: theme.space(3.5), color: color),
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LookSolidButton extends StatelessWidget {
  const LookSolidButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      rippleColor: Colors.white,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(8),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
        color: states.highlighted ? theme.accentDim : theme.accent,
        borderRadius: radius,
        child: Text(
          label,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: Colors.white),
        ),
      ),
    );
  }
}

class LookOutlineButton extends StatelessWidget {
  const LookOutlineButton({super.key, required this.label, required this.onPressed, this.icon, this.paddingX = 3.5, this.paddingY});

  final String label;
  final FaIconData? icon;
  final double paddingX;
  final double? paddingY;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    final py = paddingY;
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) {
        final color = states.highlighted ? theme.ink : theme.muted;
        return GhAnimatedBox(
          height: py == null ? theme.space(8) : null,
          alignment: py == null ? Alignment.center : null,
          padding: EdgeInsets.symmetric(horizontal: theme.space(paddingX), vertical: py == null ? 0 : theme.space(py)),
          color: py == null
              ? (states.highlighted ? theme.raised : theme.overlay)
              : (states.highlighted ? theme.raised : theme.raised.withValues(alpha: 0)),
          borderRadius: radius,
          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              if (icon != null) GhIcon(icon!, size: theme.space(3.5), color: color),
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
