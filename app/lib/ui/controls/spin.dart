import 'package:flutter/widgets.dart';

class GhSpinning extends StatefulWidget {
  const GhSpinning({super.key, required this.child});

  static const curve = Cubic(0.55, 0.15, 0.45, 0.85);

  final Widget child;

  @override
  State<GhSpinning> createState() => _GhSpinningState();
}

class _GhSpinningState extends State<GhSpinning> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  late final Animation<double> _turns = CurvedAnimation(parent: _controller, curve: GhSpinning.curve);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _turns, child: widget.child);
}
