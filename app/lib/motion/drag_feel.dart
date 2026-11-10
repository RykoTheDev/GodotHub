import 'package:flutter/widgets.dart';

import '../design/design.dart';
import 'motion.dart';

@immutable
class GhDragTiming {
  const GhDragTiming(this.duration, this.curve);

  final Duration duration;
  final Curve curve;
}

@immutable
class GhDropLineFeel {
  const GhDropLineFeel({required this.height, required this.dot, required this.glow});

  final double height;
  final double dot;
  final bool glow;
}

@immutable
class GhAutoScrollConfig {
  const GhAutoScrollConfig({required this.thresholdX, required this.thresholdY, required this.acceleration});

  final double thresholdX;
  final double thresholdY;
  final double acceleration;
}

abstract final class GhDragFeel {
  static const curve = Cubic(0.22, 1, 0.36, 1);
  static const liftCurve = GhCurves.spring;

  static const activationDistance = 7.0;
  static const ghostOpacity = 0.22;
  static const reflow = GhDragTiming(Duration(milliseconds: 220), curve);
  static const drop = GhDragTiming(Duration(milliseconds: 260), curve);
  static const liftScale = 1.02;
  static const liftDuration = Duration(milliseconds: 240);
  static const dropLine = GhDropLineFeel(height: 2, dot: 4, glow: false);
  static const autoScroll = GhAutoScrollConfig(thresholdX: 0.12, thresholdY: 0.12, acceleration: 10);

  static double dropEndScale(double liftScale) => 1 / liftScale;
}

const ghAutoScrollConfig = GhDragFeel.autoScroll;

class GhDragLift extends StatefulWidget {
  const GhDragLift({super.key, required this.child, this.scale = GhDragFeel.liftScale, this.replay});

  final Widget child;
  final double scale;
  final Object? replay;

  @override
  State<GhDragLift> createState() => _GhDragLiftState();
}

class _GhDragLiftState extends State<GhDragLift> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _curved = CurvedAnimation(parent: _controller, curve: GhDragFeel.liftCurve);
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
  void didUpdateWidget(GhDragLift oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replay != widget.replay) {
      _run();
    }
  }

  void _run() {
    _controller.duration = GhMotion.of(context).css(GhDragFeel.liftDuration);
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
      animation: _curved,
      child: widget.child,
      builder: (context, child) => Transform.scale(scale: 1 + (widget.scale - 1) * _curved.value, child: child),
    );
  }
}

class GhDragGhost extends StatelessWidget {
  const GhDragGhost({super.key, required this.ghost, required this.child});

  final bool ghost;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: ghost ? GhDragFeel.ghostOpacity : 1, child: child);
  }
}
