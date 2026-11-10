import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

@immutable
class FaIconData {
  const FaIconData(this.prefix, this.name, this.width, this.height, this.path);

  final String prefix;
  final String name;
  final int width;
  final int height;
  final String path;

  static final Map<String, Path> _cache = {};

  Path get parsed => _cache.putIfAbsent('$prefix:$name', () {
        final proxy = _PathProxy();
        writeSvgPathDataToPath(path, proxy);
        return proxy.path;
      });

  double aspectRatio() => width / height;
}

class _PathProxy extends PathProxy {
  final Path path = Path();

  @override
  void close() => path.close();

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

class GhIcon extends StatelessWidget {
  const GhIcon(this.icon, {super.key, this.size, this.width, this.natural = false, this.color, this.faded = false, this.semanticLabel});

  final FaIconData icon;
  final double? size;
  final double? width;
  final bool natural;
  final Color? color;
  final bool faded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final height = size ?? iconTheme.size ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final paintColor = color ?? iconTheme.color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    Widget result = SizedBox(
      width: width ?? (natural ? height * icon.aspectRatio() : height),
      height: height,
      child: CustomPaint(painter: _FaIconPainter(icon, paintColor)),
    );
    if (faded) {
      result = Opacity(opacity: 0.45, child: result);
    }
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: semanticLabel == null ? ExcludeSemantics(child: result) : result,
    );
  }
}

class _FaIconPainter extends CustomPainter {
  _FaIconPainter(this.icon, this.color);

  final FaIconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / icon.width < size.height / icon.height ? size.width / icon.width : size.height / icon.height;
    canvas.save();
    canvas.translate((size.width - icon.width * scale) / 2, (size.height - icon.height * scale) / 2);
    canvas.scale(scale);
    canvas.drawPath(icon.parsed, Paint()..color = color..isAntiAlias = true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FaIconPainter oldDelegate) => oldDelegate.icon != icon || oldDelegate.color != color;
}
