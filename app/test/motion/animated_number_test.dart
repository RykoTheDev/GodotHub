import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:godothub/debug/gallery/sections/motion_numbers.dart';
import 'package:godothub/motion/animated_number.dart';
import 'package:godothub/motion/motion.dart';

const _style = TextStyle(fontSize: 20, height: 1.5);

class _Driver {
  _Driver(num initial) : value = ValueNotifier<num>(initial);

  final ValueNotifier<num> value;

  Widget build({GhMotionPrefs prefs = const GhMotionPrefs(), bool reduced = false, String? locale, Alignment alignment = Alignment.topLeft}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: GhMotion(
          prefs: prefs,
          child: Align(
            alignment: alignment,
            child: ValueListenableBuilder<num>(
              valueListenable: value,
              builder: (context, v, _) => GhAnimatedNumber(v, style: _style, locale: locale),
            ),
          ),
        ),
      ),
    );
  }
}

GhNumberFlowSnapshot _snap(WidgetTester tester) => debugGhNumberFlow(tester.element(find.byType(GhAnimatedNumber)))!;

Future<void> _set(WidgetTester tester, _Driver driver, num value) async {
  driver.value.value = value;
  await tester.pump();
  await tester.pump();
}

List<List<GhNumberGlyph>> _columns(GhNumberFlowSnapshot snap, {double minOpacity = 0.01}) {
  final digits = snap.visible(minOpacity: minOpacity).where((g) => g.masked && int.tryParse(g.text) != null).toList();
  final byX = <int, List<GhNumberGlyph>>{};
  for (final g in digits) {
    byX.putIfAbsent((g.offset.dx * 100).round(), () => []).add(g);
  }
  final keys = byX.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final k in keys) byX[k]!];
}

GhNumberGlyph? _glyph(List<GhNumberGlyph> column, String text) {
  for (final g in column) {
    if (g.text == text) {
      return g;
    }
  }
  return null;
}

String _settledText(GhNumberFlowSnapshot snap) {
  final glyphs = snap.visible().toList()..sort((a, b) => a.offset.dx.compareTo(b.offset.dx));
  return glyphs.map((g) => g.text).join();
}

void main() {
  test('formats like Intl.NumberFormat with default options', () {
    expect(ghFormatNumber(0), '0');
    expect(ghFormatNumber(999), '999');
    expect(ghFormatNumber(1234), '1,234');
    expect(ghFormatNumber(1234567), '1,234,567');
    expect(ghFormatNumber(-1234), '-1,234');
    expect(ghFormatNumber(1.5), '1.5');
    expect(ghFormatNumber(1.0), '1');
    expect(ghFormatNumber(1.23456), '1.235');
    expect(ghFormatNumber(1234, locale: 'de-DE'), '1.234');
    expect(ghFormatNumber(1234.5, locale: 'pt-BR'), '1.234,5');
    expect(ghFormatNumber(1234, locale: 'es-ES'), '1234');
    expect(ghFormatNumber(12345, locale: 'es-ES'), '12.345');
    expect(ghFormatNumber(1234, locale: 'es-MX'), '1,234');
    expect(ghFormatNumber(1234, locale: 'fr-FR'), '1 234');
    expect(ghFormatNumber(1234, locale: 'ru-RU'), '1 234');
    expect(ghPlainNumber(1234), '1234');
    expect(ghPlainNumber(3.0), '3');
    expect(ghPlainNumber(2.5), '2.5');
  });

  test('timings match number-flow defaults', () {
    expect(GhNumberFlowTiming.transform, const Duration(milliseconds: 900));
    expect(GhNumberFlowTiming.opacity, const Duration(milliseconds: 450));
    expect(GhNumberFlowTiming.transformPoints.first, 0);
    expect(GhNumberFlowTiming.transformPoints.last, 1);
    expect(GhNumberFlowTiming.transformPoints.length, 90);
    expect(GhNumberFlowTiming.transformEase.transform(1 / 89), closeTo(.005, 1e-9));
    expect(GhNumberFlowTiming.opacityEase, const Cubic(0, 0, 0.58, 1));
  });

  testWidgets('first build renders the formatted number without animating', (tester) async {
    final driver = _Driver(1234);
    await tester.pumpWidget(driver.build());
    final snap = _snap(tester);
    expect(snap.text, '1,234');
    expect(snap.animating, isFalse);
    expect(_settledText(snap), '1,234');
    expect(snap.glyphs.every((g) => g.opacity == 1), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.bySemanticsLabel('1,234'), findsOneWidget);
  });

  testWidgets('plain unformatted text when animated numbers is off or intensity is none', (tester) async {
    final driver = _Driver(1234);
    await tester.pumpWidget(driver.build(prefs: const GhMotionPrefs(animatedNumbers: false)));
    expect(find.text('1234'), findsOneWidget);
    expect(debugGhNumberFlow(tester.element(find.byType(GhAnimatedNumber))), isNull);

    await tester.pumpWidget(driver.build(prefs: const GhMotionPrefs(intensity: GhMotionIntensity.none)));
    expect(find.text('1234'), findsOneWidget);
    driver.value.value = 1235;
    await tester.pump();
    expect(find.text('1235'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('OS reduced motion keeps the formatting but never animates', (tester) async {
    final driver = _Driver(999);
    await tester.pumpWidget(driver.build(reduced: true));
    await _set(tester, driver, 1000);
    final snap = _snap(tester);
    expect(snap.animating, isFalse);
    expect(_settledText(snap), '1,000');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('counting up rolls the new digit in from below', (tester) async {
    final driver = _Driver(5);
    await tester.pumpWidget(driver.build());
    final emTop = _snap(tester).glyphs.single.offset.dy;
    await _set(tester, driver, 6);
    await tester.pump(const Duration(milliseconds: 150));
    final early = _columns(_snap(tester)).single;
    final sixEarly = _glyph(early, '6')!;
    final fiveEarly = _glyph(early, '5')!;
    expect(sixEarly.offset.dy, greaterThan(emTop));
    expect(fiveEarly.offset.dy, lessThan(emTop));
    await tester.pump(const Duration(milliseconds: 150));
    final sixLater = _glyph(_columns(_snap(tester)).single, '6')!;
    expect(sixLater.offset.dy, lessThan(sixEarly.offset.dy));
    expect(sixLater.offset.dy, greaterThanOrEqualTo(emTop));
    await tester.pump(const Duration(milliseconds: 700));
    final settled = _snap(tester);
    expect(settled.animating, isFalse);
    expect(settled.glyphs.single.offset.dy, emTop);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('counting down rolls the new digit in from above', (tester) async {
    final driver = _Driver(6);
    await tester.pumpWidget(driver.build());
    final emTop = _snap(tester).glyphs.single.offset.dy;
    await _set(tester, driver, 5);
    await tester.pump(const Duration(milliseconds: 150));
    final column = _columns(_snap(tester)).single;
    expect(_glyph(column, '5')!.offset.dy, lessThan(emTop));
    expect(_glyph(column, '6')!.offset.dy, greaterThan(emTop));
  });

  testWidgets('9 to 0 wraps forward when the whole number grows', (tester) async {
    final driver = _Driver(9);
    await tester.pumpWidget(driver.build());
    final emTop = _snap(tester).glyphs.single.offset.dy;
    await _set(tester, driver, 10);
    await tester.pump(const Duration(milliseconds: 150));
    final ones = _columns(_snap(tester)).first;
    expect(_glyph(ones, '0')!.offset.dy, greaterThan(emTop));
    expect(_glyph(ones, '9')!.offset.dy, lessThan(emTop));
  });

  testWidgets('a falling number spins each digit downward the long way round', (tester) async {
    final driver = _Driver(1234);
    await tester.pumpWidget(driver.build());
    await _set(tester, driver, 987);
    await tester.pump(const Duration(milliseconds: 200));
    final columns = _columns(_snap(tester));
    final hundreds = columns[2].map((g) => g.text).toSet();
    expect(hundreds.difference({'2', '1', '0', '9'}), isEmpty);
    expect(hundreds.intersection({'1', '0'}), isNotEmpty);
  });

  testWidgets('layout width snaps while the mask width animates from the old width', (tester) async {
    final driver = _Driver(9);
    await tester.pumpWidget(driver.build());
    final before = _snap(tester);
    final em = before.em;
    final oneDigit = before.size.width;
    await _set(tester, driver, 10);
    final start = _snap(tester);
    expect(start.size.width, closeTo(oneDigit * 2, 1e-6));
    expect(start.mask, isNotNull);
    expect(start.mask!.width, closeTo(oneDigit + em, 1e-6));
    await tester.pump(const Duration(milliseconds: 300));
    final mid = _snap(tester).mask!.width;
    expect(mid, greaterThan(oneDigit + em));
    expect(mid, lessThan(oneDigit * 2 + em));
    await tester.pump(const Duration(milliseconds: 700));
    final end = _snap(tester);
    expect(end.mask, isNull);
    expect(_settledText(end), '10');
  });

  testWidgets('existing digits slide right as a new leading digit fades in', (tester) async {
    final driver = _Driver(9);
    await tester.pumpWidget(driver.build());
    final settledX = _snap(tester).glyphs.single.offset.dx;
    await _set(tester, driver, 10);
    final start = _columns(_snap(tester), minOpacity: 0);
    expect(start.first.first.offset.dx, closeTo(settledX, 1e-6));
    final leading = start.last.first;
    expect(leading.opacity, lessThan(0.01));
    await tester.pump(const Duration(milliseconds: 300));
    final mid = _columns(_snap(tester));
    expect(mid.first.first.offset.dx, greaterThan(settledX));
    expect(mid.last.first.opacity, greaterThan(0.5));
  });

  testWidgets('separators and removed digits fade out then leave', (tester) async {
    final driver = _Driver(1234);
    await tester.pumpWidget(driver.build());
    await _set(tester, driver, 987);
    final start = _snap(tester);
    expect(start.glyphs.where((g) => g.text == ',').single.opacity, closeTo(1, 0.01));
    await tester.pump(const Duration(milliseconds: 500));
    final faded = _snap(tester);
    expect(faded.glyphs.where((g) => g.text == ',').single.opacity, lessThan(0.01));
    await tester.pump(const Duration(milliseconds: 500));
    final end = _snap(tester);
    expect(end.animating, isFalse);
    expect(end.glyphs.map((g) => g.text).join(), '987');
  });

  testWidgets('a group separator appears when crossing a thousand', (tester) async {
    final driver = _Driver(999);
    await tester.pumpWidget(driver.build());
    final narrow = _snap(tester).size.width;
    await _set(tester, driver, 1000);
    final start = _snap(tester);
    expect(start.size.width, greaterThan(narrow));
    expect(start.glyphs.where((g) => g.text == ',').single.opacity, lessThan(0.01));
    await tester.pump(const Duration(seconds: 1));
    expect(_settledText(_snap(tester)), '1,000');
    expect(_snap(tester).text, '1,000');
  });

  testWidgets('a right-aligned number keeps its ones digit still while growing to the left', (tester) async {
    final driver = _Driver(9);
    await tester.pumpWidget(driver.build(alignment: Alignment.topRight));
    final box = tester.getTopLeft(find.byType(GhAnimatedNumber)).dx;
    final settled = _snap(tester).glyphs.single.offset.dx + box;
    await _set(tester, driver, 10);
    final newBox = tester.getTopLeft(find.byType(GhAnimatedNumber)).dx;
    expect(newBox, lessThan(box));
    final start = _columns(_snap(tester), minOpacity: 0);
    expect(start.first.first.offset.dx + newBox, closeTo(settled, 1e-6));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_columns(_snap(tester)).first.first.offset.dx + newBox, closeTo(settled, 1e-6));
  });

  testWidgets('a locale changes the separators', (tester) async {
    final driver = _Driver(1234);
    await tester.pumpWidget(driver.build(locale: 'de-DE'));
    expect(_settledText(_snap(tester)), '1.234');
  });

  testWidgets('speed setting does not scale number-flow timings', (tester) async {
    final driver = _Driver(5);
    await tester.pumpWidget(driver.build(prefs: const GhMotionPrefs(speed: 2)));
    await _set(tester, driver, 6);
    await tester.pump(const Duration(milliseconds: 850));
    expect(_snap(tester).animating, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_snap(tester).animating, isFalse);
  });

  testWidgets('gallery sections build, jump and play', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final section in motionNumbersSections) {
      await tester.pumpWidget(
        MaterialApp(
          home: GhMotion(
            child: Scaffold(body: SingleChildScrollView(child: Builder(builder: section.builder))),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('Play all'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: GhMotion(
          child: Scaffold(body: SingleChildScrollView(child: Builder(builder: motionNumbersSections.first.builder))),
        ),
      ),
    );
    await tester.tap(find.text('99 to 100'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('100'), findsWidgets);
  });
}
