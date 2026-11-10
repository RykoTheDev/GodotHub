import 'dart:io';

import 'common.dart';

void main(List<String> args) {
  final filter = args.where((a) => !a.startsWith('--')).firstOrNull;
  final onlySame = args.contains('--same');
  final onlyDiff = args.contains('--diff');
  final locales = localeNames().where((l) {
    final dir = Directory('$localesPath/$l');
    return dir.listSync().any((f) => f.path.endsWith('.json'));
  }).where((l) => filter == null || l == filter);

  var total = 0;
  for (final locale in locales) {
    final all = <String, List<(String, Object?)>>{};
    for (final ns in namespaceNames(locale)) {
      final data = readLocaleFile(locale, ns) ?? const {};
      for (final entry in data.entries) {
        all.putIfAbsent(entry.key, () => []).add(('$ns.json', entry.value));
      }
    }
    final same = <String, List<(String, Object?)>>{};
    final diff = <String, List<(String, Object?)>>{};
    for (final entry in all.entries) {
      if (entry.value.length <= 1) continue;
      final values = entry.value.map((e) => e.$2.toString()).toSet();
      (values.length == 1 ? same : diff)[entry.key] = entry.value;
    }
    if (same.isEmpty && diff.isEmpty) continue;
    stdout.writeln('\n${paint('=== $locale ===', bold)}');
    if (same.isNotEmpty && !onlyDiff) {
      stdout.writeln('\n  ${paint('Same-value duplicates (${same.length}):', yellow)}');
      for (final e in same.entries) {
        stdout.writeln('    ${paint(e.key, cyan)} → ${e.value.map((v) => v.$1).join(', ')}');
        total++;
      }
    }
    if (diff.isNotEmpty && !onlySame) {
      stdout.writeln('\n  ${paint('Different-value duplicates (${diff.length}):', red)}');
      for (final e in diff.entries) {
        stdout.writeln('    ${paint(e.key, cyan)}');
        for (final (file, value) in e.value) {
          final text = '$value';
          stdout.writeln('      $file: ${text.length > 60 ? '${text.substring(0, 57)}...' : text}');
        }
        total++;
      }
    }
  }

  if (total == 0) {
    stdout.writeln('\n${paint('No duplicate keys found.', green)}');
    return;
  }
  stdout.writeln('\n${paint('Total: $total duplicate key(s) found.', bold)}');
  exitCode = 1;
}
