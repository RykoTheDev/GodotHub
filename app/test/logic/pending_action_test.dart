import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/pending_action.dart';

void main() {
  test('nothing is pending, so consuming returns null every time', () {
    expect(consumePendingAction(), isNull);
    expect(consumePendingAction(), isNull);
  });
}
