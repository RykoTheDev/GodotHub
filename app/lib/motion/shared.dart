import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'ease.dart';
import 'motion.dart';
import 'tween.dart';

abstract final class GhSharedElements {
  static const seconds = 0.6;
  static const iconDelay = 0.12;
  static const iconSeconds = 0.9;
  static const iconFrom = GhPose(scale: 0.6, rotation: -20);

  static final Map<Object, Rect> _rects = {};
  static final Map<Object, _GhSharedState> _live = {};
  static final Map<Object, ValueNotifier<int>> _flips = {};
  static bool _installed = false;

  static void _install() {
    if (_installed) {
      return;
    }
    _installed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(_MetricsObserver());
  }

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      measure();
    }
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      measure();
    }
    return false;
  }

  static void measure() {
    for (final entry in _live.entries.toList()) {
      final rect = entry.value._measure();
      if (rect != null) {
        _rects[entry.key] = rect;
      }
    }
  }

  static Rect? rectOf(Object tag) => _rects[tag];

  static void forget(Object tag) {
    _rects.remove(tag);
    _flips.remove(tag)?.dispose();
  }

  static ValueListenable<int> flipsOf(Object tag) => _flips.putIfAbsent(tag, () => ValueNotifier<int>(0));

  static void _flip(Object tag) {
    final notifier = _flips.putIfAbsent(tag, () => ValueNotifier<int>(0));
    notifier.value += 1;
  }

  @visibleForTesting
  static void debugReset() {
    _rects.clear();
    _live.clear();
  }
}

class _MetricsObserver with WidgetsBindingObserver {
  bool _pending = false;

  @override
  void didChangeMetrics() {
    if (_pending) {
      return;
    }
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      GhSharedElements.measure();
    });
  }
}

class GhShared extends StatefulWidget {
  const GhShared({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  @override
  State<GhShared> createState() => _GhSharedState();
}

class _GhSharedState extends State<GhShared> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: 1);
  _RenderShared? _box;
  GhMotionData _motion = const GhMotionData();

  @override
  void initState() {
    super.initState();
    GhSharedElements._install();
    GhSharedElements._live[widget.tag] = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = GhMotion.of(context);
  }

  @override
  void didUpdateWidget(GhShared oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      if (identical(GhSharedElements._live[oldWidget.tag], this)) {
        GhSharedElements._live.remove(oldWidget.tag);
      }
      GhSharedElements._live[widget.tag] = this;
    }
  }

  @override
  void dispose() {
    if (identical(GhSharedElements._live[widget.tag], this)) {
      GhSharedElements._live.remove(widget.tag);
    }
    _controller.dispose();
    super.dispose();
  }

  double get _progress => GhEase.out.transform(_controller.value.clamp(0.0, 1.0));

  Rect? _measure() {
    final box = _box;
    if (box == null || !box.attached || !box.hasSize) {
      return null;
    }
    final matrix = box.getTransformTo(null);
    final own = box._matrix();
    if (own != null) {
      matrix.multiply(own);
    }
    return MatrixUtils.transformRect(matrix, Offset.zero & box.size);
  }

  void _firstPaint(_RenderShared box) {
    final global = box.getTransformTo(null);
    final rect = MatrixUtils.transformRect(global, Offset.zero & box.size);
    final previous = GhSharedElements._rects[widget.tag];
    GhSharedElements._rects[widget.tag] = rect;
    if (previous == null || _motion.off || rect.isEmpty || previous.isEmpty) {
      return;
    }
    final inverse = Matrix4.tryInvert(global);
    if (inverse == null) {
      return;
    }
    final local = MatrixUtils.transformRect(inverse, previous);
    if (local.left.abs() < 1 && local.top.abs() < 1) {
      return;
    }
    box._from = local;
    box._waiting = true;
    final tag = widget.tag;
    scheduleMicrotask(() {
      if (!mounted) {
        return;
      }
      box._waiting = false;
      _controller.duration = _motion.gsap(GhSharedElements.seconds);
      _controller.forward(from: 0);
      GhSharedElements._flip(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SharedBox(state: this, progress: _controller, child: widget.child);
  }
}

class _SharedBox extends SingleChildRenderObjectWidget {
  const _SharedBox({required this.state, required this.progress, super.child});

  final _GhSharedState state;
  final Animation<double> progress;

  @override
  _RenderShared createRenderObject(BuildContext context) => _RenderShared(state, progress);

  @override
  void updateRenderObject(BuildContext context, _RenderShared renderObject) {
    renderObject.progress = progress;
  }
}

class _RenderShared extends RenderProxyBox {
  _RenderShared(this._state, this._progress) {
    _state._box = this;
  }

  final _GhSharedState _state;
  Animation<double> _progress;
  bool _pending = true;
  bool _waiting = false;
  Rect? _from;

  set progress(Animation<double> value) {
    if (identical(value, _progress)) {
      return;
    }
    if (attached) {
      _progress.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _progress = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  Matrix4? _matrix() {
    final from = _from;
    if (from == null || !hasSize || size.isEmpty) {
      return null;
    }
    final t = _waiting ? 0.0 : _state._progress;
    if (t >= 1) {
      return null;
    }
    final inv = 1 - t;
    final sx = from.width / size.width;
    final sy = from.height / size.height;
    return Matrix4.identity()
      ..translateByDouble(from.left * inv, from.top * inv, 0, 1)
      ..scaleByDouble(sx + (1 - sx) * t, sy + (1 - sy) * t, 1, 1);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final matrix = _matrix();
    if (matrix != null) {
      transform.multiply(matrix);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final matrix = _matrix();
    if (matrix == null) {
      return super.hitTestChildren(result, position: position);
    }
    return result.addWithPaintTransform(
      transform: matrix,
      position: position,
      hitTest: (result, position) => super.hitTestChildren(result, position: position),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_pending) {
      _pending = false;
      _state._firstPaint(this);
    }
    final matrix = _matrix();
    if (matrix == null) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      matrix,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer : null,
    );
  }
}

class GhSharedIcon extends StatefulWidget {
  const GhSharedIcon({super.key, required this.tag, required this.child, this.enabled = true});

  final Object tag;
  final Widget child;
  final bool enabled;

  @override
  State<GhSharedIcon> createState() => _GhSharedIconState();
}

class _GhSharedIconState extends State<GhSharedIcon> with SingleTickerProviderStateMixin {
  late final GhTimeline _timeline = GhTimeline(vsync: this);
  late final Animation<double> _track = _timeline.add(
    GhTrack(start: GhSharedElements.iconDelay, duration: GhSharedElements.iconSeconds, ease: GhEase.elastic),
  );
  ValueListenable<int>? _flips;
  GhMotionData _motion = const GhMotionData();

  @override
  void initState() {
    super.initState();
    _timeline.finish();
    _listen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = GhMotion.of(context);
  }

  @override
  void didUpdateWidget(GhSharedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      _flips?.removeListener(_onFlip);
      _listen();
    }
  }

  void _listen() {
    _flips = GhSharedElements.flipsOf(widget.tag)..addListener(_onFlip);
  }

  void _onFlip() {
    if (!mounted || !widget.enabled) {
      return;
    }
    if (_motion.off) {
      return;
    }
    _timeline.play(_motion);
  }

  @override
  void dispose() {
    _flips?.removeListener(_onFlip);
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _track,
      child: widget.child,
      builder: (context, child) =>
          GhPoseView(allowBlur: false, pose: GhPose.lerp(GhSharedElements.iconFrom, GhPose.identity, _track.value), child: child!),
    );
  }
}
