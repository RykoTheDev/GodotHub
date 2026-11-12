import 'dart:async';

import 'package:flutter/foundation.dart';

import '../src/rust/api/types.dart';

const assetSearchCacheTtlMs = 120000;

final _responseCache = <String, ({int at, Future<AssetLibraryResponse> future})>{};

Future<AssetLibraryResponse> cachedAssetSearch(String key, Future<AssetLibraryResponse> Function() fn, {int Function()? now}) {
  final clock = now ?? () => DateTime.now().millisecondsSinceEpoch;
  final hit = _responseCache[key];
  if (hit != null && clock() - hit.at < assetSearchCacheTtlMs) {
    return hit.future;
  }
  final future = Future.sync(fn);
  unawaited(future.then<void>((_) {}, onError: (Object _) => _responseCache.remove(key)));
  _responseCache[key] = (at: clock(), future: future);
  return future;
}

@visibleForTesting
void clearAssetSearchCache() => _responseCache.clear();
