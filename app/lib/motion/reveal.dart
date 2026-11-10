import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'ease.dart';
import 'motion.dart';
import 'tween.dart';

const ghRevealMaxBatch = 120;
const ghRevealBlurLimit = 24;
const ghRevealDuration = 0.75;
const ghRevealPaneFade = 0.4;
const ghRevealViewDelay = 0.05;

double ghRevealDelay(int index, {double base = 0}) => base + math.min(index * 0.035, 0.8);

double ghScrollRevealDelay(int index) => math.min(index * 0.06, 0.5);

abstract final class GhLiveReveal {
  static final ValueNotifier<bool> _live = ValueNotifier(false);
  static final Set<int> _held = {};
  static bool _tracking = false;

  static ValueListenable<bool> get listenable => _live;

  static bool get live => _live.value;

  static void enable() => _live.value = true;

  static bool get pointerHeld => _held.isNotEmpty;

  static void ensurePointerTracking() {
    if (_tracking) {
      return;
    }
    _tracking = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_route);
  }

  static void _route(PointerEvent event) {
    if (event is PointerDownEvent) {
      _held.add(event.pointer);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _held.remove(event.pointer);
    }
  }

  @visibleForTesting
  static void reset() {
    _live.value = false;
    _held.clear();
  }
}

enum GhRevealKind { standard, tile, heading, fade }

@immutable
class GhRevealSpec {
  const GhRevealSpec({required this.from, required this.duration, required this.ease});

  final GhPose from;
  final double duration;
  final Curve ease;
}

GhRevealSpec ghRevealSpec({
  GhRevealKind kind = GhRevealKind.standard,
  GhViewEntrance entrance = GhViewEntrance.slide,
  bool fromScroll = false,
  bool blur = true,
  bool blurAllowed = true,
  bool ownOpacity = false,
  bool canTransform = true,
}) {
  var from = GhPose(opacity: ownOpacity ? 1 : 0);
  var duration = ghRevealDuration;
  Curve ease = GhEase.out;
  if (canTransform && kind != GhRevealKind.fade && entrance != GhViewEntrance.fade) {
    switch (kind) {
      case GhRevealKind.tile:
        from = from.copyWith(scale: 0.3, rotation: -16);
        ease = GhEase.pop;
        duration = 0.85;
      case GhRevealKind.heading:
        from = entrance == GhViewEntrance.slide ? from.copyWith(y: 20, clipBottom: 1) : from.copyWith(scale: 0.96);
      case GhRevealKind.standard || GhRevealKind.fade:
        if (entrance == GhViewEntrance.scale) {
          from = from.copyWith(scale: 0.92);
          ease = GhEase.spring;
        } else {
          from = from.copyWith(y: fromScroll ? 40 : 26, scale: 0.96, blur: blur && blurAllowed ? 4 : 0);
        }
    }
  }
  return GhRevealSpec(from: from, duration: duration, ease: ease);
}

class GhRevealProject extends InheritedWidget {
  const GhRevealProject({super.key, required this.id, required super.child});

  final Object id;

  static Object? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GhRevealProject>()?.id;

  @override
  bool updateShouldNotify(GhRevealProject oldWidget) => id != oldWidget.id;
}

class GhRevealSkip extends StatelessWidget {
  const GhRevealSkip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GhRevealScopeMarker(state: null, child: child);
}

class GhRevealScope extends StatefulWidget {
  const GhRevealScope({super.key, required this.child, this.active = true, this.replay, this.fadePane = true});

  final Widget child;
  final bool active;
  final Object? replay;
  final bool fadePane;

  static GhRevealScopeState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GhRevealScopeMarker>()?.state;

  static void flushAll() {
    for (final scope in GhRevealScopeState._scopes.toList()) {
      scope.flushPending();
    }
  }

  @override
  State<GhRevealScope> createState() => GhRevealScopeState();
}

class GhRevealScopeState extends State<GhRevealScope> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final Set<GhRevealScopeState> _scopes = {};

  late final AnimationController _pane = AnimationController(vsync: this, value: 1);
  late final Animation<double> _paneOpacity = CurvedAnimation(parent: _pane, curve: GhEase.soft);
  final List<_GhRevealState> _items = [];
  final List<_GhRevealState> _fresh = [];
  final Set<_GhRevealState> _pending = {};
  final Set<Object> _seen = {};
  GhMotionData _motion = const GhMotionData();
  bool _hasMotion = false;
  bool _viewQueued = false;
  bool _processScheduled = false;
  bool _checkScheduled = false;

  int get pendingCount => _pending.length;

  bool get paneFading => _pane.isAnimating;

  @override
  void initState() {
    super.initState();
    _scopes.add(this);
    GhLiveReveal.ensurePointerTracking();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GhMotion.of(context);
    final first = !_hasMotion;
    _motion = next;
    _hasMotion = true;
    if (first) {
      if (widget.active) {
        _requestView();
      }
      return;
    }
    final prefs = next.prefs;
    if (!prefs.scrollReveal || prefs.entrance == GhViewEntrance.none || prefs.intensity == GhMotionIntensity.none) {
      flushPending();
    }
  }

  @override
  void didUpdateWidget(GhRevealScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && (!oldWidget.active || widget.replay != oldWidget.replay)) {
      _requestView();
    }
  }

  @override
  void didChangeMetrics() {
    if (_pending.isNotEmpty) {
      _scheduleCheck();
    }
  }

  @override
  void dispose() {
    _scopes.remove(this);
    WidgetsBinding.instance.removeObserver(this);
    _pane.dispose();
    super.dispose();
  }

  void replay() => _requestView();

  void _requestView() {
    if (!_motion.entranceOn || _pane.isAnimating) {
      return;
    }
    _viewQueued = true;
    if (widget.fadePane) {
      _pane.value = 0;
    }
    _scheduleProcess();
  }

  bool _register(_GhRevealState item) {
    _items.add(item);
    final identity = item.identity;
    if (_seen.contains(identity) && !_viewQueued) {
      return false;
    }
    _fresh.add(item);
    _scheduleProcess();
    if (!_motion.entranceOn || item.widget.ownOpacity) {
      return false;
    }
    return _viewQueued || (GhLiveReveal.live && !GhLiveReveal.pointerHeld);
  }

  void _unregister(_GhRevealState item) {
    _items.remove(item);
    _fresh.remove(item);
    _pending.remove(item);
  }

  void _scheduleProcess() {
    if (_processScheduled) {
      return;
    }
    _processScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _processScheduled = false;
      if (mounted) {
        _process();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _process() {
    if (_viewQueued) {
      _viewQueued = false;
      _fresh.clear();
      final batch = _items.toList();
      _seen
        ..clear()
        ..addAll(batch.map((item) => item.identity));
      if (!_motion.entranceOn) {
        _pane.value = 1;
        _showAll(batch);
        return;
      }
      if (widget.fadePane) {
        _pane.duration = _motion.gsap(ghRevealPaneFade);
        _pane.forward(from: 0);
      }
      _animateIn(batch, baseDelay: ghRevealViewDelay);
      return;
    }
    if (_fresh.isEmpty) {
      return;
    }
    final batch = _fresh.toList();
    _fresh.clear();
    _seen.addAll(batch.map((item) => item.identity));
    if (GhLiveReveal.live && !GhLiveReveal.pointerHeld) {
      _animateIn(batch);
    } else {
      _showAll(batch);
    }
  }

  void _showAll(Iterable<_GhRevealState> items) {
    for (final item in items) {
      if (!_pending.contains(item) && !item.playing) {
        item._show();
      }
    }
  }

  void _animateIn(List<_GhRevealState> elements, {double baseDelay = 0}) {
    final motion = _motion;
    if (!motion.entranceOn) {
      _showAll(elements);
      return;
    }
    var list = elements;
    final projects = {for (final item in list) ?item.projectId};
    if (projects.length > motion.prefs.threshold) {
      for (final item in list) {
        item.thresholdSkipped = item.projectId != null;
      }
      _showAll(list.where((item) => item.projectId != null));
      list = list.where((item) => item.projectId == null).toList();
    } else {
      for (final item in list) {
        item.thresholdSkipped = false;
      }
    }
    final batch = list.take(ghRevealMaxBatch).where((item) => !_pending.contains(item) && !item.playing).toList();
    _showAll(list.skip(ghRevealMaxBatch));
    var index = 0;
    for (final item in batch) {
      final rect = item.globalRect();
      if (rect == null || rect.width == 0 || rect.height == 0) {
        item._show();
        continue;
      }
      if (!rect.overlaps(item.viewport())) {
        if (motion.prefs.scrollReveal) {
          _defer(item);
        } else {
          item._show();
        }
        continue;
      }
      item._play(motion, ghRevealDelay(index, base: baseDelay), fromScroll: false, blur: index < ghRevealBlurLimit);
      index += 1;
    }
  }

  void _defer(_GhRevealState item) {
    if (item.widget.ownOpacity) {
      item._show();
      return;
    }
    _pending.add(item);
    item._setPending(true);
  }

  void flushPending() {
    if (_pending.isEmpty) {
      return;
    }
    final items = _pending.toList();
    _pending.clear();
    for (final item in items) {
      item._setPending(false);
      item._show();
    }
  }

  void _scheduleCheck() {
    if (_checkScheduled) {
      return;
    }
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (mounted) {
        _checkPending();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _checkPending() {
    var index = 0;
    for (final item in _pending.toList()) {
      final rect = item.globalRect();
      if (rect == null || !rect.overlaps(item.viewport())) {
        continue;
      }
      _pending.remove(item);
      item._setPending(false);
      item._play(_motion, ghScrollRevealDelay(index), fromScroll: true, blur: index < ghRevealBlurLimit);
      index += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _GhRevealScopeMarker(state: this, child: widget.child);
    if (widget.fadePane) {
      child = FadeTransition(opacity: _paneOpacity, child: child);
    }
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        if (_pending.isNotEmpty) {
          _scheduleCheck();
        }
        return false;
      },
      child: child,
    );
  }
}

class _GhRevealScopeMarker extends InheritedWidget {
  const _GhRevealScopeMarker({required this.state, required super.child});

  final GhRevealScopeState? state;

  @override
  bool updateShouldNotify(_GhRevealScopeMarker oldWidget) => state != oldWidget.state;
}

class GhReveal extends StatefulWidget {
  const GhReveal({
    super.key,
    required this.child,
    this.kind = GhRevealKind.standard,
    this.id,
    this.projectId,
    this.ownOpacity = false,
    this.canTransform = true,
  });

  final Widget child;
  final GhRevealKind kind;
  final Object? id;
  final Object? projectId;
  final bool ownOpacity;
  final bool canTransform;

  @override
  State<GhReveal> createState() => _GhRevealState();
}

enum _Phase { shown, hidden, playing }

class _GhRevealState extends State<GhReveal> with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  GhRevealScopeState? _scope;
  GhTimeline? _timeline;
  Animation<double>? _track;
  GhPose _from = GhPose.identity;
  _Phase _phase = _Phase.shown;
  bool _registered = false;
  bool _pendingScroll = false;
  List<ScrollableState> _scrollables = const [];
  Object? _inheritedProject;
  bool thresholdSkipped = false;

  Object get identity => widget.id ?? this;

  Object? get projectId => widget.projectId ?? _inheritedProject;

  bool get playing => _phase == _Phase.playing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollables = <ScrollableState>[];
    var scrollable = context.findAncestorStateOfType<ScrollableState>();
    while (scrollable != null) {
      scrollables.add(scrollable);
      scrollable = scrollable.context.findAncestorStateOfType<ScrollableState>();
    }
    if (_pendingScroll) {
      _listen(false);
      _scrollables = scrollables;
      _listen(true);
    } else {
      _scrollables = scrollables;
    }
    _inheritedProject = GhRevealProject.maybeOf(context);
    if (!_registered) {
      _registered = true;
      _scope = GhRevealScope.maybeOf(context);
      if (_scope?._register(this) ?? false) {
        _phase = _Phase.hidden;
      }
    }
  }

  @override
  void dispose() {
    if (_pendingScroll) {
      _listen(false);
    }
    _scope?._unregister(this);
    _timeline?.dispose();
    super.dispose();
  }

  void _listen(bool on) {
    for (final scrollable in _scrollables) {
      if (on) {
        scrollable.position.addListener(_onScroll);
      } else {
        scrollable.position.removeListener(_onScroll);
      }
    }
  }

  void _onScroll() => _scope?._scheduleCheck();

  Rect? globalRect() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
  }

  Rect viewport() {
    final view = View.maybeOf(context);
    var clip = Offset.zero & (MediaQuery.maybeSizeOf(context) ?? (view == null ? Size.infinite : view.physicalSize / view.devicePixelRatio));
    for (final scrollable in _scrollables) {
      final box = scrollable.context.findRenderObject();
      if (box is RenderBox && box.hasSize && box.attached) {
        clip = clip.intersect(MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size));
      }
    }
    return clip;
  }

  void _setPending(bool pending) {
    if (pending == _pendingScroll) {
      return;
    }
    _pendingScroll = pending;
    _listen(pending);
    if (pending && mounted) {
      setState(() => _phase = _Phase.hidden);
    }
  }

  void _show() {
    if (!mounted || _phase == _Phase.shown) {
      return;
    }
    _timeline?.controller.stop();
    setState(() => _phase = _Phase.shown);
  }

  void _play(GhMotionData motion, double delay, {required bool fromScroll, required bool blur}) {
    if (!mounted) {
      return;
    }
    final spec = ghRevealSpec(
      kind: widget.kind,
      entrance: motion.prefs.entrance,
      fromScroll: fromScroll,
      blur: blur,
      blurAllowed: motion.blur,
      ownOpacity: widget.ownOpacity,
      canTransform: widget.canTransform,
    );
    final timeline = _timeline ??= GhTimeline(vsync: this);
    timeline.clear();
    _track = timeline.add(GhTrack(start: delay, duration: spec.duration, ease: spec.ease));
    _from = spec.from;
    setState(() => _phase = _Phase.playing);
    timeline.play(motion).whenCompleteOrCancel(() {
      if (mounted && _phase == _Phase.playing && timeline.controller.isCompleted) {
        setState(() => _phase = _Phase.shown);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    switch (_phase) {
      case _Phase.shown:
        return child;
      case _Phase.hidden:
        return Opacity(opacity: 0, child: child);
      case _Phase.playing:
        return GhPoseTransition(animation: _track!, from: _from, child: child);
    }
  }
}
