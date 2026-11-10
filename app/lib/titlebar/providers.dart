import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_signals.dart';
import 'running_projects_chip.dart';
import 'window_controls.dart';

export '../state/changelog.dart' show ChangelogBadgeNotifier, changelogBadgeProvider;
export '../state/task_tray.dart' show taskTrayActiveCountProvider, taskTrayProvider;

const openConsoleSignal = 'app:open-console';

final titleBarWindowProvider = Provider<TitleBarWindow>((ref) => const NativeTitleBarWindow());

final runningProjectsSourceProvider = Provider<RunningProjectsSource>((ref) => RunningProjectsSource.native());

final titleBarConsoleOpenerProvider = Provider<void Function(String id, String name)>(
  (ref) => (id, name) => AppSignals.emit(openConsoleSignal, {'id': id, 'name': name}),
);
