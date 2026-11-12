import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../controls/spin.dart';
import '../core/interaction.dart';

class GhSpinnerIcon extends StatelessWidget {
  const GhSpinnerIcon({super.key, this.size = 3.5, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhSpinning(
      child: GhIcon(GhIcons.spinner, size: theme.space(size), color: color ?? IconTheme.of(context).color),
    );
  }
}

class GhOutlineAction extends StatelessWidget {
  const GhOutlineAction({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.spinIcon = false,
    this.primary = false,
    this.expand = false,
    this.iconSize = 3.5,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.child,
  });

  final VoidCallback? onPressed;
  final String? label;
  final FaIconData? icon;
  final FaIconData? trailingIcon;
  final bool busy;
  final bool spinIcon;
  final bool primary;
  final bool expand;
  final double iconSize;
  final String? semanticLabel;
  final String? tooltip;
  final FocusNode? focusNode;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      disabledCursor: SystemMouseCursors.forbidden,
      semanticLabel: semanticLabel ?? label,
      tooltip: tooltip,
      borderRadius: radius,
      rippleColor: primary ? Colors.white : null,
      builder: (context, states) {
        final hover = states.active;
        final foreground = primary ? Colors.white : theme.ink;
        Widget? leading;
        if (busy) {
          leading = GhSpinnerIcon(size: iconSize, color: foreground);
        } else if (icon != null) {
          leading = GhIcon(icon!, size: theme.space(iconSize), color: foreground);
          if (spinIcon) leading = GhSpinning(child: leading);
        }
        return GhAnimatedBox(
          color: primary ? (hover ? theme.accentBright : theme.accent) : (hover ? theme.overlay : theme.raised),
          borderRadius: radius,
          border: Border.all(color: primary ? theme.accentDim : (hover ? theme.accentDim : theme.line)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(primary ? 4 : 3), vertical: theme.space(2)),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: expand ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            spacing: theme.space(2),
            children: [
              ?leading,
              if (child != null)
                Flexible(
                  child: DefaultTextStyle.merge(
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
                    child: child!,
                  ),
                )
              else if (label != null)
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
                  ),
                ),
              if (trailingIcon != null) GhIcon(trailingIcon!, size: theme.space(iconSize), color: foreground),
            ],
          ),
        );
      },
    );
  }
}

class GhFieldLabel extends StatelessWidget {
  const GhFieldLabel(this.text, {super.key, this.optional, this.inset = false});

  final String text;
  final String? optional;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final style = theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: inset ? theme.space(3) : 0),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (optional != null)
              TextSpan(
                text: ' $optional',
                style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.6)),
              ),
          ],
        ),
        style: style,
      ),
    );
  }
}

enum GhChoiceTone { accent, mint, muted }

class GhChoiceChip extends StatelessWidget {
  const GhChoiceChip({
    super.key,
    required this.label,
    required this.active,
    required this.onPressed,
    this.tone = GhChoiceTone.accent,
    this.showCheck = true,
    this.dotColor,
    this.trailing,
    this.paddingY = 1.5,
    this.expand = false,
  });

  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final GhChoiceTone tone;
  final bool showCheck;
  final Color? dotColor;
  final Widget? trailing;
  final double paddingY;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      checked: active,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active && !active;
        final (border, background, foreground) = !active
            ? (
                hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5),
                hover ? theme.raised : theme.raised.withValues(alpha: 0),
                hover ? theme.ink : theme.muted,
              )
            : switch (tone) {
                GhChoiceTone.accent => (theme.accent, theme.accent.withValues(alpha: 0.1), theme.accentBright),
                GhChoiceTone.mint => (theme.mint, theme.mint.withValues(alpha: 0.1), theme.mint),
                GhChoiceTone.muted => (theme.outline.withValues(alpha: 0.6), theme.raised.withValues(alpha: 0), theme.muted),
              };
        return GhAnimatedBox(
          color: background,
          borderRadius: radius,
          border: Border.all(color: border),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(paddingY)),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: theme.space(1.5),
            children: [
              if (active && showCheck && tone != GhChoiceTone.muted) GhIcon(GhIcons.check, size: theme.space(3), color: foreground),
              if (dotColor != null)
                Container(
                  width: theme.space(1.5),
                  height: theme.space(1.5),
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
                ),
              ),
              ?trailing,
            ],
          ),
        );
      },
    );
  }
}

enum GhAlertTone { danger, amber, mint }

class GhAlertBox extends StatelessWidget {
  const GhAlertBox({super.key, required this.tone, this.text, this.title, this.icon, this.child, this.padding = 3, this.strong = false});

  final GhAlertTone tone;
  final String? text;
  final String? title;
  final FaIconData? icon;
  final Widget? child;
  final double padding;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final color = switch (tone) {
      GhAlertTone.danger => theme.danger,
      GhAlertTone.amber => theme.amber,
      GhAlertTone.mint => theme.mint,
    };
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: color),
          ),
        if (text != null)
          Padding(
            padding: EdgeInsets.only(top: title != null ? theme.space(1) : 0),
            child: Text(
              text!,
              style: theme.text(size: GhTextSize.xs, color: title != null ? theme.muted : color, lineHeight: 1.625),
            ),
          ),
        ?child,
      ],
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(theme.space(padding)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: strong ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: color.withValues(alpha: strong ? 0.25 : 0.3)),
        ),
        child: icon == null
            ? body
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(2.5),
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(0.5)),
                    child: GhIcon(icon!, size: theme.space(4), color: color),
                  ),
                  Expanded(child: body),
                ],
              ),
      ),
    );
  }
}

class GhBusyButton extends StatelessWidget {
  const GhBusyButton({
    super.key,
    required this.onPressed,
    required this.busy,
    required this.label,
    this.paddingX = 5,
    this.danger = false,
    this.icon,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;
  final double paddingX;
  final bool danger;
  final FaIconData? icon;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      autofocus: autofocus,
      borderRadius: radius,
      disabledOpacity: danger ? 0.4 : 0.5,
      disabledCursor: SystemMouseCursors.forbidden,
      rippleColor: Colors.white,
      builder: (context, states) => GhAnimatedBox(
        color: danger
            ? Color.lerp(theme.danger, Colors.white, states.active ? 0.1 : 0)!
            : (states.active ? theme.accentBright : theme.accent),
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(paddingX), vertical: theme.space(2.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            if (busy)
              const GhSpinnerIcon(color: Colors.white)
            else if (icon != null)
              GhIcon(icon!, size: theme.space(3.5), color: Colors.white),
            Text(
              label,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
