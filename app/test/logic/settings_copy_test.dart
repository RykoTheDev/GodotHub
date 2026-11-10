import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/state/settings.dart';

void main() {
  test('copies every field unchanged by default', () {
    final copy = copySettings(defaultSettings);
    expect(identical(copy, defaultSettings), isFalse);
    expect(copy, defaultSettings);
  });

  test('overrides only the given fields, including clearing nullable ones', () {
    final withDir = copySettings(defaultSettings, downloadDir: () => '/downloads', language: 'fr-FR', tooltipDelay: 10);
    expect(withDir.downloadDir, '/downloads');
    expect(withDir.language, 'fr-FR');
    expect(withDir.tooltipDelay, 10);
    expect(withDir.themeMode, defaultSettings.themeMode);
    expect(withDir.cardLayout, defaultSettings.cardLayout);

    final cleared = copySettings(withDir, downloadDir: () => null);
    expect(cleared.downloadDir, isNull);
    expect(cleared.language, 'fr-FR');
  });
}
