import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/palette.dart';
import 'package:godothub/logic/pending_save.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/providers.dart' as legacy;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/settings.dart';
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

  test('is the provider src/providers.dart exposes', () {
    expect(identical(legacy.settingsProvider, settingsProvider), isTrue);
  });

  test('waits for the active workspace, then loads and reloads on workspace switches', () async {
    final backend = CoreBackend(rust, active: 'w1', settings: settingsWith(language: 'fr-FR'));
    final container = createContainer([settingsProvider]);

    expect(container.read(settingsProvider).isLoading, isTrue);
    expect(container.read(settingsLoadedProvider), isFalse);
    await settle();
    expect(container.read(settingsProvider).value?.language, 'fr-FR');
    expect(container.read(settingsLoadedProvider), isTrue);
    expect(container.read(settingsProvider.notifier).settingsWorkspaceId, 'w1');
    expect(rust.callCount('crateApiSettingsGetSettings'), 1);

    backend.settings = settingsWith(language: 'ja-JP');
    await container.read(workspacesProvider.notifier).switchWorkspace('w2');
    expect(container.read(settingsProvider).value?.language, 'fr-FR');
    await settle();
    expect(container.read(settingsProvider).value?.language, 'ja-JP');
    expect(container.read(settingsProvider.notifier).settingsWorkspaceId, 'w2');
    expect(rust.callCount('crateApiSettingsGetSettings'), 2);
  });

  test('update is optimistic and re-applies the settings the backend returns', () async {
    final backend = CoreBackend(rust, active: 'w1');
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) async {
      backend.saved.add(settings);
      return copySettings(settings, tooltipDelay: 999);
    });
    final container = createContainer([settingsProvider]);
    await settle();

    final next = settingsWith(language: 'ru-RU');
    final saving = container.read(settingsProvider.notifier).save(next);
    expect(container.read(settingsProvider).value, same(next));
    expect(await saving, same(next));
    expect(backend.saved, [next]);
    expect(container.read(settingsProvider).value?.tooltipDelay, 999);
    expect(container.read(settingsProvider).value?.language, 'ru-RU');
  });

  test('save applies a copied settings value', () async {
    final backend = CoreBackend(rust, active: 'w1');
    final container = createContainer([settingsProvider]);
    await settle();

    await container.read(settingsProvider.notifier).save(copySettings(container.read(settingsProvider).value!, language: 'vi-VN'));
    expect(backend.saved.single.language, 'vi-VN');
    expect(container.read(settingsProvider).value?.language, 'vi-VN');
  });

  test('updates made while a save is in flight are debounced into one save of the latest value', () async {
    final backend = CoreBackend(rust, active: 'w1');
    final gates = <Completer<AppSettings>>[];
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) {
      backend.saved.add(settings);
      final gate = Completer<AppSettings>();
      gates.add(gate);
      return gate.future;
    });
    final container = createContainer([settingsProvider]);
    await settle();
    final notifier = container.read(settingsProvider.notifier);

    final first = settingsWith(language: 'fr-FR');
    final firstSave = notifier.save(first);
    await settle();
    expect(backend.saved, [first]);

    final second = settingsWith(language: 'es-MX');
    final third = settingsWith(language: 'pt-BR');
    expect(await notifier.save(second), same(second));
    expect(await notifier.save(third), same(third));
    expect(container.read(settingsProvider).value, same(third));
    expect(backend.saved, [first]);

    gates[0].complete(copySettings(first, tooltipDelay: 1));
    await firstSave;
    expect(container.read(settingsProvider).value, same(third));

    await Future<void>.delayed(const Duration(milliseconds: saveDebounceMs ~/ 2));
    expect(backend.saved, [first]);
    await Future<void>.delayed(const Duration(milliseconds: saveDebounceMs));
    expect(backend.saved, [first, third]);

    gates[1].complete(copySettings(third, tooltipDelay: 2));
    await settle();
    expect(container.read(settingsProvider).value?.tooltipDelay, 2);
  });

  test('registers a pending save so workspace switches flush the debounced change', () async {
    final backend = CoreBackend(rust, active: 'w1');
    final gates = <Completer<AppSettings>>[];
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) {
      backend.saved.add(settings);
      final gate = Completer<AppSettings>();
      gates.add(gate);
      return gate.future;
    });
    final container = createContainer([settingsProvider]);
    await settle();
    final notifier = container.read(settingsProvider.notifier);

    final first = settingsWith(language: 'fr-FR');
    unawaited(notifier.save(first));
    await settle();
    final second = settingsWith(language: 'ar-MA');
    await notifier.save(second);

    final flushed = flushPendingSave();
    gates[0].complete(first);
    await settle();
    expect(backend.saved, [first, second]);
    gates[1].complete(second);
    await flushed;
    expect(container.read(settingsProvider).value, same(second));
  });

  test('a workspace change drops a debounced save that was not flushed', () async {
    final backend = CoreBackend(rust, active: 'w1');
    final gates = <Completer<AppSettings>>[];
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) {
      backend.saved.add(settings);
      final gate = Completer<AppSettings>();
      gates.add(gate);
      return gate.future;
    });
    final container = createContainer([settingsProvider]);
    await settle();
    final notifier = container.read(settingsProvider.notifier);

    final first = settingsWith(language: 'fr-FR');
    final firstSave = notifier.save(first);
    await settle();
    await notifier.save(settingsWith(language: 'es-MX'));

    backend.active = 'w2';
    await container.read(workspacesProvider.notifier).refresh();
    await settle();
    gates[0].complete(first);
    await firstSave;
    await Future<void>.delayed(const Duration(milliseconds: saveDebounceMs * 2));
    expect(backend.saved, [first]);
  });

  test('a failed save keeps the optimistic value and rethrows', () async {
    CoreBackend(rust, active: 'w1');
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) async => throw StateError('disk full'));
    final container = createContainer([settingsProvider]);
    await settle();

    final next = settingsWith(language: 'zh-CN');
    await expectLater(container.read(settingsProvider.notifier).save(next), throwsStateError);
    expect(container.read(settingsProvider).value, same(next));
  });

  test('resetToDefaults waits for the in-flight save and applies the backend defaults', () async {
    final backend = CoreBackend(rust, active: 'w1', settings: settingsWith(language: 'fr-FR'));
    final gate = Completer<AppSettings>();
    final order = <String>[];
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) {
      backend.saved.add(settings);
      return gate.future.then((value) {
        order.add('saved');
        return value;
      });
    });
    rust.on('crateApiSettingsResetSettings', () async {
      order.add('reset');
      return defaultSettings;
    });
    final container = createContainer([settingsProvider]);
    await settle();
    final notifier = container.read(settingsProvider.notifier);

    final first = settingsWith(language: 'ja-JP');
    unawaited(notifier.save(first));
    await settle();
    await notifier.save(settingsWith(language: 'ru-RU'));

    final reset = notifier.resetToDefaults();
    await settle();
    expect(order, isEmpty);
    gate.complete(first);
    expect(await reset, same(defaultSettings));
    expect(order, ['saved', 'reset']);
    expect(container.read(settingsProvider).value, same(defaultSettings));
    await Future<void>.delayed(const Duration(milliseconds: saveDebounceMs * 2));
    expect(backend.saved, [first]);
  });

  testWidgets('a system theme follows the OS brightness by swapping a clashing custom background', (tester) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    final backend = CoreBackend(rust, active: 'w1', settings: settingsWith(themeMode: 'system'));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(settingsProvider, (_, _) {});
    addTearDown(sub.close);

    Future<void> flush() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: saveDebounceMs + 50));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }

    await flush();
    expect(container.read(settingsProvider).value?.backgroundColor, defaultBackground);
    expect(backend.saved, isEmpty);

    dispatcher.platformBrightnessTestValue = Brightness.light;
    await flush();
    expect(backend.saved.single.backgroundColor, defaultBackgroundLight);
    expect(container.read(settingsProvider).value?.backgroundColor, defaultBackgroundLight);

    await container.read(settingsProvider.notifier).save(settingsWith(themeMode: 'system'));
    await flush();
    expect(backend.saved.map((s) => s.backgroundColor), [defaultBackgroundLight, defaultBackground, defaultBackgroundLight]);

    await container.read(settingsProvider.notifier).save(settingsWith(themeMode: 'dark'));
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await flush();
    expect(backend.saved.length, 4);
  });
}
