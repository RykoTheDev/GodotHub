import '../src/rust/api/types.dart';
import 'locale.dart';
import 'project_sort.dart';

enum ProjectSearchField { name, tag, category, version, path, pinned }

const _fieldAliases = <String, ProjectSearchField>{
  'name': ProjectSearchField.name,
  'tag': ProjectSearchField.tag,
  'tags': ProjectSearchField.tag,
  'category': ProjectSearchField.category,
  'cat': ProjectSearchField.category,
  'version': ProjectSearchField.version,
  'engine': ProjectSearchField.version,
  'path': ProjectSearchField.path,
  'folder': ProjectSearchField.path,
  'dir': ProjectSearchField.path,
  'pinned': ProjectSearchField.pinned,
  'pin': ProjectSearchField.pinned,
};

const _pinnedTrue = ['true', 'yes', 'on', '1', 'y', 't'];
const _pinnedFalse = ['false', 'no', 'off', '0', 'n', 'f'];

class ProjectSearchToken {
  const ProjectSearchToken({
    required this.raw,
    required this.start,
    required this.end,
    required this.field,
    required this.value,
  });

  final String raw;
  final int start;
  final int end;
  final ProjectSearchField? field;
  final String value;
}

class ProjectSearchFilter {
  const ProjectSearchFilter(this.field, this.value);

  final ProjectSearchField field;
  final String value;

  @override
  bool operator ==(Object other) => other is ProjectSearchFilter && other.field == field && other.value == value;

  @override
  int get hashCode => Object.hash(field, value);

  @override
  String toString() => '${field.name}:$value';
}

class ParsedProjectQuery {
  const ParsedProjectQuery({
    required this.text,
    required this.filters,
    required this.activeToken,
    required this.active,
  });

  final List<String> text;
  final List<ProjectSearchFilter> filters;
  final ProjectSearchToken? activeToken;
  final bool active;
}

final _nonSpace = RegExp(r'\S+');
final _versionSeparators = RegExp(r'[.\s_-]+');
final _nameSeparators = RegExp(r'[\s._-]+');

String _slice(String text, int start, [int? end]) {
  final from = start.clamp(0, text.length);
  final to = (end ?? text.length).clamp(from, text.length);
  return text.substring(from, to);
}

List<ProjectSearchToken> _tokenize(String input) {
  final tokens = <ProjectSearchToken>[];
  for (final match in _nonSpace.allMatches(input)) {
    final raw = match[0]!;
    final start = match.start;
    final end = start + raw.length;
    final sep = raw.toLowerCase().indexOf(':');
    ProjectSearchField? field;
    var value = '';
    if (sep > 0) {
      final resolved = _fieldAliases[_slice(raw, 0, sep).toLowerCase()];
      if (resolved != null) {
        field = resolved;
        value = _slice(raw, sep + 1);
      }
    }
    tokens.add(ProjectSearchToken(raw: raw, start: start, end: end, field: field, value: value));
  }
  return tokens;
}

ProjectSearchToken? _findActiveToken(List<ProjectSearchToken> tokens, int caret) {
  for (final token in tokens) {
    if (caret >= token.start && caret <= token.end) return token;
  }
  return null;
}

ParsedProjectQuery parseProjectQuery(String input, [int? caret]) {
  final tokens = _tokenize(input);
  final activeToken = _findActiveToken(tokens, caret ?? input.length);
  final text = <String>[];
  final filters = <ProjectSearchFilter>[];
  for (final token in tokens) {
    final field = token.field;
    if (field != null) {
      final value = token.value.trim().toLowerCase();
      if (value.isNotEmpty) {
        filters.add(ProjectSearchFilter(field, value));
      } else if (field == ProjectSearchField.pinned) {
        filters.add(const ProjectSearchFilter(ProjectSearchField.pinned, ''));
      }
      continue;
    }
    if (identical(token, activeToken) && token.raw.startsWith('/')) continue;
    text.add(token.raw.toLowerCase());
  }
  return ParsedProjectQuery(
    text: text,
    filters: filters,
    activeToken: activeToken,
    active: text.isNotEmpty || filters.isNotEmpty,
  );
}

bool _includesLower(String? haystack, String needle) => (haystack ?? '').toLowerCase().contains(needle);

bool _matchesVersion(String? version, String term) {
  final value = (version ?? '').toLowerCase();
  if (value.isEmpty || term.isEmpty) return false;
  if (value.startsWith(term)) return true;
  return value.split(_versionSeparators).any((segment) => segment.isNotEmpty && segment.startsWith(term));
}

bool _matchesPinned(Project project, String value) {
  if (value.isEmpty) return project.pinned;
  if (_pinnedFalse.contains(value)) return !project.pinned;
  if (_pinnedTrue.contains(value)) return project.pinned;
  return project.pinned;
}

bool _matchesFilter(Project project, ProjectSearchField field, String value) => switch (field) {
  ProjectSearchField.name => _includesLower(project.name, value),
  ProjectSearchField.tag => project.tags.any((tag) => tag.toLowerCase().contains(value)),
  ProjectSearchField.category => _includesLower(project.category, value),
  ProjectSearchField.version => _matchesVersion(project.godotVersion, value),
  ProjectSearchField.path => _includesLower(project.path, value),
  ProjectSearchField.pinned => _matchesPinned(project, value),
};

int _termScore(Project project, String term) {
  final name = project.name.toLowerCase();
  if (name == term) return 120;
  if (name.startsWith(term)) return 90;
  if (name.split(_nameSeparators).any((word) => word.startsWith(term))) return 70;
  if (name.contains(term)) return 50;
  if (project.tags.any((tag) => tag.toLowerCase().contains(term))) return 30;
  if (_includesLower(project.category, term)) return 24;
  if (_matchesVersion(project.godotVersion, term)) return 20;
  if (_includesLower(project.path, term)) return 12;
  return 0;
}

int? matchProject(Project project, ParsedProjectQuery query) {
  if (!query.active) return 0;
  for (final filter in query.filters) {
    if (!_matchesFilter(project, filter.field, filter.value)) return null;
  }
  var total = 0;
  for (final term in query.text) {
    final score = _termScore(project, term);
    if (score == 0) return null;
    total += score;
  }
  return total;
}

({String value, int caret}) replaceToken(String input, ({int start, int end}) token, String replacement) {
  final value = _slice(input, 0, token.start) + replacement + _slice(input, token.end);
  return (value: value, caret: token.start + replacement.length);
}

extension ProjectSearchTokenRange on ProjectSearchToken {
  ({int start, int end}) get range => (start: start, end: end);
}

List<String> collectTags(List<Project> projects) {
  final seen = <String>{};
  for (final project in projects) {
    for (final tag in project.tags) {
      final trimmed = tag.trim();
      if (trimmed.isNotEmpty) seen.add(trimmed);
    }
  }
  return stableSorted(seen, ghLocaleCompare);
}

List<String> collectVersions(List<Project> projects) {
  final seen = <String>{};
  for (final project in projects) {
    final version = project.godotVersion.trim();
    if (version.isNotEmpty) seen.add(version);
  }
  return stableSorted(seen, (a, b) => ghLocaleCompare(b, a));
}
