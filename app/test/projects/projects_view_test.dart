import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/bulk_tag_modal.dart';
import 'package:godothub/modals/category_manager_modal.dart';
import 'package:godothub/modals/tag_manager_modal.dart';
import 'package:godothub/projects/category_sections.dart';
import 'package:godothub/projects/project_card.dart';
import 'package:godothub/projects/project_tile.dart';
import 'package:godothub/projects/projects_view.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/keyboard_shortcuts.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/ui/dnd/sortable.dart';
import 'package:godothub/ui/overlays/slash_menu.dart';
import 'package:godothub/ui/reusables/view_header.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

Project project(
  String id,
  String name, {
  String? category,
  bool pinned = false,
  int order = 0,
  List<String> tags = const [],
  String version = '4.3',
}) => Project(
  id: id,
  name: name,
  path: 'C:/games/$id',
  godotVersion: version,
  createdAt: '2026-01-0${order + 1}T00:00:00Z',
  category: category,
  pinned: pinned,
  sortOrder: order,
  launchArguments: '',
  tags: tags,
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

Category category(String id, String name, {int order = 0, bool hidden = false}) =>
    Category(id: id, name: name, sortOrder: order, color: '#457ff2', hidden: hidden, folders: const []);

const installed = InstalledGodotVersion(
  tag: '4.3',
  version: '4.3',
  executablePath: 'C:/godot/4.3.exe',
  isMono: false,
  installedAt: '',
  supportsConsole: true,
);

AppSettings viewSettings({bool categories = false, bool customize = false}) => copySettings(
  baseSettings,
  setupComplete: true,
  categoriesEnabled: categories,
  customizeViewEnabled: customize,
  cardShowTags: true,
);

late FakeRustApi rust;
late UiPrefsStore prefs;
late List<Project> store;
List<List<String>> reorders = [];
List<String> removed = [];

void backend(List<Project> projects, {List<Category> categories = const []}) {
  store = List.of(projects);
  reorders = [];
  removed = [];
  var cats = List.of(categories);
  rust
    ..on('crateApiProjectsListProjects', () async => store)
    ..on('crateApiProjectsGetProjectName', ({required String path}) async => null)
    ..on('crateApiProjectsGetProjectIcon', ({required String path}) async => null)
    ..on('crateApiSettingsRefreshTrayMenu', () async {})
    ..on('crateApiGitBatchGitStatus', ({required List<String> paths}) async => <String, GitStatus>{})
    ..on('crateApiCategoriesListCategories', () async => cats)
    ..on('crateApiGodotVersionsListInstalledVersions', () async => [installed])
    ..on('crateApiWorkspaceListWorkspaces', () async => const WorkspacesState(workspaces: [], activeId: ''))
    ..on('crateApiProjectsReorderProjects', ({required List<String> orderedIds}) async => reorders.add(orderedIds))
    ..on('crateApiProjectsRemoveProject', ({required String id, required bool deleteFiles}) async {
      removed.add(id);
      store = [for (final p in store) if (p.id != id) p];
    })
    ..on('crateApiProjectsUpdateProject', ({required String id, required ProjectUpdate updates}) async {
      final index = store.indexWhere((p) => p.id == id);
      return store[index];
    })
    ..on('crateApiCategoriesCreateCategory', ({required String name, String? color}) async {
      final created = category('c${cats.length + 1}', name, order: cats.length);
      cats = [...cats, created];
      return created;
    });
}

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(file).readAsBytesSync())));
  }
  await loader.load();
}

Future<void> pumpView(WidgetTester tester, AppSettings settings, {Size size = const Size(1400, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fakeSettings(() => settings)],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        builder: (context, child) => GhKeyboardShortcuts(child: child!),
        home: Scaffold(body: ProjectsView(prefs: prefs)),
      ),
    ),
  );
  await settle(tester);
}

Future<void> settle(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder card(String id) => find.byKey(ValueKey('card:$id'));

Finder searchField() => find.descendant(of: find.byType(ProjectsView), matching: find.byType(TextField)).first;

Future<void> dragCard(WidgetTester tester, String from, Offset to) async {
  final start = tester.getTopLeft(card(from)) + const Offset(6, 6);
  final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
  await tester.pump();
  for (var i = 1; i <= 10; i++) {
    await gesture.moveTo(Offset.lerp(start, to, i / 10)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await settle(tester, 8);
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
    ProjectsViewPrefs.session.clear();
  });

  testWidgets('lists projects with a pinned section and the animated count', (tester) async {
    backend([project('a', 'Alpha', order: 1), project('b', 'Beta', pinned: true), project('c', 'Gamma', order: 2)]);
    await pumpView(tester, viewSettings());
    expect(card('a'), findsOneWidget);
    expect(card('b'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);
    expect(tester.getTopLeft(card('b')).dy, lessThan(tester.getTopLeft(card('a')).dy));
    expect(tester.getTopLeft(card('a')).dy, lessThan(tester.getTopLeft(card('c')).dy));
  });

  testWidgets('search narrows the list and the slash menu inserts a field', (tester) async {
    backend([project('a', 'Alpha', tags: ['jam']), project('b', 'Beta')]);
    await pumpView(tester, viewSettings());
    await tester.enterText(searchField(), 'alp');
    await settle(tester, 5);
    expect(card('a'), findsOneWidget);
    expect(card('b'), findsNothing);

    await tester.enterText(searchField(), '/');
    await settle(tester, 5);
    expect(find.byType(GhSlashMenu), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester, 5);
    final field = tester.widget<TextField>(searchField());
    expect(field.controller!.text, 'tag:');
    expect(find.text('jam'), findsWidgets);
  });

  testWidgets('sort choice is saved and reorders the list', (tester) async {
    backend([project('a', 'Zulu', order: 0), project('b', 'Alpha', order: 1)]);
    await pumpView(tester, viewSettings());
    expect(tester.getTopLeft(card('a')).dy, lessThan(tester.getTopLeft(card('b')).dy));
    await tester.tap(find.text('Sort'));
    await settle(tester, 5);
    await tester.tap(find.text('Name (A–Z)').last);
    await settle(tester, 5);
    expect(prefs.getItem(ProjectsViewPrefs.sortBy), 'name_asc');
    expect(tester.getTopLeft(card('b')).dy, lessThan(tester.getTopLeft(card('a')).dy));
  });

  testWidgets('view mode follows the switch-view signal and is saved', (tester) async {
    backend([project('a', 'Alpha'), project('b', 'Beta')]);
    await pumpView(tester, viewSettings(customize: true));
    AppSignals.emit(switchViewSignal, 'grid');
    await settle(tester, 5);
    expect(find.byType(ProjectTile), findsNWidgets(2));
    expect(prefs.getItem(ProjectsViewPrefs.viewMode), 'grid');
    AppSignals.emit(switchViewSignal, 'kanban');
    await settle(tester, 5);
    expect(find.text('Uncategorized'), findsOneWidget);
  });

  testWidgets('dragging a card below another reorders and switches to manual sort', (tester) async {
    backend([project('a', 'Alpha', order: 0), project('b', 'Beta', order: 1), project('c', 'Gamma', order: 2)]);
    await pumpView(tester, viewSettings());
    final target = tester.getBottomLeft(card('b')) + const Offset(40, -6);
    await dragCard(tester, 'a', target);
    expect(reorders, [
      ['b', 'a', 'c'],
    ]);
    expect(prefs.getItem(ProjectsViewPrefs.sortBy), 'manual');
    expect(tester.getTopLeft(card('b')).dy, lessThan(tester.getTopLeft(card('a')).dy));
  });

  testWidgets('dragging into another category moves the project', (tester) async {
    backend(
      [project('a', 'Alpha', category: 'Games', order: 0), project('b', 'Beta', category: 'Tools', order: 1)],
      categories: [category('c1', 'Games'), category('c2', 'Tools', order: 1)],
    );
    final changes = <String>[];
    rust.on('crateApiProjectsUpdateProject', ({required String id, required ProjectUpdate updates}) async {
      changes.add('$id:${updates.category}');
      return store.firstWhere((p) => p.id == id);
    });
    await pumpView(tester, viewSettings(categories: true));
    expect(find.byType(ProjectCategorySection), findsNWidgets(3));
    await dragCard(tester, 'a', tester.getCenter(card('b')) + const Offset(0, 10));
    expect(changes, ['a:Tools']);
  });

  testWidgets('modifier clicks select cards and the selection bar removes them', (tester) async {
    backend([project('a', 'Alpha'), project('b', 'Beta')]);
    await pumpView(tester, viewSettings());
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tapAt(tester.getTopLeft(card('a')) + const Offset(6, 6));
    await tester.tapAt(tester.getTopLeft(card('b')) + const Offset(6, 6));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester, 5);
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await settle(tester, 5);
    expect(find.text('REMOVE 2 PROJECTS FROM LIBRARY?'), findsOneWidget);
    await tester.tap(find.text('Remove').last);
    await settle(tester, 8);
    expect(removed, ['a', 'b']);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('escape clears the selection', (tester) async {
    backend([project('a', 'Alpha')]);
    await pumpView(tester, viewSettings());
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tapAt(tester.getTopLeft(card('a')) + const Offset(6, 6));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester, 5);
    expect(find.text('1 selected'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester, 8);
    expect(find.text('1 selected'), findsNothing);
  });

  testWidgets('tag clicks filter by tag until cleared', (tester) async {
    backend([project('a', 'Alpha', tags: ['jam']), project('b', 'Beta')]);
    await pumpView(tester, viewSettings());
    await tester.tap(find.text('jam').first);
    await settle(tester, 5);
    expect(card('b'), findsNothing);
    expect(ProjectsViewPrefs.session[ProjectsViewPrefs.tagFilter], 'jam');
    await tester.tap(find.byTooltip('Clear tag filter'));
    await settle(tester, 5);
    expect(card('b'), findsOneWidget);
  });

  testWidgets('category manager creates a category', (tester) async {
    backend([project('a', 'Alpha')]);
    await pumpView(tester, viewSettings(categories: true));
    await tester.tap(
      find.descendant(of: find.byType(GhViewHeader), matching: find.byWidgetPredicate((w) => w is GhIcon && w.icon == GhIcons.tags)),
    );
    await settle(tester, 8);
    expect(find.byType(CategoryManagerModal), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(CategoryManagerModal), matching: find.byType(TextField)), 'Prototypes');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 8);
    expect(rust.callCount('crateApiCategoriesCreateCategory'), 1);
    expect(find.descendant(of: find.byType(CategoryManagerModal), matching: find.text('Prototypes')), findsOneWidget);
  });

  testWidgets('tag manager saves the edited tags', (tester) async {
    List<String>? saved;
    backend([project('a', 'Alpha', tags: ['old'])]);
    rust.on('crateApiProjectsWriteProjectTags', ({required String id, required String path, required List<String> tags}) async {
      saved = tags;
      return project('a', 'Alpha', tags: tags);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: TagManagerModal(project: project('a', 'Alpha', tags: ['old']), onClose: () {}, onSaved: (_) {}),
        ),
      ),
    );
    await settle(tester, 5);
    await tester.enterText(find.byType(TextField).first, 'new');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 3);
    await tester.tap(find.text('old'));
    await settle(tester, 3);
    await tester.enterText(find.byType(TextField).last, 'renamed');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 3);
    await tester.tap(find.text('Save'));
    await settle(tester, 5);
    expect(saved, ['renamed', 'new']);
  });

  testWidgets('bulk tags add to every selected project', (tester) async {
    final writes = <String>[];
    backend([project('a', 'Alpha'), project('b', 'Beta')]);
    rust.on('crateApiProjectsWriteProjectTags', ({required String id, required String path, required List<String> tags}) async {
      writes.add('$id:${tags.join(',')}');
      return project(id, id, tags: tags);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: BulkTagModal(projects: [project('a', 'Alpha'), project('b', 'Beta')], onClose: () {}, onApplied: () {}),
        ),
      ),
    );
    await settle(tester, 5);
    await tester.enterText(find.byType(TextField), 'jam');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 5);
    expect(writes, ['a:jam', 'b:jam']);
    expect(find.text('2/2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });

  test('vertical sortable offsets match dnd-kit', () {
    final model = GhDndModel();
    expect(model.offsetFor('a', ['a', 'b', 'c'], GhSortStrategy.vertical), Offset.zero);
  });

  testWidgets('a project card shows git branch chips and opens the tag input', (tester) async {
    backend([project('a', 'Alpha')]);
    rust.on(
      'crateApiGitBatchGitStatus',
      ({required List<String> paths}) async => {'C:/games/a': const GitStatus(branch: 'main', hasUncommitted: true, isRepo: true)},
    );
    await pumpView(tester, viewSettings());
    expect(find.text('main'), findsOneWidget);
    expect(find.byType(ProjectCard), findsOneWidget);
  });
}
