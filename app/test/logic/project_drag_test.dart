import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/project_drag.dart';
import 'package:godothub/src/rust/api/types.dart';

Project _p(String id, [String? category, bool pinned = false]) => Project(
  id: id,
  name: id,
  path: '/projects/$id',
  godotVersion: '4.3',
  createdAt: '2026-01-01',
  category: category,
  pinned: pinned,
  sortOrder: 0,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

Category _cat(String id, String name) =>
    Category(id: id, name: name, sortOrder: 0, color: '#5865f2', hidden: false, folders: const []);

const _prefixes = DroppablePrefixes(category: 'cat:');

final _projects = [_p('a', 'X'), _p('b', 'X'), _p('c', 'X'), _p('d', 'Y'), _p('e'), _p('f', '')];
final _categories = [_cat('x', 'X'), _cat('y', 'Y')];

ProjectDropResolution _drop(
  String activeId,
  String overId, {
  List<String>? activeIds,
  bool grouped = false,
  DropPlacement? placement,
  List<Project>? projects,
  DroppablePrefixes prefixes = _prefixes,
}) => resolveProjectDrop(
  ProjectDropInput(
    activeId: activeId,
    activeIds: activeIds,
    overId: overId,
    projects: projects ?? _projects,
    categories: _categories,
    grouped: grouped,
    prefixes: prefixes,
    placement: placement,
  ),
);

void main() {
  test('categoryKeyOf treats null and empty as uncategorized', () {
    expect(uncategorizedKey, '__uncategorized__');
    expect(categoryKeyOf(_p('a')), uncategorizedKey);
    expect(categoryKeyOf(_p('a', '')), uncategorizedKey);
    expect(categoryKeyOf(_p('a', 'Jam')), 'Jam');
  });

  group('kanbanColumnOrder', () {
    test('returns the same list when there are no categories', () {
      final projects = [_p('a', 'X'), _p('b')];
      expect(identical(kanbanColumnOrder(projects, const []), projects), isTrue);
    });

    test('orders by category, then unknown categories by first appearance, then uncategorized', () {
      final projects = [
        _p('p1', 'Y'),
        _p('p2', 'X'),
        _p('p3'),
        _p('p4', 'Z'),
        _p('p5', 'X'),
        _p('p6', ''),
        _p('p7', 'W'),
        _p('p8', 'Z'),
      ];
      expect(kanbanColumnOrder(projects, _categories).map((p) => p.id), ['p2', 'p5', 'p1', 'p4', 'p8', 'p7', 'p3', 'p6']);
    });

    test('a category listed twice repeats its projects', () {
      final projects = [_p('a', 'X'), _p('b')];
      expect(kanbanColumnOrder(projects, [_cat('1', 'X'), _cat('2', 'X')]).map((p) => p.id), ['a', 'a', 'b']);
    });
  });

  group('hasOnlyPinnedProjects', () {
    test('needs at least one member and every member pinned', () {
      final projects = [_p('a', 'X', true), _p('b', 'X', true), _p('c', 'Y', true), _p('d', 'Y'), _p('e', null, true), _p('f', '', true)];
      expect(hasOnlyPinnedProjects(projects, 'X'), isTrue);
      expect(hasOnlyPinnedProjects(projects, 'Y'), isFalse);
      expect(hasOnlyPinnedProjects(projects, 'Z'), isFalse);
      expect(hasOnlyPinnedProjects(projects, uncategorizedKey), isTrue);
      expect(hasOnlyPinnedProjects(const [], 'X'), isFalse);
    });
  });

  group('resolveProjectDrop ungrouped', () {
    test('dragging down lands after the target', () {
      expect(_drop('a', 'c'), const ProjectDropReorder(['b', 'c', 'a', 'd', 'e', 'f']));
    });

    test('dragging up lands before the target', () {
      expect(_drop('c', 'a'), const ProjectDropReorder(['c', 'a', 'b', 'd', 'e', 'f']));
    });

    test('explicit placement wins', () {
      expect(_drop('a', 'c', placement: DropPlacement.before), const ProjectDropReorder(['b', 'a', 'c', 'd', 'e', 'f']));
      expect(_drop('c', 'a', placement: DropPlacement.after), const ProjectDropReorder(['a', 'c', 'b', 'd', 'e', 'f']));
    });

    test('a drop that keeps the order is none', () {
      expect(_drop('a', 'b', placement: DropPlacement.before), const ProjectDropNone());
      expect(_drop('b', 'a', placement: DropPlacement.after), const ProjectDropNone());
    });

    test('invalid drops are none', () {
      expect(_drop('a', 'a'), const ProjectDropNone());
      expect(_drop('missing', 'b'), const ProjectDropNone());
      expect(_drop('a', 'missing'), const ProjectDropNone());
      expect(_drop('a', 'cat:y'), const ProjectDropNone());
      expect(_drop('a', 'b', activeIds: ['b', 'c']), const ProjectDropNone());
      expect(_drop('a', 'b', activeIds: ['zzz']), const ProjectDropNone());
    });

    test('multi-select keeps visible order and always lands before', () {
      expect(_drop('b', 'd', activeIds: ['b', 'a']), const ProjectDropReorder(['c', 'a', 'b', 'd', 'e', 'f']));
      expect(_drop('a', 'f', activeIds: ['c', 'a']), const ProjectDropReorder(['b', 'd', 'e', 'a', 'c', 'f']));
    });

    test('an empty selection falls back to the grabbed card', () {
      expect(_drop('a', 'c', activeIds: const []), const ProjectDropReorder(['b', 'c', 'a', 'd', 'e', 'f']));
    });

    test('a selection without the grabbed card still uses the grabbed card for placement', () {
      expect(_drop('a', 'c', activeIds: ['b']), const ProjectDropReorder(['a', 'c', 'b', 'd', 'e', 'f']));
    });

    test('ids shorter than the zone prefix are plain cards', () {
      expect(
        _drop('a', 'b', prefixes: const DroppablePrefixes(category: 'category-zone:')),
        const ProjectDropReorder(['b', 'a', 'c', 'd', 'e', 'f']),
      );
    });
  });

  group('resolveProjectDrop grouped', () {
    test('reordering within a category', () {
      expect(_drop('a', 'c', grouped: true), const ProjectDropReorder(['b', 'c', 'a']));
      expect(_drop('c', 'a', grouped: true), const ProjectDropReorder(['c', 'a', 'b']));
    });

    test('dropping on the own category zone moves to the end', () {
      expect(_drop('a', 'cat:x', grouped: true), const ProjectDropReorder(['b', 'c', 'a']));
      expect(_drop('c', 'cat:x', grouped: true), const ProjectDropNone());
    });

    test('dropping on another category zone moves to its end', () {
      expect(
        _drop('a', 'cat:y', grouped: true),
        const ProjectDropMove(activeIds: ['a'], categoryName: 'Y', destOrderedIds: ['d', 'a']),
      );
    });

    test('dropping on the uncategorized zone clears the category', () {
      expect(
        _drop('a', 'cat:uncategorized', grouped: true),
        const ProjectDropMove(activeIds: ['a'], categoryName: '', destOrderedIds: ['e', 'f', 'a']),
      );
      expect(_drop('e', 'cat:uncategorized', grouped: true), const ProjectDropReorder(['f', 'e']));
    });

    test('an unknown zone id is used as the category name', () {
      expect(
        _drop('a', 'cat:Z', grouped: true),
        const ProjectDropMove(activeIds: ['a'], categoryName: 'Z', destOrderedIds: ['a']),
      );
    });

    test('dropping on a card in another category lands before it', () {
      expect(
        _drop('a', 'd', grouped: true),
        const ProjectDropMove(activeIds: ['a'], categoryName: 'Y', destOrderedIds: ['a', 'd']),
      );
      expect(
        _drop('d', 'f', grouped: true),
        const ProjectDropMove(activeIds: ['d'], categoryName: '', destOrderedIds: ['e', 'd', 'f']),
      );
    });

    test('explicit placement after a card in another category', () {
      expect(
        _drop('a', 'e', grouped: true, placement: DropPlacement.after),
        const ProjectDropMove(activeIds: ['a'], categoryName: '', destOrderedIds: ['e', 'a', 'f']),
      );
    });

    test('a mixed selection moves in visible order', () {
      expect(
        _drop('d', 'b', grouped: true, activeIds: ['d', 'a']),
        const ProjectDropMove(activeIds: ['a', 'd'], categoryName: 'X', destOrderedIds: ['a', 'd', 'b', 'c']),
      );
    });

    test('an empty prefix turns every id into a zone', () {
      expect(
        _drop('a', 'd', grouped: true, prefixes: const DroppablePrefixes(category: '')),
        const ProjectDropMove(activeIds: ['a'], categoryName: 'd', destOrderedIds: ['a']),
      );
    });

    test('every project sharing the grabbed id travels together', () {
      final projects = [_p('a', 'X'), _p('b', 'X'), _p('a', 'X'), _p('c', 'X')];
      expect(_drop('a', 'c', grouped: true, projects: projects), const ProjectDropReorder(['b', 'a', 'a', 'c']));
    });
  });
}
