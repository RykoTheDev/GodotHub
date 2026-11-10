import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/card_view_settings.dart';
import 'package:godothub/src/rust/api/types.dart';

import 'logic_fixtures.dart';

AppSettings withList(Map<CardViewKey, bool> values) {
  var settings = baseSettings;
  for (final entry in values.entries) {
    settings = setCardViewOverride(settings, ProjectViewMode.list, entry.key, entry.value);
  }
  return settings;
}

final settings = withList({
  CardViewKey.showSize: false,
  CardViewKey.showTime: true,
  CardViewKey.blurPath: true,
  CardViewKey.showPath: false,
  CardViewKey.showTags: true,
  CardViewKey.showLastOpened: false,
  CardViewKey.showPlay: false,
  CardViewKey.showConsole: true,
  CardViewKey.showSessionTimer: true,
});

void main() {
  test('fixture has no per-view overrides', () {
    expect(settings.cardViewOverrides, isEmpty);
  });

  test('all views inherit global visibility and privacy settings', () {
    const expected = CardViewOverride(
      showSize: false,
      showTime: true,
      blurPath: true,
      showPath: false,
      showTags: true,
      showLastOpened: false,
      showPlay: false,
      showConsole: true,
      showSessionTimer: true,
    );
    for (final view in ProjectViewMode.values) {
      expect(getCardViewSettings(settings, view), expected);
    }
  });

  test('a partial override affects only the chosen setting and view', () {
    final next = setCardViewOverride(settings, ProjectViewMode.grid, CardViewKey.showSize, true);
    expect(getCardViewSettings(next, ProjectViewMode.grid).showSize, isTrue);
    expect(getCardViewSettings(next, ProjectViewMode.grid).showPath, isFalse);
    expect(getCardViewSettings(next, ProjectViewMode.grid).blurPath, isTrue);
    expect(getCardViewSettings(next, ProjectViewMode.kanban), getCardViewSettings(settings, ProjectViewMode.kanban));
    expect(settings.cardViewOverrides, isEmpty);
  });

  test('editing list defaults preserves per-view overrides', () {
    final original = setCardViewOverride(settings, ProjectViewMode.kanban, CardViewKey.showTags, false);
    final next = setCardViewOverride(original, ProjectViewMode.list, CardViewKey.showPlay, true);
    expect(getCardViewSettings(next, ProjectViewMode.grid).showPlay, isTrue);
    expect(getCardViewSettings(next, ProjectViewMode.kanban).showTags, isFalse);
    expect(original.cardShowPlay, isFalse);
  });

  test('list edits write the matching card_* field and keep everything else', () {
    for (final key in CardViewKey.values) {
      final flipped = !key.of(getCardViewSettings(settings, ProjectViewMode.list));
      final next = setCardViewOverride(settings, ProjectViewMode.list, key, flipped);
      for (final other in CardViewKey.values) {
        final before = other.of(getCardViewSettings(settings, ProjectViewMode.list));
        expect(other.of(getCardViewSettings(next, ProjectViewMode.list)), other == key ? flipped : before);
      }
      expect(next.cardViewOverrides, isEmpty);
      expect(next.language, settings.language);
      expect(next.disabledFeatures, settings.disabledFeatures);
    }
  });

  test('a second override on the same view keeps the first', () {
    final first = setCardViewOverride(settings, ProjectViewMode.grid, CardViewKey.showSize, true);
    final second = setCardViewOverride(first, ProjectViewMode.grid, CardViewKey.showConsole, false);
    final grid = getCardViewSettings(second, ProjectViewMode.grid);
    expect(grid.showSize, isTrue);
    expect(grid.showConsole, isFalse);
    expect(second.cardViewOverrides.keys, ['grid']);
  });

  test('ids match the TypeScript keys', () {
    expect([for (final mode in ProjectViewMode.values) mode.id], ['list', 'grid', 'kanban']);
    expect(ProjectViewMode.fromId('kanban'), ProjectViewMode.kanban);
    expect(ProjectViewMode.fromId('table'), isNull);
    expect([for (final key in CardViewKey.values) key.settingsKey], [
      'card_show_size',
      'card_show_time',
      'card_blur_path',
      'card_show_path',
      'card_show_tags',
      'card_show_last_opened',
      'card_show_play',
      'card_show_console',
      'card_show_session_timer',
    ]);
  });
}
