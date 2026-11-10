import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/state/app_version.dart';

import '../support/fake_rust.dart';

void main() {
  test('resolves the version from the loader', () async {
    final container = ProviderContainer(
      overrides: [appVersionLoaderProvider.overrideWithValue(() async => '1.2.3')],
    );
    addTearDown(container.dispose);
    expect(await container.read(appVersionProvider.future), '1.2.3');
  });

  test('a failing loader resolves to null', () async {
    final container = ProviderContainer(
      overrides: [appVersionLoaderProvider.overrideWithValue(() async => throw StateError('no version'))],
    );
    addTearDown(container.dispose);
    expect(await container.read(appVersionProvider.future), isNull);
  });

  test('defaults to the version the runner gave the core', () async {
    final rust = installFakeRust();
    rust.on('crateApiAppAppVersion', () => '0.1.0');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(appVersionProvider.future), '0.1.0');
    expect(rust.callCount('crateApiAppAppVersion'), 1);
  });
}
