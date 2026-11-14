import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/ui/controls/checkbox.dart';
import 'package:godothub/ui/controls/slider.dart';
import 'package:godothub/ui/core/interaction.dart';
import 'package:godothub/ui/core/tooltip.dart';

import 'controls_test.dart' show host, settle;
import 'i18n_setup.dart';

SemanticsData labelled(String label) => find.semantics.byLabel(label).evaluate().single.getSemanticsData();

void main() {
  setUp(setUpTestI18n);

  testWidgets('a label that replaces visible text keeps the tap action and focus state', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        GhPressable(
          onPressed: () => taps++,
          semanticLabel: 'Appearance',
          excludeChildSemantics: true,
          builder: (context, states) => const Text('Appearance'),
        ),
      ),
    );
    expect(labelled('Appearance').label, 'Appearance');
    expect(labelled('Appearance').hasAction(SemanticsAction.tap), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(labelled('Appearance').flagsCollection.isFocused, Tristate.isTrue);

    tester.semantics.tap(find.semantics.byLabel('Appearance'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('a pressable can expose a value next to its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        GhPressable(
          onPressed: () {},
          semanticLabel: 'Accent Color',
          semanticValue: '#457ff2',
          excludeChildSemantics: true,
          builder: (context, states) => const Text('#457FF2'),
        ),
      ),
    );
    expect(labelled('Accent Color').value, '#457ff2');
    expect(find.semantics.byLabel('#457FF2'), findsNothing);
    handle.dispose();
  });

  testWidgets('a labelled checkbox reads its label once', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(GhCheckbox(checked: true, label: 'Unused versions', onChanged: (_) {}, child: const Text('Unused versions'))));
    expect(labelled('Unused versions').label, 'Unused versions');
    expect(labelled('Unused versions').flagsCollection.isChecked, CheckedState.isTrue);
    handle.dispose();
  });

  testWidgets('a slider without its own label takes the field name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        GhFieldName(
          name: 'Corner radius',
          child: GhSlider(value: 7, min: 0, max: 20, onChanged: (_) {}),
        ),
      ),
    );
    expect(labelled('Corner radius').flagsCollection.isSlider, isTrue);
    handle.dispose();
  });

  testWidgets('a tooltip opened by keyboard focus stays out of the semantics tree', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Row(
          children: [
            GhTooltip(
              message: 'Layout tooltip',
              child: GhPressable(onPressed: () {}, semanticLabel: 'List', builder: (context, states) => const SizedBox(width: 40, height: 40)),
            ),
            GhPressable(onPressed: () {}, semanticLabel: 'Next', builder: (context, states) => const SizedBox(width: 40, height: 40)),
          ],
        ),
      ),
    );
    final before = find.semantics.byLabel('List').evaluate().single.id;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await settle(tester);
    expect(find.text('Layout tooltip'), findsOneWidget);
    expect(find.semantics.byLabel('Layout tooltip'), findsNothing);
    final focused = find.semantics.byLabel('List').evaluate().single;
    expect(focused.id, before);
    expect(focused.getSemanticsData().flagsCollection.isFocused, Tristate.isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await settle(tester);
    expect(find.text('Layout tooltip'), findsNothing);
    expect(labelled('Next').flagsCollection.isFocused, Tristate.isTrue);
    expect(labelled('List').flagsCollection.isFocused, isNot(Tristate.isTrue));
    handle.dispose();
  });
}
