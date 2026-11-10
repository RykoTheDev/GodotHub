import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/project_search.dart';

import 'logic_fixtures.dart';

void main() {
  group('parseProjectQuery', () {
    test('splits text, field filters and drops empty non-pinned filters', () {
      final q = parseProjectQuery('Foo tag:RPG  cat: pinned: ver:4. /sl', 37);
      expect(q.text, ['foo', 'ver:4.', '/sl']);
      expect(q.filters, const [
        ProjectSearchFilter(ProjectSearchField.tag, 'rpg'),
        ProjectSearchFilter(ProjectSearchField.pinned, ''),
      ]);
      expect(q.activeToken, isNull);
      expect(q.active, isTrue);
    });

    test('skips the slash token under the caret', () {
      final q = parseProjectQuery('/slash name:', 3);
      expect(q.text, isEmpty);
      expect(q.filters, isEmpty);
      expect(q.activeToken?.raw, '/slash');
      expect(q.activeToken?.start, 0);
      expect(q.activeToken?.end, 6);
      expect(q.activeToken?.field, isNull);
      expect(q.active, isFalse);
    });

    test('keeps unknown prefixes and leading colons as text and lowercases values', () {
      final q = parseProjectQuery('a:b :x PIN:No');
      expect(q.text, ['a:b', ':x']);
      expect(q.filters, const [ProjectSearchFilter(ProjectSearchField.pinned, 'no')]);
      expect(q.activeToken?.raw, 'PIN:No');
      expect(q.activeToken?.field, ProjectSearchField.pinned);
      expect(q.activeToken?.value, 'No');
    });

    test('empty input is inactive', () {
      final q = parseProjectQuery('', 0);
      expect(q.text, isEmpty);
      expect(q.active, isFalse);
      expect(q.activeToken, isNull);
    });

    test('dotted capital I lowercases with Dart rules and stays text', () {
      final q = parseProjectQuery('İ:x', 2);
      expect('İ'.toLowerCase(), 'i');
      expect(q.text, ['i:x']);
      expect(q.activeToken?.raw, 'İ:x');
    });

    test('every alias resolves', () {
      const aliases = {
        'name': ProjectSearchField.name,
        'tag': ProjectSearchField.tag,
        'tags': ProjectSearchField.tag,
        'category': ProjectSearchField.category,
        'cat': ProjectSearchField.category,
        'version': ProjectSearchField.version,
        'engine': ProjectSearchField.version,
        'path': ProjectSearchField.path,
        'folder': ProjectSearchField.path,
        'dir': ProjectSearchField.path,
        'pinned': ProjectSearchField.pinned,
        'pin': ProjectSearchField.pinned,
      };
      for (final entry in aliases.entries) {
        expect(parseProjectQuery('${entry.key.toUpperCase()}:X').filters.single, ProjectSearchFilter(entry.value, 'x'));
      }
    });
  });

  group('matchProject', () {
    final projects = [
      project(
        name: 'Space Shooter',
        tags: ['Arcade', 'shmup'],
        category: 'Games',
        godotVersion: '4.2.1-stable',
        path: 'C:/Dev/space',
      ),
      project(name: 'shooter', pinned: true, godotVersion: '3.5'),
      project(name: 'My_Shooter-Game', tags: [' rpg ', ''], godotVersion: '4.3 mono'),
    ];
    const expected = <String, List<int?>>{
      'shooter': [70, 120, 70],
      'shoot': [70, 90, 70],
      'game': [24, null, 70],
      'arcade': [30, null, null],
      'games': [24, null, null],
      '4.2': [20, null, null],
      '1': [20, null, null],
      'mono': [null, null, 20],
      'dev': [12, null, null],
      'pinned:': [null, 0, null],
      'pin:no': [0, null, 0],
      'pin:maybe': [null, 0, null],
      'tag:sh': [0, null, null],
      'version:4': [0, null, 0],
      'engine:stable': [0, null, null],
      'path:dev': [0, null, null],
      'cat:gam': [0, null, null],
      'name:my': [null, null, 0],
      'zzz': [null, null, null],
      'shooter space': [160, null, null],
      '': [0, 0, 0],
      'folder:/projects': [null, 0, 0],
    };
    for (final entry in expected.entries) {
      test('"${entry.key}" scores like the TypeScript port', () {
        final query = parseProjectQuery(entry.key);
        expect([for (final p in projects) matchProject(p, query)], entry.value);
      });
    }
  });

  test('replaceToken replaces the span and clamps like String.slice', () {
    final a = replaceToken('abc /sl def', (start: 4, end: 7), 'tag:');
    expect(a.value, 'abc tag: def');
    expect(a.caret, 8);
    final b = replaceToken('abc', (start: 5, end: 9), 'x');
    expect(b.value, 'abcx');
    expect(b.caret, 6);
    final token = parseProjectQuery('foo /ta', 7).activeToken!;
    expect(replaceToken('foo /ta', token.range, 'tag:').value, 'foo tag:');
  });

  test('collectTags trims, dedupes and sorts with localeCompare', () {
    final tags = collectTags([
      project(tags: ['b', 'A', 'a', ' a ', 'é', 'E', 'z', '10', '9', '']),
      project(tags: ['B', '_x']),
    ]);
    expect(tags, ['_x', '10', '9', 'a', 'A', 'b', 'B', 'E', 'é', 'z']);
  });

  test('collectVersions trims, dedupes and sorts descending with localeCompare', () {
    final versions = collectVersions([
      for (final v in ['4.3-stable', '4.10', '4.3 mono', ' 4.2.2-stable ', '', '3.x', '4.3-beta1', '4.10'])
        project(godotVersion: v),
    ]);
    expect(versions, ['4.3-stable', '4.3-beta1', '4.3 mono', '4.2.2-stable', '4.10', '3.x']);
  });
}
