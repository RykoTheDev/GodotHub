import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/modals/export_templates_modal.dart';
import 'package:godothub/modals/git_auth_modal.dart';
import 'package:godothub/src/rust/api/dto.dart' as dto;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

String tv(String key, {num? count}) => ghTr('versions:$key', count: count);

DeviceFlowStart flow(String provider) => DeviceFlowStart(
  provider: provider,
  deviceCode: 'dev',
  userCode: 'ABCD-1234',
  verificationUri: 'https://github.com/login/device',
  verificationUriComplete: '',
  interval: BigInt.from(5),
  expiresIn: BigInt.from(900),
);

TemplateFile file(String name, {bool installed = false}) =>
    TemplateFile(name: name, sizeBytes: BigInt.from(2048), downloadBytes: BigInt.from(1024), installed: installed);

List<TemplateOption> options() => [
  TemplateOption(
    id: 'windows',
    label: 'Windows',
    files: [file('windows_debug_x86_64.exe'), file('windows_release_x86_64.exe')],
    sizeBytes: BigInt.from(4096),
    downloadBytes: BigInt.from(2048),
    installed: false,
  ),
  TemplateOption(
    id: 'android',
    label: 'Android',
    files: [file('android_debug.apk')],
    sizeBytes: BigInt.from(2048),
    downloadBytes: BigInt.from(1024),
    installed: false,
  ),
];

Finder closeButton() => find.bySemanticsLabel(ghTr('close'));

void main() {
  late FakeRustApi rust;
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
  });

  group('git sign-in', () {
    testWidgets('while waiting, Escape is ignored and there is no close button; Cancel stops and closes', (tester) async {
      var polls = 0;
      var closed = 0;
      rust
        ..on('crateApiGitAuthStartDeviceFlow', ({required String provider, String? baseUrl, String? clientId}) async => flow(provider))
        ..on('crateApiDtoPollDeviceFlow', ({
          required String provider,
          required String deviceCode,
          String? baseUrl,
          String? clientId,
        }) async {
          polls++;
          return const dto.DeviceFlowPoll(status: dto.DeviceFlowStatus.pending);
        });
      await base.openModal(
        tester,
        (close) => GitAuthModal(
          provider: 'github',
          onClose: () {
            closed++;
            close();
          },
          onConnected: (_) {},
        ),
      );
      expect(find.text('ABCD – 1234'), findsOneWidget);
      expect(find.text(ghTr('settings:git_auth_intro', args: {'provider': 'GitHub'})), findsOneWidget);
      expect(closeButton(), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await base.settle(tester, 3);
      expect(find.byType(GitAuthModal), findsOneWidget);
      expect(closed, 0);
      await tester.tap(find.byKey(const ValueKey('git-auth-cancel')));
      await base.settle(tester);
      expect(closed, 1);
      expect(find.byType(GitAuthModal), findsNothing);
      final before = polls;
      await tester.pump(const Duration(seconds: 12));
      expect(polls, before);
    });

    testWidgets('after a failure, Escape and the close button work and Try again restarts', (tester) async {
      var starts = 0;
      var closed = 0;
      rust.on('crateApiGitAuthStartDeviceFlow', ({required String provider, String? baseUrl, String? clientId}) async {
        starts++;
        throw StateError('network down');
      });
      await base.openModal(
        tester,
        (close) => GitAuthModal(
          provider: 'github',
          onClose: () {
            closed++;
            close();
          },
          onConnected: (_) {},
        ),
      );
      expect(find.text(ghTr('settings:git_auth_failed')), findsOneWidget);
      expect(closeButton(), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('git-auth-retry')));
      await base.settle(tester, 3);
      expect(starts, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await base.settle(tester);
      expect(closed, 1);
    });

    testWidgets('fits a 340px window while waiting', (tester) async {
      rust
        ..on('crateApiGitAuthStartDeviceFlow', ({required String provider, String? baseUrl, String? clientId}) async => flow(provider))
        ..on(
          'crateApiDtoPollDeviceFlow',
          ({required String provider, required String deviceCode, String? baseUrl, String? clientId}) async =>
              const dto.DeviceFlowPoll(status: dto.DeviceFlowStatus.pending),
        );
      await base.openModal(
        tester,
        (close) => GitAuthModal(provider: 'github', onClose: close, onConnected: (_) {}),
        size: const Size(340, 640),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('git-auth-cancel')));
      await base.settle(tester);
    });
  });

  group('export templates', () {
    testWidgets('summary sits above the list, select all and none work, download explains when disabled', (tester) async {
      List<String>? downloaded;
      await base.openModal(
        tester,
        (close) => ExportTemplatesModal(
          tag: '4.3-stable',
          onClose: close,
          onDownload: (files) => downloaded = files,
          fetch: (tag, refresh) async => options(),
        ),
      );
      expect(find.text(tv('export_templates_select_hint')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('export-templates-download')));
      await base.settle(tester, 2);
      expect(downloaded, isNull);
      await tester.tap(find.byKey(const ValueKey('export-templates-select-all')));
      await base.settle(tester, 3);
      expect(find.text(tv('export_templates_selected', count: 3)), findsOneWidget);
      expect(find.text(tv('export_templates_select_hint')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('export-templates-select-none')));
      await base.settle(tester, 3);
      expect(find.text(tv('export_templates_selected', count: 0)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('export-templates-select-all')));
      await base.settle(tester, 3);
      await tester.tap(find.byKey(const ValueKey('export-templates-download')));
      await base.settle(tester, 2);
      expect(downloaded, hasLength(3));
    });

    testWidgets('says when everything is already installed', (tester) async {
      await base.openModal(
        tester,
        (close) => ExportTemplatesModal(
          tag: '4.3-stable',
          onClose: close,
          onDownload: (_) {},
          fetch: (tag, refresh) async => [
            TemplateOption(
              id: 'android',
              label: 'Android',
              files: [file('android_debug.apk', installed: true)],
              sizeBytes: BigInt.from(2048),
              downloadBytes: BigInt.from(1024),
              installed: true,
            ),
          ],
        ),
      );
      expect(find.text(tv('export_templates_all_installed')), findsOneWidget);
    });

    testWidgets('fits a 340px window', (tester) async {
      await base.openModal(
        tester,
        (close) => ExportTemplatesModal(tag: '4.3-stable', onClose: close, onDownload: (_) {}, fetch: (tag, refresh) async => options()),
        size: const Size(340, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
