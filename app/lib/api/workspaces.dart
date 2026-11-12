import '../src/rust/api/types.dart';
import '../src/rust/api/workspace.dart' as rust;

abstract final class WorkspacesApi {
  static Future<WorkspacesState> list() => rust.listWorkspaces();

  static Future<List<WorkspaceScanDirs>> scanDirs() => rust.listWorkspaceScanDirs();

  static Future<WorkspacesState> create(String name, String icon, String color, [String? copySettingsFrom]) =>
      rust.createWorkspace(name: name, icon: icon, color: color, copySettingsFrom: copySettingsFrom);

  static Future<WorkspacesState> switchWorkspace(String id) => rust.switchWorkspace(id: id);

  static Future<WorkspacesState> update(String id, String? name, String? icon, String? color) =>
      rust.updateWorkspace(id: id, name: name, icon: icon, color: color);

  static Future<WorkspacesState> delete(String id) => rust.deleteWorkspace(id: id);
}
