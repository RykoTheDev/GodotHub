import 'package:flutter/widgets.dart';
import 'package:godothub/i18n/i18n.dart';
import 'package:godothub/i18n/i18n_controller.dart';
import 'package:godothub/src/ui_prefs.dart';

Future<GhI18n> setUpTestI18n([String language = 'en-US']) async {
  final i18n = await GhI18n.init(
    prefs: UiPrefsStore(MemoryUiPrefsBackend()),
    settingsLanguage: language,
    settingsRtlLayout: false,
    systemLocales: const [Locale('en', 'US')],
  );
  LocaleSettings.setLocaleSync(ghAppLocaleFor(i18n.language) ?? AppLocale.enUs);
  return i18n;
}
