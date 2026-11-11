import 'package:flutter/widgets.dart';

class GhDashedBox extends StatelessWidget {
  const GhDashedBox({super.key, required this.color, required this.radius, required this.child});

  final Color color;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(foregroundPainter: _DashedPainter(color, radius), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius);

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(radius.toRRect(Offset.zero & size).deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
        distance += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
