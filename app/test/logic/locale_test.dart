import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/i18n/i18n_controller.dart';
import 'package:godothub/logic/locale.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> useLanguage(String language, {bool rtlLayout = false}) => GhI18n.init(
  prefs: UiPrefsStore(MemoryUiPrefsBackend()),
  settingsLanguage: language,
  settingsRtlLayout: rtlLayout,
  systemLocales: const [Locale('en', 'US')],
);

void main() {
  final collation = jsonDecode(File('test/logic/fixtures/locale_compare.json').readAsStringSync()) as Map<String, dynamic>;
  final dates = jsonDecode(File('test/logic/fixtures/locale_dates.json').readAsStringSync()) as Map<String, dynamic>;

  setUpAll(initializeDateFormatting);
  tearDown(() => useLanguage('en-US'));

  group('ghLocaleCompare', () {
    test('sorts the fixture corpus exactly like Chromium localeCompare', () {
      final expected = (collation['sorted'] as List).cast<String>();
      final shuffled = [...expected.reversed];
      shuffled.sort(ghLocaleCompare);
      expect(shuffled, expected);
    });

    test('matches every fixture pair sign', () {
      final mismatches = <String>[];
      for (final pair in collation['pairs'] as List) {
        final a = pair[0] as String;
        final b = pair[1] as String;
        final actual = ghLocaleCompare(a, b).sign;
        if (actual != pair[2]) {
          mismatches.add('${jsonEncode(a)} vs ${jsonEncode(b)}: expected ${pair[2]}, got $actual');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('orders case and accents like ICU root', () {
      final words = ['b', 'A', 'á', 'a', 'Á', 'B', 'ab', 'Ab', 'aB'];
      words.sort(ghLocaleCompare);
      expect(words, ['a', 'A', 'á', 'Á', 'ab', 'aB', 'Ab', 'b', 'B']);
      expect(ghLocaleCompare('a', 'a'), 0);
      expect(ghLocaleCompare('Project 10', 'Project 9'), -1);
      expect(ghLocaleCompare('a b', 'a_b'), -1);
      expect(ghLocaleCompare('a_b', 'a-b'), -1);
      expect(ghLocaleCompare('a-b', 'ab'), -1);
    });
  });

  group('ui locale and direction', () {
    test('uiLocale follows the app language', () async {
      await useLanguage('fr-FR');
      expect(uiLocale(), 'fr-FR');
      expect(formatLocaleDate(DateTime(2026, 1, 5)), '05/01/2026');
      await useLanguage('en-US');
      expect(uiLocale(), 'en-US');
      expect(formatLocaleDate(DateTime(2026, 1, 5)), '1/5/2026');
    });

    test('mirrorUiSide flips only when the layout is RTL', () async {
      await useLanguage('ar-MA');
      expect(isRtl(), isFalse);
      expect(mirrorUiSide(GhSide.left), GhSide.left);
      await useLanguage('ar-MA', rtlLayout: true);
      expect(isRtl(), isTrue);
      expect(mirrorUiSide(GhSide.left), GhSide.right);
      expect(mirrorUiSide(GhSide.right), GhSide.left);
      expect(mirrorUiSide(GhSide.top), GhSide.top);
      await useLanguage('en-US', rtlLayout: true);
      expect(isRtl(), isFalse);
      expect(mirrorSide(GhSide.left, TextDirection.rtl), GhSide.right);
    });

    test('UTC instants are formatted in local time like Date.toLocale*', () {
      final local = DateTime(2026, 3, 9, 23, 30);
      expect(formatLocaleDateTime(local.toUtc(), null, 'en-US'), formatLocaleDateTime(local, null, 'en-US'));
      expect(formatLocaleDate(local.toUtc(), null, 'en-US'), '3/9/2026');
    });

    test('option combinations', () {
      final d = DateTime(2026, 1, 5, 15, 4, 5);
      expect(formatLocaleDate(d, const GhDateFormatOptions(day: GhDatePart.twoDigit, month: GhDatePart.twoDigit, year: GhDatePart.numeric), 'en-US'), '01/05/2026');
      expect(formatLocaleDate(d, const GhDateFormatOptions(month: GhDatePart.long, year: GhDatePart.numeric), 'en-US'), 'January 2026');
      expect(formatLocaleDate(d, const GhDateFormatOptions(day: GhDatePart.numeric, month: GhDatePart.long), 'en-US'), 'January 5');
      expect(formatLocaleDate(d, const GhDateFormatOptions(weekday: GhDatePart.long, day: GhDatePart.numeric, month: GhDatePart.long, year: GhDatePart.numeric), 'en-US'), 'Monday, January 5, 2026');
      expect(formatLocaleDate(d, const GhDateFormatOptions(hour: GhDatePart.numeric, minute: GhDatePart.twoDigit), 'en-US'), '1/5/2026, 3:04 PM');
      expect(formatLocaleDateTime(d, const GhDateFormatOptions(hour: GhDatePart.numeric, minute: GhDatePart.twoDigit), 'en-US'), '3:04 PM');
      expect(formatLocaleDateTime(d, const GhDateFormatOptions(), 'en-US'), '1/5/2026, 3:04:05 PM');
      expect(formatLocaleDateTime(d, const GhDateFormatOptions(day: GhDatePart.numeric, month: GhDatePart.short), 'en-US'), 'Jan 5');
    });
  });

  group('dates', () {
    final points = [for (final d in (dates['dates'] as List)) DateTime(d[0], d[1] + 1, d[2], d[3], d[4], d[5])];
    final options = <String, GhDateFormatOptions?>{
      'default': null,
      'ymmmd': const GhDateFormatOptions(year: GhDatePart.numeric, month: GhDatePart.short, day: GhDatePart.numeric),
      'weekdayShort': const GhDateFormatOptions(weekday: GhDatePart.short),
      'weekdayLong': const GhDateFormatOptions(weekday: GhDatePart.long),
      'monthShort': const GhDateFormatOptions(month: GhDatePart.short),
    };

    for (final entry in (dates['locales'] as Map<String, dynamic>).entries) {
      final expected = entry.value as Map<String, dynamic>;
      for (final option in options.entries) {
        test('${entry.key} ${option.key} matches Chromium', () {
          expect([for (final d in points) formatLocaleDate(d, option.value, entry.key)], expected[option.key]);
        });
      }
      test('${entry.key} dateTime matches Chromium', () {
        expect([for (final d in points) formatLocaleDateTime(d, null, entry.key)], expected['dateTime']);
      });
    }
  });
}
