import 'package:flutter/widgets.dart';

class GhKeyframe extends StatefulWidget {
  const GhKeyframe({super.key, required this.active, required this.duration, required this.builder, this.token, this.child});

  final bool active;
  final Object? token;
  final Duration duration;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<GhKeyframe> createState() => _GhKeyframeState();
}

class _GhKeyframeState extends State<GhKeyframe> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration, value: 1);

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(GhKeyframe oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.active && (!oldWidget.active || oldWidget.token != widget.token)) {
      _controller.forward(from: 0);
    }
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
      builder: (context, child) => widget.builder(context, _controller.value, child),
      child: widget.child,
    );
  }
}
