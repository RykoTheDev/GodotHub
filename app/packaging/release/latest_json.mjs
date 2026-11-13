import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

const channel = process.env.CHANNEL ?? 'beta'
const tag = process.env.RELEASE_TAG
const repo = process.env.REPO
const dir = process.env.ASSETS_DIR ?? 'dist'
const out = process.env.OUT ?? (channel === 'stable' ? 'latest-v2.json' : 'latest.json')
const notes = (process.env.NOTES ?? '')
  .replace(/(^|\r?\n)(?:---[ \t]*\r?\n(?:[ \t]*\r?\n)*)?## Downloads[\s\S]*$/, '')
  .trimEnd()
if (!tag || !repo) throw new Error('RELEASE_TAG and REPO are required')
if (channel !== 'stable' && channel !== 'beta') throw new Error(`unknown channel ${channel}`)
if (channel === 'stable' && out.endsWith('/latest.json')) throw new Error('latest.json is reserved for the frozen legacy manifest')

const version = tag.replace(channel === 'stable' ? /^v/ : /^flutter-v/, '')
const prefix = channel === 'stable' ? 'GodotHub' : 'GodotHub-Beta'
const url = (name) => `https://github.com/${repo}/releases/download/${tag}/${encodeURIComponent(name)}`

const classify = (name) => {
  const m = name.match(/-(windows|darwin|linux)-([a-z0-9_]+)/)
  if (!m) return null
  const arch = { x64: 'x86_64', amd64: 'x86_64', x86_64: 'x86_64', arm64: 'aarch64', aarch64: 'aarch64' }[m[2]] ?? m[2]
  if (m[1] === 'windows' && name.endsWith('-setup.exe')) return { os: 'windows', arch, installer: 'nsis' }
  if (m[1] === 'windows' && name.endsWith('.msi')) return { os: 'windows', arch, installer: 'msi', only: true }
  if (m[1] === 'windows' && name.endsWith(`-${m[2]}.zip`)) return { os: 'windows', arch, installer: 'inapp', only: true }
  if (m[1] === 'darwin' && name.endsWith('.app.tar.gz')) return { os: 'darwin', arch, installer: 'app' }
  if (m[1] === 'linux' && (name.endsWith('.AppImage.zip') || name.endsWith('.AppImage'))) return { os: 'linux', arch, installer: 'appimage' }
  if (m[1] === 'linux' && name.endsWith('.deb')) return { os: 'linux', arch, installer: 'deb', only: true }
  if (m[1] === 'linux' && name.endsWith('.rpm')) return { os: 'linux', arch, installer: 'rpm', only: true }
  return null
}

const sigs = readdirSync(dir).filter((f) => f.endsWith('.sig')).sort()
if (sigs.length === 0) throw new Error(`no .sig files in ${dir}`)
const platforms = {}
for (const sig of sigs) {
  const name = sig.slice(0, -'.sig'.length)
  const c = classify(name)
  if (!c) throw new Error(`unrecognized updater artifact: ${name}`)
  if (!name.startsWith(`${prefix}-${version}-`)) throw new Error(`artifact ${name} does not belong to ${prefix} ${version}`)
  const entry = { signature: readFileSync(join(dir, sig), 'utf8').trim(), url: url(name) }
  if (c.os === 'darwin' && c.arch === 'universal') {
    for (const arch of ['aarch64', 'x86_64', 'universal']) {
      platforms[`darwin-${arch}`] = entry
      platforms[`darwin-${arch}-app`] = entry
    }
  } else {
    if (!c.only) platforms[`${c.os}-${c.arch}`] = entry
    platforms[`${c.os}-${c.arch}-${c.installer}`] = entry
  }
}
const defaultRequired =
  channel === 'stable'
    ? [
        'darwin-aarch64',
        'darwin-x86_64',
        'darwin-universal',
        'darwin-aarch64-app',
        'darwin-x86_64-app',
        'darwin-universal-app',
        'linux-x86_64',
        'linux-x86_64-appimage',
        'linux-x86_64-deb',
        'linux-x86_64-rpm',
        'windows-x86_64',
        'windows-x86_64-nsis',
        'windows-x86_64-msi',
        'windows-x86_64-inapp',
      ].join(',')
    : 'windows-x86_64,darwin-aarch64,darwin-x86_64,linux-x86_64'
const required = (process.env.REQUIRED_PLATFORMS ?? defaultRequired).split(',').filter(Boolean)
const missing = required.filter((k) => !platforms[k])
if (missing.length) throw new Error(`required platforms missing: ${missing.join(', ')}`)

const ordered = Object.fromEntries(Object.keys(platforms).sort().map((k) => [k, platforms[k]]))
writeFileSync(out, JSON.stringify({ version, notes, pub_date: new Date().toISOString(), platforms: ordered }, null, 2))
console.log(`wrote ${out} with ${Object.keys(ordered).length} platform entries`)
