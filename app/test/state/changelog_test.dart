import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/changelog.dart';
import 'package:godothub/titlebar/providers.dart' as titlebar;

import '../support/fake_rust.dart';

ChangelogEntry entry(String id) =>
    ChangelogEntry(id: id, version: '1.$id', date: '2026-01-01', notes: const [], knownIssues: const [], createdAt: 0);

void main() {
  late FakeRustApi rust;
  late MemoryUiPrefsBackend prefs;
  late List<ChangelogEntry> entries;

  void usePrefs([Map<String, String>? values]) {
    prefs = MemoryUiPrefsBackend(values);
    UiPrefsStore.instance = UiPrefsStore(prefs)..fill(values ?? {});
  }

  setUp(() {
    rust = installFakeRust();
    usePrefs();
    entries = [entry('a')];
    rust.on('crateApiChangelogListChangelogEntries', () async => entries);
  });

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('changelogProvider', () {
    test('loads entries and refreshes plus signals after add and update', () async {
      final c = container();
      final signals = <String>[];
      AppSignals.on(changelogEntryAddedSignal).listen((s) => signals.add(s.name));
      final sub = c.listen(changelogProvider, (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(c.read(changelogProvider).data.map((e) => e.id), ['a']);

      rust.on('crateApiChangelogAddChangelogEntry', ({
        required String version,
        required String date,
        required List<ChangelogNote> notes,
        required List<String> knownIssues,
      }) async {
        entries = [...entries, entry('b')];
        return entries.last;
      });
      await c.read(changelogProvider.notifier).addEntry('1.b', '2026-01-02', const [], const []);
      expect(c.read(changelogProvider).data.map((e) => e.id), ['a', 'b']);
      expect(signals, [changelogEntryAddedSignal]);

      rust.on('crateApiChangelogUpdateChangelogEntry', ({
        required String id,
        required String version,
        required String date,
        required List<ChangelogNote> notes,
        required List<String> knownIssues,
      }) async => entries.first);
      await c.read(changelogProvider.notifier).updateEntry('a', '1.a', '2026-01-03', const [], const []);
      expect(signals, hasLength(2));

      rust.on('crateApiChangelogDeleteChangelogEntry', ({required String id}) async {
        entries = entries.where((e) => e.id != id).toList();
      });
      await c.read(changelogProvider.notifier).removeEntry('a');
      expect(c.read(changelogProvider).data.map((e) => e.id), ['b']);
      expect(signals, hasLength(2));
      expect(rust.callCount('crateApiChangelogListChangelogEntries'), 4);
    });
  });

  group('changelogBadgeProvider', () {
    test('is the provider the title bar watches', () {
      expect(identical(titlebar.changelogBadgeProvider, changelogBadgeProvider), isTrue);
    });

    test('first load marks every entry seen and persists the ids', () async {
      final c = container();
      final sub = c.listen(changelogBadgeProvider, (_, _) {});
      addTearDown(sub.close);
      expect(c.read(changelogBadgeProvider), isFalse);
      await pumpEventQueue();
      expect(c.read(changelogBadgeProvider), isFalse);
      await UiPrefsStore.instance.flush();
      expect(prefs.values[changelogSeenKey], '"[\\"a\\"]"');
    });

    test('a new entry signal refetches and lights the badge until markSeen', () async {
      usePrefs({changelogSeenKey: '"[\\"a\\"]"'});
      final c = container();
      final sub = c.listen(changelogBadgeProvider, (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(c.read(changelogBadgeProvider), isFalse);

      entries = [entry('a'), entry('b')];
      AppSignals.emit(changelogEntryAddedSignal);
      await pumpEventQueue();
      expect(rust.callCount('crateApiChangelogListChangelogEntries'), 2);
      expect(c.read(changelogBadgeProvider), isTrue);

      c.read(changelogBadgeProvider.notifier).markSeen();
      expect(c.read(changelogBadgeProvider), isFalse);
      await UiPrefsStore.instance.flush();
      expect(prefs.values[changelogSeenKey], '"[\\"a\\",\\"b\\"]"');
    });

    test('stored seen ids light the badge on load and markSeen is ignored before loading', () async {
      usePrefs({changelogSeenKey: '"[]"'});
      final c = container();
      final sub = c.listen(changelogBadgeProvider, (_, _) {});
      addTearDown(sub.close);
      c.read(changelogBadgeProvider.notifier).markSeen();
      expect(c.read(changelogBadgeProvider.notifier).seenIds, isEmpty);
      await pumpEventQueue();
      expect(c.read(changelogBadgeProvider), isTrue);
    });
  });
}
