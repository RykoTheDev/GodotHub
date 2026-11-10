import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../design/design.dart';

@immutable
class GhHsv {
  const GhHsv(this.h, this.s, this.v);

  final double h;
  final double s;
  final double v;

  @override
  bool operator ==(Object other) => other is GhHsv && other.h == h && other.s == s && other.v == v;

  @override
  int get hashCode => Object.hash(h, s, v);

  @override
  String toString() => 'GhHsv($h, $s, $v)';
}

int _jsRound(double x) => (x + 0.5).floorToDouble().toInt();

GhHsv hexToHsv(String hex) {
  final clean = hex.replaceFirst('#', '');
  double channel(int start) {
    if (clean.length < start + 2) {
      return double.nan;
    }
    final parsed = int.tryParse(clean.substring(start, start + 2), radix: 16);
    return parsed == null ? double.nan : parsed / 255;
  }

  final r = channel(0);
  final g = channel(2);
  final b = channel(4);
  if (r.isNaN || g.isNaN || b.isNaN) {
    return const GhHsv(0, 0, 0);
  }
  final max = math.max(r, math.max(g, b));
  final min = math.min(r, math.min(g, b));
  final d = max - min;
  var h = 0.0;
  if (d != 0) {
    if (max == r) {
      h = ((g - b) / d).remainder(6);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h = _jsRound(h * 60).toDouble();
    if (h < 0) {
      h += 360;
    }
  }
  final s = max == 0 ? 0.0 : _jsRound((d / max) * 100).toDouble();
  final v = _jsRound(max * 100).toDouble();
  return GhHsv(h, s, v);
}

String hsvToHex(double h, double s, double v) {
  s /= 100;
  v /= 100;
  final c = v * s;
  final x = c * (1 - (((h / 60).remainder(2)) - 1).abs());
  final m = v - c;
  double r, g, b;
  if (h < 60) {
    (r, g, b) = (c, x, 0);
  } else if (h < 120) {
    (r, g, b) = (x, c, 0);
  } else if (h < 180) {
    (r, g, b) = (0, c, x);
  } else if (h < 240) {
    (r, g, b) = (0, x, c);
  } else if (h < 300) {
    (r, g, b) = (x, 0, c);
  } else {
    (r, g, b) = (c, 0, x);
  }
  String hex(double n) => _jsRound((n + m) * 255).toRadixString(16).padLeft(2, '0');
  return '#${hex(r)}${hex(g)}${hex(b)}';
}

List<BoxShadow> _thumbShadow(double y, double blur, double alpha) => [
  cssShadow(0, 0, 0, 1, const Color(0x4D000000)),
  cssShadow(0, y, blur, 0, Color.fromRGBO(0, 0, 0, alpha)),
];

class GhHsvColorPicker extends StatefulWidget {
  const GhHsvColorPicker({super.key, required this.value, required this.onChanged, this.size = 200});

  final String value;
  final ValueChanged<String> onChanged;
  final double size;

  @override
  State<GhHsvColorPicker> createState() => _GhHsvColorPickerState();
}

enum _Drag { sv, hue }

const _hueStops = [
  Color(0xFFFF0000),
  Color(0xFFFFFF00),
  Color(0xFF00FF00),
  Color(0xFF00FFFF),
  Color(0xFF0000FF),
  Color(0xFFFF00FF),
  Color(0xFFFF0000),
];

class _GhHsvColorPickerState extends State<GhHsvColorPicker> {
  _Drag? _dragging;

  GhHsv get _hsv => hexToHsv(widget.value);

  void _updateFromSv(Offset local) {
    final size = widget.size;
    final s = (local.dx / size * 100).clamp(0.0, 100.0);
    final v = (100 - local.dy / size * 100).clamp(0.0, 100.0);
    widget.onChanged(hsvToHex(_hsv.h, s, v));
  }

  void _updateFromHue(Offset local) {
    final h = (local.dx / widget.size * 360).clamp(0.0, 359.0);
    final hsv = _hsv;
    widget.onChanged(hsvToHex(h, hsv.s, hsv.v));
  }

  bool _isPrimary(PointerDownEvent event) => event.kind != PointerDeviceKind.mouse || event.buttons & kPrimaryMouseButton != 0;

  Widget _region(_Drag kind, void Function(Offset) update, Widget child) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!_isPrimary(event)) {
          return;
        }
        setState(() => _dragging = kind);
        update(event.localPosition);
      },
      onPointerMove: (event) {
        if (_dragging == kind) {
          update(event.localPosition);
        }
      },
      onPointerUp: (_) => setState(() => _dragging = null),
      onPointerCancel: (_) => setState(() => _dragging = null),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final hsv = _hsv;
    final size = widget.size;
    final radius = theme.radiusLg;
    final innerRadius = BorderRadius.circular(math.max(0, radius - 1));
    final svThumbX = hsv.s / 100 * size;
    final svThumbY = (100 - hsv.v) / 100 * size;
    final hueX = hsv.h / 360 * size;
    final pure = HSVColor.fromAHSV(1, hsv.h % 360, 1, 1).toColor();
    final svThumb = theme.space(4);
    final hueThumbW = theme.space(2);
    final hueThumbH = theme.space(5);

    final sv = MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: _region(
        _Drag.sv,
        _updateFromSv,
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: theme.line),
          ),
          child: ClipRRect(
            borderRadius: innerRadius,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: GhGradients.toRight([Colors.white, pure]))),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: GhGradients.toTop([Colors.black, Colors.black.withValues(alpha: 0)])),
                  ),
                ),
                Positioned(
                  left: svThumbX - svThumb / 2,
                  top: svThumbY - svThumb / 2,
                  width: svThumb,
                  height: svThumb,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: _thumbShadow(2, 4, 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final hue = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _region(
        _Drag.hue,
        _updateFromHue,
        Container(
          width: size,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: theme.line),
          ),
          child: ClipRRect(
            borderRadius: innerRadius,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: GhGradients.toRight(_hueStops))),
                ),
                Positioned(
                  left: hueX - hueThumbW / 2,
                  top: 6 - hueThumbH,
                  width: hueThumbW,
                  height: hueThumbH,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(theme.radiusSm),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: _thumbShadow(1, 3, 0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sv,
          SizedBox(height: theme.space(3)),
          hue,
        ],
      ),
    );
  }
}
