import '../src/rust/api/export_runner.dart' as exports;
import '../src/rust/api/onyx.dart' as rust;
import '../src/rust/api/types.dart' as types;

abstract final class OnyxApi {
  static Future<types.OnyxStatus> status() => rust.onyxStatus();

  /// Opens Onyx on the folder holding a finished export so it can be uploaded to Steam.
  static Future<void> openExport(String runId) => exports.openExportInOnyx(runId: runId);
}
