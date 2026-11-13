import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'bidi.dart';
import 'interaction.dart';

enum GhButtonVariant { primary, danger, ghost, subtle, outline }

class GhButton extends StatelessWidget {
  const GhButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.variant = GhButtonVariant.ghost,
    this.size = GhTextSize.sm,
    this.weight,
    this.paddingX = 4,
    this.paddingY = 2.5,
    this.iconSize,
    this.autofocus = false,
    this.focusNode,
    this.tooltip,
    this.semanticLabel,
    this.expand = false,
    this.disabledOpacity = 0.4,
  });

  final VoidCallback? onPressed;
  final String? label;
  final FaIconData? icon;
  final GhButtonVariant variant;
  final GhTextSize size;
  final FontWeight? weight;
  final double paddingX;
  final double paddingY;
  final double? iconSize;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? tooltip;
  final String? semanticLabel;
  final bool expand;
  final double disabledOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      disabledOpacity: disabledOpacity,
      rippleColor: variant == GhButtonVariant.primary || variant == GhButtonVariant.danger ? Colors.white : theme.ink,
      autofocus: autofocus,
      focusNode: focusNode,
      borderRadius: radius,
      tooltip: tooltip,
      semanticLabel: semanticLabel ?? (label == null ? tooltip : null),
      builder: (context, states) {
        final (background, foreground, brightness, lift) = _colors(theme, states);
        final fontWeight =
            weight ?? (variant == GhButtonVariant.primary || variant == GhButtonVariant.danger ? GhWeight.medium : GhWeight.normal);
        final textStyle = theme.text(size: size, weight: fontWeight, color: foreground);
        final children = <Widget>[
          if (icon != null)
            GhIconMotionScale(
              states: states,
              enabled: label == null,
              child: GhAnimatedIcon(icon!, color: foreground, size: iconSize ?? textStyle.fontSize!),
            ),
          if (icon != null && label != null) SizedBox(width: theme.space(2)),
          if (label != null)
            Flexible(
              child: ghPlaintext(label!, GhAnimatedText(label!, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ),
        ];
        return GhBrightness(
          amount: brightness,
          child: GhAnimatedBox(
            color: background,
            borderRadius: radius,
            border: variant == GhButtonVariant.outline ? Border.all(color: states.highlighted ? theme.accentDim : theme.line) : null,
            boxShadow: lift ? GhShadows.hoverLift() : const [],
            padding: EdgeInsets.symmetric(horizontal: theme.space(paddingX), vertical: theme.space(paddingY)),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }

  (Color, Color, double, bool) _colors(GhTheme theme, GhStates states) {
    final hover = states.active;
    return switch (variant) {
      GhButtonVariant.primary => (hover ? theme.accentBright : theme.accent, Colors.white, 1.0, hover),
      GhButtonVariant.danger => (theme.danger, Colors.white, hover ? 1.1 : 1.0, false),
      GhButtonVariant.ghost => (hover ? theme.raised : theme.raised.withValues(alpha: 0), hover ? theme.ink : theme.muted, 1.0, hover),
      GhButtonVariant.subtle => (
        hover ? theme.raised : theme.raised.withValues(alpha: 0),
        hover ? theme.ink : theme.muted.withValues(alpha: 0.5),
        1.0,
        hover,
      ),
      GhButtonVariant.outline => (hover ? theme.raised : theme.raised.withValues(alpha: 0), theme.ink, 1.0, hover),
    };
  }
}

class GhIconButton extends StatelessWidget {
  const GhIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.variant = GhButtonVariant.subtle,
    this.padding = 1.5,
    this.iconSpace = 4,
    this.autofocus = false,
  });

  final FaIconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final GhButtonVariant variant;
  final double padding;
  final double iconSpace;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhButton(
      onPressed: onPressed,
      icon: icon,
      variant: variant,
      paddingX: padding,
      paddingY: padding,
      iconSize: theme.space(iconSpace),
      tooltip: tooltip,
      semanticLabel: semanticLabel ?? tooltip,
      autofocus: autofocus,
    );
  }
}
