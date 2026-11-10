import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/core.dart' as core;
import 'package:godothub/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());

  testWidgets('starts the beta core and reads its settings', (tester) async {
    expect(core.startCore(channel: 'beta'), 'GodotHub Beta');
    final settings = jsonDecode(await core.getSettingsJson()) as Map<String, dynamic>;
    expect(settings, contains('language'));
    expect(() => core.startCore(channel: 'stable'), throwsA(anything));
    expect(() => core.startCore(channel: 'nightly'), throwsA(anything));
  });
}
