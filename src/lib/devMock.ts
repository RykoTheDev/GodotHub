import { mockIPC } from '@tauri-apps/api/mocks'
import { DEFAULTS } from '../hooks/useSettings'
import type { InstalledGodotVersion, Project } from '../types'

const now = Date.now()
const hoursAgo = (h: number) => new Date(now - h * 3600_000).toISOString()

const SETTINGS = {
  ...DEFAULTS,
  setup_complete: true,
  customize_view_enabled: true,
  categories_enabled: true,
  workspaces_enabled: false,
  auto_scan_on_startup: false,
}

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
