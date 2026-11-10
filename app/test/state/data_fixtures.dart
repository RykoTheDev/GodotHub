import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/settings.dart';

import '../support/fake_rust.dart';

Workspace workspace(String id, {String name = 'Workspace'}) =>
    Workspace(id: id, name: name, icon: 'folder', color: '#457ff2', createdAt: '2026-01-01T00:00:00Z');

WorkspacesState workspacesState(String activeId, [List<String> ids = const ['w1', 'w2']]) =>
    WorkspacesState(workspaces: [for (final id in ids) workspace(id)], activeId: activeId);

Project project(
  String id, {
  String? name,
  String? category,
  bool pinned = false,
  int sortOrder = 0,
  List<String> tags = const [],
}) => Project(
  id: id,
  name: name ?? 'Project $id',
  path: '/projects/$id',
  godotVersion: '4.3-stable',
  createdAt: '2026-01-01T00:00:00Z',
  category: category,
  pinned: pinned,
  sortOrder: sortOrder,
  launchArguments: '',
  tags: tags,
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

Category category(String id, {int sortOrder = 0, bool hidden = false}) =>
    Category(id: id, name: 'Category $id', sortOrder: sortOrder, color: '#ffffff', hidden: hidden, folders: const []);

AppSettings settingsWith({
  String language = 'en-US',
  bool useMise = false,
  bool projectTodosEnabled = false,
  bool desktopNotificationsEnabled = false,
  String themeMode = 'dark',
  String backgroundColor = '#15171c',
}) => copySettings(
  defaultSettings,
  language: language,
  useMise: useMise,
  projectTodosEnabled: projectTodosEnabled,
  desktopNotificationsEnabled: desktopNotificationsEnabled,
  themeMode: themeMode,
  backgroundColor: backgroundColor,
);

class CoreBackend {
  CoreBackend(this.rust, {required this.active, AppSettings? settings}) : settings = settings ?? defaultSettings {
    rust.on('crateApiWorkspaceListWorkspaces', () async => workspacesState(active));
    rust.on('crateApiWorkspaceSwitchWorkspace', ({required String id}) async {
      active = id;
      return workspacesState(active);
    });
    rust.on('crateApiSettingsGetSettings', () async => this.settings);
    rust.on('crateApiSettingsUpdateSettings', ({required AppSettings settings}) async {
      saved.add(settings);
      this.settings = settings;
      return settings;
    });
  }

  final FakeRustApi rust;
  String active;
  AppSettings settings;
  final List<AppSettings> saved = [];
}

void useMemoryUiPrefs([Map<String, String> values = const {}]) {
  UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
  for (final entry in values.entries) {
    UiPrefsStore.instance.setItem(entry.key, entry.value);
  }
}

ProviderContainer createContainer(List<ProviderListenable<Object?>> keepAlive) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  for (final provider in keepAlive) {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
  }
  return container;
}

Future<void> settle() => pumpEventQueue();
