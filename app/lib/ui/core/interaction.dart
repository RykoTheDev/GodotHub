import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../../motion/ease.dart';
import '../../motion/intro.dart';
import '../../motion/motion.dart';

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
    this.pressMotion = true,
    this.ripple = true,
    this.rippleColor,
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
  final bool pressMotion;
  final bool ripple;
  final Color? rippleColor;

  @override
  State<GhPressable> createState() => _GhPressableState();
}

class _GhPressableState extends State<GhPressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  int _pulse = 0;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    if (_enabled) {
      widget.onPressed!();
    }
  }

  void _keyActivate() {
    if (!_enabled) {
      return;
    }
    if (widget.pressMotion) {
      setState(() => _pulse += 1);
    }
    widget.onPressed!();
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
    child = GhPressMotion(
      enabled: enabled && widget.pressMotion,
      ripple: widget.ripple,
      rippleColor: widget.rippleColor,
      borderRadius: widget.borderRadius,
      pulse: _pulse,
      child: child,
    );
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
          _keyActivate();
          return null;
        }),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) {
          _keyActivate();
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
    child = GhNoDrag(child: child);
    if (GhIntroItem.participates(context)) {
      child = GhIntroItem(child: child);
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
      duration: GhMotion.of(context).css(states.pressed ? GhDurations.iconPress : GhDurations.iconTransform),
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
      duration: GhMotion.of(context).css(duration),
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
      duration: GhMotion.of(context).css(GhDurations.color),
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
      duration: GhMotion.of(context).css(GhDurations.color),
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

abstract final class GhPressTiming {
  static double pressScale(double width) => width > 260 ? 0.985 : (width > 90 ? 0.955 : 0.88);
  static const press = 0.14;
  static final pressEase = GsapEase('power2.out');
  static const release = 0.8;
  static final releaseEase = GsapEase('elastic.out(1.15, 0.32)');
  static const pulseFrom = 0.92;
  static const pulse = 0.7;
  static const ripple = 0.6;
  static final rippleEase = GsapEase('power2.out');
  static const rippleAlpha = 0.18;
  static const rippleMinWidth = 18.0;
  static const rippleMinHeight = 14.0;
}

double ghRippleDiameter(Size size) => math.sqrt(size.width * size.width + size.height * size.height) * 2;

class GhNoRipple extends InheritedWidget {
  const GhNoRipple({super.key, required super.child});

  static bool of(BuildContext context) => context.getInheritedWidgetOfExactType<GhNoRipple>() != null;

  @override
  bool updateShouldNotify(GhNoRipple oldWidget) => false;
}

class GhPressMotion extends StatefulWidget {
  const GhPressMotion({
    super.key,
    required this.child,
    this.enabled = true,
    this.press = true,
    this.ripple = true,
    this.rippleColor,
    this.borderRadius,
    this.pulse = 0,
  });

  final Widget child;
  final bool enabled;
  final bool press;
  final bool ripple;
  final Color? rippleColor;
  final BorderRadius? borderRadius;
  final int pulse;

  @override
  State<GhPressMotion> createState() => GhPressMotionState();
}

class _Ripple {
  _Ripple(this.center, this.diameter, this.controller);

  final Offset center;
  final double diameter;
  final AnimationController controller;
}

class GhPressMotionState extends State<GhPressMotion> with TickerProviderStateMixin {
  static int? _claimedPointer;

  AnimationController? _scale;
  double _from = 1;
  double _to = 1;
  Curve _curve = Curves.linear;
  bool _held = false;
  final List<_Ripple> _ripples = [];
  GhMotionData _motion = const GhMotionData();

  double get scale {
    final controller = _scale;
    if (controller == null) {
      return 1;
    }
    if (controller.isCompleted) {
      return _to;
    }
    return _from + (_to - _from) * _curve.transform(controller.value);
  }

  int get rippleCount => _ripples.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = GhMotion.of(context);
  }

  @override
  void didUpdateWidget(GhPressMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse && widget.enabled && widget.press && _motion.pressOn) {
      _tween(1, GhPressTiming.pulse, GhEase.elastic, from: GhPressTiming.pulseFrom);
    }
  }

  @override
  void dispose() {
    _scale?.dispose();
    final ripples = _ripples.toList();
    _ripples.clear();
    for (final ripple in ripples) {
      ripple.controller.dispose();
    }
    super.dispose();
  }

  void _tween(double to, double seconds, Curve curve, {double? from}) {
    final start = from ?? scale;
    final controller = _scale ??= AnimationController(vsync: this)..addListener(_onScale);
    _from = start;
    _to = to;
    _curve = curve;
    controller.duration = _motion.gsap(seconds);
    controller.forward(from: 0);
  }

  void _onScale() => setState(() {});

  void _onDown(PointerDownEvent event) {
    if (_claimedPointer == event.pointer) {
      return;
    }
    _claimedPointer = event.pointer;
    if (!widget.enabled || (event.buttons & kPrimaryButton) == 0 || _motion.off) {
      return;
    }
    if (widget.press && _motion.prefs.press) {
      _held = true;
      _tween(GhPressTiming.pressScale(context.size?.width ?? 0), GhPressTiming.press, GhPressTiming.pressEase);
    }
    if (widget.ripple && _motion.rippleOn && !GhNoRipple.of(context)) {
      _addRipple(event.localPosition);
    }
  }

  void _onUp(PointerEvent event) {
    if (!_held) {
      return;
    }
    _held = false;
    _tween(1, GhPressTiming.release, GhPressTiming.releaseEase);
  }

  void _addRipple(Offset position) {
    final size = context.size;
    if (size == null || size.width < GhPressTiming.rippleMinWidth || size.height < GhPressTiming.rippleMinHeight) {
      return;
    }
    final controller = AnimationController(vsync: this, duration: _motion.gsap(GhPressTiming.ripple));
    final ripple = _Ripple(position, ghRippleDiameter(size), controller);
    setState(() => _ripples.add(ripple));
    controller.forward().whenCompleteOrCancel(() {
      if (!_ripples.remove(ripple)) {
        return;
      }
      controller.dispose();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.rippleColor ?? DefaultTextStyle.of(context).style.color ?? GhTheme.of(context).ink;
    return _PressScale(
      scale: scale,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerUp: _onUp,
        onPointerCancel: _onUp,
        child: CustomPaint(
          foregroundPainter: _ripples.isEmpty
              ? null
              : _RipplePainter(
                  ripples: _ripples.toList(),
                  color: color,
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PressScale extends SingleChildRenderObjectWidget {
  const _PressScale({required this.scale, super.child});

  final double scale;

  Matrix4 get _matrix => Matrix4.diagonal3Values(scale, scale, 1);

  @override
  RenderTransform createRenderObject(BuildContext context) =>
      RenderTransform(transform: _matrix, alignment: Alignment.center, textDirection: Directionality.maybeOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderTransform renderObject) {
    renderObject
      ..transform = _matrix
      ..textDirection = Directionality.maybeOf(context);
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.ripples, required this.color, required this.borderRadius})
      : super(repaint: Listenable.merge([for (final ripple in ripples) ripple.controller]));

  final List<_Ripple> ripples;
  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(borderRadius.toRRect(Offset.zero & size));
    for (final ripple in ripples) {
      final t = GhPressTiming.rippleEase.transform(ripple.controller.value.clamp(0.0, 1.0));
      final alpha = color.a * GhPressTiming.rippleAlpha * (1 - t);
      if (alpha <= 0) {
        continue;
      }
      canvas.drawCircle(ripple.center, ripple.diameter / 2 * t, Paint()..color = color.withValues(alpha: alpha));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius || oldDelegate.ripples.length != ripples.length;
}

abstract final class GhTiltTiming {
  static const perspective = 900.0;
  static const maxStrength = 7.0;
  static const lift = -4.0;
  static const move = 0.5;
  static final moveEase = GhEase.soft;
  static const leave = 1.0;
  static final leaveEase = GsapEase('elastic.out(1, 0.5)');
}

double ghTiltStrength(Size size) {
  if (size.width < 120 || size.height < 64 || size.width > 1400 || size.height > 640) {
    return 0;
  }
  return math.min(GhTiltTiming.maxStrength, 2400 / size.width);
}

GhTiltAngles? ghTiltAngles(Size size, Offset local) {
  final strength = ghTiltStrength(size);
  if (strength == 0) {
    return null;
  }
  final px = (local.dx / size.width).clamp(0.0, 1.0);
  final py = (local.dy / size.height).clamp(0.0, 1.0);
  return GhTiltAngles(rotationX: (0.5 - py) * strength, rotationY: (px - 0.5) * strength, y: GhTiltTiming.lift);
}

@immutable
class GhTiltAngles {
  const GhTiltAngles({this.rotationX = 0, this.rotationY = 0, this.y = 0});

  static const rest = GhTiltAngles();

  final double rotationX;
  final double rotationY;
  final double y;

  static GhTiltAngles lerp(GhTiltAngles a, GhTiltAngles b, double t) => GhTiltAngles(
        rotationX: a.rotationX + (b.rotationX - a.rotationX) * t,
        rotationY: a.rotationY + (b.rotationY - a.rotationY) * t,
        y: a.y + (b.y - a.y) * t,
      );

  bool get isRest => rotationX == 0 && rotationY == 0 && y == 0;

  Matrix4 toMatrix() {
    if (isRest) {
      return Matrix4.identity();
    }
    return Matrix4.identity()
      ..setEntry(3, 2, -1 / GhTiltTiming.perspective)
      ..translateByDouble(0, y, 0, 1)
      ..rotateY(rotationY * math.pi / 180)
      ..rotateX(rotationX * math.pi / 180);
  }

  @override
  bool operator ==(Object other) =>
      other is GhTiltAngles && other.rotationX == rotationX && other.rotationY == rotationY && other.y == y;

  @override
  int get hashCode => Object.hash(rotationX, rotationY, y);
}

class GhNoTilt extends InheritedWidget {
  const GhNoTilt({super.key, required super.child});

  static bool of(BuildContext context) => context.getInheritedWidgetOfExactType<GhNoTilt>() != null;

  @override
  bool updateShouldNotify(GhNoTilt oldWidget) => false;
}

class GhTiltCard extends StatefulWidget {
  const GhTiltCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.press = true,
    this.ripple = true,
    this.rippleColor,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final bool press;
  final bool ripple;
  final Color? rippleColor;

  @override
  State<GhTiltCard> createState() => GhTiltCardState();
}

class GhTiltCardState extends State<GhTiltCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)..addListener(() => setState(() {}));
  GhTiltAngles _from = GhTiltAngles.rest;
  GhTiltAngles _to = GhTiltAngles.rest;
  Curve _curve = Curves.linear;
  bool _hovered = false;

  GhTiltAngles get angles {
    if (_controller.isCompleted) {
      return _to;
    }
    return GhTiltAngles.lerp(_from, _to, _curve.transform(_controller.value.clamp(0.0, 1.0)));
  }

  bool get hovered => _hovered;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _allowed() {
    if (!GhMotion.of(context).tiltOn || GhNoTilt.of(context)) {
      return false;
    }
    return ModalRoute.of(context) is! PopupRoute;
  }

  void _tween(GhTiltAngles to, double seconds, Curve curve) {
    _from = angles;
    _to = to;
    _curve = curve;
    _controller.duration = GhMotion.of(context).gsap(seconds);
    _controller.forward(from: 0);
  }

  void _onHover(PointerHoverEvent event) {
    if (event.kind != PointerDeviceKind.mouse || event.buttons != 0) {
      return;
    }
    if (!_allowed()) {
      _leave();
      return;
    }
    _hovered = true;
    final size = context.size;
    if (size == null) {
      return;
    }
    final target = ghTiltAngles(size, event.localPosition);
    if (target == null) {
      return;
    }
    _tween(target, GhTiltTiming.move, GhTiltTiming.moveEase);
  }

  void _leave() {
    if (!_hovered) {
      return;
    }
    _hovered = false;
    _tween(GhTiltAngles.rest, GhTiltTiming.leave, GhTiltTiming.leaveEase);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: _onHover,
      onExit: (_) => _leave(),
      child: Transform(
        alignment: Alignment.center,
        transform: angles.toMatrix(),
        child: GhPressMotion(
          enabled: widget.press,
          ripple: widget.ripple,
          rippleColor: widget.rippleColor,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}

abstract final class GhSpinTiming {
  static const duration = 0.9;
  static const rotation = 180.0;
  static const fromScale = 0.6;
}

class GhSpin extends StatefulWidget {
  const GhSpin({super.key, required this.child, this.trigger});

  final Widget child;
  final Object? trigger;

  @override
  State<GhSpin> createState() => GhSpinState();
}

class GhSpinState extends State<GhSpin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didUpdateWidget(GhSpin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      spin();
    }
  }

  void spin() {
    final motion = GhMotion.of(context);
    if (motion.off) {
      return;
    }
    _controller.duration = motion.gsap(GhSpinTiming.duration);
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) {
        _controller.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final matrix = Matrix4.identity();
        if (_controller.isAnimating) {
          final t = GhEase.elastic.transform(_controller.value);
          final scale = GhSpinTiming.fromScale + (1 - GhSpinTiming.fromScale) * t;
          matrix
            ..rotateZ(GhSpinTiming.rotation * t * math.pi / 180)
            ..scaleByDouble(scale, scale, 1, 1);
        }
        return Transform(alignment: Alignment.center, transform: matrix, child: child);
      },
    );
  }
}

class GhNoDrag extends StatelessWidget {
  const GhNoDrag({super.key, required this.child});

  static const marker = 'gh-no-drag';

  final Widget child;

  @override
  Widget build(BuildContext context) => MetaData(metaData: marker, child: child);
}

bool ghHitsControl(Offset position, int viewId, RenderObject? self) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, position, viewId);
  for (final entry in result.path) {
    final target = entry.target;
    if (identical(target, self)) return false;
    if (target is RenderMetaData && target.metaData == GhNoDrag.marker) return true;
    if (target is RenderEditable) return true;
  }
  return false;
}
