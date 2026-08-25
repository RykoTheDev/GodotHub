import i18n from '../i18n'

/**
 * BCP 47 tag for the Intl APIs, taken from the UI language instead of the OS.
 *
 * Passing `undefined` to Intl makes it follow the system locale, so picking
 * Japanese on an English Windows still rendered dates as "Aug 26, 2026".
 *
 * `resolvedLanguage` is preferred over `language` because the detector can
 * hand i18next a tag we do not ship (e.g. "de-DE"), and only the resolved
 * value reflects the fallback that is actually being rendered.
 */
export function uiLocale(): string {
  return i18n.resolvedLanguage || i18n.language || 'en-US'
}

export function formatLocaleDate(
  date: Date,
  options?: Intl.DateTimeFormatOptions,
): string {
  return date.toLocaleDateString(uiLocale(), options)
}

export function formatLocaleTime(
  date: Date,
  options?: Intl.DateTimeFormatOptions,
): string {
  return date.toLocaleTimeString(uiLocale(), options)
}

export function formatLocaleDateTime(
  date: Date,
  options?: Intl.DateTimeFormatOptions,
): string {
  return date.toLocaleString(uiLocale(), options)
}

export function formatRelativeTime(
  value: number,
  unit: Intl.RelativeTimeFormatUnit,
): string {
  return new Intl.RelativeTimeFormat(uiLocale(), { numeric: 'auto' }).format(
    value,
    unit,
  )
}
