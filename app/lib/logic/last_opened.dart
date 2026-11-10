enum LastOpenedTimeFormat {
  h12('12h'),
  h24('24h');

  const LastOpenedTimeFormat(this.id);

  final String id;

  static LastOpenedTimeFormat parse(String? id) => id == h24.id ? h24 : h12;
}

enum LastOpenedDateFormat {
  ddMmYyyy('DD-MM-YYYY'),
  mmDdYyyy('MM-DD-YYYY'),
  yyyyMmDd('YYYY-MM-DD');

  const LastOpenedDateFormat(this.id);

  final String id;

  static LastOpenedDateFormat parse(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return ddMmYyyy;
  }
}

final _dateOnly = RegExp(r'^([+-]\d{6}|\d{4})(?:-(\d{2})(?:-(\d{2}))?)?$');
final _dateTime = RegExp(r'^([+-]\d{6}|\d{4})-\d{2}-\d{2}[T ]\d{2}:\d{2}');

DateTime? parseJsDate(String? value) {
  if (value == null) return null;
  final text = value.trim();
  final dateOnly = _dateOnly.firstMatch(text);
  if (dateOnly != null) {
    final year = int.parse(dateOnly[1]!);
    final month = int.parse(dateOnly[2] ?? '1');
    final day = int.parse(dateOnly[3] ?? '1');
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime.utc(year, month, day);
  }
  if (!_dateTime.hasMatch(text)) return null;
  return DateTime.tryParse(text);
}

int? jsTimeOf(String? value) => parseJsDate(value)?.millisecondsSinceEpoch;

String _pad2(int n) => n < 10 ? '0$n' : '$n';

String formatTime(DateTime date, LastOpenedTimeFormat timeFormat) {
  final local = date.toLocal();
  var hours = local.hour;
  final minutes = _pad2(local.minute);
  if (timeFormat == LastOpenedTimeFormat.h24) {
    return '${_pad2(hours)}:$minutes';
  }
  final suffix = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  if (hours == 0) hours = 12;
  return '$hours:$minutes $suffix';
}

String formatDate(DateTime date, LastOpenedDateFormat dateFormat) {
  final local = date.toLocal();
  final day = _pad2(local.day);
  final month = _pad2(local.month);
  final year = local.year;
  return switch (dateFormat) {
    LastOpenedDateFormat.mmDdYyyy => '$month-$day-$year',
    LastOpenedDateFormat.yyyyMmDd => '$year-$month-$day',
    LastOpenedDateFormat.ddMmYyyy => '$day-$month-$year',
  };
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String? formatLastOpened(
  String? lastOpened, {
  LastOpenedTimeFormat timeFormat = LastOpenedTimeFormat.h12,
  LastOpenedDateFormat dateFormat = LastOpenedDateFormat.ddMmYyyy,
  DateTime? now,
}) {
  if (lastOpened == null || lastOpened.isEmpty) return null;
  final date = parseJsDate(lastOpened);
  if (date == null) return null;
  final local = date.toLocal();
  return _isSameDay(local, (now ?? DateTime.now()).toLocal())
      ? formatTime(local, timeFormat)
      : formatDate(local, dateFormat);
}
