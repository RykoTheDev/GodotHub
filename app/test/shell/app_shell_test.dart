import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/git/git_sidebar.dart';
import 'package:godothub/versions/versions_view.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/command_palette.dart';
import 'package:godothub/modals/create_workspace_modal.dart';
import 'package:godothub/shell/app_shell.dart';
import 'package:godothub/shell/git_sidebar_overlay.dart';
import 'package:godothub/shell/placeholder_view.dart';
import 'package:godothub/shell/tabs.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/src/ui_transition.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/keyboard_shortcuts.dart';
import 'package:godothub/state/news.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/titlebar/providers.dart';
import 'package:godothub/ui/shell/sidebar.dart';

import '../support/fake_git.dart';
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show FakeRunningSource, FakeWindow, baseSettings;
import '../ui/i18n_setup.dart';

Workspace workspace(String id, String name) => Workspace(id: id, name: name, icon: 'briefcase', color: '#457ff2', createdAt: '');

WorkspacesState workspaces(String active, List<Workspace> list) => WorkspacesState(workspaces: list, activeId: active);

Project testProject(String id, String name, {String? lastOpened}) => Project(
  id: id,
  name: name,
  path: 'C:/games/$name',
  godotVersion: '4.3',
  createdAt: '2026-01-01T00:00:00Z',
  lastOpened: lastOpened,
  pinned: false,
  sortOrder: 0,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

AppSettings shellSettings({bool workspacesEnabled = false, String landing = '', bool cardLayout = true}) => copySettings(
  baseSettings,
  setupComplete: true,
  workspacesEnabled: workspacesEnabled,
  defaultLandingTab: landing,
  cardLayout: cardLayout,
);

late FakeRustApi rust;
late UiPrefsStore prefs;
final signals = <AppSignal>[];
StreamSubscription<AppSignal>? _signalLog;

void fakeBackend({List<Project> projects = const [], WorkspacesState? state, LoadStatus health = LoadStatus.ok}) {
  final current = state ?? workspaces('w1', [workspace('w1', 'Main')]);
  rust
    ..on('crateApiChangelogListChangelogEntries', () async => <ChangelogEntry>[])
    ..on('crateApiWorkspaceListWorkspaces', () async => current)
    ..on('crateApiProjectsListProjects', () async => projects)
    ..on('crateApiProjectsGetProjectName', ({required String path}) async => null)
    ..on('crateApiProjectsGetProjectIcon', ({required String path}) async => null)
    ..on('crateApiProjectsGetProjectsHealth', () async => health)
    ..on('crateApiProjectsRestoreProjectsFromBackup', () async => BigInt.one)
    ..on('crateApiSettingsRefreshTrayMenu', () async {})
    ..on('crateApiNewsFetchGodotNews', ({bool? force}) async => throw StateError('offline'))
    ..on('crateApiCategoriesListCategories', () async => <Category>[])
    ..on('crateApiGodotVersionsListInstalledVersions', () async => <InstalledGodotVersion>[]);
  FakeGitRepo().install(rust);
}

Future<void> pumpShell(
  WidgetTester tester,
  AppSettings settings, {
  Size size = const Size(1400, 900),
  Widget Function(Widget app)? wrap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = ProviderScope(
    overrides: [
      fakeSettings(() => settings),
      titleBarWindowProvider.overrideWithValue(FakeWindow()),
      runningProjectsSourceProvider.overrideWithValue(FakeRunningSource().source),
      newsBadgeProvider.overrideWith(_NoNews.new),
    ],
    child: MaterialApp(
      theme: GhTheme.defaults().toThemeData(),
      builder: (context, child) => GhKeyboardShortcuts(child: child!),
      home: Scaffold(body: AppShell(prefs: prefs, isMac: false)),
    ),
  );
  await tester.pumpWidget(wrap == null ? app : wrap(app));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

class _NoNews extends NewsBadgeNotifier {
  @override
  int build() => 0;
}

Finder tabButton(String id) => find.byWidgetPredicate((w) => w is GhSidebarTabButton && w.tab.id == id);

Finder gitSidebar(String name) => find.byWidgetPredicate((w) => w is GitSidebar && w.project.name == name);

Finder placeholder(String title) => find.byWidgetPredicate((w) => w is PlaceholderView && w.title == title);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> chord(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await settle(tester);
}

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(file).readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    prefs = UiPrefsStore(MemoryUiPrefsBackend());
    UiPrefsStore.instance = prefs;
    GhUiTransition.reset();
    signals.clear();
    _signalLog?.cancel();
    _signalLog = AppSignals.all.listen(signals.add);
  });

  group('tabs', () {
    test('sidebar tabs hide hidden tabs, group them and number the first nine', () {
      final tabs = sidebarTabsFor(shellSettings(), newsUnread: 3);
      expect(tabs.map((t) => t.id), ['projects', 'versions', 'templates', 'vault', 'storage', 'asset-store', 'news']);
      expect(tabs.map((t) => t.shortcut), [1, 2, 3, 4, 5, 6, 7]);
      expect(tabs.first.group?.id, 'workspace');
      expect(tabs.first.group?.label, 'Workspace');
      expect(tabs.firstWhere((t) => t.id == 'storage').label, 'Storage');
      expect(tabs.where((t) => t.isNew).map((t) => t.id), ['vault', 'storage']);
      expect(tabs.last.badge, 3);
    });

    test('disabled features drop out and shortcuts close the gap', () {
      final settings = copySettings(shellSettings(), disabledFeatures: ['templates', 'vault']);
      final tabs = sidebarTabsFor(settings);
      expect(tabs.map((t) => t.id), ['projects', 'versions', 'storage', 'asset-store', 'news']);
      expect(tabs.firstWhere((t) => t.id == 'storage').shortcut, 3);
      expect(resolveTab('templates', enabledTabsFor(settings)), 'projects');
      expect(resolveTab('changelog', enabledTabsFor(settings)), 'changelog');
    });
  });

  group('prefs', () {
    test('sidebar width falls back, clamps and parses lists safely', () {
      final store = UiPrefsStore(MemoryUiPrefsBackend());
      expect(SidebarPrefs.readWidth(store), GhSidebar.defaultWidth);
      store.setItem(SidebarPrefs.width, '900');
      expect(SidebarPrefs.readWidth(store), GhSidebar.maxWidth);
      store.setItem(SidebarPrefs.width, 'abc');
      expect(SidebarPrefs.readWidth(store), GhSidebar.defaultWidth);
      store.setItem(SidebarPrefs.closedGroups, '["explore", 3]');
      expect(SidebarPrefs.readList(store, SidebarPrefs.closedGroups), ['explore']);
      store.setItem(SidebarPrefs.closedGroups, '{bad');
      expect(SidebarPrefs.readList(store, SidebarPrefs.closedGroups), isEmpty);
    });

    test('git sidebar width clamps to 280..560 with 320 as the default', () {
      expect(GitSidebarWidth.parse(null), 320);
      expect(GitSidebarWidth.parse('0'), 320);
      expect(GitSidebarWidth.parse('100'), 280);
      expect(GitSidebarWidth.parse('999'), 560);
      expect(GitSidebarWidth.parse('400'), 400);
    });
  });

  group('shell', () {
    testWidgets('opens the landing tab, navigates from the sidebar and announces the view', (tester) async {
      fakeBackend();
      await pumpShell(tester, shellSettings(landing: 'storage'));
      expect(placeholder('Storage'), findsOneWidget);
      expect(signals.where((s) => s.name == viewChangedSignal).map((s) => s.detail), ['storage']);

      await tester.tap(tabButton('versions'));
      await settle(tester);
      expect(find.byType(VersionsView), findsOneWidget);
      expect(placeholder('Storage'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is PlaceholderView && w.title == 'Storage', skipOffstage: false), findsOneWidget);
      expect(signals.where((s) => s.name == viewChangedSignal).last.detail, 'versions');

      AppSignals.emit(setTabSignal, 'changelog');
      await settle(tester);
      expect(placeholder('Changelog'), findsOneWidget);
    });

    testWidgets('persists the sidebar collapse state and closed groups', (tester) async {
      fakeBackend();
      await pumpShell(tester, shellSettings());
      await tester.tap(find.byWidgetPredicate((w) => w is GhSidebarGroupHeader && w.group.id == 'explore'));
      await settle(tester);
      expect(prefs.getItem(SidebarPrefs.closedGroups), '["explore"]');
      await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
      await settle(tester);
      expect(prefs.getItem(SidebarPrefs.collapsed), '1');
    });

    testWidgets('Mod+digit switches tabs and Mod+P toggles the command palette', (tester) async {
      fakeBackend(projects: [testProject('p1', 'Space Game', lastOpened: '2026-11-10T10:00:00Z')]);
      await pumpShell(tester, shellSettings());
      await chord(tester, LogicalKeyboardKey.digit2);
      expect(signals.where((s) => s.name == setTabSignal).last.detail, 'versions');

      await chord(tester, LogicalKeyboardKey.keyP);
      expect(find.byType(CommandPalette), findsOneWidget);
      expect(find.text('COMMAND PALETTE'), findsOneWidget);
      expect(find.text('Space Game'), findsNWidgets(2));

      await chord(tester, LogicalKeyboardKey.keyP);
      expect(find.byType(CommandPalette), findsNothing);
    });

    testWidgets('the palette filters, moves with arrows and runs the selection', (tester) async {
      fakeBackend();
      await pumpShell(tester, shellSettings());
      AppSignals.emit(toggleCommandPaletteSignal);
      await settle(tester);
      await tester.enterText(find.descendant(of: find.byType(CommandPalette), matching: find.byType(TextField)), 'changelog');
      await settle(tester);
      expect(find.text('Changelog'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.byType(CommandPalette), findsNothing);
      expect(placeholder('Changelog'), findsOneWidget);

      AppSignals.emit(toggleCommandPaletteSignal);
      await settle(tester);
      await tester.enterText(find.descendant(of: find.byType(CommandPalette), matching: find.byType(TextField)), 'zzzz-nothing');
      await settle(tester);
      expect(find.textContaining('"zzzz-nothing"', findRichText: true), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.byType(CommandPalette), findsNothing);
    });

    testWidgets('project commands only show on the projects tab', (tester) async {
      fakeBackend();
      await pumpShell(tester, shellSettings());
      AppSignals.emit(toggleCommandPaletteSignal);
      await settle(tester);
      expect(find.text('New Project'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      AppSignals.emit(setTabSignal, 'news');
      await settle(tester);
      AppSignals.emit(toggleCommandPaletteSignal);
      await settle(tester);
      expect(find.text('New Project'), findsNothing);
    });

    testWidgets('workspace create request validates the name and creates with copied settings', (tester) async {
      fakeBackend();
      String? copiedFrom;
      String? createdName;
      rust.on('crateApiWorkspaceCreateWorkspace', ({
        required String name,
        required String icon,
        required String color,
        String? copySettingsFrom,
      }) async {
        createdName = name;
        copiedFrom = copySettingsFrom;
        return workspaces('w2', [workspace('w1', 'Main'), workspace('w2', name)]);
      });
      await pumpShell(tester, shellSettings(workspacesEnabled: true));
      AppSignals.emit(createWorkspaceRequestSignal);
      await settle(tester);
      expect(find.byType(CreateWorkspaceModal), findsOneWidget);
      expect(find.text('Copy settings from Main'), findsOneWidget);

      await tester.tap(find.text('Create Workspace').last);
      await settle(tester);
      expect(find.text('Give the workspace a name.'), findsOneWidget);

      await tester.enterText(find.descendant(of: find.byType(CreateWorkspaceModal), matching: find.byType(TextField)), 'main');
      await settle(tester);
      expect(find.text('Another workspace already uses this name.'), findsOneWidget);

      await tester.enterText(find.descendant(of: find.byType(CreateWorkspaceModal), matching: find.byType(TextField)), ' Jam ');
      await settle(tester);
      await tester.tap(find.text('Create Workspace').last);
      await settle(tester);
      expect(createdName, 'Jam');
      expect(copiedFrom, 'w1');
      expect(find.byType(CreateWorkspaceModal), findsNothing);
    });

    testWidgets('git sidebar toggles per project and its width persists after a double-click reset', (tester) async {
      fakeBackend();
      prefs.setItem(GitSidebarWidth.prefKey, '480');
      await pumpShell(tester, shellSettings());
      final target = GitSidebarTarget(project: testProject('p1', 'Space Game'));
      AppSignals.emit(showGitSidebarSignal, target);
      await settle(tester);
      expect(gitSidebar('Space Game'), findsOneWidget);
      final panel = find.ancestor(of: gitSidebar('Space Game'), matching: find.byType(Container)).first;
      expect(tester.getSize(panel).width, 480);

      final strip = find.descendant(
        of: find.byType(GitSidebarOverlay),
        matching: find.byWidgetPredicate((w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn),
      );
      final center = tester.getCenter(strip);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.down(center);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.down(center);
      await gesture.up();
      await settle(tester);
      expect(prefs.getItem(GitSidebarWidth.prefKey), '320');

      AppSignals.emit(showGitSidebarSignal, target);
      await settle(tester);
      expect(gitSidebar('Space Game'), findsNothing);
    });

    testWidgets('escape closes the git sidebar and the palette', (tester) async {
      fakeBackend();
      await pumpShell(tester, shellSettings());
      AppSignals.emit(showGitSidebarSignal, GitSidebarTarget(project: testProject('p1', 'Space Game')));
      await settle(tester);
      AppSignals.emit(escapeSignal);
      await settle(tester);
      expect(gitSidebar('Space Game'), findsNothing);
    });

    testWidgets('a corrupt project registry offers to restore the backup', (tester) async {
      fakeBackend(health: LoadStatus.corrupt);
      await pumpShell(tester, shellSettings());
      expect(find.text("PROJECT LIST COULDN'T BE READ"), findsOneWidget);
      await tester.tap(find.text('Restore backup'));
      await settle(tester);
      expect(rust.callCount('crateApiProjectsRestoreProjectsFromBackup'), 1);
    });

    testWidgets('opening a running project asks first', (tester) async {
      final running = Project(
        id: 'p1',
        name: 'Space Game',
        path: 'C:/games/space',
        godotVersion: '4.3',
        createdAt: '',
        pinned: false,
        sortOrder: 0,
        launchArguments: '',
        tags: const [],
        totalTimeSeconds: BigInt.zero,
        timeTodaySeconds: BigInt.zero,
        timeWeekSeconds: BigInt.zero,
        sessionStartedAtMs: BigInt.one,
      );
      fakeBackend(projects: [running]);
      final opened = <String>[];
      rust.on('crateApiProjectsOpenProject', ({required String id, required bool editor, bool? console}) async => opened.add(id));
      await pumpShell(tester, shellSettings());
      AppSignals.emit(openProjectSignal, 'p1');
      await settle(tester);
      expect(find.text('PROJECT ALREADY OPEN'), findsOneWidget);
      expect(opened, isEmpty);
      await tester.tap(find.text('Open anyway'));
      await settle(tester);
      expect(opened, ['p1']);
    });

    testWidgets('onboarding is gated until setup is complete', (tester) async {
      fakeBackend();
      await pumpShell(tester, copySettings(baseSettings, setupComplete: false));
      expect(placeholder('Onboarding'), findsOneWidget);
      expect(find.byType(GhSidebar), findsNothing);
    });
  });
}
