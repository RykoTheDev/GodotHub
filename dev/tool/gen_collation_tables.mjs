import fs from 'node:fs'
const col = new Intl.Collator(undefined)
const base = new Intl.Collator(undefined, { sensitivity: 'base' })
const accent = new Intl.Collator(undefined, { sensitivity: 'accent' })
const ranges = [[0x09,0x0d],[0x20,0x7e],[0xa0,0x24f],[0x370,0x3ff],[0x400,0x4ff],[0x5d0,0x5ea],[0x620,0x64a],[0x660,0x669],[0xe01,0xe3a],[0xe40,0xe4e],[0x1e00,0x1eff],[0x2010,0x2027],[0x2030,0x205e],[0x20a0,0x20c0],[0x2100,0x22ff],[0x2460,0x24ff],[0x3000,0x303f],[0x3041,0x3096],[0x30a1,0x30fa],[0xfb00,0xfb06],[0xff01,0xff5e]]
const anchors = [[0x2300,0x23ff],[0x2500,0x257f],[0x2580,0x259f],[0x25a0,0x25ff],[0x2600,0x26ff],[0x2700,0x27bf],[0x2b00,0x2bff],[0xac00,0xd7a3]]
const expansions = { 'ß': 'ss', 'æ': 'ae', 'Æ': 'AE', 'œ': 'oe', 'Œ': 'OE', }
const marks = []
for (let cp = 0x300; cp <= 0x36f; cp++) {
  const m = String.fromCodePoint(cp)
  if (base.compare('a' + m, 'a') === 0 && col.compare('a' + m, 'a') !== 0) marks.push(m)
}
marks.sort((x, y) => col.compare('a' + x, 'a' + y))
const singles = []
const decomp = []
const ignorable = []
for (const [lo, hi] of ranges) for (let cp = lo; cp <= hi; cp++) {
  const s = String.fromCodePoint(cp)
  if (/\p{Cn}|\p{Cs}/u.test(s)) continue
  if (col.compare(s, '') === 0) { ignorable.push(cp); continue }
  if (expansions[s]) { decomp.push([cp, 2, ...[...expansions[s]].map(c => c.codePointAt(0))]); continue }
  const d = s.normalize('NFD')
  if (d !== s) {
    const parts = [...d]
    if (parts.slice(1).every(m => marks.includes(m)) && base.compare(s, parts[0]) === 0) {
      decomp.push([cp, 0, ...parts.map(c => c.codePointAt(0))]); continue
    }
  }
  const k = s.normalize('NFKD')
  if (k !== d && k.length > 0 && [...k].every(c => !marks.includes(c) || true) && base.compare(s, k) === 0) {
    decomp.push([cp, 1, ...[...k].map(c => c.codePointAt(0))]); continue
  }
  singles.push(s)
}
for (const [lo] of anchors) { let c = lo; while (/\p{Cn}/u.test(String.fromCodePoint(c))) c++; singles.push(String.fromCodePoint(c)) }
singles.sort(col.compare)
const seq = []
for (let i = 0; i < singles.length; i++) {
  if (i > 0) {
    const a = singles[i - 1], b = singles[i]
    const level = base.compare(a, b) !== 0 ? -1 : accent.compare(a, b) !== 0 ? -2 : col.compare(a, b) !== 0 ? -3 : -4
    seq.push(level)
  }
  seq.push(singles[i].codePointAt(0))
}
const variants = []
{
  let groupBase = null
  for (let i = 0; i < singles.length; i++) {
    const x = singles[i]
    if (i === 0 || base.compare(singles[i - 1], x) !== 0) { groupBase = x; continue }
    if (accent.compare(groupBase, x) === 0) continue
    let k = 0
    while (k < marks.length && accent.compare(groupBase + marks[k], x) < 0) k++
    variants.push([x.codePointAt(0), k * 2 + (k < marks.length && accent.compare(groupBase + marks[k], x) === 0 ? 1 : 0)])
  }
}
const decompFlat = decomp.flatMap(([cp, compat, ...rest]) => [cp, compat === 2 ? -(rest.length) - 100 : compat ? -(rest.length) : rest.length, ...rest])
const fmt = (arr) => { const out = []; for (let i = 0; i < arr.length; i += 24) out.push('  ' + arr.slice(i, i + 24).join(', ') + ','); return out.join('\n') }
fs.writeFileSync('tables.dart.txt', `const _collationOrder = <int>[\n${fmt(seq)}\n];\n\nconst _collationMarks = <int>[\n${fmt(marks.map(m => m.codePointAt(0)))}\n];\n\nconst _collationDecompositions = <int>[\n${fmt(decompFlat)}\n];\n\nconst _collationAnchors = <int>[
${fmt(anchors.flatMap(([lo, hi]) => { let c = lo; while (/\p{Cn}/u.test(String.fromCodePoint(c))) c++; return [lo, hi, c] }))}
];

const _collationVariants = <int>[\n${fmt(variants.flat())}\n];\n`)
console.log(singles.length, decomp.length, marks.length, ignorable.length)
const pool = ['a','A','á','Á','à','ä','b','B','e','é','ê','ế','ệ','o','ø','ő','ß','ss','SS','æ','ae','đ','d','ł','l','z','Z','ž','þ','ı','i','I','İ',' ','_','-','.',',','(',')','#','$','€','0','1','2','9','ω','Ω','я','Я','ё','е','й','и','あ','ア','日','中','가','한','ａ','１','ﬁ','́',' ','\t','★','→','…','–','"',"'",'/',String.fromCharCode(92),'@','x','X','y','м','א','ا','ก','ü','Ü','u','n','ñ','N','Ñ','ç','c','C']
let seed = 12345
const rnd = () => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 }
const corpus = new Set()
while (corpus.size < 600) {
  const len = 1 + Math.floor(rnd() * 4)
  let s = ''
  for (let i = 0; i < len; i++) s += pool[Math.floor(rnd() * pool.length)]
  corpus.add(s)
}
const words = ['My Game','my game','My-Game','my_game','Project 2','Project 10','project 1','Écran','ecran','Ecran','Zoo','zoo','Äpfel','apfel','Øresund','Oslo','Straße','Strasse','strasse','Ærø','Aero','Crème brûlée','creme brulee','Đà Nẵng','Da Nang','Tiếng Việt','Tieng Viet','Москва','москва','日本語','中文','한국어','ゲーム','げーむ','4.3-stable','4.3-beta1','4.3 mono','4.2.2-stable','4.10','3.x','v1','V1','v1.0','_private','-dash','.hidden','#tag','$money','(paren)','[bracket]','@at','~tilde','  spaces','tab\tname','',' ','a','A','asset_123','asset_45','asset-9']
for (const w of words) corpus.add(w)
const list = [...corpus]
const pairsOut = []
for (let i = 0; i < 4000; i++) {
  const a = list[Math.floor(rnd() * list.length)], b = list[Math.floor(rnd() * list.length)]
  pairsOut.push([a, b, Math.sign(col.compare(a, b))])
}
fs.writeFileSync('locale_compare.json', JSON.stringify({ icu: process.versions.icu, sorted: [...list].sort(col.compare), pairs: pairsOut }))
