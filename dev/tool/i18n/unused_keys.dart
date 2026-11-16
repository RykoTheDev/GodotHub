import 'dart:convert';
import 'dart:io';

import 'common.dart';

const _annotationLimit = 10;
final _pluralSuffix = RegExp(r'_(one|other|zero|two|few|many)$');

class _Key {
  _Key(this.key, this.line);

  final String key;
  final int line;
}

List<_Key> _collectKeys(File file) {
  final raw = file.readAsStringSync();
  final lines = raw.split(RegExp(r'\r?\n'));
  final keys = <_Key>[];
  void walk(Map<String, Object?> data, String prefix) {
    for (final entry in data.entries) {
      final full = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value is Map) {
        walk(value.cast<String, Object?>(), full);
      } else {
        keys.add(_Key(full, lines.indexWhere((l) => l.contains('"${entry.key}":')) + 1));
      }
    }
  }

  walk((jsonDecode(raw) as Map).cast<String, Object?>(), '');
  return keys;
}

Iterable<File> _sourceFiles(Directory dir, bool Function(String path) include, bool Function(String path) skip) sync* {
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    final path = entity.path.replaceAll('\\', '/');
    if (entity is! File || skip(path) || !include(path)) continue;
    yield entity;
  }
}

void main(List<String> args) {
  final jsonMode = args.contains('--json');
  final strict = args.contains('--strict');
  final flutter = args.contains('--flutter');
  final annotate = !jsonMode && Platform.environment.containsKey('GITHUB_ACTIONS');

  final namespaces = <String, List<_Key>>{
    for (final ns in namespaceNames()) ns: _collectKeys(File('$localesPath/$sourceLocale/$ns.json')),
  };

  final files = flutter
      ? _sourceFiles(
          Directory('$repoRoot/app/lib'),
          (p) => p.endsWith('.dart'),
          (p) => p.contains('/app/lib/i18n/') || p.contains('/app/lib/src/rust/'),
        ).toList()
      : _sourceFiles(
          Directory('$repoRoot/src'),
          (p) => p.endsWith('.ts') || p.endsWith('.tsx'),
          (p) => p.contains('/src/i18n/locales/') || p.endsWith('/src/i18n/types.ts'),
        ).toList();
  final source = files.map((f) => f.readAsStringSync()).join('\n');

  final literals = <String>{
    for (final m in RegExp('[\'"`]([A-Za-z0-9_:.]+)[\'"`]').allMatches(source)) m[1]!.split(':').last,
    if (flutter)
      for (final m in RegExp(r'\bt\.(?:changelog|common|dashboard|git|nav|onboarding|settings|todos|versions)\.([A-Za-z0-9_.]+)').allMatches(source))
        ...[m[1]!, m[1]!.replaceFirst(RegExp(r'_plural$'), '')],
  };
  final prefixes = <String>{
    for (final m in RegExp(r'`([A-Za-z0-9_]+_)\$\{').allMatches(source)) m[1]!,
    if (flutter)
      for (final m in RegExp(r"'([A-Za-z0-9_:]+_)\$").allMatches(source)) m[1]!.split(':').last,
  }.toList()
    ..sort();

  bool isUsed(String key) {
    if (literals.contains(key)) return true;
    if (literals.contains(key.replaceFirst(_pluralSuffix, ''))) return true;
    return prefixes.any(key.startsWith);
  }

  final unused = <String, List<_Key>>{};
  var total = 0;
  var scanned = 0;
  for (final entry in namespaces.entries) {
    scanned += entry.value.length;
    final dead = entry.value.where((k) => !isUsed(k.key)).toList();
    if (dead.isNotEmpty) {
      unused[entry.key] = dead;
      total += dead.length;
    }
  }

  if (jsonMode) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({
      'sourceLocale': sourceLocale,
      'scannedKeys': scanned,
      'scannedFiles': files.length,
      'dynamicPrefixes': prefixes,
      'unusedCount': total,
      'unused': {for (final e in unused.entries) e.key: e.value.map((k) => k.key).toList()},
    }));
    exitCode = strict && total > 0 ? 1 : 0;
    return;
  }

  stdout.writeln('');
  stdout.writeln(paint('  Unused i18n Keys${flutter ? ' (Flutter app)' : ''}', '$cyan$bold'));
  stdout.writeln('');
  stdout.writeln(paint('  Scanned $scanned $sourceLocale keys against ${files.length} source files', dim));
  stdout.writeln(paint('  Dynamic prefixes treated as used: ${prefixes.isEmpty ? 'none' : prefixes.join(', ')}', dim));
  stdout.writeln('');
  if (total == 0) {
    stdout.writeln(paint('  Every key is referenced somewhere.', green));
    stdout.writeln('');
    return;
  }
  var annotated = 0;
  for (final entry in unused.entries) {
    stdout.writeln('${paint('  ${entry.key}.json', bold)}${paint(' (${entry.value.length})', dim)}');
    for (final key in entry.value) {
      stdout.writeln('    ${paint('x', yellow)} ${key.key}${paint('  :${key.line}', dim)}');
      if (annotate && annotated < _annotationLimit) {
        stdout.writeln('::warning file=src/i18n/locales/$sourceLocale/${entry.key}.json,line=${key.line}::Unused i18n key "${key.key}"');
        annotated++;
      }
    }
    stdout.writeln('');
  }
  stdout.writeln(paint('  $total of $scanned keys look unreferenced', '$yellow$bold'));
  if (annotate && total > _annotationLimit) {
    stdout.writeln(paint('  Annotated the first $_annotationLimit, the rest are listed above', dim));
  }
  stdout.writeln('');
  exitCode = strict ? 1 : 0;
}
