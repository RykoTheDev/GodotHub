import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/changelog/changelog_view.dart';
import 'package:godothub/modals/changelog_entry_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/changelog.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
late MemoryUiPrefsBackend prefs;

String tc(String key, {Map<String, Object?> args = const {}}) => ghTr('changelog:$key', args: args);

ChangelogEntry entry(String id, String version, {List<ChangelogNote> notes = const [], List<String> issues = const []}) =>
    ChangelogEntry(id: id, version: version, date: '2026-03-04', notes: notes, knownIssues: issues, createdAt: 0);

class ChangelogBackend {
  List<ChangelogEntry> entries = [
    entry(
      'e2',
      'v2.0',
      notes: const [
        ChangelogNote(category: 'add', text: 'Added dashboards'),
        ChangelogNote(category: 'add', text: 'Added news'),
        ChangelogNote(category: 'fix', text: 'Fixed crash'),
      ],
      issues: const ['Slow on first launch'],
    ),
    entry('e1', 'v1.0', notes: const [ChangelogNote(category: 'improve', text: 'Faster scans')]),
  ];
  final calls = <String>[];

  void install(FakeRustApi rust) {
    rust
      ..on('crateApiChangelogListChangelogEntries', () async => entries)
      ..on('crateApiChangelogAddChangelogEntry', ({
        required String version,
        required String date,
        required List<ChangelogNote> notes,
        required List<String> knownIssues,
      }) async {
        calls.add('add:$version:$date:${[for (final n in notes) '${n.category}=${n.text}'].join(',')}:${knownIssues.join(',')}');
        final created = entry('e${entries.length + 1}', version, notes: notes, issues: knownIssues);
        entries = [created, ...entries];
        return created;
      })
      ..on('crateApiChangelogUpdateChangelogEntry', ({
        required String id,
        required String version,
        required String date,
        required List<ChangelogNote> notes,
        required List<String> knownIssues,
      }) async {
        calls.add('update:$id:$version');
        return entry(id, version, notes: notes, issues: knownIssues);
      })
      ..on('crateApiChangelogDeleteChangelogEntry', ({required String id}) async {
        calls.add('delete:$id');
        entries = [for (final e in entries) if (e.id != id) e];
      });
  }
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    prefs = MemoryUiPrefsBackend();
    UiPrefsStore.instance = UiPrefsStore(prefs);
  });

  test('today is a utc iso date and dates format', () {
    expect(changelogTodayIso(DateTime.utc(2026, 1, 5, 23)), '2026-01-05');
    expect(formatChangelogDate(''), '');
    expect(formatChangelogDate('not a date'), 'not a date');
    expect(formatChangelogDate('2026-03-04'), isNot('2026-03-04'));
  });

  testWidgets('lists entries with grouped notes and marks the badge seen', (tester) async {
    final backend = ChangelogBackend()..install(rust);
    UiPrefsStore.instance.setItem(changelogSeenKey, jsonEncode(['e1']));
    late WidgetRef captured;
    await base.pumpHost(
      tester,
      body: Consumer(
        builder: (context, ref, _) {
          captured = ref;
          ref.watch(changelogBadgeProvider);
          return const ChangelogView(devTools: false);
        },
      ),
    );
    await base.settle(tester);
    expect(find.text('v2.0'), findsOneWidget);
    expect(find.text('v1.0'), findsOneWidget);
    expect(find.text('2 ${tc('added')}'), findsOneWidget);
    expect(find.text('1 ${tc('fixed')}'), findsOneWidget);
    expect(find.text('1 ${tc('changelog_known_issues')}'), findsOneWidget);
    expect(find.text('Added dashboards'), findsOneWidget);
    expect(find.text('Slow on first launch'), findsOneWidget);
    expect(find.text(tc('added').toUpperCase()), findsOneWidget);
    expect(find.text(ghTr('add_entry')), findsNothing);
    expect(find.byTooltip(tc('edit_entry_aria', args: {'version': 'v2.0'})), findsNothing);
    expect(captured.read(changelogBadgeProvider), isFalse);
    expect(jsonDecode(UiPrefsStore.instance.getItem(changelogSeenKey)!), ['e2', 'e1']);
    expect(backend.calls, isEmpty);
  });

  testWidgets('shows the empty state', (tester) async {
    (ChangelogBackend()..entries = []).install(rust);
    await base.pumpHost(tester, body: const ChangelogView(devTools: true));
    await base.settle(tester);
    expect(find.text(tc('no_entries')), findsOneWidget);
    expect(find.text(ghTr('changelog_generate_from_git')), findsOneWidget);
  });

  testWidgets('adds, edits and deletes entries with the dev tools', (tester) async {
    final backend = ChangelogBackend()..install(rust);
    await base.pumpHost(tester, body: const ChangelogView(devTools: true));
    await base.settle(tester);

    await tester.tap(find.text(ghTr('add_entry')));
    await base.settle(tester);
    expect(find.text(ghTr('new_entry').toUpperCase()), findsOneWidget);
    await tester.tap(find.widgetWithText(GestureDetector, ghTr('add_entry')).last);
    await base.settle(tester, 3);
    expect(find.text(ghTr('changelog_error_no_version')), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'v3.0');
    await tester.enterText(find.byType(EditableText).at(2), 'New view');
    await tester.tap(find.byTooltip(ghTr('fix')));
    await tester.pump();
    await tester.tap(find.text(ghTr('changelog_add_known_issue')));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).at(3), 'Known bug');
    await tester.tap(find.text(ghTr('add_entry')).last);
    await base.settle(tester);
    expect(backend.calls.single, startsWith('add:v3.0:'));
    expect(backend.calls.single, endsWith(':fix=New view:Known bug'));
    expect(find.text(ghTr('new_entry').toUpperCase()), findsNothing);
    expect(find.text('v3.0'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(tc('edit_entry_aria', args: {'version': 'v2.0'})));
    await base.settle(tester);
    expect(find.text(ghTr('edit_entry').toUpperCase()), findsOneWidget);
    expect(find.text('Added dashboards'), findsWidgets);
    await tester.tap(find.text(ghTr('save_changes')));
    await base.settle(tester);
    expect(backend.calls.last, 'update:e2:v2.0');

    await tester.tap(find.bySemanticsLabel(tc('delete_entry_aria', args: {'version': 'v1.0'})));
    await base.settle(tester);
    expect(find.text(tc('delete_entry_title').toUpperCase()), findsOneWidget);
    await tester.tap(find.text(tc('delete')).last);
    await base.settle(tester);
    expect(backend.calls.last, 'delete:e1');
    expect(find.text('v1.0'), findsNothing);
  });

  testWidgets('entry modal adds and removes lines from the keyboard', (tester) async {
    final saved = <String>[];
    await base.openModal(
      tester,
      (close) => ChangelogEntryModal(
        initial: (version: 'v9', date: '2026-01-01', notes: const [ChangelogNote(category: 'improve', text: 'Draft line')]),
        onClose: close,
        onSave: (version, date, notes, issues) async {
          saved.add('$version|$date|${[for (final n in notes) '${n.category}=${n.text}'].join(',')}|${issues.join(',')}');
        },
      ),
    );
    expect(find.text('Draft line'), findsOneWidget);
    expect(find.text(ghTr('changelog_known_issues_none')), findsOneWidget);
    expect(find.bySemanticsLabel(ghTr('changelog_remove_line_aria')), findsNothing);

    await tester.tap(find.text('Draft line'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byType(EditableText), findsNWidgets(4));
    expect(find.bySemanticsLabel(ghTr('changelog_remove_line_aria')), findsNWidgets(2));
    await tester.tap(find.bySemanticsLabel(ghTr('changelog_remove_line_aria')).last);
    await tester.pump();
    expect(find.byType(EditableText), findsNWidgets(3));

    await tester.tap(find.text(ghTr('changelog_add_known_issue')));
    await tester.pump();
    expect(find.text(ghTr('changelog_known_issues_none')), findsNothing);
    await tester.tap(find.bySemanticsLabel(ghTr('changelog_remove_known_issue_aria')));
    await tester.pump();
    expect(find.text(ghTr('changelog_known_issues_none')), findsOneWidget);

    await tester.tap(find.text(ghTr('add_entry')));
    await base.settle(tester);
    expect(saved, ['v9|2026-01-01|improve=Draft line|']);
  });
}
