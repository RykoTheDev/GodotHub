import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/screen_reader.dart';
import 'package:godothub/state/app_signals.dart';

Widget _host({required bool enabled, TextDirection direction = TextDirection.ltr, Widget? child}) =>
    Directionality(textDirection: direction, child: ScreenReaderAnnouncer(enabled: enabled, child: child));

void main() {
  setUp(AppSignals.debugReset);

  test('announce emits app:announce with the message', () {
    final seen = <AppSignal>[];
    final sub = AppSignals.all.listen(seen.add);
    addTearDown(sub.cancel);
    announce('Project saved');
    expect(seen.single.name, announceEvent);
    expect(announceEvent, 'app:announce');
    expect(seen.single.detail, const ScreenReaderAnnouncement('Project saved'));
  });

  testWidgets('announces politely while enabled', (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    announce('Project saved');
    final announcements = tester.takeAnnouncements();
    expect(announcements, hasLength(1));
    expect(announcements.single.message, 'Project saved');
    expect(announcements.single.assertiveness, Assertiveness.polite);
    expect(announcements.single.textDirection, TextDirection.ltr);
  });

  testWidgets('repeats identical messages', (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    announce('Copied');
    announce('Copied');
    expect(tester.takeAnnouncements().map((a) => a.message), ['Copied', 'Copied']);
  });

  testWidgets('uses the ambient text direction', (tester) async {
    await tester.pumpWidget(_host(enabled: true, direction: TextDirection.rtl));
    announce('تم الحفظ');
    expect(tester.takeAnnouncements().single.textDirection, TextDirection.rtl);
  });

  testWidgets('stays silent while disabled and picks up a later enable', (tester) async {
    await tester.pumpWidget(_host(enabled: false));
    announce('Hidden');
    expect(tester.takeAnnouncements(), isEmpty);

    await tester.pumpWidget(_host(enabled: true));
    expect(tester.takeAnnouncements(), isEmpty);
    announce('Visible');
    expect(tester.takeAnnouncements().single.message, 'Visible');
  });

  testWidgets('ignores empty and malformed details', (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    announce('');
    AppSignals.emit(announceEvent);
    AppSignals.emit(announceEvent, 'raw string');
    AppSignals.emit(announceEvent, const ScreenReaderAnnouncement(null));
    expect(tester.takeAnnouncements(), isEmpty);
  });

  testWidgets('stops listening once removed', (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    await tester.pumpWidget(const SizedBox());
    announce('Gone');
    expect(tester.takeAnnouncements(), isEmpty);
  });

  testWidgets('renders its child or nothing', (tester) async {
    await tester.pumpWidget(_host(enabled: true, child: const Text('content')));
    expect(find.text('content'), findsOneWidget);
    await tester.pumpWidget(_host(enabled: false));
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
