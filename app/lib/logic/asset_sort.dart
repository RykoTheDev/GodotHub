import '../src/rust/api/types.dart';
import 'locale.dart';
import 'project_sort.dart';

enum AssetSortKey {
  relevance('relevance'),
  updatedNew('updated_new'),
  updatedOld('updated_old'),
  nameAz('name_az'),
  nameZa('name_za'),
  ratingHigh('rating_high'),
  ratingLow('rating_low'),
  licenseAz('license_az'),
  licenseZa('license_za');

  const AssetSortKey(this.id);

  final String id;

  static AssetSortKey? fromId(String id) {
    for (final key in values) {
      if (key.id == id) return key;
    }
    return null;
  }
}

enum AssetSource { all, library, store }

({String? sort, bool reverse}) assetSortParams(AssetSortKey key) => switch (key) {
  AssetSortKey.updatedNew => (sort: 'updated', reverse: false),
  AssetSortKey.updatedOld => (sort: 'updated', reverse: true),
  AssetSortKey.nameAz => (sort: 'name', reverse: false),
  AssetSortKey.nameZa => (sort: 'name', reverse: true),
  AssetSortKey.ratingHigh => (sort: 'rating', reverse: true),
  AssetSortKey.ratingLow => (sort: 'rating', reverse: false),
  AssetSortKey.licenseAz => (sort: 'cost', reverse: false),
  AssetSortKey.licenseZa => (sort: 'cost', reverse: true),
  AssetSortKey.relevance => (sort: null, reverse: false),
};

int _relevanceScore(AssetLibraryAsset asset, String query) {
  final title = asset.title.toLowerCase();
  final author = asset.author.toLowerCase();
  final category = asset.category.toLowerCase();
  final description = (asset.description ?? '').toLowerCase();
  var score = 0;
  if (title == query) {
    score += 100;
  } else if (title.startsWith(query)) {
    score += 80;
  } else if (title.contains(query)) {
    score += 60;
  }
  if (author.contains(query)) score += 25;
  if (category.contains(query)) score += 15;
  if (description.contains(query)) score += 10;
  return score;
}

int _tieBreak(AssetLibraryAsset a, AssetLibraryAsset b) {
  final byTitle = ghLocaleCompare(a.title, b.title);
  if (byTitle != 0) return byTitle;
  return ghLocaleCompare(a.assetId, b.assetId);
}

List<AssetLibraryAsset> rankByRelevance(List<AssetLibraryAsset> assets, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return stableSorted(assets, _tieBreak);
  final scores = {for (final asset in assets) asset: _relevanceScore(asset, q)};
  return stableSorted(assets, (a, b) {
    final byScore = scores[b]! - scores[a]!;
    return byScore != 0 ? byScore : _tieBreak(a, b);
  });
}

String storeServerSort(AssetSortKey key) => switch (key) {
  AssetSortKey.updatedNew => 'updated_desc',
  AssetSortKey.updatedOld => 'updated_asc',
  AssetSortKey.ratingHigh => 'reviews_desc',
  AssetSortKey.ratingLow => 'reviews_asc',
  _ => 'relevance',
};

List<AssetSortKey> sortKeysForSource(AssetSource source) {
  const base = [
    AssetSortKey.relevance,
    AssetSortKey.nameAz,
    AssetSortKey.nameZa,
    AssetSortKey.licenseAz,
    AssetSortKey.licenseZa,
    AssetSortKey.ratingHigh,
    AssetSortKey.ratingLow,
  ];
  return source == AssetSource.all ? [...base] : [...base, AssetSortKey.updatedNew, AssetSortKey.updatedOld];
}
