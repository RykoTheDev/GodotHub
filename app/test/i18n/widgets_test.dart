import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/i18n/i18n_controller.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/titlebar/language_menu.dart';
import 'package:godothub/titlebar/running_projects_chip.dart';
import 'package:godothub/ui/controls/feature_setup_picker.dart';
import 'package:godothub/logic/features.dart';
import 'package:godothub/ui/controls/search_bar.dart';
import 'package:godothub/ui/overlays/date_picker.dart';

import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show settingsWith;
import '../ui/i18n_setup.dart';

const _toRtl = 'التبديل إلى التخطيط من اليمين إلى اليسار';
const _toLtr = 'التبديل إلى التخطيط من اليسار إلى اليمين';

Widget _app(Widget child) => TranslationProvider(
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(body: Align(alignment: Alignment.topRight, child: child)),
      ),
    );

void main() {
  setUp(setUpTestI18n);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.enUs));

  group('locale switching', () {
    testWidgets('widgets under TranslationProvider rebuild with the new locale', (tester) async {
      await tester.pumpWidget(_app(SizedBox(width: 400, child: GhSearchBar(value: '', onChanged: (_) {}))));
      final english = AppLocale.enUs.translations.common.search_projects_placeholder;
      final japanese = AppLocale.jaJp.translations.common.search_projects_placeholder;
      expect(japanese, isNot(english));
      expect(find.text(english), findsOneWidget);

      GhI18n.instance.setLanguageSetting('ja-JP');
      await tester.pumpAndSettle();
      expect(find.text(japanese), findsOneWidget);
      expect(find.text(english), findsNothing);
    });

    testWidgets('feature picker uses the plural accessor of the active locale', (tester) async {
      GhI18n.instance.setLanguageSetting('ar-MA');
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SizedBox(width: 600, child: GhFeatureSetupPicker(enabled: const {GhFeatureId.news}, onChanged: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final arabic = AppLocale.arMa.translations;
      expect(find.text(arabic.settings.features_enabled_count(count: 3)), findsOneWidget);
      expect(
        arabic.settings.features_enabled_count(count: 3),
        ghTr('settings:features_enabled_count', count: 3, translations: arabic),
      );
      expect(find.text(arabic.settings.setup_profile_custom), findsOneWidget);
    });

    test('running projects description follows each locale plural rules', () {
      for (final locale in [AppLocale.enUs, AppLocale.jaJp, AppLocale.arMa, AppLocale.ruRu]) {
        final translations = locale.translations;
        for (final count in [0, 1, 2, 5, 11, 100]) {
          expect(
            runningProjectsDescription(count, translations),
            ghTr('common:running_projects_desc', count: count, translations: translations),
          );
        }
      }
      expect(runningProjectsDescription(2, AppLocale.enUs.translations), '2 projects running');
    });
  });

  group('LanguageMenu', () {
    testWidgets('Japanese labels, switching to Arabic shows the RTL toggle which flips mirroring', (tester) async {
      GhI18n.instance.setLanguageSetting('ja-JP');
      var current = settingsWith(lang: 'ja-JP');
      final saved = <AppSettings>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fakeSettings(
              () => current,
              onSave: (next) {
                saved.add(next);
                current = next;
                return next;
              },
            ),
          ],
          child: _app(const LanguageMenu()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-menu-trigger')));
      await tester.pumpAndSettle();

      final japanese = AppLocale.jaJp.translations;
      expect(find.text(japanese.common.language_label.toUpperCase()), findsOneWidget);
      expect(find.text(japanese.settings.language_complete), findsNWidgets(5));
      expect(find.text(japanese.common.system_language), findsOneWidget);
      expect(find.byKey(const ValueKey('rtl-layout-toggle')), findsNothing);

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(saved.last.language, 'ar-MA');
      expect(GhI18n.instance.language, 'ar-MA');
      expect(GhI18n.instance.textDirection, TextDirection.rtl);
      expect(GhI18n.instance.layoutDirection, TextDirection.ltr);
      expect(LocaleSettings.currentLocale, AppLocale.arMa);

      await tester.tap(find.byKey(const ValueKey('language-menu-trigger')));
      await tester.pumpAndSettle();
      final arabic = AppLocale.arMa.translations;
      expect(find.text(arabic.common.language_label.toUpperCase()), findsOneWidget);
      expect(find.text(arabic.settings.language_beta), findsNWidgets(2));
      expect(find.byKey(const ValueKey('rtl-layout-toggle')), findsOneWidget);
      expect(find.bySemanticsLabel(_toRtl), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rtl-layout-toggle')));
      await tester.pumpAndSettle();
      expect(saved.last.rtlLayout, isTrue);
      expect(saved.last.language, 'ar-MA');
      expect(find.bySemanticsLabel(_toLtr), findsOneWidget);

      GhI18n.instance.setRtlLayout(saved.last.rtlLayout);
      expect(GhI18n.instance.layoutDirection, TextDirection.rtl);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(GhI18n.instance.language, 'en-US');
      expect(GhI18n.instance.layoutDirection, TextDirection.ltr);
      await tester.tap(find.byKey(const ValueKey('language-menu-trigger')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('rtl-layout-toggle')), findsNothing);
      expect(find.text(AppLocale.enUs.translations.common.language_label.toUpperCase()), findsOneWidget);
    });
  });

  group('DatePicker formatting', () {
    final date = DateTime(2026, 1, 5);

    test('numeric dates follow the locale', () {
      expect(ghFormatDate(date, 'en-US'), '1/5/2026');
      expect(ghFormatDate(date, 'ja-JP'), '2026/1/5');
      expect(ghFormatDate(date, 'fr-FR'), '05/01/2026');
      expect(ghFormatDate(date, 'vi-VN'), '5/1/2026');
      expect(ghFormatDate(date, 'zh-CN'), '2026/1/5');
      expect(ghFormatDate(date, 'pt-BR'), '05/01/2026');
      expect(ghFormatDate(date, 'ar-MA'), '5‏/1‏/2026');
      expect(ghFormatDate(date, 'es-MX'), '5/1/2026');
      expect(ghFormatDate(date, 'ru-RU'), '05.01.2026');
    });

    test('month and weekday names', () {
      expect(ghIntlLocale('ar-MA'), 'ar');
      expect(ghIntlLocale('ja-JP'), 'ja');
      expect(ghIntlLocale('zh-CN'), 'zh_CN');
      expect(ghMonthNames('en-US').first, 'January');
      expect(ghCapitalizeWords(ghMonthNames('fr-FR').first), 'Janvier');
      expect(ghCapitalizeWords(ghMonthNames('ru-RU').first), 'Январь');
      expect(ghMonthNames('ja-JP').first, '1月');
      expect(ghWeekdayNames('en-US'), ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
      expect(ghWeekdayNames('fr-FR'), ['dim', 'lun', 'mar', 'mer', 'jeu', 'ven', 'sam']);
      expect(ghWeekdayNames('ja-JP'), ['日', '月', '火', '水', '木', '金', '土']);
      expect(ghWeekdayNames('ar-MA'), ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']);
    });

    testWidgets('picker renders in the current language and keeps overrides', (tester) async {
      GhI18n.instance.setLanguageSetting('fr-FR');
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                child: GhDatePicker(value: '2026-01-05', placeholder: '-', clearLabel: 'x', onChanged: (_) {}),
              ),
              GhDatePicker(
                value: '2026-01-05',
                placeholder: '-',
                clearLabel: 'x',
                compact: true,
                formatDate: (d) => 'custom ${d.day}',
                changeDueLabel: (d) => 'due $d',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('05/01/2026'), findsOneWidget);
      expect(find.bySemanticsLabel('due custom 5'), findsOneWidget);
      await tester.tap(find.text('05/01/2026'));
      await tester.pumpAndSettle();
      expect(find.text('Janvier'), findsOneWidget);
      expect(find.text('dim'), findsOneWidget);
      expect(find.bySemanticsLabel(AppLocale.frFr.translations.common.date_previous_month), findsOneWidget);
    });
  });
}
