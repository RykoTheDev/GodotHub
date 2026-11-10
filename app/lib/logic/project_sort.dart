import '../i18n/i18n.dart';
import '../src/rust/api/types.dart';
import 'last_opened.dart';
import 'locale.dart';

enum ProjectSortOption {
  manual('manual', 'sort_manual'),
  categories('categories', 'sort_categories'),
  recent('recent', 'sort_recent'),
  nameAsc('name_asc', 'sort_name_asc'),
  nameDesc('name_desc', 'sort_name_desc'),
  createdDesc('created_desc', 'sort_created_desc'),
  createdAsc('created_asc', 'sort_created_asc'),
  timeDesc('time_desc', 'sort_time_desc');

  const ProjectSortOption(this.value, this.labelKey);

  final String value;
  final String labelKey;

  String label([Translations? translations]) {
    final tr = (translations ?? t).common;
    return switch (this) {
      manual => tr.sort_manual,
      categories => tr.sort_categories,
      recent => tr.sort_recent,
      nameAsc => tr.sort_name_asc,
      nameDesc => tr.sort_name_desc,
      createdDesc => tr.sort_created_desc,
      createdAsc => tr.sort_created_asc,
      timeDesc => tr.sort_time_desc,
    };
  }

  static ProjectSortOption? fromValue(String value) {
    for (final option in values) {
      if (option.value == value) return option;
    }
    return null;
  }
}

List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [for (final (i, item) in items.indexed) (i, item)];
  indexed.sort((a, b) {
    final result = compare(a.$2, b.$2);
    return result != 0 ? result : a.$1 - b.$1;
  });
  return [for (final entry in indexed) entry.$2];
}

double _timeOf(String? iso) {
  if (iso == null || iso.isEmpty) return double.negativeInfinity;
  return jsTimeOf(iso)?.toDouble() ?? double.negativeInfinity;
}

int _sign(double diff) => diff.isNaN || diff == 0 ? 0 : (diff < 0 ? -1 : 1);

int liveSessionMs(Project project, [int? now]) {
  final start = project.sessionStartedAtMs?.toInt() ?? 0;
  if (start == 0) return 0;
  final diff = (now ?? DateTime.now().millisecondsSinceEpoch) - start;
  return diff < 0 ? 0 : diff;
}

int effectiveTotalMs(Project project, [int? now]) =>
    project.totalTimeSeconds.toInt() * 1000 + liveSessionMs(project, now);

int Function(Project a, Project b)? comparatorFor(ProjectSortOption sort, [int? now]) {
  final at = now ?? DateTime.now().millisecondsSinceEpoch;
  return switch (sort) {
    ProjectSortOption.recent => (a, b) => _sign(_timeOf(b.lastOpened) - _timeOf(a.lastOpened)),
    ProjectSortOption.nameAsc => (a, b) => ghLocaleCompare(a.name, b.name),
    ProjectSortOption.nameDesc => (a, b) => ghLocaleCompare(b.name, a.name),
    ProjectSortOption.createdDesc => (a, b) => _sign(_timeOf(b.createdAt) - _timeOf(a.createdAt)),
    ProjectSortOption.createdAsc => (a, b) => _sign(_timeOf(a.createdAt) - _timeOf(b.createdAt)),
    ProjectSortOption.timeDesc => (a, b) => effectiveTotalMs(b, at) - effectiveTotalMs(a, at),
    ProjectSortOption.manual || ProjectSortOption.categories => null,
  };
}
