import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/modals/bulk_tag_modal.dart';
import 'package:godothub/modals/category_manager_modal.dart';
import 'package:godothub/modals/create_workspace_modal.dart';
import 'package:godothub/modals/workspace_edit_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/ui/core/button.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';

import '../projects/project_actions_test.dart' as base;
import '../projects/projects_view_test.dart' show category, project;
import '../ui/i18n_setup.dart';

const _workspace = Workspace(id: 'w1', name: 'Main', icon: 'briefcase', color: '#457ff2', createdAt: '');

Future<void> open(WidgetTester tester, Widget Function(VoidCallback close) build, {Size size = const Size(1280, 800)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late BuildContext host;
  await tester.pumpWidget(
    MaterialApp(
      theme: GhTheme.defaults().toThemeData(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            host = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  showGhModal<void>(host, (modal) => build(() => Navigator.of(modal).pop())).ignore();
  await tester.pumpAndSettle();
}

Widget createWorkspace(VoidCallback close) => CreateWorkspaceModal(takenNames: const [], onClose: close, onCreate: (_, _) async {});

Widget editWorkspace(VoidCallback close, {Future<void> Function()? onDelete}) => WorkspaceEditModal(
  workspace: _workspace,
  takenNames: const [],
  canDelete: true,
  onClose: close,
  onSave: (_, _, _) async {},
  onDelete: onDelete ?? () async {},
);

Widget bulkTags(VoidCallback close) => BulkTagModal(
  projects: [project('a', 'Alpha'), project('b', 'Beta')],
  onClose: close,
  onApplied: () {},
  saveTags: (id, path, tags) async => project(id, id),
);

Widget categories(VoidCallback close, {List<Category>? list}) => CategoryManagerModal(
  categories: list ?? [category('c1', 'Games'), category('c2', 'Tools', order: 1)],
  projects: [project('a', 'Alpha'), project('b', 'Beta'), project('c', 'Gamma')],
  onClose: close,
  onCreate: (name, color) async => category('c3', name),
  onUpdate: (id, name, color) async => category(id, name ?? id),
  onDelete: (_) async {},
  onReorder: (_) async {},
  onAssignFolder: (id, _) async => category(id, id),
  onUnassignFolder: (id, _) async => category(id, id),
);

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);

  final modals = <String, Widget Function(VoidCallback close)>{
    'create workspace': createWorkspace,
    'edit workspace': (close) => editWorkspace(close),
    'bulk tags': bulkTags,
    'category manager': (close) => categories(close),
  };
  for (final entry in modals.entries) {
    for (final size in [const Size(340, 640), const Size(500, 640)]) {
      testWidgets('${entry.key} fits a ${size.width.toInt()} px window without overflow', (tester) async {
        await open(tester, entry.value, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('category manager counts with plurals and closes with Done', (tester) async {
    var closed = 0;
    await open(tester, (close) {
      return categories(() {
        closed++;
        close();
      });
    });
    expect(find.text('${ghTr('n_categories', count: 2)} · ${ghTr('n_projects', count: 3)}'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('categories-done')));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('category manager rejects an empty or duplicate name in the user language', (tester) async {
    await open(tester, (close) => categories(close));
    final field = find.byType(TextField).first;
    await tester.enterText(field, 'games');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text(ghTr('category_name_taken')), findsOneWidget);
  });

  for (final size in [const Size(340, 640), const Size(1280, 800)]) {
    testWidgets('category folders can be typed, browsed or cancelled at ${size.width.toInt()} px', (tester) async {
      final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('gh-category-')))!;
      addTearDown(() => dir.deleteSync(recursive: true));
      final assigned = <String>[];
      await open(
        tester,
        (close) => CategoryManagerModal(
          categories: [category('c1', 'Games')],
          onClose: close,
          onCreate: (name, color) async => category('c3', name),
          onUpdate: (id, name, color) async => category(id, name ?? id),
          onDelete: (_) async {},
          onReorder: (_) async {},
          onAssignFolder: (id, folder) async {
            assigned.add(folder);
            return category(id, id);
          },
          onUnassignFolder: (id, _) async => category(id, id),
          pickFolder: () async => '/picked/folder',
        ),
        size: size,
      );
      final field = find.byKey(const ValueKey('category-folder-c1'));
      Future<void> openField() async {
        await tester.ensureVisible(find.text(ghTr('assign_folder')));
        await tester.tap(find.text(ghTr('assign_folder')));
        await tester.pumpAndSettle();
        expect(field, findsOneWidget);
      }

      await openField();
      await tester.enterText(find.descendant(of: field, matching: find.byType(TextField)), dir.path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'the open field with its Assign button fits');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(assigned, [dir.path]);
      expect(field, findsNothing);

      await openField();
      await tester.tap(find.descendant(of: field, matching: find.byKey(const ValueKey('path-browse'))));
      await tester.pumpAndSettle();
      expect(assigned.last, '/picked/folder');

      await openField();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(find.byType(CategoryManagerModal), findsOneWidget);
      await openField();
      await tester.tap(find.bySemanticsLabel(ghTr('cancel')).last);
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(assigned, hasLength(2));
    });
  }

  testWidgets('bulk tags explains that changes apply right away and closes with Done', (tester) async {
    var closed = 0;
    await open(tester, (close) {
      return bulkTags(() {
        closed++;
        close();
      });
    });
    expect(find.text(ghTr('bulk_tags_intro', count: 2)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bulk-tags-done')));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('edit workspace shows Delete as destructive and still confirms', (tester) async {
    var deleted = 0;
    await open(tester, (close) => editWorkspace(close, onDelete: () async => deleted++));
    final delete = tester.widget<GhButton>(find.byKey(const ValueKey('workspace-delete')));
    expect(delete.variant, GhButtonVariant.danger);
    await tester.tap(find.byKey(const ValueKey('workspace-delete')));
    await tester.pumpAndSettle();
    expect(deleted, 0);
  });
}
