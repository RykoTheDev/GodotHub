import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/debug/gallery/sections/motion_reveal.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/motion/drag_feel.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/motion/reveal.dart';
import 'package:godothub/motion/shared_ticker.dart';
import 'package:godothub/ui/core/interaction.dart';

const _speed1 = GhMotionPrefs(speed: 1);

Widget _host(Widget child, {GhMotionPrefs prefs = _speed1, bool reduced = false}) {
  return MaterialApp(
    theme: GhTheme.defaults().toThemeData(),
    home: GhMotion(
      prefs: prefs,
      osReduced: reduced,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Widget _button(double width, {double height = 36, VoidCallback? onPressed, Key? key, bool ripple = true}) => GhPressable(
      key: key,
      onPressed: onPressed ?? () {},
      ripple: ripple,
      borderRadius: BorderRadius.circular(8),
      builder: (context, states) => SizedBox(width: width, height: height),
    );

GhPressMotionState _motion(WidgetTester tester, [Finder? within]) => tester.state<GhPressMotionState>(
      within == null ? find.byType(GhPressMotion).first : find.descendant(of: within, matching: find.byType(GhPressMotion)).first,
    );

void main() {
  setUp(GhLiveReveal.reset);

  test('press scale depends on width', () {
    expect(GhPressTiming.pressScale(300), 0.985);
    expect(GhPressTiming.pressScale(261), 0.985);
    expect(GhPressTiming.pressScale(260), 0.955);
    expect(GhPressTiming.pressScale(91), 0.955);
    expect(GhPressTiming.pressScale(90), 0.88);
    expect(ghRippleDiameter(const Size(30, 40)), 100);
  });

  for (final (width, scale) in [(300.0, 0.985), (120.0, 0.955), (40.0, 0.88)]) {
    testWidgets('press squashes a ${width.toInt()}px button to $scale and releases elastically', (tester) async {
      await tester.pumpWidget(_host(_button(width)));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(_motion(tester).scale, closeTo(scale, 1e-9));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _motion(tester).scale;
      expect(mid, isNot(closeTo(scale, 1e-3)));
      await tester.pump(const Duration(milliseconds: 750));
      expect(_motion(tester).scale, 1);
    });
  }

  testWidgets('ripple needs the ripple pref and full intensity', (tester) async {
    await tester.pumpWidget(_host(_button(120)));
    await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
    await tester.pump();
    expect(_motion(tester).rippleCount, 1);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();
    expect(_motion(tester).rippleCount, 0);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(_button(120, key: const ValueKey('subtle')), prefs: _speed1.copyWith(intensity: GhMotionIntensity.subtle)));
    final subtle = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
    await tester.pump();
    expect(_motion(tester).rippleCount, 0);
    await subtle.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(_button(120, key: const ValueKey('pref')), prefs: _speed1.copyWith(ripple: false)));
    final pref = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
    await tester.pump();
    expect(_motion(tester).rippleCount, 0);
    await pref.up();
    await tester.pumpAndSettle();
  });

  testWidgets('ripple opt-outs and the minimum size', (tester) async {
    await tester.pumpWidget(_host(GhNoRipple(child: _button(120))));
    var gesture = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
    await tester.pump();
    expect(_motion(tester).rippleCount, 0);
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(_button(120, key: const ValueKey('flag'), ripple: false)));
    gesture = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
    await tester.pump();
    expect(_motion(tester).rippleCount, 0);
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(_button(17, height: 20, key: const ValueKey('small'))));
    gesture = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
    await tester.pump();
    expect(_motion(tester).rippleCount, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('press needs the press pref and motion on; disabled buttons never move', (tester) async {
    Future<double> pressed(Widget widget) async {
      await tester.pumpWidget(widget);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(GhPressable)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final scale = _motion(tester).scale;
      await gesture.up();
      await tester.pumpAndSettle();
      return scale;
    }

    expect(await pressed(_host(_button(120), prefs: _speed1.copyWith(press: false))), 1);
    expect(await pressed(_host(_button(120, key: const ValueKey('off')), reduced: true)), 1);
    expect(await pressed(_host(_button(120, key: const ValueKey('none')), prefs: _speed1.copyWith(intensity: GhMotionIntensity.none))), 1);
    expect(
      await pressed(_host(GhPressable(onPressed: null, builder: (context, states) => const SizedBox(width: 120, height: 36)))),
      1,
    );
    expect(await pressed(_host(_button(120, key: const ValueKey('subtle')), prefs: _speed1.copyWith(intensity: GhMotionIntensity.subtle))), 0.955);
  });

  testWidgets('only the innermost pressable reacts', (tester) async {
    await tester.pumpWidget(_host(GhPressable(
      key: const ValueKey('outer'),
      onPressed: () {},
      builder: (context, states) => SizedBox(width: 300, height: 80, child: Center(child: _button(60, key: const ValueKey('inner')))),
    )));
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('inner'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_motion(tester, find.byKey(const ValueKey('inner'))).scale, closeTo(0.88, 1e-9));
    expect(_motion(tester).scale, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Enter and Space pulse the focused pressable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_button(120, onPressed: () => taps += 1)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
    expect(_motion(tester).scale, closeTo(0.92, 1e-9));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_motion(tester).scale, isNot(0.92));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_motion(tester).scale, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
    expect(_motion(tester).scale, closeTo(0.92, 1e-9));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(_button(120, key: const ValueKey('nopress'), onPressed: () => taps += 1), prefs: _speed1.copyWith(press: false)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 3);
    expect(_motion(tester).scale, 1);
  });

  group('tilt', () {
    test('strength and angles', () {
      expect(ghTiltStrength(const Size(300, 150)), 7);
      expect(ghTiltStrength(const Size(600, 150)), 4);
      expect(ghTiltStrength(const Size(119, 150)), 0);
      expect(ghTiltStrength(const Size(300, 63)), 0);
      expect(ghTiltStrength(const Size(1401, 150)), 0);
      expect(ghTiltStrength(const Size(300, 641)), 0);
      final angles = ghTiltAngles(const Size(300, 150), const Offset(300, 0))!;
      expect(angles.rotationY, 3.5);
      expect(angles.rotationX, 3.5);
      expect(angles.y, -4);
      expect(ghTiltAngles(const Size(100, 150), Offset.zero), isNull);
      expect(GhTiltAngles.rest.toMatrix(), Matrix4.identity());
      expect(angles.toMatrix(), isNot(Matrix4.identity()));
    });

    Future<TestGesture> hover(WidgetTester tester, Offset at) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await tester.pump();
      await mouse.moveTo(at);
      await tester.pump();
      return mouse;
    }

    testWidgets('a card tilts toward the mouse and springs back on leave', (tester) async {
      await tester.pumpWidget(_host(const GhTiltCard(child: SizedBox(width: 300, height: 150))));
      final rect = tester.getRect(find.byType(GhTiltCard));
      final mouse = await hover(tester, rect.topRight + const Offset(-1, 1));
      await tester.pump(const Duration(seconds: 1));
      final state = tester.state<GhTiltCardState>(find.byType(GhTiltCard));
      expect(state.angles.rotationY, greaterThan(3));
      expect(state.angles.rotationX, greaterThan(3));
      expect(state.angles.y, -4);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(state.angles, GhTiltAngles.rest);
      await mouse.removePointer();
    });

    testWidgets('no tilt with subtle intensity, without the pref or inside a no-tilt region', (tester) async {
      for (final (index, widget) in [
        _host(const GhTiltCard(child: SizedBox(width: 300, height: 150)), prefs: _speed1.copyWith(intensity: GhMotionIntensity.subtle)),
        _host(const GhTiltCard(child: SizedBox(width: 300, height: 150)), prefs: _speed1.copyWith(tilt: false)),
        _host(const GhNoTilt(child: GhTiltCard(child: SizedBox(width: 300, height: 150)))),
      ].indexed) {
        await tester.pumpWidget(KeyedSubtree(key: ValueKey(index), child: widget));
        final rect = tester.getRect(find.byType(GhTiltCard));
        final mouse = await hover(tester, rect.topRight + const Offset(-1, 1));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.state<GhTiltCardState>(find.byType(GhTiltCard)).angles, GhTiltAngles.rest);
        await mouse.removePointer();
      }
    });

    testWidgets('cards inside dialogs do not tilt', (tester) async {
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => const Center(child: GhTiltCard(child: SizedBox(width: 300, height: 150))),
          ),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(GhTiltCard));
      final mouse = await hover(tester, rect.topRight + const Offset(-1, 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.state<GhTiltCardState>(find.byType(GhTiltCard)).angles, GhTiltAngles.rest);
      await mouse.removePointer();
    });
  });

  testWidgets('spin turns and grows, then clears; skipped when motion is off', (tester) async {
    Widget build(int trigger, {bool reduced = false}) =>
        _host(GhSpin(trigger: trigger, child: const SizedBox(key: ValueKey('icon'), width: 20, height: 20)), reduced: reduced);
    Matrix4 matrix() => tester.widget<Transform>(find.ancestor(of: find.byKey(const ValueKey('icon')), matching: find.byType(Transform)).first).transform;
    await tester.pumpWidget(build(0));
    expect(matrix(), Matrix4.identity());
    await tester.pumpWidget(build(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(matrix(), isNot(Matrix4.identity()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(matrix(), Matrix4.identity());
    await tester.pumpWidget(build(2, reduced: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(matrix(), Matrix4.identity());
  });

  group('drag feel', () {
    test('constants', () {
      expect(GhDragFeel.activationDistance, 7);
      expect(GhDragFeel.ghostOpacity, 0.22);
      expect(GhDragFeel.reflow.duration, const Duration(milliseconds: 220));
      expect(GhDragFeel.drop.duration, const Duration(milliseconds: 260));
      expect(GhDragFeel.curve, const Cubic(0.22, 1, 0.36, 1));
      expect(GhDragFeel.liftScale, 1.02);
      expect(GhDragFeel.dropEndScale(1.02), closeTo(1 / 1.02, 1e-12));
      expect(GhDragFeel.dropLine.height, 2);
      expect(GhDragFeel.dropLine.dot, 4);
      expect(GhDragFeel.dropLine.glow, isFalse);
      expect(ghAutoScrollConfig.thresholdX, 0.12);
      expect(ghAutoScrollConfig.thresholdY, 0.12);
      expect(ghAutoScrollConfig.acceleration, 10);
    });

    testWidgets('lift scales to 1.02 over the CSS duration and stays', (tester) async {
      double scale() => tester
          .widget<Transform>(find.ancestor(of: find.byKey(const ValueKey('card')), matching: find.byType(Transform)).first)
          .transform
          .entry(0, 0);
      await tester.pumpWidget(_host(const GhDragLift(child: SizedBox(key: ValueKey('card'), width: 100, height: 40))));
      expect(scale(), 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), greaterThan(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(scale(), closeTo(1.02, 1e-9));
      await tester.pumpWidget(_host(const GhDragLift(key: ValueKey('r'), child: SizedBox(key: ValueKey('card'), width: 100, height: 40)), reduced: true));
      await tester.pump(const Duration(milliseconds: 1));
      expect(scale(), closeTo(1.02, 1e-9));
    });

    testWidgets('ghost dims the source', (tester) async {
      await tester.pumpWidget(_host(const GhDragGhost(ghost: true, child: SizedBox(width: 10, height: 10))));
      expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 0.22);
    });
  });

  group('shared ticker', () {
    testWidgets('one timer starts with the first subscriber and stops after the last', (tester) async {
      final ticker = GhSharedTicker.instance;
      expect(ticker.running, isFalse);
      var a = 0;
      var b = 0;
      final stopA = ticker.subscribe((_) => a += 1);
      final stopB = ticker.subscribe((_) => b += 1);
      expect(ticker.running, isTrue);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(a, 2);
      expect(b, 2);
      stopA();
      stopA();
      expect(ticker.running, isTrue);
      stopB();
      expect(ticker.running, isFalse);
      void listener() {}
      ticker.addListener(listener);
      expect(ticker.running, isTrue);
      ticker.removeListener(listener);
      expect(ticker.running, isFalse);
    });

    testWidgets('GhNow rebuilds every second while active', (tester) async {
      var builds = 0;
      Widget build(bool active) => Directionality(
            textDirection: TextDirection.ltr,
            child: GhNow(
              active: active,
              builder: (context, now) {
                builds += 1;
                return Text('${now.millisecondsSinceEpoch}');
              },
            ),
          );
      await tester.pumpWidget(build(true));
      expect(builds, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(builds, 2);
      await tester.pumpWidget(build(false));
      expect(GhSharedTicker.instance.running, isFalse);
      final before = builds;
      await tester.pump(const Duration(seconds: 2));
      expect(builds, before);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('motion gallery sections build', (tester) async {
    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final section in motionRevealSections) {
      await tester.pumpWidget(_host(SingleChildScrollView(child: Builder(builder: section.builder))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull, reason: section.title);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
