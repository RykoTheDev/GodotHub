import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/confirm_dialog.dart';
import 'package:godothub/vault/add_vault_item_modal.dart';
import 'package:godothub/vault/edit_vault_item_modal.dart';
import 'package:godothub/vault/save_to_vault_modal.dart';
import 'package:godothub/vault/vault_file_tree.dart';
import 'package:godothub/vault/vault_view.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

late FakeRustApi rust;

VaultFileEntry file(String path, {bool dir = false, int size = 0}) => VaultFileEntry(path: path, isDir: dir, size: BigInt.from(size));

VaultItem item(
  String id,
  String name, {
  String description = '',
  List<String> tags = const [],
  String createdAt = '2026-01-01T00:00:00Z',
  List<VaultFileEntry> files = const [],
}) => VaultItem(
  id: id,
  name: name,
  description: description,
  godotVersion: '4.3',
  createdAt: createdAt,
  sourceProjectIds: const [],
  tags: tags,
  files: files,
  path: 'C:/vault/$id',
);

final second = Project(
  id: 'p2',
  name: 'Second',
  path: 'C:/games/second',
  godotVersion: '4.3',
  createdAt: '2026-01-01T00:00:00Z',
  pinned: false,
  sortOrder: 1,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

class VaultBackend {
  List<VaultItem> items = [
    item('a', 'Player kit', description: 'Movement scripts', tags: ['player', 'scripts'], createdAt: '2026-02-01T00:00:00Z'),
    item(
      'b',
      'Shaders',
      tags: ['fx'],
      createdAt: '2026-03-01T00:00:00Z',
      files: [file('shaders', dir: true), file('shaders/water.gdshader', size: 2048)],
    ),
  ];
  final calls = <String>[];
  List<VaultProjectImportResult> Function(bool overwrite)? addResult;

  void install(FakeRustApi rust) {
    rust
      ..on('crateApiProjectsListProjects', () async => [base.demo, second])
      ..on('crateApiVaultListVaultItems', () async => items)
      ..on('crateApiVaultDeleteVaultItem', ({required String itemId}) async => calls.add('delete:$itemId'))
      ..on('crateApiVaultUpdateVaultItem', ({
        required String itemId,
        required String name,
        required String description,
        required List<String> tags,
      }) async {
        calls.add('update:$itemId:$name:${tags.join(',')}');
        return item(itemId, name, description: description, tags: tags);
      })
      ..on('crateApiProjectsGetProjectFileTree', ({required String path}) async {
        calls.add('tree:$path');
        return [
          ProjectFileEntry(path: 'addons', isDir: true, size: BigInt.zero),
          ProjectFileEntry(path: 'addons/tool.gd', isDir: false, size: BigInt.from(100)),
          ProjectFileEntry(path: 'main.tscn', isDir: false, size: BigInt.from(300)),
        ];
      })
      ..on('crateApiVaultSaveToVault', ({
        required String name,
        required String description,
        required List<String> tags,
        required List<VaultSaveSource> sources,
      }) async {
        calls.add(
          'save:$name:$description:${tags.join(',')}:${[for (final s in sources) '${s.projectId}=${s.paths.join('+')}'].join(';')}',
        );
        return item('c', name);
      })
      ..on('crateApiVaultAddVaultItemToProjects', ({
        required String itemId,
        required List<String> projectIds,
        required bool overwrite,
      }) async {
        calls.add('add:$itemId:${projectIds.join(',')}:$overwrite');
        return addResult?.call(overwrite) ??
            [
              for (final id in projectIds)
                VaultProjectImportResult(projectId: id, installed: const ['x'], conflicts: const [], skipped: false),
            ];
      });
  }
}

Future<void> pumpVault(WidgetTester tester) async {
  await base.pumpHost(tester, body: const VaultView());
  await base.settle(tester);
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    debugResetOpenTodos();
  });

  group('logic', () {
    test('filters by every active tag, searches name, description and tags, sorts', () {
      final items = VaultBackend().items;
      List<String> ids(List<VaultItem> list) => [for (final i in list) i.id];
      expect(ids(filterVaultItems(items, query: '', tags: const [], sort: VaultSort.nameAsc)), ['a', 'b']);
      expect(ids(filterVaultItems(items, query: '', tags: const [], sort: VaultSort.nameDesc)), ['b', 'a']);
      expect(ids(filterVaultItems(items, query: '', tags: const [], sort: VaultSort.newest)), ['b', 'a']);
      expect(ids(filterVaultItems(items, query: '', tags: const [], sort: VaultSort.oldest)), ['a', 'b']);
      expect(ids(filterVaultItems(items, query: 'movement', tags: const [], sort: VaultSort.nameAsc)), ['a']);
      expect(ids(filterVaultItems(items, query: 'FX', tags: const [], sort: VaultSort.nameAsc)), ['b']);
      expect(ids(filterVaultItems(items, query: '', tags: const ['player', 'scripts'], sort: VaultSort.nameAsc)), ['a']);
      expect(filterVaultItems(items, query: '', tags: const ['player', 'fx'], sort: VaultSort.nameAsc), isEmpty);
      expect(VaultSort.parse('newest'), VaultSort.newest);
      expect(VaultSort.parse('bogus'), VaultSort.nameAsc);
    });

    test('builds nested trees with implied folders', () {
      final tree = buildVaultTree([
        (path: 'a/b/c.gd', isDir: false, size: 5),
        (path: 'a', isDir: true, size: 0),
        (path: 'd.txt', isDir: false, size: 1),
      ]);
      expect([for (final n in tree) n.name], ['a', 'd.txt']);
      expect(tree.first.isDir, isTrue);
      expect(tree.first.children.single.rel, 'a/b');
      expect(tree.first.children.single.children.single.size, 5);
    });
  });

  group('vault view', () {
    testWidgets('shows the empty state', (tester) async {
      final backend = VaultBackend()..items = [];
      backend.install(rust);
      await pumpVault(tester);
      expect(find.textContaining('Your vault is empty'), findsOneWidget);
      expect(find.text(ghTr('vault_save_btn')), findsOneWidget);
    });

    testWidgets('filters with tag chips and search, and persists the sort', (tester) async {
      VaultBackend().install(rust);
      await pumpVault(tester);
      expect(find.text('Player kit'), findsOneWidget);
      expect(find.text('Shaders'), findsOneWidget);
      expect(find.text(ghTr('vault_item_count', count: 2).toUpperCase()), findsOneWidget);
      await tester.tap(find.text('fx').first);
      await base.settle(tester, 3);
      expect(find.text('Player kit'), findsNothing);
      expect(find.text('Shaders'), findsOneWidget);
      await tester.tap(find.text('fx').first);
      await base.settle(tester, 3);
      await tester.enterText(find.byType(TextField), 'nothing here');
      await base.settle(tester, 3);
      expect(find.text(ghTr('vault_no_match')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await base.settle(tester, 3);
      await tester.tap(find.text(ghTr('sort_name_asc')));
      await base.settle(tester, 3);
      await tester.tap(find.text(ghTr('sort_created_desc')).last);
      await base.settle(tester, 3);
      expect(UiPrefsStore.instance.getItem(vaultSortKey), 'newest');
      expect(tester.getTopLeft(find.text('Shaders')).dx, lessThan(tester.getTopLeft(find.text('Player kit')).dx));
    });

    testWidgets('deletes after confirming and edits an item', (tester) async {
      final backend = VaultBackend()..install(rust);
      await pumpVault(tester);
      await tester.tap(find.bySemanticsLabel(ghTr('vault_delete_action', args: {'name': 'Shaders'})));
      await base.settle(tester);
      expect(find.byType(GhConfirmDialog), findsOneWidget);
      await tester.tap(find.text(ghTr('delete')).last);
      await base.settle(tester);
      expect(backend.calls, contains('delete:b'));
      expect(find.text('Shaders'), findsNothing);

      await tester.tap(find.bySemanticsLabel(ghTr('vault_edit_action')));
      await base.settle(tester);
      expect(find.byType(EditVaultItemModal), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Hero kit');
      await tester.enterText(find.byType(TextField).at(3), 'core');
      await base.settle(tester, 2);
      await tester.tap(find.text(ghTr('add_tag')));
      await base.settle(tester, 3);
      await tester.tap(find.text(ghTr('save')));
      await base.settle(tester);
      expect(backend.calls, contains('update:a:Hero kit:player,scripts,core'));
      expect(find.text('Hero kit'), findsOneWidget);
      await base.drainToasts(tester);
    });

    testWidgets('previews an item with its file tree', (tester) async {
      VaultBackend().install(rust);
      await pumpVault(tester);
      await tester.tap(find.text('Shaders'));
      await base.settle(tester);
      expect(find.text(ghTr('file_count', count: 1), findRichText: true), findsNothing);
      expect(find.textContaining(ghTr('file_count', count: 1)), findsOneWidget);
      expect(find.text('water.gdshader'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
    });
  });

  group('modals', () {
    testWidgets('save collects selections per source and covers children of a folder', (tester) async {
      final backend = VaultBackend()..install(rust);
      var saved = 0;
      await base.openModal(tester, (close) => SaveToVaultModal(projects: [base.demo, second], onClose: close, onSaved: () => saved++));
      await tester.tap(find.text(ghTr('vault_select_project')));
      await base.settle(tester, 3);
      await tester.tap(find.text('Demo').last);
      await base.settle(tester);
      expect(backend.calls, contains('tree:C:/games/demo'));
      expect(find.text('tool.gd'), findsOneWidget);
      await tester.tap(find.text('tool.gd'));
      await base.settle(tester, 2);
      expect(find.text(ghTr('vault_selected_count', args: {'count': 1})), findsOneWidget);
      await tester.tap(find.text('addons'));
      await base.settle(tester, 2);
      expect(find.text(ghTr('vault_selected_count', args: {'count': 1})), findsOneWidget);
      await tester.tap(find.text('main.tscn'));
      await base.settle(tester, 2);

      await tester.tap(find.text(ghTr('vault_add_source')));
      await base.settle(tester, 3);
      expect(find.text(ghTr('vault_source_n', args: {'index': 2}).toUpperCase()), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ghTr('vault_remove_source')).last);
      await base.settle(tester, 3);

      await tester.enterText(find.byType(TextField).first, '  Starter  ');
      await base.settle(tester, 2);
      await tester.tap(find.text(ghTr('vault_save_btn')));
      await base.settle(tester);
      expect(backend.calls, contains('save:Starter:::p1=addons+main.tscn'));
      expect(saved, 1);
      await base.drainToasts(tester);
    });

    testWidgets('add shows conflicts and overwrites on confirm', (tester) async {
      final backend = VaultBackend()
        ..addResult = (overwrite) => [
          VaultProjectImportResult(
            projectId: 'p2',
            installed: const [],
            conflicts: overwrite ? const [] : const ['scripts/player.gd'],
            skipped: false,
          ),
        ];
      backend.install(rust);
      await base.openModal(tester, (close) => AddVaultItemModal(item: backend.items.first, projects: [base.demo, second], onClose: close));
      expect(find.text(ghTr('vault_selected_count', args: {'count': 0})), findsOneWidget);
      await tester.tap(find.text('Second'));
      await base.settle(tester, 2);
      await tester.tap(find.text(ghTr('vault_add_btn')));
      await base.settle(tester);
      expect(backend.calls, ['add:a:p2:false']);
      expect(find.text('scripts/player.gd'), findsOneWidget);
      expect(find.text(ghTr('vault_conflict_summary_desc', count: 1)), findsOneWidget);
      await tester.tap(find.text(ghTr('vault_overwrite_btn')));
      await base.settle(tester);
      expect(backend.calls, ['add:a:p2:false', 'add:a:p2:true']);
      expect(find.text(ghTr('vault_added_to_projects_toast', count: 1)), findsOneWidget);
      await base.drainToasts(tester);
    });

    testWidgets('add without conflicts applies straight away', (tester) async {
      final backend = VaultBackend()..install(rust);
      await base.openModal(tester, (close) => AddVaultItemModal(item: backend.items.first, projects: [base.demo, second], onClose: close));
      await tester.tap(find.text('Demo'));
      await tester.tap(find.text('Second'));
      await base.settle(tester, 2);
      await tester.tap(find.text(ghTr('vault_add_btn')));
      await base.settle(tester);
      expect(backend.calls, ['add:a:p1,p2:false', 'add:a:p1,p2:true']);
      expect(find.text(ghTr('vault_added_to_projects_toast', count: 2)), findsOneWidget);
      await base.drainToasts(tester);
    });
  });
}
