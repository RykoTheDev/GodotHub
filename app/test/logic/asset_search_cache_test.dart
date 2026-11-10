import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/asset_search_cache.dart';
import 'package:godothub/src/rust/api/types.dart';

const response = AssetLibraryResponse(assets: [], page: 0, pages: 1, total: 0);

void main() {
  setUp(clearAssetSearchCache);

  test('returns the cached future within the TTL and refetches after it', () async {
    var clock = 1000;
    var calls = 0;
    Future<AssetLibraryResponse> fetch() async {
      calls++;
      return response;
    }

    final first = cachedAssetSearch('q', fetch, now: () => clock);
    clock += assetSearchCacheTtlMs - 1;
    final second = cachedAssetSearch('q', fetch, now: () => clock);
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    clock += 1;
    final third = cachedAssetSearch('q', fetch, now: () => clock);
    expect(identical(first, third), isFalse);
    expect(calls, 2);
    expect(await third, response);
  });

  test('keys are independent', () {
    var calls = 0;
    Future<AssetLibraryResponse> fetch() async {
      calls++;
      return response;
    }

    cachedAssetSearch('a', fetch, now: () => 0);
    cachedAssetSearch('b', fetch, now: () => 0);
    expect(calls, 2);
  });

  test('a failed search is evicted so the next call retries', () async {
    var calls = 0;
    Future<AssetLibraryResponse> fail() async {
      calls++;
      throw StateError('offline');
    }

    await expectLater(cachedAssetSearch('q', fail, now: () => 0), throwsStateError);
    await Future<void>.delayed(Duration.zero);
    await expectLater(cachedAssetSearch('q', fail, now: () => 0), throwsStateError);
    expect(calls, 2);
  });

  test('synchronous throws become failed futures', () async {
    await expectLater(cachedAssetSearch('s', () => throw StateError('boom'), now: () => 0), throwsStateError);
  });
}
