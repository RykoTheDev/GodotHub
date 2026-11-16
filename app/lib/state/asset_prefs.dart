import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';

const _emptyPrefs = AssetPrefs(schemaVersion: 0, favorites: [], hidden: []);

/// Favorite and hidden ("not interested") assets. Global across workspaces.
final assetPrefsProvider = NotifierProvider<AssetPrefsNotifier, ApiData<AssetPrefs>>(AssetPrefsNotifier.new);

class AssetPrefsNotifier extends ApiDataNotifier<AssetPrefs> {
  @override
  AssetPrefs get initial => _emptyPrefs;

  @override
  Future<AssetPrefs> fetch() => AssetLibraryApi.prefs();

  Future<void> _apply(AssetPrefs optimistic, Future<AssetPrefs> Function() save) async {
    final previous = state.data;
    state = state.copyWith(data: optimistic);
    try {
      final saved = await save();
      if (ref.mounted) state = state.copyWith(data: saved);
    } catch (_) {
      if (ref.mounted) state = state.copyWith(data: previous);
      rethrow;
    }
  }

  Future<void> setFavorite(AssetLibraryAsset asset, bool favorite) {
    final prefs = state.data;
    final favorites = [
      if (favorite) asset,
      for (final a in prefs.favorites)
        if (a.assetId != asset.assetId) a,
    ];
    return _apply(
      AssetPrefs(schemaVersion: prefs.schemaVersion, favorites: favorites, hidden: prefs.hidden),
      () => AssetLibraryApi.setFavorite(asset, favorite),
    );
  }

  Future<void> setHidden(String assetId, String title, bool hidden) {
    final prefs = state.data;
    final list = [
      if (hidden) HiddenAsset(assetId: assetId, title: title),
      for (final h in prefs.hidden)
        if (h.assetId != assetId) h,
    ];
    return _apply(
      AssetPrefs(schemaVersion: prefs.schemaVersion, favorites: prefs.favorites, hidden: list),
      () => AssetLibraryApi.setHidden(assetId, title, hidden),
    );
  }
}

extension AssetPrefsLookup on AssetPrefs {
  bool isFavorite(String assetId) => favorites.any((a) => a.assetId == assetId);

  Set<String> get hiddenIds => {for (final h in hidden) h.assetId};
}

/// Which of the user's projects each asset was installed into by GodotHub.
final assetInstallationsProvider = NotifierProvider<AssetInstallationsNotifier, ApiData<List<AssetInstallation>>>(
  AssetInstallationsNotifier.new,
);

class AssetInstallationsNotifier extends ApiDataNotifier<List<AssetInstallation>> {
  @override
  List<AssetInstallation> get initial => const [];

  @override
  Future<List<AssetInstallation>> fetch() => AssetLibraryApi.installations();
}

Map<String, List<AssetInstallation>> groupInstallations(List<AssetInstallation> all) {
  final map = <String, List<AssetInstallation>>{};
  for (final i in all) {
    map.putIfAbsent(i.assetId, () => []).add(i);
  }
  return map;
}

/// True when [asset] reports a version and a project has a different one.
bool assetHasUpdate(AssetLibraryAsset asset, List<AssetInstallation> installs) =>
    asset.version.isNotEmpty && installs.any((i) => i.version.isNotEmpty && i.version != asset.version);

/// Local templates whose Asset Library source has a newer upload.
final templateUpdatesProvider = NotifierProvider<TemplateUpdatesNotifier, ApiData<List<TemplateUpdate>>>(TemplateUpdatesNotifier.new);

class TemplateUpdatesNotifier extends ApiDataNotifier<List<TemplateUpdate>> {
  @override
  List<TemplateUpdate> get initial => const [];

  @override
  Future<List<TemplateUpdate>> fetch() => AssetLibraryApi.templateUpdates();
}
