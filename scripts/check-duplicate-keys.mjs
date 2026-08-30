#!/usr/bin/env node
/**
 * Checks for duplicate translation keys across namespace JSON files
 * within each locale directory.
 *
 * Usage:
 *   node scripts/check-duplicate-keys.mjs           # check all locales
 *   node scripts/check-duplicate-keys.mjs en-US     # check one locale
 *   node scripts/check-duplicate-keys.mjs --same     # only show same-value dupes
 *   node scripts/check-duplicate-keys.mjs --diff     # only show different-value dupes
 */

import { readdirSync, readFileSync } from 'node:fs'
import { join, basename } from 'node:path'

const LOCALES_DIR = new URL('../src/i18n/locales', import.meta.url).pathname

const args = process.argv.slice(2)
const localeFilter = args.find(a => !a.startsWith('--'))
const onlySame = args.includes('--same')
const onlyDiff = args.includes('--diff')

const locales = readdirSync(LOCALES_DIR).filter(d => {
  try { return readdirSync(join(LOCALES_DIR, d)).some(f => f.endsWith('.json')) }
  catch { return false }
})

const filteredLocales = localeFilter ? locales.filter(l => l === localeFilter) : locales

let totalDupes = 0

for (const locale of filteredLocales) {
  const localeDir = join(LOCALES_DIR, locale)
  const files = readdirSync(localeDir).filter(f => f.endsWith('.json'))

  const allKeys = new Map() // key -> [{ file, value }]

  for (const file of files.sort()) {
    const data = JSON.parse(readFileSync(join(localeDir, file), 'utf-8'))
    for (const [key, value] of Object.entries(data)) {
      if (!allKeys.has(key)) allKeys.set(key, [])
      allKeys.get(key).push({ file, value })
    }
  }

  const sameDupes = []
  const diffDupes = []

  for (const [key, entries] of allKeys) {
    if (entries.length <= 1) continue

    const values = [...new Set(entries.map(e => e.value))]
    if (values.length === 1) {
      sameDupes.push({ key, entries })
    } else {
      diffDupes.push({ key, entries, values })
    }
  }

  if (sameDupes.length === 0 && diffDupes.length === 0) continue

  console.log(`\n\u001b[1m=== ${locale} ===\u001b[0m`)

  if (sameDupes.length > 0 && !onlyDiff) {
    console.log(`\n  \u001b[33mSame-value duplicates (${sameDupes.length}):\u001b[0m`)
    for (const { key, entries } of sameDupes) {
      const fileList = entries.map(e => e.file).join(', ')
      console.log(`    \u001b[36m${key}\u001b[0m → ${fileList}`)
      totalDupes++
    }
  }

  if (diffDupes.length > 0 && !onlySame) {
    console.log(`\n  \u001b[31mDifferent-value duplicates (${diffDupes.length}):\u001b[0m`)
    for (const { key, entries, values } of diffDupes) {
      console.log(`    \u001b[36m${key}\u001b[0m`)
      for (const { file, value } of entries) {
        const truncated = value.length > 60 ? value.slice(0, 57) + '...' : value
        console.log(`      ${file}: ${truncated}`)
      }
      totalDupes++
    }
  }
}

if (totalDupes === 0) {
  console.log('\n\u001b[32mNo duplicate keys found.\u001b[0m')
} else {
  console.log(`\n\u001b[1mTotal: ${totalDupes} duplicate key(s) found.\u001b[0m`)
  process.exit(1)
}
