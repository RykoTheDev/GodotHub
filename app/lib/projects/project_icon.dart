import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/design.dart';
import '../motion/motion.dart';
import '../motion/presence.dart';

final Map<String, ({Uint8List bytes, bool svg})?> _decoded = {};

({Uint8List bytes, bool svg})? decodeIconDataUrl(String url) {
  if (_decoded.containsKey(url)) return _decoded[url];
  ({Uint8List bytes, bool svg})? result;
  try {
    final data = UriData.parse(url);
    result = (bytes: data.contentAsBytes(), svg: data.mimeType == 'image/svg+xml');
  } catch (_) {
    result = null;
  }
  if (_decoded.length > 512) _decoded.remove(_decoded.keys.first);
  _decoded[url] = result;
  return result;
}

String projectInitials(String name, {bool tileStyle = false}) {
  final words = name.trim().split(RegExp(r'[\s_-]+')).where((w) => w.isNotEmpty).toList();
  if (tileStyle) {
    if (words.length > 1) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.length > 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }
  if (words.isEmpty) return '';
  if (words.length == 1) return (words[0].length > 2 ? words[0].substring(0, 2) : words[0]).toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

class ProjectIconImage extends StatelessWidget {
  const ProjectIconImage({super.key, required this.url, this.fit = BoxFit.contain, this.onError});

  final String url;
  final BoxFit fit;
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) {
    final decoded = decodeIconDataUrl(url);
    if (decoded == null) {
      if (onError != null) WidgetsBinding.instance.addPostFrameCallback((_) => onError!());
      return const SizedBox.shrink();
    }
    if (decoded.svg) {
      return SvgPicture.memory(
        decoded.bytes,
        fit: fit,
        errorBuilder: (context, error, stack) {
          if (onError != null) WidgetsBinding.instance.addPostFrameCallback((_) => onError!());
          return const SizedBox.shrink();
        },
      );
    }
    return Image.memory(
      decoded.bytes,
      frameBuilder: ghFadeInFrameBuilder,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) {
        if (onError != null) WidgetsBinding.instance.addPostFrameCallback((_) => onError!());
        return const SizedBox.shrink();
      },
    );
  }
}

List<double> _grayscaleContrast(double amount) {
  final g = amount;
  final r = 0.2126 + 0.7874 * (1 - g);
  final rg = 0.7152 - 0.7152 * (1 - g);
  final rb = 0.0722 - 0.0722 * (1 - g);
  final gr = 0.2126 - 0.2126 * (1 - g);
  final gg = 0.7152 + 0.2848 * (1 - g);
  final gb = 0.0722 - 0.0722 * (1 - g);
  final br = 0.2126 - 0.2126 * (1 - g);
  final bg = 0.7152 - 0.7152 * (1 - g);
  final bb = 0.0722 + 0.9278 * (1 - g);
  const c = 1.25;
  const o = (1 - c) * 0.5 * 255;
  return [r * c, rg * c, rb * c, 0, o, gr * c, gg * c, gb * c, 0, o, br * c, bg * c, bb * c, 0, o, 0, 0, 0, 1, 0];
}

class ProjectBackdropIcon extends StatelessWidget {
  const ProjectBackdropIcon({
    super.key,
    required this.hovered,
    required this.child,
    required this.restAngle,
    this.hoverAngle = 0,
    this.grayscale = true,
  });

  final bool hovered;
  final Widget child;
  final double restAngle;
  final double hoverAngle;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    final motion = GhMotion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: hovered ? 1 : 0),
      duration: motion.css(const Duration(milliseconds: 500)),
      curve: GhCurves.outExpo,
      child: child,
      builder: (context, t, child) {
        Widget result = Transform.rotate(angle: (restAngle + (hoverAngle - restAngle) * t) * 3.141592653589793 / 180, child: child);
        if (grayscale) {
          result = ColorFiltered(colorFilter: ColorFilter.matrix(_grayscaleContrast(1 - t)), child: result);
        }
        return result;
      },
    );
  }
}
