#!/usr/bin/env node
// ─── Unused i18n Key Remover ───────────────────────────────────────
// Finds en-US keys that no source file references, then deletes them
// from every locale JSON file and regenerates types.ts.
//
// Usage:
//   node scripts/remove-unused-keys.cjs            # Dry run (report only)
//   node scripts/remove-unused-keys.cjs --apply    # Actually delete keys
//   node scripts/remove-unused-keys.cjs --apply --strict  # Fail on any removal
//
// ⚠️  Always review the dry-run output before running with --apply.
// ─────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ── Config ──────────────────────────────────────────────────────────
const LOCALES_DIR = 'src/i18n/locales';
const SOURCE_LOCALE = 'en-US';
const TYPES_FILE = 'src/i18n/types.ts';
const SRC_DIR = 'src';

const SKIP = [
  path.join('src', 'i18n', 'locales'),
  path.join('src', 'i18n', 'types.ts'),
];

// ── Colors ──────────────────────────────────────────────────────────
const c = {
  reset:  '\x1b[0m',
  bold:   '\x1b[1m',
  dim:    '\x1b[2m',
  red:    '\x1b[31m',
  green:  '\x1b[32m',
  yellow: '\x1b[33m',
  cyan:   '\x1b[36m',
};

function color(text, ...codes) {
  if (!process.stdout.isTTY) return text;
  return codes.join('') + text + c.reset;
}

// ── Parse CLI flags ─────────────────────────────────────────────────
const rawArgs = process.argv.slice(2);
const apply = rawArgs.includes('--apply');
const strictMode = rawArgs.includes('--strict');

// ── Collect en-US keys ─────────────────────────────────────────────
function collectKeys(file) {
  const raw = fs.readFileSync(file, 'utf8');
  const keys = [];

  function walk(obj, prefix) {
    for (const [k, v] of Object.entries(obj)) {
      const full = prefix ? `${prefix}.${k}` : k;
      if (v && typeof v === 'object' && !Array.isArray(v)) {
        walk(v, full);
      } else {
        keys.push(full);
      }
    }
  }
  walk(JSON.parse(raw), '');
  return keys;
}

const sourceDir = path.join(LOCALES_DIR, SOURCE_LOCALE);
const namespaces = {};
for (const file of fs.readdirSync(sourceDir).filter(f => f.endsWith('.json'))) {
  namespaces[file.replace('.json', '')] = collectKeys(path.join(sourceDir, file));
}

// ── Read source files ──────────────────────────────────────────────
function sourceFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (SKIP.some(s => p === s || p.startsWith(s + path.sep))) continue;
    if (entry.isDirectory()) sourceFiles(p, out);
    else if (/\.(ts|tsx)$/.test(entry.name)) out.push(p);
  }
  return out;
}

const files = sourceFiles(SRC_DIR);
const source = files.map(f => fs.readFileSync(f, 'utf8')).join('\n');

// Build literal set
const literals = new Set();
for (const m of source.matchAll(/['"`]([A-Za-z0-9_:.]+)['"`]/g)) {
  literals.add(m[1].split(':').pop());
}

// Dynamic prefixes
const prefixes = [...new Set(
  [...source.matchAll(/`([A-Za-z0-9_]+_)\$\{/g)].map(m => m[1])
)].sort();

const PLURAL_SUFFIX = /_(one|other|zero|two|few|many)$/;

function isUsed(key) {
  if (literals.has(key)) return true;
  if (literals.has(key.replace(PLURAL_SUFFIX, ''))) return true;
  return prefixes.some(p => key.startsWith(p));
}

// ── Find unused keys ───────────────────────────────────────────────
const unused = {};
let total = 0;
for (const [ns, keys] of Object.entries(namespaces)) {
  const dead = keys.filter(k => !isUsed(k));
  if (dead.length) {
    unused[ns] = dead;
    total += dead.length;
  }
}

// ── Report ──────────────────────────────────────────────────────────
console.log('');
console.log(color('  ╭─────────────────────────────────────────────╮', c.cyan));
console.log(color('  │         🗑️  Remove Unused i18n Keys          │', c.cyan, c.bold));
console.log(color('  ╰─────────────────────────────────────────────╯', c.cyan));
console.log('');
console.log(color(`  Mode: ${apply ? color('APPLY', c.red, c.bold) : color('DRY RUN', c.yellow, c.bold)}`, c.dim));
console.log(color(`  Found ${total} unused keys across ${Object.keys(unused).length} namespaces`, c.dim));
console.log('');

if (total === 0) {
  console.log(color('  🎉 No unused keys found.', c.green));
  console.log('');
  process.exit(0);
}

// Show what will be removed
for (const [ns, keys] of Object.entries(unused)) {
  console.log(color(`  ${ns}.json`, c.bold) + color(` (${keys.length})`, c.dim));
  for (const key of keys) {
    console.log(`    ${color('✗', c.yellow)} ${key}`);
  }
  console.log('');
}

if (!apply) {
  console.log(color('  ────────────────────────────────────────────────', c.dim));
  console.log(color('  Dry run complete. Re-run with --apply to delete.', c.yellow));
  console.log('');
  process.exit(0);
}

// ── Delete from locale files ───────────────────────────────────────
console.log(color('  Removing keys from locale files...', c.cyan));
console.log('');

const locales = fs.readdirSync(LOCALES_DIR).filter(d => {
  return fs.statSync(path.join(LOCALES_DIR, d)).isDirectory();
});

let removedCount = 0;

for (const locale of locales) {
  const localeDir = path.join(LOCALES_DIR, locale);
  let localeRemoved = 0;

  for (const [ns, deadKeys] of Object.entries(unused)) {
    const filePath = path.join(localeDir, `${ns}.json`);
    if (!fs.existsSync(filePath)) continue;

    const raw = fs.readFileSync(filePath, 'utf8');
    const obj = JSON.parse(raw);

    for (const key of deadKeys) {
      if (key in obj) {
        delete obj[key];
        localeRemoved++;
      }
    }

    if (localeRemoved > 0) {
      fs.writeFileSync(filePath, JSON.stringify(obj, null, 2) + '\n');
    }
  }

  if (localeRemoved > 0) {
    console.log(`    ${color('✓', c.green)} ${locale}: removed ${localeRemoved} keys`);
    removedCount += localeRemoved;
  }
}

console.log('');
console.log(color(`  Total removed: ${removedCount} key occurrences across ${locales.length} locales`, c.dim));
console.log('');

// ── Regenerate types ───────────────────────────────────────────────
console.log(color('  Regenerating types.ts...', c.cyan));
try {
  execSync('node scripts/generate-i18n-types.cjs', { stdio: 'inherit' });
  console.log(color('  ✓ types.ts updated', c.green));
} catch (e) {
  console.log(color('  ⚠ Failed to regenerate types.ts — run manually: bun run i18n:types', c.yellow));
}

console.log('');
console.log(color('  ────────────────────────────────────────────────', c.dim));
console.log(color('  Done! Run `npx tsc --noEmit` to verify.', c.green));
console.log('');

process.exit(strictMode && total > 0 ? 1 : 0);
