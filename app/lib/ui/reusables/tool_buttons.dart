import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/projects.dart';
import '../../design/design.dart';
import '../../motion/motion.dart';
import '../controls/spin.dart';
import '../core/i18n.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart' show GhSide;
import '../feedback/confirm_dialog.dart';
import '../feedback/toast.dart';
import '../overlays/dropdown.dart';
import '../overlays/menu.dart';

class GhToolButtonFace extends StatelessWidget {
  const GhToolButtonFace({super.key, required this.states, required this.child, required this.borderRadius, this.padding, this.width});

  final GhStates states;
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final hover = states.active;
    return GhAnimatedBox(
      height: theme.space(10),
      width: width,
      padding: padding,
      alignment: Alignment.center,
      color: hover ? theme.raised : theme.overlay,
      borderRadius: borderRadius.resolve(Directionality.of(context)),
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      boxShadow: hover ? GhShadows.hoverLift() : GhShadows.md(Colors.black.withValues(alpha: 0.1)),
      child: DefaultTextStyle.merge(
        style: theme.text(weight: GhWeight.semibold, color: hover ? theme.ink : theme.muted).copyWith(fontSize: theme.rem(1.0625)),
        child: IconTheme.merge(
          data: IconThemeData(color: hover ? theme.ink : theme.muted),
          child: child,
        ),
      ),
    );
  }
}

class GhImportButton extends StatefulWidget {
  const GhImportButton({super.key, required this.onImport, this.options = const [], this.disabled = false, this.pickFolder});

  final Future<void> Function(String folder) onImport;
  final List<GhMenuItem> options;
  final bool disabled;
  final Future<String?> Function()? pickFolder;

  @override
  State<GhImportButton> createState() => GhImportButtonState();
}

class GhImportButtonState extends State<GhImportButton> {
  bool _busy = false;

  Future<void> trigger() async {
    if (_busy || widget.disabled) return;
    setState(() => _busy = true);
    try {
      final folder = await (widget.pickFolder ?? ProjectsApi.pickFolder)();
      if (folder == null) return;
      try {
        await widget.onImport(folder);
      } catch (e) {
        debugPrint('[new-ui] import failed: $e');
        ghToasts.pushToast(GhToastType.error, '$e');
      }
    } catch (e) {
      debugPrint('[new-ui] import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final hasOptions = widget.options.isNotEmpty;
    final main = GhPressable(
      onPressed: _busy || widget.disabled ? null : trigger,
      borderRadius: BorderRadius.circular(theme.radiusItem),
      builder: (context, states) => GhToolButtonFace(
        states: states,
        padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
        borderRadius: hasOptions
            ? BorderRadiusDirectional.horizontal(start: Radius.circular(theme.radiusDropdownBtn), end: const Radius.circular(4))
            : BorderRadius.circular(theme.radiusItem),
        child: Text(tr.import),
      ),
    );
    if (!hasOptions) return main;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.space(1),
      children: [
        main,
        GhDropdown(
          align: GhSide.right,
          items: widget.options,
          trigger: (context, open, toggle) => GhPressable(
            onPressed: toggle,
            semanticLabel: tr.more_import_options,
            expanded: open,
            builder: (context, states) => GhToolButtonFace(
              states: states,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              borderRadius: BorderRadiusDirectional.horizontal(start: const Radius.circular(4), end: Radius.circular(theme.radiusDropdown)),
              child: AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: GhMotion.of(context).css(const Duration(milliseconds: 500)),
                curve: GhCurves.spring,
                child: GhIcon(GhIcons.chevronDown, size: theme.space(4), color: open ? theme.ink : null),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum GhScanPhase { idle, scanning, done, error }

class GhScanButton extends StatefulWidget {
  const GhScanButton({
    super.key,
    required this.scanDirs,
    required this.scan,
    this.onOpenSettings,
    this.onComplete,
    this.onReadd,
    this.onScanStart,
    this.onScanEnd,
    this.disabled = false,
    this.requiresDirs = true,
  });

  static const minScanTime = Duration(milliseconds: 800);
  static const resultHold = Duration(milliseconds: 1500);

  final List<String> scanDirs;
  final Future<List<String>> Function() scan;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onComplete;
  final FutureOr<void> Function(List<String> paths)? onReadd;
  final VoidCallback? onScanStart;
  final VoidCallback? onScanEnd;
  final bool disabled;
  final bool requiresDirs;

  @override
  State<GhScanButton> createState() => _GhScanButtonState();
}

class _GhScanButtonState extends State<GhScanButton> {
  GhScanPhase _phase = GhScanPhase.idle;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setPhase(GhScanPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
    if (phase == GhScanPhase.done || phase == GhScanPhase.error) {
      _timer?.cancel();
      _timer = Timer(GhScanButton.resultHold, () => _setPhase(GhScanPhase.idle));
    }
  }

  Future<void> _handleScan() async {
    if (_phase != GhScanPhase.idle) return;
    if (widget.scanDirs.isEmpty && widget.requiresDirs) {
      widget.onOpenSettings?.call();
      return;
    }
    _setPhase(GhScanPhase.scanning);
    widget.onScanStart?.call();
    final watch = Stopwatch()..start();
    void hold(GhScanPhase next) {
      final remaining = GhScanButton.minScanTime - watch.elapsed;
      if (remaining > Duration.zero) {
        _timer?.cancel();
        _timer = Timer(remaining, () => _setPhase(next));
      } else {
        _setPhase(next);
      }
    }

    try {
      final dismissed = await widget.scan();
      if (dismissed.isNotEmpty && widget.onReadd != null && mounted) {
        _askReadd(dismissed).ignore();
      }
      widget.onComplete?.call();
      hold(GhScanPhase.done);
    } catch (e) {
      debugPrint('[new-ui] scan failed: $e');
      hold(GhScanPhase.error);
    } finally {
      widget.onScanEnd?.call();
    }
  }

  Future<void> _askReadd(List<String> paths) async {
    final tr = context.tr.common;
    final theme = GhTheme.of(context);
    final confirmed = await showGhConfirmDialog(
      context,
      title: tr.found_dismissed_title(count: paths.length),
      descriptionContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(2),
        children: [
          Text(tr.found_dismissed_desc(count: paths.length)),
          Padding(
            padding: EdgeInsets.only(top: theme.space(1)),
            child: Wrap(
              spacing: theme.space(1.5),
              runSpacing: theme.space(1.5),
              children: [
                for (final path in paths)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: theme.space(48)),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
                      decoration: BoxDecoration(
                        color: theme.raised,
                        borderRadius: BorderRadius.circular(theme.radiusMd),
                        border: Border.all(color: theme.line.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        path.split(RegExp(r'[\\/]')).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      confirmLabel: tr.readd_all,
      cancelLabel: tr.skip_all,
    );
    if (!confirmed) return;
    try {
      await widget.onReadd?.call(paths);
    } catch (e) {
      debugPrint('[new-ui] re-adding dismissed projects failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final label = switch (_phase) {
      GhScanPhase.idle => tr.scan_for_projects,
      GhScanPhase.done => tr.scan_complete,
      GhScanPhase.error => tr.scan_failed,
      GhScanPhase.scanning => tr.scanning,
    };
    final idle = _phase == GhScanPhase.idle;
    return GhTooltip(
      message: label,
      side: GhSide.bottom,
      child: Semantics(
        liveRegion: true,
        child: GhPressable(
          onPressed: idle && !widget.disabled ? _handleScan : null,
          disabledOpacity: null,
          semanticLabel: label,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          builder: (context, states) {
            final hover = states.active;
            final (background, foreground) = switch (_phase) {
              GhScanPhase.idle => (hover ? theme.raised : theme.overlay, hover ? theme.ink : theme.muted),
              GhScanPhase.done => (theme.mint, theme.overlay),
              GhScanPhase.error => (theme.danger, theme.overlay),
              GhScanPhase.scanning => (theme.accent, Colors.white),
            };
            return GhAnimatedBox(
              width: theme.space(10),
              height: theme.space(10),
              alignment: Alignment.center,
              clip: true,
              color: background,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.1)),
              child: KeyedSubtree(
                key: ValueKey(_phase),
                child: switch (_phase) {
                  GhScanPhase.idle => GhIcon(GhIcons.refresh, size: theme.space(5), color: foreground),
                  GhScanPhase.scanning => _Spinner(color: foreground),
                  GhScanPhase.done => CustomPaint(
                    size: Size.square(theme.space(5)),
                    painter: _GlyphPainter(foreground, const [
                      [Offset(20, 6), Offset(9, 17), Offset(4, 12)],
                    ]),
                  ),
                  GhScanPhase.error => CustomPaint(
                    size: Size.square(theme.space(5)),
                    painter: _GlyphPainter(foreground, const [
                      [Offset(18, 6), Offset(6, 18)],
                      [Offset(6, 6), Offset(18, 18)],
                    ]),
                  ),
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = GhTheme.of(context).space(5);
    return GhSpinning(child: CustomPaint(size: Size.square(size), painter: _ArcPainter(color)));
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: Offset(12 * scale, 12 * scale), radius: 9 * scale);
    canvas.drawArc(rect, -1.2566, 5.0265, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.color, this.lines);

  final Color color;
  final List<List<Offset>> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final points in lines) {
      final path = Path()..moveTo(points.first.dx * scale, points.first.dy * scale);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * scale, point.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.color != color || oldDelegate.lines != lines;
}
