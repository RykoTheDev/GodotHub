import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'

const runtime = /^(msvcp140.*|vcruntime140.*|concrt140|vccorlib140)\.dll$/i

function imports(file) {
  const b = readFileSync(file)
  const pe = b.readUInt32LE(0x3c)
  if (b.toString('latin1', pe, pe + 4) !== 'PE\0\0') throw new Error(`${file} is not a PE file`)
  const sections = b.readUInt16LE(pe + 6)
  const optSize = b.readUInt16LE(pe + 20)
  const opt = pe + 24
  const dirs = opt + (b.readUInt16LE(opt) === 0x20b ? 112 : 96)
  const secTable = opt + optSize
  const offset = (rva) => {
    for (let i = 0; i < sections; i++) {
      const s = secTable + i * 40
      const va = b.readUInt32LE(s + 12)
      const size = Math.max(b.readUInt32LE(s + 8), b.readUInt32LE(s + 16))
      if (rva >= va && rva < va + size) return rva - va + b.readUInt32LE(s + 20)
    }
    return -1
  }
  const names = []
  for (const [dir, stride, nameAt] of [[1, 20, 12], [13, 32, 4]]) {
    const start = b.readUInt32LE(dirs + dir * 8)
    if (!start) continue
    for (let p = offset(start); p > 0; p += stride) {
      const nameRva = b.readUInt32LE(p + nameAt)
      if (!nameRva) break
      const o = offset(nameRva)
      names.push(b.toString('latin1', o, b.indexOf(0, o)))
    }
  }
  return names
}

const files = process.argv.slice(2).flatMap((path) =>
  statSync(path).isDirectory()
    ? readdirSync(path).filter((f) => /\.(exe|dll)$/i.test(f)).map((f) => join(path, f))
    : [path],
)
if (files.length === 0) {
  console.error('usage: node check_runtime_imports.mjs <folder or binary>...')
  process.exit(64)
}
const problems = []
for (const file of files) {
  const name = file.split(/[\\/]/).pop()
  if (runtime.test(name)) problems.push(`${name} is a Visual C++ runtime DLL and should not be shipped`)
  const needs = imports(file).filter((n) => runtime.test(n))
  if (needs.length) problems.push(`${name} needs ${needs.join(', ')}`)
}
if (problems.length) {
  console.error(`The Windows build must not depend on the Visual C++ runtime DLLs:\n  ${problems.join('\n  ')}`)
  process.exit(1)
}
console.log(`ok: ${files.length} binaries need no Visual C++ runtime DLLs`)
