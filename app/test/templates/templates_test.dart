import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/create_project_modal.dart';
import 'package:godothub/modals/template_preview_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/state/task_tray.dart';
import 'package:godothub/templates/templates_view.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/confirm_dialog.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;

ProjectTemplate template(String id, String name, {String description = '', String createdAt = '2026-01-01T00:00:00Z'}) => ProjectTemplate(
  id: id,
  name: name,
  description: description,
  godotVersion: '4.3',
  createdAt: createdAt,
  path: 'C:/templates/$id',
  keepName: false,
);

class TemplatesBackend {
  List<ProjectTemplate> list = [
    template('b', 'Platformer', description: 'Jump and run', createdAt: '2026-03-01T00:00:00Z'),
    template('a', 'Arena', createdAt: '2026-02-01T00:00:00Z'),
  ];
  List<TemplateFileEntry> preview = [
    TemplateFileEntry(path: 'scenes/', isDir: true, size: BigInt.zero),
    TemplateFileEntry(path: 'scenes/main.tscn', isDir: false, size: BigInt.from(2048)),
    TemplateFileEntry(path: 'project.godot', isDir: false, size: BigInt.from(512)),
  ];
  TemplateSyncResult sync = TemplateSyncResult(imported: [template('c', 'Shooter')], updated: const [], removed: const []);
  final calls = <String>[];

  void install(FakeRustApi rust) {
    rust
      ..on('crateApiTemplatesListTemplates', () async {
        calls.add('list');
        return list;
      })
      ..on('crateApiTemplatesDeleteTemplate', ({required String templateId}) async => calls.add('delete:$templateId'))
      ..on('crateApiTemplatesGetTemplatePreview', ({required String templateId}) async {
        calls.add('preview:$templateId');
        return preview;
      })
      ..on('crateApiTemplatesSyncTemplatesWithScanDir', () async {
        calls.add('sync');
        list = [...list, ...sync.imported];
        return sync;
      });
  }
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
  });

  test('sorting, filtering, sync summary and tree building', () {
    final list = [
      template('1', 'beta', createdAt: '2026-01-02T00:00:00Z'),
      template('2', 'Alpha', description: 'Racing kit', createdAt: '2026-01-03T00:00:00Z'),
      template('3', 'gamma', createdAt: '2026-01-01T00:00:00Z'),
    ];
    expect([for (final t in filterAndSortTemplates(list, '', TemplateSort.nameAsc)) t.id], ['2', '1', '3']);
    expect([for (final t in filterAndSortTemplates(list, '', TemplateSort.nameDesc)) t.id], ['3', '1', '2']);
    expect([for (final t in filterAndSortTemplates(list, '', TemplateSort.newest)) t.id], ['2', '1', '3']);
    expect([for (final t in filterAndSortTemplates(list, '', TemplateSort.oldest)) t.id], ['3', '1', '2']);
    expect(filterAndSortTemplates(list, 'racing', TemplateSort.nameAsc).single.id, '2');
    expect(TemplateSort.parse('newest'), TemplateSort.newest);
    expect(TemplateSort.parse('bogus'), TemplateSort.nameAsc);
    expect(templateSyncSummary(const TemplateSyncResult(imported: [], updated: [], removed: [])), isNull);
    expect(templateSyncSummary(const TemplateSyncResult(imported: [], updated: ['x'], removed: ['y'])), contains(' · '));
    expect(templateFileSize(0), '');
    expect(templateFileSize(512), '512 B');
    expect(templateFileSize(2048), '2.0 KB');
    expect(templateFileSize(3 * 1024 * 1024), '3.0 MB');
    final tree = buildTemplateTree([
      TemplateFileEntry(path: 'a/b/c.gd', isDir: false, size: BigInt.from(10)),
      TemplateFileEntry(path: 'a/', isDir: true, size: BigInt.zero),
      TemplateFileEntry(path: 'readme.md', isDir: false, size: BigInt.one),
    ]);
    expect([for (final n in tree) n.name], ['a', 'readme.md']);
    expect(tree.first.isDir, isTrue);
    expect(tree.first.children.single.name, 'b');
    expect(tree.first.children.single.children.single.size, 10);
  });

  testWidgets('lists templates sorted, searches and persists sort', (tester) async {
    TemplatesBackend().install(rust);
    await base.pumpHost(tester, body: const TemplatesView());
    await base.settle(tester);
    expect(find.text('Arena'), findsOneWidget);
    expect(find.text('Platformer'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Arena')).dx, lessThan(tester.getTopLeft(find.text('Platformer')).dx));
    expect(find.text('Jump and run'), findsOneWidget);
    expect(find.text(ghTr("template_your_templates", count: 2).toUpperCase()), findsWidgets);
    await tester.tap(find.text(ghTr('sort_name_asc')));
    await base.settle(tester, 3);
    await tester.tap(find.text(ghTr('sort_created_desc')).last);
    await base.settle(tester, 3);
    expect(UiPrefsStore.instance.getItem(templateSortKey), 'newest');
    expect(tester.getTopLeft(find.text('Platformer')).dx, lessThan(tester.getTopLeft(find.text('Arena')).dx));
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await base.settle(tester, 3);
    expect(find.text(ghTr('no_templates_match'), findRichText: true), findsNothing);
    expect(find.textContaining('"zzz"', findRichText: true), findsOneWidget);
  });

  testWidgets('empty state renders the bold Save as Template hint', (tester) async {
    (TemplatesBackend()..list = []).install(rust);
    await base.pumpHost(tester, body: const TemplatesView());
    await base.settle(tester);
    expect(find.textContaining('Save as Template', findRichText: true), findsOneWidget);
  });

  testWidgets('deletes a template after confirming', (tester) async {
    final backend = TemplatesBackend()..install(rust);
    await base.pumpHost(tester, body: const TemplatesView());
    await base.settle(tester);
    await tester.tap(find.bySemanticsLabel(ghTr('delete_template', args: {'name': 'Arena'})));
    await base.settle(tester, 4);
    expect(find.byType(GhConfirmDialog), findsOneWidget);
    expect(find.textContaining('Arena', findRichText: true), findsWidgets);
    await tester.tap(find.text(ghTr('delete')).last);
    await base.settle(tester, 4);
    expect(backend.calls, contains('delete:a'));
    expect(find.text('Arena'), findsNothing);
    expect(find.text('Platformer'), findsOneWidget);
  });

  testWidgets('sync signal registers a tray task and reloads, refresh signal reloads', (tester) async {
    final backend = TemplatesBackend()..install(rust);
    final host = await base.pumpHost(tester, body: const TemplatesView());
    await base.settle(tester);
    expect(find.text('Shooter'), findsNothing);
    AppSignals.emit(syncTemplatesSignal);
    await base.settle(tester, 4);
    expect(backend.calls, contains('sync'));
    expect(find.text('Shooter'), findsOneWidget);
    final task = ProviderScope.containerOf(host).read(taskTrayProvider).singleWhere((t) => t.id == 'sync-templates');
    expect(task.status, TaskStatus.completed);
    expect(task.type, TaskType.syncTemplates);
    backend.list = [template('z', 'Zombie')];
    AppSignals.emit(refreshTemplatesSignal);
    await base.settle(tester, 4);
    expect(find.text('Zombie'), findsOneWidget);
    await base.drainToasts(tester);
  });

  testWidgets('card opens the preview with a collapsible tree', (tester) async {
    final backend = TemplatesBackend()..install(rust);
    await base.pumpHost(tester, body: const TemplatesView());
    await base.settle(tester);
    await tester.tap(find.text('Platformer'));
    await base.settle(tester, 6);
    expect(find.byType(TemplatePreviewModal), findsOneWidget);
    expect(backend.calls, contains('preview:b'));
    expect(find.textContaining(ghTr('file_count', count: 2)), findsOneWidget);
    expect(find.text('scenes'), findsOneWidget);
    expect(find.text('main.tscn'), findsNothing);
    await tester.tap(find.bySemanticsLabel(ghTr('expand')));
    await base.settle(tester, 3);
    expect(find.text('main.tscn'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
  });

  testWidgets('preview shows error and empty states', (tester) async {
    rust.on('crateApiTemplatesGetTemplatePreview', ({required String templateId}) async => throw 'boom');
    await base.openModal(tester, (close) => TemplatePreviewModal(template: template('x', 'X'), onClose: close));
    expect(find.text('boom'), findsOneWidget);
    rust.on('crateApiTemplatesGetTemplatePreview', ({required String templateId}) async => <TemplateFileEntry>[]);
    await base.openModal(tester, (close) => TemplatePreviewModal(template: template('y', 'Y'), onClose: close));
    expect(find.text(ghTr('template_empty')), findsOneWidget);
  });

  testWidgets('create project button opens the modal with the template, and its preview button opens the preview', (tester) async {
    final backend = TemplatesBackend()..install(rust);
    rust
      ..on('crateApiGitGitIsAvailable', () async => false)
      ..on('crateApiGitAuthGetGitAuthState', () async => const GitAuthState(pats: []));
    await base.pumpHost(
      tester,
      body: const TemplatesView(),
      settings: copySettings(baseSettings, setupComplete: true),
    );
    await base.settle(tester);
    await tester.tap(find.text(ghTr('create_project_btn')).first);
    await base.settle(tester, 6);
    final modal = tester.widget<CreateProjectModal>(find.byType(CreateProjectModal));
    expect(modal.initialTemplateId, 'a');
    await tester.tap(find.byWidgetPredicate((w) => w is GhIcon && w.icon == GhIcons.bookOpen).last);
    await base.settle(tester, 6);
    expect(find.byType(TemplatePreviewModal), findsOneWidget);
    expect(backend.calls.where((c) => c.startsWith('preview:')), hasLength(1));
  });
}
