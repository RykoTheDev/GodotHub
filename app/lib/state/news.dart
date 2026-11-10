import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/news.dart';
import '../logic/features.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';
import 'changelog.dart';
import 'settings.dart';

const newsPageSize = 10;
const newsSeenKey = 'news_seen_ids';
const viewChangedSignal = 'app:view-changed';

@immutable
class NewsFeed {
  const NewsFeed({this.all = const [], this.fromCache = false, this.visibleCount = newsPageSize});

  final List<NewsItem> all;
  final bool fromCache;
  final int visibleCount;

  List<NewsItem> get items => all.take(visibleCount).toList(growable: false);

  bool get hasMore => visibleCount < all.length;

  int get total => all.length;

  NewsFeed copyWith({int? visibleCount}) =>
      NewsFeed(all: all, fromCache: fromCache, visibleCount: visibleCount ?? this.visibleCount);

  @override
  bool operator ==(Object other) =>
      other is NewsFeed &&
      listEquals(other.all, all) &&
      other.fromCache == fromCache &&
      other.visibleCount == visibleCount;

  @override
  int get hashCode => Object.hash(Object.hashAll(all), fromCache, visibleCount);
}

final newsProvider = NotifierProvider<NewsNotifier, ApiData<NewsFeed>>(NewsNotifier.new);

class NewsNotifier extends ApiDataNotifier<NewsFeed> {
  bool _force = false;

  @override
  NewsFeed get initial => const NewsFeed();

  @override
  bool get keepsError => true;

  @override
  Future<NewsFeed> fetch() async {
    final force = _force;
    _force = false;
    final response = await NewsApi.fetch(force);
    return NewsFeed(all: response.items, fromCache: response.fromCache);
  }

  Future<void> reload() {
    _force = true;
    return refresh();
  }

  void showMore() => setData((feed) => feed.copyWith(visibleCount: math.min(feed.visibleCount + newsPageSize, feed.total)));
}

final newsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider).value;
  return settings != null && isFeatureEnabled(settings, GhFeatureId.news.id);
});

final currentViewProvider = NotifierProvider<CurrentViewNotifier, String?>(CurrentViewNotifier.new);

class CurrentViewNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.listenSignal(viewChangedSignal, (signal) {
      final detail = signal.detail;
      if (detail is String) state = detail;
    });
    return null;
  }
}

final newsBadgeItemsProvider = NotifierProvider<NewsBadgeItemsNotifier, ApiData<List<NewsItem>>>(NewsBadgeItemsNotifier.new);

class NewsBadgeItemsNotifier extends ApiDataNotifier<List<NewsItem>> {
  bool _enabled = false;

  @override
  List<NewsItem> get initial => const [];

  @override
  void setup() => _enabled = ref.watch(newsEnabledProvider);

  @override
  Future<List<NewsItem>> fetch() async => _enabled ? (await NewsApi.fetch()).items : const [];
}

final newsBadgeProvider = NotifierProvider<NewsBadgeNotifier, int>(NewsBadgeNotifier.new);

class NewsBadgeNotifier extends Notifier<int> {
  List<String>? _seen;
  bool _read = false;

  List<String>? get seenIds => _seen;

  @override
  int build() {
    if (!_read) {
      _read = true;
      _seen = readSeenIds(newsSeenKey);
    }
    final items = ref.watch(newsBadgeItemsProvider).data;
    final viewing = ref.watch(currentViewProvider) == 'news';
    if (items.isNotEmpty && (_seen == null || (viewing && _unread(items) > 0))) {
      _markSeen(items);
    }
    return _unread(items);
  }

  int _unread(List<NewsItem> items) {
    final seen = _seen;
    return seen == null ? 0 : items.where((item) => !seen.contains(item.id)).length;
  }

  void _markSeen(List<NewsItem> items) {
    if (items.isEmpty) return;
    final ids = [for (final item in items) item.id];
    _seen = ids;
    writeSeenIds(newsSeenKey, ids);
  }

  void markSeen() {
    final items = ref.read(newsBadgeItemsProvider).data;
    _markSeen(items);
    state = _unread(items);
  }
}
