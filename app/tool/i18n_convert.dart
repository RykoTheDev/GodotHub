import 'dart:convert';
import 'dart:io';

import 'package:godothub/i18n/plural_rules.dart';

const sourceLocale = 'en-US';
const pluralSuffixes = ['zero', 'one', 'two', 'few', 'many', 'other'];

final _interpolation = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

String get _repoRoot => File.fromUri(Platform.script).parent.parent.parent.path;

Directory get localesDir => Directory('$_repoRoot/src/i18n/locales');
Directory get outputDir => Directory('$_repoRoot/app/lib/i18n/json');

Map<String, dynamic> _read(File file) => jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

List<String> locales() =>
    localesDir.listSync().whereType<Directory>().map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last).toList()..sort();

List<String> namespaces() => Directory('${localesDir.path}/$sourceLocale')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'))
    .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
    .toList()
  ..sort();

String _normalize(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll(r'$', r'\$').replaceAllMapped(_interpolation, (m) => '{{${m[1]}}}');

String _pluralForm(String value) => _normalize(value).replaceAll('{{count}}', r'${count}');

Set<String> pluralBases(Map<String, dynamic> en) {
  return {
    for (final entry in en.entries)
      if (entry.value is String && entry.key.endsWith('_one')) entry.key.substring(0, entry.key.length - 4),
  };
}

String pluralKeyName(String base, Map<String, dynamic> en) => en.containsKey(base) ? '${base}_plural' : base;

String? _string(Map<String, dynamic>? map, String key) {
  final value = map?[key];
  return value is String ? value : null;
}

Map<String, String> pluralForms({
  required String base,
  required String language,
  required Map<String, dynamic> en,
  required Map<String, dynamic>? local,
}) {
  final forms = <String, String>{};
  final localZero = _string(local, '${base}_zero');
  if (localZero != null) {
    forms['zero'] = _pluralForm(localZero);
  }
  for (final category in cardinalCategories(language)) {
    final value = _string(local, '${base}_$category') ??
        _string(local, base) ??
        (category == 'zero' ? _string(en, '${base}_zero') : null) ??
        (category == 'one' ? _string(en, '${base}_one') : null) ??
        _string(en, '${base}_other') ??
        _string(en, base) ??
        base;
    forms[category] = _pluralForm(value);
  }
  return {for (final c in pluralSuffixes) if (forms.containsKey(c)) c: forms[c]!};
}

Map<String, dynamic> convertLevel({
  required Map<String, dynamic> en,
  required Map<String, dynamic>? local,
  required String language,
}) {
  final out = <String, dynamic>{};
  final bases = pluralBases(en);
  final emitted = <String>{};
  for (final entry in en.entries) {
    final key = entry.key;
    final suffix = pluralSuffixes.firstWhere((s) => key.endsWith('_$s'), orElse: () => '');
    final base = suffix.isEmpty ? null : key.substring(0, key.length - suffix.length - 1);
    if (base != null && bases.contains(base)) {
      if (emitted.add(base)) {
        out['${pluralKeyName(base, en)}(plural)'] = pluralForms(base: base, language: language, en: en, local: local);
      }
      final literal = _string(local, key);
      if (literal != null) {
        out[key] = _normalize(literal);
      }
      continue;
    }
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      final nested = local?[key];
      out[key] = convertLevel(en: value, local: nested is Map<String, dynamic> ? nested : null, language: language);
      continue;
    }
    final localValue = _string(local, key);
    if (localValue != null) {
      out[key] = _normalize(localValue);
    }
  }
  return out;
}

String _encode(Object value) => '${const JsonEncoder.withIndent('  ').convert(value)}\n';

Map<String, String> buildOutputs() {
  final outputs = <String, String>{};
  for (final ns in namespaces()) {
    final en = _read(File('${localesDir.path}/$sourceLocale/$ns.json'));
    for (final locale in locales()) {
      final file = File('${localesDir.path}/$locale/$ns.json');
      final local = file.existsSync() ? _read(file) : null;
      final converted = convertLevel(en: en, local: local, language: locale.split('-').first);
      outputs['$ns/${ns}_$locale.i18n.json'] = _encode(converted);
    }
  }
  return outputs;
}

void main(List<String> args) {
  final check = args.contains('--check');
  final outputs = buildOutputs();
  final drift = <String>[];
  for (final entry in outputs.entries) {
    final file = File('${outputDir.path}/${entry.key}');
    final current = file.existsSync() ? file.readAsStringSync().replaceAll('\r\n', '\n') : null;
    if (current == entry.value) {
      continue;
    }
    drift.add(entry.key);
    if (!check) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }
  final expected = outputs.keys.toSet();
  final stale = outputDir.existsSync()
      ? outputDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.i18n.json'))
          .map((f) => f.path.substring(outputDir.path.length + 1).replaceAll('\\', '/'))
          .where((p) => !expected.contains(p))
          .toList()
      : <String>[];
  if (check) {
    if (drift.isEmpty && stale.isEmpty) {
      stdout.writeln('Flutter locale files match src/i18n/locales (${outputs.length} files).');
      return;
    }
    stderr.writeln('Flutter locale files are out of date. Run: dart run tool/i18n_convert.dart && dart run slang');
    for (final path in [...drift, ...stale]) {
      stderr.writeln('  $path');
    }
    exitCode = 1;
    return;
  }
  for (final path in stale) {
    File('${outputDir.path}/$path').deleteSync();
  }
  stdout.writeln('Wrote ${drift.length} of ${outputs.length} locale files, removed ${stale.length}.');
}
