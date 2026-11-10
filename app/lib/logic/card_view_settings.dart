import '../src/rust/api/types.dart';
import 'settings_copy.dart';

enum ProjectViewMode {
  list('list'),
  grid('grid'),
  kanban('kanban');

  const ProjectViewMode(this.id);

  final String id;

  static ProjectViewMode? fromId(String id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

enum CardViewKey {
  showSize('show_size', 'card_show_size'),
  showTime('show_time', 'card_show_time'),
  blurPath('blur_path', 'card_blur_path'),
  showPath('show_path', 'card_show_path'),
  showTags('show_tags', 'card_show_tags'),
  showLastOpened('show_last_opened', 'card_show_last_opened'),
  showPlay('show_play', 'card_show_play'),
  showConsole('show_console', 'card_show_console'),
  showSessionTimer('show_session_timer', 'card_show_session_timer');

  const CardViewKey(this.id, this.settingsKey);

  final String id;
  final String settingsKey;

  bool of(CardViewOverride settings) => switch (this) {
    showSize => settings.showSize,
    showTime => settings.showTime,
    blurPath => settings.blurPath,
    showPath => settings.showPath,
    showTags => settings.showTags,
    showLastOpened => settings.showLastOpened,
    showPlay => settings.showPlay,
    showConsole => settings.showConsole,
    showSessionTimer => settings.showSessionTimer,
  };
}

CardViewOverride _listCardViewSettings(AppSettings settings) => CardViewOverride(
  showSize: settings.cardShowSize,
  showTime: settings.cardShowTime,
  blurPath: settings.cardBlurPath,
  showPath: settings.cardShowPath,
  showTags: settings.cardShowTags,
  showLastOpened: settings.cardShowLastOpened,
  showPlay: settings.cardShowPlay,
  showConsole: settings.cardShowConsole,
  showSessionTimer: settings.cardShowSessionTimer,
);

CardViewOverride _withKey(CardViewOverride base, CardViewKey key, bool value) => CardViewOverride(
  showSize: key == CardViewKey.showSize ? value : base.showSize,
  showTime: key == CardViewKey.showTime ? value : base.showTime,
  blurPath: key == CardViewKey.blurPath ? value : base.blurPath,
  showPath: key == CardViewKey.showPath ? value : base.showPath,
  showTags: key == CardViewKey.showTags ? value : base.showTags,
  showLastOpened: key == CardViewKey.showLastOpened ? value : base.showLastOpened,
  showPlay: key == CardViewKey.showPlay ? value : base.showPlay,
  showConsole: key == CardViewKey.showConsole ? value : base.showConsole,
  showSessionTimer: key == CardViewKey.showSessionTimer ? value : base.showSessionTimer,
);

CardViewOverride getCardViewSettings(AppSettings settings, ProjectViewMode viewMode) {
  final result = _listCardViewSettings(settings);
  if (viewMode == ProjectViewMode.list) return result;
  return settings.cardViewOverrides[viewMode.id] ?? result;
}

AppSettings setCardViewOverride(AppSettings settings, ProjectViewMode viewMode, CardViewKey key, bool value) {
  if (viewMode == ProjectViewMode.list) {
    return copySettings(
      settings,
      cardShowSize: key == CardViewKey.showSize ? value : null,
      cardShowTime: key == CardViewKey.showTime ? value : null,
      cardBlurPath: key == CardViewKey.blurPath ? value : null,
      cardShowPath: key == CardViewKey.showPath ? value : null,
      cardShowTags: key == CardViewKey.showTags ? value : null,
      cardShowLastOpened: key == CardViewKey.showLastOpened ? value : null,
      cardShowPlay: key == CardViewKey.showPlay ? value : null,
      cardShowConsole: key == CardViewKey.showConsole ? value : null,
      cardShowSessionTimer: key == CardViewKey.showSessionTimer ? value : null,
    );
  }
  final existing = settings.cardViewOverrides[viewMode.id] ?? _listCardViewSettings(settings);
  return copySettings(
    settings,
    cardViewOverrides: {...settings.cardViewOverrides, viewMode.id: _withKey(existing, key, value)},
  );
}
