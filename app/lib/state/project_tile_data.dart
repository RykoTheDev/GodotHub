import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import 'project_resolution_epoch.dart';

final Map<String, int> _sizes = {};
final Map<String, Future<int>> _sizeRequests = {};

@visibleForTesting
void debugResetProjectTileSizes() {
  _sizes.clear();
  _sizeRequests.clear();
}

@immutable
class ProjectTileData {
  const ProjectTileData({this.icon, this.name, this.size, this.sizeFailed = false});

  final String? icon;
  final String? name;
  final int? size;
  final bool sizeFailed;

  String displayName(String fallback) => name ?? fallback;

  ProjectTileData copyWith({
    ValueGetter<String?>? icon,
    ValueGetter<String?>? name,
    ValueGetter<int?>? size,
    bool? sizeFailed,
  }) => ProjectTileData(
    icon: icon != null ? icon() : this.icon,
    name: name != null ? name() : this.name,
    size: size != null ? size() : this.size,
    sizeFailed: sizeFailed ?? this.sizeFailed,
  );

  @override
  bool operator ==(Object other) =>
      other is ProjectTileData &&
      other.icon == icon &&
      other.name == name &&
      other.size == size &&
      other.sizeFailed == sizeFailed;

  @override
  int get hashCode => Object.hash(icon, name, size, sizeFailed);
}

typedef ProjectTileRequest = ({String path, bool showSize, bool preview});

final projectTileDataProvider = NotifierProvider.autoDispose
    .family<ProjectTileDataNotifier, ProjectTileData, ProjectTileRequest>(ProjectTileDataNotifier.new);

class ProjectTileDataNotifier extends Notifier<ProjectTileData> {
  ProjectTileDataNotifier(this.request);

  final ProjectTileRequest request;

  @override
  ProjectTileData build() {
    final epoch = ref.watch(projectResolutionEpochProvider);
    final path = request.path;
    final sizeKey = '$epoch:$path';
    var cancelled = false;
    ref.onDispose(() => cancelled = true);

    void apply(ProjectTileData Function(ProjectTileData previous) update) {
      if (!cancelled && ref.mounted) state = update(state);
    }

    if (!request.preview) {
      ProjectsApi.getIcon(path).then((value) => apply((s) => s.copyWith(icon: () => value))).ignore();
      ProjectsApi.getName(path).then((value) => apply((s) => s.copyWith(name: () => value))).ignore();
      if (request.showSize && !_sizes.containsKey(sizeKey)) {
        final pending = _sizeRequests[sizeKey] ??= Future<int>.sync(() async {
          final info = await ProjectsApi.getSize(path);
          final total = info.totalSize.toInt();
          _sizes[sizeKey] = total;
          _sizeRequests.remove(sizeKey);
          return total;
        });
        pending.then(
          (value) => apply((s) => s.copyWith(size: () => value, sizeFailed: false)),
          onError: (Object _) {
            _sizeRequests.remove(sizeKey);
            apply((s) => s.copyWith(size: () => null, sizeFailed: true));
          },
        ).ignore();
      }
    }

    return ProjectTileData(icon: getCachedProjectIcon(path), name: getCachedProjectName(path), size: _sizes[sizeKey]);
  }
}
