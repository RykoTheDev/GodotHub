import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/news.dart';

import '../support/fake_rust.dart';

NewsItem item(int i) => NewsItem(id: 'n$i', title: 'News $i', link: 'https://example.com/$i');

void main() {
  late FakeRustApi rust;

  setUp(() => rust = installFakeRust());

  test('loads a page, shows more, and reload forces past the api cache', () async {
    var fail = false;
    var fromCache = true;
    rust.on('crateApiNewsFetchGodotNews', () async {
      if (fail) throw StateError('offline');
      return NewsResponse(items: [for (var i = 0; i < 25; i++) item(i)], fromCache: fromCache);
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(newsProvider, (_, _) {});
    addTearDown(sub.close);
    expect(c.read(newsProvider).loading, isTrue);
    await pumpEventQueue();

    var feed = c.read(newsProvider).data;
    expect(feed.items, hasLength(newsPageSize));
    expect(feed.total, 25);
    expect(feed.hasMore, isTrue);
    expect(feed.fromCache, isTrue);

    c.read(newsProvider.notifier).showMore();
    c.read(newsProvider.notifier).showMore();
    feed = c.read(newsProvider).data;
    expect(feed.items, hasLength(25));
    expect(feed.hasMore, isFalse);

    await c.read(newsProvider.notifier).refresh();
    expect(rust.callCount('crateApiNewsFetchGodotNews'), 1);
    expect(c.read(newsProvider).data.items, hasLength(newsPageSize));

    fromCache = false;
    await c.read(newsProvider.notifier).reload();
    expect(rust.callCount('crateApiNewsFetchGodotNews'), 2);
    feed = c.read(newsProvider).data;
    expect(feed.items, hasLength(newsPageSize));
    expect(feed.fromCache, isFalse);

    fail = true;
    await c.read(newsProvider.notifier).reload();
    expect(c.read(newsProvider).error, contains('offline'));
    expect(c.read(newsProvider).data.total, 0);
  });
}
