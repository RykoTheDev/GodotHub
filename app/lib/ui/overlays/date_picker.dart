import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/design.dart';
import '../core/i18n.dart';
import '../core/interaction.dart';
import 'menu.dart';

String ghDateToValue(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime? ghDateFromValue(String value) {
  if (value.isEmpty) {
    return null;
  }
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String ghIntlLocale(String language) {
  final normalized = language.replaceAll('-', '_');
  for (final candidate in {normalized, normalized.split('_').first}) {
    try {
      if (DateFormat.localeExists(candidate)) {
        return candidate;
      }
    } on Object {
      break;
    }
  }
  return 'en_US';
}

String ghFormatDate(DateTime date, String language) => DateFormat.yMd(ghIntlLocale(language)).format(date);

const _arMaMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'يونيو', 'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر'];

List<String> ghMonthNames(String language) {
  if (language.toLowerCase() == 'ar-ma') {
    return _arMaMonths;
  }
  final format = DateFormat('LLLL', ghIntlLocale(language));
  return List.generate(12, (index) => format.format(DateTime(2026, index + 1, 1)));
}

List<String> ghWeekdayNames(String language) {
  final locale = ghIntlLocale(language);
  final week = List.generate(7, (index) => DateTime(2026, 1, 4 + index));
  final short = DateFormat('ccc', locale);
  final shortDays = [for (final date in week) short.format(date).replaceFirst('.', '')];
  if (shortDays.every((day) => day.length <= 3)) {
    return shortDays;
  }
  final narrow = DateFormat('ccccc', locale);
  return [for (final date in week) narrow.format(date)];
}

String ghCapitalizeWords(String text) => text.replaceAllMapped(RegExp(r'(^|\s)(\S)'), (match) => '${match[1]}${match[2]!.toUpperCase()}');

String _languageOf(BuildContext context, String? locale) => locale ?? context.tr.$meta.locale.languageTag;

List<DateTime> ghCalendarDays(DateTime viewDate) {
  final first = DateTime(viewDate.year, viewDate.month, 1);
  final offset = first.weekday % 7;
  return List.generate(42, (index) => DateTime(viewDate.year, viewDate.month, 1 - offset + index));
}

class GhDatePicker extends StatefulWidget {
  const GhDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.clearLabel,
    this.placeholder,
    this.displayValue,
    this.markPastDates = false,
    this.pastDateMessage,
    this.compact = false,
    this.disabled = false,
    this.locale,
    this.formatDate,
    this.monthNames,
    this.weekdayNames,
    this.previousMonthLabel,
    this.nextMonthLabel,
    this.addDueLabel,
    this.changeDueLabel,
    this.today,
  }) : assert(placeholder != null || displayValue != null);

  final String value;
  final ValueChanged<String> onChanged;
  final String clearLabel;
  final String? placeholder;
  final Widget? displayValue;
  final bool markPastDates;
  final String? pastDateMessage;
  final bool compact;
  final bool disabled;
  final String? locale;
  final String Function(DateTime date)? formatDate;
  final List<String>? monthNames;
  final List<String>? weekdayNames;
  final String? previousMonthLabel;
  final String? nextMonthLabel;
  final String? addDueLabel;
  final String Function(String date)? changeDueLabel;
  final DateTime Function()? today;

  @override
  State<GhDatePicker> createState() => _GhDatePickerState();
}

class _GhDatePickerState extends State<GhDatePicker> {
  final _portal = OverlayPortalController();
  final _group = Object();
  bool _open = false;
  late DateTime _viewDate = ghDateFromValue(widget.value) ?? _now();

  DateTime _now() => widget.today?.call() ?? DateTime.now();

  String _formatValue(String value) {
    final date = ghDateFromValue(value);
    if (date == null) {
      return widget.placeholder ?? '';
    }
    final format = widget.formatDate;
    return format != null ? format(date) : ghFormatDate(date, _languageOf(context, widget.locale));
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      setState(() {
        _viewDate = ghDateFromValue(widget.value) ?? _now();
        _open = true;
      });
      _portal.show();
    }
  }

  void _close() {
    if (!_open) {
      return;
    }
    if (_portal.isShowing) {
      _portal.hide();
    }
    setState(() => _open = false);
  }

  void _select(DateTime date) {
    widget.onChanged(ghDateToValue(date));
    _close();
  }

  void _clear() {
    widget.onChanged('');
    _close();
  }

  void _changeMonth(int offset) {
    setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + offset, 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final value = widget.value;
    final todayValue = ghDateToValue(_now());
    final selectedIsPast = value.isNotEmpty && value.compareTo(todayValue) < 0;
    final button = OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context, info) {
        final anchor = MatrixUtils.transformRect(info.childPaintTransform, Offset.zero & info.childSize);
        return CustomSingleChildLayout(
          delegate: _DatePickerLayout(anchor),
          child: TapRegion(
            groupId: _group,
            onTapOutside: (_) => _close(),
            child: GhDatePickerPanel(
              viewDate: _viewDate,
              value: value,
              todayValue: todayValue,
              markPastDates: widget.markPastDates,
              clearLabel: widget.clearLabel,
              locale: widget.locale,
              monthNames: widget.monthNames,
              weekdayNames: widget.weekdayNames,
              previousMonthLabel: widget.previousMonthLabel,
              nextMonthLabel: widget.nextMonthLabel,
              onSelect: _select,
              onClear: _clear,
              onPreviousMonth: () => _changeMonth(-1),
              onNextMonth: () => _changeMonth(1),
            ),
          ),
        );
      },
      child: widget.compact ? _compactTrigger(theme) : _fullTrigger(theme),
    );
    if (widget.compact) {
      return TapRegion(groupId: _group, child: button);
    }
    return TapRegion(
      groupId: _group,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          button,
          if (widget.markPastDates && selectedIsPast && widget.pastDateMessage != null)
            Padding(
              padding: EdgeInsetsDirectional.only(top: theme.space(1), start: theme.space(3)),
              child: Text(
                widget.pastDateMessage!,
                style: theme.text(size: GhTextSize.x3s, color: theme.danger),
              ),
            ),
        ],
      ),
    );
  }

  String _changeDueLabel(String date) {
    final label = widget.changeDueLabel;
    return label != null ? label(date) : context.tr.common.date_change_due.args({'date': date});
  }

  Widget _compactTrigger(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    final value = widget.value;
    return GhPressable(
      onPressed: widget.disabled ? null : _toggle,
      borderRadius: radius,
      disabledOpacity: 0.5,
      disabledCursor: SystemMouseCursors.forbidden,
      semanticLabel: value.isNotEmpty ? _changeDueLabel(_formatValue(value)) : widget.addDueLabel ?? context.tr.common.date_add_due,
      builder: (context, states) {
        final hovered = states.hovered && !states.disabled;
        final style = theme
            .text(size: GhTextSize.x3s, color: hovered ? theme.ink : theme.muted)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
        return GhLiftBox(
          constraints: const BoxConstraints(minWidth: 48),
          color: hovered ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          lift: hovered,
          padding: EdgeInsets.all(theme.space(1)),
          child: AnimatedDefaultTextStyle(
            style: style,
            duration: GhDurations.color,
            curve: GhCurves.outExpo,
            child: ExcludeSemantics(
              child: widget.displayValue ?? Text(_formatValue(value), maxLines: 1, softWrap: false, textAlign: TextAlign.end),
            ),
          ),
        );
      },
    );
  }

  Widget _fullTrigger(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusItem);
    final value = widget.value;
    return GhPressable(
      onPressed: widget.disabled ? null : _toggle,
      borderRadius: radius,
      disabledOpacity: null,
      disabledCursor: SystemMouseCursors.click,
      builder: (context, states) {
        final hovered = states.hovered && !states.disabled;
        final style = theme.text(size: GhTextSize.sm, mono: true, color: value.isNotEmpty ? theme.ink : theme.muted);
        return GhAnimatedBox(
          alignment: AlignmentDirectional.centerStart,
          color: theme.overlay,
          borderRadius: radius,
          border: Border.all(color: hovered ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
          child: DefaultTextStyle(style: style, textAlign: TextAlign.start, child: widget.displayValue ?? Text(_formatValue(value))),
        );
      },
    );
  }
}

class GhDatePickerPanel extends StatelessWidget {
  const GhDatePickerPanel({
    super.key,
    required this.viewDate,
    required this.value,
    required this.todayValue,
    required this.onSelect,
    required this.onClear,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.clearLabel,
    this.markPastDates = false,
    this.locale,
    this.monthNames,
    this.weekdayNames,
    this.previousMonthLabel,
    this.nextMonthLabel,
  });

  final DateTime viewDate;
  final String value;
  final String todayValue;
  final bool markPastDates;
  final String clearLabel;
  final String? locale;
  final List<String>? monthNames;
  final List<String>? weekdayNames;
  final String? previousMonthLabel;
  final String? nextMonthLabel;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onClear;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    final language = _languageOf(context, locale);
    final months = monthNames ?? ghMonthNames(language);
    final weekdays = weekdayNames ?? ghWeekdayNames(language);
    final days = ghCalendarDays(viewDate);
    final gap = theme.space(0.5);
    final rows = <Widget>[];
    for (var week = 0; week < 6; week++) {
      if (week > 0) {
        rows.add(SizedBox(height: gap));
      }
      final cells = <Widget>[];
      for (var column = 0; column < 7; column++) {
        if (column > 0) {
          cells.add(SizedBox(width: gap));
        }
        final date = days[week * 7 + column];
        final dateValue = ghDateToValue(date);
        cells.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _DayButton(
                key: ValueKey(dateValue),
                day: date.day,
                selected: value == dateValue,
                currentMonth: date.month == viewDate.month,
                past: markPastDates && dateValue.compareTo(todayValue) < 0,
                onPressed: () => onSelect(date),
              ),
            ),
          ),
        );
      }
      rows.add(Row(children: cells));
    }
    return Container(
      width: theme.space(72),
      padding: EdgeInsets.all(theme.space(3)),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        boxShadow: GhShadows.xl2(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: theme.space(3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PanelButton(label: '‹', semanticLabel: previousMonthLabel ?? tr.common.date_previous_month, onPressed: onPreviousMonth),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ghCapitalizeWords(months[viewDate.month - 1]),
                      style: theme.text(size: GhTextSize.sm, color: theme.ink),
                    ),
                    SizedBox(width: theme.space(1)),
                    Text(
                      '${viewDate.year}',
                      style: theme.text(size: GhTextSize.sm, color: theme.muted),
                    ),
                  ],
                ),
                _PanelButton(label: '›', semanticLabel: nextMonthLabel ?? tr.common.date_next_month, onPressed: onNextMonth),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: theme.space(1)),
            child: Row(
              children: [
                for (final day in weekdays)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.space(1)),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...rows,
          if (value.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: theme.space(3)),
              padding: EdgeInsets.only(top: theme.space(3)),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.line)),
              ),
              child: _PanelButton(label: clearLabel, onPressed: onClear, wide: true),
            ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.label, required this.onPressed, this.semanticLabel, this.wide = false});

  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    Widget text(Color color) => GhAnimatedText(
      label,
      style: wide ? theme.text(size: GhTextSize.xs, color: color) : theme.text(size: GhTextSize.base, color: color),
      textAlign: TextAlign.center,
    );
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hovered = states.hovered;
        final child = text(hovered ? theme.ink : theme.muted);
        return GhLiftBox(
          alignment: wide ? Alignment.center : null,
          color: hovered ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          lift: hovered,
          padding: wide
              ? EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2))
              : EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
          child: semanticLabel == null ? child : ExcludeSemantics(child: child),
        );
      },
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    super.key,
    required this.day,
    required this.selected,
    required this.currentMonth,
    required this.past,
    required this.onPressed,
  });

  final int day;
  final bool selected;
  final bool currentMonth;
  final bool past;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      selected: selected,
      builder: (context, states) {
        final hovered = states.hovered && !selected;
        final Color background;
        final Color foreground;
        if (selected) {
          background = theme.accent;
          foreground = Colors.white;
        } else if (currentMonth && !past) {
          background = hovered ? theme.raised : theme.raised.withValues(alpha: 0);
          foreground = theme.ink;
        } else {
          background = hovered ? theme.raised : theme.raised.withValues(alpha: 0);
          foreground = hovered ? theme.muted : theme.muted.withValues(alpha: currentMonth ? 0.4 : 0.35);
        }
        return GhLiftBox(
          alignment: Alignment.center,
          color: background,
          borderRadius: radius,
          lift: hovered,
          child: GhAnimatedText(
            '$day',
            style: theme.text(size: GhTextSize.xs, color: foreground),
          ),
        );
      },
    );
  }
}

class _DatePickerLayout extends SingleChildLayoutDelegate {
  _DatePickerLayout(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) => ghDatePickerPosition(anchor: anchor, popover: childSize, viewport: size);

  @override
  bool shouldRelayout(_DatePickerLayout oldDelegate) => oldDelegate.anchor != anchor;
}

Offset ghDatePickerPosition({required Rect anchor, required Size popover, required Size viewport}) {
  const gap = 8.0;
  const pad = 12.0;
  final spaceBelow = viewport.height - anchor.bottom - pad;
  final spaceAbove = anchor.top - pad;
  final openAbove = spaceBelow < popover.height && spaceAbove > spaceBelow;
  var top = openAbove ? anchor.top - popover.height - gap : anchor.bottom + gap;
  top = math.max(pad, math.min(top, viewport.height - popover.height - pad));
  final left = math.max(pad, math.min(anchor.left, viewport.width - popover.width - pad));
  return Offset(left, top);
}
