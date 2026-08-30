#!/usr/bin/env node
// ─── i18n Translation Checker ───────────────────────────────────────
// Checks all locales against en-US and shows a beautiful summary.
//
// Usage:
//   bun run i18n:check                   # Check all locales
//   bun run i18n:check -- zh-CN          # Check only zh-CN
//   bun run i18n:check -- zh-CN ru-RU    # Check multiple locales
//   bun run i18n:check -- --json         # Machine-readable JSON
//   bun run i18n:check -- --md           # Markdown for PR comments
//   bun run i18n:check -- --md zh-CN     # Markdown for one locale
//   bun run i18n:check -- --missing      # Show only missing keys
//   bun run i18n:check -- --list         # List available locales
//   bun run i18n:check -- --check-values # Also detect untranslated (same as English)
// ─────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');

// ── Config ──────────────────────────────────────────────────────────
const LOCALES_DIR = 'src/i18n/locales';
const SOURCE_LOCALE = 'en-US';

// ── Colors (no dependency needed) ───────────────────────────────────
const c = {
  reset:   '\x1b[0m',
  bold:    '\x1b[1m',
  dim:     '\x1b[2m',
  red:     '\x1b[31m',
  green:   '\x1b[32m',
  yellow:  '\x1b[33m',
  blue:    '\x1b[34m',
  cyan:    '\x1b[36m',
  white:   '\x1b[37m',
  gray:    '\x1b[90m',
};

// ── Parse CLI flags ─────────────────────────────────────────────────
const rawArgs = process.argv.slice(2);
const jsonMode = rawArgs.includes('--json');
const mdMode = rawArgs.includes('--md');
const missingOnly = rawArgs.includes('--missing');
const listMode = rawArgs.includes('--list');
const checkValues = rawArgs.includes('--check-values');
const useColor = !jsonMode && !mdMode && process.stdout.isTTY;

// Filter out flags, remaining args are locale names
const localeFilter = rawArgs.filter(a => !a.startsWith('--'));

function color(text, ...codes) {
  if (!useColor) return text;
  return codes.join('') + text + c.reset;
}

// ── List available locales ──────────────────────────────────────────
if (listMode) {
  const available = fs.readdirSync(LOCALES_DIR, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name)
    .sort();
  
  console.log(color('\n  Available locales:\n', c.bold));
  for (const loc of available) {
    const isSource = loc === SOURCE_LOCALE;
    const tag = isSource ? color(' (source)', c.green, c.dim) : '';
    console.log(`    ${color(loc, c.bold)}${tag}`);
  }
  console.log('');
  process.exit(0);
}

// ── Parse keys from JSON ────────────────────────────────────────────
function parseKeys(filePath) {
  if (!fs.existsSync(filePath)) return null;
  const stat = fs.statSync(filePath);
  if (stat.size === 0) return null;
  try {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const keys = new Set();
    function walk(obj, prefix) {
      for (const [k, v] of Object.entries(obj)) {
        const full = prefix ? `${prefix}.${k}` : k;
        if (typeof v === 'object' && v !== null) walk(v, full);
        else keys.add(full);
      }
    }
    walk(data, '');
    return keys;
  } catch {
    return null;
  }
}

function parseKeysWithValues(filePath) {
  if (!fs.existsSync(filePath)) return null;
  const stat = fs.statSync(filePath);
  if (stat.size === 0) return null;
  try {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const keys = {};
    function walk(obj, prefix) {
      for (const [k, v] of Object.entries(obj)) {
        const full = prefix ? `${prefix}.${k}` : k;
        if (typeof v === 'object' && v !== null) walk(v, full);
        else keys[full] = v;
      }
    }
    walk(data, '');
    return keys;
  } catch {
    return null;
  }
}

// ── Progress bar helper ─────────────────────────────────────────────
function progressBar(pct, width = 20) {
  const filled = Math.round((pct / 100) * width);
  const empty = width - filled;
  const bar = '█'.repeat(filled) + '░'.repeat(empty);
  if (!useColor) return `[${bar}] ${pct.toFixed(0)}%`;
  
  const hue = pct >= 90 ? c.green : pct >= 50 ? c.yellow : c.red;
  return color(`${bar}`, hue) + ` ${color(`${pct.toFixed(0)}%`, pct >= 90 ? c.green : pct >= 50 ? c.yellow : c.red)}`;
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

// Apply locale filter if provided
let locales;
if (localeFilter.length > 0) {
  // Validate requested locales exist
  const invalid = localeFilter.filter(l => !allLocales.includes(l));
  if (invalid.length > 0) {
    console.error(color(`\n  ❌ Unknown locale: ${invalid.join(', ')}`, c.red));
    console.error(color(`  Available: ${allLocales.join(', ')}\n`, c.dim));
    process.exit(1);
  }
  locales = localeFilter.filter(l => allLocales.includes(l));
} else {
  locales = allLocales;
}

// ── Analyze each locale ─────────────────────────────────────────────
const results = {};
let overallMissing = 0;
let overallTotal = 0;
let overallUntranslated = 0;

for (const locale of locales) {
  const localeDir = path.join(LOCALES_DIR, locale);
  results[locale] = { namespaces: {}, totalKeys: 0, missingKeys: 0, extraKeys: 0, untranslatedKeys: 0 };

  for (const ns of namespaces) {
    const enKeys = parseKeys(path.join(enDir, `${ns}.json`));
    const localeKeys = parseKeys(path.join(localeDir, `${ns}.json`));
    const localeData = checkValues ? parseKeysWithValues(path.join(localeDir, `${ns}.json`)) : null;
    const enData = checkValues ? parseKeysWithValues(path.join(enDir, `${ns}.json`)) : null;

    if (!enKeys) continue;

    const enCount = enKeys.size;
    const missing = localeKeys ? [...enKeys].filter(k => !localeKeys.has(k)) : [...enKeys];
    const extra = localeKeys ? [...localeKeys].filter(k => !enKeys.has(k)) : [];
    
    // Find keys with identical English values (untranslated)
    let untranslated = [];
    if (checkValues && localeData && enData) {
      untranslated = [...enKeys].filter(k => localeData[k] && enData[k] && localeData[k] === enData[k]);
    }
    
    const translated = enCount - missing.length - untranslated.length;
    const pct = enCount > 0 ? (translated / enCount) * 100 : 100;

    results[locale].namespaces[ns] = { enCount, translated, missing, extra, untranslated, pct };
    results[locale].totalKeys += enCount;
    results[locale].missingKeys += missing.length;
    results[locale].extraKeys += extra.length;
    results[locale].untranslatedKeys += untranslated.length;
    overallMissing += missing.length;
    overallTotal += enCount;
    overallUntranslated += untranslated.length;
  }
}

// ── JSON output ─────────────────────────────────────────────────────
if (jsonMode) {
  console.log(JSON.stringify({ locales, results, overallMissing, overallTotal }, null, 2));
  process.exit(overallMissing > 0 ? 1 : 0);
}

// ── Markdown output ─────────────────────────────────────────────────
if (mdMode) {
  const title = localeFilter.length > 0
    ? `## 🌐 Key Sync Status — ${localeFilter.join(', ')}\n`
    : '## 🌐 Key Sync Status\n';
  
  console.log(title);
  
  if (locales.length > 1) {
    console.log('| Locale | Progress | Missing | Extra |');
    console.log('|--------|----------|---------|-------|');
  }
  
  for (const locale of locales) {
    const r = results[locale];
    const pct = r.totalKeys > 0 ? ((r.totalKeys - r.missingKeys) / r.totalKeys * 100) : 100;
    const icon = pct >= 100 ? '✅' : pct >= 80 ? '🟡' : '🔴';
    
    if (locales.length > 1) {
      console.log(`| ${locale} | ${icon} ${pct.toFixed(0)}% (${r.totalKeys - r.missingKeys}/${r.totalKeys}) | ${r.missingKeys} | ${r.extraKeys} |`);
    } else {
      console.log(`**${locale}** — ${icon} ${pct.toFixed(0)}% (${r.totalKeys - r.missingKeys}/${r.totalKeys} keys)\n`);
      
      for (const [ns, data] of Object.entries(r.namespaces)) {
        if (data.missing.length === 0 && data.extra.length === 0) continue;
        console.log(`**${ns}.json** (${data.pct.toFixed(0)}%)`);
        if (data.missing.length > 0) {
          console.log(`- Missing (${data.missing.length}): ${data.missing.map(k => '`' + k + '`').join(', ')}`);
        }
        if (data.extra.length > 0) {
          console.log(`- Extra (${data.extra.length}): ${data.extra.map(k => '`' + k + '`').join(', ')}`);
        }
      }
      console.log('');
    }
  }
  
  if (locales.length > 1) {
    console.log(`\n**Total:** ${overallTotal - overallMissing}/${overallTotal} keys present (${((overallTotal - overallMissing) / overallTotal * 100).toFixed(1)}%)`);
  }
  
  process.exit(overallMissing > 0 ? 1 : 0);
}

// ── Pretty terminal output ──────────────────────────────────────────
const isSingle = locales.length === 1;
const singleLocale = isSingle ? locales[0] : null;

console.log('');
if (isSingle) {
  const r = results[singleLocale];
  const pct = r.totalKeys > 0 ? ((r.totalKeys - r.missingKeys) / r.totalKeys * 100) : 100;
  const icon = pct >= 100 ? '✅' : pct >= 80 ? '🟡' : '🔴';
  const cvTag = checkValues ? ' (checking values)' : '';
  
  console.log(color(`  ╭─────────────────────────────────────────────╮`, c.cyan));
  console.log(color(`  │   🌐  ${singleLocale}  ${icon}  ${pct.toFixed(0)}% keys present${cvTag}   │`, c.cyan, c.bold));
  console.log(color(`  ╰─────────────────────────────────────────────╯`, c.cyan));
} else {
  const cvTag = checkValues ? ' (checking values)' : '';
  console.log(color('  ╭─────────────────────────────────────────────╮', c.cyan));
  console.log(color(`  │         🌐  Key Sync Status${cvTag}             │`, c.cyan, c.bold));
  console.log(color('  ╰─────────────────────────────────────────────╯', c.cyan));
}
console.log('');

// ── Summary table ───────────────────────────────────────────────────
const maxLocaleLen = Math.max(...locales.map(l => l.length));

for (const locale of locales) {
  const r = results[locale];
  const pct = r.totalKeys > 0 ? ((r.totalKeys - r.missingKeys) / r.totalKeys * 100) : 100;
  const label = locale.padEnd(maxLocaleLen);
  
  let status;
  if (pct >= 100) status = color('✓ Complete', c.green, c.bold);
  else if (pct >= 80) status = color(`${pct.toFixed(0)}%`, c.yellow, c.bold);
  else status = color(`${pct.toFixed(0)}%`, c.red, c.bold);

  console.log(`  ${color(label, c.bold)}  ${progressBar(pct, 15)}  ${status}`);
}

console.log('');
console.log(color('  ────────────────────────────────────────────────', c.dim));
console.log(`  ${color('Total:', c.bold)} ${color(`${overallTotal - overallMissing}`, c.green)}/${overallTotal} keys present`);
if (overallUntranslated > 0 && !checkValues) {
  console.log(`  ${color('⚠️  Note:', c.yellow)} ${color(`${overallUntranslated}`, c.yellow)} keys may still have English values — run with ${color('--check-values', c.bold)} to verify`);
} else if (overallUntranslated > 0) {
  console.log(`  ${color('⚠️  Note:', c.yellow)} ${color(`${overallUntranslated}`, c.yellow)} keys still have identical English values (not translated)`);
}
console.log('');

// ── Detail per locale ───────────────────────────────────────────────
console.log(color('  📋 Namespace breakdown', c.bold, c.cyan));
console.log('');

for (const locale of locales) {
  const r = results[locale];
  const hasNsIssues = Object.values(r.namespaces).some(d => d.missing.length > 0 || d.extra.length > 0);

  if (isSingle || hasNsIssues) {
    console.log(color(`  ${locale}/`, c.bold));
  }

  for (const [ns, data] of Object.entries(r.namespaces)) {
    // In missing-only mode, skip namespaces with no missing keys
    if (missingOnly && data.missing.length === 0) continue;
    
    // In single mode, show all namespaces; in multi mode, only show ones with issues
    if (!isSingle && !hasNsIssues) continue;
    if (!isSingle && data.missing.length === 0 && data.extra.length === 0) continue;

    const nsPct = data.pct.toFixed(0);
    const nsColor = data.pct >= 90 ? c.green : data.pct >= 50 ? c.yellow : c.red;
    const nsIcon = data.pct >= 100 ? color('✓', c.green) : '';

    console.log(`    ${color(ns + '.json', c.white)} ${nsIcon || color(`${nsPct}%`, nsColor)} ${color(`(${data.translated}/${data.enCount})`, c.dim)}`);

    if (data.missing.length > 0) {
      console.log(`      ${color('↓ Missing:', c.red)} ${data.missing.slice(0, 8).map(k => color(k, c.gray)).join(', ')}`);
      if (data.missing.length > 8) {
        console.log(`        ${color(`... and ${data.missing.length - 8} more`, c.dim)}`);
      }
    }

    if (data.untranslated && data.untranslated.length > 0) {
      console.log(`      ${color('≈ Untranslated:', c.yellow)} ${data.untranslated.slice(0, 8).map(k => color(k, c.gray)).join(', ')}`);
      if (data.untranslated.length > 8) {
        console.log(`        ${color(`... and ${data.untranslated.length - 8} more`, c.dim)}`);
      }
    }

    if (data.extra.length > 0 && !missingOnly) {
      console.log(`      ${color('↑ Extra:', c.yellow)} ${data.extra.slice(0, 5).map(k => color(k, c.gray)).join(', ')}`);
      if (data.extra.length > 5) {
        console.log(`        ${color(`... and ${data.extra.length - 5} more`, c.dim)}`);
      }
    }
  }
  console.log('');
}

// ── Next steps ──────────────────────────────────────────────────────
if (overallMissing > 0) {
  console.log(color('  💡 Next steps:', c.bold, c.blue));
  if (isSingle) {
    console.log(`     ${color('1.', c.cyan)} Add missing keys from ${color('en-US/', c.bold)} to ${color(singleLocale + '/', c.bold)}`);
    console.log(`     ${color('2.', c.cyan)} Translate the values (keep keys identical)`);
    console.log(`     ${color('3.', c.cyan)} Run ${color(`bun run i18n:check -- ${singleLocale}`, c.bold)} again`);
  } else {
    console.log(`     ${color('1.', c.cyan)} Copy missing keys from ${color('en-US/', c.bold)} to each locale`);
    console.log(`     ${color('2.', c.cyan)} Translate the values (keep keys identical)`);
    console.log(`     ${color('3.', c.cyan)} Run ${color('bun run i18n:check', c.bold)} again to verify`);
  }
  console.log('');
} else {
  console.log(color('  🎉 All checked locales have all keys present!', c.green, c.bold));
if (!checkValues) {
  console.log(color('  💡 Run with --check-values to verify translations are not just English', c.dim));
}
  console.log('');
}

// ── Help hint ───────────────────────────────────────────────────────
if (allLocales.length > 1 && locales.length === allLocales.length) {
  console.log(color('  💬 Tip: Filter by locale with bun run i18n:check -- zh-CN', c.dim));
  console.log('');
}

process.exit(overallMissing > 0 ? 1 : 0);
