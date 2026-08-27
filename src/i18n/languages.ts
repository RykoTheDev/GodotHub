export type LanguageStatus = 'complete' | 'beta' | 'incomplete'

export const SYSTEM_LANGUAGE = 'system'

export interface LanguageOption {
  value: string
  label: string
  labelKey?: string
  country: string
  status: LanguageStatus
  priority?: number
}

export const LANGUAGES: LanguageOption[] = [
  {
    value: SYSTEM_LANGUAGE,
    label: 'System language',
    labelKey: 'language_system',
    country: 'SYSTEM',
    status: 'complete',
    priority: -1,
  },

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

export function getSystemLanguage(): string {
  if (typeof navigator === 'undefined') {
    return 'en-US'
  }

  const availableLanguages = LANGUAGES.filter(
    (language) => language.value !== SYSTEM_LANGUAGE,
  )

  const systemLanguages =
    navigator.languages?.length
      ? navigator.languages
      : [navigator.language]

  for (const systemLanguage of systemLanguages) {
    const normalized = systemLanguage.toLowerCase()

    const exact = availableLanguages.find(
      (language) =>
        language.value.toLowerCase() === normalized,
    )

    if (exact) {
      return exact.value
    }

    const baseLanguage = normalized.split('-')[0]

    const compatible = availableLanguages.find(
      (language) =>
        language.value.toLowerCase().split('-')[0] === baseLanguage,
    )

    if (compatible) {
      return compatible.value
    }
  }

  return 'en-US'
}

const STATUS_ORDER: Record<LanguageStatus, number> = {
  complete: 0,
  beta: 1,
  incomplete: 2,
}

const countryNames = new Intl.DisplayNames(['en'], {
  type: 'region',
})

LANGUAGES.sort((a, b) => {
  const priorityDifference =
    (a.priority ?? 0) - (b.priority ?? 0)

  if (priorityDifference !== 0) {
    return priorityDifference
  }

  const statusDifference =
    STATUS_ORDER[a.status] - STATUS_ORDER[b.status]

  if (statusDifference !== 0) {
    return statusDifference
  }

  if (
    a.value === SYSTEM_LANGUAGE ||
    b.value === SYSTEM_LANGUAGE
  ) {
    return 0
  }

  const countryA =
    countryNames.of(a.country) ?? a.country

  const countryB =
    countryNames.of(b.country) ?? b.country

  return countryA.localeCompare(countryB, 'en')
})