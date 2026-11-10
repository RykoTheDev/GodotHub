import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/debug/gallery/sections/overlays.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/ui/core/ui_settings.dart';
import 'package:godothub/ui/overlays/context_menu.dart';
import 'package:godothub/ui/overlays/date_picker.dart';
import 'package:godothub/ui/overlays/dropdown.dart';
import 'package:godothub/ui/overlays/menu.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';
import 'package:godothub/ui/overlays/slash_menu.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: Scaffold(body: Center(child: child)),
  );
}

Widget _trigger(String label, bool open, VoidCallback toggle) {
  return TextButton(onPressed: toggle, child: Text(open ? '$label open' : label));
}

String? _focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  tearDown(GhPopupRegistry.debugReset);

  group('GhDropdown', () {
    testWidgets('opens, selects an item and closes', (tester) async {
      final selected = <String>[];
      final changes = <bool>[];
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
            onOpenChange: changes.add,
            items: [
              GhMenuItem(id: 'a', label: 'Alpha', onSelected: () => selected.add('a')),
              GhMenuItem(id: 'b', label: 'Beta', onSelected: () => selected.add('b')),
            ],
          ),
        ),
      );
      expect(find.text('Alpha'), findsNothing);
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Menu open'), findsOneWidget);
      expect(GhPopupRegistry.openMenuCount.value, 1);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(selected, ['b']);
      expect(find.text('Alpha'), findsNothing);
      expect(changes, [true, false]);
      expect(GhPopupRegistry.openMenuCount.value, 0);
    });

    testWidgets('trigger toggles closed and outside click closes', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhDropdown(
                trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
                items: const [GhMenuItem(id: 'a', label: 'Alpha')],
              ),
              const SizedBox(height: 200),
              const Text('Elsewhere'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menu open'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(GhPopupRegistry.openMenuCount.value, 0);
    });

    testWidgets('keyboard navigation skips disabled items and wraps', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
            items: [
              const GhMenuItem(id: 'off', label: 'Off', disabled: true),
              GhMenuItem(id: 'a', label: 'Alpha', onSelected: () => selected.add('a')),
              const GhMenuItem(id: 'b', label: 'Beta', disabled: true),
              GhMenuItem(id: 'c', label: 'Gamma', onSelected: () => selected.add('c')),
              GhMenuItem(id: 'd', label: 'Delta', onSelected: () => selected.add('d')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'GhDropdown a');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown c');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown d');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown a');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown d');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown a');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, ['c']);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('Escape closes the menu and the modal sees the open count first', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _app(
          Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                seen.add(GhPopupRegistry.openMenuCount.value);
              }
              return KeyEventResult.ignored;
            },
            child: GhDropdown(
              trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
              content: (context, close) => const SizedBox(width: 100, height: 40, child: Text('Custom')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Custom'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Custom'), findsNothing);
      expect(seen, [1]);
      expect(GhPopupRegistry.openMenuCount.value, 0);
    });

    testWidgets('Escape inside the menu is handled by the menu', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _app(
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                seen.add(GhPopupRegistry.openMenuCount.value);
              }
              return KeyEventResult.ignored;
            },
            child: GhDropdown(
              trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
              items: const [GhMenuItem(id: 'a', label: 'Alpha')],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'GhDropdown a');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(seen, isEmpty);
    });

    testWidgets('submenu opens on hover delay and on click, child selection closes all', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
            items: [
              const GhMenuItem(id: 'plain', label: 'Plain'),
              GhMenuItem(
                id: 'more',
                label: 'More',
                children: [
                  GhMenuItem(id: 'x', label: 'Child X', onSelected: () => selected.add('x')),
                  const GhMenuItem(id: 'y', label: 'Child Y'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.text('Plain')));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('More')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Child X'), findsNothing);
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('Child X'), findsOneWidget);
      await gesture.moveTo(tester.getCenter(find.text('Plain')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Child X'), findsNothing);
      await gesture.removePointer();
      await tester.tap(find.text('More'));
      await tester.pump();
      expect(find.text('Child X'), findsOneWidget);
      expect(find.text('Plain'), findsOneWidget);
      await tester.tap(find.text('Child X'));
      await tester.pumpAndSettle();
      expect(selected, ['x']);
      expect(find.text('Plain'), findsNothing);
    });

    testWidgets('keyboard reaches open submenu children after the parent', (tester) async {
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
            items: const [
              GhMenuItem(
                id: 'more',
                label: 'More',
                children: [GhMenuItem(id: 'x', label: 'Child X')],
              ),
              GhMenuItem(id: 'last', label: 'Last'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'GhDropdown more');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Child X'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown more\u0000x');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(), 'GhDropdown last');
    });

    testWidgets('header and item actions close the menu and fire', (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
            header: [GhDropdownHeaderItem(id: 'h', icon: GhIcons.gear, label: 'Settings', onPressed: () => fired.add('h'))],
            items: [
              GhMenuItem(
                id: 'a',
                label: 'Alpha',
                action: GhMenuItemAction(icon: GhIcons.trash, label: 'Remove', onPressed: () => fired.add('action')),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Remove'));
      await tester.pumpAndSettle();
      expect(fired, ['action']);
      expect(find.text('Alpha'), findsNothing);
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      expect(fired, ['action', 'h']);
    });

    testWidgets('content builder receives close', (tester) async {
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
            content: (context, close) => TextButton(onPressed: close, child: const Text('Done')),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('only one popup is open at a time', (tester) async {
      await tester.pumpWidget(
        _app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhDropdown(
                trigger: (context, open, toggle) => _trigger('First', open, toggle),
                items: const [GhMenuItem(id: 'a', label: 'From first')],
              ),
              const SizedBox(width: 300),
              GhDropdown(
                trigger: (context, open, toggle) => _trigger('Second', open, toggle),
                items: const [GhMenuItem(id: 'b', label: 'From second')],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();
      expect(find.text('From first'), findsOneWidget);
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(find.text('From first'), findsNothing);
      expect(find.text('From second'), findsOneWidget);
      expect(GhPopupRegistry.openMenuCount.value, 1);
    });

    testWidgets('a dropdown opened from inside another keeps the outer open', (tester) async {
      await tester.pumpWidget(
        _app(
          GhDropdown(
            trigger: (context, open, toggle) => _trigger('Outer', open, toggle),
            content: (context, close) => GhDropdown(
              trigger: (context, open, toggle) => _trigger('Inner', open, toggle),
              items: const [GhMenuItem(id: 'i', label: 'Inner item')],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Outer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inner'));
      await tester.pumpAndSettle();
      expect(find.text('Inner item'), findsOneWidget);
      expect(find.text('Inner open'), findsOneWidget);
      expect(GhPopupRegistry.openMenuCount.value, 2);
    });

    testWidgets('scrolling an ancestor closes the menu', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SizedBox(
        height: 300,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              GhDropdown(
                trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
                items: const [GhMenuItem(id: 'a', label: 'Alpha')],
              ),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      )));
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      controller.jumpTo(40);
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(GhPopupRegistry.openMenuCount.value, 0);
    });

    test('position flips up, aligns and clamps like the React measure', () {
      const viewport = Size(800, 600);
      const menu = Size(200, 150);
      expect(
        ghDropdownPosition(
          anchor: const Rect.fromLTWH(300, 100, 100, 30),
          menu: menu,
          viewport: viewport,
          side: GhSide.bottom,
          align: GhSide.right,
        ),
        const Offset(200, 138),
      );
      expect(
        ghDropdownPosition(
          anchor: const Rect.fromLTWH(300, 100, 100, 30),
          menu: menu,
          viewport: viewport,
          side: GhSide.bottom,
          align: GhSide.left,
        ),
        const Offset(300, 138),
      );
      expect(
        ghDropdownPosition(
          anchor: const Rect.fromLTWH(300, 500, 100, 30),
          menu: menu,
          viewport: viewport,
          side: GhSide.bottom,
          align: GhSide.left,
        ),
        const Offset(300, 342),
      );
      expect(
        ghDropdownPosition(
          anchor: const Rect.fromLTWH(10, 100, 100, 30),
          menu: menu,
          viewport: viewport,
          side: GhSide.bottom,
          align: GhSide.right,
        ),
        const Offset(10, 138),
      );
      expect(
        ghDropdownPosition(
          anchor: const Rect.fromLTWH(700, 100, 60, 30),
          menu: menu,
          viewport: viewport,
          side: GhSide.top,
          align: GhSide.left,
        ),
        const Offset(560, 8),
      );
      expect(
        ghDropdownPosition(
          anchor: const Rect.fromLTWH(100, 100, 60, 30),
          menu: menu,
          viewport: viewport,
          side: GhSide.left,
          align: GhSide.right,
        ),
        const Offset(168, 100),
      );
    });
  });

  group('GhContextMenu', () {
    testWidgets('opens at the pointer, selects and closes on Escape and outside click', (tester) async {
      final selected = <String>[];
      var closed = 0;
      Widget menu() => GhContextMenu(
        position: const Offset(100, 120),
        onClose: () => closed++,
        label: 'Project actions',
        items: [
          GhMenuItem(id: 'open', label: 'Open', onSelected: () => selected.add('open')),
          const GhMenuItem(id: 'delete', label: 'Delete', danger: true, dividerAfter: true),
        ],
      );
      await tester.pumpWidget(_app(menu()));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(GhMenuSurface)), const Offset(100, 120));
      expect(_focusedLabel(), 'GhContextMenu open');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(), 'GhContextMenu delete');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(closed, 1);
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpWidget(_app(menu()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(selected, ['open']);
      expect(closed, 2);
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpWidget(_app(menu()));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(closed, 3);
    });

    testWidgets('opening a context menu closes an open dropdown', (tester) async {
      var showContext = false;
      late StateSetter update;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GhDropdown(
                    trigger: (context, open, toggle) => _trigger('Menu', open, toggle),
                    items: const [GhMenuItem(id: 'a', label: 'Alpha')],
                  ),
                  if (showContext)
                    GhContextMenu(
                      position: const Offset(20, 20),
                      onClose: () => update(() => showContext = false),
                      items: const [GhMenuItem(id: 'c', label: 'Context item')],
                    ),
                ],
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      update(() => showContext = true);
      await tester.pumpAndSettle();
      expect(find.text('Context item'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(GhPopupRegistry.openMenuCount.value, 1);
    });

    testWidgets('context menu area opens on secondary click', (tester) async {
      await tester.pumpWidget(
        _app(
          GhContextMenuArea(
            items: () => const [GhMenuItem(id: 'a', label: 'Rename')],
            child: const SizedBox(key: ValueKey('area'), width: 200, height: 100),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('area')), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    });

    test('position flips at the viewport edges', () {
      const viewport = Size(800, 600);
      const menu = Size(200, 150);
      expect(ghContextMenuPosition(point: const Offset(100, 100), menu: menu, viewport: viewport), const Offset(100, 100));
      expect(ghContextMenuPosition(point: const Offset(700, 550), menu: menu, viewport: viewport), const Offset(500, 400));
      expect(ghContextMenuPosition(point: const Offset(2, 2), menu: menu, viewport: viewport), const Offset(8, 8));
    });
  });

  group('GhSlashMenu', () {
    testWidgets('renders items, highlights on hover and selects', (tester) async {
      final highlighted = <int>[];
      final selected = <String>[];
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: GhSlashMenu(
              title: 'Commands',
              footer: 'Enter to insert',
              selectedIndex: 0,
              emptyLabel: 'Nothing found',
              items: const [
                GhSlashMenuItem(id: 'todo', label: 'Todo', hint: '/todo', icon: GhIcons.check),
                GhSlashMenuItem(id: 'tag', label: 'Tag', dotColor: Colors.green),
              ],
              onHighlight: highlighted.add,
              onSelect: (item, index) => selected.add('${item.id}$index'),
            ),
          ),
        ),
      );
      expect(find.text('COMMANDS'), findsOneWidget);
      expect(find.text('Enter to insert'), findsOneWidget);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Tag')));
      await tester.pump();
      expect(highlighted, [1]);
      await gesture.removePointer();
      await tester.tap(find.text('Tag'));
      expect(selected, ['tag1']);
      await tester.pumpAndSettle();
    });

    testWidgets('shows the empty label', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: GhSlashMenu(
              title: 'Commands',
              selectedIndex: 0,
              emptyLabel: 'Nothing found',
              items: const [],
              onHighlight: (_) {},
              onSelect: (_, _) {},
            ),
          ),
        ),
      );
      expect(find.text('Nothing found'), findsOneWidget);
    });

    testWidgets('anchor places the menu under its child', (tester) async {
      await tester.pumpWidget(
        _app(
          GhSlashMenuAnchor(
            open: true,
            menu: GhSlashMenu(
              title: 'Commands',
              selectedIndex: 0,
              emptyLabel: 'Nothing found',
              items: const [GhSlashMenuItem(id: 'a', label: 'Alpha')],
              onHighlight: (_) {},
              onSelect: (_, _) {},
            ),
            child: const SizedBox(key: ValueKey('input'), width: 400, height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final anchor = tester.getRect(find.byKey(const ValueKey('input')));
      final menu = tester.getRect(find.byType(GhMenuSurface));
      expect(menu.left, anchor.left);
      expect(menu.width, anchor.width);
      expect(menu.top, greaterThan(anchor.bottom));
    });
  });

  group('GhDatePicker', () {
    DateTime today() => DateTime(2026, 11, 10);

    testWidgets('opens on the selected month, selects a day and closes', (tester) async {
      String? changed;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: GhDatePicker(
              value: '2026-11-20',
              placeholder: 'Pick a date',
              clearLabel: 'Clear',
              today: today,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );
      expect(find.text('11/20/2026'), findsOneWidget);
      await tester.tap(find.text('11/20/2026'));
      await tester.pumpAndSettle();
      expect(find.text('November'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('2026-11-15')));
      await tester.pumpAndSettle();
      expect(changed, '2026-11-15');
      expect(find.text('November'), findsNothing);
    });

    testWidgets('navigates months, clears and closes on outside click', (tester) async {
      String? changed;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: GhDatePicker(
              value: '2026-01-05',
              placeholder: 'Pick a date',
              clearLabel: 'Clear',
              today: today,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );
      await tester.tap(find.text('1/5/2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('December'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('February'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(changed, '');
      await tester.tap(find.text('1/5/2026'));
      await tester.pumpAndSettle();
      expect(find.text('January'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('January'), findsNothing);
    });

    testWidgets('compact trigger exposes the due date label and past message', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhDatePicker(value: '', placeholder: '—', clearLabel: 'Clear', compact: true, today: today, onChanged: (_) {}),
              GhDatePicker(value: '2026-11-02', placeholder: '—', clearLabel: 'Clear', compact: true, today: today, onChanged: (_) {}),
              SizedBox(
                width: 300,
                child: GhDatePicker(
                  value: '2026-11-02',
                  placeholder: '—',
                  clearLabel: 'Clear',
                  markPastDates: true,
                  pastDateMessage: 'This date has passed',
                  today: today,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Add due date'), findsOneWidget);
      expect(find.bySemanticsLabel('Change due date: 11/2/2026'), findsOneWidget);
      expect(find.text('This date has passed'), findsOneWidget);
    });

    test('calendar grid starts on Sunday and spans 42 days', () {
      final days = ghCalendarDays(DateTime(2026, 11, 1));
      expect(days.length, 42);
      expect(days.first, DateTime(2026, 11, 1));
      final march = ghCalendarDays(DateTime(2026, 3, 1));
      expect(march.first, DateTime(2026, 3, 1));
      final april = ghCalendarDays(DateTime(2026, 4, 1));
      expect(april.first, DateTime(2026, 3, 29));
      expect(ghDateToValue(DateTime(2026, 4, 3)), '2026-04-03');
      expect(ghDateFromValue('2026-04-03'), DateTime(2026, 4, 3));
      expect(ghDateFromValue(''), isNull);
    });
  });
  testWidgets('gallery sections build without layout errors', (tester) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final section in overlaysSections) {
      await tester.pumpWidget(_app(SingleChildScrollView(child: Builder(builder: section.builder))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
