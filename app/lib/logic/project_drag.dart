import 'package:flutter/foundation.dart' hide Category;

import '../src/rust/api/types.dart';

const String uncategorizedKey = '__uncategorized__';

@immutable
class DroppablePrefixes {
  const DroppablePrefixes({required this.category});

  final String category;
}

enum DropPlacement { before, after }

@immutable
sealed class ProjectDropResolution {
  const ProjectDropResolution();
}

final class ProjectDropNone extends ProjectDropResolution {
  const ProjectDropNone();

  @override
  bool operator ==(Object other) => other is ProjectDropNone;

  @override
  int get hashCode => (ProjectDropNone).hashCode;

  @override
  String toString() => 'ProjectDropNone()';
}

final class ProjectDropReorder extends ProjectDropResolution {
  const ProjectDropReorder(this.orderedIds);

  final List<String> orderedIds;

  @override
  bool operator ==(Object other) => other is ProjectDropReorder && listEquals(other.orderedIds, orderedIds);

  @override
  int get hashCode => Object.hashAll(orderedIds);

  @override
  String toString() => 'ProjectDropReorder($orderedIds)';
}

final class ProjectDropMove extends ProjectDropResolution {
  const ProjectDropMove({required this.activeIds, required this.categoryName, required this.destOrderedIds});

  final List<String> activeIds;
  final String categoryName;
  final List<String> destOrderedIds;

  @override
  bool operator ==(Object other) =>
      other is ProjectDropMove &&
      listEquals(other.activeIds, activeIds) &&
      other.categoryName == categoryName &&
      listEquals(other.destOrderedIds, destOrderedIds);

  @override
  int get hashCode => Object.hash(Object.hashAll(activeIds), categoryName, Object.hashAll(destOrderedIds));

  @override
  String toString() => 'ProjectDropMove($activeIds -> "$categoryName", $destOrderedIds)';
}

String categoryKeyOf(Project project) {
  final category = project.category;
  return category == null || category.isEmpty ? uncategorizedKey : category;
}

List<Project> kanbanColumnOrder(List<Project> projects, List<Category> categories) {
  if (categories.isEmpty) return projects;
  final groups = <String, List<Project>>{};
  for (final project in projects) {
    groups.putIfAbsent(categoryKeyOf(project), () => []).add(project);
  }
  final known = {for (final category in categories) category.name};
  final ordered = <Project>[];
  for (final category in categories) {
    ordered.addAll(groups[category.name] ?? const []);
  }
  for (final entry in groups.entries) {
    if (entry.key != uncategorizedKey && !known.contains(entry.key)) ordered.addAll(entry.value);
  }
  ordered.addAll(groups[uncategorizedKey] ?? const []);
  return ordered;
}

bool hasOnlyPinnedProjects(List<Project> projects, String categoryKey) {
  final members = projects.where((p) => categoryKeyOf(p) == categoryKey).toList();
  return members.isNotEmpty && members.every((p) => p.pinned);
}

@immutable
class ProjectDropInput {
  const ProjectDropInput({
    required this.activeId,
    this.activeIds,
    required this.overId,
    required this.projects,
    required this.categories,
    required this.grouped,
    required this.prefixes,
    this.placement,
  });

  final String activeId;
  final List<String>? activeIds;
  final String overId;
  final List<Project> projects;
  final List<Category> categories;
  final bool grouped;
  final DroppablePrefixes prefixes;
  final DropPlacement? placement;
}

ProjectDropResolution resolveProjectDrop(ProjectDropInput input) {
  final activeId = input.activeId;
  final overId = input.overId;
  final projects = input.projects;
  final grouped = input.grouped;
  final prefix = input.prefixes.category;
  final activeIds = input.activeIds;
  final travelling = <String>{...(activeIds != null && activeIds.isNotEmpty ? activeIds : [activeId])};
  final moving = projects.where((p) => travelling.contains(p.id)).toList();
  final draggedIndex = projects.indexWhere((p) => p.id == activeId);
  if (draggedIndex == -1 || moving.isEmpty || travelling.contains(overId)) return const ProjectDropNone();
  final dragged = projects[draggedIndex];

  final onZone = overId.startsWith(prefix);
  final overIndexInProjects = projects.indexWhere((p) => p.id == overId);
  final overProject = overIndexInProjects == -1 ? null : projects[overIndexInProjects];
  if ((!grouped || !onZone) && overProject == null) return const ProjectDropNone();

  final suffix = overId.length > prefix.length ? overId.substring(prefix.length) : '';
  final String targetKey;
  if (onZone) {
    if (suffix == 'uncategorized') {
      targetKey = uncategorizedKey;
    } else {
      final categoryIndex = input.categories.indexWhere((c) => c.id == suffix);
      targetKey = categoryIndex == -1 ? suffix : input.categories[categoryIndex].name;
    }
  } else {
    targetKey = categoryKeyOf(overProject!);
  }
  final destination = grouped ? projects.where((p) => categoryKeyOf(p) == targetKey).toList() : projects;
  final rest = destination.where((p) => !travelling.contains(p.id)).toList();
  final overIndex = rest.indexWhere((p) => p.id == overId);
  final sameCategory = moving.every((p) => categoryKeyOf(p) == targetKey);
  final placement =
      input.placement ??
      (moving.length == 1 &&
              (!grouped || sameCategory) &&
              destination.indexWhere((p) => identical(p, dragged)) < destination.indexWhere((p) => p.id == overId)
          ? DropPlacement.after
          : DropPlacement.before);
  final insertAt = onZone ? rest.length : overIndex + (placement == DropPlacement.after ? 1 : 0);
  final next = [...rest];
  next.insertAll(_spliceIndex(insertAt, next.length), moving);
  final orderedIds = next.map((p) => p.id).toList();

  if (!grouped || sameCategory) {
    if (destination.length == next.length && _idsMatch(destination, orderedIds)) {
      return const ProjectDropNone();
    }
    return ProjectDropReorder(orderedIds);
  }
  return ProjectDropMove(
    activeIds: moving.map((p) => p.id).toList(),
    categoryName: targetKey == uncategorizedKey ? '' : targetKey,
    destOrderedIds: orderedIds,
  );
}

int _spliceIndex(int start, int length) {
  if (start < 0) return start + length < 0 ? 0 : start + length;
  return start > length ? length : start;
}

bool _idsMatch(List<Project> projects, List<String> ids) {
  for (var i = 0; i < projects.length; i++) {
    if (projects[i].id != ids[i]) return false;
  }
  return true;
}
