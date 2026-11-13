import '../src/rust/api/current_version.dart' as current_rust;
import '../src/rust/api/export_templates.dart' as templates_rust;
import '../src/rust/api/godot_versions.dart' as rust;
import '../src/rust/api/native.dart' as native;
import '../src/rust/api/scan.dart' as scan_rust;
import '../src/rust/api/types.dart' as types;

abstract final class VersionsApi {
  static Future<List<types.GodotRelease>> fetchAvailable([String? source]) => rust.fetchAvailableGodotVersions(source: source ?? 'github');

  static Future<void> download(String tag, String assetName, String downloadUrl) =>
      rust.downloadGodotVersion(tag: tag, assetName: assetName, downloadUrl: downloadUrl);

  static Future<void> pauseDownload(String key) => rust.pauseDownload(key: key);

  static Future<void> resumeDownload(String key) => rust.resumeDownload(key: key);

  static Future<void> cancelDownload(String key) => rust.cancelDownload(key: key);

  static Future<void> reorderDownloadQueue(String key, int direction) => rust.reorderDownloadQueue(key: key, direction: direction);

  static Future<List<types.InstalledGodotVersion>> listInstalled() => rust.listInstalledGodotVersions();

  static Future<types.InstalledGodotVersion> rename(String tag, String? customName) =>
      rust.renameGodotVersion(tag: tag, customName: customName);

  static Future<void> delete(String tag) => rust.deleteGodotVersion(tag: tag);

  static Future<types.CurrentVersionInfo?> getCurrent() => current_rust.getCurrentVersion();

  static Future<types.CurrentVersionInfo> setCurrent(String tag) => current_rust.setCurrentVersion(tag: tag);

  static Future<void> clearCurrent() => current_rust.clearCurrentVersion();

  static Future<types.VersionAliases> listAliases() => current_rust.listVersionAliases();

  static Future<types.AliasBatchResult> createAliases(List<types.AliasRequest> entries) =>
      current_rust.createVersionAliases(entries: entries);

  static Future<String?> pickExecutable() async => native.pickExecutable();

  static Future<types.InstalledGodotVersion> addCustomBuild(String path, String? name) => scan_rust.addCustomBuild(path: path, name: name);

  static Future<void> deleteAlias(String name) => current_rust.deleteVersionAlias(name: name);

  static Future<void> open(String tag, [bool? withConsole]) => rust.openGodotVersion(tag: tag, console: withConsole);

  static Future<List<types.InstalledGodotVersion>> import(String path) => scan_rust.importVersion(path: path);

  static Future<List<types.InstalledGodotVersion>> scan(List<String> dirs, int depth) =>
      scan_rust.scanForVersions(dirs: dirs, depth: depth);

  static Future<types.RateLimitInfo> testGithubToken() => rust.testGithubToken();

  static Future<types.RateLimitInfo> getGithubRateLimit() => rust.getGithubRateLimit();

  static Future<types.ExportTemplatesState> exportTemplatesState() => templates_rust.getExportTemplatesState();

  static Future<List<types.TemplateOption>> getExportTemplateOptions(String tag, [bool refresh = false]) =>
      templates_rust.getExportTemplateOptions(tag: tag, refresh: refresh);

  static Future<types.ExportTemplatesInstallResult?> installExportTemplates(String tag, List<String> files) =>
      templates_rust.installExportTemplates(tag: tag, files: files);

  static Future<void> cancelExportTemplates(String tag) => templates_rust.cancelExportTemplatesDownload(tag: tag);

  static Future<void> deleteExportTemplates(String folder, String root) => templates_rust.deleteExportTemplates(folder: folder, root: root);

  static Future<void> uninstallExportTemplateFiles(String tag, List<String> files) =>
      templates_rust.uninstallExportTemplateFiles(tag: tag, files: files);

  static Future<void> openExportTemplatesFolder([String? tag]) => templates_rust.openExportTemplatesFolder(tag: tag);

  static Future<void> openFolder() => rust.openVersionsFolder();
}
