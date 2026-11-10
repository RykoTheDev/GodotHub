import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/debug/gallery/sections/motion_presence.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/motion/ease.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/motion/presence.dart';
import 'package:godothub/motion/shared.dart';
import 'package:godothub/motion/tween.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/ui/core/tooltip.dart';
import 'package:godothub/ui/core/ui_settings.dart';
import 'package:godothub/ui/feedback/feedback.dart';
import 'package:godothub/ui/overlays/dropdown.dart';
import 'package:godothub/ui/overlays/menu.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';
import 'package:godothub/ui/shell/disclosure.dart';
import 'package:godothub/ui/shell/sidebar.dart';

const _unit = GhMotionPrefs(speed: 1);

Widget _host(
  Widget child, {
  GhMotionPrefs prefs = _unit,
  bool reduced = false,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: GhMotion(
      prefs: prefs,
      osReduced: reduced,
      child: Directionality(
        textDirection: direction,
        child: Scaffold(body: child),
      ),
    ),
  );
}

GhPose _layerPose(WidgetTester tester, Finder of) =>
    tester.widget<GhPoseView>(find.descendant(of: of, matching: find.byType(GhPoseView)).first).pose;

GhPose _itemPose(WidgetTester tester, Key key) =>
    tester.widget<GhPoseView>(find.descendant(of: find.byKey(key), matching: find.byType(GhPoseView)).first).pose;

GhPose _wrapperPose(WidgetTester tester, Key key) =>
    tester.widget<GhPoseView>(find.ancestor(of: find.byKey(key), matching: find.byType(GhPoseView)).first).pose;

class _Toggle extends StatefulWidget {
  const _Toggle({super.key, required this.builder});

  final Widget Function(bool visible, VoidCallback onExited) builder;

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool visible = true;
  int exited = 0;

  void hide() => setState(() => visible = false);

  @override
  Widget build(BuildContext context) => widget.builder(visible, () => exited++);
}

void main() {
  tearDown(() {
    GhPopupRegistry.debugReset();
    GhSharedElements.debugReset();
  });

  test('specs mirror the GSAP presence values', () {
    final modal = GhPresenceSpecs.modal;
    expect(modal.enterLength, closeTo(0.47, 1e-12));
    expect(modal.exitLength, closeTo(0.24, 1e-12));
    expect(GhPresenceSpecs.modalParts.amountFor(3), closeTo(0.06, 1e-12));
    expect(GhPresenceSpecs.modalParts.amountFor(10), 0.12);
    expect(GhPresenceSpecs.modalParts.startOf(2, 3), closeTo(0.11, 1e-12));
    expect(GhPresenceSpecs.popover.layer.enter!.from.y, -6);
    expect(GhPresenceSpecs.popoverUp.layer.enter!.from.y, 6);
    expect(GhPresenceSpecs.popoverItems.amountFor(4), closeTo(0.06, 1e-12));
    expect(GhPresenceSpecs.popoverItems.poseAt(16, 20, 0), GhPose.identity);
    expect(GhPresenceSpecs.toast.exitWhenOff, isTrue);
    expect(GhPresenceSpecs.toast.layer.enter!.from.mirrored(true).x, -110);
    expect(
      GhPresenceSpecs.panel.layer.exit!.to.applyTo(const GhPose(y: 3)),
      const GhPose(y: 3, opacity: 0.3, xPercent: 110),
    );
    expect(ghTooltipOrigin(GhSide.top), Alignment.bottomCenter);
    expect(ghTooltipOrigin(GhSide.right), Alignment.centerLeft);
  });

  testWidgets('a popover enters, stays mounted through its exit and reports when it is gone', (tester) async {
    final key = GlobalKey<_ToggleState>();
    await tester.pumpWidget(
      _host(
        _Toggle(
          key: key,
          builder: (visible, onExited) =>
              GhPresence(visible: visible, kind: GhPresenceKind.popover, onExited: onExited, child: const Text('Menu')),
        ),
      ),
    );
    final presence = find.byType(GhPresence);
    expect(_layerPose(tester, presence).opacity, 0);
    expect(_layerPose(tester, presence).y, -6);
    await tester.pump(const Duration(milliseconds: 140));
    final half = GhEase.out.transform(0.5);
    expect(_layerPose(tester, presence).opacity, closeTo(half, 0.02));
    await tester.pumpAndSettle();
    expect(_layerPose(tester, presence), GhPose.identity);

    key.currentState!.hide();
    await tester.pump();
    expect(find.text('Menu'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 75));
    expect(_layerPose(tester, presence).opacity, closeTo(1 - GhEase.easeIn.transform(0.5), 0.03));
    expect(key.currentState!.exited, 0);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Menu'), findsNothing);
    expect(key.currentState!.exited, 1);
  });

  testWidgets('an exit that interrupts the enter starts from the current pose', (tester) async {
    final key = GlobalKey<_ToggleState>();
    await tester.pumpWidget(
      _host(
        _Toggle(
          key: key,
          builder: (visible, onExited) =>
              GhPresence(visible: visible, kind: GhPresenceKind.tooltip, child: const Text('Tip')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final before = _layerPose(tester, find.byType(GhPresence)).scale;
    expect(before, closeTo(0.78 + 0.22 * GhEase.pop.transform(0.3125), 0.02));
    key.currentState!.hide();
    await tester.pump();
    expect(_layerPose(tester, find.byType(GhPresence)).scale, closeTo(before, 0.02));
    await tester.pumpAndSettle();
    expect(find.text('Tip'), findsNothing);
  });

  testWidgets('motion off skips presence enter and exit', (tester) async {
    final key = GlobalKey<_ToggleState>();
    await tester.pumpWidget(
      _host(
        _Toggle(
          key: key,
          builder: (visible, onExited) =>
              GhPresence(visible: visible, kind: GhPresenceKind.modal, onExited: onExited, child: const Text('Body')),
        ),
        reduced: true,
      ),
    );
    expect(_layerPose(tester, find.byType(GhPresence)), GhPose.identity);
    key.currentState!.hide();
    await tester.pump();
    await tester.pump();
    expect(find.text('Body'), findsNothing);
    expect(key.currentState!.exited, 1);
  });

  testWidgets('cascade items stagger by registration order and mirror in RTL', (tester) async {
    const keys = [Key('a'), Key('b'), Key('c')];
    await tester.pumpWidget(
      _host(
        GhPresence(
          visible: true,
          kind: GhPresenceKind.popover,
          child: Column(
            children: [
              for (final key in keys)
                GhCascadeItem(key: key, role: GhCascadeRole.menuItem, child: const SizedBox(height: 10)),
            ],
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    expect(_itemPose(tester, keys[0]).x, 6);
    await tester.pump(const Duration(milliseconds: 64));
    expect(_itemPose(tester, keys[0]).opacity, greaterThan(_itemPose(tester, keys[1]).opacity));
    expect(_itemPose(tester, keys[1]).opacity, greaterThan(0));
    expect(_itemPose(tester, keys[2]).opacity, 0);
    await tester.pumpAndSettle();
    expect(_itemPose(tester, keys[2]), GhPose.identity);
  });

  testWidgets('modal route animates overlay and panel, and closes logically on pop', (tester) async {
    late BuildContext host;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            host = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    GhModalEvents.openDialogs.value = 0;
    showGhModal<void>(
      host,
      (context) => GhModalShell(
        icon: const SizedBox.shrink(),
        title: 'Title',
        onClose: () => Navigator.of(context).pop(),
        footer: [
          const Spacer(),
          GhButtonStub(key: const Key('footer')),
        ],
        child: const Text('Body'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final panel = find.byType(GhPresenceLayerView);
    final overlay = _layerPose(tester, panel.first);
    expect(overlay.opacity, closeTo(GhEase.soft.transform(0.5), 0.03));
    final dialog = _layerPose(tester, panel.last);
    expect(dialog.y, closeTo(18 * (1 - GhEase.out.transform(100 / 360)), 0.3));
    expect(_wrapperPose(tester, const Key('footer')).y, greaterThan(0));
    await tester.pumpAndSettle();
    expect(GhModalEvents.openDialogs.value, 1);

    Navigator.of(host).pop();
    await tester.pump();
    expect(GhModalEvents.openDialogs.value, 0);
    expect(find.text('Body'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 120));
    expect(_layerPose(tester, panel.first).opacity, closeTo(1 - GsapEase('power2.out').transform(0.1 / 0.22), 0.03));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('dropdown closes logically at once and unmounts after the exit', (tester) async {
    await tester.pumpWidget(
      _host(
        Center(
          child: GhDropdown(
            trigger: (context, open, toggle) => TextButton(onPressed: toggle, child: const Text('Open')),
            items: const [
              GhMenuItem(id: 'a', label: 'Alpha'),
              GhMenuItem(id: 'b', label: 'Beta'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(GhPopupRegistry.openMenuCount.value, 1);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(GhPopupRegistry.openMenuCount.value, 0);
    expect(find.text('Alpha'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('tooltip grows from its side and leaves with a short exit', (tester) async {
    await tester.pumpWidget(
      _host(
        const Center(
          child: GhTooltip(
            message: 'Hint',
            side: GhSide.top,
            delay: Duration.zero,
            child: SizedBox(width: 40, height: 20),
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(GhTooltip)));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    final presence = tester.widget<GhPresence>(find.byType(GhPresence));
    expect(presence.origin, Alignment.bottomCenter);
    await tester.pumpAndSettle();
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    expect(find.text('Hint'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Hint'), findsNothing);
    await gesture.removePointer();
  });

  testWidgets('toasts slide in and collapse out', (tester) async {
    final store = GhToastStore();
    await tester.pumpWidget(_host(GhToastHost(store: store, child: const SizedBox.expand())));
    final id = store.pushToast(GhToastType.info, 'Hello');
    await tester.pump();
    final presence = find.byType(GhPresence);
    expect(_layerPose(tester, presence), const GhPose(opacity: 0, x: 110, scale: 0.8, rotation: 8));
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byType(GhToastCard)).height;
    store.dismissToast(id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final collapse = GsapEase('power3.in').transform(300 / 450);
    expect(tester.getSize(find.byType(GhToastCard)).height, lessThan(height * (1 - collapse) + 3));
    expect(_layerPose(tester, presence).x, closeTo(80 * collapse, 0.5));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('toast leave still runs when motion is off', (tester) async {
    final store = GhToastStore();
    await tester.pumpWidget(_host(GhToastHost(store: store, child: const SizedBox.expand()), reduced: true));
    final id = store.pushToast(GhToastType.info, 'Quiet');
    await tester.pump();
    expect(_layerPose(tester, find.byType(GhPresence)), GhPose.identity);
    store.dismissToast(id);
    await tester.pump();
    expect(find.text('Quiet'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 12));
    await tester.pump();
    expect(find.text('Quiet'), findsNothing);
  });

  testWidgets('shared element flips from the rect measured on pointer down', (tester) async {
    const tag = 'pill';
    var left = 0.0;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: 100,
                  width: 80,
                  height: 30,
                  child: GhShared(
                    key: ValueKey(left),
                    tag: tag,
                    child: const SizedBox.expand(key: Key('pill')),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 300,
                  child: GhSharedIcon(
                    tag: tag,
                    child: const SizedBox(key: Key('icon'), width: 10, height: 10),
                  ),
                ),
                Positioned(
                  left: 400,
                  top: 400,
                  child: TextButton(onPressed: () {}, child: const Text('Go')),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    update(() => left = 200);
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const Key('pill'))).dx, closeTo(0, 0.5));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 300));
    final dx = tester.getTopLeft(find.byKey(const Key('pill'))).dx;
    expect(dx, closeTo(200 * GhEase.out.transform(300 / 600), 6));
    expect(_wrapperPose(tester, const Key('icon')).scale, isNot(1));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('pill'))).dx, 200);
    expect(GhSharedElements.rectOf(tag)!.left, 200);
  });

  testWidgets('disclosure staggers its items when opened from closed', (tester) async {
    const keys = [Key('one'), Key('two')];
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return GhDisclosure(
              open: open,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [for (final key in keys) GhDisclosureItem(key: key, child: const SizedBox(height: 20))],
              ),
            );
          },
        ),
      ),
    );
    update(() => open = true);
    await tester.pump();
    expect(_itemPose(tester, keys[0]).y, -6);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_itemPose(tester, keys[0]).opacity, greaterThan(_itemPose(tester, keys[1]).opacity));
    await tester.pumpAndSettle();
    expect(_itemPose(tester, keys[1]), GhPose.identity);
  });

  testWidgets('image fade waits for the first frame and skips cached images', (tester) async {
    Widget build(int? frame, {bool cached = false}) => _host(
      GhImageFadeIn(
        frame: frame,
        cached: cached,
        child: const SizedBox(key: Key('img'), width: 10, height: 10),
      ),
    );
    await tester.pumpWidget(build(null));
    expect(_wrapperPose(tester, const Key('img')).opacity, 0);
    await tester.pumpWidget(build(0));
    await tester.pump(const Duration(milliseconds: 350));
    final pose = tester.widget<GhPoseView>(find.byType(GhPoseView)).pose;
    expect(pose.opacity, closeTo(GhEase.out.transform(0.5), 0.02));
    expect(pose.blur, closeTo(8 * (1 - GhEase.out.transform(0.5)), 0.2));
    await tester.pumpWidget(_host(const SizedBox()));
    await tester.pumpWidget(build(0, cached: true));
    expect(tester.widget<GhPoseView>(find.byType(GhPoseView)).pose, GhPose.identity);
  });

  testWidgets('workspace switch notice holds then leaves, and hides after 1.5 s with motion off', (tester) async {
    const workspaces = [
      GhWorkspaceRef(id: 'a', name: 'Alpha', icon: 'house'),
      GhWorkspaceRef(id: 'b', name: 'Beta', icon: 'rocket'),
    ];
    Widget build(String id, {bool reduced = false}) => _host(
      GhWorkspaceSwitchNotice(activeId: id, workspaces: workspaces),
      reduced: reduced,
    );
    await tester.pumpWidget(build('a'));
    await tester.pumpWidget(build('b'));
    expect(tester.widget<GhPoseView>(find.byType(GhPoseView)).pose, GhWorkspaceSwitchNotice.enterFrom);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.widget<GhPoseView>(find.byType(GhPoseView)).pose, GhPose.identity);
    await tester.pump(const Duration(milliseconds: 820));
    await tester.pump();
    expect(find.text('Beta'), findsNothing);

    await tester.pumpWidget(build('a', reduced: true));
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.text('Alpha'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('sidebar pill morphs to the new tab and labels stagger in on expand', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const tabs = [
      GhSidebarTab(id: 'one', label: 'First', icon: GhIcons.folder),
      GhSidebarTab(id: 'two', label: 'Second', icon: GhIcons.news),
      GhSidebarTab(id: 'three', label: 'Third', icon: GhIcons.book),
    ];
    var active = 'one';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GhSidebar(tabs: tabs, activeTab: active, onTabChange: (id) => setState(() => active = id)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Finder pill() => find.descendant(of: find.byType(GhShared), matching: find.byType(DecoratedBox));
    final from = tester.getTopLeft(pill());
    await tester.tap(find.text('Third'));
    await tester.pump();
    expect(tester.getTopLeft(pill()).dy, closeTo(from.dy, 0.5));
    await tester.pumpAndSettle();
    final to = tester.getTopLeft(pill());
    expect(to.dy, greaterThan(from.dy + 40));

    await tester.tap(find.byWidgetPredicate((w) => w is GhTooltip && w.message == t.common.collapse_sidebar));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(600, 300));
    await mouse.moveTo(const Offset(30, 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w is GhTooltip && w.message == t.common.expand_sidebar));
    await tester.pump();
    final label = tester
        .widget<GhPoseView>(find.ancestor(of: find.text('First'), matching: find.byType(GhPoseView)).first)
        .pose;
    expect(label.opacity, 0);
    expect(label.x, -10);
    await tester.pumpAndSettle();
    expect(
      tester.widget<GhPoseView>(find.ancestor(of: find.text('First'), matching: find.byType(GhPoseView)).first).pose,
      GhPose.identity,
    );
    await mouse.removePointer();
  });

  testWidgets('presence gallery sections build', (tester) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final section in motionPresenceSections) {
      await tester.pumpWidget(_host(SingleChildScrollView(child: Builder(builder: section.builder))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: section.title);
    }
  });
}

class GhButtonStub extends StatelessWidget {
  const GhButtonStub({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(width: 40, height: 20);
}
