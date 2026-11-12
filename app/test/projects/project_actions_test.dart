import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/console/console_request.dart';
import 'package:godothub/console/project_console_window.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/last_opened.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/create_project_modal.dart';
import 'package:godothub/modals/duplicate_project_modal.dart';
import 'package:godothub/modals/launch_args_modal.dart';
import 'package:godothub/modals/project_addons_modal.dart';
import 'package:godothub/modals/project_build_modal.dart';
import 'package:godothub/modals/project_doctor_modal.dart';
import 'package:godothub/modals/project_size_modal.dart';
import 'package:godothub/modals/time_tracker_modal.dart';
import 'package:godothub/src/rust/api/dto.dart' as dto;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/project_stats.dart';
import 'package:godothub/state/projects.dart';
import 'package:godothub/state/settings.dart';
import 'package:godothub/titlebar/providers.dart' show openConsoleSignal;
import 'package:godothub/todos/project_todo_modal.dart';
import 'package:godothub/todos/project_todo_panel.dart';
import 'package:godothub/todos/todo_due_tile.dart';
import 'package:godothub/todos/todo_logic.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/modal_shell.dart';
import 'package:godothub/ui/feedback/toast_host.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;

final demo = Project(
  id: 'p1',
  name: 'Demo',
  path: 'C:/games/demo',
  godotVersion: '4.3',
  createdAt: '2026-01-01T00:00:00Z',
  pinned: false,
  sortOrder: 0,
  launchArguments: '--verbose',
  tags: const [],
  totalTimeSeconds: BigInt.from(7200),
  timeTodaySeconds: BigInt.from(600),
  timeWeekSeconds: BigInt.from(3600),
);

const engine = InstalledGodotVersion(
  tag: '4.3',
  version: '4.3',
  executablePath: 'C:/godot/4.3.exe',
  isMono: false,
  installedAt: '',
  supportsConsole: true,
);

ProjectTodo todo(
  String id,
  String title, {
  TodoStatus status = TodoStatus.todo,
  String? dueDate,
  TodoPriority? priority,
  int? number,
  String? completedAt,
}) => ProjectTodo(
  id: id,
  title: title,
  status: status,
  area: TodoArea.other,
  dueDate: dueDate,
  createdAt: '2026-01-01T00:00:00Z',
  number: number,
  priority: priority,
  checklist: const [],
  completedAt: completedAt,
);

ExportRun exportRun(String status, {String? error}) => ExportRun(
  id: 'run1',
  projectId: 'p1',
  projectName: 'Demo',
  presetName: 'Windows',
  outputPath: 'C:/out/demo.exe',
  status: status,
  error: error,
  startedAtMs: BigInt.zero,
);

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(file).readAsBytesSync())));
  }
  await loader.load();
}

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> drainToasts(WidgetTester tester) => tester.pump(const Duration(seconds: 12));

Future<BuildContext> pumpHost(WidgetTester tester, {Widget? body, AppSettings? settings, Size size = const Size(1400, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext host;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fakeSettings(() => settings ?? copySettings(baseSettings, setupComplete: true, projectTodosEnabled: true))],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(
          body: GhToastHost(
            child: Consumer(
              builder: (context, ref, _) {
                ref.watch(settingsProvider);
                host = context;
                return body ?? const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    ),
  );
  await settle(tester, 3);
  return host;
}

Future<void> openModal(WidgetTester tester, Widget Function(VoidCallback close) builder, {AppSettings? settings}) async {
  final host = await pumpHost(tester, settings: settings);
  showGhModal<void>(host, (modal) => builder(() => Navigator.of(modal).pop())).ignore();
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    debugResetOpenTodos();
  });

  group('project modals', () {
    testWidgets('duplicate defaults the name and parent folder then calls the backend', (tester) async {
      Map<String, Object?>? sent;
      var duplicated = 0;
      rust.on('crateApiProjectsDuplicateProject', ({required String id, required String name, String? destDir}) async {
        sent = {'id': id, 'name': name, 'dest': destDir};
        return demo;
      });
      await openModal(tester, (close) => DuplicateProjectModal(project: demo, onClose: close, onDuplicated: () => duplicated++));
      expect(defaultDuplicateDest(r'C:\games\demo'), r'C:\games');
      expect(find.text('C:/games'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Demo ${ghTr('copy_suffix')}');
      await tester.tap(find.text(ghTr('duplicate')));
      await settle(tester);
      expect(sent, {'id': 'p1', 'name': 'Demo ${ghTr('copy_suffix')}', 'dest': 'C:/games'});
      expect(duplicated, 1);
      expect(find.byType(DuplicateProjectModal), findsNothing);
      await drainToasts(tester);
    });

    testWidgets('launch arguments returns the trimmed value', (tester) async {
      String? saved;
      await openModal(tester, (close) => LaunchArgsModal(currentArgs: demo.launchArguments, onSave: (v) => saved = v, onClose: close));
      await tester.enterText(find.byType(TextField), '  --headless  ');
      await tester.tap(find.text(ghTr('save')));
      await settle(tester, 3);
      expect(saved, '--headless');
    });

    testWidgets('size modal sums folders and sorts them before files', (tester) async {
      rust.on(
        'crateApiProjectsGetProjectFileTree',
        ({required String path}) async => [
          ProjectFileEntry(path: 'readme.md', isDir: false, size: BigInt.from(4096)),
          ProjectFileEntry(path: 'art/', isDir: true, size: BigInt.zero),
          ProjectFileEntry(path: 'art/hero.png', isDir: false, size: BigInt.from(2 * 1024 * 1024)),
        ],
      );
      await openModal(tester, (close) => ProjectSizeModal(projectPath: demo.path, onClose: close));
      expect(find.text('art'), findsOneWidget);
      expect(find.text('2.0 MB'), findsOneWidget);
      expect(find.text('hero.png'), findsNothing);
      expect(tester.getTopLeft(find.text('art')).dy, lessThan(tester.getTopLeft(find.text('readme.md')).dy));
      await tester.tap(find.bySemanticsLabel(ghTr('expand')));
      await settle(tester, 3);
      expect(find.text('hero.png'), findsOneWidget);
    });

    testWidgets('time tracker shows the weekly chart or its empty state', (tester) async {
      await openModal(
        tester,
        (close) => TimeTrackerModal(project: demo, onClose: close, loadActivity: (_) async => [('2026-11-09', BigInt.zero)]),
      );
      expect(find.text(ghTr('time_weekly_empty')), findsOneWidget);
      expect(find.text(ghTr('time_today').toUpperCase()), findsOneWidget);
    });

    testWidgets('addons lists installed addons and offers updates after a check', (tester) async {
      rust
        ..on(
          'crateApiAddonsListProjectAddons',
          ({required String id}) async => const [
            ProjectAddon(
              folder: 'dialogic',
              name: 'Dialogic',
              description: '',
              author: 'Emi',
              version: '1.0',
              hasPlugin: true,
              enabled: true,
            ),
          ],
        )
        ..on(
          'crateApiAddonsCheckAddonUpdates',
          ({required String id}) async => const [
            AddonUpdate(
              folder: 'dialogic',
              assetId: '7',
              title: 'Dialogic',
              latestVersion: '2.0',
              updateAvailable: true,
              matchedBy: 'asset',
            ),
          ],
        );
      await openModal(tester, (close) => ProjectAddonsModal(project: demo, onClose: close));
      expect(find.text('Dialogic'), findsOneWidget);
      expect(find.text('v1.0'), findsOneWidget);
      expect(find.text(ghTr('project_addons.update')), findsNothing);
      await tester.tap(find.text(ghTr('project_addons.check_updates')));
      await settle(tester);
      expect(find.text(ghTr('project_addons.update_to', args: {'version': '2.0'})), findsOneWidget);
      expect(find.text(ghTr('project_addons.update')), findsOneWidget);
    });

    testWidgets('build modal starts an export, confirms overwrites and opens the console', (tester) async {
      final attempts = <bool>[];
      final opened = <ConsoleRequest>[];
      rust
        ..on(
          'crateApiDtoGetProjectExportPresets',
          ({required String id}) async => const dto.ExportCatalog(
            versionTag: '4.3',
            presets: [
              dto.ExportPreset(id: 0, name: 'Windows', platform: 'Windows Desktop', outputPath: 'C:/out/demo.exe', missingTemplates: []),
            ],
          ),
        )
        ..on('crateApiExportRunnerGetProjectExports', ({required String id}) async => <ExportRun>[])
        ..on(
          'crateApiToolRunnerListProjectTools',
          ({required String id}) async => const [ProjectTool(id: 'gut', kind: 'test', available: false, reason: 'missing')],
        )
        ..on('crateApiExportRunnerStartProjectExport', ({
          required String id,
          required int presetId,
          required String outputPath,
          required bool overwrite,
        }) async {
          attempts.add(overwrite);
          if (!overwrite) throw 'OUTPUT_EXISTS:$outputPath';
          return exportRun('running');
        });
      await openModal(tester, (close) => ProjectBuildModal(project: demo, onClose: close));
      AppSignals.on(openConsoleSignal).listen((signal) => opened.add(ConsoleRequest.from(signal.detail)!));
      expect(find.text(ghTr('build_export.tools_title')), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'C:/out/demo.exe');
      await tester.tap(find.text(ghTr('build_export.start')));
      await settle(tester);
      expect(find.text(ghTr('build_export.overwrite_title').toUpperCase()), findsOneWidget);
      await tester.tap(find.text(ghTr('build_export.overwrite')));
      await settle(tester);
      expect(attempts, [false, true]);
      expect(opened.single.id, 'run1');
      expect(opened.single.name, 'Demo · Windows');
      expect(find.byType(ProjectBuildModal), findsNothing);
    });

    testWidgets('doctor groups findings and applies a fix', (tester) async {
      final fixed = <String>[];
      dto.HealthReport report() => dto.HealthReport(
        projectId: 'p1',
        scannedAtMs: BigInt.zero,
        checks: [
          const dto.HealthCheck(
            id: 'cache',
            category: 'cache',
            severity: 'warning',
            code: 'import_cache_stale',
            details: ['.godot/imported'],
            values: {'bytes': '2048'},
            action: HealthAction(kind: 'clear_cache', confirm: false),
          ),
          const dto.HealthCheck(id: 'engine', category: 'engine', severity: 'ok', code: 'engine_ready', details: [], values: {}),
        ],
      );
      rust
        ..on('crateApiDtoDiagnoseProject', ({required String id}) async => report())
        ..on('crateApiProjectHealthFixProjectHealth', ({required String id, required String checkId}) async => fixed.add(checkId));
      await openModal(tester, (close) => ProjectDoctorModal(project: demo, installedVersions: const [engine], onClose: close));
      expect(find.text(ghTr('project_doctor.summary_warnings', count: 1)), findsOneWidget);
      expect(find.text(ghTr('project_doctor.category_cache')), findsOneWidget);
      expect(find.text(ghTr('project_doctor.passed_checks', count: 1)), findsOneWidget);
      expect(find.text('.godot/imported'), findsOneWidget);
      await tester.tap(find.text(ghTr('project_doctor.action_clear_cache')));
      await settle(tester);
      expect(fixed, ['cache']);
      expect(rust.callCount('crateApiDtoDiagnoseProject'), 2);
      await drainToasts(tester);
    });

    testWidgets('create project validates, creates and initialises git', (tester) async {
      Map<String, Object?>? created;
      GitInitOptions? git;
      var done = 0;
      rust
        ..on('crateApiTemplatesListTemplates', () async => <ProjectTemplate>[])
        ..on('crateApiGitGitIsAvailable', () async => true)
        ..on('crateApiGitAuthGetGitAuthState', () async => const GitAuthState(pats: []))
        ..on('crateApiProjectsCreateProject', ({
          required String name,
          required String location,
          required String godotVersion,
          String? iconPath,
          String? templateId,
          String? category,
        }) async {
          created = {'name': name, 'location': location, 'version': godotVersion, 'category': category};
          return demo;
        })
        ..on('crateApiGitGitInitProject', ({required String path, GitInitOptions? options}) async {
          git = options;
          return const GitInitOutcome(initialized: true, committed: true);
        });
      await openModal(
        tester,
        (close) => CreateProjectModal(
          installedVersions: const [engine],
          defaultLocation: 'C:/games',
          placeholder: 'My Awesome Game',
          onClose: close,
          onCreated: () => done++,
        ),
        settings: copySettings(baseSettings, setupComplete: true, gitInitNewProjects: true),
      );
      await tester.tap(find.text(ghTr('create_project_btn')));
      await settle(tester, 3);
      expect(find.text(ghTr('create_project_error')), findsOneWidget);
      expect(created, isNull);
      await tester.enterText(find.byType(TextField).first, 'Space Game');
      await settle(tester, 2);
      expect(find.text(ghTr('create_project_error')), findsNothing);
      await tester.tap(find.text(ghTr('create_project_btn')));
      await settle(tester);
      expect(created, {'name': 'Space Game', 'location': 'C:/games', 'version': '4.3', 'category': null});
      expect(git?.gitignore, isTrue);
      expect(git?.readme, isFalse);
      expect(done, 1);
    });
  });

  group('todos', () {
    test('sorting, search and due labels follow the React rules', () {
      final list = [
        todo('a', 'Later', dueDate: '2026-12-01'),
        todo('b', 'No date', priority: TodoPriority.high),
        todo('c', 'Sooner', dueDate: '2026-11-20'),
        todo('d', 'Finished', status: TodoStatus.done, completedAt: '2026-11-01T00:00:00Z'),
      ];
      expect(sortProjectTodos(list, null, TodoDueDateSort.nearestFirst).map((t) => t.id), ['c', 'a', 'b', 'd']);
      expect(sortProjectTodos(list, TodoStatusSort.completedFirst, null).first.id, 'd');
      expect(identical(sortProjectTodos(list, null, null), list), isTrue);
      expect(todoMatchesSearch(todo('x', 'Fix jump', number: 12), '#todo-12'), isTrue);
      expect(todoMatchesSearch(list.first, 'jump'), isFalse);
      expect(formatTodoDueDate(null, '2026-11-12', LastOpenedDateFormat.ddMmYyyy), '-');
      expect(formatTodoDueDate('2026-11-12', '2026-11-12', LastOpenedDateFormat.ddMmYyyy), ghTr('time_today'));
      expect(formatTodoDueDate('2026-11-13', '2026-11-12', LastOpenedDateFormat.ddMmYyyy), ghTr('todos:tomorrow'));
      expect(formatTodoDueDate('2027-01-05', '2026-11-12', LastOpenedDateFormat.yyyyMmDd), '2027-01-05');
      expect(todoDueContext('2026-11-12', '2026-11-11', overdue: true), ghTr('todos:overdue_yesterday'));
      expect(todoDueContext('2026-11-12', '2026-11-11', overdue: false), isNull);
      expect(newTodoId(), matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });

    testWidgets('panel lists pending tasks, quick-adds and completes them', (tester) async {
      var store = [todo('a', 'Write intro'), todo('b', 'Old task', status: TodoStatus.done)];
      var loaded = 0;
      rust
        ..on('crateApiProjectTodosListProjectTodos', ({required String projectId}) async => store)
        ..on('crateApiProjectTodosListOpenTodos', () async => <OpenTodo>[])
        ..on('crateApiProjectTodosSaveProjectTodos', ({required String projectId, required List<ProjectTodo> todos}) async {
          store = todos;
          return todos;
        })
        ..on(
          'crateApiTodoSyncSyncProjectTodos',
          ({required String projectId, required bool scanComments}) async => TodoSyncResult(
            todos: store,
            scanned: scanComments,
            imported: BigInt.zero,
            closed: BigInt.zero,
            reopened: BigInt.zero,
            updated: BigInt.zero,
            closedByCommits: BigInt.zero,
            gitAvailable: true,
          ),
        );
      await pumpHost(
        tester,
        body: SingleChildScrollView(
          child: ProjectTodoPanel(projectId: 'p1', onLoaded: () => loaded++, onClose: () {}),
        ),
      );
      await settle(tester);
      expect(loaded, 1);
      expect(rust.callCount('crateApiTodoSyncSyncProjectTodos'), 1);
      expect(find.text('Write intro'), findsOneWidget);
      expect(find.text('Old task'), findsNothing);
      expect(find.text(ghTr('todos:pending_count', count: 1)), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ship demo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(store.map((t) => t.title), ['Write intro', 'Old task', 'Ship demo']);
      expect(find.text('Ship demo'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(ghTr('todos:mark_completed')).first);
      await settle(tester);
      expect(store.where((t) => t.status == TodoStatus.done).length, 2);

      await tester.tap(find.text(ghTr('todos:scan_code')));
      await settle(tester);
      expect(rust.callCount('crateApiTodoSyncSyncProjectTodos'), 2);
      await drainToasts(tester);
    });

    testWidgets('task modal blocks links outside res:// and submits a new task', (tester) async {
      ProjectTodo? submitted;
      rust.on('crateApiTodoSyncListProjectResources', ({required String projectId}) async => ['res://player.gd']);
      await openModal(
        tester,
        (close) => ProjectTodoModal(
          projectId: 'p1',
          onClose: close,
          onSubmit: (value) async {
            submitted = value;
            return true;
          },
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Tune jump');
      await tester.enterText(find.byType(TextField).last, 'player.gd');
      await settle(tester, 3);
      expect(find.text(ghTr('todos:linked_file_invalid')), findsOneWidget);
      await tester.tap(find.text(ghTr('todos:add_task')));
      await settle(tester, 3);
      expect(submitted, isNull);
      await tester.enterText(find.byType(TextField).last, 'res://player.gd');
      await settle(tester, 3);
      await tester.tap(find.text(ghTr('todos:priority_high')));
      await tester.tap(find.text(ghTr('todos:add_task')));
      await settle(tester);
      expect(submitted?.title, 'Tune jump');
      expect(submitted?.link?.path, 'res://player.gd');
      expect(submitted?.priority, TodoPriority.high);
      expect(find.byType(ProjectTodoModal), findsNothing);
    });

    testWidgets('due tile shows overdue and upcoming tasks', (tester) async {
      final today = localDateValue();
      rust.on(
        'crateApiProjectTodosListOpenTodos',
        () async => [
          OpenTodo(
            projectId: 'p1',
            projectName: 'Demo',
            todo: todo('a', 'Late task', dueDate: addDaysValue(today, -2)),
          ),
          OpenTodo(
            projectId: 'p1',
            projectName: 'Demo',
            todo: todo('b', 'Soon task', dueDate: addDaysValue(today, 1)),
          ),
          OpenTodo(
            projectId: 'p1',
            projectName: 'Demo',
            todo: todo('c', 'Far task', dueDate: addDaysValue(today, 30)),
          ),
        ],
      );
      await pumpHost(
        tester,
        body: const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 400, child: TodoDueTile()),
        ),
      );
      await settle(tester);
      expect(find.text('Late task'), findsOneWidget);
      expect(find.text('Soon task'), findsOneWidget);
      expect(find.text('Far task'), findsNothing);
      expect(find.text(ghTr('todos:overdue_days', count: 2)), findsOneWidget);
      expect(find.text(ghTr('todos:tomorrow')), findsOneWidget);
      expect(tester.getTopLeft(find.text('Late task')).dy, lessThan(tester.getTopLeft(find.text('Soon task')).dy));
    });
  });

  group('console', () {
    test('pill clamps to the frame and snaps to nearby edges', () {
      const frame = Size(800, 600);
      const pill = Size(200, 36);
      expect(clampConsolePill(const Offset(-50, 900), frame, pill), const Offset(10, 554));
      expect(snapConsolePill(const Offset(40, 300), frame, pill), const Offset(10, 300));
      expect(snapConsolePill(const Offset(560, 520), frame, pill), const Offset(590, 554));
      expect(snapConsolePill(const Offset(300, 300), frame, pill), const Offset(300, 300));
    });

    testWidgets('opens on request, renders ANSI lines, filters levels and minimises', (tester) async {
      var running = true;
      var cleared = 0;
      rust
        ..on('crateApiProjectsListRunningProjects', () async => <RunningProjectInfo>[])
        ..on('crateApiConsoleClearProjectConsole', ({required String id}) async => cleared++)
        ..on('crateApiConsoleGetProjectConsole', ({required String id, BigInt? since}) async {
          final first = (since ?? BigInt.zero) == BigInt.zero;
          return ConsoleSnapshot(
            id: id,
            lines: first
                ? [
                    ConsoleLine(seq: BigInt.zero, stream: ConsoleStream.stdout, text: 'Godot Engine started'),
                    ConsoleLine(seq: BigInt.one, stream: ConsoleStream.stderr, text: 'ERROR: missing node'),
                    ConsoleLine(seq: BigInt.two, stream: ConsoleStream.stdout, text: '\u001b[32mgreen\u001b[0m text'),
                  ]
                : const [],
            nextSeq: BigInt.from(3),
            running: running,
            exitCode: running ? null : 3,
            restored: false,
          );
        });
      await pumpHost(tester, body: const ProjectConsoleWindow());
      expect(find.text(ghTr('console_title').toUpperCase()), findsNothing);
      requestOpenConsole('p1', name: 'Demo');
      await settle(tester);
      expect(find.text(ghTr('console_title').toUpperCase()), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text(ghTr('running')), findsOneWidget);
      expect(find.text('Godot Engine started'), findsOneWidget);
      expect(find.text('ERROR: missing node'), findsOneWidget);
      final green = tester.widget<RichText>(find.descendant(of: find.byKey(ValueKey(BigInt.two)), matching: find.byType(RichText)));
      expect(green.text.toPlainText(), 'green text');
      TextSpan? span;
      green.text.visitChildren((child) {
        if (child is TextSpan && child.text == 'green') span = child;
        return true;
      });
      expect(span, isNotNull);
      expect(span!.style?.color, isNot(const Color(0xFFD7DAE0)));

      await tester.tap(find.text(ghTr('console_filter_errors')));
      await settle(tester, 3);
      expect(find.text('ERROR: missing node'), findsNothing);
      expect(find.text('Godot Engine started'), findsOneWidget);
      await tester.tap(find.text(ghTr('console_filter_errors')));
      await settle(tester, 3);

      running = false;
      rust.emit(
        AppEvent(
          kind: AppEventKind.projectConsoleExit,
          name: 'project:console-exit',
          json: 'null',
          consoleExit: const ConsoleExit(id: 'p1', code: 3),
        ),
      );
      await settle(tester);
      expect(find.text(ghTr('console_exit_code', args: {'code': 3})), findsOneWidget);
      expect(find.text(ghTr('console_crash_hint', args: {'code': 3})), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(ghTr('console_minimize')));
      await settle(tester, 3);
      expect(find.text(ghTr('console_title').toUpperCase()), findsNothing);
      expect(find.bySemanticsLabel(ghTr('console_pill_hint')), findsOneWidget);
      await tester.tap(find.text('Demo'));
      await settle(tester, 3);
      expect(find.text(ghTr('console_title').toUpperCase()), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(ghTr('console_clear')));
      await settle(tester, 3);
      expect(cleared, 1);
      expect(find.text('Godot Engine started'), findsNothing);
      expect(find.text(ghTr('console_empty')), findsOneWidget);
    });

    testWidgets('export runs show their result footer', (tester) async {
      rust
        ..on('crateApiProjectsListRunningProjects', () async => <RunningProjectInfo>[])
        ..on(
          'crateApiConsoleGetProjectConsole',
          ({required String id, BigInt? since}) async =>
              ConsoleSnapshot(id: id, lines: const [], nextSeq: BigInt.zero, running: false, exitCode: 1, restored: false),
        )
        ..on('crateApiExportRunnerGetProjectExport', ({required String runId}) async => exportRun('failed', error: 'Export failed hard'));
      await pumpHost(tester, body: const ProjectConsoleWindow());
      rust.emit(AppEvent(kind: AppEventKind.exportStarted, name: 'export:started', json: 'null', exportRun: exportRun('running')));
      await settle(tester);
      expect(find.text('Demo · Windows'), findsOneWidget);
      expect(find.text('Export failed hard'), findsOneWidget);
      expect(find.text('C:/out/demo.exe'), findsOneWidget);
    });
  });

  group('time stats', () {
    test('export and import report their outcome and refresh projects', () async {
      final exported = <String>[];
      rust
        ..on('crateApiProjectsExportProjectStats', ({required String path}) async => exported.add(path))
        ..on('crateApiProjectsImportProjectStats', ({required String path}) async => BigInt.two)
        ..on('crateApiProjectsListProjects', () async => <Project>[]);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(projectsProvider, (_, _) {});
      final stats = container.read(projectStatsProvider.notifier);
      await stats.exportStats(pickSavePath: (name) async => 'C:/tmp/$name');
      expect(exported, ['C:/tmp/$projectStatsFileName']);
      expect(container.read(projectStatsProvider).message, ghTr('settings:stats_exported'));
      await stats.importStats(pickDataFile: () async => 'C:/tmp/in.json');
      expect(container.read(projectStatsProvider).message, ghTr('settings:stats_imported', count: 2));
      expect(container.read(projectStatsProvider).busy, isNull);
      await stats.exportStats(pickSavePath: (_) async => null);
      expect(container.read(projectStatsProvider).message, isNull);
      await stats.importStats(pickDataFile: () async => throw 'bad file');
      expect(container.read(projectStatsProvider).message, 'bad file');
    });
  });
}
