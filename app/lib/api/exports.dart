import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/export_runner.dart' as rust;
import '../src/rust/api/tool_runner.dart' as tools_rust;
import '../src/rust/api/types.dart' as types;

abstract final class ExportsApi {
  static Future<dto.ExportCatalog> presets(String id) => dto.getProjectExportPresets(id: id);

  static Future<types.ExportRun> start(String id, int presetId, String outputPath, [bool overwrite = false]) =>
      rust.startProjectExport(id: id, presetId: presetId, outputPath: outputPath, overwrite: overwrite);

  static Future<types.ExportRun> get(String runId) => rust.getProjectExport(runId: runId);

  static Future<List<types.ExportRun>> list(String id) => rust.getProjectExports(id: id);

  static Future<void> cancel(String runId) => rust.cancelProjectExport(runId: runId);

  static Future<void> openFolder(String runId) => rust.openExportArtifactFolder(runId: runId);

  static Future<List<types.ProjectTool>> tools(String id) => tools_rust.listProjectTools(id: id);

  static Future<String> runTool(String id, String tool) => tools_rust.runProjectTool(id: id, tool: tool);

  static Future<void> stopTool(String consoleId) => tools_rust.stopProjectTool(consoleId: consoleId);
}

const String toolConsolePrefix = 'tool:';
