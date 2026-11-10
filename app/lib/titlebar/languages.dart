import 'strings.dart' as s;

enum LanguageStatus { complete, beta, incomplete }

const systemLanguageValue = 'system';

class LanguageOption {
  const LanguageOption({required this.value, required this.label, required this.country, required this.status});

  final String value;
  final String label;
  final String country;
  final LanguageStatus status;

  bool get isSystem => value == systemLanguageValue;
}

const languages = <LanguageOption>[
  LanguageOption(value: systemLanguageValue, label: s.systemLanguage, country: 'SYSTEM', status: LanguageStatus.complete),
  LanguageOption(value: 'zh-CN', label: '简体中文', country: 'CN', status: LanguageStatus.complete),
  LanguageOption(value: 'fr-FR', label: 'Français', country: 'FR', status: LanguageStatus.complete),
  LanguageOption(value: 'ja-JP', label: '日本語', country: 'JP', status: LanguageStatus.complete),
  LanguageOption(value: 'en-US', label: 'English', country: 'US', status: LanguageStatus.complete),
  LanguageOption(value: 'vi-VN', label: 'Tiếng Việt', country: 'VN', status: LanguageStatus.complete),
  LanguageOption(value: 'pt-BR', label: 'Português (Brasil)', country: 'BR', status: LanguageStatus.beta),
  LanguageOption(value: 'ar-MA', label: 'العربية', country: 'MA', status: LanguageStatus.beta),
  LanguageOption(value: 'es-MX', label: 'Español', country: 'MX', status: LanguageStatus.incomplete),
  LanguageOption(value: 'ru-RU', label: 'Русский', country: 'RU', status: LanguageStatus.incomplete),
];

const switchToLtrLayoutLabel = 'التبديل إلى التخطيط من اليسار إلى اليمين';
const switchToRtlLayoutLabel = 'التبديل إلى التخطيط من اليمين إلى اليسار';

const _rtlBaseLanguages = {'ar', 'he', 'fa', 'ur'};

String languageStatusLabel(LanguageStatus status) => switch (status) {
  LanguageStatus.complete => s.languageComplete,
  LanguageStatus.beta => s.languageBeta,
  LanguageStatus.incomplete => s.languageIncomplete,
};

String _baseOf(String language) => language.split('-').first.toLowerCase();

bool isRtlLanguage(String language) => _rtlBaseLanguages.contains(_baseOf(language));

bool isLanguageActive(String value, String setting) {
  if (value == systemLanguageValue) return setting == systemLanguageValue;
  if (setting == systemLanguageValue) return false;
  return setting == value || setting.toLowerCase().startsWith(_baseOf(value));
}
