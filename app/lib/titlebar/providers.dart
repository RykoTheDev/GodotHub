import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/settings.dart';
import '../src/rust/api/types.dart';
import 'running_projects_chip.dart';
import 'window_controls.dart';

final titleBarWindowProvider = Provider<TitleBarWindow>((ref) => const NativeTitleBarWindow());

final runningProjectsSourceProvider = Provider<RunningProjectsSource>((ref) => RunningProjectsSource.native());

final titleBarSettingsWriterProvider = Provider<Future<AppSettings> Function(AppSettings settings)>(
  (ref) => SettingsApi.update,
);

final titleBarConsoleOpenerProvider = Provider<void Function(String id, String name)>((ref) => (id, name) {});

final changelogBadgeProvider = NotifierProvider<ChangelogBadgeNotifier, bool>(ChangelogBadgeNotifier.new);

class ChangelogBadgeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark(bool hasNewEntry) => state = hasNewEntry;
}
