import '../i18n/i18n.dart';
import '../src/rust/api/types.dart';

enum DashboardTileId {
  weekly('weekly', span: true, tall: true),
  topTime('top_time', span: true, tall: true),
  insights('insights', span: true),
  git('git', span: true, tall: true),
  storage('storage', span: true, tall: true),
  recent('recent'),
  pinned('pinned'),
  engines('engines'),
  running('running'),
  todos('todos', span: true, tall: true);

  const DashboardTileId(this.id, {this.span = false, this.tall = false});

  final String id;
  final bool span;
  final bool tall;

  static DashboardTileId? fromId(String id) {
    for (final tile in values) {
      if (tile.id == id) return tile;
    }
    return null;
  }
}

final List<String> dashboardTileIds = List.unmodifiable([for (final tile in DashboardTileId.values) tile.id]);

List<DashboardTileId> enabledTileIds(List<String> enabled) {
  if (enabled.isEmpty) return [...DashboardTileId.values];
  return [for (final tile in DashboardTileId.values) if (enabled.contains(tile.id)) tile];
}

List<DashboardTileId> orderedTileIds(List<String> order) {
  if (order.isEmpty) return [...DashboardTileId.values];
  final present = order.toSet();
  return [
    for (final id in order) ?DashboardTileId.fromId(id),
    for (final tile in DashboardTileId.values) if (!present.contains(tile.id)) tile,
  ];
}

List<DashboardTileId> removeTileId(List<String> enabled, DashboardTileId id) =>
    enabledTileIds(enabled).where((tile) => tile != id).toList();

List<DashboardTileId> addTileId(List<String> enabled, DashboardTileId id) {
  final current = enabledTileIds(enabled);
  if (current.contains(id)) return current;
  return [...current, id];
}

List<DashboardTileId> moveTileId(List<String> order, DashboardTileId id, int dir) {
  final current = orderedTileIds(order);
  final from = current.indexOf(id);
  final to = from + dir;
  if (from == -1 || to < 0 || to >= current.length) return current;
  final next = [...current];
  final moved = next[from];
  next[from] = next[to];
  next[to] = moved;
  return next;
}

bool tileCanSpan(DashboardTileId id) => id.span;

bool tileCanTall(DashboardTileId id) => id.tall;

List<String> toggleTileSpan(List<String> spans, DashboardTileId id) =>
    spans.contains(id.id) ? spans.where((x) => x != id.id).toList() : [...spans, id.id];

List<String> toggleTileTall(List<String> tall, DashboardTileId id) =>
    tall.contains(id.id) ? tall.where((x) => x != id.id).toList() : [...tall, id.id];

typedef DashboardLayout = ({List<String> sections, List<String> order, List<String> spans, List<String> tall});

class DashboardPreset {
  const DashboardPreset({
    required this.id,
    required this.labelKey,
    required this.descriptionKey,
    required this.sections,
    required this.order,
    required this.spans,
    required this.tall,
  });

  final String id;
  final String labelKey;
  final String descriptionKey;
  final List<String> sections;
  final List<String> order;
  final List<String> spans;
  final List<String> tall;

  DashboardLayout get layout => (sections: sections, order: order, spans: spans, tall: tall);

  String label([Translations? translations]) {
    final tr = (translations ?? t).dashboard;
    return switch (id) {
      'overview' => tr.dashboard_preset_overview,
      'analytics' => tr.dashboard_preset_analytics,
      'development' => tr.dashboard_preset_development,
      _ => tr.dashboard_preset_default,
    };
  }

  String description([Translations? translations]) {
    final tr = (translations ?? t).dashboard;
    return switch (id) {
      'overview' => tr.dashboard_preset_overview_desc,
      'analytics' => tr.dashboard_preset_analytics_desc,
      'development' => tr.dashboard_preset_development_desc,
      _ => tr.dashboard_preset_default_desc,
    };
  }
}

const dashboardPresets = [
  DashboardPreset(
    id: 'default',
    labelKey: 'dashboard_preset_default',
    descriptionKey: 'dashboard_preset_default_desc',
    sections: [],
    order: [],
    spans: [],
    tall: [],
  ),
  DashboardPreset(
    id: 'overview',
    labelKey: 'dashboard_preset_overview',
    descriptionKey: 'dashboard_preset_overview_desc',
    sections: ['quick_actions', 'stats', 'recent', 'pinned', 'engines', 'running'],
    order: ['recent', 'pinned', 'engines', 'running'],
    spans: [],
    tall: [],
  ),
  DashboardPreset(
    id: 'analytics',
    labelKey: 'dashboard_preset_analytics',
    descriptionKey: 'dashboard_preset_analytics_desc',
    sections: ['quick_actions', 'stats', 'weekly', 'top_time', 'storage', 'categories'],
    order: ['weekly', 'top_time', 'storage'],
    spans: ['weekly', 'storage'],
    tall: ['weekly', 'top_time', 'storage'],
  ),
  DashboardPreset(
    id: 'development',
    labelKey: 'dashboard_preset_development',
    descriptionKey: 'dashboard_preset_development_desc',
    sections: ['quick_actions', 'stats', 'git', 'running', 'engines', 'recent', 'pinned'],
    order: ['git', 'running', 'engines', 'recent', 'pinned'],
    spans: ['git'],
    tall: ['git'],
  ),
];

extension DashboardCustomPresetLayout on DashboardCustomPreset {
  DashboardLayout get layout => (sections: sections, order: order, spans: spans, tall: tall);
}

List<DashboardCustomPreset> createCustomPreset(
  List<DashboardCustomPreset> presets,
  String name,
  List<String> sections,
  List<String> order,
  List<String> spans,
  List<String> tall, {
  int? nowMs,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return presets;
  final preset = DashboardCustomPreset(
    id: 'custom-${(nowMs ?? DateTime.now().millisecondsSinceEpoch).toRadixString(36)}',
    name: trimmed,
    sections: [...sections],
    order: [...order],
    spans: [...spans],
    tall: [...tall],
  );
  return [...presets, preset];
}

List<DashboardCustomPreset> deleteCustomPreset(List<DashboardCustomPreset> presets, String id) =>
    presets.where((preset) => preset.id != id).toList();

typedef DashboardSettingsPatch = ({
  List<String> dashboardSections,
  List<String> dashboardSectionOrder,
  List<String> dashboardSectionSpans,
  List<String> dashboardTallSections,
});

DashboardSettingsPatch presetToSettings(DashboardLayout preset) => (
  dashboardSections: [...preset.sections],
  dashboardSectionOrder: [...preset.order],
  dashboardSectionSpans: [...preset.spans],
  dashboardTallSections: [...preset.tall],
);

String _sortedKey(List<String> values) => ([...values]..sort()).join(',');

bool settingsMatchPreset(
  DashboardLayout preset,
  List<String> sections,
  List<String> order,
  List<String> spans,
  List<String> tall,
) {
  final allSections = [...dashboardTileIds, 'quick_actions', 'stats'];
  final sec = sections.isEmpty ? allSections : sections;
  final presetSec = preset.sections.isEmpty ? allSections : preset.sections;
  final ord = order.isEmpty ? dashboardTileIds : order;
  final presetOrd = preset.order.isEmpty ? dashboardTileIds : preset.order;
  return _sortedKey(sec) == _sortedKey(presetSec) &&
      ord.join(',') == presetOrd.join(',') &&
      _sortedKey(spans) == _sortedKey(preset.spans) &&
      _sortedKey(tall) == _sortedKey(preset.tall);
}

class DashboardSegment {
  const DashboardSegment({required this.tiles, required this.span});

  final List<({DashboardTileId id, int index})> tiles;
  final bool span;
}

List<DashboardSegment> buildDashboardSegments(List<DashboardTileId> ordered, List<String> spans) {
  final segments = <DashboardSegment>[];
  var pending = <({DashboardTileId id, int index})>[];
  void flush() {
    if (pending.isEmpty) return;
    segments.add(DashboardSegment(tiles: pending, span: false));
    pending = [];
  }

  for (final (index, id) in ordered.indexed) {
    if (spans.contains(id.id)) {
      flush();
      segments.add(DashboardSegment(tiles: [(id: id, index: index)], span: true));
    } else {
      pending.add((id: id, index: index));
    }
  }
  flush();
  return segments;
}
