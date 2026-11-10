import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/duration.dart';

void main() {
  test('formats like the TypeScript version', () {
    const cases = {
      0: '0s',
      -1000: '0s',
      999: '0s',
      1000: '1s',
      59999: '59s',
      60000: '1m 0s',
      61000: '1m 1s',
      3599999: '59m 59s',
      3600000: '1h 0m',
      3661000: '1h 1m',
      90061000: '25h 1m',
    };
    for (final entry in cases.entries) {
      expect(formatDuration(entry.key), entry.value, reason: '${entry.key}');
    }
  });
}
