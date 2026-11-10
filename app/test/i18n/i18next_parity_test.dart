import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/i18n/i18n.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/i18next_resolution.json').readAsStringSync()) as Map<String, dynamic>;
  final counts = (fixture['counts'] as List).cast<num>();
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();
  final results = (fixture['results'] as Map<String, dynamic>);

  setUpAll(registerI18nextPluralRules);

  for (final entry in results.entries) {
    test('${entry.key} resolves every en-US key like i18next ${fixture['i18next']}', () {
      final locale = ghAppLocaleFor(entry.key)!;
      final translations = LocaleSettings.instance.translationMap[locale]!;
      final expected = entry.value as List;
      final failures = <String>[];
      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final key = '${c['ns']}:${c['key']}';
        final vars = (c['vars'] as Map).cast<String, Object?>();
        if (c['plural'] == true) {
          for (var j = 0; j < counts.length; j++) {
            final actual = ghTr(key, count: counts[j], args: vars, translations: translations);
            final want = (expected[i] as List)[j];
            if (actual != want) failures.add('$key count=${counts[j]}: got "$actual" want "$want"');
          }
        } else {
          final actual = ghTr(key, args: vars, translations: translations);
          if (actual != expected[i]) failures.add('$key: got "$actual" want "${expected[i]}"');
        }
      }
      if (failures.isNotEmpty) File('build/i18n_failures_${entry.key}.txt').writeAsStringSync(failures.join('\n---\n'));
      expect(failures, isEmpty, reason: failures.take(15).join('\n'));
    });
  }
}
