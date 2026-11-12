import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../../logic/project_drag.dart' show DropPlacement;
import '../../motion/drag_feel.dart';
import '../../motion/motion.dart';
import '../../state/drag_sort.dart' show DroppableRect, arrayMove, closestCenter, passesActivationDistance;
import '../core/interaction.dart' show ghHitsControl;

enum GhSortStrategy { vertical, rect }

@immutable
class GhCollisionArgs {
  const GhCollisionArgs({required this.activeId, required this.droppables, required this.collisionRect, this.pointer});

  final String activeId;
  final List<DroppableRect> droppables;
  final Rect collisionRect;
  final Offset? pointer;
}

typedef GhCollisionDetector = List<DroppableRect> Function(GhCollisionArgs args);

List<DroppableRect> ghClosestCenter(GhCollisionArgs args) => closestCenter(args.collisionRect, args.droppables);

class _Entry {
  _Entry({required this.id, required this.zone, required this.contextOf});

  String id;
  bool zone;
  BuildContext? Function() contextOf;

  Rect? measure() => _measureBox(contextOf());
}

class GhDndModel extends ChangeNotifier {
  String? _activeId;
  String? _overId;
  String? _dropping;
  Rect? _overRect;
  Rect? _collisionRect;
  Map<String, Rect> _rects = const {};

  String? get activeId => _activeId;

  String? get overId => _overId;

  String? get dropping => _dropping;

  Rect? get overRect => _overRect;

  Rect? get collisionRect => _collisionRect;

  bool get dragging => _activeId != null;

  Rect? rectOf(String id) => _rects[id];

  void _set({String? activeId, String? overId, Rect? overRect, Rect? collisionRect, Map<String, Rect>? rects, bool clear = false}) {
    if (clear) {
      _activeId = null;
      _overId = null;
      _overRect = null;
      _collisionRect = null;
      _rects = const {};
    } else {
      _activeId = activeId ?? _activeId;
      _overId = overId;
      _overRect = overRect;
      _collisionRect = collisionRect ?? _collisionRect;
      _rects = rects ?? _rects;
    }
    notifyListeners();
  }

  void _setDropping(String? id) {
    _dropping = id;
    notifyListeners();
  }

  Offset offsetFor(String id, List<String> items, GhSortStrategy strategy) {
    final active = _activeId;
    final over = _overId;
    if (active == null || over == null) return Offset.zero;
    final activeIndex = items.indexOf(active);
    final overIndex = items.indexOf(over);
    final index = items.indexOf(id);
    if (activeIndex < 0 || overIndex < 0 || index < 0) return Offset.zero;
    final rects = [for (final item in items) _rects[item]];
    if (strategy == GhSortStrategy.rect) {
      final moved = arrayMove(rects, overIndex, activeIndex);
      final oldRect = rects[index];
      final newRect = moved[index];
      if (oldRect == null || newRect == null) return Offset.zero;
      return newRect.topLeft - oldRect.topLeft;
    }
    final activeRect = rects[activeIndex];
    if (activeRect == null) return Offset.zero;
    if (index == activeIndex) {
      final overRect = rects[overIndex];
      if (overRect == null) return Offset.zero;
      return Offset(0, activeIndex < overIndex ? overRect.bottom - activeRect.bottom : overRect.top - activeRect.top);
    }
    final gap = _itemGap(rects, index, activeIndex);
    if (index > activeIndex && index <= overIndex) return Offset(0, -activeRect.height - gap);
    if (index < activeIndex && index >= overIndex) return Offset(0, activeRect.height + gap);
    return Offset.zero;
  }

  double _itemGap(List<Rect?> rects, int index, int activeIndex) {
    final current = rects[index];
    final previous = index > 0 ? rects[index - 1] : null;
    final next = index + 1 < rects.length ? rects[index + 1] : null;
    if (current == null) return 0;
    if (activeIndex < index) {
      if (previous != null) return current.top - previous.bottom;
      if (next != null) return next.top - current.bottom;
      return 0;
    }
    if (next != null) return next.top - current.bottom;
    if (previous != null) return current.top - previous.bottom;
    return 0;
  }
}

class GhDndScope extends StatefulWidget {
  const GhDndScope({
    super.key,
    required this.child,
    required this.onDragEnd,
    this.enabled = true,
    this.onDragStart,
    this.onDragCancel,
    this.collisionDetection = ghClosestCenter,
    this.overlayBuilder,
    this.overlayCount = 1,
    this.showDropLine = false,
    this.dropLineIgnorePrefix,
    this.placement,
    this.reflows,
    this.carriedIds = const [],
  });

  static double lastDropAt = -1e9;

  static bool get justDropped => DateTime.now().millisecondsSinceEpoch - lastDropAt < 150;

  final Widget child;
  final bool enabled;
  final void Function(String id)? onDragStart;
  final FutureOr<void> Function(String activeId, String? overId) onDragEnd;
  final VoidCallback? onDragCancel;
  final GhCollisionDetector collisionDetection;
  final Widget Function(BuildContext context, String activeId)? overlayBuilder;
  final int overlayCount;
  final bool showDropLine;
  final String? dropLineIgnorePrefix;
  final DropPlacement Function()? placement;
  final bool Function(String activeId, String overId)? reflows;
  final List<String> carriedIds;

  static GhDndScopeState? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_GhDndInherited>()?.state;

  @override
  State<GhDndScope> createState() => GhDndScopeState();
}

class GhDndScopeState extends State<GhDndScope> with TickerProviderStateMixin {
  final GhDndModel model = GhDndModel();
  final Map<Object, _Entry> _entries = {};
  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _drop = AnimationController(vsync: this);
  late final Ticker _scroller = createTicker(_autoScroll);
  int? _pointer;
  Offset _start = Offset.zero;
  String? _pendingId;
  Rect? _activeRect;
  Offset _delta = Offset.zero;
  Offset? _pointerPosition;
  bool _keyboard = false;
  bool _routed = false;
  Rect? _dropFrom;
  Rect? _dropTo;
  int _lift = 0;
  Duration _lastTick = Duration.zero;

  bool get dragging => model.dragging;

  @override
  void dispose() {
    _unroute();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _scroller.dispose();
    _drop.dispose();
    model.dispose();
    super.dispose();
  }

  Object register(String id, {required bool zone, required BuildContext? Function() contextOf}) {
    final token = Object();
    _entries[token] = _Entry(id: id, zone: zone, contextOf: contextOf);
    return token;
  }

  void update(Object token, String id, {required bool zone}) {
    final entry = _entries[token];
    if (entry == null) return;
    entry
      ..id = id
      ..zone = zone;
  }

  void unregister(Object token) => _entries.remove(token);

  Map<String, Rect> _measure() {
    final rects = <String, Rect>{};
    for (final entry in _entries.values) {
      final rect = entry.measure();
      if (rect != null) rects[entry.id] = rect;
    }
    return rects;
  }

  List<DroppableRect> _droppables(Map<String, Rect> rects) => [
    for (final entry in _entries.values)
      if (rects[entry.id] case final rect?) DroppableRect(entry.id, rect),
  ];

  void pointerDown(Object token, String id, PointerDownEvent event, RenderObject? itemRender) {
    if (!widget.enabled || dragging || model.dropping != null || _pointer != null) return;
    if (event.kind == PointerDeviceKind.mouse && event.buttons != kPrimaryButton) return;
    if (ghHitsControl(event.position, event.viewId, itemRender)) return;
    _pointer = event.pointer;
    _start = event.position;
    _pendingId = id;
    _route();
  }

  void _route() {
    if (_routed) return;
    _routed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _unroute() {
    if (!_routed) return;
    _routed = false;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
  }

  void _onPointer(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      if (!dragging) {
        if (passesActivationDistance(event.position - _start)) _begin(event.position);
        return;
      }
      _pointerPosition = event.position;
      _delta = event.position - _start;
      _refresh();
      return;
    }
    if (event is PointerUpEvent) {
      _pointer = null;
      _unroute();
      if (dragging) _finish();
      return;
    }
    if (event is PointerCancelEvent) {
      _pointer = null;
      _unroute();
      if (dragging) _cancel();
    }
  }

  void startKeyboard(String id) {
    if (!widget.enabled || dragging || model.dropping != null) return;
    _keyboard = true;
    _pendingId = id;
    _start = Offset.zero;
    _begin(null);
  }

  void _begin(Offset? pointer) {
    final id = _pendingId;
    if (id == null || !mounted) return;
    final rects = _measure();
    final rect = rects[id];
    if (rect == null) return;
    _activeRect = rect;
    _delta = pointer == null ? Offset.zero : pointer - _start;
    _pointerPosition = pointer;
    _lift++;
    widget.onDragStart?.call(id);
    model._set(activeId: id, rects: rects, collisionRect: rect.shift(_delta));
    HardwareKeyboard.instance.addHandler(_onKey);
    _portal.show();
    _refresh();
    if (!_keyboard) {
      _lastTick = Duration.zero;
      _scroller.start();
    }
  }

  void _refresh() {
    final active = model.activeId;
    final activeRect = _activeRect;
    if (active == null || activeRect == null) return;
    final rects = _measure();
    final collisionRect = activeRect.shift(_delta);
    final hits = widget.collisionDetection(
      GhCollisionArgs(
        activeId: active,
        droppables: _droppables(rects),
        collisionRect: collisionRect,
        pointer: _keyboard ? null : _pointerPosition,
      ),
    );
    final over = hits.isEmpty ? null : hits.first;
    model._set(overId: over?.id, overRect: over?.rect, collisionRect: collisionRect, rects: rects);
  }

  bool _onKey(KeyEvent event) {
    if (!dragging || event is KeyUpEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _cancel();
      return true;
    }
    if (!_keyboard) return false;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _finish();
      return true;
    }
    final direction = switch (key) {
      LogicalKeyboardKey.arrowDown => const Offset(0, 1),
      LogicalKeyboardKey.arrowUp => const Offset(0, -1),
      LogicalKeyboardKey.arrowRight => const Offset(1, 0),
      LogicalKeyboardKey.arrowLeft => const Offset(-1, 0),
      _ => null,
    };
    if (direction == null) return true;
    _keyboardMove(direction);
    return true;
  }

  void _keyboardMove(Offset direction) {
    final activeRect = _activeRect;
    final current = model.collisionRect;
    if (activeRect == null || current == null) return;
    final rects = _measure();
    Rect? best;
    var bestDistance = double.infinity;
    for (final entry in _entries.values) {
      if (entry.zone || entry.id == model.activeId) continue;
      final rect = rects[entry.id];
      if (rect == null) continue;
      final diff = rect.center - current.center;
      final along = diff.dx * direction.dx + diff.dy * direction.dy;
      if (along <= 1) continue;
      final distance = diff.distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = rect;
      }
    }
    if (best == null) return;
    _delta = best.topLeft - activeRect.topLeft;
    _refresh();
  }

  void _autoScroll(Duration elapsed) {
    final pointer = _pointerPosition;
    final activeContext = _activeContext();
    final dt = _lastTick == Duration.zero ? 16.0 : (elapsed - _lastTick).inMicroseconds / 1000.0;
    _lastTick = elapsed;
    if (pointer == null || activeContext == null || !activeContext.mounted) return;
    var scrolled = false;
    var state = Scrollable.maybeOf(activeContext);
    while (state != null) {
      final box = state.context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        final position = state.position;
        final vertical = position.axis == Axis.vertical;
        final extent = vertical ? rect.height : rect.width;
        final threshold = extent * (vertical ? GhDragFeel.autoScroll.thresholdY : GhDragFeel.autoScroll.thresholdX);
        final p = vertical ? pointer.dy : pointer.dx;
        final lead = vertical ? rect.top : rect.left;
        final trail = vertical ? rect.bottom : rect.right;
        var speed = 0.0;
        if (p < lead + threshold && position.pixels > position.minScrollExtent) {
          speed = -GhDragFeel.autoScroll.acceleration * ((lead + threshold - p) / threshold).clamp(0.0, 1.0);
        } else if (p > trail - threshold && position.pixels < position.maxScrollExtent) {
          speed = GhDragFeel.autoScroll.acceleration * ((p - (trail - threshold)) / threshold).clamp(0.0, 1.0);
        }
        if (speed != 0) {
          final next = (position.pixels + speed * dt / 5).clamp(position.minScrollExtent, position.maxScrollExtent);
          position.jumpTo(next);
          scrolled = true;
        }
      }
      state = Scrollable.maybeOf(state.context);
    }
    if (scrolled) _refresh();
  }

  BuildContext? _activeContext() {
    final id = model.activeId;
    for (final entry in _entries.values) {
      if (entry.id == id && !entry.zone) return entry.contextOf();
    }
    return null;
  }

  Rect? _currentOverlayRect() => _activeRect?.shift(_delta);

  void _stop() {
    _scroller.stop();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _keyboard = false;
    _pendingId = null;
  }

  Future<void> _finish() async {
    final active = model.activeId;
    if (active == null) return;
    final over = model.overId;
    final from = _currentOverlayRect();
    _stop();
    GhDndScope.lastDropAt = DateTime.now().millisecondsSinceEpoch.toDouble();
    model._setDropping(active);
    final result = widget.onDragEnd(active, over);
    model._set(clear: true);
    _animateDrop(active, from);
    if (result is Future) {
      try {
        await result;
      } catch (_) {}
    }
  }

  void _cancel() {
    final active = model.activeId;
    if (active == null) return;
    final from = _currentOverlayRect();
    _stop();
    _pointer = null;
    _unroute();
    model._setDropping(active);
    widget.onDragCancel?.call();
    model._set(clear: true);
    _animateDrop(active, from);
  }

  void _animateDrop(String id, Rect? from) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final to = _rectOf(id);
      if (from == null || to == null) {
        _endDrop();
        return;
      }
      setState(() {
        _dropFrom = from;
        _dropTo = to;
      });
      _drop
        ..duration = GhMotion.of(context).css(GhDragFeel.drop.duration)
        ..forward(from: 0).whenCompleteOrCancel(_endDrop);
    });
  }

  Rect? _rectOf(String id) {
    for (final entry in _entries.values) {
      if (entry.id == id && !entry.zone) return entry.measure();
    }
    return null;
  }

  void _endDrop() {
    if (!mounted) return;
    _portal.hide();
    setState(() {
      _dropFrom = null;
      _dropTo = null;
      _activeRect = null;
    });
    model._setDropping(null);
  }

  Widget _overlay(BuildContext context) {
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return const SizedBox.shrink();
    Offset local(Offset global) => overlayBox.globalToLocal(global);
    return AnimatedBuilder(
      animation: Listenable.merge([model, _drop]),
      builder: (context, _) {
        final children = <Widget>[];
        final id = model.activeId ?? model.dropping;
        final dropFrom = _dropFrom;
        final dropTo = _dropTo;
        Rect? rect;
        var dropScale = 1.0;
        if (model.activeId != null) {
          rect = _currentOverlayRect();
        } else if (dropFrom != null && dropTo != null) {
          final t = GhDragFeel.drop.curve.transform(_drop.value);
          rect = Rect.lerp(dropFrom, dropTo, t);
          dropScale = 1 + (GhDragFeel.dropEndScale(GhDragFeel.liftScale) - 1) * t;
        } else if (model.dropping != null) {
          rect = _currentOverlayRect();
        }
        if (model.dragging) {
          children.add(
            const Positioned.fill(
              child: MouseRegion(cursor: SystemMouseCursors.grabbing, opaque: true, child: SizedBox.expand()),
            ),
          );
        }
        if (widget.showDropLine && model.dragging) {
          final line = _dropLine(context, local);
          if (line != null) children.add(line);
        }
        final builder = widget.overlayBuilder;
        if (id != null && rect != null && builder != null) {
          final topLeft = local(rect.topLeft);
          children.add(
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              width: rect.width,
              height: rect.height,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: dropScale,
                  child: GhDragLift(
                    replay: _lift,
                    child: GhDragLiftOverlay(count: widget.overlayCount, child: builder(context, id)),
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(children: children);
      },
    );
  }

  Widget? _dropLine(BuildContext context, Offset Function(Offset) local) {
    final active = model.activeId;
    final overId = model.overId;
    final overRect = model.overRect;
    if (active == null || overId == null || overRect == null) return null;
    final prefix = widget.dropLineIgnorePrefix;
    final onZone = prefix != null && overId.startsWith(prefix);
    final visible = overId != active && !widget.carriedIds.contains(overId) && !onZone && !(widget.reflows?.call(active, overId) ?? false);
    if (!visible) return null;
    final placement = widget.placement?.call();
    final collision = model.collisionRect;
    final after = placement != null ? placement == DropPlacement.after : collision != null && collision.center.dy > overRect.center.dy;
    final theme = GhTheme.of(context);
    final feel = GhDragFeel.dropLine;
    final anchor = local(Offset(overRect.left, after ? overRect.bottom : overRect.top));
    return Positioned(
      left: anchor.dx,
      top: anchor.dy - feel.dot / 2,
      width: overRect.width,
      height: feel.dot,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: feel.dot,
              height: feel.dot,
              decoration: BoxDecoration(color: theme.accentBright, shape: BoxShape.circle),
            ),
            Expanded(
              child: Container(
                height: feel.height,
                decoration: BoxDecoration(color: theme.accentBright, borderRadius: BorderRadius.circular(9999)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _overlay,
      child: _GhDndInherited(state: this, model: model, child: widget.child),
    );
  }
}

class _GhDndInherited extends InheritedNotifier<GhDndModel> {
  const _GhDndInherited({required this.state, required GhDndModel model, required super.child}) : super(notifier: model);

  final GhDndScopeState state;
}

class GhSortableContext extends InheritedWidget {
  const GhSortableContext({super.key, required this.items, this.strategy = GhSortStrategy.vertical, required super.child});

  final List<String> items;
  final GhSortStrategy strategy;

  static GhSortableContext? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GhSortableContext>();

  @override
  bool updateShouldNotify(GhSortableContext oldWidget) => oldWidget.strategy != strategy || !_sameList(oldWidget.items, items);
}

bool _sameList(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Rect? _measureBox(BuildContext? context) {
  if (context == null || !context.mounted) return null;
  final render = context.findRenderObject();
  if (render is RenderBox) {
    if (!render.attached || !render.hasSize) return null;
    return render.localToGlobal(Offset.zero) & render.size;
  }
  if (render is RenderSliver) {
    final geometry = render.geometry;
    if (!render.attached || geometry == null || geometry.paintExtent <= 0) return null;
    return MatrixUtils.transformRect(render.getTransformTo(null), render.paintBounds);
  }
  return null;
}

class GhSortableItem extends StatefulWidget {
  const GhSortableItem({
    super.key,
    required this.id,
    required this.child,
    this.disabled = false,
    this.isStatic = false,
    this.carried = false,
  });

  final String id;
  final Widget child;
  final bool disabled;
  final bool isStatic;
  final bool carried;

  @override
  State<GhSortableItem> createState() => _GhSortableItemState();
}

class _GhSortableItemState extends State<GhSortableItem> {
  final GlobalKey _box = GlobalKey();
  final FocusNode _focus = FocusNode(debugLabel: 'GhSortableItem');
  GhDndScopeState? _scope;
  Object? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = GhDndScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _detach();
      _scope = scope;
      _token = scope?.register(widget.id, zone: false, contextOf: () => _box.currentContext);
    }
  }

  @override
  void didUpdateWidget(GhSortableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final token = _token;
    if (token != null) _scope?.update(token, widget.id, zone: false);
  }

  void _detach() {
    final token = _token;
    if (token != null) _scope?.unregister(token);
    _token = null;
  }

  @override
  void dispose() {
    _detach();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final scope = _scope;
    if (scope == null || widget.disabled || event is! KeyDownEvent) return KeyEventResult.ignored;
    if (scope.dragging) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
      if (!identical(FocusManager.instance.primaryFocus, _focus)) return KeyEventResult.ignored;
      scope.startKeyboard(widget.id);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final token = _token;
    final model = scope?.model;
    final sortable = GhSortableContext.maybeOf(context);
    final dragging = model?.dragging ?? false;
    final isDragging = model?.activeId == widget.id;
    final dropping = model?.dropping == widget.id;
    final offset = model == null || sortable == null || widget.isStatic
        ? Offset.zero
        : model.offsetFor(widget.id, sortable.items, sortable.strategy);
    final theme = GhTheme.of(context);
    final ghost = isDragging || widget.carried;
    final enabled = !widget.disabled;
    Widget child = Opacity(
      opacity: ghost ? GhDragFeel.ghostOpacity : (dropping ? 0 : 1),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ghost
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
              )
            : const BoxDecoration(),
        child: widget.child,
      ),
    );
    child = MouseRegion(
      cursor: enabled ? (dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab) : MouseCursor.defer,
      child: child,
    );
    child = Focus(focusNode: _focus, canRequestFocus: enabled, skipTraversal: !enabled, onKeyEvent: _onKey, child: child);
    child = Listener(
      onPointerDown: enabled && scope != null && token != null
          ? (event) => scope.pointerDown(token, widget.id, event, _box.currentContext?.findRenderObject())
          : null,
      child: child,
    );
    final reflow = GhMotion.of(context).css(GhDragFeel.reflow.duration);
    return KeyedSubtree(
      key: _box,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: offset),
        duration: dragging ? reflow : Duration.zero,
        curve: GhDragFeel.reflow.curve,
        builder: (context, value, child) => Transform.translate(offset: value, child: child),
        child: child,
      ),
    );
  }
}

class GhDropState {
  const GhDropState({required this.isOver, required this.dragging, this.overRect, this.selfRect});

  final bool isOver;
  final bool dragging;
  final Rect? overRect;
  final Rect? selfRect;

  bool get containsTarget {
    if (isOver) return true;
    final over = overRect;
    final self = selfRect;
    if (over == null || self == null) return false;
    return over.top >= self.top && over.bottom <= self.bottom && over.left >= self.left && over.right <= self.right;
  }
}

class GhDroppable extends StatefulWidget {
  const GhDroppable({super.key, required this.id, required this.builder, this.disabled = false});

  final String id;
  final bool disabled;
  final Widget Function(BuildContext context, GhDropState state) builder;

  @override
  State<GhDroppable> createState() => _GhDroppableState();
}

class _GhDroppableState extends State<GhDroppable> {
  final GlobalKey _box = GlobalKey();
  GhDndScopeState? _scope;
  Object? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = GhDndScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _detach();
      _scope = scope;
      if (!widget.disabled) {
        _token = scope?.register(widget.id, zone: true, contextOf: () => _box.currentContext);
      }
    }
  }

  @override
  void didUpdateWidget(GhDroppable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disabled != widget.disabled) {
      _detach();
      if (!widget.disabled) {
        _token = _scope?.register(widget.id, zone: true, contextOf: () => _box.currentContext);
      }
    } else if (_token != null) {
      _scope?.update(_token!, widget.id, zone: true);
    }
  }

  void _detach() {
    final token = _token;
    if (token != null) _scope?.unregister(token);
    _token = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _scope?.model;
    final state = GhDropState(
      isOver: !widget.disabled && model?.overId == widget.id,
      dragging: model?.dragging ?? false,
      overRect: model?.overRect,
      selfRect: model?.rectOf(widget.id),
    );
    return KeyedSubtree(key: _box, child: widget.builder(context, state));
  }
}

class GhDragLiftOverlay extends StatelessWidget {
  const GhDragLiftOverlay({super.key, required this.child, this.count = 1});

  final Widget child;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.overlay,
              borderRadius: radius,
              boxShadow: GhShadows.xl2(Colors.black.withValues(alpha: 0.3)),
            ),
          ),
        ),
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
        if (count > 1)
          PositionedDirectional(
            top: -theme.space(2),
            end: -theme.space(2),
            child: Container(
              constraints: BoxConstraints(minWidth: theme.space(6)),
              height: theme.space(6),
              padding: EdgeInsets.symmetric(horizontal: theme.space(1.5)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.accentBright,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$count',
                style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
