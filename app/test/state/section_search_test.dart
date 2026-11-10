import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/state/section_search.dart';

void main() {
  test('matchesSearch needs every word somewhere in the terms', () {
    expect(matchesSearch('', ['anything']), isTrue);
    expect(matchesSearch('   ', const []), isTrue);
    expect(matchesSearch('Dark theme', ['Appearance', 'Theme mode', 'dark or light']), isTrue);
    expect(matchesSearch('dark contrast', ['Appearance', null, 'Theme mode dark']), isFalse);
    expect(matchesSearch('ode da', ['Theme mode', 'dark']), isTrue);
  });

  test('tracks reported matches and no-results', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(sectionSearchProvider, (_, _) {});
    addTearDown(sub.close);
    final search = c.read(sectionSearchProvider.notifier);
    expect(c.read(sectionSearchProvider).visible, isNull);

    search.setQuery('zzz');
    expect(c.read(sectionSearchProvider).noResults, isFalse);
    search.reportMatch('appearance', false);
    expect(c.read(sectionSearchProvider).visible, isEmpty);
    expect(c.read(sectionSearchProvider).noResults, isTrue);

    search.reportMatch('git', true);
    search.reportMatch('motion', true);
    search.reportMatch('git', false);
    expect(c.read(sectionSearchProvider).visible, {'motion'});
    expect(c.read(sectionSearchProvider).noResults, isFalse);

    search.reset();
    expect(c.read(sectionSearchProvider).visible, isNull);
    expect(c.read(sectionSearchProvider).query, 'zzz');
  });

  testWidgets('clear empties the query and focuses the search field', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(sectionSearchProvider, (_, _) {});
    addTearDown(sub.close);
    final search = c.read(sectionSearchProvider.notifier);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: Scaffold(body: TextField(focusNode: search.focusNode))),
      ),
    );
    search.setQuery('motion');
    expect(search.focusNode.hasFocus, isFalse);
    search.clear();
    expect(c.read(sectionSearchProvider).query, '');
    await tester.pump();
    expect(search.focusNode.hasFocus, isTrue);
  });
}
