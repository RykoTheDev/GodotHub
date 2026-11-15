import { readdirSync, readFileSync } from 'node:fs'

const [notesPath, assetsDir] = process.argv.slice(2)
const tag = process.env.RELEASE_TAG
const repo = process.env.REPO
if (!notesPath || !assetsDir || !tag || !repo) {
  console.error('usage: RELEASE_TAG=v1.6.0 REPO=owner/name node check_note_links.mjs <notes.md> <assets dir>')
  process.exit(64)
}

const notes = readFileSync(notesPath, 'utf8')
const assets = new Set(readdirSync(assetsDir))
const link = /https:\/\/github\.com\/([^/\s)]+\/[^/\s)]+)\/releases\/download\/([^/\s)]+)\/([^\s)]+)/g
const problems = []
let count = 0
for (const [, linkRepo, linkTag, file] of notes.matchAll(link)) {
  count++
  const name = decodeURIComponent(file)
  if (linkRepo.toLowerCase() !== repo.toLowerCase()) problems.push(`${name}: links to ${linkRepo}, not ${repo}`)
  if (linkTag !== tag) problems.push(`${name}: links to release ${linkTag}, not ${tag}`)
  if (!assets.has(name)) problems.push(`${name}: no such file is uploaded`)
}
if (!/^## Downloads$/m.test(notes)) problems.push('the notes have no "## Downloads" section')
if (count === 0) problems.push('the notes have no download links')
if (problems.length) {
  console.error(`Release notes download links do not match the uploaded files:\n  ${problems.join('\n  ')}`)
  process.exit(1)
}
console.log(`ok: ${count} download links match uploaded files`)
