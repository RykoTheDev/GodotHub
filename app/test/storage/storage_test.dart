import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/dto.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/storage/storage_view.dart';
import 'package:godothub/ui/controls/checkbox.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

late FakeRustApi rust;

const mb = 1024 * 1024;

StorageVersion version(
  String tag, {
  int size = 100 * mb,
  bool unused = false,
  bool external = false,
  String? managedBy,
  bool current = false,
  List<String> projects = const [],
  List<String> aliases = const [],
}) => StorageVersion(
  tag: tag,
  name: 'Godot $tag',
  path: 'C:/godot/$tag',
  sizeBytes: BigInt.from(size),
  managedBy: managedBy,
  external_: external,
  projects: projects,
  templates: const [],
  isCurrent: current,
  aliases: aliases,
  unused: unused,
);

StorageReport report({List<StorageVersion>? versions, List<StoragePartial>? partials, List<StorageExportTemplates>? exports}) => StorageReport(
  versions:
      versions ??
      [
        version('4.3-stable', size: 200 * mb, current: true, projects: const ['Game']),
        version('4.2-stable', unused: true),
        version('4.1-stable', unused: true, external: true),
      ],
  partials: partials ?? [StoragePartial(kind: 'version_download', name: 'godot.zip.part', path: 'C:/dl/godot.zip.part', sizeBytes: BigInt.from(10 * mb))],
  templates: [StorageTemplate(id: 't', name: 'Starter', workspace: 'Default', path: 'C:/tpl/starter', sizeBytes: BigInt.from(5 * mb))],
  exportTemplates:
      exports ??
      [
        StorageExportTemplates(tag: '4.3-stable', folder: '4.3.stable', root: 'C:/et', path: 'C:/et/4.3.stable', sizeBytes: BigInt.from(50 * mb), orphan: false),
        StorageExportTemplates(folder: '3.5.stable', root: 'C:/et', path: 'C:/et/3.5.stable', sizeBytes: BigInt.from(20 * mb), orphan: true),
      ],
);

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
    rust
      ..on('crateApiGodotVersionsListInstalledGodotVersions', () async => <InstalledGodotVersion>[])
      ..on('crateApiGodotVersionsFetchAvailableGodotVersions', ({String? source}) async => <GodotRelease>[])
      ..on('crateApiMiseMiseRefreshStatus', () async => const MiseStatus(available: false));
  });

  test('reclaim entries pick unused versions, partials and orphan exports with defaults', () {
    final entries = reclaimEntries(report());
    expect([for (final e in entries) e.key], ['version:4.2-stable', 'version:4.1-stable', 'partial:C:/dl/godot.zip.part', 'export:C:/et:3.5.stable']);
    expect([for (final e in entries) e.defaultOn], [true, false, true, false]);
    expect(entries[1].detail, ghTr('cleanup_external_hint'));
    expect(entries[2].detail, ghTr('cleanup_kind_version_download'));
    expect(entries.last.item, const ReclaimItem(kind: ReclaimKind.exportTemplates, folder: '3.5.stable', root: 'C:/et'));
    final totals = storageTotals(report());
    expect(totals.versions, 400.0 * mb);
    expect(totals.all, (400 + 10 + 5 + 70) * mb.toDouble());
  });

  testWidgets('shows the report, totals, badges and sections', (tester) async {
    rust.on('crateApiStorageGetStorageReport', () async => report());
    await base.pumpHost(tester, body: const StorageView());
    await base.settle(tester);
    expect(find.text('485.0 MB'), findsOneWidget);
    expect(find.text(ghTr('cleanup_current_badge')), findsOneWidget);
    expect(find.text(ghTr('n_projects', count: 1)), findsOneWidget);
    expect(find.text(ghTr('cleanup_unused_badge')), findsNWidgets(2));
    expect(find.text(ghTr('cleanup_external_badge')), findsOneWidget);
    expect(find.text(ghTr('cleanup_orphan_badge')), findsOneWidget);
    expect(find.text(ghTr('cleanup_orphan_exports_hint')), findsOneWidget);
    expect(find.text(ghTr('cleanup_reclaim_btn', args: {'size': '110.0 MB'})), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);
  });

  testWidgets('reclaims the selected items after confirming and reloads', (tester) async {
    var loads = 0;
    List<ReclaimItem>? reclaimed;
    rust
      ..on('crateApiStorageGetStorageReport', () async {
        loads++;
        return loads == 1 ? report() : report(versions: [version('4.3-stable')], partials: const [], exports: const []);
      })
      ..on('crateApiDtoReclaimStorage', ({required List<ReclaimItem> items}) async {
        reclaimed = items;
        return ReclaimResult(
          freedBytes: BigInt.from(110 * mb),
          removed: BigInt.two,
          failed: const [ReclaimFailure(label: 'godot.zip.part', error: 'locked')],
        );
      });
    await base.pumpHost(tester, body: const StorageView());
    await base.settle(tester);

    final orphanRow = find.ancestor(of: find.text('3.5.stable'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: orphanRow, matching: find.byType(GhCheckbox)));
    await base.settle(tester, 3);
    expect(find.text(ghTr('cleanup_reclaim_btn', args: {'size': '130.0 MB'})), findsOneWidget);

    await tester.tap(find.text(ghTr('cleanup_reclaim_btn', args: {'size': '130.0 MB'})));
    await base.settle(tester);
    expect(find.text(ghTr('cleanup_confirm_title', args: {'size': '130.0 MB'}).toUpperCase()), findsOneWidget);
    expect(find.text('C:/et/3.5.stable'), findsOneWidget);
    expect(find.text(ghTr('cleanup_confirm_trash_note')), findsOneWidget);

    await tester.tap(find.text(ghTr('cancel')));
    await base.settle(tester);
    expect(reclaimed, isNull);

    await tester.tap(find.text(ghTr('cleanup_reclaim_btn', args: {'size': '130.0 MB'})));
    await base.settle(tester);
    await tester.tap(find.text(ghTr('cleanup_confirm_btn', count: 3)));
    await base.settle(tester);
    expect(reclaimed, [
      const ReclaimItem(kind: ReclaimKind.version, tag: '4.2-stable'),
      const ReclaimItem(kind: ReclaimKind.partial, path: 'C:/dl/godot.zip.part'),
      const ReclaimItem(kind: ReclaimKind.exportTemplates, folder: '3.5.stable', root: 'C:/et'),
    ]);
    expect(find.text(ghTr('cleanup_done', args: {'size': '110.0 MB'})), findsOneWidget);
    expect(find.text(ghTr('cleanup_failed', args: {'label': 'godot.zip.part', 'error': 'locked'})), findsOneWidget);
    expect(loads, 2);
    expect(find.text(ghTr('cleanup_nothing_to_reclaim')), findsOneWidget);
    await base.drainToasts(tester);
  });

  testWidgets('group checkbox toggles all rows and an empty selection disables reclaim', (tester) async {
    rust.on('crateApiStorageGetStorageReport', () async => report());
    await base.pumpHost(tester, body: const StorageView());
    await base.settle(tester);
    await tester.tap(find.text(ghTr('cleanup_group_unused_versions')));
    await base.settle(tester, 3);
    expect(find.text(ghTr('cleanup_reclaim_btn', args: {'size': '210.0 MB'})), findsOneWidget);
    await tester.tap(find.text(ghTr('cleanup_group_unused_versions')));
    await tester.tap(find.text(ghTr('cleanup_group_partials')));
    await base.settle(tester, 3);
    await tester.tap(find.text(ghTr('cleanup_reclaim_btn', args: {'size': '0 MB'})));
    await base.settle(tester);
    expect(find.text(ghTr('cleanup_confirm_desc')), findsNothing);
  });

  testWidgets('shows the load error with retry, then the report', (tester) async {
    var fail = true;
    rust.on('crateApiStorageGetStorageReport', () async {
      if (fail) throw Exception('disk gone');
      return report();
    });
    await base.pumpHost(tester, body: const StorageView());
    await base.settle(tester);
    expect(find.text(ghTr('cleanup_load_error', args: {'error': 'disk gone'})), findsOneWidget);
    fail = false;
    await tester.tap(find.text(ghTr('try_again')));
    await base.settle(tester);
    expect(find.text('Starter'), findsOneWidget);
  });

  testWidgets('reloads when the view becomes active again and opens folders', (tester) async {
    var loads = 0;
    final opened = <String>[];
    rust
      ..on('crateApiStorageGetStorageReport', () async {
        loads++;
        return report();
      })
      ..on('crateApiProjectsOpenProjectFolder', ({required String path}) async => opened.add(path));
    var active = false;
    late StateSetter setActive;
    await base.pumpHost(
      tester,
      body: StatefulBuilder(
        builder: (context, setState) {
          setActive = setState;
          return StorageView(active: active);
        },
      ),
    );
    await base.settle(tester);
    expect(loads, 0);
    setActive(() => active = true);
    await base.settle(tester);
    expect(loads, 1);
    final row = find.ancestor(of: find.text('Starter'), matching: find.byType(Row)).first;
    final button = find.descendant(of: row, matching: find.bySemanticsLabel(ghTr('open_folder')));
    await tester.ensureVisible(button);
    await base.settle(tester, 3);
    await tester.tap(button);
    await base.settle(tester, 3);
    expect(opened, ['C:/tpl/starter']);
    await tester.tap(find.text(ghTr('refresh')));
    await base.settle(tester);
    expect(loads, 2);
  });
}
