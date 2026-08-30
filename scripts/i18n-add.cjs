#!/usr/bin/env node
// ─── i18n Language Adder ────────────────────────────────────────────
// Interactive tool to add a new language to GodotHub.
//
// Usage:
//   node scripts/i18n-add.cjs              # Interactive mode
//   node scripts/i18n-add.cjs ja-JP        # Skip locale prompt
//   node scripts/i18n-add.cjs ja-JP "日本語" # Skip locale & name prompts
// ─────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const LOCALES_DIR = 'src/i18n/locales';
const LANGUAGES_FILE = 'src/i18n/languages.ts';
const INDEX_FILE = 'src/i18n/index.ts';
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
  white: '\x1b[37m',
};

function color(text, ...codes) {
  if (!process.stdout.isTTY) return text;
  return codes.join('') + text + c.reset;
}

// ── Input helper ────────────────────────────────────────────────────
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

function ask(question, defaultVal = '') {
  return new Promise(resolve => {
    rl.question(color(`  ${question}`, c.cyan), answer => {
      resolve(answer.trim() || defaultVal);
    });
  });
}

// ── Main ────────────────────────────────────────────────────────────
async function main() {
  console.log('');
  console.log(color('  ╭─────────────────────────────────────────────╮', c.cyan));
  console.log(color('  │         🌐  Add New Language                 │', c.cyan, c.bold));
  console.log(color('  ╰─────────────────────────────────────────────╯', c.cyan));
  console.log('');

  // Get existing locales
  const existingLocales = fs.readdirSync(LOCALES_DIR, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name)
    .sort();

  // ── Prompt for locale code ──────────────────────────────────────
  let locale = process.argv[2];
  if (!locale) {
    console.log(color('  Existing locales:', c.dim));
    console.log(color(`    ${existingLocales.join(', ')}`, c.dim));
    console.log('');
    locale = await ask('Locale code (e.g. ja-JP): ');
  }

  if (!locale || locale === SOURCE_LOCALE) {
    console.error(color('\n  ❌ Invalid locale code.\n', c.red));
    process.exit(1);
  }

  if (existingLocales.includes(locale)) {
    console.error(color(`\n  ❌ Locale ${locale} already exists!\n`, c.red));
    process.exit(1);
  }

  // ── Prompt for language name ────────────────────────────────────
  let label = process.argv[3];
  if (!label) {
    label = await ask('Language name (e.g. 日本語): ');
  }
  if (!label) {
    console.error(color('\n  ❌ Language name is required.\n', c.red));
    process.exit(1);
  }

  // ── Prompt for country code ─────────────────────────────────────
  let country = locale.split('-')[1] || '';
  if (!country) {
    country = await ask('Country code (e.g. JP): ');
  }
  country = country.toUpperCase();

  // ── Confirm ─────────────────────────────────────────────────────
  console.log('');
  console.log(color('  Summary:', c.bold));
  console.log(`    Locale:   ${color(locale, c.bold)}`);
  console.log(`    Language: ${color(label, c.bold)}`);
  console.log(`    Country:  ${color(country, c.bold)}`);
  console.log('');

  const confirm = await ask('Create this language? (Y/n): ', 'y');
  if (confirm.toLowerCase() !== 'y' && confirm.toLowerCase() !== 'yes') {
    console.log(color('  Cancelled.', c.dim));
    process.exit(0);
  }

  // ── Create locale folder ────────────────────────────────────────
  const localeDir = path.join(LOCALES_DIR, locale);
  const sourceDir = path.join(LOCALES_DIR, SOURCE_LOCALE);

  fs.mkdirSync(localeDir, { recursive: true });

  const sourceFiles = fs.readdirSync(sourceDir).filter(f => f.endsWith('.json'));
  for (const file of sourceFiles) {
    const sourceContent = fs.readFileSync(path.join(sourceDir, file), 'utf8');
    const sourceData = JSON.parse(sourceContent);

    // Create empty values for all keys
    const emptyData = {};
    for (const key of Object.keys(sourceData)) {
      emptyData[key] = '';
    }

    fs.writeFileSync(
      path.join(localeDir, file),
      JSON.stringify(emptyData, null, 2) + '\n'
    );
  }

  console.log(color(`\n  ✅ Created ${locale}/ with ${sourceFiles.length} namespace files`, c.green));

  // ── Update languages.ts ─────────────────────────────────────────
  let languagesContent = fs.readFileSync(LANGUAGES_FILE, 'utf8');

  // Find the LANGUAGES array and add new entry before the closing bracket
  const newLangEntry = `  { value: '${locale}', label: '${label}', country: '${country}', status: 'incomplete' },`;

  // Find the last entry in LANGUAGES array and add after it
  const lastEntryMatch = languagesContent.match(/(\{[^}]+value:\s*'[^']+'[^}]+\},?\s*\n)/g);
  if (lastEntryMatch) {
    const lastEntry = lastEntryMatch[lastEntryMatch.length - 1];
    if (!languagesContent.includes(`'${locale}'`)) {
      languagesContent = languagesContent.replace(
        lastEntry,
        lastEntry + newLangEntry + '\n'
      );
      fs.writeFileSync(LANGUAGES_FILE, languagesContent);
      console.log(color('  ✅ Updated languages.ts', c.green));
    }
  }

  // ── Update index.ts ─────────────────────────────────────────────
  let indexContent = fs.readFileSync(INDEX_FILE, 'utf8');

  // Add imports
  const nsNames = sourceFiles.map(f => f.replace('.json', ''));
  const importLines = nsNames.map(ns => {
    const nsPascal = ns.charAt(0).toUpperCase() + ns.slice(1);
    const prefix = locale.replace('-', '');
    return `import ${prefix}${nsPascal} from './locales/${locale}/${ns}.json'`;
  }).join('\n');

  // Find last import line and add after it
  const lastImportMatch = indexContent.match(/import\s+\w+\s+from\s+'\.\/locales\/[^']+'[^;]*;/g);
  if (lastImportMatch) {
    const lastImport = lastImportMatch[lastImportMatch.length - 1];
    if (!indexContent.includes(`'./locales/${locale}/`)) {
      indexContent = indexContent.replace(
        lastImport,
        lastImport + '\n' + importLines
      );
    }
  }

  // Add resources object
  const prefix = locale.replace('-', '');
  const resourceEntries = nsNames.map(ns => `  ${ns}: ${prefix}${ns.charAt(0).toUpperCase() + ns.slice(1)},`).join('\n');
  const newResources = `const ${prefix}Resources = {\n${resourceEntries}\n}`;

  // Find last resource definition and add after it
  const lastResourceMatch = indexContent.match(/const\s+\w+Resources\s*=\s*\{[^}]+\}/g);
  if (lastResourceMatch) {
    const lastResource = lastResourceMatch[lastResourceMatch.length - 1];
    if (!indexContent.includes(`${prefix}Resources`)) {
      indexContent = indexContent.replace(
        lastResource,
        lastResource + '\n\n' + newResources
      );
    }
  }

  // Add to resources object
  const shortCode = locale.split('-')[0];
  const resourceAddition = `  '${locale}': ${prefix}Resources,\n  ${shortCode}: ${prefix}Resources,`;

  // Find the resources object closing and add before it
  if (!indexContent.includes(`'${locale}'`)) {
    indexContent = indexContent.replace(
      /(\}\s*\n\s*i18n)/,
      resourceAddition + '\n$1'
    );
  }

  fs.writeFileSync(INDEX_FILE, indexContent);
  console.log(color('  ✅ Updated index.ts', c.green));

  // ── Done ────────────────────────────────────────────────────────
  console.log('');
  console.log(color('  🎉 Language added successfully!', c.green, c.bold));
  console.log('');
  console.log(color('  Next steps:', c.bold, c.cyan));
  console.log(color(`     1. Open ${locale}/ files and translate the values`, c.white));
  console.log(color(`     2. Run ${color('bun run i18n:check -- ' + locale, c.bold)} to verify`, c.white));
  console.log(color(`     3. Run ${color('bun run i18n:types', c.bold)} to regenerate types`, c.white));
  console.log('');

  rl.close();
}

main().catch(err => {
  console.error(color(`\n  ❌ Error: ${err.message}\n`, c.red));
  process.exit(1);
});
