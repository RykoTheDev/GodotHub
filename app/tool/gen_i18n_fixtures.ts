import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import i18next from 'i18next'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const localesDir = join(root, 'src/i18n/locales')
const locales = readdirSync(localesDir).sort()
const namespaces = readdirSync(join(localesDir, 'en-US')).map((f) => f.replace('.json', '')).sort()

const resources: Record<string, Record<string, unknown>> = {}
for (const locale of locales) {
  resources[locale] = {}
  for (const ns of namespaces) {
    try {
      resources[locale][ns] = JSON.parse(readFileSync(join(localesDir, locale, `${ns}.json`), 'utf8'))
    } catch {
      resources[locale][ns] = {}
    }
  }
}

const SUFFIX = /_(zero|one|two|few|many|other)$/
const COUNTS = [0, 1, 2, 3, 4, 5, 11, 12, 21, 22, 25, 100, 101, 102, 111, 1000000]

function flatten(obj: Record<string, unknown>, prefix = ''): Record<string, string> {
  const out: Record<string, string> = {}
  for (const [k, v] of Object.entries(obj)) {
    const path = prefix ? `${prefix}.${k}` : k
    if (v && typeof v === 'object') Object.assign(out, flatten(v as Record<string, unknown>, path))
    else out[path] = String(v)
  }
  return out
}

function varsIn(...texts: (string | undefined)[]) {
  const vars = new Set<string>()
  for (const text of texts) for (const m of (text ?? '').matchAll(/\{\{\s*([^}]+?)\s*\}\}/g)) vars.add(m[1])
  vars.delete('count')
  return Object.fromEntries([...vars].sort().map((v) => [v, `<${v}>`]))
}

await i18next.init({
  resources,
  fallbackLng: 'en-US',
  fallbackNS: ['common'],
  defaultNS: 'common',
  ns: namespaces,
  interpolation: { escapeValue: false },
  returnEmptyString: true,
})

type Case = { ns: string; key: string; plural: boolean; vars: Record<string, string> }
const cases: Case[] = []
for (const ns of namespaces) {
  const en = flatten(resources['en-US'][ns] as Record<string, unknown>)
  const all = locales.map((l) => flatten(resources[l][ns] as Record<string, unknown>))
  const pluralBases = new Set(Object.keys(en).filter((k) => k.endsWith('_one')).map((k) => k.slice(0, -4)))
  const seen = new Set<string>()
  for (const key of Object.keys(en)) {
    const base = key.replace(SUFFIX, '')
    if (base !== key && pluralBases.has(base)) {
      if (seen.has(base)) continue
      seen.add(base)
      const texts = all.flatMap((flat) => Object.entries(flat).filter(([k]) => k === base || k.replace(SUFFIX, '') === base).map(([, v]) => v))
      cases.push({ ns, key: base, plural: true, vars: varsIn(...texts) })
      continue
    }
    cases.push({ ns, key, plural: false, vars: varsIn(...all.map((flat) => flat[key])) })
  }
}

const results: Record<string, (string | string[])[]> = {}
for (const locale of locales) {
  const t = i18next.getFixedT(locale)
  results[locale] = cases.map((c) =>
    c.plural ? COUNTS.map((count) => t(`${c.ns}:${c.key}`, { ...c.vars, count })) : t(`${c.ns}:${c.key}`, c.vars),
  )
}

writeFileSync(
  join(root, 'app/test/fixtures/i18next_resolution.json'),
  JSON.stringify({ i18next: (i18next as unknown as { version?: string }).version ?? 'unknown', counts: COUNTS, cases, results }) + '\n',
)
console.log(`${cases.length} keys x ${locales.length} locales (${cases.filter((c) => c.plural).length} plural groups x ${COUNTS.length} counts)`)
