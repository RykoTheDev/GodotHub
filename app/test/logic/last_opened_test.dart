import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/last_opened.dart';

String iso(DateTime local) => local.toUtc().toIso8601String();

void main() {
  test('format ids and parsing defaults', () {
    expect(LastOpenedTimeFormat.parse('24h'), LastOpenedTimeFormat.h24);
    expect(LastOpenedTimeFormat.parse('12h'), LastOpenedTimeFormat.h12);
    expect(LastOpenedTimeFormat.parse('weird'), LastOpenedTimeFormat.h12);
    expect(LastOpenedDateFormat.parse('YYYY-MM-DD'), LastOpenedDateFormat.yyyyMmDd);
    expect(LastOpenedDateFormat.parse('MM-DD-YYYY'), LastOpenedDateFormat.mmDdYyyy);
    expect(LastOpenedDateFormat.parse(null), LastOpenedDateFormat.ddMmYyyy);
  });

  test('formatTime', () {
    expect(formatTime(DateTime(2026, 1, 5, 0, 7), LastOpenedTimeFormat.h12), '12:07 AM');
    expect(formatTime(DateTime(2026, 1, 5, 9, 30), LastOpenedTimeFormat.h12), '9:30 AM');
    expect(formatTime(DateTime(2026, 1, 5, 12, 0), LastOpenedTimeFormat.h12), '12:00 PM');
    expect(formatTime(DateTime(2026, 1, 5, 23, 59), LastOpenedTimeFormat.h12), '11:59 PM');
    expect(formatTime(DateTime(2026, 1, 5, 7, 5), LastOpenedTimeFormat.h24), '07:05');
    expect(formatTime(DateTime(2026, 1, 5, 7, 5).toUtc(), LastOpenedTimeFormat.h24), '07:05');
  });

  test('formatDate', () {
    final date = DateTime(2026, 3, 9);
    expect(formatDate(date, LastOpenedDateFormat.ddMmYyyy), '09-03-2026');
    expect(formatDate(date, LastOpenedDateFormat.mmDdYyyy), '03-09-2026');
    expect(formatDate(date, LastOpenedDateFormat.yyyyMmDd), '2026-03-09');
    expect(formatDate(date.toUtc(), LastOpenedDateFormat.yyyyMmDd), '2026-03-09');
  });

  test('formatLastOpened shows time today and date otherwise', () {
    final now = DateTime(2026, 3, 9, 18);
    expect(formatLastOpened(null, now: now), isNull);
    expect(formatLastOpened('', now: now), isNull);
    expect(formatLastOpened('garbage', now: now), isNull);
    expect(formatLastOpened(iso(DateTime(2026, 3, 9, 14, 5)), now: now), '2:05 PM');
    expect(
      formatLastOpened(iso(DateTime(2026, 3, 9, 14, 5)), timeFormat: LastOpenedTimeFormat.h24, now: now),
      '14:05',
    );
    expect(formatLastOpened(iso(DateTime(2026, 3, 8, 23, 59)), now: now), '08-03-2026');
    expect(
      formatLastOpened(iso(DateTime(2025, 12, 31, 1)), dateFormat: LastOpenedDateFormat.yyyyMmDd, now: now),
      '2025-12-31',
    );
    expect(formatLastOpened(iso(DateTime.now())), isNot(contains('-')));
  });

  test('parseJsDate follows JavaScript Date parsing for ISO strings', () {
    expect(parseJsDate('2026-11-11T10:00:00.123456789+00:00')?.millisecondsSinceEpoch, 1794391200123);
    expect(parseJsDate('2026-11-11')?.millisecondsSinceEpoch, 1794355200000);
    expect(parseJsDate('2026-11')?.millisecondsSinceEpoch, DateTime.utc(2026, 11).millisecondsSinceEpoch);
    expect(parseJsDate('2026')?.millisecondsSinceEpoch, DateTime.utc(2026).millisecondsSinceEpoch);
    expect(parseJsDate('2026-11-11T10:00:00')?.millisecondsSinceEpoch, DateTime(2026, 11, 11, 10).millisecondsSinceEpoch);
    expect(parseJsDate('2026-11-11 10:00:00')?.millisecondsSinceEpoch, DateTime(2026, 11, 11, 10).millisecondsSinceEpoch);
    expect(parseJsDate('2026-11-11T12:00:00+02:00')?.millisecondsSinceEpoch, 1794391200000);
    expect(parseJsDate('20261111'), isNull);
    expect(parseJsDate('2026-13-01'), isNull);
    expect(parseJsDate('nope'), isNull);
    expect(parseJsDate(null), isNull);
    expect(jsTimeOf('2026-11-11'), 1794355200000);
  });
}
