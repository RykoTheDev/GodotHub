import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/state/backdrop_dismiss.dart';

void main() {
  test('only a press that starts and ends on the backdrop dismisses', () {
    var dismissed = 0;
    final tracker = BackdropDismissTracker(() => dismissed++);
    tracker.pointerDown(onBackdrop: false);
    expect(tracker.click(onBackdrop: true), isFalse);
    tracker.pointerDown(onBackdrop: true);
    expect(tracker.click(onBackdrop: false), isFalse);
    expect(tracker.click(onBackdrop: true), isFalse);
    tracker.pointerDown(onBackdrop: true);
    tracker.cancel();
    expect(tracker.click(onBackdrop: true), isFalse);
    tracker.pointerDown(onBackdrop: true);
    expect(tracker.click(onBackdrop: true), isTrue);
    expect(dismissed, 1);
  });

  testWidgets('tapping the backdrop dismisses, tapping or dragging out of the dialog does not', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GhBackdropDismiss(
          onDismiss: () => dismissed++,
          child: const Center(child: SizedBox(key: ValueKey('dialog'), width: 200, height: 200, child: ColoredBox(color: Colors.white))),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dialog')));
    expect(dismissed, 0);

    final dialog = tester.getCenter(find.byKey(const ValueKey('dialog')));
    final gesture = await tester.startGesture(dialog);
    await gesture.moveTo(const Offset(5, 5));
    await gesture.up();
    await tester.pump();
    expect(dismissed, 0);

    await tester.tapAt(const Offset(5, 5));
    expect(dismissed, 1);
  });
}
