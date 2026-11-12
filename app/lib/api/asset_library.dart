import '../src/rust/api/addons.dart' as addons;
import '../src/rust/api/asset_library.dart' as rust;
import '../src/rust/api/types.dart';

abstract final class AssetLibraryApi {
  static Future<List<ProjectAddon>> projectAddons(String id) => addons.listProjectAddons(id: id);

  static Future<List<AddonUpdate>> addonUpdates(String id) => addons.checkAddonUpdates(id: id);

  static Future<void> updateAddon(String id, String folder, String assetId) =>
      addons.updateProjectAddon(id: id, folder: folder, assetId: assetId);

  static Future<AssetLibraryResponse> search(
    String? filter,
    String? godotVersion,
    int page,
    int maxResults, [
    String? assetType,
    String? categoryId,
    String? sort,
    bool reverse = false,
  ]) => rust.searchAssetLibrary(
    filter: filter,
    godotVersion: godotVersion,
    page: page,
    maxResults: maxResults,
    assetType: assetType,
    categoryId: categoryId,
    sort: sort,
    reverse: reverse,
  );

  static Future<ProjectTemplate> installAsTemplate(String assetId) => rust.installAssetAsTemplate(assetId: assetId);

  static Future<InstallAssetResult> install(String assetId, String? projectId, String? templateId) =>
      rust.installAsset(assetId: assetId, projectId: projectId, templateId: templateId);

  static Future<String> download(String assetId, [String? destDir]) => rust.downloadAsset(assetId: assetId, destDir: destDir);

  static Future<AssetLibraryResponse> searchStore(String? filter, String? godotVersion, int page, int maxResults, [String? sort]) =>
      rust.searchAssetStore(filter: filter, godotVersion: godotVersion, page: page, maxResults: maxResults, sort: sort);

  static Future<String> downloadStoreAsset(String publisherSlug, String assetSlug, String title) =>
      rust.downloadStoreAsset(publisherSlug: publisherSlug, assetSlug: assetSlug, title: title, destDir: null);

  static Future<InstallAssetResult> installStoreAsset(
    String publisherSlug,
    String assetSlug,
    String title,
    String? projectId,
    String? templateId,
  ) => rust.installStoreAsset(
    publisherSlug: publisherSlug,
    assetSlug: assetSlug,
    title: title,
    projectId: projectId,
    templateId: templateId,
  );

  static Future<List<AssetLibraryCategory>> listCategories() => rust.getAssetLibraryCategories();
}
