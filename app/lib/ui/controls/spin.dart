import 'package:flutter/widgets.dart';

import '../../motion/motion.dart';

class GhSpinning extends StatefulWidget {
  const GhSpinning({super.key, required this.child});

  static const curve = Cubic(0.55, 0.15, 0.45, 0.85);

  final Widget child;

  @override
  State<GhSpinning> createState() => _GhSpinningState();
}

class _GhSpinningState extends State<GhSpinning> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  late final Animation<double> _turns = CurvedAnimation(parent: _controller, curve: GhSpinning.curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GhMotion.of(context).off) {
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _turns, child: widget.child);
}
