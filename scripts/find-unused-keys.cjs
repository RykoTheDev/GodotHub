#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const LOCALES_DIR = 'src/i18n/locales';
const SOURCE_LOCALE = 'en-US';
const SRC_DIR = 'src';

const SKIP = [
  path.join('src', 'i18n', 'locales'),
  path.join('src', 'i18n', 'types.ts'),
];

const c = {
  reset:   '\x1b[0m',
  bold:    '\x1b[1m',
  dim:     '\x1b[2m',
  green:   '\x1b[32m',
  yellow:  '\x1b[33m',
  cyan:    '\x1b[36m',
};

const rawArgs = process.argv.slice(2);
const jsonMode = rawArgs.includes('--json');
const strictMode = rawArgs.includes('--strict');
const useColor = !jsonMode && process.stdout.isTTY;
const annotate = !jsonMode && !!process.env.GITHUB_ACTIONS;

const ANNOTATION_LIMIT = 10;
let annotated = 0;

function color(text, ...codes) {
  if (!useColor) return text;
  return codes.join('') + text + c.reset;
}

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

const literals = new Set();
for (const m of source.matchAll(/['"`]([A-Za-z0-9_:.]+)['"`]/g)) {
  literals.add(m[1].split(':').pop());
}

const prefixes = [...new Set(
  [...source.matchAll(/`([A-Za-z0-9_]+_)\$\{/g)].map(m => m[1])
)].sort();

const PLURAL_SUFFIX = /_(one|other|zero|two|few|many)$/;

function isUsed(key) {
  if (literals.has(key)) return true;
  if (literals.has(key.replace(PLURAL_SUFFIX, ''))) return true;
  return prefixes.some(p => key.startsWith(p));
}

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
