import { mockIPC } from '@tauri-apps/api/mocks'
import { DEFAULTS } from '../hooks/useSettings'
import type { InstalledGodotVersion, Project } from '../types'

const now = Date.now()
const hoursAgo = (h: number) => new Date(now - h * 3600_000).toISOString()

const SETTINGS = {
  ...DEFAULTS,
  setup_complete: typeof window === 'undefined' || !new URLSearchParams(window.location.search).has('onboarding'),
  customize_view_enabled: true,
  categories_enabled: true,
  workspaces_enabled: true,
  auto_scan_on_startup: false,
  default_landing_tab: 'dashboard',
  project_todos_enabled: true,
}

const pad2 = (n: number) => String(n).padStart(2, '0')
const fmtDay = (d: Date) =>
  `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`

function activitySeries(range: string): [string, number][] {
  const base = new Date()
  const out: [string, number][] = []
  if (range === 'daily') {
    for (let h = 0; h < 24; h++) {
      const load = h >= 9 && h <= 23 ? Math.sin(h / 2) * 0.5 + 0.6 : 0
      out.push([`${fmtDay(base)}T${pad2(h)}:00:00`, Math.max(0, Math.round(load * 3600))])
    }
  } else if (range === 'monthly') {
    for (let i = 29; i >= 0; i--) {
      const d = new Date(base)
      d.setDate(base.getDate() - i)
      out.push([fmtDay(d), Math.max(0, Math.round((Math.cos(i / 3) * 0.5 + 0.6) * 3 * 3600))])
    }
  } else if (range === 'yearly') {
    for (let i = 11; i >= 0; i--) {
      const d = new Date(base.getFullYear(), base.getMonth() - i, 1)
      out.push([`${d.getFullYear()}-${pad2(d.getMonth() + 1)}`, Math.round((Math.sin(i / 2) * 0.5 + 0.7) * 48 * 3600)])
    }
  } else {
    for (let i = 6; i >= 0; i--) {
      const d = new Date(base)
      d.setDate(base.getDate() - i)
      out.push([fmtDay(d), Math.round((Math.sin(i) * 0.4 + 0.7) * 4 * 3600)])
    }
  }
  return out
}

const TIME_INSIGHTS = {
  total_seconds: 227 * 3600,
  longest_streak_days: 18,
  current_streak_days: 4,
  most_productive_weekday: 2,
  this_month_seconds: 41 * 3600,
  last_month_seconds: 33 * 3600,
}

const ICON_PALETTE = ['#4f7cff', '#2fbf71', '#f0b132', '#a78bfa', '#f2555a', '#38bdf8']
function mockIcon(seed: string): string {
  let h = 0
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0
  const color = ICON_PALETTE[h % ICON_PALETTE.length]
  const svg =
    `<svg xmlns='http://www.w3.org/2000/svg' width='128' height='128'>` +
    `<defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'>` +
    `<stop offset='0' stop-color='${color}'/><stop offset='1' stop-color='#17181c'/>` +
    `</linearGradient></defs>` +
    `<rect width='128' height='128' rx='30' fill='url(#g)'/>` +
    `<circle cx='64' cy='64' r='27' fill='none' stroke='#f4f5f7' stroke-width='9'/>` +
    `<circle cx='64' cy='64' r='7' fill='#f4f5f7'/></svg>`
  return `data:image/svg+xml,${encodeURIComponent(svg)}`
}

const RUNNING = [
  {
    id: 'dev-1',
    name: 'Barely a Driver',
    version: '4.8',
    launched_at_ms: now - 23 * 60_000,
    console: false,
  },
]

const todoDate = (offset: number) => {
  const d = new Date()
  d.setDate(d.getDate() + offset)
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`
}

const OPEN_TODOS = [
  {
    projectId: 'dev-1',
    projectName: 'Barely a Driver',
    todo: {
      id: 't1',
      title: 'Fix multiplayer desync on late join',
      status: 'todo',
      area: 'programming',
      dueDate: todoDate(-1),
      createdAt: hoursAgo(200),
      priority: 'high',
    },
  },
  {
    projectId: 'dev-2',
    projectName: 'TVP-2.0',
    todo: {
      id: 't2',
      title: 'Polish arena lighting pass',
      status: 'todo',
      area: 'art',
      dueDate: todoDate(0),
      createdAt: hoursAgo(100),
      priority: 'medium',
    },
  },
  {
    projectId: 'dev-1',
    projectName: 'Barely a Driver',
    todo: {
      id: 't3',
      title: 'Record engine SFX variations',
      status: 'todo',
      area: 'audio',
      dueDate: todoDate(3),
      createdAt: hoursAgo(50),
      priority: 'low',
    },
  },
]

const VERSIONS: InstalledGodotVersion[] = [
  {
    tag: '4.8-beta1',
    version: '4.8',
    executable_path: '/dev/godot-4.8',
    is_mono: false,
    installed_at: hoursAgo(72),
    supports_console: true,
  },
  {
    tag: '4.3-stable',
    version: '4.3',
    executable_path: '/dev/godot-4.3',
    is_mono: true,
    installed_at: hoursAgo(500),
    supports_console: true,
  },
]

const mkProject = (
  p: Partial<Project> & { id: string; name: string; path: string },
): Project => ({
  godot_version: '4.8-beta1',
  created_at: hoursAgo(1000),
  last_opened: hoursAgo(5),
  category: null,
  pinned: false,
  sort_order: 0,
  launch_arguments: '',
  tags: [],
  total_time_seconds: 0,
  session_started_at_ms: null,
  time_today_seconds: 0,
  time_week_seconds: 0,
  ...p,
})

const PROJECTS: Project[] = [
  mkProject({
    id: 'dev-1',
    name: 'Barely a Driver',
    path: 'D:/Projects/GameDev/Godot/Games/BADGame',
    pinned: true,
    tags: ['multiplayer', 'friendslop'],
    total_time_seconds: 207 * 3600 + 30 * 60,
    sort_order: 0,
  }),
  mkProject({
    id: 'dev-2',
    name: 'TVP-2.0',
    path: 'D:/Projects/GameDev/Godot/Games/TVP-2.0',
    tags: ['arena-shooter'],
    total_time_seconds: 19 * 3600 + 49 * 60,
    sort_order: 1,
  }),
  mkProject({
    id: 'dev-3',
    name: 'The Void Project',
    path: 'D:/Projects/GameDev/Godot/Games/TVP-Main',
    tags: ['main'],
    total_time_seconds: 30 * 60,
    sort_order: 2,
  }),
]

const WORKSPACES = {
  workspaces: [
    {
      id: 'default',
      name: 'Default',
      icon: 'briefcase',
      color: '#4f7cff',
      created_at: hoursAgo(1000),
    },
  ],
  active_id: 'default',
}

const HANDLERS: Record<string, (args: Record<string, unknown>) => unknown> = {
  list_workspaces: () => WORKSPACES,
  switch_workspace: () => WORKSPACES,
  create_workspace: () => WORKSPACES,
  update_workspace: () => WORKSPACES,
  delete_workspace: () => WORKSPACES,
  list_workspace_scan_dirs: () => [],
  get_settings: () => SETTINGS,
  update_settings: (a) => (a?.settings as unknown) ?? SETTINGS,
  reset_settings: () => SETTINGS,
  import_settings: () => SETTINGS,
  list_projects: () => PROJECTS,
  list_installed_godot_versions: () => VERSIONS,
  scan_for_versions: () => VERSIONS,
  list_categories: () => [],
  get_os_username: () => 'dev',
  get_git_status: () => null,
  get_activity: (a) => activitySeries(String(a?.range ?? 'weekly')),
  get_time_insights: () => TIME_INSIGHTS,
  list_running_projects: () => RUNNING,
  get_project_icon: (a) => mockIcon(String(a?.path ?? '')),
  get_project_name: () => null,
  list_open_todos: () => OPEN_TODOS,
}

function fallback(cmd: string): unknown {
  if (cmd === 'plugin:event|listen') return 0
  if (cmd.startsWith('plugin:')) return null
  if (/^(list_|scan_|fetch_|search_)/.test(cmd)) return []
  return null
}

export function installDevMocks(): void {
  if (!import.meta.env.DEV) return
  if (typeof window === 'undefined') return
  if ('__TAURI_INTERNALS__' in window) return
  mockIPC((cmd, args) => {
    const handler = HANDLERS[cmd]
    return handler
      ? handler((args ?? {}) as Record<string, unknown>)
      : fallback(cmd)
  })
  const internals = (
    window as unknown as { __TAURI_INTERNALS__?: Record<string, unknown> }
  ).__TAURI_INTERNALS__
  if (internals) {
    internals.metadata = {
      currentWindow: { label: 'main' },
      currentWebview: { windowLabel: 'main', label: 'main' },
    }
  }
  console.info('[dev-mock] Tauri invoke mocked >> browser preview mode')
}
