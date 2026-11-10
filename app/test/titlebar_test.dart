import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/i18n/i18n_controller.dart';
import 'package:godothub/i18n/languages.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/titlebar/language_menu.dart';
import 'package:godothub/titlebar/providers.dart';
import 'package:godothub/titlebar/running_projects_chip.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/task_tray.dart';
import 'package:godothub/titlebar/task_tray.dart';
import 'package:godothub/titlebar/title_bar.dart';
import 'package:godothub/titlebar/window_controls.dart';

import 'support/settings_fakes.dart';
import 'support/fake_rust.dart';
import 'ui/i18n_setup.dart';

const baseSettings = AppSettings(
  schemaVersion: 1,
  downloadDir: null,
  defaultProjectLocation: null,
  projectScanDirs: [],
  versionScanDirs: [],
  scanDepth: 0,
  iconScanDepth: 0,
  downloadConcurrency: 0,
  accentColor: '#457ff2',
  backgroundColor: '#15171c',
  cornerRadius: 7,
  raisedContrast: 0,
  uiDensity: 1.05,
  fontScale: 1,
  themeMode: 'dark',
  customCss: '',
  animationIntensity: '',
  viewEntrance: '',
  launchWithConsole: false,
  builtinConsole: false,
  gitAutoFetch: false,
  closeOnProjectOpen: false,
  minimizeToTray: false,
  reopenAfterGodotCloses: false,
  lastOpenedTimeFormat: '',
  lastOpenedDateFormat: '',
  setupComplete: false,
  categoriesEnabled: false,
  workspacesEnabled: false,
  autoScanOnStartup: false,
  commandPaletteKeybind: '',
  externalEditorPath: null,
  githubToken: null,
  templateScanDir: null,
  discordAppId: null,
  discordRpcEnabled: false,
  discordRpcShowProjects: false,
  discordRpcExcludedProjects: [],
  discordRpcProjectPresences: [],
  tooltipDelay: 350,
  autoWatchProjectDirs: false,
  autoWatchVersionDirs: false,
  autoWatchTemplateDir: false,
  trayRecentProjectsCount: 0,
  showSupportButton: false,
  showStarButton: false,
  showBugButton: false,
  showTrayButton: false,
  showLanguageButton: false,
  showChangelogButton: false,
  showScrollbars: false,
  animatedNumbers: false,
  screenReaderAnnouncements: false,
  projectIconOpacity: 0,
  animationThreshold: 0,
  animationSpeed: 1,
  motionScrollReveal: false,
  motionCardTilt: false,
  motionClickRipple: false,
  motionPressBounce: false,
  language: 'en-US',
  useOsDecorations: false,
  dismissedProjectPaths: [],
  directoryNamingConvention: '',
  themePreset: '',
  gitInitNewProjects: false,
  openAfterImport: false,
  cardLayout: true,
  dashboardCustomName: null,
  defaultLandingTab: '',
  dashboardSections: [],
  dashboardSectionOrder: [],
  dashboardSectionSpans: [],
  dashboardTallSections: [],
  dashboardCustomPresets: [],
  autoBackupIntervalMinutes: 0,
  cardShowSize: false,
  cardShowTime: false,
  cardBlurPath: false,
  cardShowPath: false,
  cardShowTags: false,
  cardShowLastOpened: false,
  cardShowPlay: false,
  cardShowConsole: false,
  cardShowSessionTimer: false,
  cardViewOverrides: {},
  customizeViewEnabled: false,
  fixedSidebarResizeKnob: false,
  desktopNotificationsEnabled: false,
  coloredTitlebarButtons: false,
  rtlLayout: false,
  projectTodosEnabled: false,
  useMise: false,
  disabledFeatures: [],
);

AppSettings settingsWith({
  bool useOsDecorations = false,
  bool colored = false,
  bool support = false,
  bool star = false,
  bool bug = false,
  bool tray = false,
  bool language = false,
  bool changelog = false,
  String lang = 'en-US',
  bool rtlLayout = false,
  List<String> disabledFeatures = const [],
}) => copySettings(
  baseSettings,
  useOsDecorations: useOsDecorations,
  coloredTitlebarButtons: colored,
  showSupportButton: support,
  showStarButton: star,
  showBugButton: bug,
  showTrayButton: tray,
  showLanguageButton: language,
  showChangelogButton: changelog,
  language: lang,
  rtlLayout: rtlLayout,
  disabledFeatures: disabledFeatures,
);

class FakeWindow implements TitleBarWindow {
  bool maximized = false;
  final List<String> calls = [];
  VoidCallback? listener;

  @override
  bool get isMaximized => maximized;

  @override
  void minimize() => calls.add('minimize');

  @override
  void toggleMaximize() => calls.add('toggleMaximize');

  @override
  void close() => calls.add('close');

  @override
  void startDragging() => calls.add('startDragging');

  @override
  VoidCallback addMaximizeListener(VoidCallback onChanged) {
    listener = onChanged;
    return () => listener = null;
  }
}

class FakeRunningSource {
  FakeRunningSource([this.initial = const []]);

  final List<RunningProject> initial;
  final launched = StreamController<RunningProject>.broadcast();
  final exited = StreamController<String>.broadcast();
  final stopped = <String>[];

  RunningProjectsSource get source => RunningProjectsSource(
    load: () async => initial,
    launched: () => launched.stream,
    exited: () => exited.stream,
    stop: (id) async => stopped.add(id),
  );
}

RunningProject project(String id, String name, {String version = '4.3'}) =>
    RunningProject(id: id, name: name, version: version, startedAtMs: DateTime.now().millisecondsSinceEpoch);

Future<void> pumpTitleBar(
  WidgetTester tester,
  AppSettings settings, {
  required FakeWindow window,
  bool isMac = false,
  bool minimal = false,
  void Function(TitleBarAction action)? onAction,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeSettings(() => settings),
        titleBarWindowProvider.overrideWithValue(window),
        runningProjectsSourceProvider.overrideWithValue(FakeRunningSource().source),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitleBar(isMac: isMac, minimal: minimal, onAction: onAction),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(position);
  await tester.pumpAndSettle();
}

Offset emptyBarSpot(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('titlebar'))).center;

Finder byGhIcon(FaIconData icon) => find.byWidgetPredicate((widget) => widget is GhIcon && widget.icon == icon);

class LitChangelogBadge extends ChangelogBadgeNotifier {
  @override
  bool build() => true;
}

void main() {
  setUp(setUpTestI18n);
  setUp(() {
    installFakeRust().on('crateApiChangelogListChangelogEntries', () async => <ChangelogEntry>[]);
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
  });
  group('visibility rules', () {
    test('custom window controls only off macOS without OS decorations', () {
      expect(showsCustomWindowControls(settingsWith(), isMac: false), isTrue);
      expect(showsCustomWindowControls(settingsWith(), isMac: true), isFalse);
      expect(showsCustomWindowControls(settingsWith(useOsDecorations: true), isMac: false), isFalse);
    });

    test('changelog counts as a title bar button only when not minimal', () {
      final onlyChangelog = settingsWith(changelog: true);
      expect(hasAnyTitleBarButton(onlyChangelog, minimal: false), isTrue);
      expect(hasAnyTitleBarButton(onlyChangelog, minimal: true), isFalse);
      expect(hasAnyTitleBarButton(settingsWith(), minimal: false), isFalse);
      expect(hasAnyTitleBarButton(settingsWith(tray: true), minimal: true), isTrue);
    });

    test('copySettings overrides one field and keeps the rest', () {
      final copy = copySettings(baseSettings, language: 'fr-FR');
      expect(copy.language, 'fr-FR');
      expect(copy.tooltipDelay, baseSettings.tooltipDelay);
      expect(copy.cornerRadius, baseSettings.cornerRadius);
      expect(copy.cardLayout, baseSettings.cardLayout);
      expect(copy.themeMode, baseSettings.themeMode);
    });
  });

  group('TitleBar', () {
    testWidgets('renders nothing with OS decorations and no buttons', (tester) async {
      await pumpTitleBar(tester, settingsWith(useOsDecorations: true), window: FakeWindow());
      expect(find.byKey(const ValueKey('titlebar')), findsNothing);
    });

    testWidgets('custom controls: 32px bar, controls call the window, double-click toggles maximize', (
      tester,
    ) async {
      final window = FakeWindow();
      await pumpTitleBar(tester, settingsWith(), window: window);

      expect(tester.getSize(find.byKey(const ValueKey('titlebar'))).height, 32);
      expect(find.byKey(const ValueKey('window-controls')), findsOneWidget);
      expect(byGhIcon(GhIcons.windowMaximize), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('window-minimize')));
      await tester.tap(find.byKey(const ValueKey('window-maximize')));
      await tester.tap(find.byKey(const ValueKey('window-close')));
      await tester.pumpAndSettle();
      expect(window.calls, ['minimize', 'toggleMaximize', 'close']);

      window.calls.clear();
      await doubleTapAt(tester, emptyBarSpot(tester));
      expect(window.calls, ['toggleMaximize']);

      window.calls.clear();
      await tester.dragFrom(emptyBarSpot(tester), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(window.calls, contains('startDragging'));
    });

    testWidgets('maximize icon swaps to restore when the window reports maximized', (tester) async {
      final window = FakeWindow();
      await pumpTitleBar(tester, settingsWith(), window: window);
      window.maximized = true;
      window.listener!();
      await tester.pump();
      expect(byGhIcon(GhIcons.windowRestore), findsOneWidget);
      expect(find.bySemanticsLabel(t.common.restore), findsOneWidget);
    });

    testWidgets('colored buttons replace the icon controls', (tester) async {
      final window = FakeWindow();
      await pumpTitleBar(tester, settingsWith(colored: true), window: window);
      expect(find.byKey(const ValueKey('window-close')), findsOneWidget);
      expect(byGhIcon(GhIcons.x), findsNothing);
      expect(byGhIcon(GhIcons.minus), findsNothing);
      await tester.tap(find.byKey(const ValueKey('window-close')));
      expect(window.calls, ['close']);
    });

    testWidgets('macOS: 44px bar, 80px start padding, no controls, double-click does nothing', (tester) async {
      final window = FakeWindow();
      await pumpTitleBar(tester, settingsWith(star: true), window: window, isMac: true);

      expect(tester.getSize(find.byKey(const ValueKey('titlebar'))).height, 44);
      expect(find.byKey(const ValueKey('window-controls')), findsNothing);
      expect(tester.getTopLeft(find.byKey(const ValueKey('titlebar-wordmark'))).dx, 80);

      await doubleTapAt(tester, emptyBarSpot(tester));
      expect(window.calls, isNot(contains('toggleMaximize')));
    });

    testWidgets('OS decorations with a button: 44px bar without window controls', (tester) async {
      await pumpTitleBar(tester, settingsWith(useOsDecorations: true, bug: true), window: FakeWindow());
      expect(tester.getSize(find.byKey(const ValueKey('titlebar'))).height, 44);
      expect(find.byKey(const ValueKey('window-controls')), findsNothing);
      expect(find.byKey(const ValueKey('titlebar-bug')), findsOneWidget);
    });

    testWidgets('buttons follow their settings and report actions', (tester) async {
      final actions = <TitleBarAction>[];
      await pumpTitleBar(
        tester,
        settingsWith(support: true, star: true, bug: true, changelog: true),
        window: FakeWindow(),
        onAction: actions.add,
      );

      await tester.tap(find.byKey(const ValueKey('titlebar-wordmark')));
      await tester.tap(find.byKey(const ValueKey('titlebar-changelog')));
      await tester.tap(find.text(t.common.support));
      await tester.tap(find.byKey(const ValueKey('titlebar-star')));
      await tester.tap(find.byKey(const ValueKey('titlebar-bug')));
      await tester.pumpAndSettle();

      expect(actions, [
        TitleBarAction.wordmark,
        TitleBarAction.changelog,
        TitleBarAction.support,
        TitleBarAction.star,
        TitleBarAction.bug,
      ]);
      expect(find.byKey(const ValueKey('language-menu-trigger')), findsNothing);
      expect(find.byKey(const ValueKey('task-tray-trigger')), findsNothing);
    });

    testWidgets('wordmark is plain text when the dashboard feature is off', (tester) async {
      final actions = <TitleBarAction>[];
      final window = FakeWindow();
      await pumpTitleBar(
        tester,
        settingsWith(disabledFeatures: const ['dashboard']),
        window: window,
        onAction: actions.add,
      );
      expect(find.text('GodotHub'), findsOneWidget);
      await doubleTapAt(tester, tester.getCenter(find.text('GodotHub')));
      expect(actions, isEmpty);
      expect(window.calls, ['toggleMaximize']);
    });

    testWidgets('minimal hides everything except the language menu and controls', (tester) async {
      await pumpTitleBar(
        tester,
        settingsWith(support: true, star: true, bug: true, changelog: true, tray: true, language: true),
        window: FakeWindow(),
        minimal: true,
      );
      expect(find.text('GodotHub'), findsNothing);
      expect(find.byKey(const ValueKey('titlebar-changelog')), findsNothing);
      expect(find.byKey(const ValueKey('titlebar-support')), findsNothing);
      expect(find.byKey(const ValueKey('titlebar-star')), findsNothing);
      expect(find.byKey(const ValueKey('titlebar-bug')), findsNothing);
      expect(find.byKey(const ValueKey('task-tray-trigger')), findsNothing);
      expect(find.byKey(const ValueKey('language-menu-trigger')), findsOneWidget);
      expect(find.byKey(const ValueKey('window-controls')), findsOneWidget);
    });

    testWidgets('changelog badge variant shows the label', (tester) async {
      final container = ProviderContainer(
        overrides: [
          fakeSettings(() => settingsWith(changelog: true)),
          titleBarWindowProvider.overrideWithValue(FakeWindow()),
          runningProjectsSourceProvider.overrideWithValue(FakeRunningSource().source),
          changelogBadgeProvider.overrideWith(LitChangelogBadge.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: TitleBar(isMac: false))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.nav.changelog), findsOneWidget);
      expect(find.bySemanticsLabel('${t.nav.changelog} (${t.common.new_badge})'), findsOneWidget);
    });
  });

  group('LanguageMenu', () {
    Future<List<AppSettings>> pumpMenu(WidgetTester tester, AppSettings settings) async {
      GhI18n.instance.setLanguageSetting(settings.language, systemLocales: const [Locale('en', 'US')]);
      final saved = <AppSettings>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fakeSettings(
              () => settings,
              onSave: (next) {
                saved.add(next);
                return next;
              },
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Align(alignment: Alignment.topRight, child: LanguageMenu()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-menu-trigger')));
      await tester.pumpAndSettle();
      return saved;
    }

    testWidgets('lists every language with native names and status badges', (tester) async {
      await pumpMenu(tester, settingsWith());
      expect(find.text(t.common.language_label.toUpperCase()), findsOneWidget);
      for (final language in ghLanguages) {
        expect(find.text(language.displayLabel()), findsOneWidget);
      }
      expect(find.text(t.settings.language_complete), findsNWidgets(5));
      expect(find.text(t.settings.language_beta), findsNWidgets(2));
      expect(find.text(t.settings.language_incomplete), findsNWidgets(2));
      final englishRow = find.byKey(const ValueKey('language-en-US'));
      expect(find.descendant(of: englishRow, matching: byGhIcon(GhIcons.check)), findsOneWidget);
      expect(byGhIcon(GhIcons.check), findsOneWidget);
      expect(find.byKey(const ValueKey('rtl-layout-toggle')), findsNothing);
    });

    testWidgets('selecting a language saves it and closes the menu', (tester) async {
      final saved = await pumpMenu(tester, settingsWith());
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(saved.single.language, 'fr-FR');
      expect(GhI18n.instance.language, 'fr-FR');
      expect(LocaleSettings.currentLocale, AppLocale.frFr);
      expect(find.text('Français'), findsNothing);
    });

    testWidgets('system entry is active when the setting is system', (tester) async {
      await pumpMenu(tester, settingsWith(lang: ghSystemLanguage));
      final systemRow = find.byKey(const ValueKey('language-$ghSystemLanguage'));
      expect(find.descendant(of: systemRow, matching: byGhIcon(GhIcons.check)), findsOneWidget);
      expect(byGhIcon(GhIcons.check), findsOneWidget);
    });

    testWidgets('Arabic shows the RTL layout toggle which flips rtlLayout', (tester) async {
      final saved = await pumpMenu(tester, settingsWith(lang: 'ar-MA'));
      expect(find.byKey(const ValueKey('rtl-layout-toggle')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rtl-layout-toggle')));
      await tester.pumpAndSettle();
      expect(saved.single.rtlLayout, isTrue);
      expect(saved.single.language, 'ar-MA');
    });
  });

  group('RunningProjectsChip', () {
    Future<void> pumpChip(
      WidgetTester tester,
      FakeRunningSource fake, {
      void Function(String id, String name)? onOpen,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: RunningProjectsChip(source: fake.source, onOpenConsole: onOpen),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders nothing when no project is running', (tester) async {
      await pumpChip(tester, FakeRunningSource());
      expect(find.byKey(const ValueKey('running-projects-chip')), findsNothing);
    });

    testWidgets('shows the count, lists projects, stops and opens consoles', (tester) async {
      final fake = FakeRunningSource([project('a', 'Alpha'), project('b', 'Beta', version: '')]);
      final opened = <String>[];
      await pumpChip(tester, fake, onOpen: (id, name) => opened.add('$id:$name'));

      expect(find.byKey(const ValueKey('running-projects-chip')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('running-projects-chip')));
      await tester.pumpAndSettle();
      expect(find.text(t.common.running.toUpperCase()), findsOneWidget);
      expect(find.text('2 projects running'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.textContaining('Godot 4.3 · '), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('stop-a')));
      await tester.pump();
      expect(fake.stopped, ['a']);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(opened, ['b:Beta']);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('follows launched and exited events', (tester) async {
      final fake = FakeRunningSource();
      await pumpChip(tester, fake);

      fake.launched.add(project('a', 'Alpha'));
      await tester.pump();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      fake.launched.add(project('a', 'Alpha'));
      fake.launched.add(project('b', 'Beta'));
      await tester.pump();
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      fake.exited.add('a');
      fake.exited.add('b');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('running-projects-chip')), findsNothing);
    });

    test('formats durations and counts like the React app', () {
      expect(formatDuration(-5), '0s');
      expect(formatDuration(42000), '42s');
      expect(formatDuration(125000), '2m 5s');
      expect(formatDuration(3723000), '1h 2m');
      expect(runningProjectsDescription(1), '1 project running');
    });
  });

  group('TaskTray', () {
    testWidgets('opens an empty state and closes itself after two seconds', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Align(alignment: Alignment.topRight, child: TaskTray()),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('task-tray-trigger')));
      await tester.pumpAndSettle();
      expect(find.text(t.common.task_tray_title.toUpperCase()), findsOneWidget);
      expect(find.text(t.common.task_tray_empty), findsOneWidget);
      expect(find.text(t.common.no_tasks_running), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(t.common.no_tasks_running), findsNothing);
    });

    testWidgets('shows the active count badge from the task tray provider', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      for (var i = 0; i < 12; i++) {
        container
            .read(taskTrayProvider.notifier)
            .registerTask(TrayTask(id: '$i', type: TaskType.downloadGodot, label: '$i', status: TaskStatus.queued));
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: TaskTray())),
          ),
        ),
      );
      expect(find.text('9+'), findsOneWidget);
    });
  });

  group('native running projects source', () {
    test('adopts running projects through the retrying fetch and maps launch and exit events', () async {
      final rust = installFakeRust();
      rust.on(
        'crateApiProjectsListRunningProjects',
        () async => [RunningProjectInfo(id: 'a', name: 'Alpha', version: '4.3', launchedAtMs: BigInt.from(1000), console: false)],
      );
      final source = RunningProjectsSource.native();
      final loaded = await source.load();
      expect(loaded.single.id, 'a');
      expect(loaded.single.startedAtMs, 1000 + timerStartDelayMs);

      final launched = <RunningProject>[];
      final exited = <String>[];
      final subs = [source.launched().listen(launched.add), source.exited().listen(exited.add)];
      addTearDown(() {
        for (final sub in subs) {
          sub.cancel();
        }
      });
      rust.emit(
        AppEvent(
          kind: AppEventKind.projectLaunched,
          name: 'project:launched',
          json: '{}',
          projectLaunched: const ProjectLaunched(id: 'b', name: 'Beta', version: '4.2', console: true),
        ),
      );
      rust.emit(AppEvent(kind: AppEventKind.projectExited, name: 'project:exited', json: '{}', projectExited: const ProjectExited(id: 'a')));
      await pumpEventQueue();
      expect(launched.single.name, 'Beta');
      expect(launched.single.startedAtMs, greaterThan(DateTime.now().millisecondsSinceEpoch));
      expect(exited, ['a']);
    });

    test('the default console opener emits app:open-console', () async {
      final signals = <AppSignal>[];
      AppSignals.on(openConsoleSignal).listen(signals.add);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(titleBarConsoleOpenerProvider)('a', 'Alpha');
      expect(signals.single.detail, {'id': 'a', 'name': 'Alpha'});
    });
  });
}
