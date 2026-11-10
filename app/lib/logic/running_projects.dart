import '../api/api.dart';
import '../src/rust/api/types.dart';

const runningProjectsRetryDelaysMs = [0, 1200, 3000, 6000];

Future<List<RunningProjectInfo>> fetchRunningProjects({
  Future<List<RunningProjectInfo>> Function()? list,
  Future<void> Function(Duration delay)? wait,
}) async {
  final fetch = list ?? Api.listRunningProjects;
  final sleep = wait ?? Future<void>.delayed;
  var found = <RunningProjectInfo>[];
  for (final delay in runningProjectsRetryDelaysMs) {
    if (delay > 0) {
      await sleep(Duration(milliseconds: delay));
    }
    try {
      found = await fetch();
    } catch (_) {
      return found;
    }
    if (found.isNotEmpty) return found;
  }
  return found;
}
