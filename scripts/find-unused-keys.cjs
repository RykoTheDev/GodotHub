#!/usr/bin/env node
// ─── Unused i18n Key Finder ─────────────────────────────────────────
// Reports en-US keys that no source file references, so dead strings can
// be deleted instead of being translated into every locale forever.
//
// Usage:
//   bun run i18n:unused              # Human-readable report
//   bun run i18n:unused -- --json    # Machine-readable JSON
//   bun run i18n:unused -- --strict  # Exit 1 when unused keys are found
//
// Detection is deliberately conservative. A key counts as used when either:
//   - its name appears as a quoted literal anywhere under src/, which covers
//     t('key') as well as keys passed around in config objects, or
//   - it starts with a prefix that is built dynamically, as in
//     t(`asset_source_${asset.source}`)
//
// Static analysis cannot follow every indirection, so the output is a list
// to review by hand. Never delete from it automatically.
// ─────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');

// ── Config ──────────────────────────────────────────────────────────
const LOCALES_DIR = 'src/i18n/locales';
const SOURCE_LOCALE = 'en-US';
const SRC_DIR = 'src';

// Locale JSON is the haystack, and the generated types mirror it, so both
// would match every key and hide the ones that are actually dead.
const SKIP = [
  path.join('src', 'i18n', 'locales'),
  path.join('src', 'i18n', 'types.ts'),
];

// ── Colors (no dependency needed) ───────────────────────────────────
const c = {
  reset:   '\x1b[0m',
  bold:    '\x1b[1m',
  dim:     '\x1b[2m',
  green:   '\x1b[32m',
  yellow:  '\x1b[33m',
  cyan:    '\x1b[36m',
};

// ── Parse CLI flags ─────────────────────────────────────────────────
const rawArgs = process.argv.slice(2);
const jsonMode = rawArgs.includes('--json');
const strictMode = rawArgs.includes('--strict');
const useColor = !jsonMode && process.stdout.isTTY;
const annotate = !jsonMode && !!process.env.GITHUB_ACTIONS;

// GitHub renders at most 10 warning annotations per step, and the rest are
// dropped silently. Stop at the limit and point at the log for the others.
const ANNOTATION_LIMIT = 10;
let annotated = 0;

function color(text, ...codes) {
  if (!useColor) return text;
  return codes.join('') + text + c.reset;
}

// ── Collect en-US keys, with the line each one sits on ──────────────
function collectKeys(file) {
  const raw = fs.readFileSync(file, 'utf8');
  const lines = raw.split(/\r?\n/);
  const keys = [];

  function walk(obj, prefix) {
    for (const [k, v] of Object.entries(obj)) {
      const full = prefix ? `${prefix}.${k}` : k;
      if (v && typeof v === 'object' && !Array.isArray(v)) {
        walk(v, full);
      } else {
        keys.push({ key: full, line: lines.findIndex(l => l.includes(`"${k}":`)) + 1 });
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

// ── Read every source file as one haystack ──────────────────────────
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

// Any quoted identifier counts, not just the ones inside t(). Keys reach the
// call through props and config objects often enough that narrowing this to
// t('…') would report keys that are very much alive.
const literals = new Set();
for (const m of source.matchAll(/['"`]([A-Za-z0-9_:.]+)['"`]/g)) {
  literals.add(m[1].split(':').pop());
}

// t(`preview_state_${s}`) resolves at runtime, so every key under the prefix
// has to be treated as reachable.
const prefixes = [...new Set(
  [...source.matchAll(/`([A-Za-z0-9_]+_)\$\{/g)].map(m => m[1])
)].sort();

// i18next resolves foo_one / foo_other from a t('foo') call.
const PLURAL_SUFFIX = /_(one|other|zero|two|few|many)$/;

function isUsed(key) {
  if (literals.has(key)) return true;
  if (literals.has(key.replace(PLURAL_SUFFIX, ''))) return true;
  return prefixes.some(p => key.startsWith(p));
}

// ── Report ──────────────────────────────────────────────────────────
const unused = {};
let total = 0;
let scanned = 0;
for (const [ns, keys] of Object.entries(namespaces)) {
  scanned += keys.length;
  const dead = keys.filter(k => !isUsed(k.key));
  if (dead.length) {
    unused[ns] = dead;
    total += dead.length;
  }
}

if (jsonMode) {
  console.log(JSON.stringify({
    sourceLocale: SOURCE_LOCALE,
    scannedKeys: scanned,
    scannedFiles: files.length,
    dynamicPrefixes: prefixes,
    unusedCount: total,
    unused: Object.fromEntries(
      Object.entries(unused).map(([ns, keys]) => [ns, keys.map(k => k.key)])
    ),
  }, null, 2));
  process.exit(strictMode && total > 0 ? 1 : 0);
}

console.log('');
console.log(color('  ╭─────────────────────────────────────────────╮', c.cyan));
console.log(color('  │         🔎  Unused i18n Keys                 │', c.cyan, c.bold));
console.log(color('  ╰─────────────────────────────────────────────╯', c.cyan));
console.log('');
console.log(color(`  Scanned ${scanned} ${SOURCE_LOCALE} keys against ${files.length} source files`, c.dim));
console.log(color(`  Dynamic prefixes treated as used: ${prefixes.join(', ') || 'none'}`, c.dim));
console.log('');

if (total === 0) {
  console.log(color('  🎉 Every key is referenced somewhere.', c.green));
  console.log('');
  process.exit(0);
}

for (const [ns, keys] of Object.entries(unused)) {
  console.log(color(`  ${ns}.json`, c.bold) + color(` (${keys.length})`, c.dim));
  for (const { key, line } of keys) {
    console.log(`    ${color('✗', c.yellow)} ${key}` + color(`  :${line}`, c.dim));
    if (annotate && annotated < ANNOTATION_LIMIT) {
      console.log(`::warning file=${path.posix.join(LOCALES_DIR, SOURCE_LOCALE, ns + '.json')},line=${line}::Unused i18n key "${key}"`);
      annotated++;
    }
  }
  console.log('');
}

console.log(color('  ────────────────────────────────────────────────', c.dim));
console.log(color(`  ${total} of ${scanned} keys look unreferenced`, c.yellow, c.bold));
if (annotate && total > ANNOTATION_LIMIT) {
  console.log(color(`  Annotated the first ${ANNOTATION_LIMIT}, the rest are listed above`, c.dim));
}
console.log('');
console.log(color('  💡 Next steps:', c.cyan));
console.log('     1. Confirm by hand, indirection can hide a real usage');
console.log(`     2. Delete the dead keys from every locale under ${LOCALES_DIR}/`);
console.log('     3. Run bun run i18n:types to shrink the generated types');
console.log('');

process.exit(strictMode ? 1 : 0);
