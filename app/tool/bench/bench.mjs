import { spawn, execFileSync, spawnSync } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = path.dirname(fileURLToPath(import.meta.url))
const APP = path.resolve(HERE, '..', '..')
const LAB = process.env.GODOTHUB_BENCH_LAB || path.join(APP, 'build', 'bench_lab')
const PLATFORM = { win32: 'windows', linux: 'linux', darwin: 'macos' }[process.platform]
const RESULTS = path.join(LAB, 'results', PLATFORM)
const PROJECT_COUNT = 120
const SECRETS = new Set(['git-credentials', 'git_auth.json'])
const APP_NAMES = ['godothub', 'godothub-beta', 'GodotHub', 'GodotHub Beta']

if (!PLATFORM) throw new Error(`unsupported platform ${process.platform}`)

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const round = (v, d = 0) => Math.round(v * 10 ** d) / 10 ** d
const median = (a) => { if (!a.length) return null; const s = [...a].sort((x, y) => x - y); const m = s.length >> 1; return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2 }
const pct = (a, p) => { if (!a.length) return null; const s = [...a].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.ceil((p / 100) * s.length) - 1)] }
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a)
const readJson = (f) => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''))
const run = (cmd, args, opts = {}) => spawnSync(cmd, args, { encoding: 'utf8', ...opts })

function parseArgs(argv) {
  const opts = { _: [] }
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a.startsWith('--')) {
      const key = a.slice(2)
      const next = argv[i + 1]
      if (next !== undefined && !next.startsWith('--')) { opts[key] = next; i++ } else opts[key] = true
    } else opts._.push(a)
  }
  return opts
}

function save(name, data) {
  fs.mkdirSync(RESULTS, { recursive: true })
  const file = path.join(RESULTS, `${name}.json`)
  fs.writeFileSync(file, JSON.stringify({ savedAt: new Date().toISOString(), machine: machine(), ...data }, null, 2))
  log('saved', path.relative(process.cwd(), file))
}

function load(name) {
  const file = path.join(RESULTS, `${name}.json`)
  return fs.existsSync(file) ? readJson(file) : null
}

function tauriDataDir() {
  const home = os.homedir()
  if (PLATFORM === 'windows') return path.join(process.env.APPDATA, 'Ryko.GodotHub')
  if (PLATFORM === 'macos') return path.join(home, 'Library', 'Application Support', 'Ryko.GodotHub')
  return path.join(process.env.XDG_DATA_HOME || path.join(home, '.local', 'share'), 'Ryko.GodotHub')
}

function flutterExe() {
  if (PLATFORM === 'windows') return path.join(APP, 'build', 'windows', 'x64', 'runner', 'Release', 'godothub-beta.exe')
  if (PLATFORM === 'linux') return path.join(APP, 'build', 'linux', 'x64', 'release', 'bundle', 'godothub-beta')
  const products = path.join(APP, 'build', 'macos', 'Build', 'Products', 'Release')
  const bundle = fs.existsSync(products) ? fs.readdirSync(products).find((n) => n.endsWith('.app')) : null
  if (!bundle) return path.join(products, 'GodotHub Beta.app', 'Contents', 'MacOS', 'GodotHub Beta')
  const macosDir = path.join(products, bundle, 'Contents', 'MacOS')
  return path.join(macosDir, fs.readdirSync(macosDir)[0])
}

function tauriExe(opts) {
  if (opts.exe) return opts.exe
  if (process.env.GODOTHUB_TAURI_EXE) return process.env.GODOTHUB_TAURI_EXE
  if (PLATFORM === 'windows') return path.join(process.env.LOCALAPPDATA, 'GodotHub', 'godothub.exe')
  if (PLATFORM === 'macos') {
    const dir = '/Applications/GodotHub.app/Contents/MacOS'
    return fs.existsSync(dir) ? path.join(dir, fs.readdirSync(dir)[0]) : null
  }
  const which = run('which', ['godothub'])
  return which.status === 0 ? which.stdout.trim() : null
}

let machineCache
function machine() {
  if (machineCache) return machineCache
  const cpus = os.cpus()
  machineCache = { platform: PLATFORM, release: os.release(), cpu: cpus[0]?.model?.trim(), threads: cpus.length, memoryGB: round(os.totalmem() / 1073741824, 1), refreshHz: refreshHz(), gpu: gpu(), node: process.version }
  return machineCache
}

function refreshHz() {
  if (process.env.GODOTHUB_REFRESH_HZ) return Number(process.env.GODOTHUB_REFRESH_HZ)
  try {
    if (PLATFORM === 'windows') {
      const out = run('powershell', ['-NoProfile', '-Command', '(Get-CimInstance Win32_VideoController | Where-Object CurrentRefreshRate | Select-Object -First 1).CurrentRefreshRate']).stdout.trim()
      if (Number(out) > 0) return Number(out)
    } else if (PLATFORM === 'linux') {
      const out = run('xrandr', ['--current']).stdout || ''
      const m = out.match(/(\d+(?:\.\d+)?)\*/)
      if (m) return Number(m[1])
    } else {
      const out = run('system_profiler', ['SPDisplaysDataType']).stdout || ''
      const m = out.match(/@\s*(\d+(?:\.\d+)?)\s*Hz/i)
      if (m) return Number(m[1])
    }
  } catch {}
  return 60
}

function gpu() {
  try {
    if (PLATFORM === 'windows') return run('powershell', ['-NoProfile', '-Command', '(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name']).stdout.trim()
    if (PLATFORM === 'linux') return (run('sh', ['-c', 'lspci 2>/dev/null | grep -Ei "vga|3d" | head -n1 | cut -d: -f3']).stdout || '').trim() || null
    return ((run('system_profiler', ['SPDisplaysDataType']).stdout || '').match(/Chipset Model:\s*(.+)/) || [])[1] || null
  } catch {
    return null
  }
}

function runningApps() {
  if (PLATFORM === 'windows') {
    const out = run('powershell', ['-NoProfile', '-Command', `Get-Process ${APP_NAMES.map((n) => `'${n}'`).join(',')} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id; exit 0`]).stdout
    return out.split(/\s+/).filter(Boolean)
  }
  const out = run('ps', ['-A', '-o', 'pid=,comm=']).stdout || ''
  return out.split('\n').map((l) => l.trim()).filter((l) => APP_NAMES.some((n) => l.endsWith(`/${n}`) || l.endsWith(` ${n}`))).map((l) => l.split(/\s+/)[0])
}

function assertNotRunning() {
  const pids = runningApps()
  if (pids.length) throw new Error(`GodotHub is running (pids ${pids.join(', ')}); close every GodotHub window first`)
}

function copyProfile(from, to) {
  fs.rmSync(to, { recursive: true, force: true })
  fs.cpSync(from, to, { recursive: true, filter: (src) => !SECRETS.has(path.basename(src)) && !src.includes(`${path.sep}EBWebView`) })
}

function syntheticProfile(dir) {
  const id = '00000000-0000-4000-8000-000000000001'
  fs.mkdirSync(path.join(dir, 'workspaces', id), { recursive: true })
  const now = new Date().toISOString()
  const ws = { id, name: 'Bench', icon: 'briefcase', color: '#478cbf', created_at: now }
  fs.writeFileSync(path.join(dir, 'workspaces.json'), JSON.stringify({ workspaces: [ws], active_id: id }, null, 2))
  fs.writeFileSync(path.join(dir, 'workspaces', id, 'workspace.json'), JSON.stringify(ws, null, 2))
  fs.writeFileSync(path.join(dir, 'workspaces', id, 'projects.json'), JSON.stringify({ schema_version: 1, projects: [] }, null, 2))
  fs.writeFileSync(path.join(dir, 'workspaces', id, 'settings.json'), JSON.stringify({ setup_complete: true }, null, 2))
}

function ensureListLayout(dir) {
  const file = path.join(dir, 'ui_prefs.json')
  const prefs = fs.existsSync(file) ? readJson(file) : { schema_version: 1, migrated_from_local_storage: true, values: {} }
  prefs.values = prefs.values || {}
  prefs.values.godothub_projects_view_mode = 'list'
  fs.writeFileSync(file, JSON.stringify(prefs, null, 2))
}

function rng(seed) { let s = seed >>> 0; return () => { s = (s + 0x6d2b79f5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296 } }
function uuid(r) { const h = [...Array(32)].map(() => Math.floor(r() * 16).toString(16)); h[12] = '4'; h[16] = ((parseInt(h[16], 16) & 3) | 8).toString(16); const s = h.join(''); return `${s.slice(0, 8)}-${s.slice(8, 12)}-${s.slice(12, 16)}-${s.slice(16, 20)}-${s.slice(20)}` }

function generateBench(profile, projectsDir) {
  const r = rng(20261107)
  const icon = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" rx="24" fill="#478cbf"/><circle cx="44" cy="60" r="14" fill="#fff"/><circle cx="84" cy="60" r="14" fill="#fff"/><rect x="34" y="88" width="60" height="10" rx="5" fill="#fff"/></svg>'
  const tagsPool = ['2d', '3d', 'jam', 'prototype', 'tool', 'mobile', 'web', 'multiplayer']
  const words = ['Crystal', 'Shadow', 'Pixel', 'Rogue', 'Sky', 'Iron', 'Neon', 'Forest', 'Echo', 'Star', 'Dungeon', 'Ocean', 'Ember', 'Frost', 'Void']
  const kinds = ['Quest', 'Runner', 'Tactics', 'Defense', 'Saga', 'Arena', 'Drift', 'Tycoon', 'Legends', 'Escape']
  const ws = readJson(path.join(profile, 'workspaces.json'))
  const activeId = ws.active_id ?? ws.activeId
  const projectsFile = path.join(profile, 'workspaces', activeId, 'projects.json')
  const existing = fs.existsSync(projectsFile) ? readJson(projectsFile).projects ?? [] : []
  const godotVersion = existing.find((p) => p.godot_version)?.godot_version ?? ''
  const base = Date.UTC(2026, 9, 1)
  const projects = []
  fs.rmSync(projectsDir, { recursive: true, force: true })
  for (let i = 0; i < PROJECT_COUNT; i++) {
    const name = `${words[Math.floor(r() * words.length)]} ${kinds[Math.floor(r() * kinds.length)]} ${String(i + 1).padStart(3, '0')}`
    const dir = path.join(projectsDir, `bench-${String(i + 1).padStart(3, '0')}`)
    fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(path.join(dir, 'project.godot'), `config_version=5\n\n[application]\n\nconfig/name="${name}"\nconfig/features=PackedStringArray("4.4", "Forward Plus")\nconfig/icon="res://icon.svg"\n`)
    fs.writeFileSync(path.join(dir, 'icon.svg'), icon)
    const tags = tagsPool.filter(() => r() < 0.2)
    const created = new Date(base - Math.floor(r() * 300) * 86400000).toISOString()
    projects.push({ id: uuid(r), name, path: dir, godot_version: godotVersion, created_at: created, last_opened: r() < 0.8 ? new Date(base + Math.floor(r() * 30 * 86400) * 1000).toISOString() : null, category: null, pinned: i < 3, sort_order: i, launch_arguments: '', tags, total_time_seconds: Math.floor(r() * 200 * 3600), session_started_at_ms: null, time_today_seconds: 0, time_week_seconds: 0 })
  }
  fs.mkdirSync(path.dirname(projectsFile), { recursive: true })
  fs.writeFileSync(projectsFile, JSON.stringify({ schema_version: 1, projects }, null, 2))
  fs.rmSync(projectsFile + '.bak', { force: true })
}

function setup(opts) {
  const source = opts.from || tauriDataDir()
  fs.mkdirSync(LAB, { recursive: true })
  const real = path.join(LAB, 'real')
  const bench = path.join(LAB, 'bench')
  if (fs.existsSync(path.join(source, 'workspaces.json'))) {
    copyProfile(source, real)
    ensureListLayout(real)
    copyProfile(real, bench)
    log(`real data copied from ${source} (credentials left out)`)
  } else {
    fs.rmSync(real, { recursive: true, force: true })
    fs.rmSync(bench, { recursive: true, force: true })
    syntheticProfile(bench)
    log(`no GodotHub data at ${source}; only the generated bench data set will be used`)
  }
  ensureListLayout(bench)
  generateBench(bench, path.join(LAB, 'bench-projects'))
  log(`bench data set: ${PROJECT_COUNT} projects in ${path.join(LAB, 'bench-projects')}`)
}

function build(opts) {
  const target = { windows: 'windows', linux: 'linux', macos: 'macos' }[PLATFORM]
  const args = ['build', target, '--release', '--dart-define=GODOTHUB_BENCH=true', `--dart-define=CHANNEL=${opts.channel || 'beta'}`, '--dart-define=APP_VERSION=0.0.0-bench', '--build-name=0.0.0']
  log('flutter', args.join(' '))
  const r = spawnSync('flutter', args, { cwd: APP, stdio: 'inherit', shell: PLATFORM === 'windows' })
  if (r.status !== 0) throw new Error('flutter build failed')
}

function datasets(opts) {
  const all = ['real', 'bench'].filter((d) => fs.existsSync(path.join(LAB, d)))
  if (!all.length) throw new Error(`no data sets in ${LAB}; run "setup" first`)
  return opts.data ? all.filter((d) => d === opts.data) : all
}

function freshData(label) {
  const dir = path.join(LAB, 'work', label)
  fs.rmSync(dir, { recursive: true, force: true })
  fs.cpSync(path.join(LAB, label), dir, { recursive: true })
  return dir
}

function launchFlutter(label, task) {
  const exe = flutterExe()
  if (!fs.existsSync(exe)) throw new Error(`benchmark build not found at ${exe}; run "build" first`)
  const data = freshData(label)
  const out = path.join(LAB, 'work', `${label}-${task}.json`)
  fs.rmSync(out, { force: true })
  const t0 = Date.now()
  const child = spawn(exe, [], { env: { ...process.env, GODOTHUB_BENCH_DATA: data, GODOTHUB_BENCH_TASK: task, GODOTHUB_BENCH_OUT: out }, stdio: 'ignore' })
  return { child, t0, out }
}

async function waitResult(run, timeoutMs) {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    if (fs.existsSync(run.out)) {
      await sleep(200)
      try { return readJson(run.out) } catch {}
    }
    if (run.child.exitCode !== null && !fs.existsSync(run.out)) throw new Error(`app exited with code ${run.child.exitCode} before writing a result`)
    await sleep(100)
  }
  run.child.kill()
  throw new Error(`no result after ${timeoutMs} ms`)
}

async function waitExit(child, ms = 10000) {
  const start = Date.now()
  while (child.exitCode === null && Date.now() - start < ms) await sleep(100)
  if (child.exitCode === null) child.kill()
  await sleep(1500)
}

function summarize(results, keys) {
  const s = {}
  for (const k of keys) {
    const v = results.map((r) => r[k]).filter((x) => typeof x === 'number')
    s[k] = { median: median(v), min: Math.min(...v), max: Math.max(...v) }
  }
  return s
}

function frameStats(deltas, refreshMs) {
  if (!deltas.length) return { frames: 0 }
  const sum = deltas.reduce((a, b) => a + b, 0)
  return { frames: deltas.length, avgFps: round(1000 / (sum / deltas.length)), medianMs: round(median(deltas), 2), p95Ms: round(pct(deltas, 95), 2), p99Ms: round(pct(deltas, 99), 2), maxMs: round(Math.max(...deltas), 2), over1_5xRefresh: deltas.filter((d) => d > refreshMs * 1.5).length, over50ms: deltas.filter((d) => d > 50).length }
}

function workStats(d, refreshMs) {
  const t = d.totalMs || []
  return { ...frameStats(d.vsyncDeltasMs || [], refreshMs), workMedianMs: round(median(t), 2), workP99Ms: round(pct(t, 99), 2), workMaxMs: t.length ? round(Math.max(...t), 2) : null, workOverBudget: t.filter((x) => x > refreshMs).length }
}

async function flutterColdstart(label, runs) {
  const results = []
  for (let i = 0; i < runs; i++) {
    assertNotRunning()
    const r0 = launchFlutter(label, 'coldstart')
    const r = await waitResult(r0, 60000)
    const ms = (us) => round(us / 1000 - r0.t0)
    const m = { mainStartMs: ms(r.mainStartUs), firstFrameMs: ms(r.firstFrameUs), readyMs: ms(r.readyUs), interactiveMs: ms(r.interactiveUs), cards: r.cards }
    log(`coldstart ${label} #${i + 1}`, m)
    results.push(m)
    await waitExit(r0.child)
    await sleep(8000)
  }
  save(`flutter-coldstart-${label}`, { label, results, summary: summarize(results, ['mainStartMs', 'firstFrameMs', 'readyMs', 'interactiveMs']) })
}

function processTree(rootPid) {
  if (PLATFORM === 'windows') {
    const json = run('powershell', ['-NoProfile', '-Command', `
      $p = Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId, Name, WorkingSetSize, PrivatePageCount
      $f = Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | Select-Object IDProcess, WorkingSetPrivate
      @{ p = $p; f = $f } | ConvertTo-Json -Depth 3 -Compress`]).stdout
    const { p, f } = JSON.parse(json)
    const priv = new Map(f.map((x) => [x.IDProcess, Number(x.WorkingSetPrivate)]))
    const tree = []
    const add = (pid) => { const proc = p.find((x) => x.ProcessId === pid); if (!proc) return; tree.push({ pid, name: proc.Name, privateMB: (priv.get(pid) || 0) / 1048576, rssMB: proc.WorkingSetSize / 1048576 }); for (const c of p.filter((x) => x.ParentProcessId === pid)) add(c.ProcessId) }
    add(rootPid)
    return tree
  }
  const table = (run('ps', ['-A', '-o', 'pid=,ppid=,rss=,comm=']).stdout || '').split('\n').map((l) => l.trim().split(/\s+/)).filter((x) => x.length >= 4).map(([pid, ppid, rss, ...comm]) => ({ pid: Number(pid), ppid: Number(ppid), rss: Number(rss), name: comm.join(' ') }))
  const tree = []
  const add = (pid) => {
    const proc = table.find((x) => x.pid === pid)
    if (!proc) return
    let privateMB = null
    if (PLATFORM === 'linux') {
      try {
        const roll = fs.readFileSync(`/proc/${pid}/smaps_rollup`, 'utf8')
        const kb = (k) => Number((roll.match(new RegExp(`^${k}:\\s+(\\d+)`, 'm')) || [])[1] || 0)
        privateMB = (kb('Private_Clean') + kb('Private_Dirty')) / 1024
      } catch {}
    } else {
      const fp = run('footprint', ['-p', String(pid)]).stdout || ''
      const m = fp.match(/Footprint:\s*([\d.]+)\s*(KB|MB|GB)/i)
      if (m) privateMB = Number(m[1]) * { KB: 1 / 1024, MB: 1, GB: 1024 }[m[2].toUpperCase()]
    }
    tree.push({ pid, name: proc.name, privateMB, rssMB: proc.rss / 1024 })
    for (const c of table.filter((x) => x.ppid === pid)) add(c.pid)
  }
  add(rootPid)
  return tree
}

function memorySample(rootPid) {
  const tree = processTree(rootPid)
  const sum = (k) => round(tree.reduce((a, x) => a + (x[k] || 0), 0), 1)
  return { privateMB: tree.every((x) => x.privateMB === null) ? null : sum('privateMB'), rssMB: sum('rssMB'), processes: tree.length, tree: tree.map((x) => ({ ...x, privateMB: x.privateMB === null ? null : round(x.privateMB, 1), rssMB: round(x.rssMB, 1) })) }
}

async function flutterMemory(label, runs) {
  const results = []
  for (let i = 0; i < runs; i++) {
    assertNotRunning()
    const r0 = launchFlutter(label, 'idle')
    await sleep(30000)
    const m = memorySample(r0.child.pid)
    log(`memory ${label} #${i + 1}`, { privateMB: m.privateMB, rssMB: m.rssMB, processes: m.processes })
    results.push(m)
    r0.child.kill()
    await waitExit(r0.child)
    await sleep(3000)
  }
  save(`flutter-memory-${label}`, { label, results, summary: summarize(results, ['privateMB', 'rssMB', 'processes']) })
}

async function flutterInteraction(label, task, timeoutMs) {
  assertNotRunning()
  const r0 = launchFlutter(label, task)
  const r = await waitResult(r0, timeoutMs)
  await waitExit(r0.child)
  return r
}

async function flutterViews(label) {
  const r = await flutterInteraction(label, 'views', 180000)
  const summary = {}
  for (const v of ['versions', 'settings', 'projects']) {
    const w = r.views.warm.filter((x) => x.view === v)
    const f = r.views.first.find((x) => x.view === v)
    summary[v] = { firstContentMs: round(f.contentMs), firstSettledMs: round(f.settledMs), warmContentMs: round(median(w.map((x) => x.contentMs))), warmSettledMs: round(median(w.map((x) => x.settledMs))) }
  }
  log(`views ${label}`, summary)
  save(`flutter-views-${label}`, { label, ...r.views, summary })
}

async function flutterScroll(label) {
  const refreshMs = 1000 / machine().refreshHz
  const r = await flutterInteraction(label, 'scroll', 240000)
  const runs = r.scroll.map((x) => ({ direction: x.direction, ...workStats(x, refreshMs) }))
  for (const x of runs) log(`scroll ${label} ${x.direction}`, x)
  save(`flutter-scroll-${label}`, { label, refreshMs: round(refreshMs, 2), runs })
}

async function flutterDrag(label) {
  const refreshMs = 1000 / machine().refreshHz
  const r = await flutterInteraction(label, 'drag', 240000)
  const runs = r.drag.map((x) => workStats(x, refreshMs))
  for (const x of runs) log(`drag ${label}`, x)
  save(`flutter-drag-${label}`, { label, refreshMs: round(refreshMs, 2), runs })
}

const FLUTTER_TASKS = ['coldstart', 'memory', 'views', 'scroll', 'drag']

async function flutter(opts) {
  const tasks = opts._.length ? opts._ : FLUTTER_TASKS
  const runs = Number(opts.runs || 5)
  for (const label of datasets(opts)) {
    for (const t of tasks) {
      if (t === 'coldstart') await flutterColdstart(label, runs)
      else if (t === 'memory') await flutterMemory(label, Math.min(runs, 3))
      else if (t === 'views') await flutterViews(label)
      else if ((t === 'scroll' || t === 'drag') && label !== 'bench') continue
      else if (t === 'scroll') await flutterScroll(label)
      else if (t === 'drag') await flutterDrag(label)
      else throw new Error(`unknown task ${t}`)
    }
  }
}

function windowVisible(pid) {
  if (PLATFORM === 'windows') {
    const out = run('powershell', ['-NoProfile', '-Command', `$ids = @(${pid}) + @(Get-CimInstance Win32_Process -Filter "ParentProcessId=${pid}" | Select-Object -ExpandProperty ProcessId); @(Get-Process -Id $ids -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle }).Count; exit 0`]).stdout.trim()
    return Number(out) > 0
  }
  if (PLATFORM === 'macos') {
    const out = run('osascript', ['-e', `tell application "System Events" to count windows of (first process whose unix id is ${pid})`]).stdout.trim()
    return Number(out) > 0
  }
  const x = run('xdotool', ['search', '--onlyvisible', '--pid', String(pid)])
  if (x.status === 0 && x.stdout.trim()) return true
  const w = run('wmctrl', ['-lp'])
  return w.status === 0 && w.stdout.split('\n').some((l) => l.split(/\s+/)[2] === String(pid))
}

function checkWindowTool() {
  if (PLATFORM !== 'linux') return
  const ok = run('sh', ['-c', 'command -v xdotool || command -v wmctrl']).status === 0
  if (!ok) throw new Error('install xdotool or wmctrl (X11 session) to time the first window on Linux')
}

async function timeToWindow(exe, args, env, timeoutMs = 60000) {
  const t0 = Date.now()
  const child = spawn(exe, args, { env, stdio: 'ignore' })
  while (Date.now() - t0 < timeoutMs) {
    if (child.exitCode !== null) throw new Error(`${exe} exited with ${child.exitCode}`)
    if (windowVisible(child.pid)) return { child, windowMs: Date.now() - t0 }
    await sleep(15)
  }
  child.kill()
  throw new Error('no window after 60 s')
}

async function closeChild(child) {
  if (PLATFORM === 'windows') run('taskkill', ['/PID', String(child.pid), '/T'])
  else child.kill('SIGTERM')
  await waitExit(child)
}

async function tauri(opts) {
  checkWindowTool()
  const exe = tauriExe(opts)
  if (!exe || !fs.existsSync(exe)) throw new Error('Tauri GodotHub not found; pass --exe <path to the Tauri executable or AppImage>')
  log(`Tauri app: ${exe} (runs on its own data folder, ${tauriDataDir()})`)
  const runs = Number(opts.runs || 5)
  const cold = []
  for (let i = 0; i < runs; i++) {
    assertNotRunning()
    const { child, windowMs } = await timeToWindow(exe, [], process.env)
    log(`tauri first window #${i + 1}`, windowMs, 'ms')
    cold.push({ windowMs })
    await closeChild(child)
    await sleep(8000)
  }
  const memory = []
  for (let i = 0; i < Math.min(runs, 3); i++) {
    assertNotRunning()
    const child = spawn(exe, [], { stdio: 'ignore' })
    await sleep(30000)
    const m = memorySample(child.pid)
    log(`tauri memory #${i + 1}`, { privateMB: m.privateMB, rssMB: m.rssMB, processes: m.processes })
    memory.push(m)
    await closeChild(child)
    await sleep(3000)
  }
  save('tauri', { exe, cold, coldSummary: summarize(cold, ['windowMs']), memory, memorySummary: summarize(memory, ['privateMB', 'rssMB', 'processes']) })

  const fl = []
  for (let i = 0; i < runs; i++) {
    assertNotRunning()
    const data = freshData(datasets(opts).includes('real') ? 'real' : 'bench')
    const out = path.join(LAB, 'work', 'window.json')
    const { child, windowMs } = await timeToWindow(flutterExe(), [], { ...process.env, GODOTHUB_BENCH_DATA: data, GODOTHUB_BENCH_TASK: 'idle', GODOTHUB_BENCH_OUT: out })
    log(`flutter first window #${i + 1}`, windowMs, 'ms')
    fl.push({ windowMs })
    child.kill()
    await waitExit(child)
    await sleep(8000)
  }
  save('flutter-window', { cold: fl, coldSummary: summarize(fl, ['windowMs']) })
}

function cell(v, unit = '') { return v === null || v === undefined || Number.isNaN(v) ? 'n/a' : `${round(v, 1)}${unit}` }

function report() {
  const m = machine()
  const lines = [`# GodotHub benchmark (${PLATFORM})`, '', `Generated ${new Date().toISOString()} by app/tool/bench/bench.mjs.`, '', '## Machine', '', '| | |', '|---|---|', `| OS | ${PLATFORM} ${m.release} |`, `| CPU | ${m.cpu} (${m.threads} threads) |`, `| GPU | ${m.gpu ?? 'unknown'} |`, `| RAM | ${m.memoryGB} GB |`, `| Display | ${m.refreshHz} Hz |`, '']
  const t = load('tauri')
  const fw = load('flutter-window')
  if (t || fw) {
    lines.push('## Flutter vs Tauri (same method for both)', '', 'First window: process spawn to the first visible window (median of runs). Memory: process tree after 30 s idle (median). Tauri runs on its own data folder, Flutter on a copy of it.', '', '| Metric | Tauri | Flutter |', '|---|---|---|')
    lines.push(`| First window | ${cell(t?.coldSummary?.windowMs?.median, ' ms')} | ${cell(fw?.coldSummary?.windowMs?.median, ' ms')} |`)
    const fm = load('flutter-memory-real') || load('flutter-memory-bench')
    lines.push(`| Private memory | ${cell(t?.memorySummary?.privateMB?.median, ' MB')} | ${cell(fm?.summary?.privateMB?.median, ' MB')} |`)
    lines.push(`| Resident memory (RSS) | ${cell(t?.memorySummary?.rssMB?.median, ' MB')} | ${cell(fm?.summary?.rssMB?.median, ' MB')} |`)
    lines.push(`| Processes | ${cell(t?.memorySummary?.processes?.median)} | ${cell(fm?.summary?.processes?.median)} |`, '')
  }
  lines.push('## Flutter details', '')
  for (const label of ['real', 'bench']) {
    const c = load(`flutter-coldstart-${label}`)
    const mem = load(`flutter-memory-${label}`)
    const v = load(`flutter-views-${label}`)
    if (!c && !mem && !v) continue
    lines.push(`### ${label === 'real' ? 'Real data' : `Bench data (${PROJECT_COUNT} projects)`}`, '', '| Metric | Median | Range |', '|---|---|---|')
    if (c) for (const [k, name] of [['firstFrameMs', 'First frame'], ['readyMs', 'Ready (projects shown)'], ['interactiveMs', 'Interactive']]) lines.push(`| ${name} | ${c.summary[k].median} ms | ${c.summary[k].min} to ${c.summary[k].max} ms |`)
    if (mem) lines.push(`| Private memory | ${cell(mem.summary.privateMB.median, ' MB')} | ${cell(mem.summary.privateMB.min)} to ${cell(mem.summary.privateMB.max, ' MB')} |`, `| Resident memory | ${mem.summary.rssMB.median} MB | ${mem.summary.rssMB.min} to ${mem.summary.rssMB.max} MB |`)
    if (v) for (const view of ['versions', 'settings', 'projects']) { const s = v.summary[view]; lines.push(`| ${view}: first open content / settled | ${s.firstContentMs} / ${s.firstSettledMs} ms | later switches ${s.warmContentMs} / ${s.warmSettledMs} ms |`) }
    lines.push('')
  }
  for (const kind of ['scroll', 'drag']) {
    const s = load(`flutter-${kind}-bench`)
    if (!s) continue
    lines.push(`### ${kind === 'scroll' ? 'Scrolling' : 'Drag reorder'} (bench data)`, '', '| Pass | avg fps | median | p95 | p99 | worst | frames > 1.5x refresh | work median | work p99 |', '|---|---|---|---|---|---|---|---|---|')
    s.runs.forEach((x, i) => lines.push(`| ${x.direction ? `${x.direction} ${Math.floor(i / 2) + 1}` : i + 1} | ${cell(x.avgFps)} | ${cell(x.medianMs, ' ms')} | ${cell(x.p95Ms, ' ms')} | ${cell(x.p99Ms, ' ms')} | ${cell(x.maxMs, ' ms')} | ${x.over1_5xRefresh ?? 'n/a'} of ${x.frames} | ${cell(x.workMedianMs, ' ms')} | ${cell(x.workP99Ms, ' ms')} |`))
    lines.push('')
  }
  const file = path.join(RESULTS, 'REPORT.md')
  fs.mkdirSync(RESULTS, { recursive: true })
  fs.writeFileSync(file, lines.join('\n'))
  log('report written to', file)
}

const USAGE = `GodotHub benchmark (Windows, Linux, macOS)

  node tool/bench/bench.mjs all                 setup + build + flutter + tauri (if installed) + report
  node tool/bench/bench.mjs setup [--from DIR]  copy GodotHub data (no credentials) and generate the ${PROJECT_COUNT}-project bench set
  node tool/bench/bench.mjs build               build the Flutter benchmark binary for this OS
  node tool/bench/bench.mjs flutter [tasks]     tasks: ${FLUTTER_TASKS.join(' ')} (default all) [--data real|bench] [--runs N]
  node tool/bench/bench.mjs tauri [--exe PATH]  first window and memory of the installed Tauri app, plus Flutter first window
  node tool/bench/bench.mjs report              write results/<os>/REPORT.md

Results go to ${path.relative(process.cwd(), RESULTS) || RESULTS}. Close every GodotHub window before running.`

const opts = parseArgs(process.argv.slice(2))
const cmd = opts._.shift()
try {
  if (cmd === 'setup') setup(opts)
  else if (cmd === 'build') build(opts)
  else if (cmd === 'flutter') await flutter(opts)
  else if (cmd === 'tauri') await tauri(opts)
  else if (cmd === 'report') report()
  else if (cmd === 'all') {
    if (!fs.existsSync(path.join(LAB, 'bench'))) setup(opts)
    if (!opts['skip-build']) build(opts)
    await flutter({ ...opts, _: [] })
    if (tauriExe(opts) && fs.existsSync(tauriExe(opts))) await tauri(opts)
    else log('Tauri GodotHub not found, skipping the comparison (pass --exe to include it)')
    report()
  } else {
    console.log(USAGE)
    process.exit(cmd ? 1 : 0)
  }
} catch (e) {
  console.error(`error: ${e.message}`)
  process.exit(1)
}
