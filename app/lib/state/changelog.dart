import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/changelog.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import 'api_data.dart';
import 'app_signals.dart';

const changelogEntryAddedSignal = 'app:changelog-entry-added';
const changelogSeenKey = 'changelog_seen_ids';

final changelogProvider = NotifierProvider<ChangelogNotifier, ApiData<List<ChangelogEntry>>>(ChangelogNotifier.new);

class ChangelogNotifier extends ApiDataNotifier<List<ChangelogEntry>> {
  @override
  List<ChangelogEntry> get initial => const [];

  @override
  Future<List<ChangelogEntry>> fetch() => ChangelogApi.list();

  Future<void> addEntry(String version, String date, List<ChangelogNote> notes, List<String> knownIssues) async {
    await ChangelogApi.add(version, date, notes, knownIssues);
    await refresh();
    AppSignals.emit(changelogEntryAddedSignal);
  }

  Future<void> updateEntry(String id, String version, String date, List<ChangelogNote> notes, List<String> knownIssues) async {
    await ChangelogApi.update(id, version, date, notes, knownIssues);
    await refresh();
    AppSignals.emit(changelogEntryAddedSignal);
  }

  Future<void> removeEntry(String id) async {
    await ChangelogApi.delete(id);
    await refresh();
  }
}

final changelogBadgeEntriesProvider = NotifierProvider<ChangelogBadgeEntriesNotifier, ApiData<List<ChangelogEntry>>>(
  ChangelogBadgeEntriesNotifier.new,
);

class ChangelogBadgeEntriesNotifier extends ApiDataNotifier<List<ChangelogEntry>> {
  @override
  List<ChangelogEntry> get initial => const [];

  @override
  Future<List<ChangelogEntry>> fetch() => ChangelogApi.list();

  @override
  void setup() => ref.listenSignal(changelogEntryAddedSignal, (_) => refresh());
}

List<String>? readSeenIds(String key) {
  try {
    final raw = UiPrefsStore.instance.getItem(key);
    final saved = jsonDecode(raw ?? 'null');
    return saved is List ? saved.whereType<String>().toList() : null;
  } catch (_) {
    return null;
  }
}

void writeSeenIds(String key, List<String> ids) {
  try {
    UiPrefsStore.instance.setItem(key, jsonEncode(ids));
  } catch (_) {}
}

final changelogBadgeProvider = NotifierProvider<ChangelogBadgeNotifier, bool>(ChangelogBadgeNotifier.new);

class ChangelogBadgeNotifier extends Notifier<bool> {
  List<String>? _seen;
  bool _read = false;

  List<String>? get seenIds => _seen;

  @override
  bool build() {
    if (!_read) {
      _read = true;
      _seen = readSeenIds(changelogSeenKey);
    }
    final entries = ref.watch(changelogBadgeEntriesProvider);
    if (entries.loaded && _seen == null) {
      _store(entries.data);
    }
    return _hasNew(entries.data);
  }

  bool _hasNew(List<ChangelogEntry> entries) {
    final seen = _seen;
    return seen != null && entries.any((entry) => !seen.contains(entry.id));
  }

  void _store(List<ChangelogEntry> entries) {
    final ids = [for (final entry in entries) entry.id];
    _seen = ids;
    writeSeenIds(changelogSeenKey, ids);
  }

  void markSeen() {
    final entries = ref.read(changelogBadgeEntriesProvider);
    if (!entries.loaded) return;
    _store(entries.data);
    state = _hasNew(entries.data);
  }
}
