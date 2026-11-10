import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/pending_save.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/workspaces.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

void main() {
  late FakeRustApi rust;

  setUp(() async {
    rust = installFakeRust();
    registerPendingSave(() async {});
    await flushPendingSave();
  });

  test('loads the workspaces and exposes the active id', () async {
    rust.on('crateApiWorkspaceListWorkspaces', () async => workspacesState('w1'));
    final container = createContainer([workspacesProvider, activeWorkspaceIdProvider]);

    expect(container.read(workspacesProvider).loaded, isFalse);
    expect(container.read(activeWorkspaceIdProvider), '');
    await settle();

    final view = container.read(workspacesProvider);
    expect(view.loaded, isTrue);
    expect(view.workspaces.map((w) => w.id), ['w1', 'w2']);
    expect(container.read(activeWorkspaceIdProvider), 'w1');
  });

  test('a failed first load still marks the workspaces loaded', () async {
    rust.on('crateApiWorkspaceListWorkspaces', () async => throw StateError('offline'));
    final container = createContainer([workspacesProvider]);
    await settle();

    expect(container.read(workspacesProvider).loaded, isTrue);
    expect(container.read(workspacesProvider).workspaces, isEmpty);
    expect(container.read(activeWorkspaceIdProvider), '');
  });

  test('switching flushes the pending save first and ignores the active workspace', () async {
    final order = <String>[];
    rust.on('crateApiWorkspaceListWorkspaces', () async => workspacesState('w1'));
    rust.on('crateApiWorkspaceSwitchWorkspace', ({required String id}) async {
      order.add('switch:$id');
      return workspacesState(id);
    });
    final container = createContainer([workspacesProvider]);
    await settle();

    registerPendingSave(() async => order.add('flush'));
    await container.read(workspacesProvider.notifier).switchWorkspace('w1');
    expect(order, isEmpty);

    await container.read(workspacesProvider.notifier).switchWorkspace('w2');
    expect(order, ['flush', 'switch:w2']);
    expect(container.read(activeWorkspaceIdProvider), 'w2');
  });

  test('create, rename, restyle and delete apply the returned state', () async {
    final order = <String>[];
    rust.on('crateApiWorkspaceListWorkspaces', () async => workspacesState('w1'));
    rust.on(
      'crateApiWorkspaceCreateWorkspace',
      ({required String name, required String icon, required String color, String? copySettingsFrom}) async {
        order.add('create:$name:$copySettingsFrom');
        return workspacesState('w3', ['w1', 'w2', 'w3']);
      },
    );
    rust.on('crateApiWorkspaceUpdateWorkspace', ({required String id, String? name, String? icon, String? color}) async {
      order.add('update:$id:$name:$icon:$color');
      return WorkspacesState(
        workspaces: [workspace('w1', name: name ?? 'Workspace'), workspace('w2')],
        activeId: 'w1',
      );
    });
    rust.on('crateApiWorkspaceDeleteWorkspace', ({required String id}) async {
      order.add('delete:$id');
      return workspacesState('w1', ['w1']);
    });
    final container = createContainer([workspacesProvider]);
    await settle();
    final notifier = container.read(workspacesProvider.notifier);

    registerPendingSave(() async => order.add('flush'));
    await notifier.createWorkspace('Next', 'star', '#000', 'w1');
    expect(container.read(activeWorkspaceIdProvider), 'w3');

    await notifier.renameWorkspace('w1', 'Renamed');
    expect(container.read(workspacesProvider).workspaces.first.name, 'Renamed');

    await notifier.updateWorkspaceStyle('w1', 'gamepad', '#fff');

    registerPendingSave(() async => order.add('flush'));
    await notifier.deleteWorkspace('w2');
    expect(container.read(workspacesProvider).workspaces.map((w) => w.id), ['w1']);

    expect(order, [
      'flush',
      'create:Next:w1',
      'update:w1:Renamed:null:null',
      'update:w1:null:gamepad:#fff',
      'flush',
      'delete:w2',
    ]);
  });

  test('refresh reloads the list', () async {
    var active = 'w1';
    rust.on('crateApiWorkspaceListWorkspaces', () async => workspacesState(active));
    final container = createContainer([workspacesProvider]);
    await settle();
    active = 'w2';
    await container.read(workspacesProvider.notifier).refresh();
    expect(container.read(activeWorkspaceIdProvider), 'w2');
    expect(rust.callCount('crateApiWorkspaceListWorkspaces'), 2);
  });
}
