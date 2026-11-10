import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/api/projects.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/api_data.dart';
import 'package:godothub/state/app_signals.dart';

import '../support/fake_rust.dart';

class _Probe extends ApiDataNotifier<List<Project>> {
  @override
  List<Project> get initial => const [];

  @override
  bool get keepsError => true;

  @override
  Future<List<Project>> fetch() => ProjectsApi.list();

  @override
  void setup() {
    ref.listenAppEvent(AppEventKind.projectScanDone, (_) => refresh());
    ref.listenSignal('app:project-health-changed', (_) => refresh());
  }
}

final _probe = NotifierProvider<_Probe, ApiData<List<Project>>>(_Probe.new);

void main() {
  late FakeRustApi rust;

  setUp(() => rust = installFakeRust());

  test('fetches on first read and refetches on backend events and app signals', () async {
    var fail = false;
    rust.on('crateApiProjectsListProjects', () async {
      if (fail) throw StateError('boom');
      return <Project>[];
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(_probe, (_, _) {});
    addTearDown(sub.close);

    expect(container.read(_probe).loaded, isFalse);
    await pumpEventQueue();
    expect(container.read(_probe).loaded, isTrue);
    expect(rust.callCount('crateApiProjectsListProjects'), 1);

    rust.emit(fakeEvent(AppEventKind.projectScanDone));
    await pumpEventQueue();
    expect(rust.callCount('crateApiProjectsListProjects'), 2);

    fail = true;
    AppSignals.emit('app:project-health-changed');
    await pumpEventQueue();
    expect(rust.callCount('crateApiProjectsListProjects'), 3);
    expect(container.read(_probe).error, contains('boom'));
    expect(container.read(_probe).data, isEmpty);
  });
}
