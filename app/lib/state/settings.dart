import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/settings.dart';
import '../design/palette.dart';
import '../logic/pending_save.dart';
import '../logic/platform.dart';
import '../logic/settings_copy.dart';
import '../src/rust/api/types.dart';
import 'app_lifecycle.dart';
import 'workspaces.dart';

const int saveDebounceMs = 250;

const AppSettings defaultSettings = AppSettings(
  schemaVersion: 0,
  downloadDir: null,
  defaultProjectLocation: null,
  projectScanDirs: [],
  versionScanDirs: [],
  scanDepth: 2,
  iconScanDepth: 4,
  downloadConcurrency: 3,
  accentColor: defaultAccent,
  backgroundColor: defaultBackground,
  cornerRadius: defaultCornerRadius + 0.0,
  raisedContrast: defaultRaisedContrast,
  uiDensity: 1.05,
  fontScale: 1.0,
  themeMode: 'dark',
  customCss: '',
  animationIntensity: 'full',
  viewEntrance: 'slide',
  launchWithConsole: false,
  builtinConsole: true,
  gitAutoFetch: false,
  closeOnProjectOpen: false,
  minimizeToTray: false,
  reopenAfterGodotCloses: false,
  lastOpenedTimeFormat: '12h',
  lastOpenedDateFormat: 'DD-MM-YYYY',
  setupComplete: false,
  categoriesEnabled: true,
  workspacesEnabled: true,
  autoScanOnStartup: true,
  commandPaletteKeybind: 'p',
  externalEditorPath: null,
  githubToken: null,
  templateScanDir: null,
  discordAppId: null,
  discordRpcEnabled: true,
  discordRpcShowProjects: true,
  discordRpcExcludedProjects: [],
  discordRpcProjectPresences: [],
  tooltipDelay: 350,
  autoWatchProjectDirs: true,
  autoWatchVersionDirs: true,
  autoWatchTemplateDir: true,
  trayRecentProjectsCount: 5,
  showSupportButton: true,
  showStarButton: true,
  showBugButton: true,
  showTrayButton: true,
  showLanguageButton: true,
  showChangelogButton: true,
  showScrollbars: true,
  animatedNumbers: true,
  screenReaderAnnouncements: true,
  projectIconOpacity: 14,
  animationThreshold: 20,
  animationSpeed: 1.5,
  motionScrollReveal: true,
  motionCardTilt: true,
  motionClickRipple: true,
  motionPressBounce: true,
  language: 'en-US',
  useOsDecorations: false,
  dismissedProjectPaths: [],
  directoryNamingConvention: 'keep',
  themePreset: 'custom',
  gitInitNewProjects: false,
  openAfterImport: true,
  cardLayout: true,
  dashboardCustomName: null,
  defaultLandingTab: 'projects',
  dashboardSections: [],
  dashboardSectionOrder: [],
  dashboardSectionSpans: [],
  dashboardTallSections: [],
  dashboardCustomPresets: [],
  autoBackupIntervalMinutes: 0,
  cardShowSize: true,
  cardShowTime: true,
  cardBlurPath: false,
  cardShowPath: true,
  cardShowTags: true,
  cardShowLastOpened: true,
  cardShowPlay: true,
  cardShowConsole: true,
  cardShowSessionTimer: true,
  cardViewOverrides: {},
  customizeViewEnabled: false,
  fixedSidebarResizeKnob: false,
  desktopNotificationsEnabled: true,
  coloredTitlebarButtons: false,
  rtlLayout: false,
  projectTodosEnabled: false,
  useMise: false,
  disabledFeatures: [],
);

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
  retry: (_, _) => null,
);

final settingsLoadedProvider = Provider<bool>((ref) => ref.watch(settingsProvider.select((value) => value.hasValue)));

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  AppSettings? _pending;
  Timer? _saveTimer;
  bool _saving = false;
  Future<void>? _savePromise;
  String _settingsWorkspaceId = '';
  int _generation = 0;

  String get settingsWorkspaceId => _settingsWorkspaceId;

  @override
  Future<AppSettings> build() async {
    final activeId = ref.watch(activeWorkspaceIdProvider);
    final generation = ++_generation;
    ref.onDispose(() {
      _saveTimer?.cancel();
      _saveTimer = null;
      _pending = null;
    });
    ref.listenPlatformBrightness((brightness) {
      final current = state.value;
      if (current != null) _syncSystemTheme(current, brightness);
    });
    listenSelf((previous, next) {
      final value = next.value;
      if (value == null || !_themeChanged(previous?.value, value)) return;
      scheduleMicrotask(() {
        if (ref.mounted) _syncSystemTheme(value, ghPlatformBrightness());
      });
    });
    if (activeId.isEmpty) return Completer<AppSettings>().future;
    final settings = await SettingsApi.get();
    if (generation == _generation) _settingsWorkspaceId = activeId;
    return settings;
  }

  bool _themeChanged(AppSettings? previous, AppSettings next) =>
      previous == null ||
      previous.themeMode != next.themeMode ||
      previous.accentColor != next.accentColor ||
      previous.backgroundColor != next.backgroundColor ||
      previous.themePreset != next.themePreset ||
      previous.raisedContrast != next.raisedContrast;

  void _syncSystemTheme(AppSettings settings, Brightness brightness) {
    if (settings.themeMode != 'system') return;
    final targetDark = brightness != Brightness.light;
    final clash = settings.themePreset == 'custom' && isDarkColor(settings.backgroundColor) != targetDark;
    if (!clash) return;
    final latest = state.value ?? settings;
    unawaited(
      save(copySettings(latest, backgroundColor: targetDark ? defaultBackground : defaultBackgroundLight))
          .then<void>((_) {}, onError: _reportSaveError),
    );
  }

  void _reportSaveError(Object error) => debugPrint('Failed to save settings: $error');

  Future<void> _flushPending() {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (_saving) {
      return (_savePromise ?? Future<void>.value()).then((_) => _flushPending());
    }
    final pending = _pending;
    if (pending == null) return Future<void>.value();
    _pending = null;
    final cycle = () async {
      _saving = true;
      try {
        final saved = await SettingsApi.update(pending);
        if (_pending == null && ref.mounted) state = AsyncData(saved);
      } finally {
        _saving = false;
      }
    }();
    _savePromise = cycle;
    return cycle;
  }

  Future<AppSettings> save(AppSettings next) async {
    state = AsyncData(next);
    _pending = next;
    registerPendingSave(_flushPending);
    if (_saving) {
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: saveDebounceMs), () {
        unawaited(_flushPending().then<void>((_) {}, onError: _reportSaveError));
      });
      return next;
    }
    await _flushPending();
    return next;
  }

  Future<AppSettings> resetToDefaults() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final inFlight = _savePromise;
    if (inFlight != null) await inFlight;
    _pending = null;
    final defaults = await SettingsApi.reset();
    if (ref.mounted) state = AsyncData(defaults);
    return defaults;
  }
}
