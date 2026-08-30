#!/usr/bin/env node
// Generates TypeScript types from en-US locale files
// Run: bun run i18n:types

const fs = require('fs');
const path = require('path');

const LOCALES_DIR = 'src/i18n/locales/en-US';
const OUTPUT = 'src/i18n/types.ts';

const nsFiles = fs.readdirSync(LOCALES_DIR).filter(f => {
  if (!f.endsWith('.json')) return false;
  const fp = path.join(LOCALES_DIR, f);
  const stat = fs.statSync(fp);
  if (stat.size === 0) return false;
  try { JSON.parse(fs.readFileSync(fp, 'utf8')); return true; }
  catch { return false; }
});

// Parse keys and build types
const namespaces = {};
for (const f of nsFiles) {
  const ns = f.replace('.json', '');
  const data = JSON.parse(fs.readFileSync(path.join(LOCALES_DIR, f), 'utf8'));
  const keys = [];

  function walk(obj, prefix) {
    for (const [k, v] of Object.entries(obj)) {
      const full = prefix ? `${prefix}.${k}` : k;
      if (typeof v === 'object' && v !== null) walk(v, full);
      else keys.push(full);
    }
  }
  walk(data, '');
  namespaces[ns] = keys;
}

// Generate type definitions
let output = `// AUTO-GENERATED from en-US locale files
// Do not edit manually. Run: bun run i18n:types

`;

for (const [ns, keys] of Object.entries(namespaces)) {
  const unionStr = keys.map(k => `  | '${k}'`).join('\n');
  output += `/** Keys from ${ns}.json */\n`;
  output += `export type ${ns}Keys = \n${unionStr};\n\n`;
}

// All namespaces union
const allNs = Object.keys(namespaces);
output += `/** All namespace names */\n`;
output += `export type Namespace = ${allNs.map(n => `'${n}'`).join(' | ')};\n\n`;

// Combined key type with namespace prefix
const allKeys = [];
for (const [ns, keys] of Object.entries(namespaces)) {
  for (const k of keys) {
    allKeys.push(`${ns}:${k}`);
  }
}
const allUnion = allKeys.map(k => `  | '${k}'`).join('\n');
output += `/** All translation keys (namespace:key) */\n`;
output += `export type TranslationKey = \n${allUnion};\n`;

fs.writeFileSync(OUTPUT, output);
console.log(`Generated ${OUTPUT}`);
console.log(`  ${allNs.length} namespaces, ${allKeys.length} total keys`);
