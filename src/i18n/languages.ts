export type LanguageStatus = 'complete' | 'beta' | 'incomplete'

export interface LanguageOption {
  value: string
  label: string
  country: string
  status: LanguageStatus
}

export const LANGUAGES: LanguageOption[] = [
  { value: 'en-US', label: 'English', country: 'US', status: 'complete' },
  { value: 'ja-JP', label: '日本語', country: 'JP', status: 'complete' },
  { value: 'fr-FR', label: 'Français', country: 'FR', status: 'complete' },
  { value: 'pt-BR', label: 'Português (Brasil)', country: 'BR', status: 'beta' },
  { value: 'zh-CN', label: '简体中文', country: 'CN', status: 'beta' },
  { value: 'ar-MA', label: 'العربية', country: 'MA', status: 'beta' },
  { value: 'vi-VN', label: 'Tiếng Việt', country: 'VN', status: 'beta' },
  { value: 'es-MX', label: 'Español', country: 'MX', status: 'incomplete' },
  { value: 'ru-RU', label: 'Русский', country: 'RU', status: 'incomplete' },
]

export function languageStatusLabelKey(status: LanguageStatus): string {
  switch (status) {
    case 'complete':
      return 'language_complete'
    case 'beta':
      return 'language_beta'
    case 'incomplete':
      return 'language_incomplete'
  }
}
