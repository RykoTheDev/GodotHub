import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/format_bytes.dart';

void main() {
  test('matches Number.toFixed output from the TypeScript version', () {
    final cases = <num, String>{
      0: '0 MB',
      -5: '0 MB',
      1: '0.0 KB',
      512: '0.5 KB',
      1023: '1.0 KB',
      1024: '1.0 KB',
      1536: '1.5 KB',
      51.2: '0.1 KB',
      1048575: '1024.0 KB',
      1048576: '1.0 MB',
      1310720: '1.3 MB',
      1073741823: '1024.0 MB',
      1073741824: '1.00 GB',
      2872259379.2: '2.67 GB',
      1e15: '931322.57 GB',
    };
    for (final entry in cases.entries) {
      expect(formatBytes(entry.key), entry.value, reason: '${entry.key}');
    }
  });

  test('non-finite input is 0 MB', () {
    expect(formatBytes(double.nan), '0 MB');
    expect(formatBytes(double.infinity), '0 MB');
    expect(formatBytes(double.negativeInfinity), '0 MB');
  });

  test('BigInt sizes from the bridge', () {
    expect(formatBigBytes(BigInt.from(1536)), '1.5 KB');
    expect(formatBigBytes(BigInt.zero), '0 MB');
  });
}
