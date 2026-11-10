import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/contributors.dart';

void main() {
  late MemoryUiPrefsBackend prefs;
  final now = DateTime.utc(2026, 11, 11, 12);

  void usePrefs([Map<String, String> values = const {}]) {
    prefs = MemoryUiPrefsBackend({...values});
    UiPrefsStore.instance = UiPrefsStore(prefs)..fill(values);
  }

  setUp(usePrefs);

  ProviderContainer container(ContributorsFetcher fetcher) {
    final c = ProviderContainer(
      overrides: [
        contributorsFetcherProvider.overrideWithValue(fetcher),
        contributorsClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  String cached(List<Contributor> data, DateTime at) => jsonEncode(
    jsonEncode({'data': [for (final c in data) c.toJson()], 'timestamp': at.millisecondsSinceEpoch}),
  );

  const ryko = Contributor(login: 'ryko', avatarUrl: 'https://a/ryko', contributions: 40);
  const bot = Contributor(login: 'dependabot[bot]', avatarUrl: 'https://a/bot', contributions: 3);

  test('fetches, drops dependabot, and caches with a timestamp', () async {
    var calls = 0;
    final c = container(() async {
      calls++;
      return [ryko, bot];
    });
    expect(c.read(contributorsProvider).loading, isTrue);
    await pumpEventQueue();
    expect(c.read(contributorsProvider), const ContributorsState(contributors: [ryko], loading: false));
    expect(calls, 1);
    await UiPrefsStore.instance.flush();
    final stored = jsonDecode(jsonDecode(prefs.values[contributorsCacheKey]!) as String) as Map<String, Object?>;
    expect(stored['timestamp'], now.millisecondsSinceEpoch);
    expect(stored['data'], [ryko.toJson()]);
  });

  test('a fresh cache skips the network', () async {
    usePrefs({contributorsCacheKey: cached([ryko], now.subtract(const Duration(hours: 23)))});
    var calls = 0;
    final c = container(() async {
      calls++;
      return const [];
    });
    expect(c.read(contributorsProvider), const ContributorsState(contributors: [ryko], loading: false));
    await pumpEventQueue();
    expect(calls, 0);
  });

  test('an expired cache refetches and a failure just stops loading', () async {
    usePrefs({contributorsCacheKey: cached([ryko], now.subtract(const Duration(hours: 25)))});
    final c = container(() async => throw StateError('rate limited'));
    expect(c.read(contributorsProvider).loading, isTrue);
    await pumpEventQueue();
    expect(c.read(contributorsProvider), const ContributorsState(contributors: [], loading: false));
  });

  test('parses the github payload shape', () {
    expect(
      Contributor.fromJson({'login': 'x', 'avatar_url': 'https://a/x', 'contributions': 2, 'type': 'User'}),
      const Contributor(login: 'x', avatarUrl: 'https://a/x', contributions: 2),
    );
  });
}
