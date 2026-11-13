import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../design/design.dart';
import '../logic/last_opened.dart';
import '../motion/animated_number.dart';
import '../motion/motion.dart';
import '../motion/reveal.dart';
import '../projects/project_icon.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/keyboard_shortcuts.dart' show newProjectRequestSignal;
import '../state/shell_signals.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

String td(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('dashboard:$key', count: count, args: args);

const violet400 = Color(0xFFA78BFA);

class DashActivation extends InheritedWidget {
  const DashActivation({super.key, required this.epoch, required super.child});

  final int epoch;

  static int of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<DashActivation>()?.epoch ?? 0;

  @override
  bool updateShouldNotify(DashActivation oldWidget) => oldWidget.epoch != epoch;
}

abstract class _ReplayState<T extends StatefulWidget> extends State<T> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, value: 1);
  int? _epoch;

  Duration get baseDuration;
  Duration get baseDelay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final epoch = DashActivation.of(context);
    if (epoch == _epoch) return;
    _epoch = epoch;
    play();
  }

  void play() {
    final motion = GhMotion.of(context);
    if (motion.off) {
      controller.value = 1;
      return;
    }
    final duration = motion.css(baseDuration);
    final delay = motion.css(baseDelay);
    final total = duration + delay;
    controller.duration = total;
    _start = total.inMicroseconds == 0 ? 0 : delay.inMicroseconds / total.inMicroseconds;
    controller.forward(from: 0);
  }

  double _start = 0;

  double get progress {
    final t = controller.value;
    if (t <= _start) return 0;
    return GhCurves.outExpo.transform(((t - _start) / (1 - _start)).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class DashRise extends StatefulWidget {
  const DashRise({super.key, required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<DashRise> createState() => _DashRiseState();
}

class _DashRiseState extends _ReplayState<DashRise> {
  @override
  Duration get baseDuration => const Duration(milliseconds: 500);

  @override
  Duration get baseDelay => Duration(milliseconds: widget.delay);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, child) {
        final p = progress;
        if (p >= 1) return child!;
        return Opacity(
          opacity: p,
          child: Transform.translate(offset: Offset(0, 12 * (1 - p)), child: child),
        );
      },
    );
  }
}

class DashGrowBar extends StatefulWidget {
  const DashGrowBar({super.key, required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<DashGrowBar> createState() => _DashGrowBarState();
}

class _DashGrowBarState extends _ReplayState<DashGrowBar> {
  @override
  Duration get baseDuration => const Duration(milliseconds: 700);

  @override
  Duration get baseDelay => Duration(milliseconds: widget.delay);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, child) {
        final p = progress;
        if (p >= 1) return child!;
        return Transform(alignment: Alignment.bottomCenter, transform: Matrix4.diagonal3Values(1, p, 1), child: child);
      },
    );
  }
}

class DashPulse extends StatefulWidget {
  const DashPulse({super.key, required this.child});

  final Widget child;

  @override
  State<DashPulse> createState() => _DashPulseState();
}

class _DashPulseState extends State<DashPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GhMotion.of(context).off) {
      _controller.stop();
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = const Cubic(0.4, 0, 0.6, 1).transform(1 - (2 * _controller.value - 1).abs());
        return Opacity(opacity: 1 - 0.5 * t, child: child);
      },
    );
  }
}

class DashPanel extends StatelessWidget {
  const DashPanel({super.key, required this.title, required this.icon, required this.child, this.action, this.delay = 0});

  final String title;
  final FaIconData icon;
  final Widget? action;
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return DashRise(
      delay: delay,
      child: Container(
        padding: EdgeInsets.all(theme.space(5)),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.radiusCard),
          border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
          boxShadow: GhShadows.sm(Colors.black.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Row(
              spacing: theme.space(2.5),
              children: [
                Container(
                  width: theme.space(7),
                  height: theme.space(7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.overlay,
                    borderRadius: BorderRadius.circular(theme.radiusTile),
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: GhIcon(icon, size: theme.space(3.5), color: theme.accentBright),
                ),
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Positioned.fill(
                        child: Center(child: Container(height: 1, color: theme.outline.withValues(alpha: 0.4))),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: theme.space(2)),
                        child: ColoredBox(
                          color: theme.surface,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(end: theme.space(2.5)),
                            child: Semantics(
                              header: true,
                              child: Text(
                                title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(
                                  size: GhTextSize.xs,
                                  weight: GhWeight.semibold,
                                  color: theme.muted,
                                  letterSpacingEm: 0.05,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class DashEmptyCard extends StatelessWidget {
  const DashEmptyCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhDashedBox(
      color: theme.outline.withValues(alpha: 0.5),
      radius: radius,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(8)),
        decoration: BoxDecoration(color: theme.overlay, borderRadius: radius),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.625),
        ),
      ),
    );
  }
}

class DashInsightChip extends StatelessWidget {
  const DashInsightChip({super.key, required this.icon, required this.label, required this.value, required this.tone});

  final FaIconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhReveal(
      child: Container(
        padding: EdgeInsets.all(theme.space(3)),
        decoration: BoxDecoration(
          color: theme.overlay,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(2.5),
          children: [
            Container(
              width: theme.space(7),
              height: theme.space(7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.raised,
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              ),
              child: GhIcon(icon, size: theme.space(3.5), color: tone),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(
                      size: GhTextSize.x3s,
                      weight: GhWeight.semibold,
                      color: theme.muted.withValues(alpha: 0.6),
                      letterSpacingEm: 0.05,
                    ),
                  ),
                  SizedBox(height: theme.space(0.5)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget dashChevron(BuildContext context, GhTheme theme, Color color, {double? size}) {
  final icon = GhIcon(GhIcons.chevronRight, size: size ?? theme.space(3.5), color: color);
  if (Directionality.of(context) != TextDirection.rtl) return icon;
  return Transform.rotate(angle: math.pi, child: icon);
}

class DashProjectAvatar extends StatefulWidget {
  const DashProjectAvatar({super.key, required this.project});

  final Project project;

  @override
  State<DashProjectAvatar> createState() => _DashProjectAvatarState();
}

class _DashProjectAvatarState extends State<DashProjectAvatar> {
  String? _icon;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DashProjectAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.path != widget.project.path) _load();
  }

  void _load() {
    final path = widget.project.path;
    final request = ++_request;
    _icon = getCachedProjectIcon(path);
    Api.getProjectIcon(path).then((value) {
      if (mounted && request == _request) setState(() => _icon = value);
    }, onError: (Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.space(9);
    final radius = BorderRadius.circular(theme.radiusTile);
    final icon = _icon;
    if (icon != null && icon.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: radius,
          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          boxShadow: GhShadows.sm(Colors.black.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ExcludeSemantics(
            child: ProjectIconImage(url: icon, fit: BoxFit.cover, onError: () => setState(() => _icon = null)),
          ),
        ),
      );
    }
    final name = widget.project.name.trim();
    final letter = name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.accent, theme.accentDim]),
        border: Border.all(color: theme.accentBright.withValues(alpha: 0.3)),
        boxShadow: GhShadows.sm(theme.accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        letter,
        style: theme.text(size: GhTextSize.sm, weight: GhWeight.bold, color: theme.ink),
      ),
    );
  }
}

BoxDecoration dashRowDecoration(GhTheme theme, bool hovered) => BoxDecoration(
  color: hovered ? theme.raised : theme.overlay,
  borderRadius: BorderRadius.circular(theme.radiusItem),
  border: Border.all(color: hovered ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
);

class DashProjectRow extends StatelessWidget {
  const DashProjectRow({super.key, required this.project, required this.timeFormat, this.showOpened = true});

  final Project project;
  final LastOpenedTimeFormat timeFormat;
  final bool showOpened;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final openedAt = showOpened ? formatLastOpened(project.lastOpened, timeFormat: timeFormat) : null;
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: () => AppSignals.emit(openProjectSignal, project.id),
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.all(theme.space(2.5)),
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
        child: Row(
          spacing: theme.space(3),
          children: [
            DashProjectAvatar(project: project),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                  ),
                  Text(
                    project.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            if (openedAt != null)
              Text(
                td('dashboard_opened_at', args: {'time': openedAt}),
                style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.6)),
              ),
            dashChevron(context, theme, states.active ? theme.accentBright : theme.muted.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class DashQuickActions extends StatelessWidget {
  const DashQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final actions = [
      (label: td('dashboard_new_project'), icon: GhIcons.folderPlus, signal: newProjectRequestSignal, primary: true),
      (label: td('dashboard_import_project'), icon: GhIcons.import, signal: importProjectRequestSignal, primary: false),
      (label: td('dashboard_scan_projects'), icon: GhIcons.refresh, signal: scanProjectsSignal, primary: false),
    ];
    final radius = BorderRadius.circular(theme.radiusItem);
    return Wrap(
      spacing: theme.space(2.5),
      runSpacing: theme.space(2.5),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final a in actions)
          GhPressable(
            onPressed: () => AppSignals.emit(a.signal),
            borderRadius: radius,
            builder: (context, states) => GhAnimatedBox(
              height: theme.space(11),
              padding: EdgeInsets.symmetric(horizontal: theme.space(5)),
              borderRadius: radius,
              color: a.primary ? (states.active ? theme.accentBright : theme.accent) : (states.active ? theme.raised : theme.overlay),
              border: Border.all(
                color: !a.primary && states.active ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5),
              ),
              boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.1)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(2),
                children: [
                  GhIcon(a.icon, size: theme.space(4), color: a.primary ? theme.ink : theme.accentBright),
                  Text(
                    a.label,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class DashKpiCard extends StatefulWidget {
  const DashKpiCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.gradient,
    this.animate,
    this.hint,
    this.sub,
    this.subDown = false,
    this.onPressed,
    this.delay = 0,
  });

  final String label;
  final String? hint;
  final FaIconData icon;
  final String value;
  final int? animate;
  final String? sub;
  final bool subDown;
  final List<Color> gradient;
  final VoidCallback? onPressed;
  final int delay;

  @override
  State<DashKpiCard> createState() => _DashKpiCardState();
}

class _DashKpiCardState extends State<DashKpiCard> {
  bool _hovered = false;

  Widget _body(GhTheme theme, bool hovered) {
    final clickable = widget.onPressed != null;
    final sub = widget.sub;
    final subColor = sub != null
        ? (widget.subDown ? theme.danger : theme.mint)
        : (hovered ? theme.muted : theme.muted.withValues(alpha: 0.4));
    final iconRotation = hovered ? 0.0 : -6 * math.pi / 180;
    return AnimatedContainer(
      duration: GhDurations.interactive,
      transform: Matrix4.translationValues(0, clickable && hovered ? -2 : 0, 0),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusCard),
        border: Border.all(color: clickable && hovered ? theme.outline : theme.outline.withValues(alpha: 0.4)),
        boxShadow: GhShadows.sm(Colors.black.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            bottom: -theme.space(7),
            end: -theme.space(7),
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: 12 * math.pi / 180,
                  child: GhIcon(widget.icon, size: theme.space(28), color: theme.ink.withValues(alpha: 0.045)),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.space(2),
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: theme.space(1)),
                        child: Text(
                          widget.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(
                            size: GhTextSize.x3s,
                            weight: GhWeight.semibold,
                            color: theme.muted.withValues(alpha: 0.7),
                            letterSpacingEm: 0.05,
                          ),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: iconRotation / (2 * math.pi),
                      duration: GhDurations.interactive,
                      child: Container(
                        width: theme.space(9),
                        height: theme.space(9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.overlay,
                          borderRadius: BorderRadius.circular(theme.radiusTile),
                          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                        ),
                        child: GhIcon(widget.icon, size: theme.space(4), color: theme.accentBright),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: theme.space(3)),
                DefaultTextStyle.merge(
                  style: theme
                      .text(size: GhTextSize.base, weight: GhWeight.bold, color: theme.ink, lineHeight: 1)
                      .copyWith(fontSize: theme.rem(1.6), fontFeatures: const [FontFeature.tabularFigures()]),
                  child: widget.animate != null ? GhAnimatedNumber(widget.animate!) : Text(widget.value),
                ),
                SizedBox(height: theme.space(2.5)),
                ExcludeSemantics(
                  child: Container(
                    width: theme.space(9),
                    height: theme.space(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(colors: widget.gradient),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(3)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(1),
                    children: [
                      Flexible(
                        child: Text(
                          sub ?? widget.hint ?? widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: subColor),
                        ),
                      ),
                      if (clickable && sub == null) dashChevron(context, theme, subColor, size: theme.space(3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final onPressed = widget.onPressed;
    final Widget card;
    if (onPressed != null) {
      card = GhPressable(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(theme.radiusCard),
        builder: (context, states) => _body(theme, states.active),
      );
    } else {
      card = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: _body(theme, _hovered),
      );
    }
    return DashRise(delay: widget.delay, child: card);
  }
}
