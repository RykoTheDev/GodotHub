import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/logic/export_template_catalog.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/export_template_downloads.dart';
import 'package:godothub/ui/feedback/toast.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

AppEvent templatesEvent(
  AppEventKind kind, {
  String? text,
  ExportTemplatesProgress? progress,
  ExportTemplatesStage? stage,
  ExportTemplatesError? error,
}) => AppEvent(
  kind: kind,
  name: '',
  json: 'null',
  text: text,
  exportTemplatesProgress: progress,
  exportTemplatesStage: stage,
  exportTemplatesError: error,
);

ExportTemplatesProgress progress(String tag, int downloaded, {List<String> platforms = const [], String? file}) =>
    ExportTemplatesProgress(
      tag: tag,
      downloaded: BigInt.from(downloaded),
      total: BigInt.from(100),
      file: file,
      platforms: platforms,
    );

void clearToasts() {
  for (final toast in ghToasts.toasts.toList()) {
    dismissToast(toast.id);
  }
}

void main() {
  late FakeRustApi rust;

  setUp(() {
    rust = installFakeRust();
    clearToasts();
  });

  tearDown(clearToasts);

  test('tracks queued, progress, stage and clears on complete, cancel and error', () async {
    final container = createContainer([exportTemplateDownloadsProvider]);
    Map<String, ExportTemplateDownload> state() => container.read(exportTemplateDownloadsProvider);

    rust.emit(templatesEvent(AppEventKind.exportTemplatesQueued, text: '4.4'));
    await settle();
    expect(state()['4.4'], const ExportTemplateDownload(downloaded: 0, total: 0, stage: 'downloading'));

    rust.emit(templatesEvent(AppEventKind.exportTemplatesProgress, progress: progress('4.4', 10, platforms: ['web'], file: 'web.zip')));
    rust.emit(templatesEvent(AppEventKind.exportTemplatesQueued, text: '4.4'));
    await settle();
    expect(state()['4.4']?.downloaded, 10);
    expect(state()['4.4']?.file, 'web.zip');

    rust.emit(templatesEvent(AppEventKind.exportTemplatesProgress, progress: progress('4.4', 20)));
    await settle();
    expect(state()['4.4']?.downloaded, 20);
    expect(state()['4.4']?.platforms, ['web']);

    rust.emit(templatesEvent(AppEventKind.exportTemplatesStage, stage: const ExportTemplatesStage(tag: '4.4', stage: 'extracting')));
    rust.emit(templatesEvent(AppEventKind.exportTemplatesStage, stage: const ExportTemplatesStage(tag: 'nope', stage: 'extracting')));
    await settle();
    expect(state()['4.4']?.stage, 'extracting');
    expect(state().containsKey('nope'), isFalse);

    rust.emit(templatesEvent(AppEventKind.exportTemplatesComplete, text: '4.4'));
    rust.emit(templatesEvent(AppEventKind.exportTemplatesQueued, text: '4.3'));
    rust.emit(templatesEvent(AppEventKind.exportTemplatesQueued, text: '4.2'));
    await settle();
    expect(state().keys, ['4.3', '4.2']);

    rust.emit(templatesEvent(AppEventKind.exportTemplatesCanceled, text: '4.3'));
    rust.emit(templatesEvent(AppEventKind.exportTemplatesError, error: const ExportTemplatesError(tag: '4.2', message: 'x')));
    await settle();
    expect(state(), isEmpty);
  });

  test('install marks files installed, toasts, calls onInstalled and clears the entry', () async {
    var installedCalls = 0;
    rust.on('crateApiExportTemplatesInstallExportTemplates', ({required String tag, required List<String> files}) async {
      expect(files, ['web.zip']);
      return ExportTemplatesInstallResult(
        tag: tag,
        folder: '/t/$tag',
        verified: true,
        sizeBytes: BigInt.one,
        fileCount: BigInt.one,
      );
    });
    cacheTemplateOptions('4.4', [
      TemplateOption(
        id: 'web',
        label: 'Web',
        files: [TemplateFile(name: 'web.zip', sizeBytes: BigInt.one, downloadBytes: BigInt.one, installed: false)],
        sizeBytes: BigInt.one,
        downloadBytes: BigInt.one,
        installed: false,
      ),
    ]);
    final container = createContainer([exportTemplateDownloadsProvider]);
    final notifier = container.read(exportTemplateDownloadsProvider.notifier);

    final installing = notifier.install('4.4', ['web.zip'], onInstalled: () async => installedCalls++);
    expect(container.read(exportTemplateDownloadsProvider)['4.4']?.file, 'web.zip');
    await installing;

    expect(installedCalls, 1);
    expect(container.read(exportTemplateDownloadsProvider), isEmpty);
    expect(getCachedTemplateOptions('4.4')!.single.installed, isTrue);
    expect(ghToasts.toasts.single.type, GhToastType.success);
    expect(ghToasts.toasts.single.message, contains('4.4'));
  });

  test('a failed or skipped install toasts an error or nothing and still clears', () async {
    var fail = true;
    rust.on('crateApiExportTemplatesInstallExportTemplates', ({required String tag, required List<String> files}) async {
      if (fail) throw StateError('no space');
      return null;
    });
    final container = createContainer([exportTemplateDownloadsProvider]);
    final notifier = container.read(exportTemplateDownloadsProvider.notifier);

    await notifier.install('4.4', const []);
    expect(container.read(exportTemplateDownloadsProvider), isEmpty);
    expect(ghToasts.toasts.single.type, GhToastType.error);
    expect(ghToasts.toasts.single.message, contains('no space'));
    clearToasts();

    fail = false;
    var installedCalls = 0;
    await notifier.install('4.4', const [], onInstalled: () async => installedCalls++);
    expect(installedCalls, 0);
    expect(ghToasts.toasts, isEmpty);
  });

  test('cancel swallows backend errors', () async {
    rust.on('crateApiExportTemplatesCancelExportTemplatesDownload', ({required String tag}) async => throw StateError('done'));
    final container = createContainer([exportTemplateDownloadsProvider]);
    await container.read(exportTemplateDownloadsProvider.notifier).cancel('4.4');
    expect(rust.callCount('crateApiExportTemplatesCancelExportTemplatesDownload'), 1);
  });
}
