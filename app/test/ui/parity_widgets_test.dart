import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/motion/motion.dart';
import 'package:godothub/motion/shared.dart';
import 'package:godothub/titlebar/language_menu.dart';
import 'package:godothub/ui/core/bidi.dart';
import 'package:godothub/ui/reusables/segmented.dart';
import 'package:godothub/ui/reusables/unlocalized_badge.dart';

import 'i18n_setup.dart';

Widget _host(Widget child, {GhMotionPrefs prefs = const GhMotionPrefs(speed: 1)}) {
  return TranslationProvider(
    child: MaterialApp(
      theme: GhTheme.defaults().toThemeData(),
      home: GhMotion(
        prefs: prefs,
        osReduced: false,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

class _SegmentedHost extends StatefulWidget {
  const _SegmentedHost();

  @override
  State<_SegmentedHost> createState() => _SegmentedHostState();
}

class _SegmentedHostState extends State<_SegmentedHost> {
  String _value = 'a';

  @override
  Widget build(BuildContext context) {
    return GhSegmented(
      value: _value,
      options: [ghSegment('a', 'Alpha'), ghSegment('b', 'Bravo'), ghSegment('c', 'Charlie')],
      onChanged: (value) => setState(() => _value = value),
    );
  }
}

void main() {
  setUp(() async {
    GhSharedElements.debugReset();
    await setUpTestI18n();
  });

  group('GhSegmented', () {
    Finder thumb() => find.descendant(of: find.byKey(const ValueKey('segment-thumb')), matching: find.byType(DecoratedBox));

    testWidgets('the active thumb slides from the previous option', (tester) async {
      await tester.pumpWidget(_host(const _SegmentedHost()));
      await tester.pumpAndSettle();
      expect(thumb(), findsOneWidget);
      final from = tester.getTopLeft(thumb());
      await tester.tap(find.text('Charlie'));
      await tester.pump();
      expect(tester.getTopLeft(thumb()).dx, closeTo(from.dx, 0.5));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getTopLeft(thumb()).dx;
      expect(mid, greaterThan(from.dx + 1));
      await tester.pumpAndSettle();
      final to = tester.getTopLeft(thumb()).dx;
      expect(to, greaterThan(mid));
      expect(to, closeTo(tester.getTopLeft(find.byKey(const ValueKey('segment:c'))).dx, 0.5));
    });

    testWidgets('the thumb jumps when motion is off', (tester) async {
      await tester.pumpWidget(_host(const _SegmentedHost(), prefs: const GhMotionPrefs(intensity: GhMotionIntensity.none)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Charlie'));
      await tester.pump();
      expect(tester.getTopLeft(thumb()).dx, closeTo(tester.getTopLeft(find.byKey(const ValueKey('segment:c'))).dx, 0.5));
    });
  });

  group('LanguageFlag', () {
    testWidgets('renders the flag svg, the globe for System and nothing for unknown codes', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LanguageFlag(country: 'JP'),
              LanguageFlag(country: 'SYSTEM'),
              LanguageFlag(country: 'XX'),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('language-flag-JP')), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('language-flag-JP'))), const Size(16, 16));
      expect(find.text('\u{1F310}'), findsOneWidget);
      expect(find.text('XX'), findsNothing);
    });
  });

  group('GhUnlocalizedBadge', () {
    const checks = [('common', 'vault_save_btn'), ('common', 'vault_add_btn'), ('common', 'vault_no_match')];

    testWidgets('hidden in English', (tester) async {
      await tester.pumpWidget(_host(const GhUnlocalizedBadge(checks: checks)));
      expect(find.text('UNLOCALIZED'), findsNothing);
    });

    testWidgets('shown when every key matches English', (tester) async {
      await setUpTestI18n('fr-FR');
      await tester.pumpWidget(_host(const GhUnlocalizedBadge(checks: checks)));
      expect(find.text('UNLOCALIZED'), findsOneWidget);
    });

    test('hidden when any key is translated', () async {
      await setUpTestI18n('fr-FR');
      expect(ghIsUnlocalized(t, const [('common', 'vault_save_btn'), ('common', 'search')]), isFalse);
    });
  });

  group('ghPlaintextDirection', () {
    test('Arabic text gets RTL only in the unmirrored Arabic layout', () async {
      final i18n = await setUpTestI18n('ar-MA');
      expect(ghPlaintextDirection('مرحبا', i18n: i18n), TextDirection.rtl);
      expect(ghPlaintextDirection('Godot 4', i18n: i18n), isNull);
      i18n.setRtlLayout(true);
      expect(ghPlaintextDirection('مرحبا', i18n: i18n), isNull);
      final english = await setUpTestI18n();
      expect(ghPlaintextDirection('مرحبا', i18n: english), isNull);
    });
  });
}
