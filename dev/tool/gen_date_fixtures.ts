import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const locales = ['ar-MA', 'en-US', 'es-MX', 'fr-FR', 'ja-JP', 'pt-BR', 'ru-RU', 'vi-VN', 'zh-CN']
const dates = [new Date(2026, 0, 5), new Date(2026, 10, 20), new Date(2031, 11, 31)]
const out: Record<string, unknown> = {}
for (const locale of locales) {
  const weekDates = Array.from({ length: 7 }, (_, i) => new Date(2026, 0, 4 + i))
  const short = weekDates.map((d) => new Intl.DateTimeFormat(locale, { weekday: 'short' }).format(d).replace('.', ''))
  const weekdays = short.every((d) => d.length <= 3) ? short : weekDates.map((d) => new Intl.DateTimeFormat(locale, { weekday: 'narrow' }).format(d))
  out[locale] = {
    dates: dates.map((d) => new Intl.DateTimeFormat(locale).format(d)),
    months: Array.from({ length: 12 }, (_, i) => new Intl.DateTimeFormat(locale, { month: 'long' }).format(new Date(2026, i, 1))),
    weekdays,
  }
}
writeFileSync(join(root, 'app/test/fixtures/intl_dates.json'), JSON.stringify({ icu: process.versions.icu, cldr: process.versions.cldr, locales: out }, null, 1) + '\n')
console.log(`ICU ${process.versions.icu}, CLDR ${process.versions.cldr}`)
