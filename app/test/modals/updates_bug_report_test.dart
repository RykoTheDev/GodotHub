import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/bug_report_modal.dart';
import 'package:godothub/modals/check_for_updates_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_version.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';
import 'package:godothub/ui/feedback/toast.dart';
import 'package:godothub/ui/feedback/toast_host.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

final opened = <String>[];

Future<void> openWith(
  WidgetTester tester,
  Widget Function(VoidCallback close) builder, {
  AppSettings? settings,
  List<Override> overrides = const [],
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext host;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeSettings(() => settings ?? copySettings(baseSettings, setupComplete: true)),
        appVersionLoaderProvider.overrideWithValue(() async => '2.0.0'),
        ...overrides,
      ],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: GhToastHost(
            child: Builder(
              builder: (context) {
                host = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    ),
  );
  await base.settle(tester, 2);
  showGhModal<void>(host, (modal) => builder(() => Navigator.of(modal).pop())).ignore();
  await base.settle(tester);
}

Override checker(Future<AppUpdate?> Function() check, {bool portable = false}) => appUpdateCheckProvider.overrideWithValue(check);

Override portableIs(bool value) => portableInstallCheckProvider.overrideWithValue(() async => value);

const notes = '''Intro line.
## Added
- New thing
- Another
## Known issues
- Slow start
## Empty
''';

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    installFakeRust();
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    opened.clear();
    ghToasts.clear();
    BugReportErrorLog.debugReset();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
  });
  tearDown(() {
    OpenerApi.debugOpenUrl = null;
    BugReportModal.debugSaveReport = null;
  });

  group('update logic', () {
    test('release notes split intro, sections and known issues, dropping empty sections', () {
      final parsed = parseReleaseNotes(notes);
      expect(parsed.intro, ['Intro line.']);
      expect(parsed.sections.map((s) => s.title), ['Added', 'Known issues']);
      expect(parsed.sections.first.items, ['New thing', 'Another']);
      expect(parsed.sections.last.isKnownIssues, isTrue);
      expect(parseReleaseNotes(null).sections, isEmpty);
    });

    test('token hints follow the status code and whether a token is set', () {
      expect(githubTokenHint('HTTP 401', hasToken: false), GithubTokenHint.tokenRejected);
      expect(githubTokenHint('HTTP 403', hasToken: false), GithubTokenHint.rateLimited);
      expect(githubTokenHint('API rate limit exceeded', hasToken: true), GithubTokenHint.tokenRejected);
      expect(githubTokenHint('network down', hasToken: false), isNull);
    });
  });

  group('CheckForUpdatesModal', () {
    testWidgets('reports up to date with the current version', (tester) async {
      await openWith(tester, (close) => CheckForUpdatesModal(onClose: close), overrides: [checker(() async => null), portableIs(false)]);
      expect(find.text(ghTr('up_to_date')), findsOneWidget);
      expect(find.text(ghTr('is_latest', args: {'version': '2.0.0'})), findsOneWidget);
      await tester.tap(find.text(ghTr('close')));
      await base.settle(tester);
      expect(find.byType(CheckForUpdatesModal), findsNothing);
    });

    testWidgets('shows the available update, notes and known issues, then downloads with progress', (tester) async {
      String? token;
      late void Function(UpdateDownloadProgress) report;
      final finish = <void Function()>[];
      var restarts = 0;
      await openWith(
        tester,
        (close) => CheckForUpdatesModal(onClose: close),
        settings: copySettings(baseSettings, setupComplete: true, githubToken: () => ' tok '),
        overrides: [
          checker(
            () async => AppUpdate(
              version: '2.1.0',
              body: notes,
              date: '2026-11-10T12:00:00Z',
              downloadUrl:
                  'https://github.com/RykoTheDev/godothub/releases/download/flutter-v2.1.0/GodotHub-Beta-2.1.0-windows-x64-setup.exe',
              package: 'windows-x86_64-nsis',
              restart: () async => restarts++,
              download: (onProgress, {githubToken, onLog}) {
                token = githubToken;
                report = onProgress;
                onLog?.call('Downloading GodotHub-Beta-2.1.0-windows-x64-setup.exe from github.com');
                return Future<void>(() async {
                  await Future<void>.delayed(const Duration(seconds: 1));
                  finish.add(() {});
                });
              },
            ),
          ),
          portableIs(false),
        ],
      );
      expect(find.text(ghTr('check_updates_version_available', args: {'version': '2.1.0'})), findsOneWidget);
      expect(find.text('v2.0.0'), findsOneWidget);
      expect(find.text('v2.1.0'), findsOneWidget);
      expect(find.text('New thing'), findsOneWidget);
      expect(find.text('Slow start'), findsOneWidget);
      expect(find.text('ADDED'), findsOneWidget);
      expect(find.text('github.com'), findsOneWidget);
      expect(find.text('GodotHub-Beta-2.1.0-windows-x64-setup.exe'), findsOneWidget);
      expect(find.text('windows-x86_64-nsis'), findsOneWidget);
      expect(find.text(ghTr('check_updates_signature_checked')), findsOneWidget);
      await tester.tap(find.text(ghTr('check_updates_view_release')));
      await tester.pump();
      expect(opened, ['https://github.com/RykoTheDev/godothub/releases/tag/flutter-v2.1.0']);
      await tester.tap(find.text(ghTr('install_update')));
      await tester.pump();
      expect(token, 'tok');
      report(const UpdateDownloadProgress(downloaded: 50 * 1024 * 1024, total: 100 * 1024 * 1024));
      await tester.pump();
      expect(find.text(ghTr('downloading_update')), findsOneWidget);
      expect(find.text(ghTr('percent_complete', args: {'percent': 50})), findsOneWidget);
      expect(find.text(ghTr('check_updates_progress_size', args: {'downloaded': '50.0 MB', 'total': '100.0 MB'})), findsOneWidget);
      expect(find.text(ghTr('check_updates_from_host', args: {'host': 'github.com'})), findsOneWidget);
      expect(find.text(ghTr('check_updates_log').toUpperCase()), findsOneWidget);
      expect(find.text('Downloading GodotHub-Beta-2.1.0-windows-x64-setup.exe from github.com'), findsOneWidget);
      report(const UpdateDownloadProgress(downloaded: 100 * 1024 * 1024, total: 100 * 1024 * 1024));
      await base.settle(tester, 12);
      expect(finish, hasLength(1));
      expect(find.text(ghTr('update_downloaded')), findsOneWidget);
      expect(find.text(ghTr('check_updates_signature_verified')), findsOneWidget);
      expect(find.textContaining('100.0 MB'), findsOneWidget);
      expect(restarts, 0);
      await tester.tap(find.text(ghTr('restart_now')));
      await tester.pump();
      expect(restarts, 1);
    });

    testWidgets('preview mode shows the sample release notes and known issues', (tester) async {
      await openWith(tester, (close) => CheckForUpdatesModal(onClose: close, mode: CheckForUpdatesMode.preview));
      expect(find.text(ghTr('check_updates_release_notes').toUpperCase()), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('Faster startup times across all platforms'), findsOneWidget);
      expect(find.text(ghTr('changelog_known_issues').toUpperCase()), findsOneWidget);
      expect(find.textContaining('the taskbar may briefly show a duplicate icon'), findsOneWidget);
    });

    testWidgets('portable installs link to the GitHub release instead of installing', (tester) async {
      await openWith(
        tester,
        (close) => CheckForUpdatesModal(onClose: close),
        overrides: [
          checker(() async => AppUpdate(version: '2.1.0', download: (_, {githubToken, onLog}) async {}, restart: () async {})),
          portableIs(true),
        ],
      );
      expect(find.text(ghTr('check_updates_portable_title')), findsOneWidget);
      expect(find.text(ghTr('install_update')), findsNothing);
      await tester.tap(find.text(ghTr('check_updates_download_from_github')));
      await base.settle(tester, 2);
      expect(opened, [latestReleaseUrl]);
    });

    testWidgets('rate limit errors offer token settings and retry', (tester) async {
      var checks = 0;
      var tokenOpened = 0;
      var closed = 0;
      await openWith(
        tester,
        (close) => CheckForUpdatesModal(
          onClose: () {
            closed++;
            close();
          },
          onOpenTokenSettings: () => tokenOpened++,
        ),
        overrides: [
          checker(() async {
            checks++;
            throw 'HTTP 403 rate limit';
          }),
          portableIs(false),
        ],
      );
      expect(find.text(ghTr('check_updates_rate_limited')), findsOneWidget);
      expect(find.text(ghTr('check_updates_rate_limited_hint')), findsOneWidget);
      await tester.tap(find.text(ghTr('try_again')));
      await base.settle(tester);
      expect(checks, 2);
      await tester.tap(find.text(ghTr('check_updates_add_token')));
      await base.settle(tester);
      expect(closed, 1);
      expect(tokenOpened, 1);
    });

    testWidgets('preview mode starts on a fake update and switches between states', (tester) async {
      var checks = 0;
      await openWith(
        tester,
        (close) => CheckForUpdatesModal(onClose: close, mode: CheckForUpdatesMode.preview),
        overrides: [
          checker(() async {
            checks++;
            return null;
          }),
        ],
      );
      expect(checks, 0);
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(find.text('v$previewUpdateVersion'), findsOneWidget);
      await tester.tap(find.text(previewStateLabels[UpdateStateType.error]!));
      await base.settle(tester, 2);
      expect(find.text(previewError), findsOneWidget);
      await tester.tap(find.text(previewStateLabels[UpdateStateType.available]!));
      await base.settle(tester, 2);
      await tester.tap(find.text(ghTr('install_update')));
      await base.settle(tester, 40);
      expect(find.text(ghTr('update_downloaded')), findsOneWidget);
    });
  });

  group('BugReportModal', () {
    testWidgets('builds the report, copies it and opens a prefilled issue', (tester) async {
      BugReportErrorLog.record(CapturedErrorSource.flutterError, 'Overflow by 3px', DateTime(2026, 1, 1, 9, 5, 7));
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await openWith(tester, (close) => BugReportModal(onClose: close));
      expect(find.textContaining('## ${ghTr('bug_report_system')}'), findsOneWidget);
      expect(find.textContaining('- **${ghTr('bug_report_version')}**: 2.0.0'), findsOneWidget);
      expect(find.textContaining('`[09:05:07]` (FlutterError) Overflow by 3px'), findsOneWidget);
      expect(find.textContaining(ghTr('bug_report_no_description')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Crash on launch\nmore detail');
      await base.settle(tester, 2);
      await tester.tap(find.text(ghTr('bug_report_copy_log')));
      await base.settle(tester, 2);
      expect(copied, startsWith('## ${ghTr('bug_report_description')}\n\nCrash on launch\nmore detail'));
      expect(find.text(ghTr('bug_report_copied')), findsOneWidget);
      await tester.tap(find.text(ghTr('bug_report_open_github')));
      await base.settle(tester);
      expect(opened, hasLength(1));
      final uri = Uri.parse(opened.single);
      expect(uri.path, '/RykoTheDev/GodotHub/issues/new');
      expect(uri.queryParameters['template'], 'bug_report.yaml');
      expect(uri.queryParameters['title'], 'Crash on launch');
      expect(uri.queryParameters['description'], 'Crash on launch\nmore detail');
      expect(uri.queryParameters['actual-behavior'], contains('Overflow by 3px'));
      expect(find.byType(BugReportModal), findsNothing);
    });

    testWidgets('downloads the report and shows where it went', (tester) async {
      final writes = <String, String>{};
      BugReportModal.debugSaveReport = (name, content) async {
        writes[name] = content;
        return 'C:/Users/me/Downloads/$name';
      };
      await openWith(tester, (close) => BugReportModal(onClose: close));
      expect(find.textContaining(ghTr('bug_report_none_captured')), findsOneWidget);
      await tester.tap(find.text(ghTr('bug_report_download_log')));
      await base.settle(tester, 2);
      expect(writes.keys.single, bugReportFileName(DateTime.now()));
      expect(writes.values.single, contains('## ${ghTr('bug_report_recent_errors')}'));
      expect(find.text('C:/Users/me/Downloads/${writes.keys.single}'), findsOneWidget);
      await base.drainToasts(tester);
    });

    test('the error log keeps the newest 20 entries', () {
      for (var i = 0; i < 25; i++) {
        BugReportErrorLog.record(CapturedErrorSource.platformDispatcher, 'e$i');
      }
      expect(BugReportErrorLog.errors, hasLength(bugReportMaxCaptured));
      expect(BugReportErrorLog.errors.first.message, 'e24');
      expect(bugReportIssueUrl('', 's', 'e'), contains('title=${Uri.encodeQueryComponent(ghTr('report_a_bug'))}'));
    });
  });
}
