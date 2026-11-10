import { readFileSync } from 'node:fs'

const tag = process.env.RELEASE_TAG
const repo = process.env.REPO
const changelogPath = process.env.CHANGELOG ?? 'app/changelog.json'
const allowMissing = process.env.ALLOW_MISSING_NOTES === 'true'
if (!tag || !repo) throw new Error('RELEASE_TAG and REPO are required')

const version = tag.replace(/^flutter-v/, '')
const slug = 'GodotHub-Beta'
const entries = JSON.parse(readFileSync(changelogPath, 'utf8'))
const tagOf = (e) => (e.version || '').trim().split(' ')[0]
const entry = entries.find((e) => tagOf(e) === tag)
if (!entry && !allowMissing) throw new Error(`no entry for ${tag} in ${changelogPath}`)

const blocks = []
blocks.push(`## What's new in ${tag}`)
if (entry) {
  const headers = { add: 'New', fix: 'Fixes', improve: 'Improvements' }
  for (const key of ['add', 'fix', 'improve']) {
    const items = (entry.notes || []).filter((n) => n.category === key).map((n) => n.text)
    if (items.length) blocks.push(`### ${headers[key]}\n\n` + items.map((t) => `- ${t}`).join('\n'))
  }
  const known = (entry.known_issues || []).filter(Boolean)
  if (known.length) blocks.push('### Known issues\n\n' + known.map((t) => `- ${t}`).join('\n'))
} else {
  blocks.push('- Test build without changelog notes.')
}
blocks.push('---')

const url = (name) => `https://github.com/${repo}/releases/download/${tag}/${encodeURIComponent(name)}`
const rows = [
  ['Windows', 'x64', 'Installer', `${slug}-${version}-windows-x64-setup.exe`],
  ['macOS', 'Apple Silicon and Intel', 'Disk image', `${slug}-${version}-darwin-universal.dmg`],
  ['macOS', 'Apple Silicon and Intel', 'App archive', `${slug}-${version}-darwin-universal.app.tar.gz`],
  ['Linux', 'x64', 'AppImage (zipped)', `${slug}-${version}-linux-amd64.AppImage.zip`],
]
blocks.push(
  '## Downloads\n\n' +
    '| Platform | Architecture | Package | Download |\n' +
    '| --- | --- | --- | --- |\n' +
    rows.map(([p, a, k, f]) => `| ${p} | ${a} | ${k} | [${f}](${url(f)}) |`).join('\n'),
)
blocks.push(
  'GodotHub Beta installs next to the stable GodotHub and works on a copy of its data, so your stable settings, workspaces and history stay untouched.',
)
blocks.push(
  '**Warning:** the beta still uses your real project folders and Godot installs. Anything it does to a project or a Godot version happens to the real files.',
)
blocks.push('On Linux, unzip the archive and run the AppImage inside it.')

console.log(blocks.join('\n\n'))
