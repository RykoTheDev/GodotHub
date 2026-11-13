import '../src/rust/api/console.dart' as console_rust;
import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/native.dart' as native;
import '../src/rust/api/project_health.dart' as health_rust;
import '../src/rust/api/projects.dart' as rust;
import '../src/rust/api/time_stats.dart' as time_stats_rust;
import '../src/rust/api/types.dart' as types;

final Map<String, String?> _iconCache = {};
final Map<String, String?> _nameCache = {};
final Map<String, Future<String?>> _iconRequests = {};
final Map<String, Future<String?>> _nameRequests = {};

int _resolutionEpoch = 0;
final Set<void Function()> _epochListeners = {};

int getResolutionEpoch() => _resolutionEpoch;

void Function() subscribeResolutionEpoch(void Function() listener) {
  _epochListeners.add(listener);
  return () {
    _epochListeners.remove(listener);
  };
}

void _bumpResolutionEpoch() {
  _resolutionEpoch += 1;
  for (final listener in _epochListeners.toList()) {
    listener();
  }
}

String? getCachedProjectIcon(String path) => _iconCache[path];

String? getCachedProjectName(String path) => _nameCache[path];

Future<String?> _cachedLookup(
  String path,
  Map<String, String?> cache,
  Map<String, Future<String?>> requests,
  Future<String?> Function() fetch,
) {
  if (cache.containsKey(path)) return Future.value(cache[path]);
  final pending = requests[path];
  if (pending != null) return pending;
  final request = fetch()
      .then((data) {
        cache[path] = data;
        return data;
      })
      .whenComplete(() {
        requests.remove(path);
      });
  requests[path] = request;
  return request;
}

abstract final class ProjectsApi {
  static Future<dto.HealthReport> diagnose(String id) => dto.diagnoseProject(id: id);

  static Future<void> fixHealth(String id, String checkId) => health_rust.fixProjectHealth(id: id, checkId: checkId);

  static Future<List<types.Project>> list() => rust.listProjects();

  static Future<types.Project> create(
    String name,
    String location,
    String godotVersion, [
    String? iconPath,
    String? templateId,
    String? category,
  ]) => rust.createProject(
    name: name,
    location: location,
    godotVersion: godotVersion,
    iconPath: iconPath,
    templateId: templateId,
    category: category,
  );

  static Future<void> remove(String id, bool deleteFiles) => rust.removeProject(id: id, deleteFiles: deleteFiles);

  static Future<types.Project> duplicate(String id, String name, String? destDir) =>
      rust.duplicateProject(id: id, name: name, destDir: destDir);

  static Future<types.Project> update(String id, types.ProjectUpdate updates) => rust.updateProject(id: id, updates: updates);

  static Future<void> reorder(List<String> orderedIds) => rust.reorderProjects(orderedIds: orderedIds);

  static Future<types.Project> saveTags(String id, String path, List<String> tags) => rust.writeProjectTags(id: id, path: path, tags: tags);

  static Future<types.Project> import(String path, String godotVersion, [String? category]) =>
      rust.importProject(path: path, godotVersion: godotVersion, category: category);

  static Future<void> open(String id, bool editor, [bool? withConsole]) => rust.openProject(id: id, editor: editor, console: withConsole);

  static Future<void> stop(String id) => rust.stopProject(id: id);

  static Future<types.ConsoleSnapshot> getConsole(String id, [BigInt? since]) => console_rust.getProjectConsole(id: id, since: since);

  static Future<void> clearConsole(String id) => console_rust.clearProjectConsole(id: id);

  static Future<void> openFolder(String path) => rust.openProjectFolder(path: path);

  static Future<void> openInEditor(String path) => rust.openInEditor(path: path);

  static Future<types.ProjectSizeInfo> getSize(String path) => rust.getProjectSize(path: path);

  static Future<List<types.ProjectFileEntry>> getFileTree(String path) => rust.getProjectFileTree(path: path);

  static Future<String?> pickFolder() async => native.pickFolder();

  static Future<String?> pickFile() async => native.pickImageFile();

  static Future<String?> pickSavePath(String defaultName) async => native.pickSavePath(defaultName: defaultName);

  static Future<String?> pickDataFile() async => native.pickDataFile();

  static Future<void> exportProjectStats(String path) => rust.exportProjectStats(path: path);

  static Future<BigInt> importProjectStats(String path) => rust.importProjectStats(path: path);

  static Future<void> clearTimeStats() => time_stats_rust.clearTimeStats();

  static Future<String?> readImageFile(String path) => rust.readImageFile(path: path);

  static Future<String?> getIcon(String path) => _cachedLookup(path, _iconCache, _iconRequests, () => rust.getProjectIcon(path: path));

  static Future<String?> getName(String path) => _cachedLookup(path, _nameCache, _nameRequests, () => rust.getProjectName(path: path));

  static Future<List<types.Project>> reintroduceDismissed(List<String> paths) => rust.reintroduceDismissedProjects(paths: paths);

  static Future<types.LoadStatus> getHealth() => rust.getProjectsHealth();

  static Future<BigInt> restoreFromBackup() => rust.restoreProjectsFromBackup();

  static void clearIconCache() {
    _iconCache.clear();
    _iconRequests.clear();
    _bumpResolutionEpoch();
  }

  static void clearNameCache() {
    _nameCache.clear();
    _nameRequests.clear();
    _bumpResolutionEpoch();
  }
}
