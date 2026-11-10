import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/debug/gallery/sections/feedback.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/ui/core/button.dart';
import 'package:godothub/ui/core/interaction.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';
import 'package:godothub/ui/feedback/feedback.dart';

import 'i18n_setup.dart';

Widget _app(Widget Function(BuildContext context) builder) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: Scaffold(body: Builder(builder: builder)),
  );
}

FocusNode _focusOf(WidgetTester tester, String text) => Focus.of(tester.element(find.text(text)));

Finder _pressable(String label) => find.byWidgetPredicate((widget) => widget is GhPressable && widget.semanticLabel == label);

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext host;
  await tester.pumpWidget(
    _app((context) {
      host = context;
      return const SizedBox.expand();
    }),
  );
  return host;
}

Widget _shell(BuildContext context, {VoidCallback? onClose, bool showClose = false, bool Function()? isMenuOpen, bool withButtons = true}) {
  return GhModalShell(
    icon: const SizedBox.shrink(),
    title: 'Dialog title',
    maxWidth: GhModalWidth.md,
    showClose: showClose,
    isMenuOpen: isMenuOpen,
    onClose: onClose ?? () => Navigator.of(context).pop(),
    footer: withButtons ? [GhButton(onPressed: () {}, label: 'C')] : null,
    child: withButtons
        ? Row(
            children: [
              GhButton(onPressed: () {}, label: 'A'),
              GhButton(onPressed: () {}, label: 'B'),
            ],
          )
        : const Text('Body'),
  );
}

void main() {
  setUp(setUpTestI18n);
  tearDown(() {
    GhPopupRegistry.debugReset();
  });

  group('GhModalShell', () {
    testWidgets('Escape closes the modal', (tester) async {
      final host = await _pumpHost(tester);
      showGhModal<void>(host, (context) => _shell(context));
      await tester.pumpAndSettle();
      expect(find.text('DIALOG TITLE'), findsOneWidget);
      expect(GhModalEvents.openDialogs.value, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('DIALOG TITLE'), findsNothing);
      expect(GhModalEvents.openDialogs.value, 0);
    });

    testWidgets('Escape is ignored while a menu is open or without onClose', (tester) async {
      final host = await _pumpHost(tester);
      var menuOpen = true;
      var closes = 0;
      showGhModal<void>(host, (context) => _shell(context, isMenuOpen: () => menuOpen, onClose: () => closes++));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(closes, 0);

      menuOpen = false;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(closes, 1);
    });

    testWidgets('the shared menu counter blocks Escape by default', (tester) async {
      final host = await _pumpHost(tester);
      var closes = 0;
      showGhModal<void>(host, (context) => _shell(context, onClose: () => closes++));
      await tester.pumpAndSettle();

      late final GhPopupHandle menu;
      menu = GhPopupRegistry.open(close: () => menu.release());
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closes, 0);

      menu.release();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closes, 1);
    });

    testWidgets('clicking the backdrop closes, clicking the dialog does not', (tester) async {
      final host = await _pumpHost(tester);
      showGhModal<void>(host, (context) => _shell(context, withButtons: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      expect(find.text('DIALOG TITLE'), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('DIALOG TITLE'), findsNothing);
    });

    testWidgets('close button calls onClose when showClose is true', (tester) async {
      final host = await _pumpHost(tester);
      showGhModal<void>(host, (context) => _shell(context, showClose: true, withButtons: false));
      await tester.pumpAndSettle();

      await tester.tap(_pressable(t.common.close));
      await tester.pumpAndSettle();
      expect(find.text('DIALOG TITLE'), findsNothing);
    });

    testWidgets('Tab and Shift+Tab cycle inside the dialog', (tester) async {
      final host = await _pumpHost(tester);
      showGhModal<void>(host, (context) => _shell(context));
      await tester.pumpAndSettle();

      final a = _focusOf(tester, 'A');
      final b = _focusOf(tester, 'B');
      final c = _focusOf(tester, 'C');
      expect([a.hasPrimaryFocus, b.hasPrimaryFocus, c.hasPrimaryFocus], [false, false, false]);

      await _tab(tester);
      expect(a.hasPrimaryFocus, isTrue);
      await _tab(tester);
      expect(b.hasPrimaryFocus, isTrue);
      await _tab(tester);
      expect(c.hasPrimaryFocus, isTrue);
      await _tab(tester);
      expect(a.hasPrimaryFocus, isTrue);
      await _shiftTab(tester);
      expect(c.hasPrimaryFocus, isTrue);
      await _shiftTab(tester);
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('Shift+Tab from the banner goes to the last element', (tester) async {
      final host = await _pumpHost(tester);
      showGhModal<void>(host, (context) => _shell(context));
      await tester.pumpAndSettle();

      await _shiftTab(tester);
      expect(_focusOf(tester, 'C').hasPrimaryFocus, isTrue);
    });

    testWidgets('Tab without focusable elements keeps focus inside', (tester) async {
      final host = await _pumpHost(tester);
      showGhModal<void>(host, (context) => _shell(context, withButtons: false));
      await tester.pumpAndSettle();

      final before = FocusManager.instance.primaryFocus;
      await _tab(tester);
      expect(FocusManager.instance.primaryFocus, same(before));
    });

    testWidgets('focus returns to the opener after close', (tester) async {
      final opener = FocusNode(debugLabel: 'opener');
      addTearDown(opener.dispose);
      late BuildContext host;
      await tester.pumpWidget(
        _app((context) {
          host = context;
          return Center(
            child: GhButton(onPressed: () {}, focusNode: opener, label: 'Open'),
          );
        }),
      );
      opener.requestFocus();
      await tester.pump();
      expect(opener.hasPrimaryFocus, isTrue);

      showGhModal<void>(host, (context) => _shell(context));
      await tester.pumpAndSettle();
      expect(opener.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(opener.hasPrimaryFocus, isTrue);
    });

    testWidgets('onKeyEvent runs first and can stop the default handling', (tester) async {
      final host = await _pumpHost(tester);
      var custom = 0;
      var closes = 0;
      showGhModal<void>(
        host,
        (context) => GhModalShell(
          icon: const SizedBox.shrink(),
          title: 'Custom keys',
          onClose: () => closes++,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              custom++;
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: const Text('Body'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(custom, 1);
      expect(closes, 0);
    });
  });

  group('GhConfirmDialog', () {
    testWidgets('default variant focuses confirm and resolves true', (tester) async {
      final host = await _pumpHost(tester);
      bool? result;
      showGhConfirmDialog(host, title: 'Discard', description: 'Sure?', confirmLabel: 'Discard it').then((v) => result = v);
      await tester.pumpAndSettle();

      expect(_focusOf(tester, 'Discard it').hasPrimaryFocus, isTrue);
      expect(_focusOf(tester, t.common.cancel).hasPrimaryFocus, isFalse);
      expect(find.byWidgetPredicate((w) => w is GhIcon && w.icon == GhIcons.alertTriangle), findsOneWidget);
      expect(_pressable(t.common.close), findsNothing);

      await tester.tap(find.text('Discard it'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('danger variant focuses cancel and Escape resolves false', (tester) async {
      final host = await _pumpHost(tester);
      bool? result;
      showGhConfirmDialog(
        host,
        title: 'Delete',
        description: 'Gone forever',
        confirmLabel: 'Delete it',
        cancelLabel: 'Keep',
        variant: GhConfirmVariant.danger,
      ).then((v) => result = v);
      await tester.pumpAndSettle();

      expect(_focusOf(tester, 'Keep').hasPrimaryFocus, isTrue);
      expect(_focusOf(tester, 'Delete it').hasPrimaryFocus, isFalse);
      expect(find.byWidgetPredicate((w) => w is GhIcon && w.icon == GhIcons.trash), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('empty cancel label falls back to Cancel', (tester) async {
      final host = await _pumpHost(tester);
      showGhConfirmDialog(host, title: 'T', description: 'D', confirmLabel: 'OK', cancelLabel: '');
      await tester.pumpAndSettle();
      expect(find.text(t.common.cancel), findsOneWidget);
    });
  });

  group('toasts', () {
    Future<GhToastStore> pumpToasts(WidgetTester tester) async {
      final store = GhToastStore();
      await tester.pumpWidget(_app((context) => GhToastHost(store: store, child: const SizedBox.expand())));
      return store;
    }

    testWidgets('toasts are removed after their ttl', (tester) async {
      final store = await pumpToasts(tester);
      store.pushToast(GhToastType.success, 'Saved');
      store.pushToast(GhToastType.info, 'Later', ttlMs: 8000);
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3999));
      expect(store.toasts.map((t) => t.message), ['Saved', 'Later']);

      await tester.pump(const Duration(milliseconds: 1));
      expect(store.toasts.map((t) => t.message), ['Later']);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Later'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('dismiss button removes the toast', (tester) async {
      final store = await pumpToasts(tester);
      store.pushToast(GhToastType.error, 'Broken');
      await tester.pumpAndSettle();

      await tester.tap(_pressable(t.common.dismiss));
      await tester.pumpAndSettle();
      expect(find.text('Broken'), findsNothing);
      expect(store.toasts, isEmpty);
    });

    testWidgets('action click dismisses and runs the action', (tester) async {
      final store = await pumpToasts(tester);
      var clicks = 0;
      store.pushToast(
        GhToastType.success,
        'Removed',
        action: GhToastAction(label: 'Undo', onClick: () => clicks++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(clicks, 1);
      expect(store.toasts, isEmpty);
      expect(find.text('Removed'), findsNothing);
    });

    testWidgets('reportError shows the message or the fallback for 6 seconds', (tester) async {
      final store = await pumpToasts(tester);
      store.reportError(Exception('disk full'));
      store.reportError(42);
      await tester.pump();
      expect(find.text('disk full'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 5999));
      expect(store.toasts, hasLength(2));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(store.toasts, isEmpty);
      expect(find.text('disk full'), findsNothing);
    });

    test('subscribe emits immediately and unsubscribes', () {
      final store = GhToastStore();
      final seen = <int>[];
      final unsubscribe = store.subscribe((toasts) => seen.add(toasts.length));
      expect(seen, [0]);
      final id = store.pushToast(GhToastType.info, 'x');
      expect(seen, [0, 1]);
      unsubscribe();
      store.dismissToast(id);
      expect(seen, [0, 1]);
      expect(store.toasts, isEmpty);
    });
  });

  group('notices', () {
    testWidgets('announcement banner shows after the usage threshold and dismiss persists', (tester) async {
      final prefs = <String, String>{GhAnnouncement.usageKey: '${GhAnnouncement.usageThresholdSeconds - 15}'};
      final controller = GhAnnouncementController(getItem: (k) => prefs[k], setItem: (k, v) => prefs[k] = v);
      var supports = 0;
      await tester.pumpWidget(_app((context) => GhAnnouncementBanner(controller: controller, onSupport: () => supports++)));
      controller.start();
      await tester.pump();
      expect(find.text(t.common.announcement_support_title), findsNothing);

      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.text(t.common.announcement_support_title), findsOneWidget);
      expect(prefs[GhAnnouncement.usageKey], '${GhAnnouncement.usageThresholdSeconds}');

      await tester.tap(find.text(t.common.support));
      expect(supports, 1);

      await tester.tap(_pressable(t.common.dismiss));
      await tester.pumpAndSettle();
      expect(find.text(t.common.announcement_support_title), findsNothing);
      expect(prefs[GhAnnouncement.dismissKey], '1');
      controller.dispose();
    });

    testWidgets('workspace switch notice appears on change and hides itself', (tester) async {
      const workspaces = [GhWorkspaceRef(id: 'a', name: 'Alpha', icon: 'house'), GhWorkspaceRef(id: 'b', name: 'Beta', icon: 'rocket')];
      Widget build(String id) => _app((context) => GhWorkspaceSwitchNotice(activeId: id, workspaces: workspaces));
      await tester.pumpWidget(build('a'));
      expect(find.text('Alpha'), findsNothing);

      await tester.pumpWidget(build('b'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text(t.common.workspace_switched_to.toUpperCase()), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('Beta'), findsNothing);
    });
  });

  testWidgets('gallery sections render without layout errors', (tester) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final section in feedbackSections) {
      await tester.pumpWidget(_app((context) => SingleChildScrollView(child: Builder(builder: section.builder))));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: section.title);
      if (section.title == 'Modals') {
        for (final label in ['Shell sm', 'Long body', 'Tall body height', 'Confirm danger']) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
      }
      if (section.title == 'Toasts') {
        await tester.tap(find.text('With action'));
        await tester.pump();
        expect(find.text('Project removed'), findsOneWidget);
        expect(tester.getBottomRight(find.byType(GhToastCard).last).dx, greaterThan(1700));
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    ghToasts.clear();
  });
}
