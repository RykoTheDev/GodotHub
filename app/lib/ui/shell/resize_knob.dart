import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/motion.dart';
import '../core/interaction.dart';

class GhResizeKnob extends StatelessWidget {
  const GhResizeKnob({
    super.key,
    required this.visible,
    required this.dragging,
    required this.hovered,
    required this.offsetY,
    required this.width,
  });

  static const double height = 40;
  static const double minTop = 36;
  static const double trackDistance = 56;
  static const double resetDistance = 72;
  static const Duration doubleClickWindow = Duration(milliseconds: 350);

  static double offsetFor(double y, double extent) {
    final top = y < minTop ? minTop : y;
    final max = extent - height < minTop ? minTop : extent - height;
    return (top > max ? max : top) - extent / 2;
  }

  final bool visible;
  final bool dragging;
  final bool hovered;
  final double offsetY;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final duration = GhMotion.of(context).css(GhDurations.interactive);
    final dotColor = dragging ? Colors.white : (hovered ? theme.accent : theme.line);
    final dots = <Widget>[];
    for (var i = 0; i < 3; i++) {
      if (i > 0) {
        dots.add(SizedBox(height: theme.space(1)));
      }
      dots.add(
        GhAnimatedBox(
          duration: duration,
          width: theme.space(1),
          height: theme.space(1),
          color: dotColor,
          borderRadius: BorderRadius.circular(9999),
          child: null,
        ),
      );
    }
    final knob = AnimatedScale(
      scale: dragging ? 1.1 : 1,
      duration: duration,
      curve: GhCurves.outExpo,
      child: GhAnimatedBox(
        duration: duration,
        width: theme.space(5),
        height: theme.space(10),
        alignment: Alignment.center,
        color: dragging ? theme.accent : theme.raised,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: dragging ? theme.accent : (hovered ? theme.accentDim : theme.line)),
        boxShadow: GhShadows.md(dragging ? theme.accent.withValues(alpha: 0.3) : theme.base),
        child: Column(mainAxisSize: MainAxisSize.min, children: dots),
      ),
    );
    final label = TweenAnimationBuilder<double>(
      tween: Tween(end: dragging ? 1 : 0),
      duration: duration,
      curve: GhCurves.outExpo,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, theme.space(1) * (1 - t)), child: child),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
        decoration: BoxDecoration(
          color: theme.raised,
          borderRadius: BorderRadius.circular(theme.radiusTag),
          border: Border.all(color: theme.line),
          boxShadow: GhShadows.md(theme.base),
        ),
        child: Text(
          '${width.round()}px',
          maxLines: 1,
          softWrap: false,
          style: theme
              .text(size: GhTextSize.x3s, mono: true, color: theme.muted)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: GhCurves.outExpo,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                knob,
                Positioned(bottom: theme.space(10) + theme.space(2), child: label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
