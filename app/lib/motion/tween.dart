import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'ease.dart';
import 'motion.dart';

@immutable
class GhPose {
  const GhPose({
    this.opacity = 1,
    this.x = 0,
    this.y = 0,
    this.xPercent = 0,
    this.yPercent = 0,
    this.scale = 1,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotation = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.blur = 0,
    this.clipBottom = 0,
  });

  static const identity = GhPose();

  final double opacity;
  final double x;
  final double y;
  final double xPercent;
  final double yPercent;
  final double scale;
  final double scaleX;
  final double scaleY;
  final double rotation;
  final double rotationX;
  final double rotationY;
  final double blur;
  final double clipBottom;

  bool get isIdentity => this == identity;

  GhPose copyWith({
    double? opacity,
    double? x,
    double? y,
    double? xPercent,
    double? yPercent,
    double? scale,
    double? scaleX,
    double? scaleY,
    double? rotation,
    double? rotationX,
    double? rotationY,
    double? blur,
    double? clipBottom,
  }) {
    return GhPose(
      opacity: opacity ?? this.opacity,
      x: x ?? this.x,
      y: y ?? this.y,
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
      scale: scale ?? this.scale,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      blur: blur ?? this.blur,
      clipBottom: clipBottom ?? this.clipBottom,
    );
  }

  static GhPose lerp(GhPose a, GhPose b, double t) {
    double l(double from, double to) => from + (to - from) * t;
    return GhPose(
      opacity: l(a.opacity, b.opacity),
      x: l(a.x, b.x),
      y: l(a.y, b.y),
      xPercent: l(a.xPercent, b.xPercent),
      yPercent: l(a.yPercent, b.yPercent),
      scale: l(a.scale, b.scale),
      scaleX: l(a.scaleX, b.scaleX),
      scaleY: l(a.scaleY, b.scaleY),
      rotation: l(a.rotation, b.rotation),
      rotationX: l(a.rotationX, b.rotationX),
      rotationY: l(a.rotationY, b.rotationY),
      blur: l(a.blur, b.blur),
      clipBottom: l(a.clipBottom, b.clipBottom),
    );
  }

  GhPose mirrored(bool rtl) => rtl ? copyWith(x: -x, xPercent: -xPercent, rotation: -rotation, rotationY: -rotationY) : this;

  @override
  bool operator ==(Object other) =>
      other is GhPose &&
      other.opacity == opacity &&
      other.x == x &&
      other.y == y &&
      other.xPercent == xPercent &&
      other.yPercent == yPercent &&
      other.scale == scale &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY &&
      other.rotation == rotation &&
      other.rotationX == rotationX &&
      other.rotationY == rotationY &&
      other.blur == blur &&
      other.clipBottom == clipBottom;

  @override
  int get hashCode =>
      Object.hash(opacity, x, y, xPercent, yPercent, scale, scaleX, scaleY, rotation, rotationX, rotationY, blur, clipBottom);
}

Matrix4 ghPoseMatrix(GhPose pose, {double perspective = 0}) {
  final matrix = Matrix4.identity();
  if (perspective > 0) {
    matrix.setEntry(3, 2, -1 / perspective);
  }
  return matrix
    ..translateByDouble(pose.x, pose.y, 0, 1)
    ..rotateZ(pose.rotation * math.pi / 180)
    ..rotateY(pose.rotationY * math.pi / 180)
    ..rotateX(pose.rotationX * math.pi / 180)
    ..scaleByDouble(pose.scale * pose.scaleX, pose.scale * pose.scaleY, 1, 1);
}

class GhPoseView extends StatelessWidget {
  const GhPoseView({
    super.key,
    required this.pose,
    required this.child,
    this.origin = Alignment.center,
    this.perspective = 0,
    this.allowBlur = true,
  });

  final GhPose pose;
  final Widget child;
  final AlignmentGeometry origin;
  final double perspective;
  final bool allowBlur;

  @override
  Widget build(BuildContext context) {
    final clip = pose.clipBottom.clamp(0.0, 1.0);
    Widget result = ClipRect(clipper: _BottomInsetClipper(clip), clipBehavior: clip > 0 ? Clip.hardEdge : Clip.none, child: child);
    final blurOn = allowBlur && pose.blur > 0.01 && GhMotion.of(context).blur;
    result = ImageFiltered(
      enabled: blurOn,
      imageFilter: ui.ImageFilter.blur(sigmaX: blurOn ? pose.blur : 0, sigmaY: blurOn ? pose.blur : 0, tileMode: TileMode.decal),
      child: result,
    );
    result = Transform(
      transform: ghPoseMatrix(pose, perspective: perspective),
      alignment: origin,
      child: result,
    );
    result = FractionalTranslation(translation: Offset(pose.xPercent / 100, pose.yPercent / 100), child: result);
    return Opacity(opacity: pose.opacity.clamp(0.0, 1.0), child: result);
  }
}

class _BottomInsetClipper extends CustomClipper<Rect> {
  const _BottomInsetClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(-size.width, -size.height, size.width * 3, size.height * (2 - fraction));

  @override
  bool shouldReclip(_BottomInsetClipper oldClipper) => oldClipper.fraction != fraction;
}

class GhPoseTransition extends AnimatedWidget {
  const GhPoseTransition({
    super.key,
    required Animation<double> animation,
    required this.from,
    this.to = GhPose.identity,
    this.origin = Alignment.center,
    this.perspective = 0,
    required this.child,
  }) : super(listenable: animation);

  final GhPose from;
  final GhPose to;
  final Alignment origin;
  final double perspective;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return GhPoseView(pose: GhPose.lerp(from, to, t), origin: origin, perspective: perspective, child: child);
  }
}

@immutable
class GhTrack {
  const GhTrack({required this.start, required this.duration, required this.ease});

  final double start;
  final double duration;
  final Curve ease;

  double get end => start + duration;
}

class GhTimeline {
  GhTimeline({required TickerProvider vsync}) : controller = AnimationController(vsync: vsync);

  final AnimationController controller;
  final List<GhTrack> _tracks = [];
  double _length = 0;

  double get length => _length;

  Animation<double> add(GhTrack track) {
    _tracks.add(track);
    _length = math.max(_length, track.end);
    return _TrackAnimation(controller, this, track);
  }

  void clear() {
    _tracks.clear();
    _length = 0;
  }

  TickerFuture play(GhMotionData motion, {double from = 0}) {
    controller.duration = motion.gsap(_length <= 0 ? 0.0001 : _length);
    return controller.forward(from: from);
  }

  void finish() => controller.value = 1;

  void dispose() => controller.dispose();
}

class _TrackAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _TrackAnimation(this.parent, this.timeline, this.track);

  @override
  final Animation<double> parent;
  final GhTimeline timeline;
  final GhTrack track;

  @override
  double get value {
    final length = timeline.length;
    if (length <= 0) {
      return 1;
    }
    final time = parent.value * length;
    if (time <= track.start) {
      return 0;
    }
    if (time >= track.end || track.duration <= 0) {
      return 1;
    }
    return track.ease.transform(((time - track.start) / track.duration).clamp(0.0, 1.0));
  }
}

class GhTween extends StatefulWidget {
  const GhTween({
    super.key,
    required this.child,
    this.from = GhPose.identity,
    this.to = GhPose.identity,
    this.duration = 0.5,
    this.delay = 0,
    this.ease,
    this.origin = Alignment.center,
    this.perspective = 0,
    this.play = true,
    this.replay,
    this.runWhenOff = false,
    this.onComplete,
  });

  final Widget child;
  final GhPose from;
  final GhPose to;
  final double duration;
  final double delay;
  final Curve? ease;
  final Alignment origin;
  final double perspective;
  final bool play;
  final Object? replay;
  final bool runWhenOff;
  final VoidCallback? onComplete;

  @override
  State<GhTween> createState() => _GhTweenState();
}

class _GhTweenState extends State<GhTween> with SingleTickerProviderStateMixin {
  late final GhTimeline _timeline = GhTimeline(vsync: this);
  late Animation<double> _track;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _timeline.clear();
    _track = _timeline.add(GhTrack(start: widget.delay, duration: widget.duration, ease: widget.ease ?? GhEase.defaultEase));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.play) {
      _start();
    }
  }

  @override
  void didUpdateWidget(GhTween oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration || oldWidget.delay != widget.delay || oldWidget.ease != widget.ease) {
      _build();
    }
    if (widget.replay != oldWidget.replay || (widget.play && !oldWidget.play)) {
      _start();
    }
  }

  void _start() {
    _started = true;
    final motion = GhMotion.of(context);
    if (motion.off && !widget.runWhenOff) {
      _timeline.finish();
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete?.call());
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
    if (!_started && !widget.play) {
      return GhPoseView(pose: widget.from, origin: widget.origin, perspective: widget.perspective, child: widget.child);
    }
    return GhPoseTransition(
      animation: _track,
      from: widget.from,
      to: widget.to,
      origin: widget.origin,
      perspective: widget.perspective,
      child: widget.child,
    );
  }
}

class GhFrom extends StatelessWidget {
  const GhFrom({
    super.key,
    required this.from,
    required this.child,
    this.duration = 0.5,
    this.delay = 0,
    this.ease,
    this.origin = Alignment.center,
    this.perspective = 0,
    this.play = true,
    this.replay,
    this.runWhenOff = false,
    this.onComplete,
  });

  final GhPose from;
  final Widget child;
  final double duration;
  final double delay;
  final Curve? ease;
  final Alignment origin;
  final double perspective;
  final bool play;
  final Object? replay;
  final bool runWhenOff;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return GhTween(
      from: from,
      duration: duration,
      delay: delay,
      ease: ease,
      origin: origin,
      perspective: perspective,
      play: play,
      replay: replay,
      runWhenOff: runWhenOff,
      onComplete: onComplete,
      child: child,
    );
  }
}

abstract final class GhStagger {
  static double each(int index, double each) => index * each;

  static double amount(int index, int count, double amount) => ghStaggerAmount(index, count, amount);
}
