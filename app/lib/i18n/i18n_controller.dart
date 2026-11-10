import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../src/ui_prefs.dart';
import 'i18n.dart';
import 'languages.dart';

class GhI18n extends ChangeNotifier {
  GhI18n._(this._prefs);

  static const languageKey = 'i18nextLng';
  static const rtlLayoutKey = 'godothub_rtl_layout';

  static GhI18n instance = GhI18n._(UiPrefsStore.instance);

  final UiPrefsStore _prefs;
  String _language = 'en-US';
  bool _rtlLayout = false;

  String get language => _language;
  bool get rtlLayout => _rtlLayout;
  TextDirection get textDirection => ghTextDirectionOf(_language);
  TextDirection get layoutDirection => ghLayoutDirection(_language, rtlLayout: _rtlLayout);
  AppLocale get locale => ghAppLocaleFor(_language) ?? AppLocale.enUs;

  static Future<GhI18n> init({
    UiPrefsStore? prefs,
    String? settingsLanguage,
    bool? settingsRtlLayout,
    List<Locale>? systemLocales,
  }) async {
    final store = prefs ?? UiPrefsStore.instance;
    final i18n = GhI18n._(store);
    instance = i18n;
    registerI18nextPluralRules();
    await initializeDateFormatting();
    final locales = systemLocales ?? PlatformDispatcher.instance.locales;
    if (store.getItem(languageKey) == ghSystemLanguage) {
      store.setItem(languageKey, ghSystemLanguageFor(locales));
    }
    i18n._rtlLayout = settingsRtlLayout ?? store.getItem(rtlLayoutKey) == '1';
    final detected = settingsLanguage != null
        ? ghResolveLanguage(settingsLanguage, systemLocales: locales)
        : store.getItem(languageKey) ?? (locales.isEmpty ? 'en-US' : locales.first.toLanguageTag());
    i18n._apply(detected);
    return i18n;
  }

  void setLanguageSetting(String setting, {List<Locale>? systemLocales}) {
    final resolved = ghResolveLanguage(setting, systemLocales: systemLocales);
    if (resolved == _language) return;
    _apply(resolved);
    notifyListeners();
  }

  void setRtlLayout(bool enabled) {
    if (enabled == _rtlLayout) return;
    _rtlLayout = enabled;
    _prefs.setItem(rtlLayoutKey, enabled ? '1' : '0');
    notifyListeners();
  }

  void _apply(String language) {
    _language = language;
    LocaleSettings.setLocaleSync(locale);
    _prefs.setItem(languageKey, language);
  }
}
