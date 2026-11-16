import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/card_view_settings.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/projects/project_actions.dart';
import 'package:godothub/projects/project_tile.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/projects/project_layouts.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/ui/controls/dashed_box.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

Project _project(String id, String name, {String? category, int order = 0, bool missing = false}) => Project(
  id: id,
  name: name,
  path: 'C:/games/$id',
  godotVersion: '4.3',
  createdAt: '2026-01-01T00:00:00Z',
  category: category,
  pinned: false,
  sortOrder: order,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
  missing: missing,
);

Category _category(String id, String name, {int order = 0}) =>
    Category(id: id, name: name, sortOrder: order, color: '#457ff2', hidden: false, folders: const []);

Finder _column(String key) => find.byKey(ValueKey('kanban:$key'));

final _menuIcon = find.byWidgetPredicate((w) => w is GhIcon && w.icon == GhIcons.more);

Finder _card(String id) => find.byKey(ValueKey('stub:$id'));

class _Calls {
  final moves = <String>[];
  final reorders = <List<String>>[];
  final menus = <String>[];
}

Future<_Calls> _pump(
  WidgetTester tester, {
  required List<Project> projects,
  required List<Category> categories,
  Size size = const Size(1400, 900),
  double? columnWidthUnits,
  ValueChanged<double>? onColumnWidthChanged,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: GhTheme.defaults().toThemeData(),
      home: Scaffold(
        body: ProjectCardKanban(
          projects: projects,
          categories: categories,
          selectedIds: const {},
          cardBuilder: (p, {preview = false}) =>
              Container(key: preview ? null : ValueKey('stub:${p.id}'), height: 80, color: Colors.grey, child: Text(p.name)),
          onReorder: (ids) => calls.reorders.add(ids),
          onMoveProjects: (ids, category, dest) => calls.moves.add('${ids.join(',')}:$category'),
          onCategoryContextMenu: (position, category) => calls.menus.add(category.name),
          columnWidthUnits: columnWidthUnits,
          onColumnWidthChanged: onColumnWidthChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

Future<void> _drag(WidgetTester tester, Finder from, Offset to) async {
  final start = tester.getTopLeft(from) + const Offset(10, 10);
  final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
  await tester.pump();
  for (var i = 1; i <= 12; i++) {
    await gesture.moveTo(Offset.lerp(start, to, i / 12)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  setUp(setUpTestI18n);

  final categories = [_category('c1', 'Games'), _category('c2', 'Tools', order: 1)];

  testWidgets('column headers show the category name and project count', (tester) async {
    await _pump(
      tester,
      projects: [
        _project('a', 'Alpha', category: 'Games'),
        _project('b', 'Beta', category: 'Games', order: 1),
        _project('u', 'Loose'),
      ],
      categories: categories,
    );
    expect(find.descendant(of: _column('c1'), matching: find.text('Games')), findsOneWidget);
    expect(find.descendant(of: _column('c1'), matching: find.text('2')), findsOneWidget);
    expect(find.descendant(of: _column('c2'), matching: find.text('Tools')), findsOneWidget);
    expect(find.descendant(of: _column('c2'), matching: find.text('0')), findsOneWidget);
    expect(find.descendant(of: _column('uncategorized'), matching: find.text('Uncategorized')), findsOneWidget);
    expect(find.descendant(of: _column('uncategorized'), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('an empty column shows a dashed drop zone with a hint', (tester) async {
    await _pump(
      tester,
      projects: [_project('a', 'Alpha', category: 'Games')],
      categories: categories,
    );
    expect(find.descendant(of: _column('c2'), matching: find.byType(GhDashedBox)), findsOneWidget);
    expect(find.descendant(of: _column('c2'), matching: find.text('No projects')), findsOneWidget);
    expect(find.descendant(of: _column('c2'), matching: find.text('Drag projects here')), findsOneWidget);
    expect(find.descendant(of: _column('c1'), matching: find.byType(GhDashedBox)), findsNothing);
  });

  testWidgets('the header options button is labelled and opens the category menu', (tester) async {
    final semantics = tester.ensureSemantics();
    final calls = await _pump(
      tester,
      projects: [_project('a', 'Alpha', category: 'Games')],
      categories: categories,
    );
    expect(find.bySemanticsLabel('Category options'), findsNWidgets(2));
    await tester.tap(find.descendant(of: _column('c2'), matching: _menuIcon));
    await tester.pumpAndSettle();
    expect(calls.menus, ['Tools']);
    expect(find.descendant(of: _column('uncategorized'), matching: _menuIcon), findsNothing);
    semantics.dispose();
  });

  testWidgets('only the column under a dragged card is highlighted', (tester) async {
    await _pump(
      tester,
      projects: [
        _project('a', 'Alpha', category: 'Games'),
        _project('b', 'Beta', category: 'Tools', order: 1),
      ],
      categories: categories,
    );
    final theme = GhTheme.defaults();
    Color border(String key) {
      final box = tester.widget<AnimatedContainer>(find.descendant(of: _column(key), matching: find.byType(AnimatedContainer)).first);
      return (box.decoration! as BoxDecoration).border!.top.color;
    }

    final start = tester.getTopLeft(_card('a')) + const Offset(10, 10);
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await tester.pump();
    final overTools = tester.getCenter(_card('b')) + const Offset(0, 120);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, overTools, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(border('c2'), theme.accent.withValues(alpha: 0.6));
    expect(border('c1'), isNot(theme.accent.withValues(alpha: 0.6)));

    final overEmpty = tester.getCenter(find.descendant(of: _column('uncategorized'), matching: find.byType(GhDashedBox)));
    await gesture.moveTo(overEmpty);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(border('uncategorized'), theme.accent.withValues(alpha: 0.6));
    expect(border('c2'), isNot(theme.accent.withValues(alpha: 0.6)));
    expect(find.descendant(of: _column('uncategorized'), matching: find.text('Release to drop')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dragging a card onto a card in another column moves it', (tester) async {
    final calls = await _pump(
      tester,
      projects: [
        _project('a', 'Alpha', category: 'Games'),
        _project('b', 'Beta', category: 'Tools', order: 1),
      ],
      categories: categories,
    );
    await _drag(tester, _card('a'), tester.getCenter(_card('b')) + const Offset(0, 10));
    expect(calls.moves, ['a:Tools']);
    expect(calls.reorders, isEmpty);
  });

  testWidgets('dragging a card into an empty column moves it', (tester) async {
    final calls = await _pump(
      tester,
      projects: [_project('a', 'Alpha', category: 'Games')],
      categories: categories,
    );
    final zone = find.descendant(of: _column('c2'), matching: find.byType(GhDashedBox));
    await _drag(tester, _card('a'), tester.getCenter(zone));
    expect(calls.moves, ['a:Tools']);
  });

  testWidgets('dragging below another card in the same column reorders it', (tester) async {
    final calls = await _pump(
      tester,
      projects: [
        _project('a', 'Alpha', category: 'Games'),
        _project('b', 'Beta', category: 'Games', order: 1),
      ],
      categories: categories,
    );
    await _drag(tester, _card('a'), tester.getBottomLeft(_card('b')) + const Offset(40, -6));
    expect(calls.reorders, [
      ['b', 'a'],
    ]);
    expect(calls.moves, isEmpty);
  });

  testWidgets('a narrow window keeps the column width and scrolls horizontally', (tester) async {
    final many = [for (var i = 0; i < 5; i++) _category('c$i', 'Category $i', order: i)];
    await _pump(
      tester,
      projects: [_project('a', 'Alpha', category: 'Category 0')],
      categories: many,
      size: const Size(700, 700),
    );
    expect(tester.takeException(), isNull);
    final theme = GhTheme.defaults();
    expect(tester.getSize(_column('c0')).width, theme.space(ProjectCardKanban.defaultColumnUnits(false)));
    final scrollable = tester.state<ScrollableState>(
      find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right).first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('a few columns keep their width and leave free space instead of stretching', (tester) async {
    await _pump(
      tester,
      projects: [_project('a', 'Alpha', category: 'Games')],
      categories: categories,
      size: const Size(1600, 700),
    );
    expect(tester.takeException(), isNull);
    final theme = GhTheme.defaults();
    expect(tester.getSize(_column('c1')).width, theme.space(ProjectCardKanban.defaultColumnUnits(false)));
    expect(tester.getTopRight(_column('uncategorized')).dx, lessThan(1000), reason: 'the board does not fill the window');
  });

  testWidgets('the column options button sits flush with the column end', (tester) async {
    await _pump(tester, projects: [_project('a', 'Alpha', category: 'Games')], categories: categories);
    final column = tester.getRect(_column('c1'));
    final button = tester.getRect(find.bySemanticsLabel(ghTr('category_options')).first);
    expect(column.right - button.right, lessThan(GhTheme.defaults().space(3)));
  });

  testWidgets('dragging a column edge resizes every column and reports the width', (tester) async {
    final saved = <double>[];
    await _pump(tester, projects: [_project('a', 'Alpha', category: 'Games')], categories: categories, onColumnWidthChanged: saved.add);
    final theme = GhTheme.defaults();
    final before = tester.getSize(_column('c1')).width;
    await tester.drag(find.byKey(const ValueKey('kanban-resize')).first, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single, closeTo(ProjectCardKanban.defaultColumnUnits(false) + 80 / theme.spacingUnit, 3));
    // The parent stores the width; a saved width is applied to all columns.
    await _pump(tester, projects: [_project('a', 'Alpha', category: 'Games')], categories: categories, columnWidthUnits: saved.single);
    expect(tester.getSize(_column('c1')).width, greaterThan(before + 60));
    expect(tester.getSize(_column('uncategorized')).width, tester.getSize(_column('c1')).width);
  });

  for (final compact in [false, true]) {
    testWidgets('a kanban card at the minimum column width keeps its name, version and open action readable (compact: $compact)', (
      tester,
    ) async {
      const installed = InstalledGodotVersion(
        tag: '4.3',
        version: '4.3',
        executablePath: 'C:/godot/4.3.exe',
        isMono: false,
        installedAt: '',
        supportsConsole: true,
      );
      installFakeRust()
        ..on('crateApiProjectsGetProjectName', ({required String path}) async => null)
        ..on('crateApiProjectsGetProjectIcon', ({required String path}) async => null);
      final settings = copySettings(baseSettings, setupComplete: true, cardShowPlay: true, cardShowConsole: true, cardShowTags: true);
      final theme = GhTheme.defaults();
      final column = theme.space(ProjectCardKanban.minColumnUnits);
      final cardWidth = column - theme.space(compact ? 2 : 2.5) * 2 - 2;
      final callbacks = ProjectCallbacks(onTogglePin: () {}, onVersionChange: (_) {}, onRemove: () {});
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fakeSettings(() => settings)],
          child: MaterialApp(
            theme: theme.toThemeData(),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: cardWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in [_project('a', 'A rather long project name that wraps'), _project('m', 'Offline', missing: true)])
                        ProjectTile(
                          key: ValueKey('tile:${p.id}'),
                          project: p,
                          installedVersions: const [installed],
                          callbacks: callbacks,
                          compact: compact,
                          viewMode: ProjectViewMode.kanban,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final normal = find.byKey(const ValueKey('tile:a'));
      bool clipped(Finder text) => tester.renderObject<RenderParagraph>(text).didExceedMaxLines;
      expect(clipped(find.descendant(of: normal, matching: find.text('4.3'))), isFalse);
      expect(clipped(find.descendant(of: normal, matching: find.text('Open'))), isFalse);
      final missing = find.byKey(const ValueKey('tile:m'));
      expect(find.descendant(of: missing, matching: find.text('Project folder unavailable')), findsOneWidget);
      expect(find.descendant(of: missing, matching: find.text('Remove from Library')), findsOneWidget);
    });
  }
}
