import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_category_nav.dart';

void main() {
  test('consume returns the pending category once', () {
    expect(consumePendingSettingsCategory(), isNull);
    setPendingSettingsCategory('appearance');
    setPendingSettingsCategory('git');
    expect(consumePendingSettingsCategory(), 'git');
    expect(consumePendingSettingsCategory(), isNull);
    setPendingSettingsCategory('x');
    setPendingSettingsCategory(null);
    expect(consumePendingSettingsCategory(), isNull);
  });
}
