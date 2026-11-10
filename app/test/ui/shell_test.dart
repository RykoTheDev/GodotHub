import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/debug/gallery/sections/shell.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/ui/controls/negative_margin.dart';
import 'package:godothub/ui/core/tooltip.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';
import 'package:godothub/ui/shell/account_menu.dart';
import 'package:godothub/ui/shell/color_swatch_picker.dart';
import 'package:godothub/ui/shell/disclosure.dart';
import 'package:godothub/ui/shell/overlay_scroll_area.dart';
import 'package:godothub/ui/shell/sidebar.dart';
import 'package:godothub/ui/shell/workspace_form.dart';
import 'package:godothub/ui/shell/workspace_switcher.dart';

import 'i18n_setup.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: child),
    ),
  );
}

Widget _sidebarHost(Widget sidebar) {
  return Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      height: 600,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebar,
          const Expanded(child: SizedBox()),
        ],
      ),
    ),
  );
}

const _group = GhSidebarGroup(id: 'library', label: 'Library', icon: GhIcons.book);

const _tabs = [
  GhSidebarTab(id: 'projects', label: 'Projects', icon: GhIcons.folder, shortcut: 1, badge: 14),
  GhSidebarTab(id: 'versions', label: 'Versions', icon: GhIcons.download),
  GhSidebarTab(id: 'templates', label: 'Templates', icon: GhIcons.clone, group: _group),
  GhSidebarTab(id: 'vault', label: 'Vault', icon: GhIcons.lock, group: _group, badge: 2),
  GhSidebarTab(id: 'news', label: 'Godot News', icon: GhIcons.news, isNew: true),
];

Finder _tooltip(String message) => find.byWidgetPredicate((w) => w is GhTooltip && w.message == message);

Finder _tabButton(String id) => find.byWidgetPredicate((w) => w is GhSidebarTabButton && w.tab.id == id);

Finder get _strip => find.byWidgetPredicate((w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn);

double _sidebarWidth(WidgetTester tester) => tester.getSize(find.byType(GhNegativeMargin).first).width;

const _workspaces = [
  GhWorkspace(id: 'a', name: 'Work', icon: 'briefcase', color: '#457ff2'),
  GhWorkspace(id: 'b', name: 'Personal', icon: 'house', color: '#23a55a'),
];

void main() {
  setUp(setUpTestI18n);
  tearDown(GhPopupRegistry.debugReset);

  group('helpers', () {
    test('badge label caps at 9+', () {
      expect(ghSidebarBadgeLabel(3), '3');
      expect(ghSidebarBadgeLabel(9), '9');
      expect(ghSidebarBadgeLabel(10), '9+');
    });

    test('mod label per platform', () {
      expect(ghModLabel('P', isMac: true), '⌘P');
      expect(ghModLabel('P', isMac: false), 'Ctrl+P');
      expect(ghWorkspaceShortcut(0, isMac: true), '⌥1');
      expect(ghWorkspaceShortcut(2, isMac: false), 'Alt+3');
    });

    test('settings click counter unlocks after five clicks in two seconds', () {
      final counter = GhSettingsClickCounter();
      final start = DateTime(2026);
      for (var i = 0; i < 4; i++) {
        expect(counter.register(start.add(Duration(milliseconds: i * 300))), isFalse);
      }
      expect(counter.register(start.add(const Duration(milliseconds: 1200))), isTrue);
      expect(counter.register(start.add(const Duration(milliseconds: 1300))), isFalse);
      final slow = GhSettingsClickCounter();
      for (var i = 0; i < 6; i++) {
        expect(slow.register(start.add(Duration(milliseconds: i * 900))), isFalse);
      }
    });

    test('workspace name validation', () {
      expect(ghWorkspaceNameError('  ', const []), t.common.workspace_name_required_error);
      expect(ghWorkspaceNameError(' work ', const ['Work']), t.common.workspace_name_taken_error);
      expect(ghWorkspaceNameError('Jam', const ['Work']), isNull);
    });

    test('workspace menu item mirrors the workspace list', () {
      expect(ghWorkspaceMenuItem(workspaces: const [], activeId: null, onSwitch: (_) {}, onEdit: (_) {}, onCreate: () {}), isNull);
      final switched = <String>[];
      final edited = <String>[];
      var created = 0;
      final item = ghWorkspaceMenuItem(
        workspaces: _workspaces,
        activeId: 'missing',
        onSwitch: switched.add,
        onEdit: edited.add,
        onCreate: () => created++,
        isMac: false,
      )!;
      expect(item.label, 'Work');
      expect(item.dividerAfter, isTrue);
      expect(item.action!.label, t.common.edit_workspace_title);
      expect(item.children.map((c) => c.label), ['Work', 'Personal', t.common.create_workspace]);
      expect(item.children.first.active, isTrue);
      expect(item.children[1].shortcut, 'Alt+2');
      expect(item.children[1].dividerAfter, isTrue);
      item.children[1].onSelected!();
      item.action!.onPressed();
      item.children.last.onSelected!();
      expect(switched, ['b']);
      expect(edited, ['a']);
      expect(created, 1);
    });
  });

  group('GhSidebar', () {
    testWidgets('renders tabs, badges and handles selection', (tester) async {
      final changes = <String>[];
      final seen = <List<String>>[];
      await tester.pumpWidget(
        _app(
          _sidebarHost(
            GhSidebar(
              tabs: _tabs,
              activeTab: 'projects',
              onTabChange: changes.add,
              onSeenNewTabsChanged: seen.add,
              onOpenCommandPalette: () {},
              isMac: false,
            ),
          ),
        ),
      );
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('9+'), findsOneWidget);
      expect(find.text(t.common.new_badge), findsOneWidget);
      expect(find.text('Ctrl+P'), findsOneWidget);
      expect(find.text(t.common.search), findsOneWidget);
      await tester.tap(find.text('Versions'));
      await tester.tap(find.text('Godot News'));
      await tester.pump();
      expect(changes, ['versions', 'news']);
      expect(seen, [
        ['news'],
      ]);
      expect(find.text(t.common.new_badge), findsNothing);
    });

    testWidgets('settings button reports debug clicks and navigates', (tester) async {
      final changes = <String>[];
      var clicks = 0;
      await tester.pumpWidget(
        _app(_sidebarHost(GhSidebar(tabs: _tabs, activeTab: 'projects', onTabChange: changes.add, onSettingsClick: () => clicks++))),
      );
      await tester.tap(_tabButton('settings'));
      await tester.tap(_tabButton('settings'));
      await tester.pump();
      expect(clicks, 2);
      expect(changes, ['settings', 'settings']);
    });

    testWidgets('groups collapse, show the active child and reopen on navigation', (tester) async {
      final closed = <List<String>>[];
      var active = 'templates';
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _sidebarHost(GhSidebar(tabs: _tabs, activeTab: active, onTabChange: (_) {}, onClosedGroupsChanged: closed.add));
            },
          ),
        ),
      );
      expect(find.text('Vault'), findsOneWidget);
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(closed.last, ['library']);
      expect(find.text('Vault'), findsNothing);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      rebuild(() => active = 'vault');
      await tester.pumpAndSettle();
      expect(closed.last, isEmpty);
      expect(find.text('Vault'), findsOneWidget);
    });

    testWidgets('collapses to icons and expands back', (tester) async {
      final collapsed = <bool>[];
      await tester.pumpWidget(
        _app(
          _sidebarHost(
            GhSidebar(
              tabs: _tabs,
              activeTab: 'projects',
              onTabChange: (_) {},
              onCollapsedChanged: collapsed.add,
              onOpenCommandPalette: () {},
            ),
          ),
        ),
      );
      expect(_sidebarWidth(tester), GhSidebar.defaultWidth);
      await tester.tap(_tooltip(t.common.collapse_sidebar));
      await tester.pumpAndSettle();
      expect(collapsed, [true]);
      expect(_sidebarWidth(tester), GhSidebar.collapsedWidth);
      expect(find.text('Projects'), findsNothing);
      expect(find.text('9+'), findsOneWidget);
      expect(_tooltip('Projects'), findsOneWidget);
      expect(_tooltip(t.common.search), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(600, 300));
      await mouse.moveTo(tester.getCenter(find.text('9+')));
      await tester.pumpAndSettle();
      await tester.tap(_tooltip(t.common.expand_sidebar));
      await tester.pumpAndSettle();
      expect(collapsed, [true, false]);
      expect(_sidebarWidth(tester), GhSidebar.defaultWidth);
      expect(find.text('Projects'), findsOneWidget);
      await mouse.removePointer();
    });

    testWidgets('resize strip drags width and resets on double click', (tester) async {
      final widths = <double>[];
      await tester.pumpWidget(
        _app(_sidebarHost(GhSidebar(tabs: _tabs, activeTab: 'projects', onTabChange: (_) {}, onWidthChanged: widths.add))),
      );
      final center = tester.getCenter(_strip);
      final gesture = await tester.createGesture();
      await gesture.down(center, timeStamp: const Duration(seconds: 1));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(find.text('296px'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(widths, [296]);
      expect(_sidebarWidth(tester), 296);
      final quick = await tester.createGesture();
      await quick.down(tester.getCenter(_strip) + const Offset(0, 100), timeStamp: const Duration(milliseconds: 1200));
      await quick.up();
      await tester.pumpAndSettle();
      expect(widths.last, GhSidebar.defaultWidth);
      expect(_sidebarWidth(tester), GhSidebar.defaultWidth);
    });

    testWidgets('resize clamps and mirrors in RTL', (tester) async {
      final widths = <double>[];
      await tester.pumpWidget(
        _app(
          _sidebarHost(GhSidebar(tabs: _tabs, activeTab: 'projects', onTabChange: (_) {}, onWidthChanged: widths.add)),
          direction: TextDirection.rtl,
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(_strip));
      await gesture.moveBy(const Offset(-300, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(widths, [GhSidebar.maxWidth]);
    });

    testWidgets('update button, workspace tip and connected layout', (tester) async {
      var updates = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        _app(
          _sidebarHost(
            GhSidebar(
              tabs: _tabs,
              activeTab: 'projects',
              onTabChange: (_) {},
              connected: true,
              updateAvailable: true,
              onOpenUpdatesModal: () => updates++,
              workspacesEnabled: true,
              onWorkspaceTipDismissed: () => dismissed++,
            ),
          ),
        ),
      );
      await tester.tap(find.text(t.common.update_available));
      expect(updates, 1);
      expect(find.text(t.nav.workspace_tip_title), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(t.nav.workspace_tip_dismiss));
      await tester.pump();
      expect(dismissed, 1);
      expect(find.text(t.nav.workspace_tip_title), findsNothing);
    });

    testWidgets('account trigger opens the account menu', (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(_app(_sidebarHost(GhSidebar(tabs: _tabs, activeTab: 'projects', onTabChange: navigated.add))));
      await tester.tap(_tabButton('account'));
      await tester.pumpAndSettle();
      expect(find.text(t.nav.changelog), findsOneWidget);
      expect(GhPopupRegistry.openMenuCount.value, 1);
      await tester.tap(find.text(t.nav.changelog));
      await tester.pumpAndSettle();
      expect(navigated, ['changelog']);
      expect(GhPopupRegistry.openMenuCount.value, 0);
    });
  });

  group('GhAccountMenu', () {
    testWidgets('shows name, linked accounts and callbacks', (tester) async {
      final calls = <String>[];
      var opened = <bool>[];
      await tester.pumpWidget(
        _app(
          Center(
            child: GhAccountMenu(
              trigger: (context, open, toggle) => TextButton(onPressed: toggle, child: Text(open ? 'open' : 'closed')),
              onNavigate: (id) => calls.add('nav:$id'),
              userName: 'ryko',
              githubUsername: 'octo',
              gitlabUsername: 'lab',
              hasNewChangelog: true,
              onOpenChange: (v) => opened = [...opened, v],
              onManageAccounts: () => calls.add('manage'),
              onReportBug: () => calls.add('bug'),
              workspaceItem: ghWorkspaceMenuItem(
                workspaces: _workspaces,
                activeId: 'b',
                onSwitch: (id) => calls.add('switch:$id'),
                onEdit: (id) => calls.add('edit:$id'),
                onCreate: () => calls.add('create'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('closed'));
      await tester.pumpAndSettle();
      expect(opened, [true]);
      expect(find.text('ryko'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('@octo'), findsOneWidget);
      expect(find.text('@lab'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text(t.common.new_badge), findsOneWidget);
      expect(find.text(t.common.report_a_bug), findsOneWidget);
      await tester.tap(find.text(t.nav.account_manage));
      await tester.pumpAndSettle();
      expect(calls, ['manage']);
      expect(find.text('ryko'), findsNothing);
      await tester.tap(find.text('closed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.report_a_bug));
      await tester.pumpAndSettle();
      expect(calls, ['manage', 'bug']);
    });

    testWidgets('falls back to You and hides the accounts box', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: GhAccountMenu(
              trigger: (context, open, toggle) => TextButton(onPressed: toggle, child: const Text('trigger')),
              onNavigate: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();
      expect(find.text(t.nav.you), findsOneWidget);
      expect(find.text(t.nav.account_manage), findsNothing);
      expect(find.text(t.common.new_badge), findsNothing);
    });
  });

  group('GhWorkspaceForm', () {
    testWidgets('edits name, icon and color and shows errors', (tester) async {
      var draft = const GhWorkspaceDraft(name: '', icon: 'briefcase', color: '#457ff2');
      var submitted = 0;
      var blurred = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: GhWorkspaceForm(
                    value: draft,
                    onChanged: (next) => setState(() => draft = next),
                    takenNames: const ['Work'],
                    showErrors: true,
                    onSubmit: () => submitted++,
                    onNameBlur: () => blurred++,
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(find.text(t.common.workspace_name_required_error), findsOneWidget);
      expect(find.text(t.common.workspace_name_placeholder), findsNWidgets(2));
      expect(find.text(t.common.section_workspaces.toUpperCase()), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'work');
      await tester.pump();
      expect(draft.name, 'work');
      expect(find.text(t.common.workspace_name_taken_error), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Jam');
      await tester.pump();
      expect(find.text(t.common.workspace_name_taken_error), findsNothing);
      expect(find.text('Jam'), findsNWidgets(2));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 1);
      await tester.tap(find.bySemanticsLabel('graduation cap'));
      await tester.pump();
      expect(draft.icon, 'graduation_cap');
      expect(blurred, 0);
      await tester.tap(find.bySemanticsLabel('#eb459e'));
      await tester.pump();
      expect(draft.color, '#eb459e');
      rebuild(() => draft = draft.copyWith(name: 'Renamed'));
      await tester.pump();
      expect(find.text('Renamed'), findsNWidgets(2));
    });

    testWidgets('hides errors until requested', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 520,
            child: GhWorkspaceForm(
              value: const GhWorkspaceDraft(name: '', icon: 'rocket', color: '#23a55a'),
              onChanged: (_) {},
              takenNames: const [],
              showErrors: false,
            ),
          ),
        ),
      );
      expect(find.text(t.common.workspace_name_required_error), findsNothing);
    });
  });

  group('GhColorSwatchPicker', () {
    testWidgets('opens, picks presets and accepts hex input', (tester) async {
      var value = '#457ff2';
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.topLeft,
              child: GhColorSwatchPicker(
                label: 'Accent',
                value: value,
                onChanged: (hex) => setState(() => value = hex),
                presets: workspaceColorPresets,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Accent'), findsOneWidget);
      await tester.tap(find.text('#457ff2'));
      await tester.pumpAndSettle();
      expect(find.text(t.common.color_presets.toUpperCase()), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('#eb459e'));
      await tester.pumpAndSettle();
      expect(value, '#eb459e');
      final hexField = find.byType(TextField);
      expect(tester.widget<TextField>(hexField).controller!.text, '#eb459e');
      await tester.enterText(hexField, '23a55a');
      await tester.pump();
      expect(value, '#23a55a');
      expect(tester.widget<TextField>(hexField).controller!.text, '#23a55a');
      await tester.enterText(hexField, '#12');
      await tester.pump();
      expect(value, '#23a55a');
    });
  });

  group('reusables', () {
    testWidgets('disclosure animates open and closed', (tester) async {
      var open = true;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                children: [
                  GhDisclosure(open: open, child: const Text('inside')),
                  const Text('after'),
                ],
              );
            },
          ),
        ),
      );
      final full = tester.getTopLeft(find.text('after')).dy;
      rebuild(() => open = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getTopLeft(find.text('after')).dy;
      expect(mid, lessThan(full));
      await tester.pumpAndSettle();
      expect(find.text('inside'), findsNothing);
      expect(tester.getTopLeft(find.text('after')).dy, 0);
      rebuild(() => open = true);
      await tester.pumpAndSettle();
      expect(find.text('inside'), findsOneWidget);
      expect(tester.getTopLeft(find.text('after')).dy, full);
    });

    testWidgets('overlay scroll area shows the scroll-to-top button', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: GhOverlayScrollArea(
              controller: controller,
              child: Column(children: [for (var i = 0; i < 60; i++) SizedBox(height: 30, child: Text('Row $i'))]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.common.scroll_to_top), findsNothing);
      controller.jumpTo(400);
      await tester.pumpAndSettle();
      expect(find.text(t.common.scroll_to_top), findsOneWidget);
      await tester.tap(find.text(t.common.scroll_to_top));
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
      expect(find.text(t.common.scroll_to_top), findsNothing);
    });

    testWidgets('scroll area thumb drags the viewport', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 300,
              child: GhOverlayScrollArea(
                controller: controller,
                hideTopButton: true,
                child: Column(children: [for (var i = 0; i < 60; i++) const SizedBox(height: 30)]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(195, 20));
      await gesture.moveBy(const Offset(0, 100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
    });
  });

  testWidgets('gallery sections build', (tester) async {
    tester.view.physicalSize = const Size(2400, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final section in shellSections) {
      await tester.pumpWidget(_app(SingleChildScrollView(child: Builder(builder: section.builder))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: section.title);
    }
  });
}
