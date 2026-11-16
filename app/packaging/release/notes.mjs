import { readFileSync } from 'node:fs'

const tag = process.env.RELEASE_TAG
const repo = process.env.REPO
const stable = /^v\d/.test(tag ?? '')
const changelogPath = process.env.CHANGELOG ?? 'src-tauri/changelog.json'
const allowMissing = process.env.ALLOW_MISSING_NOTES === 'true'
const previous = process.env.PREVIOUS_TAG
if (!tag || !repo) throw new Error('RELEASE_TAG and REPO are required')

const firstFlutterStable = '1.6.0'
const lastTauri = 'v1.5.9'
const faqUrl = `https://github.com/${repo}/blob/main/docs/migration/FAQ.md`

const version = tag.replace(/^(flutter-)?v/, '')
const slug = stable ? 'GodotHub' : 'GodotHub-Beta'
const entries = JSON.parse(readFileSync(changelogPath, 'utf8'))
const tagOf = (e) => (e.version || '').trim().split(' ')[0]
const entry = entries.find((e) => tagOf(e) === tag)
if (!entry && !allowMissing) throw new Error(`no entry for ${tag} in ${changelogPath}`)

const blocks = []
blocks.push(`## What's new in ${tag}`)
if (stable && version === firstFlutterStable) {
  blocks.push(
    [
      '> [!IMPORTANT]',
      '> GodotHub has been rebuilt with Flutter. It looks and works the same, starts faster on Windows and uses less memory. Your projects, Godot versions, workspaces and settings carry over on their own.',
      '',
      '### What changes for you',
      '',
      '- **Windows:** updates now download and install inside the app, with no installer window. If a new version fails to start, GodotHub goes back to the previous one by itself.',
      '- **Windows:** the portable build is now a `.zip`. Unzip it anywhere and run `godothub.exe` inside. Everything it needs is in the folder, and neither WebView2 nor a Visual C++ install is needed.',
      '- **macOS:** GodotHub now needs macOS 12 Monterey or newer, so GodotHub 1.5 on a Mac does not update itself to this version. On macOS 12 or newer, download the disk image below once; later updates install from inside the app again. On macOS 10.15 or 11, keep using GodotHub 1.5.9.',
      '- **Linux:** the `.deb` and `.rpm` install the app into `/usr/lib/godothub` with `godothub` on your PATH, and no longer need WebKitGTK.',
      '',
      `Questions about the switch, rolling back or a failed update: see the [migration FAQ](${faqUrl}).`,
    ].join('\n'),
  )
}
if (entry) {
  const headers = { add: 'New', fix: 'Fixes', improve: 'Improvements' }
  for (const key of ['add', 'fix', 'improve']) {
    const items = (entry.notes || []).filter((n) => n.category === key).map((n) => n.text)
    if (items.length) blocks.push(`### ${headers[key]}\n\n` + items.map((t) => `- ${t}`).join('\n'))
  }
  const known = (entry.known_issues || []).filter(Boolean)
  if (known.length) blocks.push('### Known issues\n\n' + known.map((t) => `- ${t}`).join('\n'))
} else {
  blocks.push(stable ? '- No changelog notes for this release.' : '- Test build without changelog notes.')
}
blocks.push('---')

const url = (name) => `https://github.com/${repo}/releases/download/${tag}/${encodeURIComponent(name)}`
const rows = stable
  ? [
      ['Windows', 'x64', 'Installer (recommended)', `${slug}-${version}-windows-x64-setup.exe`],
      ['Windows', 'x64', 'MSI installer', `${slug}-${version}-windows-x64.msi`],
      ['Windows', 'x64', 'Portable, no install (.zip)', `${slug}-${version}-windows-x64-portable.zip`],
      ['macOS 12+', 'Apple Silicon and Intel', 'Disk image', `${slug}-${version}-darwin-universal.dmg`],
      ['Linux', 'x64', 'Debian, Ubuntu (.deb)', `${slug}-${version}-linux-amd64.deb`],
      ['Linux', 'x64', 'Fedora, openSUSE (.rpm)', `${slug}-${version}-linux-x86_64.rpm`],
      ['Linux', 'x64', 'AppImage', `${slug}-${version}-linux-amd64.AppImage`],
    ]
  : [
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
if (stable) {
  blocks.push(
    '**Package managers**\n\n' +
      '- winget: `winget install Ryko.GodotHub`\n' +
      '- Scoop: `scoop bucket add extras` then `scoop install godothub`\n' +
      '- AM (Linux): `am -i godothub`\n\n' +
      'Already using GodotHub? It offers this update in the app.',
  )
  blocks.push(
    '**AppImage not starting on Linux?**\n\n' +
      'The AppImage does not run on every Linux setup. If it fails to start, install it with ' +
      '[AM](https://github.com/ivan-hc/AM) instead. AM downloads the same AppImage from this page, ' +
      'adds GodotHub to your app menu, and updates it with `am -u godothub`.\n\n' +
      '1. Install AM:\n\n' +
      '```bash\n' +
      'wget -q https://raw.githubusercontent.com/ivan-hc/AM/main/AM-INSTALLER && chmod a+x ./AM-INSTALLER && ./AM-INSTALLER && rm ./AM-INSTALLER\n' +
      '```\n\n' +
      '2. Install GodotHub:\n\n' +
      '```bash\n' +
      'am -i godothub\n' +
      '```\n\n' +
      'If you chose AppMan in the AM installer, use `appman -i godothub` instead.',
  )
  blocks.push(
    '**Requirements:** Windows 10 or 11 (x64), macOS 12 or newer, or a 64-bit Linux desktop with GTK 3 and OpenGL ES. ' +
      `Need the last version for older systems? [GodotHub 1.5.9](https://github.com/${repo}/releases/tag/${lastTauri}) stays available.`,
  )
  if (previous) blocks.push(`**Full changelog:** [${previous}...${tag}](https://github.com/${repo}/compare/${previous}...${tag})`)
} else {
  blocks.push(
    'GodotHub Beta installs next to the stable GodotHub and works on a copy of its data, so your stable settings, workspaces and history stay untouched.',
  )
  blocks.push(
    '**Warning:** the beta still uses your real project folders and Godot installs. Anything it does to a project or a Godot version happens to the real files.',
  )
  blocks.push('On Linux, unzip the archive and run the AppImage inside it.')
}

console.log(blocks.join('\n\n'))
