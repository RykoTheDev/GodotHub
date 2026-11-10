import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/state/scroll_compensation.dart';

void main() {
  test('clamps the saved offset to the scrollable range', () {
    expect(compensatedScrollOffset(300, 1000), 300);
    expect(compensatedScrollOffset(300, 120), 120);
    expect(compensatedScrollOffset(300, -10), 0);
  });

  testWidgets('remembers the offset and restores it after the content changes', (tester) async {
    final compensation = ScrollCompensation();
    addTearDown(compensation.dispose);
    Widget list(int count) => MaterialApp(
      home: ListView(
        controller: compensation.controller,
        children: [for (var i = 0; i < count; i++) SizedBox(key: ValueKey(i), height: 50)],
      ),
    );
    await tester.pumpWidget(list(100));
    compensation.controller.jumpTo(800);
    expect(compensation.savedOffset, 800);

    await tester.pumpWidget(list(14));
    final max = compensation.controller.position.maxScrollExtent;
    compensation.restoreScroll();
    await tester.pump();
    expect(compensation.controller.offset, max);
  });
}
