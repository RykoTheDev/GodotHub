import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/dashboard_sections.dart';
import 'package:godothub/src/rust/api/types.dart';

import '../ui/i18n_setup.dart';

const all = DashboardTileId.values;

List<String> ids(List<DashboardTileId> tiles) => [for (final tile in tiles) tile.id];

void main() {
  test('tile ids keep the TypeScript order', () {
    expect(dashboardTileIds, [
      'weekly',
      'top_time',
      'insights',
      'git',
      'storage',
      'recent',
      'pinned',
      'engines',
      'running',
      'todos',
    ]);
    expect(DashboardTileId.fromId('top_time'), DashboardTileId.topTime);
    expect(DashboardTileId.fromId('stats'), isNull);
  });

  test('enabledTileIds treats empty as everything and keeps canonical order', () {
    expect(enabledTileIds([]), all);
    expect(ids(enabledTileIds(['running', 'weekly', 'bogus', 'quick_actions'])), ['weekly', 'running']);
  });

  test('orderedTileIds keeps the stored order, drops unknown ids and appends missing ones', () {
    expect(orderedTileIds([]), all);
    expect(ids(orderedTileIds(['git', 'bogus', 'recent'])), [
      'git',
      'recent',
      'weekly',
      'top_time',
      'insights',
      'storage',
      'pinned',
      'engines',
      'running',
      'todos',
    ]);
    expect(ids(orderedTileIds(['git', 'git'])).take(3), ['git', 'git', 'weekly']);
  });

  test('remove and add', () {
    expect(ids(removeTileId([], DashboardTileId.git)), [for (final id in dashboardTileIds) if (id != 'git') id]);
    expect(ids(removeTileId(['git', 'recent'], DashboardTileId.git)), ['recent']);
    expect(ids(addTileId(['recent'], DashboardTileId.weekly)), ['recent', 'weekly']);
    expect(ids(addTileId(['recent'], DashboardTileId.recent)), ['recent']);
    expect(addTileId([], DashboardTileId.todos), all);
  });

  test('moveTileId swaps neighbours and ignores out-of-range moves', () {
    expect(ids(moveTileId([], DashboardTileId.topTime, -1)).take(3), ['top_time', 'weekly', 'insights']);
    expect(ids(moveTileId([], DashboardTileId.weekly, -1)), dashboardTileIds);
    expect(ids(moveTileId([], DashboardTileId.todos, 1)), dashboardTileIds);
    expect(ids(moveTileId(['git', 'recent'], DashboardTileId.git, 1)).take(3), ['recent', 'git', 'weekly']);
  });

  test('layout options', () {
    expect([for (final t in all) if (tileCanSpan(t)) t.id], ['weekly', 'top_time', 'insights', 'git', 'storage', 'todos']);
    expect([for (final t in all) if (tileCanTall(t)) t.id], ['weekly', 'top_time', 'git', 'storage', 'todos']);
  });

  test('toggles add to the end or remove', () {
    expect(toggleTileSpan(['git'], DashboardTileId.weekly), ['git', 'weekly']);
    expect(toggleTileSpan(['git', 'weekly', 'git'], DashboardTileId.git), ['weekly']);
    expect(toggleTileTall([], DashboardTileId.todos), ['todos']);
    expect(toggleTileTall(['todos'], DashboardTileId.todos), isEmpty);
  });

  test('presets', () async {
    await setUpTestI18n();
    expect([for (final p in dashboardPresets) p.id], ['default', 'overview', 'analytics', 'development']);
    expect([for (final p in dashboardPresets) p.labelKey], [
      'dashboard_preset_default',
      'dashboard_preset_overview',
      'dashboard_preset_analytics',
      'dashboard_preset_development',
    ]);
    expect(dashboardPresets[2].spans, ['weekly', 'storage']);
    expect(dashboardPresets[3].tall, ['git']);
    expect(dashboardPresets[0].label(), 'Default');
    expect(dashboardPresets[1].description(), isNotEmpty);
  });

  test('custom presets', () {
    final sections = ['stats'];
    final created = createCustomPreset([], '  Mine  ', sections, ['git'], ['git'], [], nowMs: 1700000000000);
    expect(created.single.id, 'custom-${1700000000000.toRadixString(36)}');
    expect(created.single.id, 'custom-loyw3v28');
    expect(created.single.name, 'Mine');
    expect(created.single.sections, ['stats']);
    sections.add('mutated');
    expect(created.single.sections, ['stats']);
    final unchanged = createCustomPreset(created, '   ', [], [], [], []);
    expect(identical(unchanged, created), isTrue);
    final later = createCustomPreset(created, 'Other', [], [], [], []);
    expect(later.length, 2);
    expect(later[1].id, startsWith('custom-'));
    expect(deleteCustomPreset(later, created.single.id).map((p) => p.name), ['Other']);
  });

  test('presetToSettings copies all four lists', () {
    const custom = DashboardCustomPreset(id: 'c', name: 'n', sections: ['a'], order: ['b'], spans: ['c'], tall: ['d']);
    final patch = presetToSettings(custom.layout);
    expect(patch.dashboardSections, ['a']);
    expect(patch.dashboardSectionOrder, ['b']);
    expect(patch.dashboardSectionSpans, ['c']);
    expect(patch.dashboardTallSections, ['d']);
    expect(identical(patch.dashboardSections, custom.sections), isFalse);
  });

  test('settingsMatchPreset', () {
    final defaults = dashboardPresets[0].layout;
    expect(settingsMatchPreset(defaults, [], [], [], []), isTrue);
    expect(settingsMatchPreset(defaults, [...dashboardTileIds.reversed, 'stats', 'quick_actions'], dashboardTileIds, [], []), isTrue);
    expect(settingsMatchPreset(defaults, [], [...dashboardTileIds.reversed], [], []), isFalse);
    expect(settingsMatchPreset(defaults, [], [], ['git'], []), isFalse);
    final analytics = dashboardPresets[2].layout;
    expect(
      settingsMatchPreset(
        analytics,
        ['categories', 'storage', 'top_time', 'weekly', 'stats', 'quick_actions'],
        ['weekly', 'top_time', 'storage'],
        ['storage', 'weekly'],
        ['storage', 'top_time', 'weekly'],
      ),
      isTrue,
    );
    expect(settingsMatchPreset(analytics, analytics.sections, ['top_time', 'weekly', 'storage'], analytics.spans, analytics.tall), isFalse);
  });

  test('buildDashboardSegments groups runs between spanning tiles', () {
    final segments = buildDashboardSegments(
      [DashboardTileId.recent, DashboardTileId.pinned, DashboardTileId.git, DashboardTileId.engines, DashboardTileId.weekly],
      ['git', 'weekly'],
    );
    expect([for (final s in segments) s.span], [false, true, false, true]);
    expect([for (final s in segments) [for (final t in s.tiles) '${t.id.id}@${t.index}']], [
      ['recent@0', 'pinned@1'],
      ['git@2'],
      ['engines@3'],
      ['weekly@4'],
    ]);
    expect(buildDashboardSegments([], ['git']), isEmpty);
  });
}
