import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/titlebar/window_controls.dart';
import 'package:godothub/window/window_resize_edges.dart';
import 'package:material_ui/material_ui.dart';
import 'package:window_manager/window_manager.dart';

class _FakeWindow implements TitleBarWindow {
  bool maximized = false;
  VoidCallback? listener;

  @override
  bool get isMaximized => maximized;

  @override
  void minimize() {}

  @override
  void toggleMaximize() {}

  @override
  void close() {}

  @override
  void startDragging() {}

  @override
  VoidCallback addMaximizeListener(VoidCallback onChanged) {
    listener = onChanged;
    return () => listener = null;
  }
}

Future<void> _pump(WidgetTester tester, {required bool enabled, required TitleBarWindow window}) => tester.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: WindowResizeEdges(enabled: enabled, window: window, child: const Text('app')),
  ),
);

void main() {
  testWidgets('without a custom frame the content is left as it is', (tester) async {
    await _pump(tester, enabled: false, window: _FakeWindow());
    expect(find.byType(DragToResizeArea), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('a custom frame gets resize edges that turn off while maximized', (tester) async {
    final window = _FakeWindow();
    await _pump(tester, enabled: true, window: window);
    final area = find.byType(DragToResizeArea);
    expect(tester.widget<DragToResizeArea>(area).enableResizeEdges, isNull);
    expect(find.descendant(of: area, matching: find.byType(MouseRegion)), findsNWidgets(8));

    window.maximized = true;
    window.listener!();
    await tester.pump();
    expect(tester.widget<DragToResizeArea>(area).enableResizeEdges, isEmpty);
    expect(find.descendant(of: area, matching: find.byType(MouseRegion)), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}
