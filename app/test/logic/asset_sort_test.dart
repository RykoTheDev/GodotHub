import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/asset_sort.dart';

import 'logic_fixtures.dart';

void main() {
  test('keys keep ids and order', () {
    expect([for (final k in AssetSortKey.values) k.id], [
      'relevance',
      'updated_new',
      'updated_old',
      'name_az',
      'name_za',
      'rating_high',
      'rating_low',
      'license_az',
      'license_za',
    ]);
    expect(AssetSortKey.fromId('rating_low'), AssetSortKey.ratingLow);
    expect(AssetSortKey.fromId('x'), isNull);
  });

  test('assetSortParams', () {
    expect([for (final k in AssetSortKey.values) assetSortParams(k)], [
      (sort: null, reverse: false),
      (sort: 'updated', reverse: false),
      (sort: 'updated', reverse: true),
      (sort: 'name', reverse: false),
      (sort: 'name', reverse: true),
      (sort: 'rating', reverse: true),
      (sort: 'rating', reverse: false),
      (sort: 'cost', reverse: false),
      (sort: 'cost', reverse: true),
    ]);
  });

  test('storeServerSort', () {
    expect([for (final k in AssetSortKey.values) storeServerSort(k)], [
      'relevance',
      'updated_desc',
      'updated_asc',
      'relevance',
      'relevance',
      'reviews_desc',
      'reviews_asc',
      'relevance',
      'relevance',
    ]);
  });

  test('sortKeysForSource', () {
    final base = [
      AssetSortKey.relevance,
      AssetSortKey.nameAz,
      AssetSortKey.nameZa,
      AssetSortKey.licenseAz,
      AssetSortKey.licenseZa,
      AssetSortKey.ratingHigh,
      AssetSortKey.ratingLow,
    ];
    expect(sortKeysForSource(AssetSource.all), base);
    expect(sortKeysForSource(AssetSource.library), [...base, AssetSortKey.updatedNew, AssetSortKey.updatedOld]);
    expect(sortKeysForSource(AssetSource.store), [...base, AssetSortKey.updatedNew, AssetSortKey.updatedOld]);
  });

  final assets = [
    asset(id: '3', title: 'Dialogue Manager'),
    asset(id: '10', title: 'dialogue'),
    asset(id: '2', title: 'Dialogic', author: 'dialogue team'),
    asset(id: '1', title: 'Zebra', description: 'A dialogue tool'),
    asset(id: '5', title: 'Beta', category: 'Dialogue'),
    asset(id: '4', title: 'beta'),
    asset(id: '9', title: 'Beta'),
    asset(id: '11', title: 'Beta'),
    asset(id: '6', title: 'Ébauche'),
  ];

  test('rankByRelevance scores then breaks ties by title and id with localeCompare', () {
    expect([for (final a in rankByRelevance(assets, '  Dialogue ')) a.assetId], ['10', '3', '2', '5', '1', '4', '11', '9', '6']);
  });

  test('rankByRelevance with an empty query sorts by title then id', () {
    expect([for (final a in rankByRelevance(assets, '')) a.assetId], ['4', '11', '5', '9', '2', '10', '3', '6', '1']);
    expect(identical(rankByRelevance(assets, ''), assets), isFalse);
  });
}
