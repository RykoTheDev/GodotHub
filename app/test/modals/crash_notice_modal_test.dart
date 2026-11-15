import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/modals/bug_report_modal.dart';
import 'package:godothub/modals/crash_notice_modal.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../ui/i18n_setup.dart';
import 'beta_ended_modal_test.dart' show open;

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
  });
  setUp(setUpTestI18n);

  testWidgets('says what happened and offers a bug report', (tester) async {
    var reported = 0;
    var closed = 0;
    await open(
      tester,
      (close) => CrashNoticeModal(
        version: '1.6.0',
        rolledBackTo: '1.5.9',
        onClose: () {
          closed++;
          close();
        },
        onReport: () => reported++,
      ),
    );
    expect(find.text(ghTr('crash_notice_title').toUpperCase()), findsOneWidget);
    expect(find.text(ghTr('crash_notice_desc', args: {'version': '1.6.0'})), findsOneWidget);
    expect(find.text(ghTr('crash_notice_rolled_back', args: {'previous': '1.5.9'})), findsOneWidget);
    expect(find.text(ghTr('crash_notice_log')), findsOneWidget);
    await tester.tap(find.text(ghTr('report_a_bug')));
    expect(reported, 1);
    await tester.tap(find.text(ghTr('dismiss')));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('leaves out the rollback line when nothing was rolled back', (tester) async {
    await open(tester, (close) => CrashNoticeModal(version: '1.6.0', onClose: close, onReport: () {}));
    expect(find.text(ghTr('crash_notice_rolled_back', args: {'previous': '1.5.9'})), findsNothing);
  });

  test('the bug report shows the log and the issue gets its newest part', () {
    const log = '2026-11-15 10:00:00 [launcher] GodotHub 1.6.0 closed unexpectedly (exit code 0xC0000005)';
    final report = assembleBugReport('It crashed', 'specs', 'errors', log);
    expect(report, endsWith('## ${ghTr('bug_report_log')}\n\n```\n$log\n```'));
    expect(assembleBugReport('It crashed', 'specs', 'errors'), isNot(contains(ghTr('bug_report_log'))));

    final long = List.generate(200, (i) => 'line $i ${'x' * 40}').join('\n');
    final context = Uri.parse(bugReportIssueUrl('It crashed', 'specs', 'errors', long)).queryParameters['additional-context']!;
    expect(context, contains('line 199'));
    expect(context, isNot(contains('line 0 ')));
    expect(context.length, lessThan(bugReportMaxIssueLogChars + 100));
    expect(Uri.parse(bugReportIssueUrl('d', 's', 'e')).queryParameters.containsKey('additional-context'), isFalse);
  });
}
