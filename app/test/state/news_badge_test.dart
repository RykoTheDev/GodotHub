import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/news.dart';
import 'package:godothub/state/settings.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';

NewsItem item(String id) => NewsItem(id: id, title: id, link: 'https://example.com/$id');

void main() {
  late FakeRustApi rust;
  late MemoryUiPrefsBackend prefs;

  void usePrefs([Map<String, String> values = const {}]) {
    prefs = MemoryUiPrefsBackend({...values});
    UiPrefsStore.instance = UiPrefsStore(prefs)..fill(values);
  }

  setUp(() {
    rust = installFakeRust();
    usePrefs();
    rust.on('crateApiNewsFetchGodotNews', () async => NewsResponse(items: [item('a'), item('b')], fromCache: false));
  });

  test('stays at zero and skips the fetch while the news feature is disabled', () async {
    final c = ProviderContainer(
      overrides: [fakeSettings(() => copySettings(defaultSettings, disabledFeatures: const ['news']))],
    );
    addTearDown(c.dispose);
    final sub = c.listen(newsBadgeProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(c.read(newsBadgeProvider), 0);
    expect(rust.callCount('crateApiNewsFetchGodotNews'), 0);
  });

  test('first load marks everything seen and persists the ids', () async {
    final c = ProviderContainer(overrides: [fakeSettings(() => defaultSettings)]);
    addTearDown(c.dispose);
    final sub = c.listen(newsBadgeProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(c.read(newsBadgeProvider), 0);
    await UiPrefsStore.instance.flush();
    expect(prefs.values[newsSeenKey], '"[\\"a\\",\\"b\\"]"');
  });

  test('unread items clear when the news view becomes active and when the feature turns off', () async {
    usePrefs({newsSeenKey: '"[\\"a\\"]"'});
    final c = ProviderContainer(overrides: [fakeSettings(() => defaultSettings)]);
    addTearDown(c.dispose);
    final sub = c.listen(newsBadgeProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(c.read(newsBadgeProvider), 1);

    AppSignals.emit(viewChangedSignal, 'projects');
    await pumpEventQueue();
    expect(c.read(currentViewProvider), 'projects');
    expect(c.read(newsBadgeProvider), 1);

    AppSignals.emit(viewChangedSignal, 'news');
    await pumpEventQueue();
    expect(c.read(newsBadgeProvider), 0);
    await UiPrefsStore.instance.flush();
    expect(prefs.values[newsSeenKey], '"[\\"a\\",\\"b\\"]"');

    await c.read(settingsProvider.notifier).save(copySettings(defaultSettings, disabledFeatures: const ['news']));
    await pumpEventQueue();
    expect(c.read(newsBadgeItemsProvider).data, isEmpty);
    expect(c.read(newsBadgeProvider), 0);
  });
}
