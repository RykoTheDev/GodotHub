import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../motion/motion.dart';

class GhSmoothScrollController extends ScrollController {
  GhSmoothScrollController({super.initialScrollOffset, super.keepScrollOffset, super.debugLabel, super.onAttach, super.onDetach});

  static const duration = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) => GhSmoothScrollPosition(
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

class GhSmoothScrollPosition extends ScrollPositionWithSingleContext {
  GhSmoothScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  double? _target;

  bool get _motionOff {
    final element = context.storageContext;
    return !element.mounted || GhMotion.of(element).off;
  }

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0 || _motionOff) {
      _target = null;
      super.pointerScroll(delta);
      return;
    }
    final pending = activity is DrivenScrollActivity ? _target : null;
    final target = ((pending ?? pixels) + delta).clamp(minScrollExtent, maxScrollExtent);
    if (target == pixels && pending == null) {
      return;
    }
    _target = target;
    updateUserScrollDirection(-delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    animateTo(target, duration: GhSmoothScrollController.duration, curve: GhSmoothScrollController.curve).whenComplete(() {
      if (_target == target) {
        _target = null;
      }
    });
  }
}

class GhScrollView extends StatefulWidget {
  const GhScrollView({
    super.key,
    this.controller,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.primary,
    this.child,
  });

  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final bool? primary;
  final Widget? child;

  @override
  State<GhScrollView> createState() => _GhScrollViewState();
}

class _GhScrollViewState extends State<GhScrollView> {
  GhSmoothScrollController? _own;

  ScrollController? get _controller => widget.controller ?? (widget.primary == true ? null : (_own ??= GhSmoothScrollController()));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _controller,
    padding: widget.padding,
    scrollDirection: widget.scrollDirection,
    physics: widget.physics,
    primary: widget.primary,
    child: widget.child,
  );
}
