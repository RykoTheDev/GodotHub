import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';

/// Pumps an empty app and opens [build] as a GodotHub modal on top of it.
Future<void> open(WidgetTester tester, Widget Function(VoidCallback close) build, {Size size = const Size(1280, 800)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late BuildContext host;
  await tester.pumpWidget(
    MaterialApp(
      theme: GhTheme.defaults().toThemeData(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            host = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  showGhModal<void>(host, (modal) => build(() => Navigator.of(modal).pop())).ignore();
  await tester.pumpAndSettle();
}
