import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import gsap from 'gsap'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')

const eases = [
  'expo.out', 'expo.in', 'expo.inOut',
  'power1.out', 'power2.in', 'power2.out', 'power2.inOut', 'power3.in', 'power3.out', 'power3.inOut', 'power4.out',
  'back.out(1.8)', 'back.out(2.6)', 'back.out(1.5)', 'back.in(1.7)', 'back.inOut(1.7)',
  'elastic.out(1.1, 0.4)', 'elastic.out(1.15, 0.32)', 'elastic.out(1, 0.5)', 'elastic.out', 'elastic.in(1, 0.3)', 'elastic.inOut(1, 0.45)', 'elastic.out(0.6, 0.3)',
  'sine.inOut', 'circ.out', 'none',
]

const samples = Array.from({ length: 201 }, (_, i) => i / 200)
const out: Record<string, number[]> = {}
for (const name of eases) {
  const fn = gsap.parseEase(name)
  out[name] = samples.map((p) => fn(p))
}

writeFileSync(join(root, 'app/test/fixtures/gsap_eases.json'), JSON.stringify({ samples, eases: out }) + '\n')
console.log(`${Object.keys(out).length} eases x ${samples.length} samples`)
