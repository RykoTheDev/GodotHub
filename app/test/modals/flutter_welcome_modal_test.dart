import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/modals/flutter_welcome_modal.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';

import '../projects/project_actions_test.dart' as base;
import '../ui/i18n_setup.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(WidgetTester tester, Widget Function(VoidCallback close) build, {Size size = const Size(1280, 800)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late BuildContext host;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
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
    ),
  );
  showGhModal<void>(host, (modal) => build(() => Navigator.of(modal).pop())).ignore();
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);

  group('flutterWelcomeStart', () {
    test('shows once on data that finished setup in the Tauri app', () {
      expect(flutterWelcomeStart(channel: 'stable', setupComplete: true, seen: null), FlutterWelcomeStart.show);
    });

    test('a fresh install is marked as seen, so it only ever shows to updating users', () {
      expect(flutterWelcomeStart(channel: 'stable', setupComplete: false, seen: null), FlutterWelcomeStart.markSeen);
    });

    test('never shows again once the flag is stored', () {
      expect(flutterWelcomeStart(channel: 'stable', setupComplete: true, seen: '1.6.0'), FlutterWelcomeStart.skip);
      expect(flutterWelcomeStart(channel: 'stable', setupComplete: false, seen: 'seen'), FlutterWelcomeStart.skip);
    });

    test('the beta channel never shows it', () {
      expect(flutterWelcomeStart(channel: 'beta', setupComplete: true, seen: null), FlutterWelcomeStart.skip);
    });

    test('the flag lives under a godothub_ key in ui_prefs.json', () {
      expect(flutterWelcomeSeenKey, startsWith('godothub_'));
    });
  });

  testWidgets('shows the highlights and the real counts, hiding empty ones', (tester) async {
    await open(
      tester,
      (close) => FlutterWelcomeModal(
        counts: const FlutterWelcomeCounts(projects: 12, workspaces: 1, templates: 0, vaultItems: 3),
        onContinue: close,
        onChangelog: close,
      ),
    );
    expect(find.text('Welcome to the new'), findsOneWidget);
    expect(find.text('Faster').hitTestable(), findsOneWidget);
    expect(find.text('Updates inside the app').hitTestable(), findsOneWidget);
    expect(find.text('Refreshed design').hitTestable(), findsOneWidget);
    expect(find.text('Everything you had is here').hitTestable(), findsOneWidget);
    expect(find.text('Your data came along'), findsOneWidget);
    expect(find.text('12 projects'), findsOneWidget);
    expect(find.text('1 workspace'), findsOneWidget);
    expect(find.text('3 vault items'), findsOneWidget);
    expect(find.textContaining('template'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the summary when nothing could be counted', (tester) async {
    await open(tester, (close) => FlutterWelcomeModal(counts: const FlutterWelcomeCounts(), onContinue: close, onChangelog: close));
    expect(find.text('Your data came along'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Continue and See what\'s new each close it once', (tester) async {
    var continued = 0;
    var changelog = 0;
    await open(
      tester,
      (close) => FlutterWelcomeModal(
        counts: const FlutterWelcomeCounts(projects: 1),
        onContinue: () {
          continued++;
          close();
        },
        onChangelog: () {
          changelog++;
          close();
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('flutter-welcome-changelog')));
    await settle(tester);
    expect(changelog, 1);
    expect(find.byType(FlutterWelcomeModal), findsNothing);

    await open(
      tester,
      (close) => FlutterWelcomeModal(
        counts: const FlutterWelcomeCounts(projects: 1),
        onContinue: () {
          continued++;
          close();
        },
        onChangelog: close,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('flutter-welcome-continue')));
    await settle(tester);
    expect(continued, 1);
  });

  testWidgets('Escape continues', (tester) async {
    var continued = 0;
    await open(
      tester,
      (close) => FlutterWelcomeModal(
        counts: const FlutterWelcomeCounts(),
        onContinue: () {
          continued++;
          close();
        },
        onChangelog: close,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(continued, 1);
  });

  testWidgets('fits a small window without overflow', (tester) async {
    await open(
      tester,
      size: const Size(800, 560),
      (close) => FlutterWelcomeModal(
        counts: const FlutterWelcomeCounts(projects: 120, workspaces: 4, templates: 9, vaultItems: 31),
        onContinue: close,
        onChangelog: close,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
  });

  for (final size in [const Size(1280, 800), const Size(700, 900)]) {
    testWidgets('all four tiles are the same size at ${size.width.toInt()} wide', (tester) async {
      await open(
        tester,
        size: size,
        (close) => FlutterWelcomeModal(counts: const FlutterWelcomeCounts(), onContinue: close, onChangelog: close),
      );
      Size tile(String title) => tester.getSize(find.ancestor(of: find.text(title).hitTestable(), matching: find.byType(Container)).first);
      final sizes = [tile('Faster'), tile('Updates inside the app'), tile('Refreshed design'), tile('Everything you had is here')];
      expect(sizes.toSet(), hasLength(1), reason: '$sizes');
    });
  }
}
