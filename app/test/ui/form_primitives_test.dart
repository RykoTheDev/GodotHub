import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/ui/reusables/card_grid.dart';
import 'package:godothub/ui/reusables/labelled_field.dart';
import 'package:godothub/ui/reusables/path_field.dart';
import 'package:godothub/ui/reusables/state_panel.dart';

import 'i18n_setup.dart';

final theme = GhTheme.defaults();

Widget host(Widget child, {double width = 600}) => MaterialApp(
  theme: theme.toThemeData(),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  setUp(setUpTestI18n);

  late Directory tmp;
  setUpAll(() => tmp = Directory.systemTemp.createTempSync('godothub-path-field'));
  tearDownAll(() => tmp.deleteSync(recursive: true));

  group('ghNormalizePath', () {
    test('strips quotes from Copy as path', () {
      expect(ghNormalizePath('  "C:\\Games\\My Game"  '), 'C:\\Games\\My Game');
      expect(ghNormalizePath("'/home/me/game'"), '/home/me/game');
    });

    test('expands home on macOS and Linux', () {
      final home = Platform.environment['HOME'];
      if (Platform.isWindows || home == null) return;
      expect(ghNormalizePath('~/games'), '$home/games');
    });
  });

  group('ghPathError', () {
    test('accepts an existing folder and rejects the rest', () {
      final file = File('${tmp.path}${Platform.pathSeparator}a.txt')..writeAsStringSync('x');
      expect(ghPathError(tmp.path, GhPathKind.folder), isNull);
      expect(ghPathError('"${tmp.path}"', GhPathKind.folder), isNull);
      expect(ghPathError('', GhPathKind.folder), isNotNull);
      expect(ghPathError('', GhPathKind.folder, required: false), isNull);
      expect(ghPathError('relative/path', GhPathKind.folder), isNotNull);
      expect(ghPathError('${tmp.path}${Platform.pathSeparator}nope', GhPathKind.folder), isNotNull);
      expect(ghPathError(file.path, GhPathKind.folder), isNotNull);
    });

    test('files check existence and extension', () {
      final file = File('${tmp.path}${Platform.pathSeparator}icon.png')..writeAsStringSync('x');
      expect(ghPathError(file.path, GhPathKind.file, extensions: ['png', 'svg']), isNull);
      expect(ghPathError(file.path, GhPathKind.file, extensions: ['zip']), isNotNull);
      expect(ghPathError(tmp.path, GhPathKind.file), isNotNull);
    });

    test('new files need an existing parent', () {
      final sep = Platform.pathSeparator;
      expect(ghPathError('${tmp.path}${sep}out.zip', GhPathKind.newFile), isNull);
      expect(ghPathError('${tmp.path}${sep}missing${sep}out.zip', GhPathKind.newFile), isNotNull);
      expect(ghPathError(tmp.path, GhPathKind.newFile), isNotNull);
    });
  });

  group('GhPathField', () {
    testWidgets('typed paths commit on Enter and errors clear while typing', (tester) async {
      final controller = TextEditingController();
      final committed = <String>[];
      await tester.pumpWidget(
        host(GhPathField(controller: controller, kind: GhPathKind.folder, label: 'Location', onCommitted: committed.add)),
      );
      await tester.enterText(find.byType(TextField), 'not/absolute');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(committed, isEmpty);
      expect(find.text('Use a full path that starts at a drive or the root folder.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '"${tmp.path}"');
      await tester.pump();
      expect(find.text('Use a full path that starts at a drive or the root folder.'), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(committed, [tmp.path]);
      expect(controller.text, tmp.path);
    });

    testWidgets('browse still fills and commits the picked folder', (tester) async {
      final controller = TextEditingController();
      final committed = <String>[];
      await tester.pumpWidget(
        host(GhPathField(controller: controller, kind: GhPathKind.folder, pick: () async => tmp.path, onCommitted: committed.add)),
      );
      await tester.tap(find.byKey(const ValueKey('path-browse')));
      await tester.pumpAndSettle();
      expect(controller.text, tmp.path);
      expect(committed, [tmp.path]);
    });

    testWidgets('apply button appears only while edited', (tester) async {
      final controller = TextEditingController(text: tmp.path);
      final committed = <String>[];
      await tester.pumpWidget(
        host(GhPathField(controller: controller, kind: GhPathKind.folder, showApply: true, onCommitted: committed.add)),
      );
      expect(find.byKey(const ValueKey('path-apply')), findsNothing);
      await tester.enterText(find.byType(TextField), '${tmp.path}${Platform.pathSeparator}');
      await tester.pump();
      expect(find.byKey(const ValueKey('path-apply')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('path-apply')));
      await tester.pump();
      expect(committed, hasLength(1));
      expect(find.byKey(const ValueKey('path-apply')), findsNothing);
    });
  });

  group('GhPathField options', () {
    testWidgets('add fields clear after a commit and Enter alone submits', (tester) async {
      final controller = TextEditingController();
      final committed = <String>[];
      final submitted = <String>[];
      await tester.pumpWidget(
        host(
          GhPathField(
            controller: controller,
            kind: GhPathKind.folder,
            pick: () async => '/picked/by/dialog',
            clearOnCommit: true,
            showApply: true,
            applyLabel: 'Add folder',
            onCommitted: committed.add,
            onSubmitted: submitted.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), tmp.path);
      await tester.pump();
      expect(find.text('Add folder'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(committed, [tmp.path]);
      expect(submitted, [tmp.path]);
      expect(controller.text, isEmpty);
      expect(find.text('Add folder'), findsNothing);

      // A pick from the native dialog is trusted as is and does not submit.
      await tester.tap(find.byKey(const ValueKey('path-browse')));
      await tester.pumpAndSettle();
      expect(committed.last, '/picked/by/dialog');
      expect(submitted, hasLength(1));
    });

    testWidgets('a custom validator replaces the kind check', (tester) async {
      final controller = TextEditingController();
      final committed = <String>[];
      await tester.pumpWidget(
        host(
          GhPathField(
            controller: controller,
            kind: GhPathKind.newFile,
            pick: () async => null,
            validator: (raw) => raw.trim() == 'bad' ? 'Nope' : null,
            onCommitted: committed.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'bad');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Nope'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'builds/game.exe');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(committed, ['builds/game.exe']);
    });

    testWidgets('a failing picker reports through onPickError', (tester) async {
      Object? failure;
      await tester.pumpWidget(
        host(
          GhPathField(
            controller: TextEditingController(),
            kind: GhPathKind.folder,
            pick: () async => throw StateError('no dialog'),
            onPickError: (e) => failure = e,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('path-browse')));
      await tester.pumpAndSettle();
      expect(failure, isA<StateError>());
    });
  });

  group('GhLabelledField', () {
    testWidgets('error replaces hint and describes the input', (tester) async {
      Widget field({String? error}) =>
          host(GhLabelledField(label: 'Name', hint: 'Shown in the library', error: error, required: true, child: const GhFieldInput()));
      await tester.pumpWidget(field());
      expect(find.text('Shown in the library'), findsOneWidget);
      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.byType(TextField));
      expect(node.label, contains('Name, required'));
      expect(node.hint, 'Shown in the library');

      await tester.pumpWidget(field(error: 'Name is taken'));
      expect(find.text('Shown in the library'), findsNothing);
      expect(find.text('Name is taken'), findsOneWidget);
      expect(tester.getSemantics(find.byType(TextField)).hint, 'Name is taken');
      handle.dispose();
    });
  });

  group('GhCardGrid', () {
    test('breakpoints give 4 to 6 columns on wide layouts', () {
      const b = GhGridBreakpoints.cards;
      expect(b.columnsFor(400), 1);
      expect(b.columnsFor(700), 2);
      expect(b.columnsFor(1000), 3);
      expect(b.columnsFor(1200), 4);
      expect(b.columnsFor(1500), 5);
      expect(b.columnsFor(1900), 6);
      expect(b.columnsFor(1200, fontScale: 1.3), 3, reason: 'a larger font scale needs wider cards');
    });

    testWidgets('lays out by available width, not window width', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(width: 1200, GhCardGrid(children: [for (var i = 0; i < 9; i++) SizedBox(key: ValueKey(i), height: 40)])),
      );
      expect(tester.getTopLeft(find.byKey(const ValueKey(3))).dy, tester.getTopLeft(find.byKey(const ValueKey(0))).dy);
      expect(tester.getTopLeft(find.byKey(const ValueKey(4))).dy, greaterThan(tester.getTopLeft(find.byKey(const ValueKey(0))).dy));
    });
  });

  testWidgets('state panel offers retry on errors', (tester) async {
    var retried = 0;
    await tester.pumpWidget(host(GhStatePanel.error(title: 'Could not load', message: 'Offline', onRetry: () => retried++)));
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });
}
