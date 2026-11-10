import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/motion/intro.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/motion/reveal.dart';
import 'package:godothub/motion/tween.dart';
import 'package:godothub/src/ui_transition.dart';
import 'package:godothub/ui/core/interaction.dart';
import 'package:godothub/ui/splash/splash_screen.dart';

const _speed1 = GhMotionPrefs(speed: 1);

Widget _host(Widget child, {GhMotionPrefs prefs = _speed1, bool reduced = false, TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: GhMotion(
      prefs: prefs,
      osReduced: reduced,
      child: Directionality(textDirection: direction, child: Scaffold(body: child)),
    ),
  );
}

Widget _shell({int buttons = 35, int parts = 2, Object? replay, VoidCallback? onDone}) {
  return GhShellIntro(
    replay: replay,
    onDone: onDone,
    child: Column(
      children: [
        GhIntroTitleBar(
          child: SizedBox(
            key: const ValueKey('titlebar'),
            height: 32,
            child: Row(children: [for (var i = 0; i < parts; i++) GhIntroPart(child: SizedBox(key: ValueKey('part$i'), width: 40))]),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              GhIntroSidebar(
                child: SizedBox(
                  key: const ValueKey('sidebar'),
                  width: 120,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < buttons; i++)
                          GhPressable(
                            onPressed: () {},
                            builder: (context, states) => SizedBox(key: ValueKey('button$i'), width: 100, height: 10),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

GhPoseTransition? _transitionAbove(WidgetTester tester, String key) {
  final finder = find.ancestor(of: find.byKey(ValueKey(key), skipOffstage: false), matching: find.byType(GhPoseTransition, skipOffstage: false));
  if (finder.evaluate().isEmpty) {
    return null;
  }
  return tester.widget<GhPoseTransition>(finder.first);
}

double _value(WidgetTester tester, String key) {
  final transition = _transitionAbove(tester, key)!;
  return (transition.listenable as Animation<double>).value;
}

void main() {
  setUp(() {
    GhLiveReveal.reset();
    GhUiTransition.reset();
  });

  test('timing matches the GSAP timeline', () {
    expect(GhShellIntroTiming.titleBar.startAt(0), 0.15);
    expect(GhShellIntroTiming.titleBar.endAt(0), closeTo(0.95, 1e-12));
    expect(GhShellIntroTiming.part.startAt(2), closeTo(0.42, 1e-12));
    expect(GhShellIntroTiming.sidebar.startAt(0), closeTo(0.2, 1e-12));
    expect(GhShellIntroTiming.sidebar.endAt(0), closeTo(1.1, 1e-12));
    expect(GhShellIntroTiming.item.startAt(29), closeTo(1.22, 1e-12));
    expect(GhShellIntroTiming.item.from, const GhPose(x: -20, opacity: 0));
    expect(GhShellIntroTiming.maxItems, 30);
  });

  testWidgets('title bar, parts, sidebar and the first 30 sidebar buttons register and play in order', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(_shell(onDone: () => done += 1)));
    final state = tester.state<GhShellIntroState>(find.byType(GhShellIntro));
    expect(state.count(GhIntroRole.titleBar), 1);
    expect(state.count(GhIntroRole.part), 2);
    expect(state.count(GhIntroRole.sidebar), 1);
    expect(state.count(GhIntroRole.item), 30);
    expect(_transitionAbove(tester, 'button29'), isNotNull);
    expect(_transitionAbove(tester, 'titlebar')!.from, const GhPose(y: -40, opacity: 0));
    expect(_value(tester, 'titlebar'), 0);
    expect(GhLiveReveal.live, isFalse);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_value(tester, 'titlebar'), 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_value(tester, 'titlebar'), greaterThan(0.5));
    expect(_value(tester, 'button0'), greaterThan(0));
    expect(_value(tester, 'button20'), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(done, 1);
    expect(GhLiveReveal.live, isTrue);
    expect(state.done, isTrue);
    expect(_value(tester, 'button29'), 1);
  });

  testWidgets('parts animate inside the title bar, which is itself animating', (tester) async {
    await tester.pumpWidget(_host(_shell(parts: 3)));
    final part = find.ancestor(of: find.byKey(const ValueKey('part1')), matching: find.byType(GhPoseTransition));
    expect(part, findsNWidgets(2));
    expect(tester.widget<GhPoseTransition>(part.first).from, const GhPose(y: -14, opacity: 0));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('sidebar slides from the end side in RTL', (tester) async {
    await tester.pumpWidget(_host(_shell(), direction: TextDirection.rtl));
    expect(_transitionAbove(tester, 'sidebar')!.from, const GhPose(x: 60, opacity: 0));
    expect(_transitionAbove(tester, 'button0')!.from.x, 20);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('motion off only enables live reveal', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(_shell(onDone: () => done += 1), reduced: true));
    expect(GhLiveReveal.live, isTrue);
    expect(done, 1);
    expect(_transitionAbove(tester, 'titlebar'), isNull);
    expect(_transitionAbove(tester, 'button0'), isNull);
  });

  testWidgets('the onboarding hand-off skips the intro once', (tester) async {
    GhUiTransition.handOffShellIntro();
    await tester.pumpWidget(_host(_shell()));
    expect(GhLiveReveal.live, isTrue);
    expect(_transitionAbove(tester, 'titlebar'), isNull);
    expect(GhUiTransition.consumeShellIntroHandOff(), isFalse);
  });

  testWidgets('disposing a running intro still enables live reveal', (tester) async {
    await tester.pumpWidget(_host(_shell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(GhLiveReveal.live, isFalse);
    await tester.pumpWidget(_host(const SizedBox()));
    expect(GhLiveReveal.live, isTrue);
  });

  testWidgets('replay runs the intro again', (tester) async {
    await tester.pumpWidget(_host(_shell(replay: 0)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(_value(tester, 'titlebar'), 1);
    await tester.pumpWidget(_host(_shell(replay: 1)));
    expect(_value(tester, 'titlebar'), 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_value(tester, 'titlebar'), greaterThan(0));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(_value(tester, 'titlebar'), 1);
  });

  testWidgets('pressables outside a sidebar do not register', (tester) async {
    await tester.pumpWidget(_host(GhShellIntro(
      child: GhIntroTitleBar(child: GhPressable(onPressed: () {}, builder: (context, states) => const SizedBox(width: 10, height: 10))),
    )));
    final state = tester.state<GhShellIntroState>(find.byType(GhShellIntro));
    expect(state.count(GhIntroRole.item), 0);
    await tester.pump(const Duration(seconds: 3));
  });

  test('ui transition flags', () {
    expect(GhUiTransition.shouldShowSplash(), isTrue);
    GhUiTransition.markSplashConsumed();
    expect(GhUiTransition.shouldShowSplash(), isFalse);
    expect(GhUiTransition.shouldOpenSettingsAfterSwitch(), isFalse);
    GhUiTransition.clearUiSwitchToSettings();
    GhUiTransition.handOffShellIntro();
    expect(GhUiTransition.consumeShellIntroHandOff(), isTrue);
    expect(GhUiTransition.consumeShellIntroHandOff(), isFalse);
  });

  test('ring pulse frames', () {
    expect(ghRingFrame(-1, 0, 8), isNull);
    final start = ghRingFrame(0, 0, 8)!;
    expect(start.inset, 0);
    expect(start.radius, 8);
    expect(start.opacity, closeTo(0.75, 1e-9));
    final waiting = ghRingFrame(1, 1, 8)!;
    expect(waiting.opacity, closeTo(0.75, 1e-9));
    expect(waiting.inset, 0);
    final mid = ghRingFrame(1.2, 0, 8)!;
    expect(mid.inset, closeTo(-14 * GhRingPulseTiming.ease.transform(0.5), 1e-9));
    expect(ghRingFrame(2.4, 0, 8)!.opacity, closeTo(0.75, 1e-9));
    expect(ghRingFrame(3.6, 1, 8)!.opacity, closeTo(0.75, 1e-9));
    expect(ghRingFrame(2.3999, 0, 8)!.opacity, lessThan(0.01));
  });

  test('magnet pull stays within the margin', () {
    const anchor = Rect.fromLTWH(100, 100, 100, 40);
    expect(ghMagnetTarget(anchor, const Offset(150, 120)), Offset.zero);
    expect(ghMagnetTarget(anchor, const Offset(220, 120)), const Offset(70 * 0.3, 0));
    expect(ghMagnetTarget(anchor, const Offset(229, 120)), Offset.zero);
    expect(ghMagnetTarget(anchor, const Offset(150, 160)), Offset(0, 40 * 0.3));
  });

  testWidgets('welcome intro timeline layout', (tester) async {
    await tester.pumpWidget(_host(const _TimelineProbe()));
    final probe = tester.state<_TimelineProbeState>(find.byType(_TimelineProbe));
    expect(probe.intro.ringsAt, closeTo(1.95, 1e-12));
    expect(probe.intro.letters, hasLength(8));
    expect(GhWelcomeIntroPoses.cta, const GhPose(opacity: 0, scale: 0.85, y: 12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1950));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.idle();
    expect(probe.intro.cta.value, 1);
    expect(probe.done, isTrue);
  });

  testWidgets('ring pulse ticks only while running and motion is on', (tester) async {
    await tester.pumpWidget(_host(const GhRingPulse(color: Color(0xFF00FF00), child: SizedBox(width: 80, height: 30))));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(_host(const GhRingPulse(color: Color(0xFF00FF00), running: false, child: SizedBox(width: 80, height: 30))));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(_host(const GhRingPulse(color: Color(0xFF00FF00), child: SizedBox(width: 80, height: 30)), reduced: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('magnet follows the pointer and releases on exit', (tester) async {
    await tester.pumpWidget(_host(Center(
      child: SizedBox(
        width: 400,
        height: 300,
        child: GhMagneticArea(child: Center(child: GhMagnet(child: Container(key: const ValueKey('cta'), width: 100, height: 40, color: const Color(0xFF0000FF))))),
      ),
    )));
    final center = tester.getCenter(find.byKey(const ValueKey('cta')));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await mouse.moveTo(center + const Offset(60, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getCenter(find.byKey(const ValueKey('cta'))).dx, closeTo(center.dx + 18, 0.5));
    await mouse.moveTo(center + const Offset(150, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getCenter(find.byKey(const ValueKey('cta'))).dx, closeTo(center.dx, 0.5));
    await mouse.removePointer();
  });

  testWidgets('letter rise hides letters first and runs only with motion', (tester) async {
    const style = TextStyle(fontSize: 20);
    await tester.pumpWidget(_host(const GhLetterRise(text: 'Godot', style: style)));
    expect(find.byType(GhPoseTransition), findsNWidgets(5));
    final first = tester.widget<GhPoseTransition>(find.byType(GhPoseTransition).first);
    expect(first.from, ghLetterFrom);
    expect(first.origin, Alignment.bottomCenter);
    expect((first.listenable as Animation<double>).value, 0);
    await tester.pump(const Duration(seconds: 2));
    expect((first.listenable as Animation<double>).value, 1);
    await tester.pumpWidget(_host(const GhLetterRise(key: ValueKey('off'), text: 'Godot', style: style), reduced: true));
    final off = tester.widget<GhPoseTransition>(find.byType(GhPoseTransition).first);
    expect((off.listenable as Animation<double>).value, 1);
  });

  group('splash', () {
    testWidgets('letters rise, the track grows and the bar loops', (tester) async {
      await tester.pumpWidget(_host(const GhSplashScreen()));
      final transitions = find.byType(GhPoseTransition);
      expect(transitions, findsNWidgets(9));
      final letters = tester.widgetList<GhPoseTransition>(transitions).take(8).toList();
      expect(letters.first.from, ghLetterFrom);
      expect(letters.first.perspective, 600);
      final track = tester.widget<GhPoseTransition>(transitions.last);
      expect(track.from, GhSplashTiming.trackFrom);
      expect(find.text('G'), findsOneWidget);
      final text = tester.widget<Text>(find.text('G'));
      expect(text.style!.fontStyle, FontStyle.italic);
      expect(text.style!.fontWeight, FontWeight.w900);
      expect(text.style!.fontSize, 56);
      await tester.pump(const Duration(milliseconds: 240));
      expect((track.listenable as Animation<double>).value, 0);
      await tester.pump(const Duration(seconds: 2));
      expect((track.listenable as Animation<double>).value, 1);
      expect((letters.last.listenable as Animation<double>).value, 1);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with motion off the letters still run 40 times faster and the bar stays still', (tester) async {
      await tester.pumpWidget(_host(const GhSplashScreen(), reduced: true));
      final transitions = find.byType(GhPoseTransition);
      final last = tester.widgetList<GhPoseTransition>(transitions).elementAt(7);
      expect((last.listenable as Animation<double>).value, 0);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 30));
      expect((last.listenable as Animation<double>).value, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

class _TimelineProbe extends StatefulWidget {
  const _TimelineProbe();

  @override
  State<_TimelineProbe> createState() => _TimelineProbeState();
}

class _TimelineProbeState extends State<_TimelineProbe> with SingleTickerProviderStateMixin {
  late final GhWelcomeIntroTimeline intro = GhWelcomeIntroTimeline(vsync: this, letters: 8);
  bool done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    intro.play(GhMotion.of(context)).then((_) => done = true);
  }

  @override
  void dispose() {
    intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
