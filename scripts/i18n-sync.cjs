#!/usr/bin/env node
// ─── i18n Sync Tool ─────────────────────────────────────────────────
// Copies missing keys from en-US to all other locales.
//
// Usage:
//   bun run i18n:sync              # Sync all locales (dry run by default)
//   bun run i18n:sync -- --apply   # Actually write changes
//   bun run i18n:sync -- zh-CN     # Sync only zh-CN
//   bun run i18n:sync -- --remove-extras  # Also remove extra keys
//   bun run i18n:sync -- --empty            # Sync with empty values (for translators)
// ─────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');

const LOCALES_DIR = 'src/i18n/locales';
const SOURCE_LOCALE = 'en-US';

// ── Colors ──────────────────────────────────────────────────────────
const c = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

function color(text, ...codes) {
  if (!process.stdout.isTTY) return text;
  return codes.join('') + text + c.reset;
}

// ── Parse args ──────────────────────────────────────────────────────
const rawArgs = process.argv.slice(2);
const applyMode = rawArgs.includes('--apply');
const removeExtras = rawArgs.includes('--remove-extras');
const emptyValues = rawArgs.includes('--empty');
const localeFilter = rawArgs.filter(a => !a.startsWith('--'));

// ── Parse keys ──────────────────────────────────────────────────────
function parseKeys(filePath) {
  if (!fs.existsSync(filePath)) return null;
  const stat = fs.statSync(filePath);
  if (stat.size === 0) return null;
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

function flattenKeys(obj, prefix = '') {
  const keys = {};
  for (const [k, v] of Object.entries(obj)) {
    const full = prefix ? `${prefix}.${k}` : k;
    if (typeof v === 'object' && v !== null) {
      Object.assign(keys, flattenKeys(v, full));
    } else {
      keys[full] = v;
    }
  }
  return keys;
}

function buildObject(keys) {
  const result = {};
  for (const [full, value] of Object.entries(keys)) {
    const parts = full.split('.');
    let current = result;
    for (let i = 0; i < parts.length - 1; i++) {
      if (!current[parts[i]]) current[parts[i]] = {};
      current = current[parts[i]];
    }
    current[parts[parts.length - 1]] = value;
  }
  return result;
}

// ── Get namespaces and locales ──────────────────────────────────────
const enDir = path.join(LOCALES_DIR, SOURCE_LOCALE);
const namespaces = fs.readdirSync(enDir)
  .filter(f => f.endsWith('.json'))
  .map(f => f.replace('.json', ''));

const allLocales = fs.readdirSync(LOCALES_DIR, { withFileTypes: true })
  .filter(d => d.isDirectory() && d.name !== SOURCE_LOCALE)
  .map(d => d.name)
  .sort();

const locales = localeFilter.length > 0
  ? localeFilter.filter(l => allLocales.includes(l))
  : allLocales;

// ── Header ──────────────────────────────────────────────────────────
console.log('');
console.log(color('  ╭─────────────────────────────────────────────╮', c.cyan));
console.log(color('  │         🔄  i18n Sync Tool                  │', c.cyan, c.bold));
console.log(color('  ╰─────────────────────────────────────────────╯', c.cyan));
console.log('');
console.log(color(`  Mode: ${applyMode ? color('APPLY', c.red, c.bold) : color('DRY RUN', c.yellow, c.bold)}`, c.dim));
console.log(color(`  Values: ${emptyValues ? color('EMPTY', c.yellow, c.bold) : color('COPY ENGLISH', c.green, c.bold)}`, c.dim));
console.log(color(`  Source: ${SOURCE_LOCALE}`, c.dim));
console.log(color(`  Target${locales.length > 1 ? 's' : ''}: ${locales.join(', ')}`, c.dim));
console.log('');

let totalAdded = 0;
let totalRemoved = 0;

for (const locale of locales) {
  const localeDir = path.join(LOCALES_DIR, locale);
  console.log(color(`  ${locale}/`, c.bold));

  for (const ns of namespaces) {
    const enFile = path.join(enDir, `${ns}.json`);
    const localeFile = path.join(localeDir, `${ns}.json`);

    const enData = parseKeys(enFile);
    if (!enData) continue;

    let localeData = parseKeys(localeFile) || {};

    const enKeys = flattenKeys(enData);
    const localeKeys = flattenKeys(localeData);

    const missing = Object.keys(enKeys).filter(k => !(k in localeKeys));
    // Also detect keys with empty values that need to be filled (when not using --empty)
    const empty = !emptyValues ? Object.keys(enKeys).filter(k => k in localeKeys && localeKeys[k] === '' && enKeys[k] !== '') : [];
    const extra = Object.keys(localeKeys).filter(k => !(k in enKeys));

    if (missing.length === 0 && empty.length === 0 && extra.length === 0) {
      console.log(color(`    ${ns}.json ✓`, c.green));
      continue;
    }

    let nsChanges = 0;

    if (missing.length > 0) {
      console.log(color(`    ${ns}.json: +${missing.length} missing`, c.yellow));
      for (const k of missing.slice(0, 5)) {
        console.log(color(`      + ${k}`, c.dim));
      }
      if (missing.length > 5) {
        console.log(color(`        ... and ${missing.length - 5} more`, c.dim));
      }

      if (applyMode) {
        for (const k of missing) {
          localeKeys[k] = emptyValues ? '' : enKeys[k];
        }
        nsChanges += missing.length;
      }
    }

    if (empty.length > 0 && !emptyValues) {
      console.log(color(`    ${ns}.json: ~${empty.length} empty (will fill with English)`, c.yellow));
      for (const k of empty.slice(0, 5)) {
        console.log(color(`      ~ ${k}`, c.dim));
      }
      if (empty.length > 5) {
        console.log(color(`        ... and ${empty.length - 5} more`, c.dim));
      }

      if (applyMode) {
        for (const k of empty) {
          localeKeys[k] = enKeys[k];
        }
        nsChanges += empty.length;
      }
    }

    if (extra.length > 0 && removeExtras) {
      console.log(color(`    ${ns}.json: -${extra.length} extras`, c.yellow));
      for (const k of extra.slice(0, 5)) {
        console.log(color(`      - ${k}`, c.dim));
      }

      if (applyMode) {
        for (const k of extra) {
          delete localeKeys[k];
        }
        nsChanges += extra.length;
      }
    }

    if (applyMode && nsChanges > 0) {
      const newContent = buildObject(localeKeys);
      fs.writeFileSync(localeFile, JSON.stringify(newContent, null, 2) + '\n');
      console.log(color(`    ${ns}.json: saved`, c.green));
    }

    totalAdded += missing.length;
    totalRemoved += (removeExtras ? extra.length : 0);
  }
  console.log('');
}

// ── Summary ─────────────────────────────────────────────────────────
console.log(color('  ────────────────────────────────────────────────', c.dim));

if (applyMode) {
  console.log(color(`  ✅ Applied: +${totalAdded} keys, -${totalRemoved} extras`, c.green, c.bold));
} else {
  console.log(color(`  📋 Would add: ${totalAdded} keys`, c.yellow, c.bold));
  if (removeExtras) {
    console.log(color(`  📋 Would remove: ${totalRemoved} extras`, c.yellow, c.bold));
  }
  console.log('');
  console.log(color('  💡 To apply changes, run:', c.cyan));
  console.log(color('     bun run i18n:sync -- --apply', c.bold));
  console.log(color('     bun run i18n:sync -- --apply --empty  (empty values for translators)', c.dim));
}

console.log('');
