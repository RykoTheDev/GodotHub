import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/task_tray.dart';
import 'package:godothub/titlebar/task_tray.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../ui/i18n_setup.dart';

AppEvent ev(AppEventKind kind, {Object? json, String? text, List<String>? queue, ScanProgress? scan, DownloadProgress? download, DownloadFailure? failure, ExportTemplatesProgress? templates, ExportTemplatesStage? stage, ExportTemplatesError? templatesError, AssetDownloadProgress? asset, AssetDownloadError? assetError}) {
  return AppEvent(
    kind: kind,
    name: kind.name,
    json: jsonEncode(json),
    text: text,
    queue: queue,
    scanProgress: scan,
    downloadProgress: download,
    downloadFailure: failure,
    exportTemplatesProgress: templates,
    exportTemplatesStage: stage,
    exportTemplatesError: templatesError,
    assetDownloadProgress: asset,
    assetDownloadError: assetError,
  );
}

BigInt mb(num value) => BigInt.from(value * 1024 * 1024);

void main() {
  late FakeRustApi rust;
  late ProviderContainer container;

  setUp(() {
    setUpTestI18n();
    rust = installFakeRust();
  });

  Future<void> start(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [fakeSettings(() => defaultSettings)],
    );
    addTearDown(container.dispose);
    container.listen(taskTrayProvider, (_, _) {});
    await container.read(settingsProvider.future);
    await tester.pump();
  }

  List<TrayTask> tasks() => container.read(taskTrayProvider);

  Future<void> send(WidgetTester tester, AppEvent event) async {
    rust.emit(event);
    await tester.pump();
  }

  group('events', () {
    testWidgets('project and version scans register, complete, and auto-remove after 4s', (tester) async {
      await start(tester);
      await send(tester, ev(AppEventKind.projectScanProgress, scan: const ScanProgress(current: 2, total: 5)));
      expect(tasks().single.id, 'scan-projects');
      expect(tasks().single.label, t.common.scanning_projects);
      expect(tasks().single.description, '2 / 5');
      expect(tasks().single.progress, const TaskProgress(2, 5));
      expect(container.read(taskTrayActiveCountProvider), 1);

      await send(tester, ev(AppEventKind.versionScanProgress, scan: const ScanProgress(current: 0, total: 3)));
      expect(tasks().map((t) => t.id), ['scan-projects', 'scan-versions']);

      await send(tester, ev(AppEventKind.projectScanProgress, scan: const ScanProgress(current: 5, total: 5)));
      expect(tasks().first.status, TaskStatus.completed);
      expect(container.read(taskTrayActiveCountProvider), 1);
      await tester.pump(const Duration(milliseconds: 3999));
      expect(tasks(), hasLength(2));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tasks().map((t) => t.id), ['scan-versions']);

      await send(tester, ev(AppEventKind.versionScanProgress, scan: const ScanProgress(current: 0, total: 0)));
      expect(tasks().single.status, TaskStatus.running);
    });

    testWidgets('godot downloads queue, progress, pause, reorder, fail, complete and cancel', (tester) async {
      await start(tester);
      await send(tester, ev(AppEventKind.godotDownloadQueued, text: '4.3-stable'));
      await send(tester, ev(AppEventKind.godotDownloadQueued, text: '4.2-stable'));
      expect(tasks().first.status, TaskStatus.queued);
      expect(tasks().first.description, t.common.queued);
      expect(tasks().first.label, t.common.downloading_version.args({'version': '4.3-stable'}));
      expect(tasks().first.downloadKey, '4.3-stable');

      await send(
        tester,
        ev(AppEventKind.godotDownloadProgress, download: DownloadProgress(tag: '4.3-stable', downloaded: mb(10), total: mb(40))),
      );
      expect(tasks().first.status, TaskStatus.running);
      expect(tasks().first.description, '10.0 / 40.0 MB (25%)');
      expect(tasks().first.progress!.fraction, 0.25);

      await send(
        tester,
        ev(AppEventKind.godotDownloadProgress, download: DownloadProgress(tag: '4.3-stable', downloaded: mb(1.25), total: BigInt.zero)),
      );
      expect(tasks().first.description, '1.3 MB');
      expect(tasks().first.progress, isNull);

      await send(tester, ev(AppEventKind.godotDownloadPaused, text: '4.3-stable'));
      expect(tasks().first.status, TaskStatus.paused);
      expect(container.read(taskTrayActiveCountProvider), 1);

      await send(tester, ev(AppEventKind.godotDownloadQueue, queue: ['4.2-stable', '4.3-stable', 'missing']));
      expect(tasks().map((t) => t.id), ['download-4.2-stable', 'download-4.3-stable']);

      await send(tester, ev(AppEventKind.godotDownloadError, failure: const DownloadFailure(tag: '4.2-stable', message: 'bad hash')));
      expect(tasks().first.status, TaskStatus.error);
      expect(tasks().first.errorMessage, 'bad hash');

      await send(tester, ev(AppEventKind.godotDownloadComplete, text: '4.3-stable'));
      expect(tasks().last.status, TaskStatus.completed);
      await tester.pump(const Duration(milliseconds: 3000));
      expect(tasks().map((t) => t.id), ['download-4.2-stable']);
      await tester.pump(const Duration(milliseconds: 3000));
      expect(tasks(), isEmpty);

      await send(tester, ev(AppEventKind.godotDownloadQueued, text: '4.1-stable'));
      await send(tester, ev(AppEventKind.godotDownloadCanceled, text: '4.1-stable'));
      expect(tasks(), isEmpty);
    });

    testWidgets('export templates track platforms, stages, errors, completion and cancel', (tester) async {
      await start(tester);
      await send(tester, ev(AppEventKind.exportTemplatesQueued, text: '4.3'));
      expect(tasks().single.id, 'templates-4.3');
      expect(tasks().single.templateTag, '4.3');
      await send(
        tester,
        ev(
          AppEventKind.exportTemplatesProgress,
          templates: ExportTemplatesProgress(tag: '4.3', downloaded: mb(5), total: mb(10), file: 'linux.zip', platforms: const ['Linux', 'Web']),
        ),
      );
      expect(tasks().single.description, 'Linux, Web · linux.zip · 5.0 / 10.0 MB (50%)');
      await send(tester, ev(AppEventKind.exportTemplatesStage, stage: const ExportTemplatesStage(tag: '4.3', stage: 'verifying')));
      expect(tasks().single.description, t.common.export_templates_verifying);
      await send(tester, ev(AppEventKind.exportTemplatesStage, stage: const ExportTemplatesStage(tag: '4.3', stage: 'extracting')));
      expect(tasks().single.description, t.common.export_templates_extracting);
      await send(tester, ev(AppEventKind.exportTemplatesComplete, text: '4.3'));
      expect(tasks().single.status, TaskStatus.completed);
      await tester.pump(const Duration(seconds: 3));
      expect(tasks(), isEmpty);

      await send(tester, ev(AppEventKind.exportTemplatesQueued, text: '4.2'));
      await send(tester, ev(AppEventKind.exportTemplatesError, templatesError: const ExportTemplatesError(tag: '4.2', message: 'nope')));
      expect(tasks().single.errorMessage, 'nope');
      await tester.pump(const Duration(milliseconds: 5999));
      expect(tasks(), hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tasks(), isEmpty);

      await send(tester, ev(AppEventKind.exportTemplatesQueued, text: '4.1'));
      await send(tester, ev(AppEventKind.exportTemplatesCanceled, text: '4.1'));
      expect(tasks(), isEmpty);
    });

    testWidgets('asset downloads queue, progress, complete and fail, including a title-less failure', (tester) async {
      await start(tester);
      final queued = AssetDownloadProgress(assetId: '7', title: 'Dialogic', downloaded: BigInt.zero, total: BigInt.zero);
      await send(tester, ev(AppEventKind.assetDownloadQueued, asset: queued));
      expect(tasks().single.id, 'download-asset-7');
      expect(tasks().single.label, t.common.downloading_asset.args({'title': 'Dialogic'}));
      await send(
        tester,
        ev(AppEventKind.assetDownloadProgress, asset: AssetDownloadProgress(assetId: '7', title: 'Dialogic', downloaded: mb(1), total: mb(2))),
      );
      expect(tasks().single.description, '1.0 / 2.0 MB (50%)');
      await send(tester, ev(AppEventKind.assetDownloadComplete, asset: queued));
      expect(tasks().single.status, TaskStatus.completed);
      await tester.pump(const Duration(seconds: 3));
      expect(tasks(), isEmpty);

      await send(tester, ev(AppEventKind.assetDownloadError, assetError: const AssetDownloadError(assetId: '8', title: '', message: 'gone')));
      expect(tasks().single.label, t.common.asset_download_failed);
      expect(tasks().single.status, TaskStatus.error);
      await tester.pump(const Duration(seconds: 6));
      expect(tasks(), isEmpty);
    });
  });

  group('actions', () {
    testWidgets('register, update, unregister and clearCompleted keep active tasks', (tester) async {
      await start(tester);
      final tray = container.read(taskTrayProvider.notifier);
      tray.registerTask(const TrayTask(id: 'clone', type: TaskType.cloneRepo, label: 'Clone', status: TaskStatus.running));
      tray.registerTask(const TrayTask(id: 'sync', type: TaskType.syncTemplates, label: 'Sync', status: TaskStatus.completed));
      tray.registerTask(const TrayTask(id: 'paused', type: TaskType.downloadGodot, label: 'P', status: TaskStatus.paused));
      tray.registerTask(const TrayTask(id: 'clone', type: TaskType.cloneRepo, label: 'Clone 2', status: TaskStatus.running));
      expect(tasks().map((t) => t.label), ['Clone 2', 'Sync', 'P']);
      expect(container.read(taskTrayDismissibleCountProvider), 2);

      tray.updateTask('clone', status: TaskStatus.error, errorMessage: 'denied');
      expect(tasks().first.errorMessage, 'denied');
      tray.updateTask('clone', status: TaskStatus.running);
      tray.scheduleRemoval('sync');
      tray.clearCompleted();
      expect(tasks().map((t) => t.id), ['clone', 'paused']);
      await tester.pump(const Duration(seconds: 5));
      expect(tasks().map((t) => t.id), ['clone', 'paused']);

      tray.unregisterTask('clone');
      expect(tasks().map((t) => t.id), ['paused']);
    });

    testWidgets('tray controls call the download and template commands', (tester) async {
      final calls = <String>[];
      rust.on('crateApiGodotVersionsPauseDownload', ({required String key}) async => calls.add('pause $key'));
      rust.on('crateApiGodotVersionsResumeDownload', ({required String key}) async => calls.add('resume $key'));
      rust.on('crateApiGodotVersionsCancelDownload', ({required String key}) async => calls.add('cancel $key'));
      rust.on(
        'crateApiGodotVersionsReorderDownloadQueue',
        ({required String key, required int direction}) async => calls.add('move $key $direction'),
      );
      rust.on('crateApiExportTemplatesCancelExportTemplatesDownload', ({required String tag}) async => calls.add('templates $tag'));
      await start(tester);
      final tray = container.read(taskTrayProvider.notifier);
      await tray.pauseDownload('a');
      await tray.resumeDownload('a');
      await tray.cancelDownload('a');
      await tray.moveDownload('a', -1);
      await tray.cancelTemplates('4.3');
      expect(calls, ['pause a', 'resume a', 'cancel a', 'move a -1', 'templates 4.3']);
    });
  });

  group('TaskTray widget', () {
    Future<void> pumpTray(WidgetTester tester) async {
      await start(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: Align(alignment: Alignment.topRight, child: TaskTray()))),
        ),
      );
    }

    testWidgets('badge counts queued and running tasks, capped at 9+', (tester) async {
      await pumpTray(tester);
      expect(find.text('1'), findsNothing);
      final tray = container.read(taskTrayProvider.notifier);
      for (var i = 0; i < 12; i++) {
        tray.registerTask(TrayTask(id: '$i', type: TaskType.importProjects, label: '$i', status: TaskStatus.running));
      }
      tray.registerTask(const TrayTask(id: 'done', type: TaskType.importProjects, label: 'done', status: TaskStatus.completed));
      await tester.pump();
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('lists tasks with per-state controls and dismisses finished ones', (tester) async {
      final calls = <String>[];
      rust.on('crateApiGodotVersionsPauseDownload', ({required String key}) async => calls.add('pause $key'));
      rust.on(
        'crateApiGodotVersionsReorderDownloadQueue',
        ({required String key, required int direction}) async => calls.add('move $key $direction'),
      );
      await pumpTray(tester);
      final tray = container.read(taskTrayProvider.notifier);
      tray.registerTask(const TrayTask(id: 'download-4.3', type: TaskType.downloadGodot, label: 'Running', status: TaskStatus.running));
      tray.registerTask(const TrayTask(id: 'download-4.2', type: TaskType.downloadGodot, label: 'Waiting', status: TaskStatus.queued));
      tray.registerTask(
        const TrayTask(id: 'sync-templates', type: TaskType.syncTemplates, label: 'Synced', status: TaskStatus.completed, description: 'Done'),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('task-tray-trigger')));
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text(t.common.task_tray_active_count.args({'active': 2, 'recent': 1})), findsOneWidget);
      expect(find.byKey(const ValueKey('task-pause-download-4.3')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-move-up-download-4.2')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-cancel-download-4.2')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-resume-download-4.3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('task-pause-download-4.3')));
      await tester.tap(find.byKey(const ValueKey('task-move-down-download-4.2')));
      await tester.pump();
      expect(calls, ['pause 4.3', 'move 4.2 1']);

      expect(find.text(t.common.task_tray_dismiss.args({'count': 1})), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('task-tray-dismiss')));
      await tester.pumpAndSettle();
      expect(find.text('Synced'), findsNothing);
      expect(find.byKey(const ValueKey('task-tray-dismiss')), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('auto-closes two seconds after it is open and empty', (tester) async {
      await pumpTray(tester);
      final tray = container.read(taskTrayProvider.notifier);
      tray.registerTask(const TrayTask(id: 'x', type: TaskType.cloneRepo, label: 'Cloning', status: TaskStatus.running));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('task-tray-trigger')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Cloning'), findsOneWidget);

      tray.unregisterTask('x');
      await tester.pump();
      expect(find.text(t.common.no_tasks_running), findsOneWidget);
      expect(find.text(t.common.task_tray_empty), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text(t.common.no_tasks_running), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text(t.common.no_tasks_running), findsNothing);
    });

    testWidgets('shows the recent-only subtitle when nothing is active', (tester) async {
      await pumpTray(tester);
      container
          .read(taskTrayProvider.notifier)
          .registerTask(const TrayTask(id: 'e', type: TaskType.cloneRepo, label: 'Failed', status: TaskStatus.error, errorMessage: 'boom'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('task-tray-trigger')));
      await tester.pumpAndSettle();
      expect(find.text(t.common.task_tray_only_recent(count: 1)), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      expect(find.byKey(const ValueKey('task-status-error')), findsOneWidget);
    });
  });
}
