import { lazy, memo, Suspense, useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useProjectsContext } from './hooks/projectsContext'
import { useGodotVersionsContext } from './hooks/godotVersionsContext'
import { useKeyboardShortcuts } from './hooks/useKeyboardShortcuts'
import { useWorkspaces } from './hooks/useWorkspaces'
import { useOpenTodosSync, useTodoDueNotifications } from './hooks/useOpenTodosSync'
import { api } from './lib/api'
import { flushPendingSave } from './lib/pendingSave'
import { getCurrentWindow } from '@tauri-apps/api/window'
import type { GitStatus, Project } from './types'

import { Sidebar } from './components/ui/Sidebar'
import { AnnouncementBanner } from './components/ui/AnnouncementBanner'
import { WorkspaceSwitchNotice } from './components/ui/WorkspaceSwitchNotice'
const GitSidebar = lazy(() =>
  import('./components/git/GitSidebar').then((m) => ({ default: m.GitSidebar })),
)
import { Titlebar } from './components/titlebar/Titlebar'
import { ViewErrorBoundary } from './ErrorBoundary'
import { ConfirmDialog } from './components/modals/ConfirmDialog'
import { reportLaunchError } from './lib/launchErrors'
const loadCreateProjectModal = () => import('./components/modals/CreateProjectModal')
const loadBugReportModal = () => import('./components/modals/BugReportModal')
const loadCheckForUpdatesModal = () => import('./components/modals/CheckForUpdatesModal')
const loadCommandPalette = () => import('./components/modals/CommandPalette')
const CreateProjectModal = lazy(() =>
  loadCreateProjectModal().then((m) => ({ default: m.CreateProjectModal })),
)
const BugReportModal = lazy(() =>
  loadBugReportModal().then((m) => ({ default: m.BugReportModal })),
)
const CheckForUpdatesModal = lazy(() =>
  loadCheckForUpdatesModal().then((m) => ({ default: m.CheckForUpdatesModal })),
)
const CommandPalette = lazy(() =>
  loadCommandPalette().then((m) => ({ default: m.CommandPalette })),
)
import { ToastContainer } from './components/reusables/ToastContainer'
import { SplashScreen } from './components/reusables/SplashScreen'
const ProjectConsoleWindow = lazy(() =>
  import('./components/console/ProjectConsoleWindow').then((m) => ({
    default: m.ProjectConsoleWindow,
  })),
)
const ProjectsView = lazy(() =>
  import('./views/ProjectsView').then((m) => ({ default: m.ProjectsView })),
)
const VersionsView = lazy(() =>
  import('./views/VersionsView').then((m) => ({ default: m.VersionsView })),
)
const TemplatesView = lazy(() =>
  import('./views/TemplatesView').then((m) => ({ default: m.TemplatesView })),
)
const VaultView = lazy(() =>
  import('./views/VaultView').then((m) => ({ default: m.VaultView })),
)
const SettingsView = lazy(() =>
  import('./views/SettingsView').then((m) => ({ default: m.SettingsView })),
)
const ChangelogView = lazy(() =>
  import('./views/ChangelogView').then((m) => ({ default: m.ChangelogView })),
)
const NewsView = lazy(() =>
  import('./views/NewsView').then((m) => ({ default: m.NewsView })),
)
const AssetStoreView = lazy(() =>
  import('./views/AssetStoreView').then((m) => ({ default: m.AssetStoreView })),
)
const StorageView = lazy(() =>
  import('./views/StorageView').then((m) => ({ default: m.StorageView })),
)
const DashboardView = lazy(() =>
  import('./views/DashboardView').then((m) => ({ default: m.DashboardView })),
)
import { useSettings } from './hooks/useSettings'
import { useCategoriesContext } from './hooks/categoriesContext'
const Onboarding = lazy(() =>
  import('./views/OnboardingView').then((m) => ({ default: m.OnboardingView })),
)
import { useTauriEvent } from './lib/useTauriEvent'
import { useDiscordRpc } from './hooks/useDiscordRpc'
import { useNewsBadge } from './hooks/useNewsBadge'
import { isFeatureEnabled } from './lib/features'
import { ScreenReaderAnnouncer } from './lib/screenReader'
import { relaunch } from '@tauri-apps/plugin-process'
import {
  clearUiSwitchToSettings,
  consumeShellIntroHandOff,
  markSplashConsumed,
  shouldOpenSettingsAfterSwitch,
  shouldShowSplash,
} from './lib/uiTransition'
import { setPendingSettingsCategory } from './lib/settingsCategoryNav'
import { isRtl } from './lib/locale'
import { isMac } from './lib/platform'
import { enableLiveReveal, introShell, revealView } from './lib/motion'
import {
  IconBookOpen,
  IconBriefcase,
  IconCloudArrowDown,
  IconFolder,
  IconGear,
  IconCode,
  IconEye,
  IconHardDrive,
  IconLayoutGrid,
  IconHouse,
  IconNews,
  IconRocket,
  IconStore,
} from './lib/icons'

const TAB_GROUP_ICONS = { workspace: IconCode, resources: IconLayoutGrid, explore: IconEye }

const TABS = [
  { id: 'dashboard', navKey: 'dashboard', icon: IconHouse, hidden: true },
  { id: 'projects', navKey: 'projects', icon: IconFolder, group: 'workspace' },
  { id: 'versions', navKey: 'versions', icon: IconCloudArrowDown, group: 'workspace' },
  { id: 'templates', navKey: 'templates', icon: IconRocket, group: 'workspace' },
  { id: 'vault', navKey: 'vault', icon: IconBriefcase, isNew: true, group: 'resources' },
  { id: 'storage', navKey: 'storage_view', icon: IconHardDrive, isNew: true, group: 'resources' },
  { id: 'asset-store', navKey: 'asset_store', icon: IconStore, group: 'explore' },
  { id: 'news', navKey: 'news', icon: IconNews, group: 'explore' },
  { id: 'settings', navKey: 'settings', icon: IconGear, hidden: true },
  { id: 'changelog', navKey: 'changelog', icon: IconBookOpen, hidden: true },
] as const

const DEFAULT_GIT_SIDEBAR_WIDTH = 320

export type NewTab = (typeof TABS)[number]['id']

const VIEW_CHUNKS: Record<NewTab, () => Promise<unknown>> = {
  dashboard: () => import('./views/DashboardView'),
  projects: () => import('./views/ProjectsView'),
  versions: () => import('./views/VersionsView'),
  templates: () => import('./views/TemplatesView'),
  vault: () => import('./views/VaultView'),
  'asset-store': () => import('./views/AssetStoreView'),
  news: () => import('./views/NewsView'),
  settings: () => import('./views/SettingsView'),
  changelog: () => import('./views/ChangelogView'),
  storage: () => import('./views/StorageView'),
}

function preloadViewChunks(ids: NewTab[]) {
  const chunks = [
    ...ids.map((id) => VIEW_CHUNKS[id]()),
    import('./components/git/GitSidebar'),
    loadCommandPalette(),
    loadCreateProjectModal(),
    loadCheckForUpdatesModal(),
    loadBugReportModal(),
  ]
  chunks.forEach((c) => c.catch(() => {}))
}

function renderTabView(
  id: NewTab,
  active: boolean,
  connected: boolean,
  gitSidebarOpen: boolean,
  onOpenSettings: () => void,
) {
  switch (id) {
    case 'dashboard':
      return <DashboardView connected={connected} active={active} />
    case 'projects':
      return (
        <ProjectsView
          onOpenSettings={onOpenSettings}
          connected={connected}
          gitSidebarOpen={gitSidebarOpen}
          active={active}
        />
      )
    case 'versions':
      return <VersionsView onOpenSettings={onOpenSettings} connected={connected} />
    case 'news':
      return <NewsView connected={connected} />
    case 'templates':
      return <TemplatesView onOpenSettings={onOpenSettings} connected={connected} />
    case 'vault':
      return <VaultView connected={connected} />
    case 'asset-store':
      return <AssetStoreView connected={connected} />
    case 'storage':
      return <StorageView connected={connected} active={active} />
    case 'settings':
      return <SettingsView connected={connected} />
    case 'changelog':
      return <ChangelogView connected={connected} />
  }
}

interface ViewPaneProps {
  id: NewTab
  active: boolean
  connected: boolean
  gitSidebarOpen: boolean
  onOpenSettings: () => void
}

const ViewPane = memo(function ViewPane({
  id,
  active,
  connected,
  gitSidebarOpen,
  onOpenSettings,
}: ViewPaneProps) {
  const paneRef = useRef<HTMLDivElement>(null)
  useLayoutEffect(() => {
    if (active && paneRef.current) revealView(paneRef.current)
  }, [active])
  return (
    <div
      ref={paneRef}
      data-view-pane
      className="flex-1 min-w-0 h-full"
      style={{ display: active ? 'block' : 'none' }}
      aria-hidden={!active}
    >
      <ViewErrorBoundary>
        <Suspense fallback={null}>
          {renderTabView(id, active, connected, gitSidebarOpen, onOpenSettings)}
        </Suspense>
      </ViewErrorBoundary>
    </div>
  )
})

export function App() {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings, loaded: settingsLoaded, update: updateSettings } = useSettings()
  const cardLayout = settings.card_layout ?? true
  const { projects, refresh: refreshProjects } = useProjectsContext()
  const projectsRef = useRef(projects)
  projectsRef.current = projects
  const [splashDone, setSplashDone] = useState(() => !shouldShowSplash())
  const [uiSwitchIntent] = useState(() => shouldOpenSettingsAfterSwitch())
  const [projectsCorrupt, setProjectsCorrupt] = useState(false)
  const [requestedTab, setTab] = useState<NewTab>(uiSwitchIntent ? 'settings' : 'projects')
  const enabledTabs = TABS.filter((entry) => isFeatureEnabled(settings, entry.id))
  const enabledTabIds = enabledTabs.map((entry) => entry.id).join('|')
  const tab: NewTab = enabledTabs.some((entry) => entry.id === requestedTab) ? requestedTab : 'projects'
  const shortcutTabs = enabledTabs.filter((entry) => !('hidden' in entry)).map((entry) => entry.id).slice(0, 9)
  const newsUnread = useNewsBadge(tab === 'news', settingsLoaded && isFeatureEnabled(settings, 'news'))

  const [mountedTabs, setMountedTabs] = useState<NewTab[]>(() => [tab])
  const liveMountedTabs = mountedTabs.filter((id) => isFeatureEnabled(settings, id))
  if (!liveMountedTabs.includes(tab) || liveMountedTabs.length !== mountedTabs.length) {
    setMountedTabs(liveMountedTabs.includes(tab) ? liveMountedTabs : [...liveMountedTabs, tab])
  }
  const openSettingsTab = useCallback(() => setTab('settings'), [])
  const todosEnabled = settingsLoaded && settings.project_todos_enabled
  useOpenTodosSync(todosEnabled, projects.map((p) => p.id).join('|'))
  useTodoDueNotifications(todosEnabled && settings.desktop_notifications_enabled)

  useEffect(() => {
    if (!settingsLoaded) return
    const preload = () => preloadViewChunks(enabledTabIds.split('|') as NewTab[])
    if (typeof window.requestIdleCallback === 'function') {
      const id = window.requestIdleCallback(preload, { timeout: 2000 })
      return () => window.cancelIdleCallback(id)
    }
    const id = window.setTimeout(preload, 1000)
    return () => window.clearTimeout(id)
  }, [settingsLoaded, enabledTabIds])
  const landingTabRef = useRef<string | null>(null)

  // Flush debounced settings before the window closes. This only guarantees the
  // save runs first; the backend still decides whether to close or hide to tray.
  const keepAliveOnCloseRef = useRef(false)
  keepAliveOnCloseRef.current = isMac || settings.minimize_to_tray
  useEffect(() => {
    const win = getCurrentWindow()
    let unlisten: (() => void) | undefined
    let disposed = false
    win
      .onCloseRequested(async (event) => {
        event.preventDefault()
        await flushPendingSave().catch(() => {})
        if (!keepAliveOnCloseRef.current) {
          await win.destroy().catch(() => {})
        }
      })
      .then((u) => {
        if (disposed) u()
        else unlisten = u
      })
      .catch(() => {})
    return () => {
      disposed = true
      unlisten?.()
    }
  }, [])

  // Surface a corrupt project registry instead of silently showing an empty list.
  useEffect(() => {
    let cancelled = false
    api
      .getProjectsHealth()
      .then((health) => {
        if (!cancelled && health === 'corrupt') setProjectsCorrupt(true)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:view-changed', { detail: tab }))
  }, [tab])

  useEffect(() => {
    if (!settingsLoaded || uiSwitchIntent) return
    if (landingTabRef.current !== null) return
    landingTabRef.current = settings.default_landing_tab
    const landing = settings.default_landing_tab as NewTab
    if (TABS.some((t) => t.id === landing)) setTab(landing)
  }, [settingsLoaded, settings.default_landing_tab, uiSwitchIntent])
  const [pendingLaunch, setPendingLaunch] = useState<{
    id: string
    console?: boolean
  } | null>(null)
  const [gitSidebarProject, setGitSidebarProject] = useState<{
    project: Project
    gitStatus: GitStatus | null
  } | null>(null)
  const gitSidebarOpen = !!gitSidebarProject
  const gitSidebarOpenRef = useRef(gitSidebarOpen)
  gitSidebarOpenRef.current = gitSidebarOpen
  const [gitSidebarWidth, setGitSidebarWidth] = useState(() => {
    try {
      return Math.min(
        560,
        Math.max(280, Number(localStorage.getItem('new_ui_git_sidebar_width')) || DEFAULT_GIT_SIDEBAR_WIDTH),
      )
    } catch {
      return DEFAULT_GIT_SIDEBAR_WIDTH
    }
  })
  const gitWidthRef = useRef(gitSidebarWidth)
  gitWidthRef.current = gitSidebarWidth
  const gitStartXRef = useRef(0)
  const gitStartWidthRef = useRef(0)
  const [gitDragging, setGitDragging] = useState(false)
  const [gitRevealed, setGitRevealed] = useState(false)
  const [gitKnobY, setGitKnobY] = useState<number | null>(null)
  const lastGitDownRef = useRef(0)
  const fixedKnob = settings.fixed_sidebar_resize_knob
  const showGitKnob = gitDragging || gitRevealed

  const clampGitKnobY = (y: number, height: number) =>
    Math.min(Math.max(36, y), Math.max(36, height - 40))

  const knobOffsetY = (y: number, height: number) => clampGitKnobY(y, height) - height / 2

  const resetGitWidth = () => {
    setGitSidebarWidth(DEFAULT_GIT_SIDEBAR_WIDTH)
    try {
      localStorage.setItem('new_ui_git_sidebar_width', String(DEFAULT_GIT_SIDEBAR_WIDTH))
    } catch {}
  }

  const beginGitDrag = (e: React.PointerEvent) => {
    const now = Date.now()
    if (now - lastGitDownRef.current < 350) {
      lastGitDownRef.current = now
      resetGitWidth()
      return
    }
    lastGitDownRef.current = now
    e.preventDefault()
    gitStartXRef.current = e.clientX
    gitStartWidthRef.current = gitWidthRef.current
    setGitDragging(true)
    try {
      e.currentTarget.setPointerCapture(e.pointerId)
    } catch {}
  }

  const finishGitDrag = (e: React.PointerEvent) => {
    setGitDragging(false)
    try {
      e.currentTarget.releasePointerCapture(e.pointerId)
    } catch {}
    try {
      localStorage.setItem('new_ui_git_sidebar_width', String(gitWidthRef.current))
    } catch {}
  }

  const handleGitStripMove = (e: React.PointerEvent) => {
    if (gitDragging) {
      if (e.buttons === 0) {
        finishGitDrag(e)
        return
      }
      const delta = gitStartXRef.current - e.clientX
      const next = gitStartWidthRef.current + (isRtl() ? -delta : delta)
      setGitSidebarWidth(Math.min(560, Math.max(280, Math.round(next))))
      return
    }
    if (fixedKnob) return
    const rect = e.currentTarget.getBoundingClientRect()
    const y = e.clientY - rect.top
    setGitKnobY(knobOffsetY(y, rect.height))
  }

  const handleGitWrapperMove = (e: React.MouseEvent) => {
    if (gitDragging || fixedKnob) return
    const rect = e.currentTarget.getBoundingClientRect()
    const dist = isRtl() ? rect.right - e.clientX : e.clientX - rect.left
    if (dist > 72) {
      setGitKnobY(null)
      return
    }
    if (dist <= 56) {
      const y = e.clientY - rect.top
      setGitKnobY(knobOffsetY(y, rect.height))
    }
  }

  const endGitDrag = (e: React.PointerEvent) => {
    if (!gitDragging) return
    finishGitDrag(e)
  }
  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false)
  const [bugReportOpen, setBugReportOpen] = useState(false)
  const [confirmingRestart, setConfirmingRestart] = useState(false)
  const [createProjectOpen, setCreateProjectOpen] = useState(false)
  const [updatesModalOpen, setUpdatesModalOpen] = useState(false)
  const [updatesModalMode, setUpdatesModalMode] = useState<
    'manual' | 'preview'
  >('manual')
  const installed = useGodotVersionsContext((v) => v.installed)
  const { workspaces, switchWorkspace } = useWorkspaces()
  const { categories } = useCategoriesContext()
  const settingsRef = useRef(settings)
  settingsRef.current = settings
  const paletteKey = settings.command_palette_keybind || 'p'

  const openProject = useCallback(
    async (projectId: string, withConsole?: boolean) => {
      try {
        await api.openProject(projectId, true, withConsole)
        refreshProjects()
      } catch (err) {
        reportLaunchError(err)
      }
    },
    [refreshProjects],
  )

  useEffect(() => {
    const handleOpenProject = async (e: Event) => {
      const detail = (e as CustomEvent).detail as
        | string
        | { id: string; console?: boolean }
      const projectId = typeof detail === 'string' ? detail : detail.id
      const withConsole = typeof detail === 'string' ? undefined : detail.console
      const project = projectsRef.current.find((p) => p.id === projectId)
      if (project?.session_started_at_ms) {
        setPendingLaunch({ id: projectId, console: withConsole })
        return
      }
      await openProject(projectId, withConsole)
    }
    window.addEventListener('app:open-project', handleOpenProject)
    return () =>
      window.removeEventListener('app:open-project', handleOpenProject)
  }, [openProject])

  useTauriEvent<{ id: string }>('project:exited', () => refreshProjects())

  useDiscordRpc(settings, projects)

  useEffect(() => {
    markSplashConsumed()
    if (uiSwitchIntent) clearUiSwitchToSettings()
  }, [uiSwitchIntent])

  useEffect(() => {
    if (settingsLoaded) setSplashDone(true)
  }, [settingsLoaded])

  useEffect(() => {
    const handleOpenSetting = () => setTab('settings')
    window.addEventListener('app:open-setting', handleOpenSetting)
    return () =>
      window.removeEventListener('app:open-setting', handleOpenSetting)
  }, [])

  useEffect(() => {
    const handleOpenSettingsCategory = (e: Event) => {
      const detail = (e as CustomEvent).detail as string | undefined
      if (typeof detail !== 'string') return
      setPendingSettingsCategory(detail)
      setTab('settings')
    }
    window.addEventListener('app:open-settings-category', handleOpenSettingsCategory)
    return () =>
      window.removeEventListener('app:open-settings-category', handleOpenSettingsCategory)
  }, [])

  useEffect(() => {
    const handleShowTodos = () => {
      setGitSidebarProject(null)
      setTab('projects')
    }
    window.addEventListener('app:show-project-todos', handleShowTodos)
    return () => window.removeEventListener('app:show-project-todos', handleShowTodos)
  }, [])

  useEffect(() => {
    const handleSetTab = (e: Event) => {
      const detail = (e as CustomEvent).detail as NewTab | undefined
      if (detail) setTab(detail)
    }
    window.addEventListener('app:set-tab', handleSetTab)
    return () => window.removeEventListener('app:set-tab', handleSetTab)
  }, [])

  useEffect(() => {
    const handleNewProject = () => setCreateProjectOpen(true)
    const handleImportProject = async () => {
      try {
        const folder = await api.pickFolder()
        if (!folder) return
        await api.importProject(folder, '')
        refreshProjects()
      } catch (e) {
        console.error('[new-ui] import failed:', e)
      }
    }
    const handleScanProjects = async () => {
      if (settingsRef.current.project_scan_dirs.length === 0) {
        setTab('settings')
        return
      }
      try {
        await api.scanForProjectsWithInfo(
          settingsRef.current.project_scan_dirs,
          settingsRef.current.scan_depth,
        )
        refreshProjects()
      } catch (e) {
        console.error('[new-ui] scan failed:', e)
      }
    }
    const handleReportBug = () => setBugReportOpen(true)
    const handlePreviewUpdate = () => {
      setUpdatesModalMode('preview')
      setUpdatesModalOpen(true)
    }

    window.addEventListener('app:new-project-request', handleNewProject)
    window.addEventListener('app:import-project-request', handleImportProject)
    window.addEventListener('app:scan-projects', handleScanProjects)
    window.addEventListener('app:report-bug', handleReportBug)
    window.addEventListener('app:preview-update-modal', handlePreviewUpdate)
    return () => {
      window.removeEventListener('app:new-project-request', handleNewProject)
      window.removeEventListener('app:import-project-request', handleImportProject)
      window.removeEventListener('app:scan-projects', handleScanProjects)
      window.removeEventListener('app:report-bug', handleReportBug)
      window.removeEventListener('app:preview-update-modal', handlePreviewUpdate)
    }
  }, [refreshProjects])

  useKeyboardShortcuts(
    {
      onNewProject: () => setCreateProjectOpen(true),
      onOpenSettings: () => setTab('settings'),
      onSwitchTab: (i: number) => {
        if (shortcutTabs[i]) setTab(shortcutTabs[i])
      },
      onSwitchWorkspace: (i: number) => {
        const target = workspaces[i]
        if (settings.workspaces_enabled && target) void switchWorkspace(target.id)
      },
      onCommandPalette: () => setCommandPaletteOpen((o) => !o),
      onRestart: () => {
        setConfirmingRestart(true)
      },
      onEscape: () => {
        setGitSidebarProject(null)
        setCommandPaletteOpen(false)
        setBugReportOpen(false)
      },
      onFocusSearch: () => window.dispatchEvent(new Event('app:focus-search')),
      onLaunchSelection: () => window.dispatchEvent(new Event('app:launch-selection')),
      onDeleteSelection: () => window.dispatchEvent(new Event('app:delete-selection')),
    },
    paletteKey,
  )

  useEffect(() => {
    const handleShowGitSidebar = (e: Event) => {
      const detail = (e as CustomEvent).detail as {
        project: Project
        gitStatus: GitStatus | null
      }
      setGitSidebarProject((current) =>
        current && current.project.id === detail.project.id ? null : detail,
      )
    }
    window.addEventListener('app:show-git-sidebar', handleShowGitSidebar)
    return () =>
      window.removeEventListener('app:show-git-sidebar', handleShowGitSidebar)
  }, [])

  const tabs = enabledTabs.filter((tab) => !('hidden' in tab) || !tab.hidden).map((tab) => ({
    id: tab.id,
    label: t(tab.navKey),
    icon: tab.icon,
    isNew: 'isNew' in tab ? tab.isNew : undefined,
    group: 'group' in tab ? { id: tab.group, label: t(`group_${tab.group}`), icon: TAB_GROUP_ICONS[tab.group] } : undefined,
    shortcut: shortcutTabs.indexOf(tab.id) + 1 || undefined,
    badge: tab.id === 'news' && newsUnread > 0 ? newsUnread : undefined,
  }))

  const shellRef = useRef<HTMLDivElement>(null)
  const mainRef = useRef<HTMLDivElement>(null)
  const onboarding = settingsLoaded && !settings.setup_complete
  const shellReady = settingsLoaded && settings.setup_complete
  useEffect(() => {
    if (onboarding) enableLiveReveal()
  }, [onboarding])
  useLayoutEffect(() => {
    if (!shellReady) return
    if (consumeShellIntroHandOff()) {
      enableLiveReveal()
      return
    }
    introShell(
      shellRef.current?.querySelector<HTMLElement>(':scope > header') ?? null,
      (mainRef.current?.firstElementChild as HTMLElement | null) ?? null,
    )
  }, [shellReady])

  if (onboarding) {
    return (
      <div data-view-pane className="contents">
        <Suspense fallback={null}>
          <Onboarding
            settings={settings}
            onComplete={updateSettings}
          />
        </Suspense>
      </div>
    )
  }

  if (!settingsLoaded) {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-base text-muted text-sm">
        {tc('app_loading')}
      </div>
    )
  }

  return (
    <>
    <div ref={shellRef} className="new-ui h-screen w-screen flex flex-col bg-base text-ink font-body">
      <ScreenReaderAnnouncer enabled={settings.screen_reader_announcements} />
      <ToastContainer />
      {settings.workspaces_enabled && <WorkspaceSwitchNotice />}
      <Titlebar />

      <div
        ref={mainRef}
        className={`relative flex-1 flex min-h-0 overflow-hidden ${
          cardLayout ? 'p-4 pt-3 gap-4' : 'gap-0'
        }`}
      >
        <Sidebar
          tabs={tabs}
          activeTab={tab}
          onTabChange={(id) => {
            setGitSidebarProject(null)
            setTab(id as NewTab)
          }}
          connected={!cardLayout}
          paletteKey={paletteKey}
          onOpenCommandPalette={() => setCommandPaletteOpen(true)}
          onOpenUpdatesModal={() => {
            setUpdatesModalMode('manual')
            setUpdatesModalOpen(true)
          }}
        />

        <div data-app-main className="relative flex-1 flex min-w-0 min-h-0">
          {mountedTabs.map((id) => (
            <ViewPane
              key={id}
              id={id}
              active={id === tab}
              connected={!cardLayout}
              gitSidebarOpen={id === 'projects' && !!gitSidebarProject}
              onOpenSettings={openSettingsTab}
            />
          ))}
          <AnnouncementBanner />
        </div>


          {gitSidebarProject && (
            <>
              <div
                key="git-backdrop"
                data-motion="backdrop"
                className="absolute inset-0 z-40 bg-black/30"
                onClick={() => setGitSidebarProject(null)}
              />
              <div
                key="git-panel"
                data-motion="panel"
                className={`absolute top-2 inset-e-2 bottom-2 z-50 ${gitDragging ? 'select-none' : ''}`}
              >
                <div
                  className="relative h-full w-full"
                  onMouseEnter={() => setGitRevealed(true)}
                  onMouseMove={handleGitWrapperMove}
                  onMouseLeave={(e) => {
                    if (e.relatedTarget instanceof Node && e.currentTarget.contains(e.relatedTarget)) return
                    setGitRevealed(false)
                    setGitKnobY(null)
                  }}
                >
                  <aside
                    className="h-full overflow-hidden rounded-xl shadow-2xl shadow-black/40 shrink-0"
                    style={{ width: gitSidebarWidth }}
                  >
                    <Suspense fallback={null}>
                      <GitSidebar
                        project={gitSidebarProject.project}
                        gitStatus={gitSidebarProject.gitStatus}
                        onClose={() => setGitSidebarProject(null)}
                        onRefresh={() => refreshProjects()}
                        onSwitchProject={async (p) => {
                          const updated = await api.updateProject(p.id, { path: p.path })
                          const status = await api.getGitStatus(updated.path).catch(() => null)
                          setGitSidebarProject((prev) => prev && prev.project.id === updated.id
                            ? { project: updated, gitStatus: status }
                            : prev)
                          await refreshProjects()
                        }}
                        connected={!cardLayout}
                      />
                    </Suspense>
                  </aside>
                  <div
                    onPointerDown={beginGitDrag}
                    onPointerMove={handleGitStripMove}
                    onPointerUp={endGitDrag}
                    onPointerCancel={endGitDrag}
                    onMouseEnter={() => setGitRevealed(true)}
                    onMouseLeave={(e) => {
                      if (e.relatedTarget instanceof Node && e.currentTarget.parentElement?.contains(e.relatedTarget)) return
                      setGitRevealed(false)
                      setGitKnobY(null)
                    }}
                    role="separator"
                    aria-orientation="vertical"
                    style={{ touchAction: 'none' }}
                    className="absolute inset-y-0 -inset-s-3.5 w-7 cursor-col-resize group/edge z-10"
                  >
                    <div
                      className={`absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none  ${
                        showGitKnob ? 'opacity-100' : 'opacity-0'
                      }`}
                    >
                      <div
                        className={`flex flex-col items-center ${
                          gitKnobY != null && !fixedKnob
                            ? ''
                            : ' '
                        }`}
                        style={
                          gitKnobY != null && !fixedKnob
                            ? { transform: `translateY(${gitKnobY}px)` }
                            : undefined
                        }
                      >
                        <div
                          className={`absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 rounded-tag bg-raised border border-line shadow-md shadow-base text-3xs font-mono text-muted tabular-nums whitespace-nowrap  ${
                            gitDragging ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-1'
                          }`}
                        >
                          {gitSidebarWidth}px
                        </div>
                        <div
                          className={`flex items-center justify-center w-5 h-10 rounded-full border shadow-md shadow-base  ${
                            gitDragging
                              ? 'bg-accent border-accent scale-110 shadow-accent/30'
                              : 'bg-raised border-line shadow-base group-hover/edge:border-accent-dim'
                          }`}
                        >
                          <div className="flex flex-col items-center justify-center gap-1">
                            <div
                              className={`w-1 h-1 rounded-full  ${
                                gitDragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
                              }`}
                            />
                            <div
                              className={`w-1 h-1 rounded-full  ${
                                gitDragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
                              }`}
                            />
                            <div
                              className={`w-1 h-1 rounded-full  ${
                                gitDragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
                              }`}
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </>
          )}


        <Suspense fallback={null}>
          <ProjectConsoleWindow />
        </Suspense>

      </div>


        {pendingLaunch && (
          <ConfirmDialog
            title={tc('project_already_open_title')}
            description={tc('project_already_open_desc', {
              name:
                projects.find((p) => p.id === pendingLaunch.id)?.name ??
                pendingLaunch.id,
            })}
            confirmLabel={tc('project_open_anyway')}
            onConfirm={() => {
              const pending = pendingLaunch
              setPendingLaunch(null)
              openProject(pending.id, pending.console)
            }}
            onCancel={() => setPendingLaunch(null)}
          />
        )}



        {confirmingRestart && (
          <ConfirmDialog
            title={tc('reload_confirm_title')}
            description={tc('reload_confirm_desc')}
            confirmLabel={tc('reload')}
            onConfirm={() => {
              setConfirmingRestart(false)
              void relaunch()
            }}
            onCancel={() => setConfirmingRestart(false)}
          />
        )}



        <Suspense fallback={null}>
        {commandPaletteOpen && (
          <CommandPalette
            onClose={() => setCommandPaletteOpen(false)}
            currentTab={tab}
            onNavigate={(id) => setTab(id as NewTab)}
            projects={projects}
            installedVersions={installed}
          />
        )}



        {createProjectOpen && (
          <CreateProjectModal
            installedVersions={installed}
            defaultLocation={settings.default_project_location}
            categories={categories}
            categoriesEnabled={settings.categories_enabled}
            onClose={() => setCreateProjectOpen(false)}
            onCreated={() => {
              setCreateProjectOpen(false)
              refreshProjects()
            }}
          />
        )}



        {bugReportOpen && <BugReportModal onClose={() => setBugReportOpen(false)} />}



        {updatesModalOpen && (
          <CheckForUpdatesModal
            mode={updatesModalMode}
            onClose={() => setUpdatesModalOpen(false)}
          />
        )}
        </Suspense>
        {projectsCorrupt && (
          <ConfirmDialog
            title={tc('projects_corrupt_title')}
            description={tc('projects_corrupt_desc')}
            confirmLabel={tc('projects_corrupt_restore')}
            cancelLabel={tc('projects_corrupt_dismiss')}
            onConfirm={() => {
              void (async () => {
                try {
                  await api.restoreProjectsFromBackup()
                  refreshProjects()
                } catch {
                  // Leave the files untouched if there is no usable backup.
                }
                setProjectsCorrupt(false)
              })()
            }}
            onCancel={() => setProjectsCorrupt(false)}
          />
        )}


    </div>
    {!splashDone && <SplashScreen />}
    </>
  )
}
