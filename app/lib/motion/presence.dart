import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'ease.dart';
import 'motion.dart';
import 'tween.dart';

enum GhPresenceKind { modal, popover, tooltip, panel, backdrop, toast, splash, none }

enum GhCascadeRole { part, menuItem, label, disclosure }

double ghTweenProgress(double time, double start, double duration, Curve ease) {
  if (time <= start) {
    return 0;
  }
  if (duration <= 0 || time >= start + duration) {
    return 1;
  }
  return ease.transform((time - start) / duration);
}

@immutable
class GhPoseTarget {
  const GhPoseTarget({
    this.opacity,
    this.x,
    this.y,
    this.xPercent,
    this.yPercent,
    this.scale,
    this.scaleX,
    this.scaleY,
    this.rotation,
    this.blur,
  });

  final double? opacity;
  final double? x;
  final double? y;
  final double? xPercent;
  final double? yPercent;
  final double? scale;
  final double? scaleX;
  final double? scaleY;
  final double? rotation;
  final double? blur;

  GhPose applyTo(GhPose base) => base.copyWith(
    opacity: opacity,
    x: x,
    y: y,
    xPercent: xPercent,
    yPercent: yPercent,
    scale: scale,
    scaleX: scaleX,
    scaleY: scaleY,
    rotation: rotation,
    blur: blur,
  );

  @override
  bool operator ==(Object other) =>
      other is GhPoseTarget &&
      other.opacity == opacity &&
      other.x == x &&
      other.y == y &&
      other.xPercent == xPercent &&
      other.yPercent == yPercent &&
      other.scale == scale &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY &&
      other.rotation == rotation &&
      other.blur == blur;

  @override
  int get hashCode => Object.hash(opacity, x, y, xPercent, yPercent, scale, scaleX, scaleY, rotation, blur);
}

@immutable
class GhEnterTween {
  const GhEnterTween({required this.from, required this.duration, required this.ease, this.at = 0});

  final GhPose from;
  final double duration;
  final Curve ease;
  final double at;

  double get end => at + duration;

  double progress(double time) => ghTweenProgress(time, at, duration, ease);

  GhPose poseAt(double time) => GhPose.lerp(from, GhPose.identity, progress(time));

  @override
  bool operator ==(Object other) =>
      other is GhEnterTween && other.from == from && other.duration == duration && other.ease == ease && other.at == at;

  @override
  int get hashCode => Object.hash(from, duration, ease, at);
}

@immutable
class GhExitTween {
  const GhExitTween({required this.to, required this.duration, required this.ease, this.at = 0});

  final GhPoseTarget to;
  final double duration;
  final Curve ease;
  final double at;

  double get end => at + duration;

  double progress(double time) => ghTweenProgress(time, at, duration, ease);

  GhPose poseAt(GhPose start, double time) => GhPose.lerp(start, to.applyTo(start), progress(time));

  @override
  bool operator ==(Object other) =>
      other is GhExitTween && other.to == to && other.duration == duration && other.ease == ease && other.at == at;

  @override
  int get hashCode => Object.hash(to, duration, ease, at);
}

@immutable
class GhPresenceLayer {
  const GhPresenceLayer({this.enter, this.exit});

  static const none = GhPresenceLayer();

  final GhEnterTween? enter;
  final GhExitTween? exit;

  double get enterEnd => enter?.end ?? 0;

  double get exitEnd => exit?.end ?? 0;

  bool get blurs => (enter?.from.blur ?? 0) > 0 || (exit?.to.blur ?? 0) > 0;

  GhPose enterPoseAt(double time) => enter?.poseAt(time) ?? GhPose.identity;

  GhPose poseAt(GhPresenceClock clock) {
    if (!clock.exiting) {
      return enterPoseAt(clock.time);
    }
    final start = enterPoseAt(clock.enteredAt);
    return exit?.poseAt(start, clock.time) ?? start;
  }

  @override
  bool operator ==(Object other) => other is GhPresenceLayer && other.enter == enter && other.exit == exit;

  @override
  int get hashCode => Object.hash(enter, exit);
}

@immutable
class GhCascade {
  const GhCascade({
    required this.role,
    required this.from,
    required this.duration,
    required this.ease,
    this.at = 0,
    this.amountPerItem = 0,
    this.maxAmount = 0,
    this.limit,
  });

  final GhCascadeRole role;
  final GhPose from;
  final double duration;
  final Curve ease;
  final double at;
  final double amountPerItem;
  final double maxAmount;
  final int? limit;

  int countOf(int registered) => limit == null ? registered : math.min(registered, limit!);

  double amountFor(int count) => math.min(maxAmount, count * amountPerItem);

  double get maxEnd => at + maxAmount + duration;

  double startOf(int index, int registered) {
    final count = countOf(registered);
    return at + ghStaggerAmount(index, count, amountFor(count));
  }

  GhPose poseAt(int index, int registered, double time) {
    if (index >= countOf(registered)) {
      return GhPose.identity;
    }
    return GhPose.lerp(from, GhPose.identity, ghTweenProgress(time, startOf(index, registered), duration, ease));
  }

  @override
  bool operator ==(Object other) =>
      other is GhCascade &&
      other.role == role &&
      other.from == from &&
      other.duration == duration &&
      other.ease == ease &&
      other.at == at &&
      other.amountPerItem == amountPerItem &&
      other.maxAmount == maxAmount &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(role, from, duration, ease, at, amountPerItem, maxAmount, limit);
}

@immutable
class GhPresenceSpec {
  const GhPresenceSpec({
    this.layer = GhPresenceLayer.none,
    this.inner = GhPresenceLayer.none,
    this.cascade,
    this.enterWhenOff = false,
    this.exitWhenOff = false,
  });

  final GhPresenceLayer layer;
  final GhPresenceLayer inner;
  final GhCascade? cascade;
  final bool enterWhenOff;
  final bool exitWhenOff;

  double get enterLength => math.max(math.max(layer.enterEnd, inner.enterEnd), cascade?.maxEnd ?? 0);

  double get exitLength => math.max(layer.exitEnd, inner.exitEnd);

  static GhPresenceSpec of(GhPresenceKind kind, {bool up = false}) => switch (kind) {
    GhPresenceKind.modal => GhPresenceSpecs.modal,
    GhPresenceKind.popover => up ? GhPresenceSpecs.popoverUp : GhPresenceSpecs.popover,
    GhPresenceKind.tooltip => GhPresenceSpecs.tooltip,
    GhPresenceKind.panel => GhPresenceSpecs.panel,
    GhPresenceKind.backdrop => GhPresenceSpecs.backdrop,
    GhPresenceKind.toast => GhPresenceSpecs.toast,
    GhPresenceKind.splash => GhPresenceSpecs.splash,
    GhPresenceKind.none => GhPresenceSpecs.none,
  };

  @override
  bool operator ==(Object other) =>
      other is GhPresenceSpec &&
      other.layer == layer &&
      other.inner == inner &&
      other.cascade == cascade &&
      other.enterWhenOff == enterWhenOff &&
      other.exitWhenOff == exitWhenOff;

  @override
  int get hashCode => Object.hash(layer, inner, cascade, enterWhenOff, exitWhenOff);
}

abstract final class GhPresenceSpecs {
  static final modalOverlay = GhPresenceLayer(
    enter: GhEnterTween(from: const GhPose(opacity: 0), duration: 0.2, ease: GhEase.soft),
    exit: GhExitTween(to: const GhPoseTarget(opacity: 0), duration: 0.22, ease: GsapEase('power2.out'), at: 0.02),
  );

  static final modalPanel = GhPresenceLayer(
    enter: GhEnterTween(from: const GhPose(opacity: 0, y: 18, scale: 0.96), duration: 0.36, ease: GhEase.out),
    exit: GhExitTween(to: const GhPoseTarget(opacity: 0, y: 12, scale: 0.96), duration: 0.2, ease: GhEase.easeIn),
  );

  static final modalParts = GhCascade(
    role: GhCascadeRole.part,
    from: const GhPose(opacity: 0, y: 8),
    duration: 0.3,
    ease: GhEase.out,
    at: 0.05,
    amountPerItem: 0.02,
    maxAmount: 0.12,
    limit: 18,
  );

  static final modal = GhPresenceSpec(layer: modalOverlay, inner: modalPanel, cascade: modalParts);

  static GhPresenceLayer _popoverLayer(bool up) => GhPresenceLayer(
    enter: GhEnterTween(
      from: GhPose(opacity: 0, scale: 0.95, y: up ? 6 : -6),
      duration: 0.28,
      ease: GhEase.out,
    ),
    exit: GhExitTween(to: const GhPoseTarget(opacity: 0, scale: 0.96, y: -4), duration: 0.15, ease: GhEase.easeIn),
  );

  static final popoverItems = GhCascade(
    role: GhCascadeRole.menuItem,
    from: const GhPose(opacity: 0, x: -6),
    duration: 0.24,
    ease: GhEase.soft,
    at: 0.02,
    amountPerItem: 0.015,
    maxAmount: 0.12,
    limit: 16,
  );

  static final popover = GhPresenceSpec(layer: _popoverLayer(false), cascade: popoverItems);

  static final popoverUp = GhPresenceSpec(layer: _popoverLayer(true), cascade: popoverItems);

  static final tooltip = GhPresenceSpec(
    layer: GhPresenceLayer(
      enter: GhEnterTween(from: const GhPose(opacity: 0, scale: 0.78), duration: 0.32, ease: GhEase.pop),
      exit: GhExitTween(to: const GhPoseTarget(opacity: 0, scale: 0.88), duration: 0.14, ease: GhEase.easeIn),
    ),
  );

  static final panel = GhPresenceSpec(
    layer: GhPresenceLayer(
      enter: GhEnterTween(from: const GhPose(opacity: 0, xPercent: 110), duration: 0.7, ease: GhEase.out),
      exit: GhExitTween(to: const GhPoseTarget(opacity: 0.3, xPercent: 110), duration: 0.42, ease: GsapEase('power3.in')),
    ),
  );

  static final backdrop = GhPresenceSpec(
    layer: GhPresenceLayer(
      enter: GhEnterTween(from: const GhPose(opacity: 0), duration: 0.4, ease: GhEase.soft),
      exit: GhExitTween(to: const GhPoseTarget(opacity: 0), duration: 0.35, ease: GhEase.defaultEase),
    ),
  );

  static final toastLeave = GhExitTween(to: const GhPoseTarget(opacity: 0, x: 80, scale: 0.9), duration: 0.45, ease: GsapEase('power3.in'));

  static final toast = GhPresenceSpec(
    layer: GhPresenceLayer(
      enter: GhEnterTween(from: const GhPose(opacity: 0, x: 110, scale: 0.8, rotation: 8), duration: 0.8, ease: GsapEase('back.out(1.5)')),
      exit: toastLeave,
    ),
    exitWhenOff: true,
  );

  static final splash = GhPresenceSpec(
    layer: GhPresenceLayer(
      exit: GhExitTween(to: const GhPoseTarget(opacity: 0, scale: 1.08, blur: 12), duration: 0.75, ease: GsapEase('power2.inOut')),
    ),
  );

  static const none = GhPresenceSpec();

  static final sidebarLabels = GhCascade(
    role: GhCascadeRole.label,
    from: const GhPose(opacity: 0, x: -10),
    duration: 0.4,
    ease: GhEase.out,
    at: 0.08,
    amountPerItem: 0.012,
    maxAmount: 0.2,
  );

  static final disclosureItems = GhCascade(
    role: GhCascadeRole.disclosure,
    from: const GhPose(opacity: 0, y: -6),
    duration: 0.32,
    ease: GhEase.out,
    amountPerItem: 0.012,
    maxAmount: 0.1,
    limit: 16,
  );

  static const imageFrom = GhPose(opacity: 0, scale: 1.06, blur: 8);

  static const imageSeconds = 0.7;
}

abstract class GhPresenceClock implements Listenable {
  bool get exiting;

  double get time;

  double get enteredAt;
}

class GhCascadeRegistry {
  int _generation = 0;
  int _count = 0;

  int get generation => _generation;

  int get count => _count;

  int register() => _count++;

  void reset() {
    _generation++;
    _count = 0;
  }
}

class GhPresenceScope extends InheritedWidget {
  const GhPresenceScope({super.key, required this.clock, required this.spec, required this.registry, this.parent, required super.child});

  final GhPresenceClock clock;
  final GhPresenceSpec spec;
  final GhCascadeRegistry registry;
  final GhPresenceScope? parent;

  static GhPresenceScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GhPresenceScope>();

  GhPresenceScope? forRole(GhCascadeRole role) {
    GhPresenceScope? scope = this;
    while (scope != null) {
      if (scope.spec.cascade?.role == role) {
        return scope;
      }
      scope = scope.parent;
    }
    return null;
  }

  @override
  bool updateShouldNotify(GhPresenceScope oldWidget) =>
      clock != oldWidget.clock || spec != oldWidget.spec || registry != oldWidget.registry || parent != oldWidget.parent;
}

typedef GhPresenceFrameBuilder = Widget Function(BuildContext context, GhPresenceClock clock, Widget child);

class GhPresence extends StatefulWidget {
  const GhPresence({
    super.key,
    required this.visible,
    required this.child,
    this.kind = GhPresenceKind.none,
    this.spec,
    this.up = false,
    this.origin = Alignment.center,
    this.appear = true,
    this.replay,
    this.resetOnReplay = true,
    this.onExited,
    this.frame,
  });

  final bool visible;
  final Widget child;
  final GhPresenceKind kind;
  final GhPresenceSpec? spec;
  final bool up;
  final AlignmentGeometry origin;
  final bool appear;
  final Object? replay;
  final bool resetOnReplay;
  final VoidCallback? onExited;
  final GhPresenceFrameBuilder? frame;

  GhPresenceSpec get resolvedSpec => spec ?? GhPresenceSpec.of(kind, up: up);

  @override
  State<GhPresence> createState() => _GhPresenceState();
}

class _GhPresenceState extends State<GhPresence> with SingleTickerProviderStateMixin implements GhPresenceClock {
  late final AnimationController _controller = AnimationController(vsync: this, value: 1);
  final GhCascadeRegistry _registry = GhCascadeRegistry();
  late bool _shown = widget.visible;
  bool _exiting = false;
  bool _started = false;
  double _length = 0;
  double _enteredAt = 0;
  int _run = 0;

  @override
  bool get exiting => _exiting;

  @override
  double get time => _controller.value * _length;

  @override
  double get enteredAt => _exiting ? _enteredAt : time;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _controller.removeListener(listener);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (!widget.visible) {
      return;
    }
    if (widget.appear) {
      _enter();
    } else {
      _length = widget.resolvedSpec.enterLength;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(GhPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _enter();
      } else {
        _exit();
      }
      return;
    }
    if (widget.visible && widget.replay != oldWidget.replay) {
      if (widget.resetOnReplay) {
        _registry.reset();
      }
      _enter();
    }
  }

  void _enter() {
    final spec = widget.resolvedSpec;
    final motion = GhMotion.of(context);
    _run++;
    _exiting = false;
    _shown = true;
    _length = spec.enterLength;
    if (_length <= 0 || (motion.off && !spec.enterWhenOff)) {
      _controller.value = 1;
      return;
    }
    _controller.duration = motion.gsap(_length);
    _controller.forward(from: 0);
  }

  void _exit() {
    if (!_shown) {
      return;
    }
    final spec = widget.resolvedSpec;
    final motion = GhMotion.of(context);
    if (!_exiting) {
      _enteredAt = time;
    }
    _exiting = true;
    final run = ++_run;
    _length = spec.exitLength;
    if (_length <= 0 || (motion.off && !spec.exitWhenOff)) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(run));
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    _controller.duration = motion.gsap(_length);
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (_controller.isCompleted) {
        _finish(run);
      }
    });
  }

  void _finish(int run) {
    if (!mounted || run != _run || !_exiting) {
      return;
    }
    setState(() {
      _shown = false;
      _exiting = false;
    });
    _registry.reset();
    widget.onExited?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = GhPresenceScope.maybeOf(context);
    if (!_shown) {
      return const SizedBox.shrink();
    }
    final spec = widget.resolvedSpec;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    Widget result = AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) =>
          GhPoseView(allowBlur: spec.layer.blurs, pose: spec.layer.poseAt(this).mirrored(rtl), origin: widget.origin, child: child!),
    );
    result = IgnorePointer(
      ignoring: _exiting,
      child: ExcludeFocus(
        excluding: _exiting,
        child: ExcludeSemantics(excluding: _exiting, child: result),
      ),
    );
    final frame = widget.frame;
    if (frame != null) {
      result = frame(context, this, result);
    }
    return GhPresenceScope(clock: this, spec: spec, registry: _registry, parent: parent, child: result);
  }
}

class GhCascadeHost extends StatelessWidget {
  const GhCascadeHost({
    super.key,
    required this.cascade,
    required this.child,
    this.replay,
    this.resetOnReplay = true,
    this.runWhenOff = true,
  });

  final GhCascade cascade;
  final Widget child;
  final Object? replay;
  final bool resetOnReplay;
  final bool runWhenOff;

  @override
  Widget build(BuildContext context) {
    return GhPresence(
      visible: true,
      appear: false,
      replay: replay,
      resetOnReplay: resetOnReplay,
      spec: GhPresenceSpec(cascade: cascade, enterWhenOff: runWhenOff),
      child: child,
    );
  }
}

class GhPresenceLayerView extends StatelessWidget {
  const GhPresenceLayerView({super.key, required this.layer, required this.child, this.origin = Alignment.center});

  final GhPresenceLayer layer;
  final Widget child;
  final AlignmentGeometry origin;

  @override
  Widget build(BuildContext context) {
    final clock = GhPresenceScope.maybeOf(context)?.clock;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return ListenableBuilder(
      listenable: clock ?? kAlwaysCompleteAnimation,
      child: child,
      builder: (context, child) => GhPoseView(
        allowBlur: layer.blurs,
        pose: clock == null ? GhPose.identity : layer.poseAt(clock).mirrored(rtl),
        origin: origin,
        child: child!,
      ),
    );
  }
}

class GhPresenceBuilder extends StatelessWidget {
  const GhPresenceBuilder({super.key, required this.builder, this.child});

  final Widget Function(BuildContext context, GhPresenceClock? clock, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final clock = GhPresenceScope.maybeOf(context)?.clock;
    return ListenableBuilder(
      listenable: clock ?? kAlwaysCompleteAnimation,
      child: child,
      builder: (context, child) => builder(context, clock, child),
    );
  }
}

class GhCascadeItem extends StatefulWidget {
  const GhCascadeItem({super.key, this.role = GhCascadeRole.part, required this.child});

  final GhCascadeRole role;
  final Widget child;

  @override
  State<GhCascadeItem> createState() => _GhCascadeItemState();
}

class _GhCascadeItemState extends State<GhCascadeItem> {
  GhPresenceScope? _scope;
  GhCascadeRegistry? _registry;
  int _generation = -1;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind();
  }

  @override
  void didUpdateWidget(GhCascadeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _bind();
    }
  }

  void _bind() {
    final scope = GhPresenceScope.maybeOf(context)?.forRole(widget.role);
    _scope = scope;
    final registry = scope?.registry;
    if (registry != null && !identical(registry, _registry)) {
      _registry = registry;
      _generation = registry.generation;
      _index = registry.register();
    }
  }

  GhPose _pose(bool rtl) {
    final scope = _scope;
    final registry = _registry;
    final cascade = scope?.spec.cascade;
    if (scope == null || registry == null || cascade == null || registry.generation != _generation) {
      return GhPose.identity;
    }
    final clock = scope.clock;
    return cascade.poseAt(_index, registry.count, clock.exiting ? clock.enteredAt : clock.time).mirrored(rtl);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return ListenableBuilder(
      listenable: _scope?.clock ?? kAlwaysCompleteAnimation,
      child: widget.child,
      builder: (context, child) => GhPoseView(allowBlur: false, pose: _pose(rtl), child: child!),
    );
  }
}

Widget ghFadeInFrameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) =>
    GhImageFadeIn(frame: frame, cached: wasSynchronouslyLoaded, child: child);

class GhImageFadeIn extends StatefulWidget {
  const GhImageFadeIn({super.key, required this.frame, required this.cached, required this.child});

  final int? frame;
  final bool cached;
  final Widget child;

  @override
  State<GhImageFadeIn> createState() => _GhImageFadeInState();
}

class _GhImageFadeInState extends State<GhImageFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: 1);
  bool _waiting = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _waiting = !widget.cached && widget.frame == null && !GhMotion.of(context).off;
  }

  @override
  void didUpdateWidget(GhImageFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_waiting || widget.frame == null) {
      return;
    }
    _waiting = false;
    final motion = GhMotion.of(context);
    if (motion.off) {
      _controller.value = 1;
      return;
    }
    _controller.duration = motion.gsap(GhPresenceSpecs.imageSeconds);
    _controller.forward(from: 0);
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
        final pose = _waiting
            ? const GhPose(opacity: 0)
            : GhPose.lerp(GhPresenceSpecs.imageFrom, GhPose.identity, GhEase.out.transform(_controller.value));
        return GhPoseView(pose: pose, child: child!);
      },
    );
  }
}

class GhFadeInImage extends StatelessWidget {
  const GhFadeInImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.filterQuality = FilterQuality.medium,
    this.errorBuilder,
  });

  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder,
      frameBuilder: ghFadeInFrameBuilder,
    );
  }
}
