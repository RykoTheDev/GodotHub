import '../src/rust/api/changelog.dart' as rust;
import '../src/rust/api/types.dart';

abstract final class ChangelogApi {
  static Future<List<ChangelogEntry>> list() => rust.listChangelogEntries();

  static Future<List<String>> listGitTags() => rust.listGitTags();

  static Future<ChangelogDraft> generateDraft(String from, String to) => rust.generateChangelogDraft(from: from, to: to);

  static Future<ChangelogEntry> add(String version, String date, List<ChangelogNote> notes, List<String> knownIssues) =>
      rust.addChangelogEntry(version: version, date: date, notes: notes, knownIssues: knownIssues);

  static Future<ChangelogEntry> update(String id, String version, String date, List<ChangelogNote> notes, List<String> knownIssues) =>
      rust.updateChangelogEntry(id: id, version: version, date: date, notes: notes, knownIssues: knownIssues);

  static Future<void> delete(String id) => rust.deleteChangelogEntry(id: id);
}
