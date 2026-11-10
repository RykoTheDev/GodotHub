import 'dart:convert';
import 'dart:io';

import 'common.dart';

class _NamespaceResult {
  _NamespaceResult(this.enCount, this.missing, this.extra, this.untranslated);

  final int enCount;
  final List<String> missing;
  final List<String> extra;
  final List<String> untranslated;

  int get translated => enCount - missing.length - untranslated.length;
  double get pct => enCount > 0 ? translated / enCount * 100 : 100;
}

void main(List<String> args) {
  final jsonMode = args.contains('--json');
  final mdMode = args.contains('--md');
  final missingOnly = args.contains('--missing');
  final listMode = args.contains('--list');
  final checkValues = args.contains('--check-values');
  final filter = args.where((a) => !a.startsWith('--')).toList();

  if (listMode) {
    stdout.writeln(paint('\n  Available locales:\n', bold));
    for (final locale in localeNames()) {
      final tag = locale == sourceLocale ? paint(' (source)', '$green$dim') : '';
      stdout.writeln('    ${paint(locale, bold)}$tag');
    }
    stdout.writeln('');
    return;
  }

  final namespaces = namespaceNames();
  final all = localeNames().where((l) => l != sourceLocale).toList();
  final invalid = filter.where((l) => !all.contains(l)).toList();
  if (invalid.isNotEmpty) {
    stderr.writeln(paint('\n  Unknown locale: ${invalid.join(', ')}', red));
    stderr.writeln(paint('  Available: ${all.join(', ')}\n', dim));
    exitCode = 1;
    return;
  }
  final locales = filter.isEmpty ? all : filter;

  final results = <String, Map<String, _NamespaceResult>>{};
  var overallMissing = 0;
  var overallTotal = 0;
  var overallUntranslated = 0;
  for (final locale in locales) {
    final perNs = results[locale] = {};
    for (final ns in namespaces) {
      final enData = readLocaleFile(sourceLocale, ns);
      if (enData == null) continue;
      final en = flatten(enData);
      final localData = readLocaleFile(locale, ns);
      final local = localData == null ? null : flatten(localData);
      final missing = en.keys.where((k) => local == null || !local.containsKey(k)).toList();
      final extra = local == null ? <String>[] : local.keys.where((k) => !en.containsKey(k)).toList();
      final untranslated = checkValues && local != null
          ? en.keys.where((k) => _truthy(local[k]) && _truthy(en[k]) && local[k] == en[k]).toList()
          : <String>[];
      perNs[ns] = _NamespaceResult(en.length, missing, extra, untranslated);
      overallMissing += missing.length;
      overallTotal += en.length;
      overallUntranslated += untranslated.length;
    }
  }

  int localeTotal(String l) => results[l]!.values.fold(0, (s, r) => s + r.enCount);
  int localeMissing(String l) => results[l]!.values.fold(0, (s, r) => s + r.missing.length);
  int localeExtra(String l) => results[l]!.values.fold(0, (s, r) => s + r.extra.length);
  double localePct(String l) => localeTotal(l) > 0 ? (localeTotal(l) - localeMissing(l)) / localeTotal(l) * 100 : 100;

  if (jsonMode) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({
      'locales': locales,
      'results': {
        for (final l in locales)
          l: {
            'namespaces': {
              for (final e in results[l]!.entries)
                e.key: {
                  'enCount': e.value.enCount,
                  'translated': e.value.translated,
                  'missing': e.value.missing,
                  'extra': e.value.extra,
                  'untranslated': e.value.untranslated,
                  'pct': e.value.pct,
                },
            },
            'totalKeys': localeTotal(l),
            'missingKeys': localeMissing(l),
            'extraKeys': localeExtra(l),
            'untranslatedKeys': results[l]!.values.fold(0, (s, r) => s + r.untranslated.length),
          },
      },
      'overallMissing': overallMissing,
      'overallTotal': overallTotal,
    }));
    exitCode = overallMissing > 0 ? 1 : 0;
    return;
  }

  if (mdMode) {
    stdout.writeln(filter.isNotEmpty ? '## Key Sync Status - ${filter.join(', ')}\n' : '## Key Sync Status\n');
    if (locales.length > 1) {
      stdout.writeln('| Locale | Progress | Missing | Extra |');
      stdout.writeln('|--------|----------|---------|-------|');
    }
    for (final l in locales) {
      final present = localeTotal(l) - localeMissing(l);
      final pct = localePct(l);
      if (locales.length > 1) {
        stdout.writeln('| $l | ${pct.toStringAsFixed(0)}% ($present/${localeTotal(l)}) | ${localeMissing(l)} | ${localeExtra(l)} |');
      } else {
        stdout.writeln('**$l** - ${pct.toStringAsFixed(0)}% ($present/${localeTotal(l)} keys)\n');
        for (final e in results[l]!.entries) {
          if (e.value.missing.isEmpty && e.value.extra.isEmpty) continue;
          stdout.writeln('**${e.key}.json** (${e.value.pct.toStringAsFixed(0)}%)');
          if (e.value.missing.isNotEmpty) stdout.writeln('- Missing (${e.value.missing.length}): ${e.value.missing.map((k) => '`$k`').join(', ')}');
          if (e.value.extra.isNotEmpty) stdout.writeln('- Extra (${e.value.extra.length}): ${e.value.extra.map((k) => '`$k`').join(', ')}');
        }
        stdout.writeln('');
      }
    }
    if (locales.length > 1) {
      stdout.writeln(
          '\n**Total:** ${overallTotal - overallMissing}/$overallTotal keys present (${((overallTotal - overallMissing) / overallTotal * 100).toStringAsFixed(1)}%)');
    }
    exitCode = overallMissing > 0 ? 1 : 0;
    return;
  }

  final single = locales.length == 1;
  final valuesTag = checkValues ? ' (checking values)' : '';
  stdout.writeln('');
  stdout.writeln(paint(single ? '  ${locales.first}  ${localePct(locales.first).toStringAsFixed(0)}% keys present$valuesTag' : '  Key Sync Status$valuesTag', '$cyan$bold'));
  stdout.writeln('');
  final width = locales.fold(0, (w, l) => l.length > w ? l.length : w);
  for (final l in locales) {
    final pct = localePct(l);
    final status = pct >= 100
        ? paint('Complete', '$green$bold')
        : paint('${pct.toStringAsFixed(0)}%', pct >= 80 ? '$yellow$bold' : '$red$bold');
    stdout.writeln('  ${paint(l.padRight(width), bold)}  $status');
  }
  stdout.writeln('');
  stdout.writeln('  ${paint('Total:', bold)} ${paint('${overallTotal - overallMissing}', green)}/$overallTotal keys present');
  if (overallUntranslated > 0) {
    stdout.writeln('  ${paint('Note:', yellow)} ${paint('$overallUntranslated', yellow)} keys still have identical English values (not translated)');
  }
  stdout.writeln('');
  for (final l in locales) {
    final issues = results[l]!.values.any((r) => r.missing.isNotEmpty || r.extra.isNotEmpty);
    if (!single && !issues) continue;
    stdout.writeln(paint('  $l/', bold));
    for (final e in results[l]!.entries) {
      final r = e.value;
      if (missingOnly && r.missing.isEmpty) continue;
      if (!single && r.missing.isEmpty && r.extra.isEmpty) continue;
      stdout.writeln('    ${e.key}.json ${r.pct >= 100 ? paint('ok', green) : '${r.pct.toStringAsFixed(0)}%'} ${paint('(${r.translated}/${r.enCount})', dim)}');
      if (r.missing.isNotEmpty) stdout.writeln('      ${paint('Missing:', red)} ${r.missing.take(8).join(', ')}${r.missing.length > 8 ? ' ... and ${r.missing.length - 8} more' : ''}');
      if (r.untranslated.isNotEmpty) {
        stdout.writeln('      ${paint('Untranslated:', yellow)} ${r.untranslated.take(8).join(', ')}${r.untranslated.length > 8 ? ' ... and ${r.untranslated.length - 8} more' : ''}');
      }
      if (r.extra.isNotEmpty && !missingOnly) stdout.writeln('      ${paint('Extra:', yellow)} ${r.extra.take(5).join(', ')}${r.extra.length > 5 ? ' ... and ${r.extra.length - 5} more' : ''}');
    }
    stdout.writeln('');
  }
  if (overallMissing > 0) {
    stdout.writeln(paint('  Copy the missing keys from $sourceLocale/ to each locale, translate the values (keep keys identical), then run this check again.', bold));
  } else {
    stdout.writeln(paint('  All checked locales have all keys present.', '$green$bold'));
  }
  stdout.writeln('');
  exitCode = overallMissing > 0 ? 1 : 0;
}

bool _truthy(Object? value) => value != null && value != '' && value != false && value != 0;
