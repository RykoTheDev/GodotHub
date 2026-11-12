import 'package:flutter/widgets.dart';

import '../../design/design.dart';
import '../../ui/core/interaction.dart';

enum SettingsButtonTone { outline, accent, quiet, dangerQuiet }

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.tone = SettingsButtonTone.outline,
    this.compact = false,
    this.radius,
    this.paddingX,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String label;
  final FaIconData? icon;
  final SettingsButtonTone tone;
  final bool compact;
  final double? radius;
  final double? paddingX;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final shape = BorderRadius.circular(radius ?? (compact ? theme.radiusBtn : theme.radiusItem));
    final enabled = onPressed != null;
    final size = compact ? GhTextSize.xs : GhTextSize.sm;
    final iconSize = theme.space(compact ? 3.5 : 4);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: shape,
      semanticLabel: semanticLabel,
      disabledOpacity: 1,
      builder: (context, states) {
        final hover = states.active && enabled;
        final (Color background, Color? border, Color foreground) = switch (tone) {
          SettingsButtonTone.accent => (hover ? theme.accentBright : theme.accent, null, const Color(0xFFFFFFFF)),
          SettingsButtonTone.outline => (
            hover ? theme.raised : theme.raised.withValues(alpha: 0),
            hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5),
            theme.ink,
          ),
          SettingsButtonTone.quiet => (
            hover ? theme.raised : theme.raised.withValues(alpha: 0),
            hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5),
            hover ? theme.ink : theme.muted,
          ),
          SettingsButtonTone.dangerQuiet => (
            hover ? theme.danger.withValues(alpha: 0.05) : theme.danger.withValues(alpha: 0),
            hover ? theme.danger.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5),
            hover ? theme.danger : theme.muted,
          ),
        };
        return Opacity(
          opacity: enabled ? 1 : (compact ? 0.4 : 0.5),
          child: GhAnimatedBox(
            color: background,
            borderRadius: shape,
            border: border == null ? null : Border.all(color: border),
            height: compact ? theme.space(8) : null,
            padding: EdgeInsets.symmetric(horizontal: theme.space(paddingX ?? 4), vertical: compact ? 0 : theme.space(2.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(compact ? 1.5 : 2),
              children: [
                if (icon != null) GhIcon(icon!, size: iconSize, color: foreground),
                Text(
                  label,
                  style: theme.text(size: size, weight: GhWeight.medium, color: foreground),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
