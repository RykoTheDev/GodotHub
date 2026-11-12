import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/news.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/news/news_view.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
final opened = <String>[];

NewsItem item(int i) => NewsItem(
  id: 'n$i',
  title: 'News $i',
  link: 'https://godotengine.org/article/$i',
  published: '2026-03-0${i % 9 + 1}T10:00:00Z',
  summary: 'Summary $i',
  author: 'Author $i',
  category: i.isEven ? 'Release' : null,
);

final items = [for (var i = 0; i < 25; i++) item(i)];

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    opened.clear();
    NewsApi.debugResetCache();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
  });
  tearDown(() => OpenerApi.debugOpenUrl = null);

  test('columns split in order and dates format', () {
    expect(splitNewsColumns([1, 2, 3, 4, 5], 2), [
      [1, 2, 3],
      [4, 5],
    ]);
    expect(splitNewsColumns([1, 2], 1), [
      [1, 2],
    ]);
    expect(formatNewsDate(null), isNull);
    expect(formatNewsDate('nope'), isNull);
    expect(formatNewsDate('2026-03-04T12:00:00Z'), isNotNull);
  });

  testWidgets('shows the error state and retries', (tester) async {
    var fail = true;
    rust.on('crateApiNewsFetchGodotNews', () async {
      if (fail) throw StateError('offline');
      return NewsResponse(items: items, fromCache: true);
    });
    await base.pumpHost(tester, body: const NewsView());
    await base.settle(tester);
    expect(find.textContaining('offline'), findsOneWidget);
    fail = false;
    await tester.tap(find.text(ghTr('try_again')));
    await base.settle(tester);
    expect(find.text('News 0'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);
  });

  testWidgets('lists cards, pages, opens links and refreshes', (tester) async {
    rust.on('crateApiNewsFetchGodotNews', () async => NewsResponse(items: items, fromCache: true));
    await base.pumpHost(tester, body: const NewsView());
    await base.settle(tester);
    expect(find.text('News 9', skipOffstage: false), findsOneWidget);
    expect(find.text('News 10', skipOffstage: false), findsNothing);
    expect(find.text(ghTr('news_cached')), findsOneWidget);
    expect(find.text('RELEASE'), findsWidgets);
    expect(find.text('Author 0'), findsOneWidget);

    await tester.ensureVisible(find.text(ghTr('show_more')));
    await tester.tap(find.text(ghTr('show_more')));
    await base.settle(tester);
    expect(find.text('News 19', skipOffstage: false), findsOneWidget);

    await tester.ensureVisible(find.text('News 3'));
    await tester.tap(find.text('News 3'));
    await base.settle(tester, 2);
    expect(opened, ['https://godotengine.org/article/3']);

    final before = rust.callCount('crateApiNewsFetchGodotNews');
    await tester.tap(find.text(ghTr('refresh')));
    await base.settle(tester);
    expect(rust.callCount('crateApiNewsFetchGodotNews'), before + 1);
    expect(find.text('News 10', skipOffstage: false), findsNothing);
  });

  testWidgets('shows the empty state', (tester) async {
    rust.on('crateApiNewsFetchGodotNews', () async => const NewsResponse(items: [], fromCache: false));
    await base.pumpHost(tester, body: const NewsView());
    await base.settle(tester);
    expect(find.text(ghTr('news_empty')), findsOneWidget);
    expect(find.text(ghTr('news_cached')), findsNothing);
  });
}
