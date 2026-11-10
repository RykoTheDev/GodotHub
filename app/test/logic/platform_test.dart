import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' hide isLinux, isWindows;
import 'package:godothub/logic/platform.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  const expected = {
    TargetPlatform.windows: (false, true, false),
    TargetPlatform.macOS: (true, false, false),
    TargetPlatform.linux: (false, false, true),
    TargetPlatform.iOS: (true, false, false),
    TargetPlatform.android: (false, false, false),
    TargetPlatform.fuchsia: (false, false, false),
  };

  for (final entry in expected.entries) {
    test('${entry.key.name} maps like the user agent checks', () {
      debugDefaultTargetPlatformOverride = entry.key;
      expect((isMac, isWindows, isLinux), entry.value);
    });
  }

  test('default corner radius', () {
    expect(defaultCornerRadius, 7);
  });
}
