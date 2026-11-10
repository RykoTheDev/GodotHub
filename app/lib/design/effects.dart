import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'tokens.dart';

BoxShadow cssShadow(double x, double y, double blur, double spread, Color color) {
  final sigma = blur / 2;
  final radius = sigma <= 0.5 ? 0.0 : (sigma - 0.5) / 0.57735;
  return BoxShadow(color: color, offset: Offset(x, y), blurRadius: radius, spreadRadius: spread);
}

const _shadowBlack10 = Color(0x1A000000);
const _shadowBlack05 = Color(0x0D000000);
const _shadowBlack25 = Color(0x40000000);

abstract final class GhShadows {
  static List<BoxShadow> xs2([Color? color]) => [cssShadow(0, 1, 0, 0, color ?? _shadowBlack05)];
  static List<BoxShadow> xs([Color? color]) => [cssShadow(0, 1, 2, 0, color ?? _shadowBlack05)];
  static List<BoxShadow> sm([Color? color]) => [
        cssShadow(0, 1, 3, 0, color ?? _shadowBlack10),
        cssShadow(0, 1, 2, -1, color ?? _shadowBlack10),
      ];
  static List<BoxShadow> md([Color? color]) => [
        cssShadow(0, 4, 6, -1, color ?? _shadowBlack10),
        cssShadow(0, 2, 4, -2, color ?? _shadowBlack10),
      ];
  static List<BoxShadow> lg([Color? color]) => [
        cssShadow(0, 10, 15, -3, color ?? _shadowBlack10),
        cssShadow(0, 4, 6, -4, color ?? _shadowBlack10),
      ];
  static List<BoxShadow> xl([Color? color]) => [
        cssShadow(0, 20, 25, -5, color ?? _shadowBlack10),
        cssShadow(0, 8, 10, -6, color ?? _shadowBlack10),
      ];
  static List<BoxShadow> xl2([Color? color]) => [cssShadow(0, 25, 50, -12, color ?? _shadowBlack25)];

  static List<BoxShadow> hoverLift() => [cssShadow(0, 6, 18, -12, const Color(0x99000000))];

  static List<BoxShadow> ring(Color color, {double width = 1, double offset = 0, Color? offsetColor}) => [
        if (offset > 0) BoxShadow(color: offsetColor ?? const Color(0x00000000), spreadRadius: offset),
        BoxShadow(color: color, spreadRadius: offset + width),
      ];

  static List<BoxShadow> focusRing(GhTheme theme) => [BoxShadow(color: theme.accent.withValues(alpha: 0.45), spreadRadius: 3)];

  static List<BoxShadow> inputFocus(GhTheme theme) => [BoxShadow(color: theme.accent.withValues(alpha: 0.18), spreadRadius: 3)];
}

class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter({required this.borderRadius, this.offsetY = 2, this.blur = 4, this.color = _shadowBlack05});

  final BorderRadius borderRadius;
  final double offsetY;
  final double blur;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size);
    canvas.save();
    canvas.clipRRect(rrect);
    final outer = Path()
      ..addRect((Offset.zero & size).inflate(blur * 2 + offsetY.abs()))
      ..addRRect(rrect.shift(Offset(0, offsetY)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      outer,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.offsetY != offsetY ||
      oldDelegate.blur != blur ||
      oldDelegate.color != color;
}

abstract final class GhBlur {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xl2 = 40.0;
  static const xl3 = 64.0;
  static const backdrop = 8.0;

  static ui.ImageFilter filter(double radius) => ui.ImageFilter.blur(sigmaX: radius, sigmaY: radius);
}

abstract final class GhGradients {
  static LinearGradient toRight(List<Color> colors, {List<double>? stops}) =>
      LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: colors, stops: stops);

  static LinearGradient toTop(List<Color> colors, {List<double>? stops}) =>
      LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: colors, stops: stops);

  static LinearGradient toBottomRight(List<Color> colors, {List<double>? stops}) =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors, stops: stops);

  static Shader projectIconMask(Rect rect) {
    final center = Offset(rect.left + rect.width * 0.7, rect.top + rect.height * 0.3);
    final radius = math.sqrt(math.pow(rect.width * 0.7, 2) + math.pow(rect.height * 0.7, 2));
    return ui.Gradient.radial(
      center,
      radius,
      const [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
      const [0, 0.25, 0.7],
    );
  }
}

abstract final class GhCurves {
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const outExpo = Cubic(0.16, 1, 0.3, 1);
  static const easeIn = Cubic(0.4, 0, 1, 1);
  static const easeOut = Cubic(0, 0, 0.2, 1);
  static const easeInOut = Cubic(0.4, 0, 0.2, 1);
  static const spin = Cubic(0.55, 0.15, 0.45, 0.85);
}

abstract final class GhDurations {
  static const color = Duration(milliseconds: 260);
  static const interactive = Duration(milliseconds: 280);
  static const progress = Duration(milliseconds: 600);
  static const iconTransform = Duration(milliseconds: 500);
  static const iconPress = Duration(milliseconds: 120);
  static const focusPop = Duration(milliseconds: 450);
  static const themeTransition = Duration(milliseconds: 450);
}

abstract final class GhIconMotion {
  static const hoverScale = 1.16;
  static const pressScale = 0.86;
}

abstract final class GhScrollbar {
  static const size = 8.0;
  static const border = 2.0;
}
