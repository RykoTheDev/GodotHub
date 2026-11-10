import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/keyboard_shortcuts.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/workspaces.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';

ShortcutCommand? resolve(
  String key, {
  bool ctrl = false,
  bool meta = false,
  bool alt = false,
  bool shift = false,
  int? digit,
  bool input = false,
  bool nonSelection = false,
  bool popup = false,
  String palette = 'p',
}) => resolveShortcut(
  ShortcutKeyInput(
    key: key,
    digitCode: digit,
    ctrl: ctrl,
    meta: meta,
    alt: alt,
    shift: shift,
    isInput: input,
    nonSelectionTarget: nonSelection,
    popupOpen: popup,
  ),
  paletteKey: palette,
);

Workspace workspace(String id) => Workspace(id: id, name: id, icon: 'folder', color: '#fff', createdAt: '2026-01-01');

void main() {
  group('resolveShortcut', () {
    test('modifier shortcuts and their text-field rules', () {
      expect(resolve('p', ctrl: true)?.kind, ShortcutCommandKind.commandPalette);
      expect(resolve('P', meta: true, input: true)?.kind, ShortcutCommandKind.commandPalette);
      expect(resolve('k', ctrl: true, palette: 'K')?.kind, ShortcutCommandKind.commandPalette);
      expect(resolve('p', ctrl: true, palette: 'k'), isNull);
      expect(resolve('n', ctrl: true)?.kind, ShortcutCommandKind.newProject);
      expect(resolve('n', ctrl: true, input: true), isNull);
      expect(resolve(',', ctrl: true)?.kind, ShortcutCommandKind.openSettings);
      expect(resolve(',', ctrl: true, shift: true), isNull);
      expect(resolve(',', ctrl: true, input: true), isNull);
      expect(resolve('r', ctrl: true, input: true)?.kind, ShortcutCommandKind.restart);
      expect(resolve('f', ctrl: true)?.kind, ShortcutCommandKind.focusSearch);
      expect(resolve('f', ctrl: true, input: true), isNull);
      expect(resolve('3', ctrl: true), const ShortcutCommand(ShortcutCommandKind.switchTab, index: 2));
      expect(resolve('3', ctrl: true, input: true), isNull);
      expect(resolve('0', ctrl: true), isNull);
      expect(resolve('x', ctrl: true), isNull);
    });

    test('escape fires anywhere unless a popup is open', () {
      expect(resolve('Escape', input: true)?.kind, ShortcutCommandKind.escape);
      expect(resolve('Escape', ctrl: true)?.kind, ShortcutCommandKind.escape);
      expect(resolve('Escape', popup: true), isNull);
    });

    test('alt plus a physical digit switches workspace', () {
      expect(resolve('¡', alt: true, digit: 1), const ShortcutCommand(ShortcutCommandKind.switchWorkspace, index: 0));
      expect(resolve('9', alt: true, digit: 9)?.index, 8);
      expect(resolve('1', alt: true, shift: true, digit: 1), isNull);
      expect(resolve('1', alt: true, input: true, digit: 1), isNull);
      expect(resolve('1', ctrl: true, alt: true, digit: 1)?.kind, ShortcutCommandKind.switchTab);
    });

    test('enter and delete act on the selection only from a plain target', () {
      expect(resolve('Enter'), const ShortcutCommand(ShortcutCommandKind.launchSelection, preventDefault: false));
      expect(resolve('Delete')?.kind, ShortcutCommandKind.deleteSelection);
      expect(resolve('Backspace')?.kind, ShortcutCommandKind.deleteSelection);
      for (final blocked in [resolve('Enter', input: true), resolve('Delete', nonSelection: true), resolve('Backspace', popup: true)]) {
        expect(blocked, isNull);
      }
      expect(resolve('a'), isNull);
    });

  });

  group('ShortcutDispatcher', () {
    late FakeRustApi rust;
    late List<AppSignal> signals;

    setUp(() {
      rust = installFakeRust();
      signals = [];
      AppSignals.all.listen(signals.add);
    });

    Future<ProviderContainer> container(AppSettings settings, {List<Workspace> workspaces = const []}) async {
      rust.on('crateApiWorkspaceListWorkspaces', () async => WorkspacesState(workspaces: workspaces, activeId: workspaces.isEmpty ? 'w' : workspaces.first.id));
      final c = ProviderContainer(overrides: [fakeSettings(() => settings)]);
      addTearDown(c.dispose);
      c.listen(workspacesProvider, (_, _) {});
      await c.read(settingsProvider.future);
      await pumpEventQueue();
      return c;
    }

    test('default actions emit the app signals', () async {
      final c = await container(copySettings(defaultSettings, disabledFeatures: const ['templates', 'vault']));
      final dispatcher = c.read(keyboardShortcutsProvider);
      expect(dispatcher.shortcutTabs, ['projects', 'versions', 'storage', 'asset-store', 'news']);
      for (final key in ['p', 'n', ',', 'r', 'f', '3']) {
        dispatcher.handle(ShortcutKeyInput(key: key, ctrl: true));
      }
      dispatcher.handle(const ShortcutKeyInput(key: '9', ctrl: true));
      dispatcher.handle(const ShortcutKeyInput(key: 'Escape'));
      dispatcher.handle(const ShortcutKeyInput(key: 'Enter'));
      dispatcher.handle(const ShortcutKeyInput(key: 'Delete'));
      expect([for (final s in signals) '${s.name}${s.detail == null ? '' : ':${s.detail}'}'], [
        toggleCommandPaletteSignal,
        newProjectRequestSignal,
        '$setTabSignal:settings',
        confirmRestartSignal,
        focusSearchSignal,
        '$setTabSignal:storage',
        escapeSignal,
        launchSelectionSignal,
        deleteSelectionSignal,
      ]);
    });

    test('custom palette key comes from settings and handlers override signals', () async {
      final c = await container(copySettings(defaultSettings, commandPaletteKeybind: 'k'));
      final dispatcher = c.read(keyboardShortcutsProvider);
      var palette = 0;
      final handlers = ShortcutHandlers(onCommandPalette: () => palette++);
      expect(dispatcher.handle(const ShortcutKeyInput(key: 'p', ctrl: true), handlers), isNull);
      dispatcher.handle(const ShortcutKeyInput(key: 'k', ctrl: true), handlers);
      expect(palette, 1);
      expect(signals, isEmpty);
    });

    test('alt+digit switches to that workspace only when workspaces are enabled', () async {
      final switched = <String>[];
      rust.on('crateApiWorkspaceSwitchWorkspace', ({required String id}) async {
        switched.add(id);
        return WorkspacesState(workspaces: [workspace('a'), workspace('b')], activeId: id);
      });
      final c = await container(defaultSettings, workspaces: [workspace('a'), workspace('b')]);
      final dispatcher = c.read(keyboardShortcutsProvider);
      dispatcher.handle(const ShortcutKeyInput(key: '2', alt: true, digitCode: 2));
      dispatcher.handle(const ShortcutKeyInput(key: '5', alt: true, digitCode: 5));
      await pumpEventQueue();
      expect(switched, ['b']);

      final off = await container(copySettings(defaultSettings, workspacesEnabled: false), workspaces: [workspace('a'), workspace('b')]);
      off.read(keyboardShortcutsProvider).handle(const ShortcutKeyInput(key: '2', alt: true, digitCode: 2));
      await pumpEventQueue();
      expect(switched, ['b']);
    });
  });

  group('GhKeyboardShortcuts', () {
    late List<String> fired;

    setUp(() {
      installFakeRust();
      GhPopupRegistry.debugReset();
      fired = [];
    });

    Future<void> pump(WidgetTester tester, {FocusNode? buttonFocus}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fakeSettings(() => defaultSettings)],
          child: MaterialApp(
            home: Scaffold(
              body: GhKeyboardShortcuts(
                handlers: ShortcutHandlers(
                  onNewProject: () => fired.add('new'),
                  onEscape: () => fired.add('escape'),
                  onDeleteSelection: () => fired.add('delete'),
                  onLaunchSelection: () => fired.add('launch'),
                  onFocusSearch: () => fired.add('search'),
                ),
                child: Column(
                  children: [
                    const TextField(key: ValueKey('field')),
                    TextButton(focusNode: buttonFocus, onPressed: () {}, child: const Text('button')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('fires from the shell but respects text fields', (tester) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(fired, ['new', 'search', 'delete', 'launch']);

      fired.clear();
      await tester.tap(find.byKey(const ValueKey('field')));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(fired, ['escape']);
    });

    testWidgets('a focused button blocks selection keys and an open popup blocks escape', (tester) async {
      final buttonFocus = FocusNode();
      addTearDown(buttonFocus.dispose);
      await pump(tester, buttonFocus: buttonFocus);
      buttonFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      expect(fired, isEmpty);

      final handle = GhPopupRegistry.open(close: () {});
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(fired, isEmpty);
      handle.release();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(fired, ['escape']);
    });
  });
}
