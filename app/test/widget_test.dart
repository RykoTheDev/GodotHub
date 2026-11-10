import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/hello_screen.dart';
import 'package:godothub/src/providers.dart';
import 'package:godothub/src/rust/api/types.dart';

Finder selectableText(String text) =>
    find.byWidgetPredicate((widget) => widget is SelectableText && widget.data == text);

const status = CliToolStatus(
  installed: true,
  onPath: false,
  binDir: 'C:/beta/bin',
  shimPath: 'C:/beta/bin/godothub-beta.cmd',
  platform: 'windows',
  needsNewTerminal: false,
);

void main() {
  testWidgets('shows the command line tool status and settings errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Future<AppSettings>.error('core failed')),
          cliToolStatusProvider.overrideWith((ref) async => status),
        ],
        child: const MaterialApp(home: HelloScreen(title: 'GodotHub Beta')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GodotHub Beta: Hello from core'), findsOneWidget);
    expect(find.text('core failed'), findsOneWidget);
    expect(selectableText('installed: true'), findsOneWidget);
    expect(selectableText('shim_path: C:/beta/bin/godothub-beta.cmd'), findsOneWidget);
    expect(find.text('Install command'), findsOneWidget);
  });
}
