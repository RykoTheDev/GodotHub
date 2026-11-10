import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/motion/ease.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/motion/reveal.dart';
import 'package:godothub/motion/tween.dart';

const _speed1 = GhMotionPrefs(speed: 1);

Widget _host(Widget child, {GhMotionPrefs prefs = _speed1, bool reduced = false}) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: GhMotion(
      prefs: prefs,
      osReduced: reduced,
      child: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
    ),
  );
}

Widget _box(int i, {double height = 40}) => SizedBox(key: ValueKey('box$i'), width: 200, height: height);

Finder _item(int i) =>
    find.ancestor(of: find.byKey(ValueKey('box$i'), skipOffstage: false), matching: find.byType(GhReveal, skipOffstage: false));

bool _hidden(WidgetTester tester, int i) => find
    .descendant(of: _item(i), matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0, skipOffstage: false), skipOffstage: false)
    .evaluate()
    .isNotEmpty;

bool _playing(WidgetTester tester, int i) =>
    find.descendant(of: _item(i), matching: find.byType(GhPoseTransition, skipOffstage: false), skipOffstage: false).evaluate().isNotEmpty;

bool _settled(WidgetTester tester, int i) => !_hidden(tester, i) && !_playing(tester, i);

GhPose _from(WidgetTester tester, int i) =>
    tester
        .widget<GhPoseTransition>(find.descendant(of: _item(i), matching: find.byType(GhPoseTransition, skipOffstage: false), skipOffstage: false))
        .from;

void main() {
  setUp(GhLiveReveal.reset);

  group('spec', () {
    test('slide entrance moves, scales and blurs', () {
      final spec = ghRevealSpec();
      expect(spec.from, const GhPose(opacity: 0, y: 26, scale: 0.96, blur: 4));
      expect(spec.duration, 0.75);
      expect(spec.ease, GhEase.out);
      expect(ghRevealSpec(fromScroll: true).from.y, 40);
      expect(ghRevealSpec(blur: false).from.blur, 0);
      expect(ghRevealSpec(blurAllowed: false).from.blur, 0);
    });

    test('tiles pop with a relative rotation', () {
      final spec = ghRevealSpec(kind: GhRevealKind.tile);
      expect(spec.from, const GhPose(opacity: 0, scale: 0.3, rotation: -16));
      expect(spec.duration, 0.85);
      expect(spec.ease, GhEase.pop);
    });

    test('headings clip up on slide, otherwise scale', () {
      expect(ghRevealSpec(kind: GhRevealKind.heading).from, const GhPose(opacity: 0, y: 20, clipBottom: 1));
      expect(ghRevealSpec(kind: GhRevealKind.heading, entrance: GhViewEntrance.scale).from, const GhPose(opacity: 0, scale: 0.96));
    });

    test('scale entrance springs, fade entrance only fades', () {
      final scale = ghRevealSpec(entrance: GhViewEntrance.scale);
      expect(scale.from, const GhPose(opacity: 0, scale: 0.92));
      expect(scale.ease, GhEase.spring);
      expect(ghRevealSpec(entrance: GhViewEntrance.fade).from, const GhPose(opacity: 0));
      expect(ghRevealSpec(kind: GhRevealKind.fade).from, const GhPose(opacity: 0));
      expect(ghRevealSpec(kind: GhRevealKind.tile, entrance: GhViewEntrance.fade).from, const GhPose(opacity: 0));
    });

    test('own opacity and locked transforms', () {
      expect(ghRevealSpec(ownOpacity: true).from.opacity, 1);
      expect(ghRevealSpec(canTransform: false).from, const GhPose(opacity: 0));
    });

    test('delays', () {
      expect(ghRevealDelay(0, base: 0.05), 0.05);
      expect(ghRevealDelay(4), closeTo(0.14, 1e-12));
      expect(ghRevealDelay(40, base: 0.05), closeTo(0.85, 1e-12));
      expect(ghScrollRevealDelay(3), closeTo(0.18, 1e-12));
      expect(ghScrollRevealDelay(20), 0.5);
      expect(ghRevealMaxBatch, 120);
      expect(ghRevealBlurLimit, 24);
    });
  });

  testWidgets('view reveal fades the pane and staggers items in the viewport', (tester) async {
    await tester.pumpWidget(_host(GhRevealScope(
      child: Column(children: [for (var i = 0; i < 3; i++) GhReveal(child: _box(i))]),
    )));
    expect(_hidden(tester, 0), isTrue);
    final pane = tester.widget<FadeTransition>(find.descendant(of: find.byType(GhRevealScope), matching: find.byType(FadeTransition)).first);
    expect(pane.opacity.value, 0);
    await tester.pump();
    expect(_playing(tester, 0), isTrue);
    expect(_from(tester, 0), const GhPose(opacity: 0, y: 26, scale: 0.96, blur: 4));
    await tester.pump(const Duration(milliseconds: 450));
    expect(pane.opacity.value, 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_settled(tester, 0), isTrue);
    expect(_playing(tester, 2), isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_settled(tester, 2), isTrue);
  });

  testWidgets('Linux reveals skip the blur', (tester) async {
    await tester.pumpWidget(_host(GhRevealScope(child: GhReveal(child: _box(0)))));
    await tester.pump();
    expect(_from(tester, 0), const GhPose(opacity: 0, y: 26, scale: 0.96));
    await tester.pump(const Duration(seconds: 1));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('entrance none and motion off show items at once', (tester) async {
    await tester.pumpWidget(_host(
      GhRevealScope(child: GhReveal(child: _box(0))),
      prefs: _speed1.copyWith(entrance: GhViewEntrance.none),
    ));
    expect(_settled(tester, 0), isTrue);
    await tester.pumpWidget(_host(GhRevealScope(key: const ValueKey('b'), child: GhReveal(child: _box(0))), reduced: true));
    await tester.pump();
    expect(_settled(tester, 0), isTrue);
  });

  testWidgets('off-screen items wait for scroll and then reveal from scroll', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(_host(SizedBox(
      height: 200,
      width: 200,
      child: GhRevealScope(
        child: ListView(
          controller: controller,
          children: [for (var i = 0; i < 6; i++) GhReveal(child: _box(i, height: 100))],
        ),
      ),
    )));
    await tester.pump();
    expect(_playing(tester, 0), isTrue);
    expect(_playing(tester, 1), isTrue);
    expect(_hidden(tester, 2), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(_settled(tester, 0), isTrue);
    expect(_hidden(tester, 2), isTrue);
    controller.jumpTo(150);
    await tester.pump();
    await tester.pump();
    expect(_playing(tester, 2), isTrue);
    expect(_from(tester, 2).y, 40);
    await tester.pump(const Duration(seconds: 2));
    expect(_settled(tester, 2), isTrue);
  });

  testWidgets('without scroll reveal off-screen items are shown, and turning it off flushes', (tester) async {
    Widget build(GhMotionPrefs prefs) => _host(
          SizedBox(
            height: 200,
            width: 200,
            child: GhRevealScope(
              child: ListView(children: [for (var i = 0; i < 6; i++) GhReveal(child: _box(i, height: 100))]),
            ),
          ),
          prefs: prefs,
        );
    await tester.pumpWidget(build(_speed1));
    await tester.pump();
    expect(_hidden(tester, 2), isTrue);
    await tester.pumpWidget(build(_speed1.copyWith(scrollReveal: false)));
    await tester.pump();
    expect(_settled(tester, 2), isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('scroll reveal off from the start leaves off-screen items untouched', (tester) async {
    await tester.pumpWidget(_host(
      SizedBox(
        height: 200,
        width: 200,
        child: GhRevealScope(
          child: ListView(children: [for (var i = 0; i < 6; i++) GhReveal(child: _box(i, height: 100))]),
        ),
      ),
      prefs: _speed1.copyWith(scrollReveal: false),
    ));
    await tester.pump();
    expect(_playing(tester, 0), isTrue);
    expect(_settled(tester, 2), isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('more project items than the threshold do not animate', (tester) async {
    await tester.pumpWidget(_host(
      GhRevealScope(
        child: Column(children: [
          for (var i = 0; i < 3; i++) GhReveal(projectId: 'p$i', child: _box(i, height: 20)),
          GhRevealProject(id: 'p0', child: GhReveal(child: _box(3, height: 20))),
          GhReveal(child: _box(4, height: 20)),
        ]),
      ),
      prefs: _speed1.copyWith(threshold: 2),
    ));
    await tester.pump();
    expect(_settled(tester, 0), isTrue);
    expect(_settled(tester, 3), isTrue);
    expect(_playing(tester, 4), isTrue);
    await tester.pump(const Duration(seconds: 2));

    await tester.pumpWidget(_host(
      GhRevealScope(
        key: const ValueKey('under'),
        child: Column(children: [for (var i = 0; i < 3; i++) GhReveal(projectId: 'p${i % 2}', child: _box(i, height: 20))]),
      ),
      prefs: _speed1.copyWith(threshold: 2),
    ));
    await tester.pump();
    expect(_playing(tester, 0), isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('items with their own opacity keep it', (tester) async {
    await tester.pumpWidget(_host(GhRevealScope(child: GhReveal(ownOpacity: true, child: _box(0)))));
    expect(_hidden(tester, 0), isFalse);
    await tester.pump();
    expect(_from(tester, 0).opacity, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('live reveal animates new items only once enabled and while no pointer is held', (tester) async {
    Widget build(int count) => _host(GhRevealScope(
          child: Column(children: [for (var i = 0; i < count; i++) GhReveal(key: ValueKey(i), child: _box(i, height: 20))]),
        ));
    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(build(2));
    expect(_settled(tester, 1), isTrue);
    await tester.pump();
    expect(_settled(tester, 1), isTrue);

    GhLiveReveal.enable();
    await tester.pumpWidget(build(3));
    expect(_hidden(tester, 2), isTrue);
    await tester.pump();
    expect(_playing(tester, 2), isTrue);
    expect(_from(tester, 2).y, 26);
    await tester.pump(const Duration(seconds: 2));

    final gesture = await tester.startGesture(const Offset(600, 500));
    expect(GhLiveReveal.pointerHeld, isTrue);
    await tester.pumpWidget(build(4));
    await tester.pump();
    expect(_settled(tester, 3), isTrue);
    await gesture.up();
    expect(GhLiveReveal.pointerHeld, isFalse);
  });

  testWidgets('remounted items with an id are not revealed twice', (tester) async {
    GhLiveReveal.enable();
    Widget build(bool show) => _host(GhRevealScope(
          child: Column(children: [GhReveal(id: 'a', child: _box(0, height: 20)), if (show) GhReveal(id: 'b', child: _box(1, height: 20))]),
        ));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(build(false));
    await tester.pumpWidget(build(true));
    expect(_settled(tester, 1), isTrue);
    await tester.pump();
    expect(_settled(tester, 1), isTrue);
  });

  testWidgets('replay and activation rerun the view reveal', (tester) async {
    Widget build(bool active, int replay) => _host(GhRevealScope(
          active: active,
          replay: replay,
          child: GhReveal(child: _box(0)),
        ));
    await tester.pumpWidget(build(false, 0));
    await tester.pump();
    expect(_settled(tester, 0), isTrue);
    await tester.pumpWidget(build(true, 0));
    await tester.pump();
    expect(_playing(tester, 0), isTrue);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(build(true, 1));
    await tester.pump();
    expect(_playing(tester, 0), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(_settled(tester, 0), isTrue);
  });

  testWidgets('child state survives the reveal', (tester) async {
    await tester.pumpWidget(_host(GhRevealScope(child: GhReveal(child: const _Counter()))));
    await tester.pump(const Duration(seconds: 2));
    expect(_CounterState.created, 1);
    _CounterState.created = 0;
  });

  testWidgets('skip regions and missing scopes render children directly', (tester) async {
    await tester.pumpWidget(_host(Column(children: [
      GhReveal(child: _box(0, height: 10)),
      GhRevealScope(child: GhRevealSkip(child: GhReveal(child: _box(1, height: 10)))),
    ])));
    await tester.pump();
    expect(_settled(tester, 0), isTrue);
    expect(_settled(tester, 1), isTrue);
    await tester.pump(const Duration(seconds: 1));
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  static int created = 0;

  @override
  void initState() {
    super.initState();
    created += 1;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
}
