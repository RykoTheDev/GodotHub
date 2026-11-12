import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/dashboard/activity_panel.dart';
import 'package:godothub/dashboard/dashboard_logic.dart';
import 'package:godothub/dashboard/dashboard_parts.dart';
import 'package:godothub/dashboard/dashboard_view.dart';
import 'package:godothub/logic/last_opened.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/events.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/keyboard_shortcuts.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/ui/core/interaction.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';
import '../versions/versions_test.dart' as versions;

late FakeRustApi rust;
final signals = <AppSignal>[];
StreamSubscription<AppSignal>? _signalLog;

Project project(String id, String name, {bool pinned = false, String? lastOpened, int seconds = 0}) => Project(
  id: id,
  name: name,
  path: 'C:/games/$id',
  godotVersion: '4.3',
  createdAt: '2026-01-01T00:00:00Z',
  lastOpened: lastOpened,
  pinned: pinned,
  sortOrder: 0,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.from(seconds),
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

TimeInsights insights({int thisMonth = 7200, int lastMonth = 3600, int? weekday = 2}) => TimeInsights(
  totalSeconds: BigInt.from(36000),
  longestStreakDays: 9,
  currentStreakDays: 4,
  mostProductiveWeekday: weekday,
  thisMonthSeconds: BigInt.from(thisMonth),
  lastMonthSeconds: BigInt.from(lastMonth),
);

class DashBackend {
  List<Project> projects = [];
  List<RunningProjectInfo> running = [];
  String? osName = 'ryko';
  TimeInsights timeInsights = insights();
  final ranges = <String>[];
  final calls = <String>[];

  void install(FakeRustApi rust) {
    versions.VersionsBackend().install(rust);
    rust
      ..on('crateApiProjectsListProjects', () async => projects)
      ..on('crateApiProjectsGetProjectName', ({required String path}) async => null)
      ..on('crateApiProjectsGetProjectIcon', ({required String path}) async => null)
      ..on('crateApiAppGetOsUsername', () async => osName)
      ..on('crateApiTimeStatsGetTimeInsights', () async => timeInsights)
      ..on('crateApiTimeStatsGetActivity', ({required String range}) async {
        ranges.add(range);
        if (range == 'daily') return <(String, BigInt)>[];
        return [('2026-01-05', BigInt.from(3600)), ('2026-01-06', BigInt.from(1800)), ('2026-01-07', BigInt.zero)];
      })
      ..on('crateApiProjectsListRunningProjects', () async => running)
      ..on('crateApiProjectsStopProject', ({required String id}) async => calls.add('stop:$id'))
      ..on('crateApiGodotVersionsOpenGodotVersion', ({required String tag, bool? console}) async => calls.add('open:$tag'));
  }
}

AppSettings dashSettings({String? customName, bool todos = false}) =>
    copySettings(baseSettings, setupComplete: true, projectTodosEnabled: todos, dashboardCustomName: () => customName);

Future<void> pumpDashboard(WidgetTester tester, DashBackend backend, {AppSettings? settings, Size size = const Size(1400, 1000)}) async {
  backend.install(rust);
  await base.pumpHost(tester, settings: settings ?? dashSettings(), size: size, body: const DashboardView());
  await base.settle(tester);
}

Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

Finder pressable(String label) => find.byWidgetPredicate((w) => w is GhPressable && w.semanticLabel == label);

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    debugResetOpenTodos();
    signals.clear();
    _signalLog = AppSignals.all.listen(signals.add);
  });
  tearDown(() async {
    await _signalLog?.cancel();
    _signalLog = null;
  });

  group('logic', () {
    test('greeting buckets, activity labels and weekday names', () {
      expect(
        [greetingKey(5), greetingKey(12), greetingKey(17), greetingKey(21), greetingKey(4)],
        ['morning', 'afternoon', 'evening', 'night', 'night'],
      );
      expect(activityLabel(ActivityRange.daily, '2026-01-05T00', LastOpenedTimeFormat.h12), '12a');
      expect(activityLabel(ActivityRange.daily, '2026-01-05T13', LastOpenedTimeFormat.h12), '1p');
      expect(activityLabel(ActivityRange.daily, '2026-01-05T07', LastOpenedTimeFormat.h24), '07');
      expect(activityLabel(ActivityRange.monthly, '2026-01-17', LastOpenedTimeFormat.h12), '17');
      expect(activityLabel(ActivityRange.weekly, '2026-01-05', LastOpenedTimeFormat.h12), 'Mon');
      expect(activityLabel(ActivityRange.yearly, '2026-03', LastOpenedTimeFormat.h12), 'Mar');
      expect(weekdayName(0), 'Monday');
      expect(weekdayName(6), 'Sunday');
    });

    test('recent, pinned, top by time, totals and month delta', () {
      final list = [
        project('a', 'Alpha', lastOpened: '2026-01-02T00:00:00Z', seconds: 60),
        project('b', 'Beta', pinned: true, lastOpened: '2026-01-05T00:00:00Z', seconds: 600),
        project('c', 'Gamma', pinned: true),
      ];
      expect(recentProjects(list).map((p) => p.id), ['b', 'a']);
      expect(pinnedProjects(list).map((p) => p.id), ['b', 'c']);
      expect(topProjectsByTime(list).map((p) => p.id), ['b', 'a']);
      expect(totalProjectMs(list), 660000);
      expect(monthDeltaPercent(insights(thisMonth: 7200, lastMonth: 3600)), 100);
      expect(monthDeltaPercent(insights(thisMonth: 975, lastMonth: 1000)), -2);
      expect(monthDeltaPercent(insights(lastMonth: 0)), isNull);
      expect(monthDeltaPercent(null), isNull);
      expect(dashboardDisplayName('', 'ryko'), 'ryko');
      expect(dashboardDisplayName('Captain', 'ryko'), 'Captain');
      expect(dashboardDisplayName(null, null), '');
      expect(dashboardDisplayName('x' * 50, null).length, 40);
    });
  });

  group('view', () {
    testWidgets('renders greeting, stats, activity and lists', (tester) async {
      final backend = DashBackend()
        ..projects = [
          project('a', 'Alpha', lastOpened: '2026-01-02T00:00:00Z', seconds: 3600),
          project('b', 'Beta', pinned: true, lastOpened: '2026-01-05T00:00:00Z', seconds: 7200),
        ];
      await pumpDashboard(tester, backend);

      expect(find.textContaining('ryko', findRichText: true), findsOneWidget);
      expect(find.text(td('dashboard_stat_projects').toUpperCase()), findsOneWidget);
      expect(find.text('3h 0m'), findsOneWidget);
      expect(find.text(td('dashboard_insights_days', count: 4)), findsOneWidget);
      expect(find.text(td('dashboard_insights_delta_up', args: {'pct': 100})), findsOneWidget);
      expect(find.text(td('dashboard_weekly').toUpperCase()), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(backend.ranges, ['weekly']);
      expect(find.text('Alpha'), findsNWidgets(2));
      expect(find.text('Beta'), findsNWidgets(3));
      expect(find.text(td('dashboard_running_empty')), findsOneWidget);
      expect(find.text('4.3-stable'), findsOneWidget);
      expect(find.text(td('dashboard_todos').toUpperCase()), findsNothing);
      await unmount(tester);
    });

    testWidgets('quick actions, stat card and project rows emit app signals', (tester) async {
      final backend = DashBackend()..projects = [project('a', 'Alpha', lastOpened: '2026-01-02T00:00:00Z', seconds: 60)];
      await pumpDashboard(tester, backend);

      await tester.tap(find.text(td('dashboard_new_project')));
      await tester.tap(find.text(td('dashboard_import_project')));
      await tester.tap(find.text(td('dashboard_scan_projects')));
      await tester.tap(find.text(td('dashboard_stat_projects').toUpperCase()));
      await tester.tap(find.text('C:/games/a'));
      await tester.pump();
      expect(signals.map((s) => (s.name, s.detail)), [
        (newProjectRequestSignal, null),
        (importProjectRequestSignal, null),
        (scanProjectsSignal, null),
        (setTabSignal, 'projects'),
        (openProjectSignal, 'a'),
      ]);
      await unmount(tester);
    });

    testWidgets('empty states and activity range switching', (tester) async {
      final backend = DashBackend()..timeInsights = insights(lastMonth: 0, weekday: null);
      await pumpDashboard(tester, backend);

      expect(find.text(td('dashboard_recent_empty')), findsOneWidget);
      expect(find.text(td('dashboard_pinned_empty')), findsOneWidget);
      expect(find.text(td('dashboard_top_time_empty')), findsOneWidget);
      expect(find.text(td('dashboard_insights_delta_up', args: {'pct': 0})), findsNothing);

      await tester.tap(find.text(td('dashboard_range_daily')));
      await base.settle(tester);
      expect(backend.ranges, ['weekly', 'daily']);
      expect(find.text(td('dashboard_daily').toUpperCase()), findsOneWidget);
      expect(find.text(td('dashboard_daily_empty')), findsOneWidget);
      expect(find.byType(DashActivityPanel), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('running projects follow launch and exit events and can be stopped', (tester) async {
      final backend = DashBackend()
        ..running = [RunningProjectInfo(id: 'a', name: 'Alpha', version: '4.3', launchedAtMs: BigInt.zero, console: false)];
      await pumpDashboard(tester, backend);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.textContaining('Godot 4.3 · '), findsOneWidget);

      rust.emit(
        AppEvent(
          kind: AppEventKind.projectLaunched,
          name: 'project:launched',
          json: '{}',
          projectLaunched: const ProjectLaunched(id: 'b', name: 'Beta', version: '', console: false),
        ),
      );
      await base.settle(tester, 2);
      expect(find.text('Beta'), findsOneWidget);

      await tester.ensureVisible(pressable('${td('stop')} Alpha'));
      await base.settle(tester, 2);
      await tester.tap(pressable('${td('stop')} Alpha'));
      await tester.pump();
      expect(backend.calls, ['stop:a']);

      rust.emit(
        AppEvent(
          kind: AppEventKind.projectExited,
          name: 'project:exited',
          json: '{}',
          projectExited: const ProjectExited(id: 'a'),
        ),
      );
      await base.settle(tester, 2);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);

      await tester.ensureVisible(pressable('4.3-stable'));
      await base.settle(tester, 2);
      await tester.tap(pressable('4.3-stable'));
      await tester.pump();
      expect(backend.calls, ['stop:a', 'open:4.3-stable']);
      await unmount(tester);
    });

    testWidgets('renames the greeting with Enter, cancels with Escape and resets', (tester) async {
      await pumpDashboard(tester, DashBackend());
      expect(find.textContaining('ryko', findRichText: true), findsOneWidget);

      await tester.tap(pressable(td('dashboard_rename_aria')));
      await base.settle(tester, 2);
      final field = find.byType(EditableText);
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Captain Nemo the Explorer');
      await tester.pump();
      expect(tester.widget<EditableText>(field).controller.text, 'Captain Nemo th');
      await tester.enterText(field, 'Captain');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await base.settle(tester, 3);
      expect(find.textContaining('Captain', findRichText: true), findsOneWidget);

      await tester.tap(pressable(td('dashboard_rename_aria')));
      await base.settle(tester, 2);
      await tester.enterText(find.byType(EditableText), 'Nope');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await base.settle(tester, 3);
      expect(find.byType(EditableText), findsNothing);
      expect(find.textContaining('Captain', findRichText: true), findsOneWidget);

      await tester.tap(pressable(td('dashboard_rename_reset')));
      await base.settle(tester, 3);
      expect(find.textContaining('ryko', findRichText: true), findsOneWidget);
      expect(pressable(td('dashboard_rename_reset')), findsNothing);
      await unmount(tester);
    });

    testWidgets('narrow windows stack the panels in one column', (tester) async {
      final backend = DashBackend();
      await pumpDashboard(tester, backend, size: const Size(900, 1400));
      final running = tester.getTopLeft(find.text(td('dashboard_running').toUpperCase()));
      final pinned = tester.getTopLeft(find.text(td('dashboard_pinned').toUpperCase()));
      expect(pinned.dy, greaterThan(running.dy));
      expect((pinned.dx - running.dx).abs(), lessThan(1));
      await unmount(tester);
    });
  });
}
