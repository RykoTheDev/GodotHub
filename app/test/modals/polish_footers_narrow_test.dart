import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/modals/check_for_updates_modal.dart';
import 'package:godothub/modals/current_version_modal.dart';
import 'package:godothub/modals/project_addons_modal.dart';
import 'package:godothub/modals/project_build_modal.dart';
import 'package:godothub/modals/release_notes_draft_modal.dart';
import 'package:godothub/modals/version_aliases_modal.dart';
import 'package:godothub/src/rust/api/dto.dart' as dto;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';
import 'updates_bug_report_test.dart' as updates;

const narrow = Size(340, 640);

void expectNoOverflow(WidgetTester tester) {
  final error = tester.takeException();
  if (error is FlutterError) debugPrint(error.toStringDeep());
  expect(error, isNull);
}

Future<void> openNarrow(WidgetTester tester, Widget Function(VoidCallback close) builder) async {
  final host = await base.pumpHost(tester, size: narrow);
  showGhModal<void>(host, (modal) => builder(() => Navigator.of(modal).pop())).ignore();
  await base.settle(tester);
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    base.rust = installFakeRust();
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
  });

  testWidgets('check for updates fits 340x640 with release link, close and install', (tester) async {
    await updates.openWith(
      tester,
      (close) => CheckForUpdatesModal(onClose: close),
      size: narrow,
      overrides: [
        updates.checker(
          () async => AppUpdate(
            version: '2.1.0',
            body: updates.notes,
            date: '2026-11-10T12:00:00Z',
            downloadUrl:
                'https://github.com/RykoTheDev/godothub/releases/download/flutter-v2.1.0/GodotHub-Beta-2.1.0-windows-x64-setup.exe',
            package: 'windows-x86_64-nsis',
            restart: () async {},
            download: (onProgress, {githubToken, onLog}) async {},
          ),
        ),
        updates.portableIs(false),
      ],
    );
    expectNoOverflow(tester);
    expect(find.text(ghTr('install_update')), findsOneWidget);
    expect(find.text(ghTr('close')), findsOneWidget);
  });

  testWidgets('current version fits 340x640 and Close is not the accent action', (tester) async {
    await openNarrow(
      tester,
      (close) => CurrentVersionModal(
        info: const CurrentVersionInfo(tag: '4.3-stable', aliasPath: 'C:/a/godot.cmd', aliasesDir: 'C:/a', method: 'shim'),
        onClose: close,
      ),
    );
    expectNoOverflow(tester);
    expect(find.text(ghTr('close')), findsOneWidget);
  });

  testWidgets('version aliases fits 340x640', (tester) async {
    await openNarrow(
      tester,
      (close) => VersionAliasesModal(
        versions: const [],
        aliases: const [AliasInfo(name: 'godot', tag: '4.3-stable', aliasPath: 'C:/a/godot.cmd', aliasesDir: 'C:/a', method: 'shim')],
        aliasesDir: 'C:/a',
        windows: true,
        onClose: close,
        onCreateMany: (entries) async => const AliasBatchResult(created: [], skipped: []),
        onDelete: (_) async {},
      ),
    );
    expectNoOverflow(tester);
  });

  testWidgets('project add-ons fits 340x640 and shows the hint in the body', (tester) async {
    base.rust.on('crateApiAddonsListProjectAddons', ({required String id}) async => const <ProjectAddon>[]);
    await openNarrow(tester, (close) => ProjectAddonsModal(project: base.demo, onClose: close));
    expectNoOverflow(tester);
    expect(find.text(ghTr('project_addons.footer_hint')), findsOneWidget);
  });

  testWidgets('project build fits 340x640 with Close and Start', (tester) async {
    base.rust
      ..on(
        'crateApiDtoGetProjectExportPresets',
        ({required String id}) async => const dto.ExportCatalog(
          versionTag: '4.3',
          presets: [
            dto.ExportPreset(id: 0, name: 'Windows', platform: 'Windows Desktop', outputPath: 'C:/out/demo.exe', missingTemplates: []),
          ],
        ),
      )
      ..on('crateApiExportRunnerGetProjectExports', ({required String id}) async => <ExportRun>[])
      ..on('crateApiToolRunnerListProjectTools', ({required String id}) async => const <ProjectTool>[]);
    await openNarrow(tester, (close) => ProjectBuildModal(project: base.demo, onClose: close));
    expectNoOverflow(tester);
    expect(find.text(ghTr('build_export.start')), findsOneWidget);
  });

  testWidgets('release notes draft fits 340x640 and shows errors above the footer', (tester) async {
    base.rust.on('crateApiChangelogListGitTags', () async => throw 'git is not available');
    await openNarrow(tester, (close) => ReleaseNotesDraftModal(onClose: close, onUseDraft: (notes, v, date) {}));
    expectNoOverflow(tester);
    expect(find.text(ghTr('changelog_draft_use')), findsOneWidget);
  });
}
