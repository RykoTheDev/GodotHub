import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/motion.dart';
import '../../motion/presence.dart' show ghFadeInFrameBuilder;
import '../core/interaction.dart';
import '../core/tooltip.dart';

/// How a cover renders its picture.
enum GhCoverStyle {
  /// A real thumbnail or article image: full bleed, gently zoomed on hover.
  photo,

  /// A small square icon (Asset Library icons are often 64 px): a blurred,
  /// enlarged copy fills the cover as ambient color behind a crisp icon tile.
  icon,
}

int _hash(String text) {
  var h = 0;
  for (final unit in text.codeUnits) {
    h = (h * 31 + unit) & 0x7fffffff;
  }
  return h;
}

/// Two colors derived from [seed] around the accent hue, for covers with no
/// image and for initials avatars: every item gets its own, stable color.
(Color, Color) ghSeedColors(GhTheme theme, String seed) {
  final h = _hash(seed);
  final base = HSLColor.fromColor(theme.accent);
  final hue = (base.hue + (h % 140) - 70) % 360;
  final a = HSLColor.fromAHSL(1, hue, 0.55, theme.isLight ? 0.62 : 0.38).toColor();
  final b = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, theme.isLight ? 0.78 : 0.22).toColor();
  return (a, b);
}

/// The top of a showcase card. Shows [imageUrl] in the given [style], or a
/// generated gradient with a large faint [fallbackIcon] when there is no
/// picture (or it fails to load). [topStart] and [topEnd] float over the
/// cover (glass chips and quick actions). [zoom] is the card's hover state.
class GhCover extends StatelessWidget {
  const GhCover({
    super.key,
    required this.seed,
    required this.fallbackIcon,
    this.imageUrl,
    this.style = GhCoverStyle.photo,
    this.zoom = false,
    this.height = 40,
    this.topStart = const [],
    this.topEnd = const [],
  });

  final String seed;
  final String? imageUrl;
  final FaIconData fallbackIcon;
  final GhCoverStyle style;
  final bool zoom;

  /// Height in spacing units.
  final double height;
  final List<Widget> topStart;
  final List<Widget> topEnd;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final (c1, c2) = ghSeedColors(theme, seed);
    final duration = motion.css(const Duration(milliseconds: 420));
    final scale = zoom && !motion.off ? 1.06 : 1.0;

    final generated = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
      ),
      child: Align(
        alignment: const Alignment(0.75, 0.2),
        child: GhIcon(fallbackIcon, size: theme.space(20), color: Colors.white.withValues(alpha: 0.14)),
      ),
    );

    Widget image(BoxFit fit, {Widget? fallback}) => Image.network(
      url!,
      fit: fit,
      excludeFromSemantics: true,
      frameBuilder: ghFadeInFrameBuilder,
      errorBuilder: (context, error, stack) => fallback ?? const SizedBox.shrink(),
    );

    final Widget art;
    if (!hasImage) {
      art = AnimatedScale(scale: scale, duration: duration, curve: GhCurves.outExpo, child: generated);
    } else if (style == GhCoverStyle.photo) {
      art = Stack(
        fit: StackFit.expand,
        children: [
          generated,
          AnimatedScale(scale: scale, duration: duration, curve: GhCurves.outExpo, child: image(BoxFit.cover)),
        ],
      );
    } else {
      final tile = theme.space(17);
      art = Stack(
        fit: StackFit.expand,
        children: [
          generated,
          ClipRect(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22, tileMode: TileMode.decal),
              child: Transform.scale(scale: 1.6, child: Opacity(opacity: 0.85, child: image(BoxFit.cover))),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: theme.isLight ? 0.05 : 0.18)),
          Center(
            child: AnimatedScale(
              scale: zoom && !motion.off ? 1.08 : 1.0,
              duration: duration,
              curve: GhCurves.outExpo,
              child: Container(
                width: tile,
                height: tile,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.radiusCard),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: image(
                  BoxFit.cover,
                  fallback: Center(
                    child: GhIcon(fallbackIcon, size: theme.space(6), color: theme.muted),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: theme.space(height),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(child: art),
          // Soft scrim so glass chips read on bright images.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.35, 0.7, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
          if (topStart.isNotEmpty)
            PositionedDirectional(
              top: theme.space(3),
              start: theme.space(3),
              end: theme.space(16),
              child: Wrap(spacing: theme.space(1.5), runSpacing: theme.space(1.5), children: topStart),
            ),
          if (topEnd.isNotEmpty)
            PositionedDirectional(
              top: theme.space(2.5),
              end: theme.space(2.5),
              child: Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(1.5), children: topEnd),
            ),
        ],
      ),
    );
  }
}

/// A frosted pill for labels over a cover image (source, rating, category).
class GhGlassChip extends StatelessWidget {
  const GhGlassChip({super.key, required this.label, this.icon, this.iconColor, this.tooltip});

  final String label;
  final FaIconData? icon;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    Widget chip = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1),
            children: [
              if (icon != null) GhIcon(icon!, size: theme.space(2.75), color: iconColor ?? Colors.white),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) chip = GhTooltip(message: tooltip!, child: chip);
    return chip;
  }
}

/// A round frosted quick action over a cover (save, hide, open page).
/// [visible] lets the card reveal it on hover or focus; an [active] action
/// (a saved favorite) always shows.
class GhGlassIconButton extends StatelessWidget {
  const GhGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.active = false,
    this.activeColor,
    this.visible = true,
  });

  final FaIconData icon;
  final VoidCallback? onPressed;
  final String label;
  final bool active;
  final Color? activeColor;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final size = theme.space(8);
    return AnimatedOpacity(
      opacity: visible || active ? 1 : 0,
      duration: motion.css(GhDurations.color),
      alwaysIncludeSemantics: true,
      child: GhPressable(
        onPressed: onPressed,
        semanticLabel: label,
        tooltip: label,
        toggled: active,
        borderRadius: BorderRadius.circular(999),
        builder: (context, states) => ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: motion.css(GhDurations.color),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: states.active ? 0.6 : 0.42),
                border: Border.all(color: Colors.white.withValues(alpha: states.active ? 0.35 : 0.16)),
              ),
              child: GhIcon(icon, size: theme.space(3.5), color: active ? (activeColor ?? theme.amber) : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small round initials badge with a color from the name, for authors.
class GhInitialsAvatar extends StatelessWidget {
  const GhInitialsAvatar({super.key, required this.name, this.size = 6});

  final String name;

  /// Diameter in spacing units.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final (c1, c2) = ghSeedColors(theme, name);
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isEmpty
        ? '?'
        : (words.length == 1 ? words.first.characters.take(2).toString() : '${words.first.characters.first}${words.last.characters.first}')
              .toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: theme.space(size),
        height: theme.space(size),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
        ),
        child: Text(
          initials,
          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
