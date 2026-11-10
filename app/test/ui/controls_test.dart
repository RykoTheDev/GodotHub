import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/debug/gallery/sections/controls.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/ui/controls/checkbox.dart';
import 'package:godothub/ui/controls/feature_setup_picker.dart';
import 'package:godothub/ui/controls/features.dart';
import 'package:godothub/ui/controls/hsv_color_picker.dart';
import 'package:godothub/ui/controls/key_recorder.dart';
import 'package:godothub/ui/controls/search_bar.dart';
import 'package:godothub/ui/controls/slider.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/ui/controls/toggle.dart';
import 'package:godothub/ui/core/interaction.dart';

import 'i18n_setup.dart';

final theme = GhTheme.defaults();

Widget host(Widget child, {TextDirection direction = TextDirection.ltr, double width = 500}) {
  return MaterialApp(
    theme: theme.toThemeData(),
    home: Scaffold(
      body: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: width,
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ),
      ),
    ),
  );
}

Future<void> tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(setUpTestI18n);
  group('GhToggle', () {
    testWidgets('tap toggles and reports the inverted value', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhToggle(checked: false, onChanged: calls.add, label: 'Wifi')));
      await tester.tap(find.byType(GhToggle));
      expect(calls, [true]);
      await tester.pumpWidget(host(GhToggle(checked: true, onChanged: calls.add, label: 'Wifi')));
      await tester.tap(find.byType(GhToggle));
      expect(calls, [true, false]);
    });

    testWidgets('size matches h-7 w-12 and thumb moves to the end when checked', (tester) async {
      await tester.pumpWidget(host(GhToggle(checked: false, onChanged: (_) {})));
      expect(tester.getSize(find.byType(GhToggle)), Size(theme.space(12), theme.space(7)));
      AnimatedPositioned thumb() => tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
      expect(thumb().left, 3);
      await tester.pumpWidget(host(GhToggle(checked: true, onChanged: (_) {})));
      await settle(tester);
      expect(thumb().left, theme.space(12) - 2 - theme.space(5) - 3);
    });

    testWidgets('mirrors in rtl', (tester) async {
      await tester.pumpWidget(host(GhToggle(checked: true, onChanged: (_) {}), direction: TextDirection.rtl));
      final flip = tester.widget<Transform>(find.descendant(of: find.byType(GhToggle), matching: find.byType(Transform)).first);
      expect(flip.transform.entry(0, 0), -1);
    });

    testWidgets('disabled ignores taps and is dimmed', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhToggle(checked: false, disabled: true, onChanged: calls.add)));
      await tester.tap(find.byType(GhToggle), warnIfMissed: false);
      expect(calls, isEmpty);
      expect(
        find.descendant(of: find.byType(GhToggle), matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.4)),
        findsOneWidget,
      );
    });

    testWidgets('Tab focuses and Space / Enter activate', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhToggle(checked: false, onChanged: calls.add)));
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, [true, true]);
    });

    testWidgets('pressed thumb squashes', (tester) async {
      await tester.pumpWidget(host(GhToggle(checked: false, onChanged: (_) {})));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(GhToggle)));
      await tester.pump(const Duration(milliseconds: 200));
      await settle(tester);
      final container = tester.widget<AnimatedContainer>(
        find.descendant(of: find.byType(AnimatedPositioned), matching: find.byType(AnimatedContainer)),
      );
      expect(container.transform!.entry(0, 0), closeTo(1.25, 1e-6));
      expect(container.transform!.entry(1, 1), closeTo(0.9, 1e-6));
      await gesture.up();
      await settle(tester);
    });

    testWidgets('exposes toggled semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GhToggle(checked: true, onChanged: (_) {}, label: 'Wifi')));
      expect(find.bySemanticsLabel('Wifi'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Wifi')), isSemantics(label: 'Wifi', hasToggledState: true, isToggled: true));
      handle.dispose();
    });
  });

  group('GhCheckbox', () {
    testWidgets('tap reports the inverted checked value', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhCheckbox(checked: false, onChanged: calls.add, child: const Text('Addons'))));
      await tester.tap(find.text('Addons'));
      expect(calls, [true]);
    });

    testWidgets('indeterminate shows the minus icon and still reports !checked', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhCheckbox(checked: false, indeterminate: true, onChanged: calls.add)));
      await settle(tester);
      expect(find.byWidgetPredicate((w) => w is GhAnimatedIcon && w.icon == GhIcons.minus), findsOneWidget);
      await tester.tap(find.byType(GhCheckbox));
      expect(calls, [true]);
    });

    testWidgets('checked shows the check icon, unchecked hides it', (tester) async {
      await tester.pumpWidget(host(GhCheckbox(checked: true, onChanged: (_) {})));
      await settle(tester);
      expect(find.byWidgetPredicate((w) => w is GhAnimatedIcon && w.icon == GhIcons.check), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Opacity && w.opacity == 1), findsWidgets);
      await tester.pumpWidget(host(GhCheckbox(checked: false, onChanged: (_) {})));
      await settle(tester);
      expect(find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0), findsOneWidget);
    });

    testWidgets('negative margin keeps layout tight but extends the hit area', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        host(
          Padding(
            padding: const EdgeInsets.all(20),
            child: GhCheckbox(checked: false, onChanged: calls.add),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(GhCheckbox));
      expect(rect.width, closeTo(theme.space(4), 1e-9));
      expect(rect.height, closeTo(theme.space(4), 1e-9));
      await tester.tapAt(rect.topLeft - Offset(theme.space(0.5), theme.space(0.5)));
      expect(calls, [true]);
    });

    testWidgets('check-pop plays when it becomes checked', (tester) async {
      await tester.pumpWidget(host(GhCheckbox(checked: false, onChanged: (_) {})));
      await settle(tester);
      await tester.pumpWidget(host(GhCheckbox(checked: true, onChanged: (_) {})));
      await tester.pump(const Duration(milliseconds: 16));
      final rotations = tester
          .widgetList<Transform>(find.descendant(of: find.byType(GhCheckbox), matching: find.byType(Transform)))
          .map((t) => t.transform.entry(0, 1).abs())
          .where((v) => v > 0.01);
      expect(rotations, isNotEmpty);
      await settle(tester);
    });

    testWidgets('disabled ignores input and keyboard focus', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhCheckbox(checked: false, disabled: true, onChanged: calls.add, child: const Text('Off'))));
      await tester.tap(find.text('Off'), warnIfMissed: false);
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, isEmpty);
    });

    testWidgets('Tab focuses and Space / Enter activate', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(host(GhCheckbox(checked: true, onChanged: calls.add, child: const Text('Item'))));
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, [false, false]);
    });

    testWidgets('mixed semantics when indeterminate', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GhCheckbox(checked: false, indeterminate: true, label: 'All', onChanged: (_) {})));
      expect(tester.getSemantics(find.bySemanticsLabel('All')), isSemantics(label: 'All', isCheckStateMixed: true));
      handle.dispose();
    });
  });

  group('GhSlider', () {
    Finder trackListener() => find.byWidgetPredicate((w) => w is Listener && w.onPointerMove != null && w.child is SizedBox);

    Widget slider({
      double value = 50,
      double min = 0,
      double max = 100,
      double step = 1,
      double? defaultValue,
      bool disabled = false,
      required ValueChanged<double> onChanged,
      String? label,
    }) {
      return GhSlider(
        value: value,
        min: min,
        max: max,
        step: step,
        defaultValue: defaultValue,
        disabled: disabled,
        label: label,
        display: Text('${value.round()}'),
        onChanged: onChanged,
      );
    }

    testWidgets('arrow keys step, Home / End jump, PageUp takes a tenth', (tester) async {
      final calls = <double>[];
      await tester.pumpWidget(host(slider(onChanged: calls.add)));
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      expect(calls, [51, 51, 49, 49, 0, 100, 60, 40]);
    });

    testWidgets('arrow keys respect fractional steps and bounds', (tester) async {
      final calls = <double>[];
      await tester.pumpWidget(host(slider(value: 1.25, min: 0.75, max: 1.25, step: 0.05, onChanged: calls.add)));
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(calls, [1.2]);
    });

    testWidgets('keyboard focus shows the ring, pointer focus does not', (tester) async {
      await tester.pumpWidget(host(slider(onChanged: (_) {})));
      GhFocusRing ring() =>
          tester.widget<GhFocusRing>(find.descendant(of: find.byType(GhSlider), matching: find.byType(GhFocusRing)).first);
      expect(ring().visible, isFalse);
      await tab(tester);
      expect(ring().visible, isTrue);
    });

    testWidgets('pointer down jumps to position and drag follows', (tester) async {
      final calls = <double>[];
      var value = 50.0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            slider(
              value: value,
              onChanged: (v) {
                calls.add(v);
                setState(() => value = v);
              },
            ),
          ),
        ),
      );
      final track = tester.getRect(trackListener());
      final gesture = await tester.startGesture(Offset(track.left + 1, track.center.dy));
      await tester.pump();
      expect(calls.last, 0);
      await gesture.moveTo(Offset(track.right - 1, track.center.dy));
      await tester.pump();
      expect(calls.last, 100);
      await gesture.moveTo(Offset(track.center.dx, track.center.dy));
      await tester.pump();
      expect(calls.last, closeTo(50, 1));
      await gesture.up();
      await settle(tester);
    });

    testWidgets('reset button restores the default value', (tester) async {
      final calls = <double>[];
      await tester.pumpWidget(host(slider(value: 30, defaultValue: 50, onChanged: calls.add)));
      await settle(tester);
      await tester.tap(find.byWidgetPredicate((w) => w is GhPressable && w.semanticLabel == t.settings.reset_to_default));
      expect(calls, [50]);
      await settle(tester);
    });

    testWidgets('reset collapses when value equals default', (tester) async {
      await tester.pumpWidget(host(slider(value: 50, defaultValue: 50, onChanged: (_) {})));
      await settle(tester);
      final box = tester.widget<AnimatedContainer>(find.byWidgetPredicate((w) => w is AnimatedContainer && w.child is AnimatedOpacity));
      expect(box.constraints?.maxWidth, 0);
    });

    testWidgets('disabled ignores pointer and keyboard', (tester) async {
      final calls = <double>[];
      await tester.pumpWidget(host(slider(disabled: true, defaultValue: 10, onChanged: calls.add)));
      final track = tester.getRect(trackListener());
      await tester.tapAt(Offset(track.left + 2, track.center.dy));
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(calls, isEmpty);
    });

    testWidgets('label and display render', (tester) async {
      await tester.pumpWidget(host(slider(value: 42, label: 'Volume', onChanged: (_) {})));
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });

  group('GhSearchBar', () {
    testWidgets('typing reports changes and placeholder shows when empty', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(GhSearchBar(value: '', onChanged: calls.add)));
      expect(find.text(t.common.search_projects_placeholder), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'godot');
      expect(calls.last, 'godot');
    });

    testWidgets('clear button clears and refocuses the input', (tester) async {
      final calls = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = 'godot';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            GhSearchBar(
              value: value,
              focusNode: node,
              onChanged: (v) {
                calls.add(v);
                setState(() => value = v);
              },
            ),
          ),
        ),
      );
      final clear = find.byWidgetPredicate((w) => w is GhPressable && w.semanticLabel == t.common.clear_search);
      expect(clear, findsOneWidget);
      await tester.tap(clear);
      await tester.pump();
      await tester.pump();
      expect(calls, ['']);
      expect(clear, findsNothing);
      expect(node.hasFocus, isTrue);
      await settle(tester);
    });

    testWidgets('focus within highlights the bar and blur is reported', (tester) async {
      var blurred = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhSearchBar(value: '', onChanged: (_) {}, onBlur: () => blurred++),
              GhToggle(checked: false, onChanged: (_) {}),
            ],
          ),
        ),
      );
      Color background() =>
          tester.widget<GhAnimatedBox>(find.descendant(of: find.byType(GhSearchBar), matching: find.byType(GhAnimatedBox)).first).color!;
      expect(background(), theme.overlay);
      await tab(tester);
      expect(background(), theme.raised);
      await tab(tester);
      expect(background(), theme.overlay);
      expect(blurred, 1);
      await settle(tester);
    });

    testWidgets('key events and caret are forwarded', (tester) async {
      final keys = <LogicalKeyboardKey>[];
      final carets = <int>[];
      await tester.pumpWidget(
        host(
          GhSearchBar(
            value: 'abc',
            onChanged: (_) {},
            onCaretChange: carets.add,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                keys.add(event.logicalKey);
              }
              return event.logicalKey == LogicalKeyboardKey.arrowDown ? KeyEventResult.handled : KeyEventResult.ignored;
            },
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(keys, containsAllInOrder([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.escape]));
      expect(carets, isNotEmpty);
      await settle(tester);
    });
  });

  group('GhKeyRecorder', () {
    testWidgets('records a key after clicking and shows a confirmation', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(GhKeyRecorder(value: 'p', isMac: false, onChanged: calls.add)));
      expect(find.text('Ctrl+P'), findsOneWidget);
      expect(find.text(t.settings.reset_to_default), findsNothing);
      await tester.tap(find.text(t.settings.click_to_rebind));
      await tester.pump();
      expect(find.text(t.settings.press_key), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(calls, ['k']);
      expect(find.text('✓ Ctrl+K'), findsOneWidget);
      expect(find.text(t.settings.press_key), findsNothing);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.text('✓ Ctrl+K'), findsNothing);
    });

    testWidgets('Escape cancels without changing and non-character keys are swallowed', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(GhKeyRecorder(value: 'k', isMac: false, onChanged: calls.add)));
      await tester.tap(find.text(t.settings.click_to_rebind));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pump();
      expect(find.text(t.settings.press_key), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text(t.settings.press_key), findsNothing);
      expect(calls, isEmpty);
    });

    testWidgets('space is recorded and labelled', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(GhKeyRecorder(value: 'k', isMac: true, onChanged: calls.add)));
      await tester.tap(find.text(t.settings.click_to_rebind));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, [' ']);
      expect(find.text('✓ ⌘${t.settings.key_space}'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('reset to default is offered and confirmed', (tester) async {
      var resets = 0;
      await tester.pumpWidget(host(GhKeyRecorder(value: 'k', isMac: false, onChanged: (_) {}, onReset: () => resets++)));
      await tester.tap(find.text(t.settings.reset_to_default));
      await tester.pump();
      expect(resets, 1);
      expect(find.text('✓ Ctrl+P'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('shows None and Space labels', (tester) async {
      await tester.pumpWidget(host(GhKeyRecorder(value: '', isMac: false, onChanged: (_) {})));
      expect(find.text('Ctrl+${t.common.none}'), findsOneWidget);
      await tester.pumpWidget(host(GhKeyRecorder(value: ' ', isMac: true, onChanged: (_) {})));
      expect(find.text('⌘${t.settings.key_space}'), findsOneWidget);
    });

    testWidgets('keyboard activation starts listening and clicking again stops', (tester) async {
      await tester.pumpWidget(host(GhKeyRecorder(value: 'p', isMac: false, onChanged: (_) {})));
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text(t.settings.press_key), findsOneWidget);
      await tester.tap(find.text(t.settings.press_key));
      await tester.pump();
      expect(find.text(t.settings.press_key), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('GhHsvColorPicker', () {
    Finder pickerContainers() => find.descendant(of: find.byType(GhHsvColorPicker), matching: find.byType(Container));

    test('hex and hsv conversions match the React helpers', () {
      expect(hexToHsv('#ff0000'), const GhHsv(0, 100, 100));
      expect(hexToHsv('#00ffff'), const GhHsv(180, 100, 100));
      expect(hexToHsv('#4f7cff'), const GhHsv(225, 69, 100));
      expect(hexToHsv('#000000'), const GhHsv(0, 0, 0));
      expect(hexToHsv('#ff00ff'), const GhHsv(300, 100, 100));
      expect(hsvToHex(0, 100, 100), '#ff0000');
      expect(hsvToHex(180, 100, 100), '#00ffff');
      expect(hsvToHex(225, 69, 100), '#4f7bff');
      expect(hsvToHex(0, 0, 50), '#808080');
    });

    testWidgets('saturation / value square maps pointer to colour', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(GhHsvColorPicker(value: '#ff0000', size: 200, onChanged: calls.add)));
      final square = tester.getRect(pickerContainers().first);
      expect(square.size, const Size(200, 200));
      await tester.tapAt(square.topRight - const Offset(0.01, -0.01));
      expect(calls.last, '#ff0000');
      await tester.tapAt(square.bottomLeft + const Offset(0.01, -0.01));
      expect(calls.last, '#000000');
      await tester.tapAt(square.topLeft + const Offset(0.01, 0.01));
      expect(calls.last, '#ffffff');
    });

    testWidgets('hue bar maps pointer to hue and supports dragging', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(GhHsvColorPicker(value: '#ff0000', size: 200, onChanged: calls.add)));
      final bar = tester.getRect(pickerContainers().at(1));
      expect(bar.height, 14);
      final gesture = await tester.startGesture(bar.center);
      expect(calls.last, '#00ffff');
      await gesture.moveTo(Offset(bar.right + 50, bar.center.dy));
      expect(calls.last, hsvToHex(359, 100, 100));
      await gesture.up();
    });
  });

  group('GhFeatureSetupPicker', () {
    Future<void> pump(WidgetTester tester, Set<GhFeatureId> enabled, ValueChanged<Set<GhFeatureId>> onChanged) {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: GhFeatureSetupPicker(enabled: enabled, onChanged: onChanged),
          ),
          width: 900,
        ),
      );
    }

    testWidgets('selects the matching profile and picking another reports its features', (tester) async {
      final calls = <Set<GhFeatureId>>[];
      await pump(tester, GhSetupProfile.essentials.features.toSet(), calls.add);
      await settle(tester);
      expect(find.text(t.settings.features_always_on.toUpperCase()), findsNothing);
      await tester.tap(find.text(t.settings.setup_profile_studio));
      expect(calls.single, GhSetupProfile.studio.features.toSet());
      await settle(tester);
    });

    testWidgets('custom opens feature rows and toggles report the new set', (tester) async {
      final calls = <Set<GhFeatureId>>[];
      await pump(tester, {}, calls.add);
      await tester.tap(find.text(t.settings.setup_profile_custom));
      await settle(tester);
      expect(find.text(t.settings.features_always_on.toUpperCase()), findsOneWidget);
      expect(find.byType(GhToggle), findsNWidgets(GhCoreFeature.values.length + GhFeatureId.values.length));
      await tester.tap(find.byWidgetPredicate((w) => w is GhToggle && w.label == t.nav.news));
      expect(calls.single, {GhFeatureId.news});
      await tester.tap(find.byWidgetPredicate((w) => w is GhToggle && w.label == t.nav.projects), warnIfMissed: false);
      expect(calls.length, 1);
      await settle(tester);
    });

    testWidgets('non-matching selection starts in custom mode with a feature count', (tester) async {
      await pump(tester, {GhFeatureId.news, GhFeatureId.vault}, (_) {});
      await settle(tester);
      expect(find.text(t.settings.features_optional.toUpperCase()), findsOneWidget);
      expect(find.text(t.settings.features_enabled_count(count: 4)), findsOneWidget);
      expect(t.settings.features_enabled_count(count: 1), '1 feature on');
    });

    testWidgets('picking a profile from custom closes the rows', (tester) async {
      final calls = <Set<GhFeatureId>>[];
      await pump(tester, {GhFeatureId.news}, calls.add);
      await tester.tap(find.text(t.settings.setup_profile_minimal));
      await settle(tester);
      expect(calls.single, <GhFeatureId>{});
      expect(find.text(t.settings.features_always_on.toUpperCase()), findsNothing);
    });

    testWidgets('profiles are keyboard reachable', (tester) async {
      final calls = <Set<GhFeatureId>>[];
      await pump(tester, GhSetupProfile.minimal.features.toSet(), calls.add);
      await tab(tester);
      await tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls.single, GhSetupProfile.essentials.features.toSet());
      await settle(tester);
    });

    test('matchSetupProfile', () {
      expect(matchSetupProfile({}), GhSetupProfile.minimal);
      expect(matchSetupProfile(GhFeatureId.values.toSet()), GhSetupProfile.complete);
      expect(matchSetupProfile({GhFeatureId.news}), isNull);
    });
  });

  group('gallery', () {
    for (final section in controlsSections) {
      testWidgets('${section.title} section renders', (tester) async {
        tester.view.physicalSize = const Size(1400, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.toThemeData(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Builder(builder: section.builder),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
