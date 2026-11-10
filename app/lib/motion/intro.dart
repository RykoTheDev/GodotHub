import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../src/ui_transition.dart';
import 'ease.dart';
import 'motion.dart';
import 'reveal.dart';
import 'tween.dart';

abstract final class GhShellIntroTiming {
  static const delay = 0.15;
  static const titleBar = GhIntroTrackSpec(start: 0, duration: 0.8, from: GhPose(y: -40, opacity: 0));
  static const part = GhIntroTrackSpec(start: 0.15, duration: 0.6, from: GhPose(y: -14, opacity: 0), each: 0.06);
  static const sidebar = GhIntroTrackSpec(start: 0.05, duration: 0.9, from: GhPose(x: -60, opacity: 0));
  static const item = GhIntroTrackSpec(start: 0.2, duration: 0.6, from: GhPose(x: -20, opacity: 0), each: 0.03);
  static const maxItems = 30;
}

@immutable
class GhIntroTrackSpec {
  const GhIntroTrackSpec({required this.start, required this.duration, required this.from, this.each = 0});

  final double start;
  final double duration;
  final GhPose from;
  final double each;

  double startAt(int index) => GhShellIntroTiming.delay + start + index * each;

  double endAt(int index) => startAt(index) + duration;
}

enum GhIntroRole { titleBar, part, sidebar, item }

class GhShellIntro extends StatefulWidget {
  const GhShellIntro({super.key, required this.child, this.enabled = true, this.replay, this.onDone});

  final Widget child;
  final bool enabled;
  final Object? replay;
  final VoidCallback? onDone;

  @override
  State<GhShellIntro> createState() => GhShellIntroState();
}

class GhShellIntroState extends State<GhShellIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  final Map<GhIntroRole, int> _counts = {for (final role in GhIntroRole.values) role: 0};
  bool _accepting = true;
  bool _started = false;
  bool _done = false;
  double _length = 1;

  bool get running => _controller.isAnimating;

  bool get done => _done;

  int count(GhIntroRole role) => _counts[role]!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final motion = GhMotion.of(context);
    final handedOff = GhUiTransition.consumeShellIntroHandOff();
    if (!widget.enabled || handedOff || motion.off) {
      _accepting = false;
      _controller.value = 1;
      _finish();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _play();
      }
    });
  }

  @override
  void didUpdateWidget(GhShellIntro oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replay != oldWidget.replay && widget.enabled) {
      if (GhMotion.of(context).off) {
        _controller.value = 1;
        _finish();
        return;
      }
      _done = false;
      _controller.value = 0;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _play();
        }
      });
    }
  }

  @override
  void dispose() {
    if (!_done) {
      _done = true;
      GhLiveReveal.enable();
    }
    _controller.dispose();
    super.dispose();
  }

  GhIntroTrackSpec _spec(GhIntroRole role) => switch (role) {
        GhIntroRole.titleBar => GhShellIntroTiming.titleBar,
        GhIntroRole.part => GhShellIntroTiming.part,
        GhIntroRole.sidebar => GhShellIntroTiming.sidebar,
        GhIntroRole.item => GhShellIntroTiming.item,
      };

  _GhIntroTrack? _register(GhIntroRole role) {
    if (!_accepting) {
      return null;
    }
    final index = _counts[role]!;
    if (role == GhIntroRole.item && index >= GhShellIntroTiming.maxItems) {
      return null;
    }
    _counts[role] = index + 1;
    return _GhIntroTrack(this, _spec(role), index);
  }

  double _computeLength() {
    var end = 0.0;
    for (final role in GhIntroRole.values) {
      final n = _counts[role]!;
      if (n > 0) {
        end = math.max(end, _spec(role).endAt(n - 1));
      }
    }
    return end;
  }

  void _play() {
    _accepting = false;
    final motion = GhMotion.of(context);
    if (motion.off) {
      _controller.value = 1;
      _finish();
      return;
    }
    _length = _computeLength();
    if (_length <= 0) {
      _controller.value = 1;
      _finish();
      return;
    }
    _controller.duration = motion.gsap(_length);
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (!_done && mounted) {
        _finish();
      }
    });
  }

  void _finish() {
    _done = true;
    GhLiveReveal.enable();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) => _GhIntroScope(state: this, child: widget.child);
}

class _GhIntroTrack extends Animation<double> with AnimationWithParentMixin<double> {
  _GhIntroTrack(this.intro, this.spec, this.index);

  final GhShellIntroState intro;
  final GhIntroTrackSpec spec;
  final int index;

  @override
  Animation<double> get parent => intro._controller;

  @override
  double get value {
    final t = parent.value;
    if (t >= 1) {
      return 1;
    }
    final time = t * intro._length;
    final start = spec.startAt(index);
    if (time <= start) {
      return 0;
    }
    final p = ((time - start) / spec.duration).clamp(0.0, 1.0);
    return GhEase.out.transform(p);
  }
}

class _GhIntroScope extends InheritedWidget {
  const _GhIntroScope({required this.state, required super.child});

  final GhShellIntroState state;

  @override
  bool updateShouldNotify(_GhIntroScope oldWidget) => state != oldWidget.state;
}

class _GhIntroRegion extends InheritedWidget {
  const _GhIntroRegion({required this.role, required super.child});

  final GhIntroRole role;

  @override
  bool updateShouldNotify(_GhIntroRegion oldWidget) => role != oldWidget.role;
}

class _GhIntroNode extends StatefulWidget {
  const _GhIntroNode({required this.role, required this.child, this.region});

  final GhIntroRole role;
  final GhIntroRole? region;
  final Widget child;

  @override
  State<_GhIntroNode> createState() => _GhIntroNodeState();
}

class _GhIntroNodeState extends State<_GhIntroNode> {
  final GlobalKey _childKey = GlobalKey();
  _GhIntroTrack? _track;
  bool _registered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registered) {
      return;
    }
    _registered = true;
    final scope = context.getInheritedWidgetOfExactType<_GhIntroScope>();
    if (scope == null) {
      return;
    }
    final required = switch (widget.role) {
      GhIntroRole.part => GhIntroRole.titleBar,
      GhIntroRole.item => GhIntroRole.sidebar,
      _ => null,
    };
    if (required != null && context.getInheritedWidgetOfExactType<_GhIntroRegion>()?.role != required) {
      return;
    }
    _track = scope.state._register(widget.role);
  }

  @override
  Widget build(BuildContext context) {
    final region = widget.region;
    var child = widget.child;
    if (region != null) {
      child = _GhIntroRegion(role: region, child: child);
    }
    final track = _track;
    if (track == null) {
      return child;
    }
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return GhPoseTransition(
      animation: track,
      from: track.spec.from.mirrored(rtl),
      child: KeyedSubtree(key: _childKey, child: child),
    );
  }
}

class GhIntroTitleBar extends StatelessWidget {
  const GhIntroTitleBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GhIntroNode(role: GhIntroRole.titleBar, region: GhIntroRole.titleBar, child: child);
}

class GhIntroPart extends StatelessWidget {
  const GhIntroPart({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GhIntroNode(role: GhIntroRole.part, child: child);
}

class GhIntroSidebar extends StatelessWidget {
  const GhIntroSidebar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GhIntroNode(role: GhIntroRole.sidebar, region: GhIntroRole.sidebar, child: child);
}

class GhIntroItem extends StatelessWidget {
  const GhIntroItem({super.key, required this.child});

  final Widget child;

  static bool participates(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GhIntroRegion>()?.role == GhIntroRole.sidebar;

  @override
  Widget build(BuildContext context) => _GhIntroNode(role: GhIntroRole.item, child: child);
}

const ghLetterFrom = GhPose(yPercent: 120, rotationX: -90, opacity: 0);

List<Animation<double>> ghStaggerTracks(
  GhTimeline timeline, {
  required int count,
  required double at,
  required double duration,
  required double each,
  Curve? ease,
}) {
  return [
    for (var i = 0; i < count; i++)
      timeline.add(GhTrack(start: at + i * each, duration: duration, ease: ease ?? GhEase.out)),
  ];
}

class GhLetterRow extends StatelessWidget {
  const GhLetterRow({
    super.key,
    required this.text,
    required this.style,
    required this.animations,
    this.perspective = 600,
    this.semanticLabel,
  });

  final String text;
  final TextStyle style;
  final List<Animation<double>> animations;
  final double perspective;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final letters = text.characters.toList();
    return Semantics(
      label: semanticLabel ?? text,
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < letters.length; i++)
            GhPoseTransition(
              animation: i < animations.length ? animations[i] : kAlwaysCompleteAnimation,
              from: ghLetterFrom,
              origin: Alignment.bottomCenter,
              perspective: perspective,
              child: Text(letters[i], style: style),
            ),
        ],
      ),
    );
  }
}

class GhLetterRise extends StatefulWidget {
  const GhLetterRise({
    super.key,
    required this.text,
    required this.style,
    this.duration = 0.9,
    this.stagger = 0.045,
    this.delay = 0,
    this.ease,
    this.perspective = 600,
    this.runWhenOff = false,
    this.replay,
    this.semanticLabel,
    this.onComplete,
  });

  final String text;
  final TextStyle style;
  final double duration;
  final double stagger;
  final double delay;
  final Curve? ease;
  final double perspective;
  final bool runWhenOff;
  final Object? replay;
  final String? semanticLabel;
  final VoidCallback? onComplete;

  @override
  State<GhLetterRise> createState() => _GhLetterRiseState();
}

class _GhLetterRiseState extends State<GhLetterRise> with SingleTickerProviderStateMixin {
  late final GhTimeline _timeline = GhTimeline(vsync: this);
  List<Animation<double>> _tracks = const [];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _run();
    }
  }

  @override
  void didUpdateWidget(GhLetterRise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replay != oldWidget.replay || widget.text != oldWidget.text) {
      _run();
    }
  }

  void _run() {
    _timeline.clear();
    _tracks = ghStaggerTracks(
      _timeline,
      count: widget.text.characters.length,
      at: widget.delay,
      duration: widget.duration,
      each: widget.stagger,
      ease: widget.ease,
    );
    final motion = GhMotion.of(context);
    if (motion.off && !widget.runWhenOff) {
      _timeline.finish();
      return;
    }
    _timeline.play(motion).whenCompleteOrCancel(() {
      if (mounted && _timeline.controller.isCompleted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GhLetterRow(
      text: widget.text,
      style: widget.style,
      animations: _tracks,
      perspective: widget.perspective,
      semanticLabel: widget.semanticLabel,
    );
  }
}

abstract final class GhRingPulseTiming {
  static const growth = 14.0;
  static const duration = 2.4;
  static const each = 1.2;
  static const fromOpacity = 0.75;
  static final ease = GsapEase('power2.out');
}

class GhRingPulse extends StatefulWidget {
  const GhRingPulse({
    super.key,
    required this.child,
    required this.color,
    this.radius = 0,
    this.rings = 2,
    this.width = 2,
    this.running = true,
  });

  final Widget child;
  final Color color;
  final double radius;
  final int rings;
  final double width;
  final bool running;

  @override
  State<GhRingPulse> createState() => _GhRingPulseState();
}

class _GhRingPulseState extends State<GhRingPulse> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(-1);
  double _timeScale = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeScale = GhMotion.of(context).timeScale;
    _sync();
  }

  @override
  void didUpdateWidget(GhRingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.running && !GhMotion.of(context).off;
    if (run && !_ticker.isActive) {
      _time.value = 0;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      _time.value = -1;
    } else if (!run) {
      _time.value = -1;
    }
  }

  void _tick(Duration elapsed) {
    _time.value = elapsed.inMicroseconds / 1e6 * _timeScale;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(
        time: _time,
        rings: widget.rings,
        color: widget.color,
        radius: widget.radius,
        width: widget.width,
      ),
      child: widget.child,
    );
  }
}

@immutable
class GhRingFrame {
  const GhRingFrame({required this.inset, required this.radius, required this.opacity});

  final double inset;
  final double radius;
  final double opacity;
}

GhRingFrame? ghRingFrame(double time, int ring, double radius) {
  if (time < 0) {
    return null;
  }
  final local = time - ring * GhRingPulseTiming.each;
  final double p;
  if (local < 0) {
    p = 0;
  } else {
    final cycle = local % GhRingPulseTiming.duration;
    p = GhRingPulseTiming.ease.transform(cycle / GhRingPulseTiming.duration);
  }
  return GhRingFrame(
    inset: -GhRingPulseTiming.growth * p,
    radius: radius + GhRingPulseTiming.growth * p,
    opacity: GhRingPulseTiming.fromOpacity * (1 - p),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.time, required this.rings, required this.color, required this.radius, required this.width})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final int rings;
  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < rings; i++) {
      final frame = ghRingFrame(time.value, i, radius);
      if (frame == null || frame.opacity <= 0) {
        continue;
      }
      final rect = (Offset.zero & size).inflate(-frame.inset).deflate(width / 2);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(math.max(0, frame.radius - width / 2)));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color.withValues(alpha: color.a * frame.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.rings != rings ||
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.width != width;
}

abstract final class GhMagnetTiming {
  static const margin = 28.0;
  static const pull = 0.3;
  static const duration = 0.7;
  static final ease = GsapEase('power3.out');
}

Offset ghMagnetTarget(Rect anchor, Offset pointer, {double margin = GhMagnetTiming.margin, double pull = GhMagnetTiming.pull}) {
  final dx = pointer.dx - anchor.center.dx;
  final dy = pointer.dy - anchor.center.dy;
  if (dx.abs() > anchor.width / 2 + margin || dy.abs() > anchor.height / 2 + margin) {
    return Offset.zero;
  }
  return Offset(dx * pull, dy * pull);
}

class GhMagneticArea extends StatefulWidget {
  const GhMagneticArea({super.key, required this.child});

  final Widget child;

  @override
  State<GhMagneticArea> createState() => _GhMagneticAreaState();
}

class _GhMagneticAreaState extends State<GhMagneticArea> {
  final ValueNotifier<Offset?> _pointer = ValueNotifier(null);

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onExit: (_) => _pointer.value = null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (event) => _pointer.value = event.position,
        onPointerMove: (event) => _pointer.value = event.position,
        child: _GhMagnetScope(pointer: _pointer, child: widget.child),
      ),
    );
  }
}

class _GhMagnetScope extends InheritedWidget {
  const _GhMagnetScope({required this.pointer, required super.child});

  final ValueNotifier<Offset?> pointer;

  @override
  bool updateShouldNotify(_GhMagnetScope oldWidget) => pointer != oldWidget.pointer;
}

class GhMagnet extends StatefulWidget {
  const GhMagnet({
    super.key,
    required this.child,
    this.enabled = true,
    this.margin = GhMagnetTiming.margin,
    this.pull = GhMagnetTiming.pull,
  });

  final Widget child;
  final bool enabled;
  final double margin;
  final double pull;

  @override
  State<GhMagnet> createState() => _GhMagnetState();
}

class _GhMagnetState extends State<GhMagnet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)..addListener(_onTick);
  final ValueNotifier<Offset> _offset = ValueNotifier(Offset.zero);
  ValueNotifier<Offset?>? _pointer;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pointer = context.dependOnInheritedWidgetOfExactType<_GhMagnetScope>()?.pointer;
    if (pointer != _pointer) {
      _pointer?.removeListener(_onPointer);
      _pointer = pointer;
      _pointer?.addListener(_onPointer);
    }
  }

  @override
  void dispose() {
    _pointer?.removeListener(_onPointer);
    _controller.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onTick() {
    _offset.value = Offset.lerp(_from, _to, GhMagnetTiming.ease.transform(_controller.value))!;
  }

  void _quickTo(Offset target) {
    if (target == _to) {
      return;
    }
    _from = _offset.value;
    _to = target;
    _controller.duration = GhMotion.of(context).gsap(GhMagnetTiming.duration);
    _controller.forward(from: 0);
  }

  void _onPointer() {
    if (!widget.enabled || GhMotion.of(context).off) {
      return;
    }
    final pointer = _pointer?.value;
    final box = context.findRenderObject();
    if (pointer == null || box is! RenderBox || !box.hasSize) {
      _quickTo(Offset.zero);
      return;
    }
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _quickTo(ghMagnetTarget(anchor, pointer, margin: widget.margin, pull: widget.pull));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: _offset,
      child: widget.child,
      builder: (context, offset, child) => Transform.translate(offset: offset, child: child),
    );
  }
}

abstract final class GhWelcomeIntroPoses {
  static const grid = GhPose(opacity: 0);
  static const eyebrow = GhPose(opacity: 0, y: 14);
  static const letter = ghLetterFrom;
  static const line = GhPose(scaleX: 0, opacity: 0);
  static const desc = GhPose(opacity: 0, y: 16);
  static const cta = GhPose(opacity: 0, scale: 0.85, y: 12);
}

class GhWelcomeIntroTimeline {
  GhWelcomeIntroTimeline({required TickerProvider vsync, required int letters}) : timeline = GhTimeline(vsync: vsync) {
    grid = timeline.add(GhTrack(start: 0, duration: 1.4, ease: GhEase.out));
    eyebrow = timeline.add(GhTrack(start: 0.25, duration: 0.7, ease: GhEase.out));
    this.letters = ghStaggerTracks(timeline, count: letters, at: 0.4, duration: 1, each: 0.05);
    line = timeline.add(GhTrack(start: 0.85, duration: 0.9, ease: GhEase.out));
    desc = timeline.add(GhTrack(start: 1, duration: 0.8, ease: GhEase.out));
    cta = timeline.add(GhTrack(start: 1.25, duration: 0.7, ease: GhEase.spring));
  }

  final GhTimeline timeline;
  late final Animation<double> grid;
  late final Animation<double> eyebrow;
  late final List<Animation<double>> letters;
  late final Animation<double> line;
  late final Animation<double> desc;
  late final Animation<double> cta;

  double get ringsAt => timeline.length;

  Future<void> play(GhMotionData motion) {
    if (motion.off) {
      timeline.finish();
      return Future.value();
    }
    final completer = Completer<void>();
    timeline.play(motion).whenCompleteOrCancel(completer.complete);
    return completer.future;
  }

  void dispose() => timeline.dispose();
}
