import 'package:flutter/widgets.dart';

import '../../design/design.dart';
import 'keyframe.dart';

const _cssEaseOut = Cubic(0, 0, 0.58, 1);

class GhPulseDot extends StatefulWidget {
  const GhPulseDot({super.key, required this.color, this.pulseColor, this.size});

  final Color color;
  final Color? pulseColor;
  final double? size;

  @override
  State<GhPulseDot> createState() => _GhPulseDotState();
}

class _GhPulseDotState extends State<GhPulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = widget.size ?? theme.space(2);
    final pulse = (widget.pulseColor ?? widget.color).withValues(alpha: 0.7);
    return GhKeyframe(
      active: true,
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) {
        final v = GhCurves.spring.transform(t);
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: v, child: child),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final raw = (_pulse.value / 0.8).clamp(0.0, 1.0);
                final p = _cssEaseOut.transform(raw);
                return Transform.scale(
                  scale: 1 + 1.75 * p,
                  child: Opacity(
                    opacity: 1 - p,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: pulse, shape: BoxShape.circle),
                      child: SizedBox(width: size, height: size),
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              child: SizedBox(width: size, height: size),
            ),
          ],
        ),
      ),
    );
  }
}
