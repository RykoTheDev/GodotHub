import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/modals/beta_ended_modal.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';

import '../projects/project_actions_test.dart' as base;
import '../ui/i18n_setup.dart';

const uninstaller = r'C:\Users\x\AppData\Local\GodotHub Beta\uninstall.exe';

Future<void> open(WidgetTester tester, Widget Function(VoidCallback close) build) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
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

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);

  testWidgets('offers stable and an uninstall when an uninstaller exists', (tester) async {
    final opened = <String>[];
    final uninstalled = <String>[];
    var closed = 0;
    await open(
      tester,
      (close) => BetaEndedModal(
        version: '1.6.0',
        uninstallerPath: uninstaller,
        onClose: () {
          closed++;
          close();
        },
        openUrl: (url) async => opened.add(url),
        runUninstaller: (path) async => uninstalled.add(path),
      ),
    );
    expect(find.text('GodotHub Beta has ended'.toUpperCase()), findsOneWidget);
    expect(
      find.text(
        'GodotHub 1.6.0 is out. The app you have been testing is now the regular GodotHub, so the beta will not get any more updates.',
      ),
      findsOneWidget,
    );
    expect(find.text('When you have moved over, remove GodotHub Beta like any other app.'), findsNothing);

    await tester.tap(find.text('Get GodotHub'));
    expect(opened, [stableReleaseUrl]);
    await tester.tap(find.text('Uninstall Beta'));
    expect(uninstalled, [uninstaller]);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('explains how to remove the beta when there is no uninstaller', (tester) async {
    await open(tester, (close) => BetaEndedModal(version: '1.6.0', onClose: close, openUrl: (_) async {}));
    expect(find.text('Uninstall Beta'), findsNothing);
    expect(find.text('When you have moved over, remove GodotHub Beta like any other app.'), findsOneWidget);
  });

  test('finds the uninstaller next to the launcher of a versioned install', () {
    if (!Platform.isWindows) return;
    final root = Directory.systemTemp.createTempSync('godothub-beta');
    addTearDown(() => root.deleteSync(recursive: true));
    final appDir = Directory('${root.path}\\app-0.3.0')..createSync();
    final exe = '${appDir.path}\\godothub-beta.exe';
    expect(betaUninstallerPath(exe), isNull);
    File('${root.path}\\uninstall.exe').writeAsStringSync('');
    expect(betaUninstallerPath(exe), '${root.path}\\uninstall.exe');
  });
}
