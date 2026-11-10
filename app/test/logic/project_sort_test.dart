import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/logic/project_sort.dart';
import 'package:godothub/src/rust/api/types.dart';

import '../ui/i18n_setup.dart';
import 'logic_fixtures.dart';

List<String> sortedNames(List<Project> projects, ProjectSortOption option, [int? now]) =>
    [for (final p in stableSorted(projects, comparatorFor(option, now)!)) p.name];

void main() {
  test('options keep the TypeScript order, values and label keys', () {
    expect([for (final o in ProjectSortOption.values) o.value], [
      'manual',
      'categories',
      'recent',
      'name_asc',
      'name_desc',
      'created_desc',
      'created_asc',
      'time_desc',
    ]);
    expect([for (final o in ProjectSortOption.values) o.labelKey], [
      'sort_manual',
      'sort_categories',
      'sort_recent',
      'sort_name_asc',
      'sort_name_desc',
      'sort_created_desc',
      'sort_created_asc',
      'sort_time_desc',
    ]);
    expect(ProjectSortOption.fromValue('time_desc'), ProjectSortOption.timeDesc);
    expect(ProjectSortOption.fromValue('nope'), isNull);
  });

  test('labels come from the common namespace', () async {
    await setUpTestI18n();
    for (final option in ProjectSortOption.values) {
      expect(option.label(), ghTr('common:${option.labelKey}'));
    }
  });

  test('manual and categories have no comparator', () {
    expect(comparatorFor(ProjectSortOption.manual), isNull);
    expect(comparatorFor(ProjectSortOption.categories), isNull);
  });

  test('recent sorts newest first, missing and invalid dates last and stable', () {
    final projects = [
      project(name: 'none'),
      project(name: 'old', lastOpened: '2025-01-01T00:00:00Z'),
      project(name: 'bad', lastOpened: 'not a date'),
      project(name: 'new', lastOpened: '2026-03-01T10:00:00.123456789+00:00'),
      project(name: 'dateOnly', lastOpened: '2026-03-01'),
      project(name: 'offset', lastOpened: '2026-03-01T12:00:00+02:00'),
    ];
    expect(sortedNames(projects, ProjectSortOption.recent), ['new', 'offset', 'dateOnly', 'old', 'none', 'bad']);
  });

  test('created sorts both ways', () {
    final projects = [
      project(name: 'b', createdAt: '2025-06-01T00:00:00Z'),
      project(name: 'a', createdAt: '2024-06-01T00:00:00Z'),
      project(name: 'c', createdAt: ''),
      project(name: 'd', createdAt: '2026-06-01T00:00:00Z'),
    ];
    expect(sortedNames(projects, ProjectSortOption.createdDesc), ['d', 'b', 'a', 'c']);
    expect(sortedNames(projects, ProjectSortOption.createdAsc), ['c', 'a', 'b', 'd']);
  });

  test('name sorts use localeCompare semantics', () {
    final projects = [for (final n in ['b', 'B', 'a', 'Á', 'A', '_x', '10', '9', 'é', 'e']) project(name: n)];
    expect(sortedNames(projects, ProjectSortOption.nameAsc), ['_x', '10', '9', 'a', 'A', 'Á', 'b', 'B', 'e', 'é']);
    expect(sortedNames(projects, ProjectSortOption.nameDesc), ['é', 'e', 'B', 'b', 'Á', 'A', 'a', '9', '10', '_x']);
  });

  test('time sorts by stored plus live session time', () {
    const now = 1000000;
    final projects = [
      project(name: 'stored', totalTimeSeconds: 100),
      project(name: 'live', totalTimeSeconds: 50, sessionStartedAtMs: now - 60000),
      project(name: 'idle'),
      project(name: 'future', sessionStartedAtMs: now + 5000),
    ];
    expect(sortedNames(projects, ProjectSortOption.timeDesc, now), ['live', 'stored', 'idle', 'future']);
  });

  test('liveSessionMs and effectiveTotalMs', () {
    expect(liveSessionMs(project(), 5000), 0);
    expect(liveSessionMs(project(sessionStartedAtMs: 0), 5000), 0);
    expect(liveSessionMs(project(sessionStartedAtMs: 1000), 5000), 4000);
    expect(liveSessionMs(project(sessionStartedAtMs: 9000), 5000), 0);
    expect(effectiveTotalMs(project(totalTimeSeconds: 3, sessionStartedAtMs: 1000), 5000), 7000);
    final start = DateTime.now().millisecondsSinceEpoch - 2000;
    expect(liveSessionMs(project(sessionStartedAtMs: start)), greaterThanOrEqualTo(2000));
  });

  test('stableSorted keeps input order for ties', () {
    final items = [for (var i = 0; i < 100; i++) (i % 3, i)];
    final sorted = stableSorted(items, (a, b) => a.$1 - b.$1);
    expect(sorted.where((e) => e.$1 == 1).map((e) => e.$2).toList(), [for (var i = 1; i < 100; i += 3) i]);
  });
}
