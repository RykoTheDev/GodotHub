import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/projects.dart';
import 'package:godothub/state/scan_progress.dart';
import 'package:godothub/state/workspaces.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

const _list = 'crateApiProjectsListProjects';

void main() {
  late FakeRustApi rust;
  late CoreBackend backend;
  late List<Project> server;
  late List<String> calls;

  setUp(() {
    rust = installFakeRust();
    backend = CoreBackend(rust, active: 'w1');
    server = [project('a', sortOrder: 0), project('b', sortOrder: 1), project('c', sortOrder: 2)];
    calls = [];
    rust.on(_list, () async => List<Project>.of(server));
  });

  List<String> ids(List<Project> projects) => [for (final p in projects) p.id];

  test('loads, then refetches on workspace switches, scans, downloads and health changes', () async {
    final container = createContainer([projectsProvider]);
    await settle();
    expect(container.read(projectsProvider).loaded, isTrue);
    expect(ids(container.read(projectsProvider).data), ['a', 'b', 'c']);
    final initial = rust.callCount(_list);
    expect(initial, greaterThanOrEqualTo(1));

    await container.read(workspacesProvider.notifier).switchWorkspace('w2');
    await settle();
    expect(rust.callCount(_list), initial + 1);

    rust.emit(fakeEvent(AppEventKind.projectScanDone));
    await settle();
    expect(rust.callCount(_list), initial + 2);

    rust.emit(fakeEvent(AppEventKind.godotDownloadComplete, text: '4.4-stable'));
    await settle();
    expect(rust.callCount(_list), initial + 3);

    AppSignals.emit(projectHealthChangedSignal);
    await settle();
    expect(rust.callCount(_list), initial + 4);

    rust.emit(fakeEvent(AppEventKind.versionScanDone));
    await settle();
    expect(rust.callCount(_list), initial + 4);
  });

  test('keeps the load error and falls back to an empty list', () async {
    rust.on(_list, () async => throw StateError('corrupt'));
    final container = createContainer([projectsProvider]);
    await settle();
    expect(container.read(projectsProvider).error, contains('corrupt'));
    expect(container.read(projectsProvider).data, isEmpty);
  });

  test('scan progress follows the backend and clears 800 ms after completion', () async {
    final container = createContainer([projectScanProgressProvider]);
    rust.emit(fakeEvent(AppEventKind.projectScanProgress, scanProgress: const ScanProgress(current: 1, total: 3)));
    await settle();
    expect(container.read(projectScanProgressProvider), const ScanProgress(current: 1, total: 3));

    rust.emit(fakeEvent(AppEventKind.versionScanProgress, scanProgress: const ScanProgress(current: 9, total: 9)));
    rust.emit(fakeEvent(AppEventKind.projectScanProgress, scanProgress: const ScanProgress(current: 3, total: 3)));
    await settle();
    expect(container.read(projectScanProgressProvider), const ScanProgress(current: 3, total: 3));

    await Future<void>.delayed(scanProgressClearDelay - const Duration(milliseconds: 300));
    expect(container.read(projectScanProgressProvider), isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(container.read(projectScanProgressProvider), isNull);
  });

  group('optimistic updates', () {
    late bool fail;

    setUp(() {
      fail = false;
      rust.on('crateApiProjectsRemoveProject', ({required String id, required bool deleteFiles}) async {
        calls.add('remove:$id:$deleteFiles');
        if (fail) throw StateError('nope');
        server.removeWhere((p) => p.id == id);
      });
      rust.on('crateApiProjectsUpdateProject', ({required String id, required ProjectUpdate updates}) async {
        calls.add('update:$id:${updates.pinned}:${updates.category}:${updates.godotVersion}');
        if (fail) throw StateError('nope');
        return server.firstWhere((p) => p.id == id);
      });
      rust.on('crateApiProjectsReorderProjects', ({required List<String> orderedIds}) async {
        calls.add('reorder:${orderedIds.join(',')}');
        if (fail) throw StateError('nope');
      });
    });

    test('remove drops the project at once and rolls back by refetching on failure', () async {
      final container = createContainer([projectsProvider]);
      await settle();
      final notifier = container.read(projectsProvider.notifier);

      final removing = notifier.remove('a', true);
      expect(ids(container.read(projectsProvider).data), ['b', 'c']);
      await removing;
      expect(calls, ['remove:a:true']);

      fail = true;
      final before = rust.callCount(_list);
      final failing = notifier.remove('b', false);
      expect(ids(container.read(projectsProvider).data), ['c']);
      await expectLater(failing, throwsStateError);
      expect(rust.callCount(_list), before + 1);
      expect(ids(container.read(projectsProvider).data), ['b', 'c']);
    });

    test('setPinned and setCategory update in place and roll back on failure', () async {
      final container = createContainer([projectsProvider]);
      await settle();
      final notifier = container.read(projectsProvider.notifier);

      final pinning = notifier.setPinned('b', true);
      expect(container.read(projectsProvider).data[1].pinned, isTrue);
      await pinning;

      final categorizing = notifier.setCategory('c', 'tools');
      expect(container.read(projectsProvider).data[2].category, 'tools');
      await categorizing;

      await notifier.setCategory('c', '');
      expect(container.read(projectsProvider).data[2].category, isNull);
      expect(calls, ['update:b:true:null:null', 'update:c:null:tools:null', 'update:c:null::null']);

      fail = true;
      final failing = notifier.setPinned('a', true);
      expect(container.read(projectsProvider).data[0].pinned, isTrue);
      await expectLater(failing, throwsStateError);
      expect(container.read(projectsProvider).data[0].pinned, isFalse);

      final failingCategory = notifier.setCategory('a', 'art');
      expect(container.read(projectsProvider).data[0].category, 'art');
      await expectLater(failingCategory, throwsStateError);
      expect(container.read(projectsProvider).data[0].category, isNull);
    });

    test('updateTags only changes local state and updateVersion saves then refetches', () async {
      final container = createContainer([projectsProvider]);
      await settle();
      final notifier = container.read(projectsProvider.notifier);
      final before = rust.callCount(_list);

      await notifier.updateTags('a', ['jam']);
      expect(container.read(projectsProvider).data[0].tags, ['jam']);
      expect(calls, isEmpty);

      server[1] = project('b', sortOrder: 1);
      await notifier.updateVersion('b', '4.4-stable');
      expect(calls, ['update:b:null:null:4.4-stable']);
      expect(rust.callCount(_list), before + 1);
    });

    test('reorder applies the new sort order and refetches on failure', () async {
      final container = createContainer([projectsProvider]);
      await settle();
      final notifier = container.read(projectsProvider.notifier);

      final reordering = notifier.reorder(['c', 'a']);
      final data = container.read(projectsProvider).data;
      expect({for (final p in data) p.id: p.sortOrder}, {'a': 1, 'b': 1, 'c': 0});
      await reordering;
      expect(calls, ['reorder:c,a']);

      fail = true;
      final before = rust.callCount(_list);
      await expectLater(notifier.reorder(['b', 'a', 'c']), throwsStateError);
      expect(rust.callCount(_list), before + 1);
      expect({for (final p in container.read(projectsProvider).data) p.id: p.sortOrder}, {'a': 0, 'b': 1, 'c': 2});
    });

    test('moveProjects recategorizes and reorders, restoring the snapshot on failure', () async {
      final container = createContainer([projectsProvider]);
      await settle();
      final notifier = container.read(projectsProvider.notifier);

      await notifier.moveProjects(const [], 'x', const []);
      expect(calls, isEmpty);

      final moving = notifier.moveProjects(['a', 'b'], 'tools', ['b', 'c', 'a']);
      final data = container.read(projectsProvider).data;
      expect({for (final p in data) p.id: (p.category, p.sortOrder)}, {
        'a': ('tools', 2),
        'b': ('tools', 0),
        'c': (null, 1),
      });
      await moving;
      expect(calls, ['update:a:null:tools:null', 'update:b:null:tools:null', 'reorder:b,c,a']);

      calls.clear();
      fail = true;
      final failing = notifier.moveProjects(['c'], '', ['c']);
      expect(container.read(projectsProvider).data[2].category, isNull);
      await expectLater(failing, throwsStateError);
      expect(calls, ['update:c:null::null']);
      expect({for (final p in container.read(projectsProvider).data) p.id: p.category}, {
        'a': null,
        'b': null,
        'c': null,
      });
    });
  });

  test('a project copy keeps every untouched field', () {
    final source = project('z', name: 'Zed', category: 'art', pinned: true, sortOrder: 4, tags: const ['t']);
    final copy = copyProject(source);
    expect(copy, source);
    expect(copyProject(source, category: () => null).category, isNull);
    expect(backend.active, 'w1');
  });
}
