import { execFileSync } from 'node:child_process'
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const app = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const repo = resolve(app, '..')
const out = join(app, 'assets', 'licenses', 'rust-crates.txt')
const roots = ['godothub_bridge', 'godothub_launcher']
const check = process.argv.includes('--check')

const metadata = JSON.parse(
  execFileSync('cargo', ['metadata', '--format-version', '1', '--locked', '--manifest-path', join(repo, 'Cargo.toml')], {
    encoding: 'utf8',
    maxBuffer: 256 * 1024 * 1024,
  }),
)
const packages = new Map(metadata.packages.map((p) => [p.id, p]))
const nodes = new Map(metadata.resolve.nodes.map((n) => [n.id, n]))
const workspace = new Set(metadata.workspace_members)

const shipped = new Set()
const queue = metadata.packages.filter((p) => roots.includes(p.name) && workspace.has(p.id)).map((p) => p.id)
while (queue.length) {
  const id = queue.pop()
  if (shipped.has(id)) continue
  shipped.add(id)
  for (const dep of nodes.get(id)?.deps ?? []) {
    if (dep.dep_kinds.some((k) => k.kind === null)) queue.push(dep.pkg)
  }
}

const licenseFile = /^(licen[cs]e|copying|notice|copyright)([-._].*)?$/i
const groups = new Map()
const crates = [...shipped]
  .map((id) => packages.get(id))
  .filter((p) => !workspace.has(p.id))
  .sort((a, b) => a.name.localeCompare(b.name) || a.version.localeCompare(b.version))

for (const crate of crates) {
  const dir = dirname(crate.manifest_path)
  const files = readdirSync(dir)
    .filter((f) => licenseFile.test(f))
    .sort()
  if (crate.license_file && existsSync(join(dir, crate.license_file)) && !files.includes(crate.license_file)) files.push(crate.license_file)
  const texts = files.length
    ? files.map((f) => readFileSync(join(dir, f), 'utf8').replace(/\r\n/g, '\n').trim())
    : [`Licensed under ${crate.license ?? 'an unspecified license'}. The crate ships no license file.`]
  for (const text of texts) {
    if (!groups.has(text)) groups.set(text, [])
    groups.get(text).push(`${crate.name} ${crate.version} (${crate.license ?? 'unknown'})`)
  }
}

const parts = [`Third-party Rust crates used by GodotHub: ${crates.length} crates.\n`]
for (const [text, names] of groups) {
  parts.push(`${'='.repeat(78)}\n${names.join('\n')}\n${'-'.repeat(78)}\n${text}\n`)
}
const content = parts.join('\n')

if (check) {
  const current = existsSync(out) ? readFileSync(out, 'utf8') : ''
  if (current !== content) {
    console.error(`${out} is out of date; run: node app/tool/gen_rust_notices.mjs`)
    process.exit(1)
  }
  console.log(`ok: ${crates.length} crates`)
} else {
  writeFileSync(out, content)
  console.log(`wrote ${out}: ${crates.length} crates, ${groups.size} distinct license texts, ${(content.length / 1024).toFixed(0)} KB`)
}
