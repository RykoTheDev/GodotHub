import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/debug_mode.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/ui/feedback/toast.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';
import 'package:godothub/ui/shell/sidebar.dart' show GhSidebar, GhSidebarTab, GhSidebarTabButton;

import '../ui/i18n_setup.dart';

void main() {
  late MemoryUiPrefsBackend backend;

  setUp(() {
    backend = MemoryUiPrefsBackend();
    UiPrefsStore.instance = UiPrefsStore(backend);
    debugResetDebugMode();
  });

  tearDown(ghToasts.clear);

  group('GhSettingsClickCounter', () {
    test('unlocks after five clicks inside two seconds and then starts over', () {
      final counter = GhSettingsClickCounter();
      final start = DateTime(2026);
      for (var i = 0; i < 4; i++) {
        expect(counter.register(start.add(Duration(milliseconds: i * 300))), isFalse);
      }
      expect(counter.register(start.add(const Duration(milliseconds: 1200))), isTrue);
      for (var i = 0; i < 4; i++) {
        expect(counter.register(start.add(Duration(milliseconds: 1300 + i))), isFalse);
      }
      expect(counter.register(start.add(const Duration(milliseconds: 1304))), isTrue);
    });

    test('the window is exclusive at two seconds', () {
      final start = DateTime(2026);
      final inside = GhSettingsClickCounter();
      for (final ms in [0, 500, 1000, 1500]) {
        expect(inside.register(start.add(Duration(milliseconds: ms))), isFalse);
      }
      expect(inside.register(start.add(const Duration(milliseconds: 1999))), isTrue);

      final edge = GhSettingsClickCounter();
      for (final ms in [0, 500, 1000, 1500, 2000]) {
        expect(edge.register(start.add(Duration(milliseconds: ms))), isFalse);
      }
      expect(edge.register(start.add(const Duration(milliseconds: 2001))), isTrue);
    });

    test('slow clicks never unlock', () {
      final start = DateTime(2026);
      final slow = GhSettingsClickCounter();
      for (var i = 0; i < 10; i++) {
        expect(slow.register(start.add(Duration(milliseconds: i * 900))), isFalse);
      }
    });

    test('sub-millisecond differences are ignored like Date.now', () {
      final start = DateTime(2026);
      final counter = GhSettingsClickCounter(clicksToUnlock: 2);
      expect(counter.register(start), isFalse);
      expect(counter.register(start.add(const Duration(milliseconds: 1999, microseconds: 999))), isTrue);
      final late = GhSettingsClickCounter(clicksToUnlock: 2);
      expect(late.register(start.add(const Duration(microseconds: 999))), isFalse);
      expect(late.register(start.add(const Duration(milliseconds: 2000, microseconds: 1))), isFalse);
    });
  });

  group('debug unlock state', () {
    test('reads the stored flag', () {
      expect(isDebugUnlocked, isFalse);
      UiPrefsStore.instance.fill({debugUnlockedStorageKey: '"1"'});
      debugResetDebugMode();
      expect(isDebugUnlocked, isTrue);
      UiPrefsStore.instance.fill({debugUnlockedStorageKey: '"true"'});
      debugResetDebugMode();
      expect(isDebugUnlocked, isFalse);
    });

    test('setDebugUnlocked persists and notifies every time', () async {
      var notified = 0;
      void listener() => notified++;
      debugUnlocked.addListener(listener);
      addTearDown(() => debugUnlocked.removeListener(listener));

      setDebugUnlocked(true);
      setDebugUnlocked(true);
      expect(debugUnlocked.value, isTrue);
      expect(notified, 2);
      await UiPrefsStore.instance.flush();
      expect(backend.values[debugUnlockedStorageKey], '"1"');

      setDebugUnlocked(false);
      expect(isDebugUnlocked, isFalse);
      await UiPrefsStore.instance.flush();
      expect(backend.values.containsKey(debugUnlockedStorageKey), isFalse);
      expect(notified, 3);
    });

    test('five quick settings clicks unlock once and show a toast', () {
      final start = DateTime(2026);
      for (var i = 0; i < 4; i++) {
        registerSettingsClick(start.add(Duration(milliseconds: i * 100)));
      }
      expect(isDebugUnlocked, isFalse);
      expect(ghToasts.toasts, isEmpty);

      registerSettingsClick(start.add(const Duration(milliseconds: 400)));
      expect(isDebugUnlocked, isTrue);
      expect(UiPrefsStore.instance.getItem(debugUnlockedStorageKey), '1');
      expect(ghToasts.toasts.single.type, GhToastType.info);
      expect(ghToasts.toasts.single.message, 'Debug settings unlocked');

      for (var i = 0; i < 10; i++) {
        registerSettingsClick(start.add(Duration(milliseconds: 500 + i)));
      }
      expect(ghToasts.toasts, hasLength(1));
    });

    test('clicks are ignored while already unlocked', () {
      setDebugUnlocked(true);
      final start = DateTime(2026);
      for (var i = 0; i < 4; i++) {
        registerSettingsClick(start.add(Duration(milliseconds: i)));
      }
      setDebugUnlocked(false);
      registerSettingsClick(start.add(const Duration(milliseconds: 10)));
      expect(isDebugUnlocked, isFalse);
    });
  });

  group('sidebar', () {
    setUp(setUpTestI18n);
    tearDown(GhPopupRegistry.debugReset);

    testWidgets('settings clicks in the sidebar feed the debug counter', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: GhTheme.defaults().toThemeData(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: 600,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GhSidebar(
                      tabs: const [GhSidebarTab(id: 'projects', label: 'Projects', icon: GhIcons.folder)],
                      activeTab: 'projects',
                      onTabChange: changes.add,
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final settings = find.byWidgetPredicate((w) => w is GhSidebarTabButton && w.tab.id == 'settings');
      for (var i = 0; i < 4; i++) {
        await tester.tap(settings);
      }
      expect(isDebugUnlocked, isFalse);
      await tester.tap(settings);
      await tester.pump();
      expect(isDebugUnlocked, isTrue);
      expect(changes, List.filled(5, 'settings'));
      ghToasts.clear();
    });
  });
}
