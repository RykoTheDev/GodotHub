import 'package:flutter/widgets.dart';

import '../../i18n/i18n.dart';

export '../../i18n/i18n.dart';

extension GhTranslationsContext on BuildContext {
  Translations get tr =>
      dependOnInheritedWidgetOfExactType<InheritedLocaleData<AppLocale, Translations>>()?.translations ??
      LocaleSettings.instance.currentTranslations;
}
