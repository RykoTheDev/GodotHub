import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/projects/category_sections.dart';

Future<void> _pump(WidgetTester tester, String title) async {
  tester.view.physicalSize = const Size(1000, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GhTheme.defaults().toThemeData(),
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CategorySectionHeader(title: title, count: 5, open: true, color: Colors.orange, onToggle: () {}),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the divider line fills the header and the count sits at the end', (tester) async {
    await _pump(tester, 'Prototypes');
    final row = tester.getRect(find.descendant(of: find.byType(CategorySectionHeader), matching: find.byType(Row)).first);
    final count = tester.getRect(find.textContaining('·'));
    expect(row.right - count.right, lessThan(20));
  });

  testWidgets('a long title still truncates instead of overflowing', (tester) async {
    await _pump(tester, 'A very long category name ' * 12);
    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.textContaining('A VERY LONG'));
    expect(title.right, lessThan(1000));
  });
}
