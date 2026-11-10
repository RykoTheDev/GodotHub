import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/src/rust/api/addons.dart' as addons;
import 'package:godothub/src/rust/api/app.dart' as app;
import 'package:godothub/src/rust/api/asset_library.dart' as asset_library;
import 'package:godothub/src/rust/api/backup.dart' as backup;
import 'package:godothub/src/rust/api/categories.dart' as categories;
import 'package:godothub/src/rust/api/changelog.dart' as changelog;
import 'package:godothub/src/rust/api/cli_shim.dart' as cli_shim;
import 'package:godothub/src/rust/api/console.dart' as console;
import 'package:godothub/src/rust/api/current_version.dart' as current_version;
import 'package:godothub/src/rust/api/discovery.dart' as discovery;
import 'package:godothub/src/rust/api/dto.dart' as dto;
import 'package:godothub/src/rust/api/error.dart';
import 'package:godothub/src/rust/api/export_runner.dart' as export_runner;
import 'package:godothub/src/rust/api/export_templates.dart' as export_templates;
import 'package:godothub/src/rust/api/git.dart' as git;
import 'package:godothub/src/rust/api/git_auth.dart' as git_auth;
import 'package:godothub/src/rust/api/godot_versions.dart' as godot_versions;
import 'package:godothub/src/rust/api/install_mode.dart' as install_mode;
import 'package:godothub/src/rust/api/mise.dart' as mise;
import 'package:godothub/src/rust/api/news.dart' as news;
import 'package:godothub/src/rust/api/project_todos.dart' as project_todos;
import 'package:godothub/src/rust/api/projects.dart' as projects;
import 'package:godothub/src/rust/api/scan.dart' as scan;
import 'package:godothub/src/rust/api/settings.dart' as settings;
import 'package:godothub/src/rust/api/storage.dart' as storage;
import 'package:godothub/src/rust/api/sync.dart' as sync;
import 'package:godothub/src/rust/api/templates.dart' as templates;
import 'package:godothub/src/rust/api/time_stats.dart' as time_stats;
import 'package:godothub/src/rust/api/todo_sync.dart' as todo_sync;
import 'package:godothub/src/rust/api/tool_runner.dart' as tool_runner;
import 'package:godothub/src/rust/api/ui_prefs.dart' as ui_prefs;
import 'package:godothub/src/rust/api/vault.dart' as vault;
import 'package:godothub/src/rust/api/watcher.dart' as watcher;
import 'package:godothub/src/rust/api/workspace.dart' as workspace;
import 'package:godothub/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

late Directory root;
late String projectId;

Directory makeProject(Directory parent, String name) {
  final dir = Directory('${parent.path}${Platform.pathSeparator}$name')..createSync(recursive: true);
  File('${dir.path}${Platform.pathSeparator}project.godot')
      .writeAsStringSync('config_version=5\n\n[application]\n\nconfig/name="$name"\n');
  return dir;
}

Future<void> tolerateNetwork(Future<Object?> Function() call) async {
  try {
    await call();
  } on CoreError catch (error) {
    expect(error.message, isNotEmpty);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    root = Directory.systemTemp.createTempSync('godothub-it-');
    String dir(String name) => Directory('${root.path}${Platform.pathSeparator}$name').path;
    expect(
      await app.startCoreIn(channel: 'beta', dataDir: dir('data'), configDir: dir('config'), cacheDir: dir('cache')),
      'GodotHub Beta',
    );
    final project = makeProject(root, 'Space Game');
    projectId = (await projects.importProject(path: project.path, godotVersion: '4.4.1-stable')).id;
  });

  tearDownAll(() {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('projects, settings and workspaces', (tester) async {
    expect((await projects.listProjects()).map((p) => p.id), contains(projectId));
    final current = await settings.getSettings();
    expect((await settings.updateSettings(settings: current)).language, current.language);
    final before = await workspace.listWorkspaces();
    final after = await workspace.createWorkspace(name: 'Second', icon: 'folder', color: '#478cbf');
    expect(after.workspaces.length, before.workspaces.length + 1);
    expect(after.activeId, isNot(before.activeId));
    expect((await workspace.switchWorkspace(id: before.activeId)).activeId, before.activeId);
    expect(await app.getOsUsername(), isNotNull);
  });

  testWidgets('categories, todos, time stats and ui prefs', (tester) async {
    final category = await categories.createCategory(name: 'Prototypes');
    expect((await categories.listCategories()).map((c) => c.id), contains(category.id));
    expect(await project_todos.listProjectTodos(projectId: projectId), isEmpty);
    expect(await project_todos.listOpenTodos(), isA<List<Object>>());
    expect(await time_stats.getActivity(range: 'week'), isA<List<(String, BigInt)>>());
    await dto.setUiPref(key: 'new_ui_sidebar_width', value: '"300"');
    expect(await dto.getUiPref(key: 'new_ui_sidebar_width'), '"300"');
    await ui_prefs.removeUiPref(key: 'new_ui_sidebar_width');
    expect(await dto.getUiPref(key: 'new_ui_sidebar_width'), isNull);
  });

  testWidgets('project tools, health and consoles', (tester) async {
    expect(await addons.listProjectAddons(id: projectId), isEmpty);
    expect(await tool_runner.listProjectTools(id: projectId), isA<List<Object>>());
    expect(await todo_sync.listProjectResources(projectId: projectId), isA<List<String>>());
    expect(await export_runner.getProjectExports(id: projectId), isEmpty);
    expect((await console.getProjectConsole(id: projectId)).running, isFalse);
    expect((await dto.diagnoseProject(id: projectId)).projectId, projectId);
    await expectLater(
      dto.diagnoseProject(id: 'missing'),
      throwsA(isA<CoreError>().having((e) => e.message, 'message', 'Project is no longer registered')),
    );
  });

  testWidgets('versions, templates, storage and git', (tester) async {
    expect(await godot_versions.listInstalledGodotVersions(), isEmpty);
    expect(await current_version.getCurrentVersion(), isNull);
    expect(await discovery.detectGodotInstalls(), isA<List<Object>>());
    expect(await export_templates.getExportTemplatesState(), isNotNull);
    expect(await mise.miseStatus(), isNotNull);
    expect(await templates.listTemplates(), isEmpty);
    expect(await vault.listVaultItems(), isEmpty);
    expect(await storage.getStorageReport(), isNotNull);
    expect(await changelog.listChangelogEntries(), isNotEmpty);
    expect(await git.gitIsAvailable(), isA<bool>());
    expect(await git_auth.getGitAuthState(), isNotNull);
    expect(await sync.gistSyncGetInfo(), isA<Object?>());
    expect(await install_mode.isPortableInstall(), isA<bool>());
    expect((await cli_shim.cliToolStatus()).installed, isFalse);
    await watcher.restartWatchers();
    final file = File('${root.path}${Platform.pathSeparator}backup.json');
    await backup.exportAppBackup(path: file.path);
    expect(file.existsSync(), isTrue);
  });

  testWidgets('network commands fail with typed errors instead of crashing', (tester) async {
    await tolerateNetwork(asset_library.getAssetLibraryCategories);
    await tolerateNetwork(news.fetchGodotNews);
  });

  testWidgets('the event stream delivers scan progress', (tester) async {
    final scanRoot = Directory('${root.path}${Platform.pathSeparator}scan')..createSync();
    makeProject(scanRoot, 'Found Game');
    final progress = AppEvents.of(AppEventKind.projectScanProgress).first.timeout(const Duration(seconds: 20));
    final added = await scan.scanForProjects(dirs: [scanRoot.path], depth: 2);
    expect(added.map((p) => p.name), contains('Found Game'));
    final event = await progress;
    expect(event.scanProgress, isNotNull);
    expect(event.scanProgress!.total, greaterThanOrEqualTo(event.scanProgress!.current));
  });

  testWidgets('the event stream delivers download progress', (tester) async {
    final progress = AppEvents.payloads(AppEventKind.godotDownloadProgress, (event) => event.downloadProgress)
        .first
        .timeout(const Duration(seconds: 20));
    await app.emitEventForTest(
      name: 'godot-download-progress',
      payloadJson: '{"tag":"4.4.1-stable","downloaded":5,"total":10}',
    );
    final payload = await progress;
    expect(payload.tag, '4.4.1-stable');
    expect(payload.downloaded, BigInt.from(5));
    expect(payload.total, BigInt.from(10));
  });
}
