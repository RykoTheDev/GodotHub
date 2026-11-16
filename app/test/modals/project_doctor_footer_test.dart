import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/modals/project_doctor_modal.dart';
import 'package:godothub/src/rust/api/dto.dart' as dto;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/keyboard_shortcuts.dart' show setTabSignal;
import 'package:godothub/ui/core/button.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/reusables/modal_kit.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

dto.HealthCheck finding(String id, String category, String code, {String severity = 'warning', HealthAction? action}) =>
    dto.HealthCheck(id: id, category: category, severity: severity, code: code, details: const [], values: const {}, action: action);

final cache = finding('cache', 'cache', 'cache_stale', action: const HealthAction(kind: 'clear_cache', confirm: false));
final ignores = finding('git', 'git', 'ignore_missing', action: const HealthAction(kind: 'add_ignores', confirm: false));
final unbound = finding(
  'engine',
  'engine',
  'version_unbound',
  severity: 'error',
  action: const HealthAction(kind: 'choose_version', confirm: false),
);
final addon = finding('addon', 'addons', 'addon_disabled', action: const HealthAction(kind: 'enable_addon', confirm: true));
final ready = finding('format', 'engine', 'format_ready', severity: 'ok');
final infoFix = finding(
  'note',
  'git',
  'ignore_missing',
  severity: 'info',
  action: const HealthAction(kind: 'add_ignores', confirm: false),
);

void installReport(List<dto.HealthCheck> Function() checks, {List<String>? fixed}) {
  base.rust
    ..on(
      'crateApiDtoDiagnoseProject',
      ({required String id}) async => dto.HealthReport(projectId: 'p1', scannedAtMs: BigInt.zero, checks: checks()),
    )
    ..on('crateApiProjectHealthFixProjectHealth', ({required String id, required String checkId}) async => fixed?.add(checkId));
}

Future<void> openDoctor(WidgetTester tester, {Size size = const Size(1400, 1000)}) => base.openModal(
  tester,
  (close) => ProjectDoctorModal(project: base.demo, installedVersions: const [base.engine], onClose: close),
  size: size,
);

Finder get primaryButtons => find.byWidgetPredicate(
  (w) => w is GhBusyButton || (w is GhButton && (w.variant == GhButtonVariant.primary || w.variant == GhButtonVariant.danger)),
);

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    base.rust = installFakeRust();
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
  });

  test('fix all only batches one-step fixes that need no confirmation', () {
    expect(
      [
        for (final f in doctorBatchFixable([cache, ignores, unbound, addon, ready])) f.id,
      ],
      ['cache', 'git'],
    );
  });

  testWidgets('fix all is the single primary action when batch fixes exist and applies them once', (tester) async {
    final fixed = <String>[];
    var fixedYet = false;
    installReport(() => fixedYet ? [unbound, ready] : [cache, ignores, unbound, ready], fixed: fixed);
    await openDoctor(tester);

    expect(primaryButtons, findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-fix-all')), findsOneWidget);
    expect(find.text(ghTr('doctor_fix_all', args: {'count': 2})), findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-done')), findsNothing);
    final close = tester.widget<GhButton>(find.byKey(const ValueKey('doctor-close')));
    expect(close.variant, GhButtonVariant.ghost);
    expect(find.byType(GhOutlineAction).evaluate().where((e) => (e.widget as GhOutlineAction).label == ghTr('close')), isEmpty);

    fixedYet = true;
    await tester.tap(find.byKey(const ValueKey('doctor-fix-all')));
    await base.settle(tester);
    expect(fixed, ['cache', 'git']);
    expect(base.rust.callCount('crateApiDtoDiagnoseProject'), 2);
    expect(find.byKey(const ValueKey('doctor-fix-all')), findsNothing);
    expect(find.byKey(const ValueKey('doctor-done')), findsOneWidget);
    expect(primaryButtons, findsOneWidget);
    await base.drainToasts(tester);
  });

  testWidgets('done is the primary action when nothing can be batch fixed, and closes', (tester) async {
    installReport(() => [addon, ready]);
    var closed = 0;
    await base.openModal(
      tester,
      (close) => ProjectDoctorModal(
        project: base.demo,
        installedVersions: const [base.engine],
        onClose: () {
          closed++;
          close();
        },
      ),
    );
    expect(primaryButtons, findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-fix-all')), findsNothing);
    expect(find.byKey(const ValueKey('doctor-close')), findsNothing);
    expect(find.text(ghTr('project_doctor.action_enable_addon')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-done')));
    await base.settle(tester);
    expect(closed, 1);
  });

  testWidgets('manage versions sits on the engine binding row, not in the footer', (tester) async {
    installReport(() => [unbound, cache, ready]);
    final tabs = <Object?>[];
    final sub = AppSignals.on(setTabSignal).listen((s) => tabs.add(s.detail));
    addTearDown(sub.cancel);
    var closed = 0;
    await base.openModal(
      tester,
      (close) => ProjectDoctorModal(
        project: base.demo,
        installedVersions: const [base.engine],
        onClose: () {
          closed++;
          close();
        },
      ),
    );
    final manage = find.text(ghTr('project_doctor.action_manage_versions'));
    expect(manage, findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('doctor-row:engine')), matching: manage), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('doctor-row:cache')), matching: manage), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('doctor-row:engine')),
        matching: find.text(ghTr('project_doctor.action_choose_version')),
      ),
      findsOneWidget,
    );
    await tester.tap(manage);
    await base.settle(tester);
    expect(closed, 1);
    expect(tabs, ['versions']);
  });

  testWidgets('the status line has its own region and the footer fits 340x640', (tester) async {
    installReport(() => [cache, ignores, unbound, ready]);
    await openDoctor(tester, size: const Size(340, 640));
    final error = tester.takeException();
    if (error is FlutterError) debugPrint(error.toStringDeep());
    expect(error, isNull);
    final status = find.byKey(const ValueKey('doctor-status'));
    expect(find.descendant(of: status, matching: find.text(ghTr('project_doctor.local_checks'))), findsOneWidget);
    final text = tester.widget<Text>(find.descendant(of: status, matching: find.text(ghTr('project_doctor.local_checks'))));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(find.byKey(const ValueKey('doctor-fix-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-close')), findsOneWidget);
  });
}
