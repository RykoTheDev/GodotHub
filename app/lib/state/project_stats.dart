import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../ui/core/i18n.dart';
import 'projects.dart';

enum ProjectStatsAction { export, import }

const projectStatsFileName = 'godothub-time-stats.json';

@immutable
class ProjectStatsState {
  const ProjectStatsState({this.busy, this.message});

  final ProjectStatsAction? busy;
  final String? message;
}

final projectStatsProvider = NotifierProvider<ProjectStatsNotifier, ProjectStatsState>(ProjectStatsNotifier.new);

class ProjectStatsNotifier extends Notifier<ProjectStatsState> {
  @override
  ProjectStatsState build() => const ProjectStatsState();

  Future<void> _run(ProjectStatsAction action, Future<String?> Function() work) async {
    if (state.busy != null) return;
    state = ProjectStatsState(busy: action);
    String? message;
    try {
      message = await work();
    } catch (error) {
      message = '$error';
    }
    if (ref.mounted) state = ProjectStatsState(message: message);
  }

  Future<void> exportStats({Future<String?> Function(String defaultName)? pickSavePath}) => _run(ProjectStatsAction.export, () async {
    final path = await (pickSavePath ?? ProjectsApi.pickSavePath)(projectStatsFileName);
    if (path == null) return null;
    await ProjectsApi.exportProjectStats(path);
    return ghTr('settings:stats_exported');
  });

  Future<void> importStats({Future<String?> Function()? pickDataFile}) => _run(ProjectStatsAction.import, () async {
    final path = await (pickDataFile ?? ProjectsApi.pickDataFile)();
    if (path == null) return null;
    final count = await ProjectsApi.importProjectStats(path);
    await ref.read(projectsProvider.notifier).refresh();
    return ghTr('settings:stats_imported', count: count.toInt());
  });
}
