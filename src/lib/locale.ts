import i18n from '../i18n'

export function isRtl(): boolean {
  return typeof document !== 'undefined' && document.documentElement.dir === 'rtl'
}

export function mirrorSide<T extends string>(side: T): T {
  if (!isRtl()) return side
  if (side === 'left') return 'right' as T
  if (side === 'right') return 'left' as T
  return side
}

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
