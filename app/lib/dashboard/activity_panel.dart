import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../design/design.dart';
import '../logic/duration.dart';
import '../logic/last_opened.dart';
import '../motion/motion.dart';
import '../src/rust/api/types.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart';
import 'dashboard_logic.dart';
import 'dashboard_parts.dart';

class DashActivityPanel extends StatefulWidget {
  const DashActivityPanel({super.key, required this.insights, required this.timeFormat, required this.active});

  final TimeInsights? insights;
  final LastOpenedTimeFormat timeFormat;
  final bool active;

  @override
  State<DashActivityPanel> createState() => _DashActivityPanelState();
}

class _DashActivityPanelState extends State<DashActivityPanel> {
  ActivityRange _range = ActivityRange.weekly;
  List<(String, int)> _data = const [];
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(DashActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  void _load() {
    final request = ++_request;
    setState(() => _loading = true);
    Api.getActivity(_range.id).then(
      (list) {
        if (!mounted || request != _request) return;
        setState(() {
          _data = [for (final (key, seconds) in list) (key, seconds.toInt())];
          _loading = false;
        });
      },
      onError: (Object _) {
        if (mounted && request == _request) setState(() => _loading = false);
      },
    );
  }

  void _setRange(ActivityRange range) {
    if (range == _range) return;
    _range = range;
    if (widget.active) {
      _load();
    } else {
      setState(() {});
    }
  }

  Widget _toggle(GhTheme theme) {
    return Container(
      padding: EdgeInsets.all(theme.space(1)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1),
        children: [
          for (final r in ActivityRange.values)
            GhPressable(
              onPressed: () => _setRange(r),
              toggled: _range == r,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              builder: (context, states) {
                final selected = _range == r;
                return GhAnimatedBox(
                  height: theme.space(7),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(2.5)),
                  alignment: Alignment.center,
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  color: selected ? theme.accent : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
                  boxShadow: selected ? GhShadows.sm(Colors.black.withValues(alpha: 0.2)) : null,
                  child: Text(
                    td('dashboard_range_${r.id}'),
                    style: theme.text(
                      size: GhTextSize.x2s,
                      weight: GhWeight.semibold,
                      color: selected || states.active ? theme.ink : theme.muted,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _chart(GhTheme theme, int max) {
    final labelStep = _data.length > 14 ? (_data.length / 7).ceil() : 1;
    return SizedBox(
      height: theme.space(56),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: theme.space(5),
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [for (var i = 0; i < 4; i++) Container(height: 1, color: theme.outline.withValues(alpha: 0.25))],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                for (final (i, (key, seconds)) in _data.indexed)
                  Expanded(
                    key: ValueKey(key),
                    child: _Bar(
                      label: activityLabel(_range, key, widget.timeFormat),
                      showLabel: i % labelStep == 0,
                      seconds: seconds,
                      fraction: seconds > 0 ? math.max(seconds / max, 0.03) : 0,
                      delay: i * 16,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(GhTheme theme) {
    return SizedBox(
      height: theme.space(56),
      child: DashPulse(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(1.5),
          children: [
            for (var i = 0; i < _range.bars; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final total = _data.fold(0, (sum, e) => sum + e.$2);
    final max = _data.fold(1, (m, e) => math.max(m, e.$2));
    final insights = widget.insights;
    final weekday = insights?.mostProductiveWeekday;
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final chips = [
      DashInsightChip(
        icon: GhIcons.clock,
        label: td('dashboard_activity_tracked'),
        value: total > 0 ? formatDuration(total * 1000) : '-',
        tone: theme.accentBright,
      ),
      DashInsightChip(
        icon: GhIcons.stopwatch,
        label: td('dashboard_activity_peak'),
        value: total > 0 ? formatDuration(max * 1000) : '-',
        tone: violet400,
      ),
      DashInsightChip(
        icon: GhIcons.star,
        label: td('dashboard_insights_longest_streak'),
        value: td('dashboard_insights_days', count: insights?.longestStreakDays ?? 0),
        tone: theme.amber,
      ),
      DashInsightChip(
        icon: GhIcons.gamepad,
        label: td('dashboard_insights_productive_day'),
        value: weekday == null ? '-' : weekdayName(weekday),
        tone: theme.mint,
      ),
    ];
    final columns = wide ? 4 : 2;
    final gap = theme.space(2.5);
    return DashPanel(
      title: td('dashboard_${_range.id}'),
      icon: GhIcons.clock,
      action: _toggle(theme),
      delay: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(4),
        children: [
          if (_loading)
            _skeleton(theme)
          else if (total == 0)
            DashEmptyCard(text: td('dashboard_${_range.id}_empty'))
          else
            _chart(theme, max),
          Padding(
            padding: EdgeInsets.only(top: theme.space(1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                for (var i = 0; i < chips.length; i += columns)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: gap,
                      children: [for (var c = i; c < i + columns; c++) Expanded(child: chips[c])],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({required this.label, required this.showLabel, required this.seconds, required this.fraction, required this.delay});

  final String label;
  final bool showLabel;
  final int seconds;
  final double fraction;
  final int delay;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final duration = formatDuration(widget.seconds * 1000);
    return GhTooltip(
      side: GhSide.top,
      delay: const Duration(milliseconds: 80),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1.5),
        children: [
          Text(
            widget.label,
            style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.7)),
          ),
          Text(
            duration,
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2),
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: widget.fraction,
                  child: Semantics(
                    label: td('dashboard_weekly_aria', args: {'label': duration}),
                    child: DashGrowBar(
                      delay: widget.delay,
                      child: AnimatedOpacity(
                        opacity: _hovered ? 1.0 : 0.8,
                        duration: GhMotion.of(context).css(GhDurations.interactive),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [theme.accentDim, theme.accentBright],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: theme.space(3),
              child: Text(
                widget.showLabel ? widget.label : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.text(size: GhTextSize.x4s, color: theme.muted.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
