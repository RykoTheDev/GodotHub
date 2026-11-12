import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../../motion/presence.dart';
import '../core/interaction.dart';

const double ghMenuViewportPad = 8;
const double ghMenuGap = 8;

abstract final class GhMenuColors {
  static const red300 = Color(0xFFFFA2A2);
  static const red400 = Color(0xFFFF6467);
  static const red500 = Color(0xFFFB2C36);
  static const divider = Color(0x0FFFFFFF);
}

@immutable
class GhMenuItemAction {
  const GhMenuItemAction({required this.icon, required this.label, required this.onPressed});

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;
}

@immutable
class GhMenuItem {
  const GhMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.leading,
    this.onSelected,
    this.disabled = false,
    this.danger = false,
    this.active = false,
    this.dotColor,
    this.shortcut,
    this.dividerAfter = false,
    this.badge,
    this.children = const [],
    this.action,
  });

  final String id;
  final String label;
  final FaIconData? icon;
  final Widget? leading;
  final VoidCallback? onSelected;
  final bool disabled;
  final bool danger;
  final bool active;
  final Color? dotColor;
  final String? shortcut;
  final bool dividerAfter;
  final String? badge;
  final List<GhMenuItem> children;
  final GhMenuItemAction? action;

  bool get hasChildren => children.isNotEmpty;
}

Color _accentBackground(GhTheme theme) => theme.accent;
Color _raisedBackground(GhTheme theme) => theme.raised;
Color _inkForeground(GhTheme theme) => theme.ink;

@immutable
class GhMenuActiveStyle {
  const GhMenuActiveStyle({required this.background, required this.foreground});

  final Color Function(GhTheme theme) background;
  final Color Function(GhTheme theme) foreground;

  static const accent = GhMenuActiveStyle(background: _accentBackground, foreground: _inkForeground);
  static const raised = GhMenuActiveStyle(background: _raisedBackground, foreground: _inkForeground);
}

class GhMenuItemFocusNode extends FocusNode {
  GhMenuItemFocusNode({super.debugLabel});
}

KeyEventResult ghMenuArrowNavigation(KeyEvent event, Iterable<FocusNode> nodes) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  final key = event.logicalKey;
  if (key != LogicalKeyboardKey.arrowDown &&
      key != LogicalKeyboardKey.arrowUp &&
      key != LogicalKeyboardKey.home &&
      key != LogicalKeyboardKey.end) {
    return KeyEventResult.ignored;
  }
  final entries = nodes.where((n) => n.context != null && n.canRequestFocus).toList();
  if (entries.isEmpty) {
    return KeyEventResult.ignored;
  }
  final index = entries.indexWhere((n) => n.hasPrimaryFocus);
  final length = entries.length;
  final next = switch (key) {
    LogicalKeyboardKey.arrowDown => (index + 1) % length,
    LogicalKeyboardKey.arrowUp => (index - 1 + length) % length,
    LogicalKeyboardKey.home => 0,
    _ => length - 1,
  };
  entries[next].requestFocus();
  return KeyEventResult.handled;
}

FocusNode? ghFirstFocusableMenuNode(Iterable<FocusNode> nodes) {
  for (final node in nodes) {
    if (node.context != null && node.canRequestFocus) {
      return node;
    }
  }
  return null;
}

class GhMenuSurface extends StatelessWidget {
  const GhMenuSurface({super.key, required this.child, this.compact = false, this.minWidth, this.maxHeight, this.fitContent = true});

  final Widget child;
  final bool compact;
  final double? minWidth;
  final double? maxHeight;
  final bool fitContent;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final padding = EdgeInsets.all(theme.space(compact ? 2 : 2.5));
    final radius = BorderRadius.circular(theme.radiusMenu);
    final decoration = BoxDecoration(
      color: theme.overlay,
      borderRadius: radius,
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      boxShadow: GhShadows.md(),
    );
    final scrollable = maxHeight != null;
    Widget surface = Container(
      decoration: decoration,
      constraints: scrollable ? BoxConstraints(maxHeight: maxHeight!) : null,
      clipBehavior: scrollable ? Clip.antiAlias : Clip.none,
      padding: scrollable ? null : padding,
      child: scrollable ? SingleChildScrollView(padding: padding, child: child) : child,
    );
    if (fitContent) {
      surface = IntrinsicWidth(child: surface);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth ?? theme.space(compact ? 48 : 60)),
      child: surface,
    );
  }
}

class GhMenuDivider extends StatelessWidget {
  const GhMenuDivider({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: theme.space(compact ? 0.5 : 1)),
      color: GhMenuColors.divider,
    );
  }
}

class GhMenuButton extends StatefulWidget {
  const GhMenuButton({
    super.key,
    required this.item,
    required this.onSelect,
    this.compact = false,
    this.caret = false,
    this.activeStyle = GhMenuActiveStyle.accent,
    this.focusNode,
  });

  final GhMenuItem item;
  final VoidCallback onSelect;
  final bool compact;
  final bool caret;
  final GhMenuActiveStyle activeStyle;
  final FocusNode? focusNode;

  @override
  State<GhMenuButton> createState() => _GhMenuButtonState();
}

class _GhMenuButtonState extends State<GhMenuButton> {
  bool _disabledHover = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final item = widget.item;
    final radius = BorderRadius.circular(theme.radiusItem);
    Widget result = GhPressable(
      onPressed: item.disabled ? null : widget.onSelect,
      focusNode: widget.focusNode,
      focusStyle: GhFocusStyle.outline,
      borderRadius: radius,
      disabledCursor: SystemMouseCursors.forbidden,
      selected: item.active ? true : null,
      builder: (context, states) => _content(context, theme, states, radius),
    );
    if (item.disabled) {
      result = MouseRegion(
        onEnter: (_) => setState(() => _disabledHover = true),
        onExit: (_) => setState(() => _disabledHover = false),
        child: result,
      );
    }
    return GhCascadeItem(role: GhCascadeRole.menuItem, child: result);
  }

  Widget _content(BuildContext context, GhTheme theme, GhStates states, BorderRadius radius) {
    final item = widget.item;
    final compact = widget.compact;
    final hovered = states.hovered || (item.disabled && _disabledHover);
    final Color background;
    final Color foreground;
    final Color iconBox;
    if (item.danger) {
      background = GhMenuColors.red500.withValues(alpha: hovered ? 0.1 : 0);
      foreground = hovered ? GhMenuColors.red300 : GhMenuColors.red400;
      iconBox = GhMenuColors.red500.withValues(alpha: 0.1);
    } else if (item.active) {
      background = widget.activeStyle.background(theme);
      foreground = widget.activeStyle.foreground(theme);
      iconBox = theme.accent.withValues(alpha: 0.2);
    } else {
      background = hovered ? theme.raised : theme.raised.withValues(alpha: 0);
      foreground = hovered ? theme.ink : theme.muted;
      iconBox = theme.raised.withValues(alpha: 0);
    }
    final lift = states.hovered && !states.disabled;
    final spanIconStates = GhStates(hovered: states.hovered, disabled: states.disabled);
    final children = <Widget>[
      if (item.leading != null) item.leading!,
      if (item.icon != null)
        Container(
          width: theme.space(compact ? 6 : 7),
          height: theme.space(compact ? 6 : 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: iconBox, borderRadius: BorderRadius.circular(theme.radiusBtn)),
          child: GhIconMotionScale(
            states: spanIconStates,
            child: GhAnimatedIcon(item.icon!, color: foreground, size: theme.space(compact ? 3 : 3.5)),
          ),
        ),
      if (item.dotColor != null)
        ExcludeSemantics(
          child: Container(
            width: theme.space(2),
            height: theme.space(2),
            decoration: BoxDecoration(color: item.dotColor, shape: BoxShape.circle),
          ),
        ),
      Expanded(
        child: GhAnimatedText(
          item.label,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
      ),
      if (item.badge != null)
        Container(
          padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
          decoration: BoxDecoration(
            color: item.active ? Colors.black.withValues(alpha: 0.15) : theme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.radiusTag),
            border: Border.all(color: item.active ? Colors.black.withValues(alpha: 0.1) : theme.accentDim.withValues(alpha: 0.4)),
          ),
          child: Text(
            item.badge!,
            maxLines: 1,
            style: theme.text(
              size: GhTextSize.x3s,
              weight: GhWeight.semibold,
              lineHeight: 1 / 0.75,
              color: item.active ? theme.ink : theme.accentBright,
            ),
          ),
        ),
      if (item.shortcut != null)
        Text(
          item.shortcut!,
          maxLines: 1,
          style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted, lineHeight: 1 / 0.75),
        ),
      if (widget.caret)
        GhIconMotionScale(
          states: states,
          child: Transform.flip(
            flipX: Directionality.of(context) == TextDirection.rtl,
            child: GhIcon(GhIcons.chevronRight, size: theme.space(3), color: theme.muted.withValues(alpha: 0.8)),
          ),
        ),
    ];
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(SizedBox(width: theme.space(1)));
      }
      spaced.add(children[i]);
    }
    return GhLiftBox(
      color: background,
      borderRadius: radius,
      lift: lift,
      padding: EdgeInsets.symmetric(horizontal: theme.space(compact ? 2 : 2.5), vertical: theme.space(compact ? 1.5 : 2)),
      child: Row(children: spaced),
    );
  }
}

class GhLiftBox extends StatelessWidget {
  const GhLiftBox({
    super.key,
    required this.lift,
    required this.borderRadius,
    this.color,
    this.border,
    this.padding,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    required this.child,
  });

  final bool lift;
  final BorderRadius borderRadius;
  final Color? color;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: lift ? 1 : 0),
      duration: GhDurations.interactive,
      curve: GhCurves.outExpo,
      builder: (context, t, child) => CustomPaint(
        painter: _OuterShadowPainter(progress: t, borderRadius: borderRadius),
        child: child,
      ),
      child: GhAnimatedBox(
        color: color,
        border: border,
        borderRadius: borderRadius,
        padding: padding,
        width: width,
        height: height,
        constraints: constraints,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

class _OuterShadowPainter extends CustomPainter {
  _OuterShadowPainter({required this.progress, required this.borderRadius});

  final double progress;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }
    final rrect = borderRadius.toRRect(Offset.zero & size);
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(64))
        ..addRRect(rrect),
    );
    for (final shadow in GhShadows.hoverLift()) {
      final paint = shadow.toPaint()..color = shadow.color.withValues(alpha: shadow.color.a * progress);
      canvas.drawRRect(rrect.shift(shadow.offset).inflate(shadow.spreadRadius), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.borderRadius != borderRadius;
}
