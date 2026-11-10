import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/projects.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/project_resolution_epoch.dart';
import 'package:godothub/state/project_tile_data.dart';

import '../support/fake_rust.dart';
import 'data_fixtures.dart';

const _icon = 'crateApiProjectsGetProjectIcon';
const _name = 'crateApiProjectsGetProjectName';
const _size = 'crateApiProjectsGetProjectSize';

ProjectSizeInfo sizeInfo(int bytes) =>
    ProjectSizeInfo(totalSize: BigInt.from(bytes), categories: const [], fileCount: BigInt.one);

void main() {
  late FakeRustApi rust;
  late bool failSize;
  late int bytes;

  setUp(() {
    rust = installFakeRust();
    ProjectsApi.clearIconCache();
    ProjectsApi.clearNameCache();
    debugResetProjectTileSizes();
    failSize = false;
    bytes = 2048;
    rust.on(_icon, ({required String path}) async => 'icon:$path');
    rust.on(_name, ({required String path}) async => 'Name of $path');
    rust.on(_size, ({required String path}) async {
      if (failSize) throw StateError('locked');
      return sizeInfo(bytes);
    });
  });

  test('resolves the icon, name and lazily the size, reusing caches', () async {
    final request = (path: '/p', showSize: true, preview: false);
    final container = createContainer([projectTileDataProvider(request)]);
    expect(container.read(projectTileDataProvider(request)), const ProjectTileData());
    await settle();

    final data = container.read(projectTileDataProvider(request));
    expect(data.icon, 'icon:/p');
    expect(data.displayName('Fallback'), 'Name of /p');
    expect(data.size, 2048);
    expect(data.sizeFailed, isFalse);

    final other = createContainer([projectTileDataProvider(request)]);
    expect(other.read(projectTileDataProvider(request)), data);
    await settle();
    expect(rust.callCount(_icon), 1);
    expect(rust.callCount(_name), 1);
    expect(rust.callCount(_size), 1);
  });

  test('previews never fetch and hidden sizes are not loaded', () async {
    final container = createContainer([
      projectTileDataProvider((path: '/preview', showSize: true, preview: true)),
      projectTileDataProvider((path: '/nosize', showSize: false, preview: false)),
    ]);
    await settle();
    expect(container.read(projectTileDataProvider((path: '/preview', showSize: true, preview: true))).icon, isNull);
    expect(
      container.read(projectTileDataProvider((path: '/preview', showSize: true, preview: true))).displayName('Fallback'),
      'Fallback',
    );
    expect(container.read(projectTileDataProvider((path: '/nosize', showSize: false, preview: false))).size, isNull);
    expect(rust.callCount(_icon), 1);
    expect(rust.callCount(_size), 0);
  });

  test('a failed size load is reported and retried by the next consumer', () async {
    failSize = true;
    final request = (path: '/p', showSize: true, preview: false);
    final container = createContainer([projectTileDataProvider(request)]);
    await settle();
    expect(container.read(projectTileDataProvider(request)).sizeFailed, isTrue);
    expect(container.read(projectTileDataProvider(request)).size, isNull);

    failSize = false;
    final retry = createContainer([projectTileDataProvider(request)]);
    await settle();
    expect(retry.read(projectTileDataProvider(request)).size, 2048);
    expect(rust.callCount(_size), 2);
  });

  test('clearing the icon cache bumps the resolution epoch and refetches everything', () async {
    final request = (path: '/p', showSize: true, preview: false);
    final container = createContainer([projectTileDataProvider(request), projectResolutionEpochProvider]);
    await settle();
    final epoch = container.read(projectResolutionEpochProvider);

    bytes = 4096;
    rust.on(_icon, ({required String path}) async => 'new-icon:$path');
    ProjectsApi.clearIconCache();
    expect(container.read(projectResolutionEpochProvider), epoch + 1);
    await settle();

    final data = container.read(projectTileDataProvider(request));
    expect(data.icon, 'new-icon:/p');
    expect(data.size, 4096);
    expect(rust.callCount(_icon), 2);
    expect(rust.callCount(_size), 2);
  });
}
