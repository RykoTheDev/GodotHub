import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/ui/shell/smooth_scroll.dart';

Future<ScrollController> _pump(WidgetTester tester, {GhMotionPrefs prefs = const GhMotionPrefs()}) async {
  final controller = GhSmoothScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: GhMotion(
        prefs: prefs,
        osReduced: false,
        child: GhScrollView(controller: controller, child: const SizedBox(height: 5000)),
      ),
    ),
  );
  return controller;
}

Future<void> _wheel(WidgetTester tester, double dy) async {
  final center = tester.getCenter(find.byType(GhScrollView));
  tester.binding.handlePointerEvent(PointerScrollEvent(position: center, scrollDelta: Offset(0, dy)));
}

void main() {
  testWidgets('wheel scrolling eases to the target instead of jumping', (tester) async {
    final controller = await _pump(tester);
    await _wheel(tester, 200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(200));
    await tester.pumpAndSettle();
    expect(controller.offset, 200);
  });

  testWidgets('wheel notches during an animation add up', (tester) async {
    final controller = await _pump(tester);
    await _wheel(tester, 200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await _wheel(tester, 200);
    await tester.pumpAndSettle();
    expect(controller.offset, 400);
    await _wheel(tester, -10000);
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  testWidgets('wheel scrolling jumps when motion is off', (tester) async {
    final controller = await _pump(tester, prefs: const GhMotionPrefs(intensity: GhMotionIntensity.none));
    await _wheel(tester, 200);
    await tester.pump();
    expect(controller.offset, 200);
  });
}
