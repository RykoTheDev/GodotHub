import '../src/rust/api/mise.dart' as rust;
import '../src/rust/api/types.dart' as types;

abstract final class MiseApi {
  static Future<types.MiseStatus> status() => rust.miseStatus();

  static Future<types.MiseStatus> refreshStatus() => rust.miseRefreshStatus();

  static Future<List<types.InstalledGodotVersion>> syncVersions() => rust.miseSyncGodotVersions();

  static Future<List<types.InstalledGodotVersion>> install(String tag) => rust.miseInstallGodotVersion(tag: tag);

  static Future<void> uninstall(String tag) => rust.miseUninstallGodotVersion(tag: tag);
}
