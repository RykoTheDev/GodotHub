import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/motion/ease.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/motion/tween.dart';

Opacity? _opacity(WidgetTester tester) {
  final finder = find.byType(Opacity);
  return finder.evaluate().isEmpty ? null : tester.widget<Opacity>(finder.first);
}

Widget _host(Widget child, {GhMotionPrefs prefs = const GhMotionPrefs(speed: 1), bool reduced = false}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: GhMotion(prefs: prefs, child: child),
    ),
  );
}

void main() {
  test('timing follows the GSAP global time scale', () {
    const base = GhMotionData();
    expect(base.speed, 1.5);
    expect(base.gsap(0.75), const Duration(milliseconds: 500));
    expect(const GhMotionData(prefs: GhMotionPrefs(intensity: GhMotionIntensity.subtle)).speed, closeTo(2.7, 1e-12));
    expect(const GhMotionData(osReduced: true).timeScale, 40);
    expect(const GhMotionData(prefs: GhMotionPrefs(intensity: GhMotionIntensity.none)).off, isTrue);
    expect(const GhMotionData(prefs: GhMotionPrefs(intensity: GhMotionIntensity.subtle)).flourishes, isFalse);
    expect(const GhMotionData().css(const Duration(milliseconds: 300)), const Duration(milliseconds: 200));
    expect(const GhMotionData(osReduced: true).css(const Duration(milliseconds: 300)).inMicroseconds, 10);
    expect(ghStaggerAmount(0, 5, 0.12), 0);
    expect(ghStaggerAmount(4, 5, 0.12), closeTo(0.12, 1e-12));
    expect(ghStaggerAmount(0, 1, 0.12), 0);
  });

  testWidgets('a from tween holds its start pose through the delay, then eases in', (tester) async {
    await tester.pumpWidget(_host(GhFrom(
      from: const GhPose(opacity: 0),
      delay: 0.2,
      duration: 0.4,
      ease: GsapEase('none'),
      child: const SizedBox(width: 10, height: 10),
    )));
    expect(_opacity(tester)!.opacity, 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(_opacity(tester)!.opacity, 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_opacity(tester)!.opacity, closeTo(0.5, 0.01));
    await tester.pump(const Duration(milliseconds: 250));
    expect(_opacity(tester)!.opacity, 1);
  });

  testWidgets('motion off skips the tween unless it runs when off', (tester) async {
    await tester.pumpWidget(_host(
      GhFrom(from: const GhPose(opacity: 0), duration: 1, child: const SizedBox()),
      reduced: true,
    ));
    expect(_opacity(tester)!.opacity, 1);
    await tester.pumpWidget(_host(
      GhFrom(key: const ValueKey('b'), from: const GhPose(opacity: 0), duration: 1, ease: GsapEase('none'), runWhenOff: true, child: const SizedBox()),
      reduced: true,
    ));
    await tester.pump(const Duration(milliseconds: 12));
    expect(_opacity(tester)!.opacity, closeTo(0.48, 0.02));
    await tester.pump(const Duration(milliseconds: 20));
    expect(_opacity(tester)!.opacity, 1);
  });
}
