import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/categories.dart';
import 'package:godothub/state/workspaces.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

const _list = 'crateApiCategoriesListCategories';

void main() {
  late FakeRustApi rust;
  late List<Category> server;
  late List<String> calls;
  late bool fail;

  setUp(() {
    rust = installFakeRust();
    CoreBackend(rust, active: 'w1');
    server = [category('a', sortOrder: 0), category('b', sortOrder: 1), category('c', sortOrder: 2)];
    calls = [];
    fail = false;
    rust.on(_list, () async => List<Category>.of(server));
    rust.on('crateApiCategoriesCreateCategory', ({required String name, String? color}) async {
      calls.add('create:$name:$color');
      final created = category('n');
      server.add(created);
      return created;
    });
    rust.on('crateApiCategoriesRenameCategory', ({required String id, required String name}) async {
      calls.add('rename:$id:$name');
      return category(id);
    });
    rust.on('crateApiCategoriesUpdateCategory', ({required String id, String? name, String? color, bool? hidden}) async {
      calls.add('update:$id:$name:$color:$hidden');
      if (fail) throw StateError('nope');
      return category(id, hidden: hidden ?? false);
    });
    rust.on('crateApiCategoriesDeleteCategory', ({required String id}) async {
      calls.add('delete:$id');
      server.removeWhere((c) => c.id == id);
    });
    rust.on('crateApiCategoriesReorderCategories', ({required List<String> orderedIds}) async {
      calls.add('reorder:${orderedIds.join(',')}');
      if (fail) throw StateError('nope');
    });
    rust.on('crateApiCategoriesAddCategoryFolder', ({required String id, required String folder}) async {
      calls.add('add:$id:$folder');
      return category(id);
    });
    rust.on('crateApiCategoriesRemoveCategoryFolder', ({required String id, required String folder}) async {
      calls.add('removeFolder:$id:$folder');
      return category(id);
    });
  });

  List<String> ids(List<Category> categories) => [for (final c in categories) c.id];

  test('loads and refetches when the active workspace changes', () async {
    final container = createContainer([categoriesProvider]);
    await settle();
    expect(container.read(categoriesProvider).loaded, isTrue);
    expect(ids(container.read(categoriesProvider).data), ['a', 'b', 'c']);
    final before = rust.callCount(_list);

    await container.read(workspacesProvider.notifier).switchWorkspace('w2');
    await settle();
    expect(rust.callCount(_list), before + 1);
  });

  test('a failed load falls back to an empty list without an error', () async {
    rust.on(_list, () async => throw StateError('offline'));
    final container = createContainer([categoriesProvider]);
    await settle();
    expect(container.read(categoriesProvider).data, isEmpty);
    expect(container.read(categoriesProvider).error, isNull);
  });

  test('mutations call the backend and refetch', () async {
    final container = createContainer([categoriesProvider]);
    await settle();
    final notifier = container.read(categoriesProvider.notifier);
    final before = rust.callCount(_list);

    expect((await notifier.create('New', '#123')).id, 'n');
    expect(ids(container.read(categoriesProvider).data), ['a', 'b', 'c', 'n']);
    await notifier.rename('a', 'Art');
    expect((await notifier.update('b', 'Bee', '#000', true)).hidden, isTrue);
    await notifier.remove('n');
    expect(ids(container.read(categoriesProvider).data), ['a', 'b', 'c']);
    await notifier.assignFolder('a', '/x');
    await notifier.unassignFolder('a', '/x');

    expect(calls, [
      'create:New:#123',
      'rename:a:Art',
      'update:b:Bee:#000:true',
      'delete:n',
      'add:a:/x',
      'removeFolder:a:/x',
    ]);
    expect(rust.callCount(_list), before + 6);
  });

  test('setHidden is optimistic and always refetches, rethrowing failures', () async {
    final container = createContainer([categoriesProvider]);
    await settle();
    final notifier = container.read(categoriesProvider.notifier);
    final before = rust.callCount(_list);

    final hiding = notifier.setHidden('b', true);
    expect(container.read(categoriesProvider).data[1].hidden, isTrue);
    await hiding;
    expect(calls, ['update:b:null:null:true']);
    expect(rust.callCount(_list), before + 1);
    expect(container.read(categoriesProvider).data[1].hidden, isFalse);

    fail = true;
    final failing = notifier.setHidden('c', true);
    expect(container.read(categoriesProvider).data[2].hidden, isTrue);
    await expectLater(failing, throwsStateError);
    expect(rust.callCount(_list), before + 2);
    expect(container.read(categoriesProvider).data[2].hidden, isFalse);
  });

  test('reorder sorts optimistically and keeps the local order when the save fails', () async {
    final container = createContainer([categoriesProvider]);
    await settle();
    final notifier = container.read(categoriesProvider.notifier);

    final reordering = notifier.reorder(['c', 'a', 'b']);
    expect(ids(container.read(categoriesProvider).data), ['c', 'a', 'b']);
    await reordering;

    fail = true;
    final before = rust.callCount(_list);
    await expectLater(notifier.reorder(['b', 'c']), throwsStateError);
    expect(ids(container.read(categoriesProvider).data), ['a', 'b', 'c']);
    expect(rust.callCount(_list), before);
    expect(calls, ['reorder:c,a,b', 'reorder:b,c']);
  });
}
