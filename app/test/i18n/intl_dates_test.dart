import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/ui/overlays/date_picker.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/intl_dates.json').readAsStringSync()) as Map<String, dynamic>;
  final dates = [DateTime(2026, 1, 5), DateTime(2026, 11, 20), DateTime(2031, 12, 31)];

  setUpAll(initializeDateFormatting);

  for (final entry in (fixture['locales'] as Map<String, dynamic>).entries) {
    test('${entry.key} date parts match Chromium Intl (CLDR ${fixture['cldr']})', () {
      final expected = entry.value as Map<String, dynamic>;
      expect([for (final d in dates) ghFormatDate(d, entry.key)], expected['dates']);
      expect(ghMonthNames(entry.key), expected['months']);
      expect(ghWeekdayNames(entry.key), expected['weekdays']);
    });
  }
}
