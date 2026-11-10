import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/git_status.dart';

import '../support/fake_rust.dart';

const _batch = 'crateApiGitBatchGitStatus';

void main() {
  late FakeRustApi rust;
  late List<List<String>> requests;
  late Map<String, GitStatus> server;

  setUp(() {
    rust = installFakeRust();
    requests = [];
    server = {
      '/a': const GitStatus(branch: 'main', hasUncommitted: false, isRepo: true),
      '/b': const GitStatus(branch: 'dev', hasUncommitted: true, isRepo: true),
    };
    rust.on(_batch, ({required List<String> paths}) async {
      requests.add(paths);
      return {for (final path in paths) if (server[path] != null) path: server[path]!};
    });
  });

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  ProviderContainer container() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('active consumers share one batched, sorted request and stay fresh for five seconds', (tester) async {
    final c = container();
    final first = c.listen(gitStatusMapProvider(gitStatusRequest(['/b', '/a'], true)), (_, _) {});
    expect(first.read().loading, isTrue);
    await flush(tester);
    expect(requests, [
      ['/a', '/b'],
    ]);
    expect(first.read().loading, isFalse);
    expect(first.read().statusMap['/b']?.branch, 'dev');

    final again = c.listen(gitStatusMapProvider(gitStatusRequest(['/a'], true)), (_, _) {});
    expect(again.read().loading, isFalse);
    await flush(tester);
    expect(requests, hasLength(1));

    final inactive = c.listen(gitStatusMapProvider(gitStatusRequest(['/c'], false)), (_, _) {});
    final empty = c.listen(gitStatusMapProvider(gitStatusRequest(const [], true)), (_, _) {});
    await flush(tester);
    expect(requests, hasLength(1));
    expect(empty.read().loading, isFalse);
    expect(inactive.read().statusMap['/a']?.branch, 'main');

    final widened = c.listen(gitStatusMapProvider(gitStatusRequest(['/c'], true)), (_, _) {});
    expect(widened.read().loading, isTrue);
    await flush(tester);
    expect(requests.last, ['/a', '/b', '/c']);
    expect(widened.read().loading, isFalse);

    for (final sub in [first, again, inactive, empty, widened]) {
      sub.close();
    }
    await flush(tester);
  });

  testWidgets('polls every 30 s, refreshes on the debounced signal and on resume, and stops without consumers', (
    tester,
  ) async {
    final c = container();
    final sub = c.listen(gitStatusMapProvider(gitStatusRequest(['/a'], true)), (_, _) {});
    await flush(tester);
    expect(requests, hasLength(1));

    server['/a'] = const GitStatus(branch: 'feature', hasUncommitted: true, isRepo: true);
    await tester.pump(gitStatusPollInterval);
    await flush(tester);
    expect(requests, hasLength(2));
    expect(sub.read().statusMap['/a']?.branch, 'feature');

    AppSignals.emit(refreshGitStatusSignal);
    await tester.pump(const Duration(milliseconds: 100));
    AppSignals.emit(refreshGitStatusSignal);
    await tester.pump(const Duration(milliseconds: 200));
    expect(requests, hasLength(2));
    await tester.pump(gitStatusRefreshDebounce);
    await flush(tester);
    expect(requests, hasLength(3));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(tester);
    expect(requests, hasLength(3));

    sub.close();
    await flush(tester);
    AppSignals.emit(refreshGitStatusSignal);
    await tester.pump(gitStatusPollInterval);
    await flush(tester);
    expect(requests, hasLength(3));
  });

  testWidgets('keeps the previous map instance when nothing changed and ignores failures', (tester) async {
    final c = container();
    final sub = c.listen(gitStatusMapProvider(gitStatusRequest(['/a', '/b'], true)), (_, _) {});
    await flush(tester);
    final firstMap = sub.read().statusMap;

    await tester.pump(gitStatusPollInterval);
    await flush(tester);
    expect(requests, hasLength(2));
    expect(identical(sub.read().statusMap, firstMap), isTrue);

    rust.on(_batch, ({required List<String> paths}) async => throw StateError('git missing'));
    await tester.pump(gitStatusPollInterval);
    await flush(tester);
    expect(identical(sub.read().statusMap, firstMap), isTrue);

    sub.close();
    await flush(tester);
  });
}
