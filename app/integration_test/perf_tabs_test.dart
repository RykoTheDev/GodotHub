import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/main.dart' as app;
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/keyboard_shortcuts.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('tab switching', (tester) async {
    await app.main();
    await tester.pump(const Duration(seconds: 6));
    const tabs = ['versions', 'projects', 'settings', 'versions', 'projects', 'settings', 'versions', 'projects'];
    await binding.watchPerformance(() async {
      for (final tab in tabs.take(3)) {
        AppSignals.emit(setTabSignal, tab);
        await tester.pump(const Duration(milliseconds: 900));
      }
    }, reportKey: 'first');
    await binding.watchPerformance(() async {
      for (final tab in tabs) {
        AppSignals.emit(setTabSignal, tab);
        await tester.pump(const Duration(milliseconds: 900));
      }
    }, reportKey: 'tabs');
  });
}
