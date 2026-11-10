import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/running_projects.dart';
import 'package:godothub/src/rust/api/types.dart';

final running = RunningProjectInfo(id: 'a', name: 'A', version: '4.3', launchedAtMs: BigInt.one, console: false);

void main() {
  test('retries with the TypeScript delays until something is running', () async {
    final waits = <int>[];
    var calls = 0;
    final result = await fetchRunningProjects(
      list: () async => ++calls < 3 ? [] : [running],
      wait: (delay) async => waits.add(delay.inMilliseconds),
    );
    expect(result, [running]);
    expect(calls, 3);
    expect(waits, [1200, 3000]);
  });

  test('gives up after the last delay with an empty list', () async {
    final waits = <int>[];
    var calls = 0;
    final result = await fetchRunningProjects(
      list: () async {
        calls++;
        return [];
      },
      wait: (delay) async => waits.add(delay.inMilliseconds),
    );
    expect(result, isEmpty);
    expect(calls, 4);
    expect(waits, [1200, 3000, 6000]);
  });

  test('stops on the first error and returns what it had', () async {
    var calls = 0;
    final result = await fetchRunningProjects(
      list: () async {
        calls++;
        if (calls == 2) throw StateError('bridge down');
        return [];
      },
      wait: (_) async {},
    );
    expect(result, isEmpty);
    expect(calls, 2);
  });

  test('returns immediately when the first call finds projects', () async {
    var waited = false;
    final result = await fetchRunningProjects(list: () async => [running], wait: (_) async => waited = true);
    expect(result, [running]);
    expect(waited, isFalse);
  });
}
