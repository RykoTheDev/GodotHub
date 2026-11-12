import 'dart:ui';

import 'i18n.dart';

enum GhLanguageStatus { complete, beta, incomplete }

const ghSystemLanguage = 'system';

class GhLanguageOption {
  const GhLanguageOption({
    required this.value,
    required this.label,
    required this.country,
    required this.status,
    this.labelKey,
    this.priority = 0,
  });

  final String value;
  final String label;
  final String? labelKey;
  final String country;
  final GhLanguageStatus status;
  final int priority;

  bool get isSystem => value == ghSystemLanguage;

  String displayLabel([Translations? translations]) => labelKey == null ? label : ghTr(labelKey!, translations: translations);
}

const _unsorted = <GhLanguageOption>[
  GhLanguageOption(
    value: ghSystemLanguage,
    label: 'System language',
    labelKey: 'system_language',
    country: 'SYSTEM',
    status: GhLanguageStatus.complete,
    priority: -1,
  ),
  GhLanguageOption(value: 'en-US', label: 'English', country: 'US', status: GhLanguageStatus.complete),
  GhLanguageOption(value: 'ja-JP', label: '日本語', country: 'JP', status: GhLanguageStatus.complete),
  GhLanguageOption(value: 'fr-FR', label: 'Français', country: 'FR', status: GhLanguageStatus.complete),
  GhLanguageOption(value: 'vi-VN', label: 'Tiếng Việt', country: 'VN', status: GhLanguageStatus.complete),
  GhLanguageOption(value: 'zh-CN', label: '简体中文', country: 'CN', status: GhLanguageStatus.complete),
  GhLanguageOption(value: 'pt-BR', label: 'Português (Brasil)', country: 'BR', status: GhLanguageStatus.beta),
  GhLanguageOption(value: 'ar-MA', label: 'العربية', country: 'MA', status: GhLanguageStatus.beta),
  GhLanguageOption(value: 'es-MX', label: 'Español', country: 'MX', status: GhLanguageStatus.incomplete),
  GhLanguageOption(value: 'ru-RU', label: 'Русский', country: 'RU', status: GhLanguageStatus.incomplete),
];

const _englishRegionNames = {
  'BR': 'Brazil',
  'CN': 'China',
  'FR': 'France',
  'JP': 'Japan',
  'MA': 'Morocco',
  'MX': 'Mexico',
  'RU': 'Russia',
  'US': 'United States',
  'VN': 'Vietnam',
};

final List<GhLanguageOption> ghLanguages = List.of(_unsorted)
  ..sort((a, b) {
    final priority = a.priority - b.priority;
    if (priority != 0) return priority;
    final status = a.status.index - b.status.index;
    if (status != 0) return status;
    if (a.isSystem || b.isSystem) return 0;
    final countryA = _englishRegionNames[a.country] ?? a.country;
    final countryB = _englishRegionNames[b.country] ?? b.country;
    return countryA.toLowerCase().compareTo(countryB.toLowerCase());
  });

String languageStatusLabelKey(GhLanguageStatus status) => switch (status) {
  GhLanguageStatus.complete => 'settings:language_complete',
  GhLanguageStatus.beta => 'settings:language_beta',
  GhLanguageStatus.incomplete => 'settings:language_incomplete',
};

String ghSystemLanguageFor(List<Locale> systemLocales) {
  final available = ghLanguages.where((l) => !l.isSystem).toList();
  for (final locale in systemLocales) {
    final normalized = locale.toLanguageTag().toLowerCase();
    for (final language in available) {
      if (language.value.toLowerCase() == normalized) return language.value;
    }
    final base = normalized.split('-').first;
    for (final language in available) {
      if (language.value.toLowerCase().split('-').first == base) return language.value;
    }
  }
  return 'en-US';
}

String ghSystemLanguageNow() => ghSystemLanguageFor(PlatformDispatcher.instance.locales);

String ghResolveLanguage(String language, {List<Locale>? systemLocales}) =>
    language == ghSystemLanguage ? (systemLocales == null ? ghSystemLanguageNow() : ghSystemLanguageFor(systemLocales)) : language;

bool ghIsLanguageActive(String value, String setting) {
  if (value == ghSystemLanguage) return setting == ghSystemLanguage;
  if (setting == ghSystemLanguage) return false;
  return setting == value || setting.toLowerCase().startsWith(value.split('-').first.toLowerCase());
}
