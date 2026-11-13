import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/error_boundary.dart';

import 'i18n_setup.dart';

class _Flaky extends StatelessWidget {
  const _Flaky({required this.fail});

  final ValueNotifier<bool> fail;

  @override
  Widget build(BuildContext context) {
    if (fail.value) throw StateError('view exploded');
    return const Text('view ok');
  }
}

void main() {
  setUp(setUpTestI18n);

  testWidgets('a crashing view shows the retry panel and recovers on retry', (tester) async {
    final previous = ErrorWidget.builder;
    ErrorWidget.builder = ghErrorWidget;
    final fail = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(body: GhViewErrorScope(child: _Flaky(fail: fail))),
      ),
    );
    tester.takeException();
    await tester.pump();
    expect(find.text(ghTr('view_error_title')), findsOneWidget);
    await tester.tap(find.text(ghTr('error_details')));
    await tester.pump();
    expect(find.textContaining('view exploded'), findsOneWidget);
    fail.value = false;
    await tester.tap(find.text(ghTr('retry')));
    await tester.pump();
    expect(find.text('view ok'), findsOneWidget);
    expect(find.text(ghTr('view_error_title')), findsNothing);
    ErrorWidget.builder = previous;
  });

  testWidgets('an error outside any view shows the full app error screen', (tester) async {
    await tester.pumpWidget(ghErrorWidget(FlutterErrorDetails(exception: Exception('shell exploded'))));
    expect(find.text(ghTr('app_error_title')), findsOneWidget);
    expect(find.text('shell exploded'), findsOneWidget);
    expect(find.text(ghTr('reload')), findsOneWidget);
  });
}
