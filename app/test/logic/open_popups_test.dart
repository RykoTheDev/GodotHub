import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/open_popups.dart';
import 'package:godothub/ui/overlays/popup_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(GhPopupRegistry.debugReset);

  test('reflects the popup registry open count', () {
    expect(isPopupOpen(), isFalse);
    final first = GhPopupRegistry.open(close: () {});
    expect(isPopupOpen(), isTrue);
    first.release();
    expect(isPopupOpen(), isFalse);
  });

  test('stays open until every popup is released', () {
    final first = GhPopupRegistry.open(close: () {});
    final second = GhPopupRegistry.open(close: () {});
    first.release();
    expect(isPopupOpen(), isTrue);
    first.release();
    expect(isPopupOpen(), isTrue);
    second.release();
    expect(isPopupOpen(), isFalse);
  });
}
