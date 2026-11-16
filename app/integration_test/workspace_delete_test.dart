import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/app.dart' as app;
import 'package:godothub/src/rust/api/godot_versions.dart' as godot_versions;
import 'package:godothub/src/rust/api/projects.dart' as projects;
import 'package:godothub/src/rust/api/scan.dart' as scan;
import 'package:godothub/src/rust/api/settings.dart' as settings;
import 'package:godothub/src/rust/api/workspace.dart' as workspace;
import 'package:godothub/src/rust/frb_generated.dart';
import 'package:godothub/state/godot_versions.dart';
import 'package:godothub/state/projects.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/state/workspaces.dart';
import 'package:integration_test/integration_test.dart';

Directory makeProject(Directory parent, String name) {
  final dir = Directory('${parent.path}${Platform.pathSeparator}$name')..createSync(recursive: true);
  File('${dir.path}${Platform.pathSeparator}project.godot').writeAsStringSync('config_version=5\n\n[application]\n\nconfig/name="$name"\n');
  return dir;
}

Future<void> settle(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deleting the active workspace leaves the remaining one working', (tester) async {
    await tester.runAsync(() async {
      await RustLib.init();
      final root = Directory.systemTemp.createTempSync('godothub-ws-delete-');
      addTearDown(() {
        try {
          root.deleteSync(recursive: true);
        } catch (_) {}
      });
      String dir(String name) => Directory('${root.path}${Platform.pathSeparator}$name').path;
      await app.startCoreIn(channel: 'beta', dataDir: dir('data'), configDir: dir('config'), cacheDir: dir('cache'));

      final first = await workspace.listWorkspaces();
      final firstId = first.activeId;
      final firstProject = (await projects.importProject(path: makeProject(root, 'First Game').path, godotVersion: '4.4.1-stable')).id;
      final firstSettings = await settings.getSettings();
      await settings.updateSettings(settings: copySettings(firstSettings, projectScanDirs: [root.path]));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(projectsProvider, (_, _) {});
      container.listen(settingsProvider, (_, _) {});
      container.listen(godotVersionsProvider, (_, _) {});
      await settle(container);
      expect(container.read(workspacesProvider).activeId, firstId);

      await container.read(workspacesProvider.notifier).createWorkspace('Second', 'folder', '#478cbf');
      await settle(container);
      final secondId = container.read(workspacesProvider).activeId;
      expect(secondId, isNot(firstId));
      await projects.importProject(path: makeProject(root, 'Second Game').path, godotVersion: '4.4.1-stable');
      await container.read(projectsProvider.notifier).refresh();
      await settle(container);

      await container.read(workspacesProvider.notifier).deleteWorkspace(secondId);
      await settle(container);

      expect(container.read(workspacesProvider).activeId, firstId);
      expect((await workspace.listWorkspaces()).activeId, firstId);
      final direct = await projects.listProjects();
      expect(direct.map((p) => p.id), [firstProject], reason: 'core list after delete');
      final view = container.read(projectsProvider);
      expect(view.error, isNull, reason: 'projects provider error: ${view.error}');
      expect(view.data.map((p) => p.id), [firstProject], reason: 'projects provider after delete');
      final current = container.read(settingsProvider).value;
      expect(current?.projectScanDirs, [root.path], reason: 'settings provider after delete');
      await scan.scanForProjectsWithInfo(dirs: [root.path], depth: 2);
      await godot_versions.listInstalledGodotVersions();
      expect(Directory('${dir('data')}${Platform.pathSeparator}workspaces${Platform.pathSeparator}$secondId').existsSync(), isFalse);
    });
  });
}
