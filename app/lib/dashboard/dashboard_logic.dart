import '../logic/last_opened.dart';
import '../logic/locale.dart';
import '../src/rust/api/types.dart';

enum ActivityRange {
  daily('daily', 24),
  weekly('weekly', 7),
  monthly('monthly', 30),
  yearly('yearly', 12);

  const ActivityRange(this.id, this.bars);

  final String id;
  final int bars;
}

String greetingKey(int hour) {
  if (hour >= 5 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 21) return 'evening';
  return 'night';
}

String weekdayName(int weekday) => formatLocaleDate(DateTime(2026, 1, 5 + weekday), const GhDateFormatOptions(weekday: GhDatePart.long));

DateTime? _keyDate(String key) {
  final parts = key.split('-');
  if (parts.length < 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = parts.length > 2 ? int.tryParse(parts[2].substring(0, parts[2].length.clamp(0, 2))) : 1;
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String activityLabel(ActivityRange range, String key, LastOpenedTimeFormat timeFormat) {
  if (range == ActivityRange.daily) {
    final hour = key.length >= 13 ? int.tryParse(key.substring(11, 13)) ?? 0 : 0;
    if (timeFormat == LastOpenedTimeFormat.h24) return hour.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'p' : 'a';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12$suffix';
  }
  final date = _keyDate(key);
  if (date == null) return key;
  return switch (range) {
    ActivityRange.yearly => formatLocaleDate(date, const GhDateFormatOptions(month: GhDatePart.short)),
    ActivityRange.weekly => formatLocaleDate(date, const GhDateFormatOptions(weekday: GhDatePart.short)),
    _ => '${date.day}',
  };
}

int _openedMs(Project p) => jsTimeOf(p.lastOpened) ?? 0;

List<Project> recentProjects(List<Project> projects) {
  final list = [
    for (final p in projects)
      if (p.lastOpened != null && p.lastOpened!.isNotEmpty) p,
  ]..sort((a, b) => _openedMs(b).compareTo(_openedMs(a)));
  return list.take(6).toList();
}

List<Project> pinnedProjects(List<Project> projects) => projects.where((p) => p.pinned).take(6).toList();

List<Project> topProjectsByTime(List<Project> projects) {
  final list = [
    for (final p in projects)
      if (p.totalTimeSeconds > BigInt.zero) p,
  ]..sort((a, b) => b.totalTimeSeconds.compareTo(a.totalTimeSeconds));
  return list.take(6).toList();
}

int totalProjectMs(List<Project> projects) => projects.fold(0, (sum, p) => sum + p.totalTimeSeconds.toInt() * 1000);

int? monthDeltaPercent(TimeInsights? insights) {
  if (insights == null || insights.lastMonthSeconds <= BigInt.zero) return null;
  final last = insights.lastMonthSeconds.toDouble();
  return ((insights.thisMonthSeconds.toDouble() - last) / last * 100 + 0.5).floor();
}

String dashboardDisplayName(String? customName, String? osName) {
  final name = (customName?.isNotEmpty ?? false) ? customName! : (osName ?? '');
  return name.length > 40 ? name.substring(0, 40) : name;
}
