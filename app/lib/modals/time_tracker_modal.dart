import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../design/design.dart';
import '../logic/duration.dart';
import '../logic/locale.dart';
import '../logic/project_sort.dart';
import '../motion/shared_ticker.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';

bool isSameLocalDay(int aMs, int bMs) {
  final a = DateTime.fromMillisecondsSinceEpoch(aMs);
  final b = DateTime.fromMillisecondsSinceEpoch(bMs);
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime startOfLocalWeek(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day - (d.weekday - 1));
}

bool isSameLocalWeek(int aMs, int bMs) => startOfLocalWeek(aMs) == startOfLocalWeek(bMs);

class TimeTrackerModal extends StatefulWidget {
  const TimeTrackerModal({super.key, required this.project, required this.onClose, this.loadActivity});

  final Project project;
  final VoidCallback onClose;
  final Future<List<(String, BigInt)>> Function(String projectId)? loadActivity;

  @override
  State<TimeTrackerModal> createState() => _TimeTrackerModalState();
}

class _TimeTrackerModalState extends State<TimeTrackerModal> {
  List<(String, int)> _weekly = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    (widget.loadActivity ?? Api.getProjectActivity)(widget.project.id).then(
      (data) {
        if (mounted) {
          setState(() {
            _weekly = [for (final (key, seconds) in data) (key, seconds.toInt())];
            _loading = false;
          });
        }
      },
      onError: (Object _) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  Widget _stat(GhTheme theme, FaIconData icon, String label, String value) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3.5)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusXl / 2),
        border: Border.all(color: theme.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(1.5),
        children: [
          Row(
            spacing: theme.space(1.5),
            children: [
              GhIcon(icon, size: theme.space(3), color: theme.muted.withValues(alpha: 0.6)),
              Flexible(
                child: Text(
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
              ),
            ],
          ),
          Text(
            value,
            style: theme
                .text(size: GhTextSize.lg, weight: GhWeight.semibold, color: theme.ink)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    ),
  );

  Widget _summary(BuildContext context, int now) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final project = widget.project;
    final start = project.sessionStartedAtMs?.toInt();
    final live = start != null ? math.max(0, now - start) : 0;
    final today = project.timeTodaySeconds.toInt() * 1000 + (start != null && isSameLocalDay(start, now) ? live : 0);
    final week = project.timeWeekSeconds.toInt() * 1000 + (start != null && isSameLocalWeek(start, now) ? live : 0);
    return Row(
      spacing: theme.space(3),
      children: [
        _stat(theme, GhIcons.clock, tr.time_today, formatDuration(today)),
        _stat(theme, GhIcons.history, tr.time_this_week, formatDuration(week)),
        _stat(theme, GhIcons.stopwatch, tr.time_all_time, formatDuration(effectiveTotalMs(project, now))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final hint = theme.muted.withValues(alpha: 0.6);
    final weekTotal = _weekly.fold<int>(0, (acc, e) => acc + e.$2);
    final max = math.max(1, _weekly.fold<int>(0, (acc, e) => math.max(acc, e.$2)));
    final tiny = theme.text(size: GhTextSize.x4s, color: hint).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final Widget chart;
    if (_loading) {
      chart = SizedBox(
        height: theme.space(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(1.5),
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.rem(0.25))),
                ),
              ),
          ],
        ),
      );
    } else if (weekTotal == 0) {
      chart = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(10)),
        child: Column(
          spacing: theme.space(2),
          children: [
            Opacity(
              opacity: 0.4,
              child: GhIcon(GhIcons.stopwatch, size: theme.space(7), color: hint),
            ),
            Text(
              tr.time_weekly_empty,
              style: theme.text(size: GhTextSize.sm, color: hint),
            ),
          ],
        ),
      );
    } else {
      chart = SizedBox(
        height: theme.space(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(1.5),
          children: [
            for (final (key, seconds) in _weekly)
              Expanded(
                child: Column(
                  spacing: theme.space(1),
                  children: [
                    Expanded(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusMd / 2)),
                        alignment: Alignment.bottomCenter,
                        child: seconds > 0
                            ? FractionallySizedBox(
                                heightFactor: math.max(seconds / max, 0.06),
                                widthFactor: 1,
                                child: _Bar(label: formatDuration(seconds * 1000)),
                              )
                            : Padding(
                                padding: EdgeInsets.only(bottom: theme.space(1)),
                                child: Text(formatDuration(0), textAlign: TextAlign.center, style: tiny),
                              ),
                      ),
                    ),
                    Text(
                      formatLocaleDate(DateTime.parse('${key}T00:00:00'), const GhDateFormatOptions(weekday: GhDatePart.short)),
                      style: theme.text(size: GhTextSize.x4s, color: hint),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return GhModalShell(
      icon: GhIcon(GhIcons.stopwatch, size: theme.space(5), color: theme.accentBright),
      title: tr.time_tracked_title,
      maxWidth: GhModalWidth.xl,
      onClose: widget.onClose,
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(6),
          children: [
            if (widget.project.sessionStartedAtMs != null)
              GhNow(builder: (context, now) => _summary(context, now.millisecondsSinceEpoch))
            else
              _summary(context, DateTime.now().millisecondsSinceEpoch),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(3),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.time_weekly_chart.toUpperCase(),
                      style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: hint, letterSpacingEm: 0.05),
                    ),
                    Text(
                      tr.time_week_total.args({'total': formatDuration(weekTotal * 1000)}),
                      style: theme.text(size: GhTextSize.x2s, color: hint).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
                chart,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({required this.label});

  final String label;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: GhDurations.color,
        decoration: BoxDecoration(
          color: _hovered ? theme.accentBright : theme.accent.withValues(alpha: 0.5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(theme.rem(0.25))),
        ),
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          maxHeight: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(bottom: theme.space(1)),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: theme
                  .text(size: GhTextSize.x4s, weight: GhWeight.semibold, color: theme.ink)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      ),
    );
  }
}
