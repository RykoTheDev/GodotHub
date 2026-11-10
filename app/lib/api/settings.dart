import '../src/rust/api/app.dart' as app;
import '../src/rust/api/backup.dart' as backup;
import '../src/rust/api/cli_shim.dart' as cli_shim;
import '../src/rust/api/scan.dart' as scan;
import '../src/rust/api/settings.dart' as rust;
import '../src/rust/api/sync.dart' as sync;
import '../src/rust/api/time_stats.dart' as time_stats;
import '../src/rust/api/types.dart';
import '../src/rust/api/watcher.dart' as watcher;

abstract final class SettingsApi {
  static Future<AppSettings> get() => rust.getSettings();

  static Future<AppSettings> update(AppSettings settings) =>
      rust.updateSettings(settings: settings);

  static Future<AppSettings> reset() => rust.resetSettings();

  static Future<void> exportSettings(String path) =>
      rust.exportSettings(path: path);

  static Future<AppSettings> importSettings(String path) =>
      rust.importSettings(path: path);

  static Future<void> exportWorkspaceBackup(String path) =>
      backup.exportWorkspaceBackup(path: path);

  static Future<AppSettings> importWorkspaceBackup(String path) =>
      backup.importWorkspaceBackup(path: path);

  static Future<void> exportAppBackup(String path) =>
      backup.exportAppBackup(path: path);

  static Future<AppSettings> importAppBackup(String path) =>
      backup.importAppBackup(path: path);

  static Future<GistSyncResult> gistSyncPush() => sync.gistSyncPush();

  static Future<AppSettings> gistSyncPull() => sync.gistSyncPull();

  static Future<GistSyncResult?> gistSyncGetInfo() => sync.gistSyncGetInfo();

  static Future<AppSettings> gistSyncPullByUrl(String gistUrl) =>
      sync.gistSyncPullByUrl(gistUrl: gistUrl);

  static Future<void> gistSyncSaveGistUrl(String gistUrl) =>
      sync.gistSyncSaveGistUrl(gistUrl: gistUrl);

  static Future<RestorePreview> gistSyncFetchBackup() =>
      sync.gistSyncFetchBackup();

  static Future<TimeInsights> getTimeInsights() =>
      time_stats.getTimeInsights();

  static Future<void> resetData() => rust.resetAppData();

  static Future<List<Project>> scanForProjects(List<String> dirs, int depth) =>
      scan.scanForProjects(dirs: dirs, depth: depth);

  static Future<ScanProjectsResult> scanForProjectsWithInfo(
    List<String> dirs,
    int depth,
  ) => scan.scanForProjectsWithInfo(dirs: dirs, depth: depth);

  static Future<void> refreshTrayMenu() => throw UnsupportedError(
    'refreshTrayMenu is not available in the Flutter app yet',
  );

  static Future<void> restartWatchers() => watcher.restartWatchers();

  static Future<String?> getOsUsername() => app.getOsUsername();

  static Future<CliToolStatus> cliToolStatus() => cli_shim.cliToolStatus();

  static Future<CliToolStatus> installCliTool() => cli_shim.installCliTool();

  static Future<CliToolStatus> uninstallCliTool() =>
      cli_shim.uninstallCliTool();
}
