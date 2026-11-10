import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/hello_screen.dart';
import 'package:godothub/src/providers.dart';

Finder selectableText(String text) =>
    find.byWidgetPredicate((widget) => widget is SelectableText && widget.data == text);

void main() {
  testWidgets('shows core settings and the command line tool status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsJsonProvider.overrideWith((ref) async => '{"language": "en-US"}'),
          cliToolStatusProvider.overrideWith((ref) async => '{"installed": false}'),
        ],
        child: const MaterialApp(home: HelloScreen(title: 'GodotHub Beta')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GodotHub Beta: Hello from core'), findsOneWidget);
    expect(selectableText('{"language": "en-US"}'), findsOneWidget);
    expect(selectableText('{"installed": false}'), findsOneWidget);
    expect(find.text('Install command'), findsOneWidget);
  });

  testWidgets('shows core errors instead of data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsJsonProvider.overrideWith((ref) => Future<String>.error('core failed')),
          cliToolStatusProvider.overrideWith((ref) async => '{}'),
        ],
        child: const MaterialApp(home: HelloScreen(title: 'GodotHub Beta')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('core failed'), findsOneWidget);
  });
}
