import 'package:flutter/foundation.dart';

import '../src/rust/api/news.dart' as rust;
import '../src/rust/api/types.dart' as types;

const int _newsTtlMs = 15 * 60 * 1000;

final class _NewsCacheEntry {
  _NewsCacheEntry(this.at, this.request);

  final int at;
  final Future<types.NewsResponse> request;
}

_NewsCacheEntry? _cached;

abstract final class NewsApi {
  @visibleForTesting
  static void debugResetCache() => _cached = null;

  static Future<types.NewsResponse> fetch([bool force = false]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = _cached;
    if (!force && current != null && now - current.at < _newsTtlMs) return current.request;
    final request = rust.fetchGodotNews();
    final entry = _NewsCacheEntry(now, request);
    _cached = entry;
    request.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_cached, entry)) _cached = null;
      },
    );
    return request;
  }
}
