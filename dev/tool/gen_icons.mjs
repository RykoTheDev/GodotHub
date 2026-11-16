import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import * as solid from '@fortawesome/free-solid-svg-icons'
import * as brands from '@fortawesome/free-brands-svg-icons'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const source = readFileSync(join(root, 'src/lib/icons.tsx'), 'utf8')

const aliases = new Map()
for (const block of source.matchAll(/import\s*\{([^}]*)\}\s*from\s*'@fortawesome\/(free-[a-z]+)-svg-icons'/g)) {
  const pack = block[2] === 'free-brands' ? brands : solid
  for (const raw of block[1].split(',')) {
    const part = raw.trim()
    if (!part) continue
    const [name, alias] = part.split(/\s+as\s+/)
    aliases.set(alias ?? name, pack[name])
  }
}

const lower = (s) => s.charAt(0).toLowerCase() + s.slice(1)
const lines = []
for (const m of source.matchAll(/export const Icon(\w+) = solid\((\w+)(?: as IconDefinition)?\)/g)) {
  const def = aliases.get(m[2])
  if (!def) throw new Error(`missing ${m[2]}`)
  const [width, height, , , path] = def.icon
  if (typeof path !== 'string') throw new Error(`multi-path ${m[2]}`)
  lines.push(`  static const ${lower(m[1])} = FaIconData('${def.prefix}', '${def.iconName}', ${width}, ${height}, '${path}');`)
}

const out = [
  "import 'fa_icon_data.dart';",
  '',
  'abstract final class GhIcons {',
  ...lines,
  '}',
  '',
].join('\n')
writeFileSync(join(root, 'app/lib/design/icons.g.dart'), out)
console.log(`${lines.length} icons`)
