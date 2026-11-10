import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';

@immutable
class GhStates {
  const GhStates({this.hovered = false, this.pressed = false, this.focused = false, this.disabled = false});

  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool disabled;

  bool get active => hovered && !disabled;
  bool get highlighted => (hovered || focused) && !disabled;
}

enum GhFocusStyle { outline, ring, none }

class GhForcedStates extends InheritedWidget {
  const GhForcedStates({super.key, this.hovered = false, this.pressed = false, this.focused = false, required super.child});

  final bool hovered;
  final bool pressed;
  final bool focused;

  static GhForcedStates? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GhForcedStates>();

  GhStates apply(GhStates states) => GhStates(
        hovered: states.hovered || hovered,
        pressed: states.pressed || (pressed && !states.disabled),
        focused: states.focused || focused,
        disabled: states.disabled,
      );

  @override
  bool updateShouldNotify(GhForcedStates oldWidget) =>
      hovered != oldWidget.hovered || pressed != oldWidget.pressed || focused != oldWidget.focused;
}

class GhPressable extends StatefulWidget {
  const GhPressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.onSecondaryTapUp,
    this.focusNode,
    this.autofocus = false,
    this.focusStyle = GhFocusStyle.ring,
    this.borderRadius,
    this.cursor,
    this.disabledCursor = SystemMouseCursors.basic,
    this.semanticLabel,
    this.tooltip,
    this.button = true,
    this.toggled,
    this.checked,
    this.mixed,
    this.selected,
    this.expanded,
    this.canRequestFocus = true,
    this.disabledOpacity = 0.4,
    this.shortcuts,
  });

  final Widget Function(BuildContext context, GhStates states) builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onSecondaryTapUp;
  final FocusNode? focusNode;
  final bool autofocus;
  final GhFocusStyle focusStyle;
  final BorderRadius? borderRadius;
  final MouseCursor? cursor;
  final MouseCursor disabledCursor;
  final String? semanticLabel;
  final String? tooltip;
  final bool button;
  final bool? toggled;
  final bool? checked;
  final bool? mixed;
  final bool? selected;
  final bool? expanded;
  final bool canRequestFocus;
  final double? disabledOpacity;
  final Map<ShortcutActivator, Intent>? shortcuts;

  @override
  State<GhPressable> createState() => _GhPressableState();
}

class _GhPressableState extends State<GhPressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    if (_enabled) {
      widget.onPressed!();
    }
  }

  @override
  void didUpdateWidget(GhPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && (_pressed || _hovered)) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final raw = GhStates(hovered: _hovered, pressed: _pressed && enabled, focused: _focused, disabled: !enabled);
    final states = GhForcedStates.maybeOf(context)?.apply(raw) ?? raw;
    Widget child = widget.builder(context, states);
    if (widget.focusStyle != GhFocusStyle.none) {
      child = GhFocusRing(
        visible: states.focused && enabled,
        style: widget.focusStyle,
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: child,
      );
    }
    if (!enabled && widget.disabledOpacity != null) {
      child = Opacity(opacity: widget.disabledOpacity!, child: child);
    }
    child = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: true,
      shortcuts: widget.shortcuts,
      mouseCursor: enabled ? (widget.cursor ?? SystemMouseCursors.click) : widget.disabledCursor,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          _activate();
          return null;
        }),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) {
          _activate();
          return null;
        }),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? _activate : null,
        onLongPress: enabled ? widget.onLongPress : null,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        child: child,
      ),
    );
    if (!widget.canRequestFocus) {
      child = ExcludeFocus(child: child);
    }
    child = Semantics(
      button: widget.button,
      enabled: enabled,
      label: widget.semanticLabel,
      toggled: widget.toggled,
      checked: widget.checked,
      mixed: widget.mixed,
      selected: widget.selected,
      expanded: widget.expanded,
      child: child,
    );
    final tooltip = widget.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      child = Tooltip(message: tooltip, excludeFromSemantics: true, child: child);
    }
    return child;
  }
}

class GhFocusRing extends StatelessWidget {
  const GhFocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.style = GhFocusStyle.ring,
    this.borderRadius = BorderRadius.zero,
  });

  final bool visible;
  final GhFocusStyle style;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (style == GhFocusStyle.none) {
      return child;
    }
    final theme = GhTheme.of(context);
    return CustomPaint(
      foregroundPainter: _FocusRingPainter(
        progress: visible ? 1 : 0,
        style: style,
        color: theme.accent,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({required this.progress, required this.style, required this.color, required this.borderRadius});

  final double progress;
  final GhFocusStyle style;
  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }
    final rect = Offset.zero & size;
    if (style == GhFocusStyle.ring) {
      final inner = borderRadius.toRRect(rect);
      final outer = inner.inflate(3);
      canvas.drawDRRect(outer, inner, Paint()..color = color.withValues(alpha: 0.45 * progress));
      return;
    }
    final inner = borderRadius.toRRect(rect).inflate(2);
    final outer = inner.inflate(2);
    canvas.drawDRRect(outer, inner, Paint()..color = color.withValues(alpha: 0.7 * progress));
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.style != style ||
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius;
}

class GhIconMotionScale extends StatelessWidget {
  const GhIconMotionScale({super.key, required this.states, required this.child, this.enabled = true});

  final GhStates states;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scale = !enabled || states.disabled
        ? 1.0
        : states.pressed
            ? GhIconMotion.pressScale
            : states.hovered
                ? GhIconMotion.hoverScale
                : 1.0;
    return AnimatedScale(
      scale: scale,
      duration: states.pressed ? GhDurations.iconPress : GhDurations.iconTransform,
      curve: GhCurves.spring,
      child: child,
    );
  }
}

class GhBrightness extends StatelessWidget {
  const GhBrightness({super.key, required this.amount, required this.child});

  final double amount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (amount == 1) {
      return child;
    }
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        amount, 0, 0, 0, 0,
        0, amount, 0, 0, 0,
        0, 0, amount, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }
}

class GhAnimatedBox extends StatelessWidget {
  const GhAnimatedBox({
    super.key,
    this.color,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.padding,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.clip = false,
    this.duration = GhDurations.interactive,
    required this.child,
  });

  final Color? color;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final bool clip;
  final Duration duration;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: GhCurves.outExpo,
      width: width,
      height: height,
      constraints: constraints,
      alignment: alignment,
      padding: padding,
      clipBehavior: clip && borderRadius != null ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(color: color, border: border, borderRadius: borderRadius, boxShadow: boxShadow),
      child: child,
    );
  }
}

class GhAnimatedText extends StatelessWidget {
  const GhAnimatedText(this.text, {super.key, required this.style, this.maxLines, this.overflow, this.textAlign});

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      style: style,
      duration: GhDurations.color,
      curve: GhCurves.outExpo,
      child: Text(text, maxLines: maxLines, overflow: overflow, textAlign: textAlign),
    );
  }
}

class GhAnimatedIcon extends StatelessWidget {
  const GhAnimatedIcon(this.icon, {super.key, required this.color, required this.size, this.faded = false});

  final FaIconData icon;
  final Color color;
  final double size;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: GhDurations.color,
      curve: GhCurves.outExpo,
      builder: (context, value, _) => GhIcon(icon, size: size, color: value, faded: faded),
    );
  }
}

const ghActivateShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
};
