import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/export_template_catalog.dart';
import 'package:godothub/src/rust/api/types.dart';

import 'logic_fixtures.dart';

void main() {
  setUp(clearTemplateCatalog);

  test('cache and read back', () {
    expect(getCachedTemplateOptions('4.3'), isNull);
    final options = [templateOption('web', [])];
    cacheTemplateOptions('4.3', options);
    expect(getCachedTemplateOptions('4.3'), same(options));
  });

  test('setTemplateFilesInstalled updates named files and recomputes option.installed', () {
    cacheTemplateOptions('4.3', [
      templateOption('windows', [templateFile('a'), templateFile('b')]),
      templateOption('web', [templateFile('c', installed: true)], installed: true),
    ]);
    setTemplateFilesInstalled('4.3', ['a', 'zzz'], true);
    var options = getCachedTemplateOptions('4.3')!;
    expect([for (final f in options[0].files) f.installed], [true, false]);
    expect(options[0].installed, isFalse);
    expect(options[1].installed, isTrue);
    setTemplateFilesInstalled('4.3', ['b'], true);
    expect(getCachedTemplateOptions('4.3')![0].installed, isTrue);
    setTemplateFilesInstalled('4.3', null, false);
    options = getCachedTemplateOptions('4.3')!;
    expect([for (final o in options) o.installed], [false, false]);
    expect([for (final o in options) for (final f in o.files) f.installed], [false, false, false]);
    expect(options[0].files[0].sizeBytes, BigInt.one);
  });

  test('setTemplateFilesInstalled ignores unknown tags', () {
    setTemplateFilesInstalled('nope', null, true);
    expect(getCachedTemplateOptions('nope'), isNull);
  });

  test('empty option counts as installed after an update, like Array.every', () {
    cacheTemplateOptions('t', [templateOption('icu', [])]);
    setTemplateFilesInstalled('t', null, false);
    expect(getCachedTemplateOptions('t')!.single.installed, isTrue);
  });

  test('loadTemplateOptions shares in-flight requests per tag and refresh flag, then caches', () async {
    final calls = <String>[];
    final completers = <String, Completer<List<TemplateOption>>>{};
    Future<List<TemplateOption>> fetch(String tag, bool refresh) {
      calls.add('$tag:$refresh');
      return (completers['$tag:$refresh'] = Completer()).future;
    }

    final a = loadTemplateOptions('4.3', fetch: fetch);
    final b = loadTemplateOptions('4.3', fetch: fetch);
    final c = loadTemplateOptions('4.3', refresh: true, fetch: fetch);
    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
    expect(calls, ['4.3:false', '4.3:true']);
    final options = [templateOption('web', [])];
    completers['4.3:false']!.complete(options);
    expect(await a, same(options));
    expect(getCachedTemplateOptions('4.3'), same(options));
    final again = loadTemplateOptions('4.3', fetch: fetch);
    expect(identical(again, a), isFalse);
    expect(calls, ['4.3:false', '4.3:true', '4.3:false']);
  });

  test('failed loads are not cached and can be retried', () async {
    var attempts = 0;
    Future<List<TemplateOption>> fetch(String tag, bool refresh) async {
      attempts++;
      throw StateError('offline');
    }

    await expectLater(loadTemplateOptions('x', fetch: fetch), throwsStateError);
    await expectLater(loadTemplateOptions('x', fetch: fetch), throwsStateError);
    expect(attempts, 2);
    expect(getCachedTemplateOptions('x'), isNull);
  });
}
