import { useEffect, useState, useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow'
import { listen } from '@tauri-apps/api/event'
import { ProjectsView } from './views/ProjectsView'
import { VersionsView } from './views/VersionsView'
import { NewsView } from './views/NewsView'
import { SettingsView } from './views/SettingsView'
import { ChangelogView } from './views/ChangelogView'
import { TemplatesView } from './views/TemplatesView'
import { OnboardingView } from './views/OnboardingView'
import { useSettings } from './hooks/useSettings'
import { useWorkspaces } from './hooks/useWorkspaces'
import { useProjectsContext } from './hooks/projectsContext'
import { useKeyboardShortcuts } from './hooks/useKeyboardShortcuts'
import { check } from '@tauri-apps/plugin-updater'
import { BugReportModal } from './components/modals/BugReportModal'
import { CheckForUpdatesModal } from './components/modals/CheckForUpdatesModal'
import { CommandPalette } from './components/modals/CommandPalette'
import { ConfirmDialog } from './components/modals/ConfirmDialog'
import { ShortcutCheatsheet } from './components/modals/ShortcutCheatsheet'
import { CreateWorkspaceModal } from './components/modals/CreateWorkspaceModal'
import { api } from './lib/api'
import { TitleBar } from './components/Titlebar'
import { SplashScreen, type SplashPhase } from './components/SplashScreen'
import { OnboardingTips } from './components/OnboardingTips'
import { WorkspaceSwitcher } from './WorkspaceSwitcher'
import { Tooltip } from './components/ui/Tooltip'
import type { GitStatus, Project } from './types'
import { GitSidebar } from './components/git/GitSidebar'
import {
  IconGear,
  IconLayoutGrid,
  IconLayoutList,
  IconNews,
  IconChevronsLeft,
  IconChevronsRight,
  IconBookOpen,
  IconCheck,
  IconDownload,
  IconFolderPlus,
  IconCopy,
  IconRefresh,
  IconX,
  IconPlay,
} from './components/Icons'
import './index.css'
import {
  GodotVersionsProvider,
  useGodotVersionsContext,
} from './hooks/godotVersionsContext'

type Tab = 'projects' | 'versions' | 'news' | 'templates' | 'settings' | 'changelog'

const NAV_ITEMS: { tab: Tab; label: string; icon: typeof IconLayoutGrid }[] = [
  { tab: 'projects', label: 'Projects', icon: IconLayoutGrid },
  { tab: 'versions', label: 'Versions', icon: IconLayoutList },
  { tab: 'templates', label: 'Templates', icon: IconCopy },
  { tab: 'news', label: 'News', icon: IconNews },
]

const SIDEBAR_COLLAPSED_KEY = 'sidebar_collapsed'
const SIDEBAR_COLLAPSED_WIDTH_KEY = 'sidebar_width_collapsed'
const SIDEBAR_EXPANDED_WIDTH_KEY = 'sidebar_width_expanded'

function loadCollapsedWidth(): number {
  try {
    const raw = localStorage.getItem(SIDEBAR_COLLAPSED_WIDTH_KEY)
    const n = Number(raw)
    if (n >= 50 && n <= 120) return n
  } catch {}
  return 76
}

function loadExpandedWidth(): number {
  try {
    const raw = localStorage.getItem(SIDEBAR_EXPANDED_WIDTH_KEY)
    const n = Number(raw)
    if (n >= 150 && n <= 420) return n
  } catch {}
  return 230
}

function AppContent() {
  const [tab, setTab] = useState<Tab>('projects')
  const tabRef = useRef(tab)
  tabRef.current = tab
  const pendingActionRef = useRef<
    'new-project' | 'import-project' | 'scan-projects' | 'import-version' | 'sync-templates' | null
  >(null)
  const [collapsed, setCollapsed] = useState(() => {
    try {
      return localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === '1'
    } catch {
      return false
    }
  })
  const [sidebarCollapsedWidth, setSidebarCollapsedWidth] =
    useState(loadCollapsedWidth)
  const [sidebarExpandedWidth, setSidebarExpandedWidth] =
    useState(loadExpandedWidth)

  const { projects, refresh: refreshProjects } = useProjectsContext()
  const { installed, refreshInstalled } = useGodotVersionsContext()
  const {
    workspaces,
    activeId,
    switchWorkspace,
    createWorkspace,
  } = useWorkspaces()
  const { settings } = useSettings()

  const [gitSidebarProject, setGitSidebarProject] = useState<{
    project: Project
    gitStatus: GitStatus | null
  } | null>(null)

const [bugReportOpen, setBugReportOpen] = useState(false)
  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false)
  const [highlightSetting, setHighlightSetting] = useState<string | null>(null)
  const [createWorkspaceOpen, setCreateWorkspaceOpen] = useState(false)
  const [showShortcuts, setShowShortcuts] = useState(false)
  const [updatesModalOpen, setUpdatesModalOpen] = useState(false)
  const [updateModalMode, setUpdateModalMode] = useState<'background' | 'manual'>('manual')
  const [showTips, setShowTips] = useState(() => {
    try {
      return localStorage.getItem('godothub_tips_shown') !== '1'
    } catch {
      return false
    }
  })
  const [splashPhase, setSplashPhase] = useState<SplashPhase | 'done'>('enter')
  const [dragOver, setDragOver] = useState(false)
  const [dragType, setDragType] = useState<'project' | 'version'>('project')
  const [importingOverlay, setImportingOverlay] = useState<{
    type: 'project' | 'version'
    total: number
    current: number
  } | null>(null)
  const projectsRef = useRef(projects)
  projectsRef.current = projects
  const [launchingProject, setLaunchingProject] = useState<{
    id: string
    name: string
    version: string
  } | null>(null)
  const [confirmingStop, setConfirmingStop] = useState(false)
  const [errorNotification, setErrorNotification] = useState<string | null>(null)
  const [successNotification, setSuccessNotification] = useState<{
    count: number
    firstId: string
    firstProjectName: string
    failCount?: number
  } | null>(null)

  const paletteKey = settings.command_palette_keybind || 'k'

  useEffect(() => {
    const unlistenProject = listen('watcher:project-scan-done', () => {
      refreshProjects()
    })
    const unlistenVersion = listen('watcher:version-scan-done', () => {
      refreshInstalled()
    })
    const unlistenTemplate = listen('watcher:template-synced', () => {
      if (tabRef.current === 'templates') {
        window.dispatchEvent(new CustomEvent('app:refresh-templates'))
      }
    })
    return () => {
      unlistenProject.then((fn) => fn())
      unlistenVersion.then((fn) => fn())
      unlistenTemplate.then((fn) => fn())
    }
  }, [refreshProjects, refreshInstalled])

  useEffect(() => {
    if (settings.auto_scan_on_startup) {
      const dirs = settings.project_scan_dirs
      const depth = settings.scan_depth
      if (dirs.length > 0) {
        api.scanForProjects(dirs, depth).catch(() => {})
      }
      const versionDirs = settings.version_scan_dirs
      if (versionDirs.length > 0) {
        api.scanForVersions(versionDirs, depth).catch(() => {})
      }
    }
  }, [])

  useEffect(() => {
    if (splashPhase === 'enter') {
      const t = setTimeout(() => setSplashPhase('fly'), 1000)
      return () => clearTimeout(t)
    }
    if (splashPhase === 'fly') {
      const t = setTimeout(() => setSplashPhase('fade'), 500)
      return () => clearTimeout(t)
    }
    if (splashPhase === 'fade') {
      const t = setTimeout(() => setSplashPhase('done'), 400)
      return () => clearTimeout(t)
    }
  }, [splashPhase])

  useEffect(() => {
    const handler = () => {
      setSidebarCollapsedWidth(loadCollapsedWidth())
      setSidebarExpandedWidth(loadExpandedWidth())
    }
    window.addEventListener('app:sidebar-width-changed', handler)
    return () =>
      window.removeEventListener('app:sidebar-width-changed', handler)
  }, [])

  const requestNewProject = useCallback(() => {
    if (tabRef.current === 'projects') {
      window.dispatchEvent(new CustomEvent('app:new-project'))
    } else {
      pendingActionRef.current = 'new-project'
      setTab('projects')
    }
  }, [])

  const requestImportProject = useCallback(() => {
    if (tabRef.current === 'projects') {
      window.dispatchEvent(new CustomEvent('app:import-project'))
    } else {
      pendingActionRef.current = 'import-project'
      setTab('projects')
    }
  }, [])

  const requestScanProjects = useCallback(() => {
    if (tabRef.current === 'projects') {
      window.dispatchEvent(new CustomEvent('app:scan-projects'))
    } else {
      pendingActionRef.current = 'scan-projects'
      setTab('projects')
    }
  }, [])

  const requestImportVersion = useCallback(() => {
    if (tabRef.current === 'versions') {
      window.dispatchEvent(new CustomEvent('app:import-version'))
    } else {
      pendingActionRef.current = 'import-version'
      setTab('versions')
    }
  }, [])

  const requestSyncTemplates = useCallback(() => {
    if (tabRef.current === 'templates') {
      window.dispatchEvent(new CustomEvent('app:sync-templates'))
    } else {
      pendingActionRef.current = 'sync-templates'
      setTab('templates')
    }
  }, [])

  const openCreateWorkspace = useCallback(
    () => setCreateWorkspaceOpen(true),
    [],
  )

  useEffect(() => {
    const appWindow = getCurrentWebviewWindow()
    const unlistenPromise = appWindow.onDragDropEvent((event) => {
      const { type } = event.payload

      if (type === 'enter' || type === 'over') {
        setDragOver(true)
        if (type === 'enter') {
          const paths = (event.payload as { paths: string[] }).paths
          if (paths && paths.length > 0) {
            setDragType(
              paths[0].toLowerCase().endsWith('.zip')
                ? 'version'
                : 'project',
            )
          }
        }
      } else if (type === 'leave') {
        setDragOver(false)
      } else if (type === 'drop') {
        setDragOver(false)
        const paths = (event.payload as { paths: string[] }).paths
        if (!paths || paths.length === 0) return

        const isVersionZipDrop =
          tabRef.current === 'versions' &&
          paths.length === 1 &&
          paths[0].toLowerCase().endsWith('.zip')

        if (isVersionZipDrop) {
          setImportingOverlay({ type: 'version', total: 1, current: 0 })
          ;(async () => {
            try {
              setImportingOverlay({ type: 'version', total: 1, current: 1 })
              const version = await api.importVersionZip(paths[0])
              await refreshInstalled()
              setSuccessNotification({
                count: 1,
                firstId: version.tag,
                firstProjectName: version.tag,
              })
            } catch (e) {
              setErrorNotification(String(e))
            } finally {
              setImportingOverlay(null)
            }
          })()
        } else {
          const imported: Project[] = []
          const errors: unknown[] = []

          setImportingOverlay({
            type: 'project',
            total: paths.length,
            current: 0,
          })

          ;(async () => {
            for (const [i, p] of paths.entries()) {
              try {
                const project = await api.importProject(p, '')
                imported.push(project)
              } catch (e) {
                errors.push(e)
              }
              setImportingOverlay({
                type: 'project',
                total: paths.length,
                current: i + 1,
              })
            }

            await refreshProjects()

            if (imported.length > 0) {
              const last = imported[imported.length - 1]
              setSuccessNotification({
                count: imported.length,
                firstId: last.id,
                firstProjectName: last.name,
                failCount: errors.length > 0 ? errors.length : undefined,
              })
              window.dispatchEvent(
                new CustomEvent('app:scroll-to-project', {
                  detail: last.id,
                }),
              )
            }

            if (imported.length === 0 && errors.length > 0) {
              setErrorNotification(String(errors[0]))
            }
            setImportingOverlay(null)
          })()
        }
      }
    })

    return () => {
      unlistenPromise.then((fn) => fn())
    }
  }, [refreshProjects, setTab])

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const update = await check()
        if (update && !cancelled) {
          setUpdateModalMode('background')
          setUpdatesModalOpen(true)
        }
      } catch {
        // Silently ignore background check failures
      }
    })()
    return () => { cancelled = true }
  }, [])

  useEffect(() => {
    const dismissTimeout: { current: ReturnType<typeof setTimeout> | null } = { current: null }
    const unlistenLaunched = listen<{ id: string; name: string; version: string }>('project:launched', (event) => {
      setLaunchingProject(event.payload)
      if (dismissTimeout.current) clearTimeout(dismissTimeout.current)
      dismissTimeout.current = setTimeout(() => setLaunchingProject(null), 3000)
    })
    const unlistenExited = listen('project:exited', () => {
      if (dismissTimeout.current) clearTimeout(dismissTimeout.current)
      setLaunchingProject(null)
    })
    return () => {
      if (dismissTimeout.current) clearTimeout(dismissTimeout.current)
      unlistenLaunched.then((fn) => fn())
      unlistenExited.then((fn) => fn())
    }
  }, [])

  useEffect(() => {
    if (!errorNotification) return
    const t = setTimeout(() => setErrorNotification(null), 6000)
    return () => clearTimeout(t)
  }, [errorNotification])

  useEffect(() => {
    if (!successNotification) return
    const t = setTimeout(() => setSuccessNotification(null), 4000)
    return () => clearTimeout(t)
  }, [successNotification])

  useEffect(() => {
    const handleSwitchTab = (e: Event) => {
      const idx = (e as CustomEvent).detail as number
      const tabs: Tab[] = [
        'projects',
        'versions',
        'news',
        'templates',
        'settings',
        'changelog',
      ]
      if (tabs[idx]) setTab(tabs[idx])
    }
    const handleOpenSetting = (e: Event) => {
      const settingKey = (e as CustomEvent).detail as string
      setTab('settings')
      setHighlightSetting(settingKey)
    }
    const handleOpenProject = async (e: Event) => {
      const projectId = (e as CustomEvent).detail as string
      const proj = projectsRef.current.find((p) => p.id === projectId)
      if (proj) {
        setLaunchingProject({
          id: proj.id,
          name: proj.name,
          version: proj.godot_version,
        })
      }
      try {
        await api.openProject(projectId, true)
      } catch (_err) {
        setLaunchingProject(null)
      }
    }
    const handleSwitchWorkspace = (e: Event) => {
      const id = (e as CustomEvent).detail as string
      switchWorkspace(id)
    }
    const handleShowShortcuts = () => setShowShortcuts(true)
    const handleCheckUpdates = () => {
      setUpdateModalMode('manual')
      setUpdatesModalOpen(true)
    }
  const handleReportBug = () => setBugReportOpen(true)

    window.addEventListener('app:switch-tab', handleSwitchTab)
    window.addEventListener('app:new-project-request', requestNewProject)
    window.addEventListener('app:import-project-request', requestImportProject)
    window.addEventListener('app:scan-projects-request', requestScanProjects)
    window.addEventListener('app:import-version-request', requestImportVersion)
    window.addEventListener('app:sync-templates-request', requestSyncTemplates)
    window.addEventListener(
      'app:create-workspace-request',
      openCreateWorkspace,
    )
    window.addEventListener('app:open-project', handleOpenProject)
    window.addEventListener('app:open-setting', handleOpenSetting)
    window.addEventListener('app:switch-workspace', handleSwitchWorkspace)
    window.addEventListener('app:show-shortcuts', handleShowShortcuts)
    window.addEventListener('app:check-updates', handleCheckUpdates)
    window.addEventListener('app:report-bug', handleReportBug)

    return () => {
      window.removeEventListener('app:switch-tab', handleSwitchTab)
      window.removeEventListener('app:new-project-request', requestNewProject)
      window.removeEventListener(
        'app:import-project-request',
        requestImportProject,
      )
      window.removeEventListener(
        'app:scan-projects-request',
        requestScanProjects,
      )
      window.removeEventListener(
        'app:create-workspace-request',
        openCreateWorkspace,
      )
      window.removeEventListener(
        'app:import-version-request',
        requestImportVersion,
      )
      window.removeEventListener(
        'app:sync-templates-request',
        requestSyncTemplates,
      )
      window.removeEventListener('app:open-project', handleOpenProject)
      window.removeEventListener('app:open-setting', handleOpenSetting)
      window.removeEventListener(
        'app:switch-workspace',
        handleSwitchWorkspace,
      )
      window.removeEventListener('app:show-shortcuts', handleShowShortcuts)
      window.removeEventListener('app:check-updates', handleCheckUpdates)
      window.removeEventListener('app:report-bug', handleReportBug)
    }
  }, [
    requestNewProject,
    requestImportProject,
    requestScanProjects,
    requestImportVersion,
    requestSyncTemplates,
    openCreateWorkspace,
    switchWorkspace,
  ])

  useKeyboardShortcuts(
    {
      onNewProject: requestNewProject,
      onOpenSettings: () => setTab('settings'),
      onSwitchTab: (i: number) => {
        const tabs: Tab[] = ['projects', 'versions', 'news', 'templates']
        if (tabs[i]) setTab(tabs[i])
      },
      onCommandPalette: () => setCommandPaletteOpen((o) => !o),
      onEscape: () => {
        setGitSidebarProject(null)
        setCommandPaletteOpen(false)
        setShowShortcuts(false)
      },
    },
    paletteKey,
  )

  const toggleCollapsed = () => {
    setCollapsed((prev) => {
      const next = !prev
      try {
        localStorage.setItem(SIDEBAR_COLLAPSED_KEY, next ? '1' : '0')
      } catch {}
      return next
    })
  }

  const displayWidth = collapsed ? sidebarCollapsedWidth : sidebarExpandedWidth

  return (
    <div className="h-screen w-screen flex flex-col bg-base text-ink font-body">
      <div className="relative flex-1 flex min-h-0">
        <aside
          className={`group relative border-r border-line flex flex-col p-4 gap-1 bg-surface/40 transition-[width] duration-200 ease-out ${
            collapsed ? 'items-center' : ''
          }`}
          style={{
            width: displayWidth,
            paddingTop: 'calc(2.5rem + 1rem)',
            marginTop: '-0.5rem',
          }}
        >
          <nav
            className={`flex flex-col gap-1.5 mt-3 w-full ${collapsed ? 'items-center' : ''}`}
          >
            {NAV_ITEMS.map(({ tab: t, label, icon: Icon }) => {
              const active = tab === t
              const btn = (
                <button
                  key={t}
                  onClick={() => setTab(t)}
                  aria-label={label}
                  className={`focus-ring cursor-pointer icon-wiggle relative flex items-center gap-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                    collapsed
                      ? 'w-11 h-11 justify-center px-0'
                      : 'w-full pl-4 pr-3'
                  } ${active ? 'text-ink' : 'text-muted hover:text-ink hover:bg-raised/60'}`}
                >
                  {active && (
                    <motion.span
                      layoutId="nav-active-pill"
                      transition={{
                        type: 'spring',
                        stiffness: 420,
                        damping: 34,
                      }}
                      className="absolute inset-0 rounded-lg bg-raised border border-line"
                    />
                  )}
                  <Icon
                    className={`relative w-4 h-4 shrink-0 ${active ? 'text-accent-bright' : ''}`}
                  />
                  {!collapsed && <span className="relative">{label}</span>}
                </button>
              )
              return collapsed ? (
                <Tooltip key={t} content={label} side="right">
                  {btn}
                </Tooltip>
              ) : (
                btn
              )
            })}
          </nav>

<div
            className={`mt-auto pt-4 border-t border-line w-full flex flex-col gap-1 ${collapsed ? 'items-center' : ''}`}
          >
            {settings.workspaces_enabled && (
              <WorkspaceSwitcher collapsed={collapsed} />
            )}

            {!collapsed && (
              <div className="w-full px-3 mt-2 mb-1">
                <button
                  onClick={() => setCommandPaletteOpen(true)}
                  className="focus-ring cursor-pointer w-full flex items-center gap-2 px-3 py-1.5 rounded-lg border border-dashed border-line/50 text-[10px] font-medium text-muted/50 hover:text-muted hover:border-line hover:bg-raised/30 transition-colors"
                >
                  <kbd className="font-mono text-[9px] px-1 py-0.5 rounded bg-raised border border-line">
                    {navigator.platform.includes('Mac') ? `⌘${paletteKey.toUpperCase()}` : `Ctrl+${paletteKey.toUpperCase()}`}
                  </kbd>
                  <span>Quick commands</span>
                </button>
              </div>
            )}            {(() => {
              const navButton = (t: Tab, label: string, Icon: typeof IconGear) => {
                const active = tab === t
                const btn = (
                  <button
                    key={t}
                    onClick={() => setTab(t)}
                    aria-label={label}
                    className={`focus-ring cursor-pointer icon-wiggle relative flex items-center gap-3 text-left py-2.5 rounded-lg text-sm font-medium transition-colors ${collapsed ? 'w-11 h-11 justify-center px-0' : 'w-full pl-4 pr-3'} ${active ? 'text-ink' : 'text-muted hover:text-ink hover:bg-raised/60'}`}
                  >
                    {active && (
                      <motion.span
                        layoutId="nav-active-pill"
                        transition={{ type: 'spring', stiffness: 420, damping: 34 }}
                        className="absolute inset-0 rounded-lg bg-raised border border-line"
                      />
                    )}
                    <Icon className={`relative w-4 h-4 shrink-0 ${active ? 'text-accent-bright' : ''}`} />
                    {!collapsed && <span className="relative">{label}</span>}
                  </button>
                )
                return collapsed ? (
                  <Tooltip key={t} content={label} side="right">
                    {btn}
                  </Tooltip>
                ) : (
                  btn
                )
              }
              return (
                <>
                  {navButton('changelog', 'Changelog', IconBookOpen)}
                  {navButton('settings', 'Settings', IconGear)}
                </>
              )
            })()}

          </div>
          <div className="absolute -right-4 top-1/2 -translate-y-1/2 z-20">
              <button
                onClick={toggleCollapsed}
                aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                className="focus-ring cursor-pointer w-8 h-8 flex items-center justify-center rounded-full bg-surface border border-line text-muted hover:text-ink hover:border-accent-dim transition-opacity opacity-0 group-hover:opacity-100 shadow-sm"
              >
                {collapsed ? (
                  <IconChevronsRight className="w-5 h-5" />
                ) : (
                  <IconChevronsLeft className="w-5 h-5" />
                )}
              </button>
          </div>
        </aside>

        <main className="flex-1 overflow-y-auto relative">
          <AnimatePresence
            mode="wait"
            onExitComplete={() => {
              if (pendingActionRef.current) {
                const action = pendingActionRef.current
                pendingActionRef.current = null
                window.dispatchEvent(new CustomEvent(`app:${action}`))
              }
            }}
          >
            <motion.div
              key={tab}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
            >
              {tab === 'projects' ? (
                <ProjectsView
                  key={activeId}
                  onShowGitSidebar={(p, s) => setGitSidebarProject({ project: p, gitStatus: s })}
                />
              ) : tab === 'versions' ? (
                <VersionsView />
              ) : tab === 'news' ? (
                <NewsView />
              ) : tab === 'templates' ? (
                <TemplatesView />
              ) : tab === 'changelog' ? (
                <ChangelogView />
              ) : (
                <SettingsView
                  key={activeId}
                  highlightSetting={highlightSetting}
                  onHighlightDone={() => setHighlightSetting(null)}
                />
              )}
            </motion.div>
          </AnimatePresence>

        </main>

        {/* Git sidebar overlay + backdrop */}
        <AnimatePresence>
          {gitSidebarProject && (
            <motion.div
              key="backdrop"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.15 }}
              onClick={() => setGitSidebarProject(null)}
              className="absolute inset-0 z-20 bg-black/40"
            />
          )}
          {gitSidebarProject && (
            <motion.aside
              key={gitSidebarProject.project.id}
              initial={{ x: 380 }}
              animate={{ x: 0 }}
              exit={{ x: 380 }}
              transition={{ type: 'spring', stiffness: 350, damping: 30 }}
              className="absolute right-0 top-0 bottom-0 z-30 w-[380px] border-l border-line bg-surface shadow-2xl shadow-black/30 flex flex-col overflow-hidden"
            >
              <GitSidebar
                project={gitSidebarProject.project}
                gitStatus={gitSidebarProject.gitStatus}
                onClose={() => setGitSidebarProject(null)}
                onRefresh={() => refreshProjects()}
              />
            </motion.aside>
          )}
        </AnimatePresence>
      </div>

      <div className="absolute top-0 left-0 right-0 z-20 pointer-events-none">
        <div className="pointer-events-auto">
          <TitleBar />
        </div>
      </div>

      {splashPhase !== 'done' && <SplashScreen phase={splashPhase} />}

      <AnimatePresence>
        {splashPhase === 'done' && showTips && (
          <OnboardingTips
            onDismiss={() => {
              setShowTips(false)
              try {
                localStorage.setItem('godothub_tips_shown', '1')
              } catch {}
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {commandPaletteOpen && (
          <CommandPalette
            onClose={() => setCommandPaletteOpen(false)}
            currentTab={tab}
            projects={projects}
            installedVersions={installed}
            workspaces={workspaces}
            activeWorkspaceId={activeId}
            paletteKey={paletteKey}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {createWorkspaceOpen && (
          <CreateWorkspaceModal
            onClose={() => setCreateWorkspaceOpen(false)}
            onCreate={async (name, icon, color) => {
              await createWorkspace(name, icon, color)
              setCreateWorkspaceOpen(false)
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {bugReportOpen && (
          <BugReportModal
            onClose={() => setBugReportOpen(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {updatesModalOpen && (
          <CheckForUpdatesModal
            mode={updateModalMode}
            onClose={() => setUpdatesModalOpen(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showShortcuts && (
          <ShortcutCheatsheet
            onClose={() => setShowShortcuts(false)}
            paletteKey={paletteKey}
          />
        )}
      </AnimatePresence>

      {/* Drag & Drop overlay */}
      <AnimatePresence>
        {dragOver && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.12 }}
            className="fixed inset-0 z-100 flex items-center justify-center pointer-events-none"
          >
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="absolute inset-0 bg-black/60"
            />

            <motion.div
              initial={{ scale: 0.92, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.92, opacity: 0 }}
              transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
              className={`relative z-10 flex flex-col items-center gap-5 px-14 py-11 rounded-2xl bg-surface border-2 border-dashed shadow-2xl ${
                dragType === 'version'
                  ? 'border-amber/60'
                  : 'border-accent/60'
              }`}
            >
              <div
                className={`w-16 h-16 rounded-full flex items-center justify-center ${
                  dragType === 'version'
                    ? 'bg-amber/10'
                    : 'bg-accent/10'
                }`}
              >
                {dragType === 'version' ? (
                  <IconDownload className="w-7 h-7 text-amber" />
                ) : (
                  <IconFolderPlus className="w-7 h-7 text-accent-bright" />
                )}
              </div>
              <div className="text-center">
                <p className="text-lg font-semibold text-ink">
                  {dragType === 'version'
                    ? 'Drop your Godot .zip file'
                    : 'Drop your Godot project folders'}
                </p>
                <p className="text-sm mt-1">
                  {dragType === 'version' ? (
                    <span className="text-amber">
                      The archive will be extracted and registered automatically
                    </span>
                  ) : (
                    <span className="text-muted">
                      Each folder must contain a{' '}
                      <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-raised border border-line">
                        project.godot
                      </code>{' '}
                      file
                    </span>
                  )}
                </p>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Success notification toast */}
      <AnimatePresence>
        {successNotification && (
          <motion.div
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="fixed bottom-6 left-1/2 -translate-x-1/2 z-110 flex items-center gap-3 px-5 py-3 rounded-xl bg-mint/10 border border-mint/30 shadow-lg backdrop-blur-md max-w-lg"
          >
            <div className="w-8 h-8 rounded-full bg-mint/15 flex items-center justify-center shrink-0">
              <IconCheck className="w-4 h-4 text-mint" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-mint uppercase tracking-wide">
                {successNotification.count === 1
                  ? 'Imported successfully'
                  : `Imported ${successNotification.count} projects`}
              </p>
              <p className="text-sm text-ink mt-0.5 truncate">
                {successNotification.count === 1
                  ? successNotification.firstProjectName
                  : successNotification.failCount && successNotification.failCount > 0
                    ? `${successNotification.count} succeeded, ${successNotification.failCount} failed`
                    : `All ${successNotification.count} project folders imported`}
              </p>
            </div>
            <button
              onClick={() => setSuccessNotification(null)}
              className="focus-ring cursor-pointer shrink-0 p-1.5 rounded-lg text-muted hover:text-ink hover:bg-black/10 transition-colors"
              aria-label="Dismiss"
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Launch overlay */}
      <AnimatePresence>
        {launchingProject && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.15 }}
            className="fixed inset-0 z-50 flex items-center justify-center"
          >
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ scale: 0.92, opacity: 0, y: 10 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.92, opacity: 0, y: 10 }}
              transition={{ type: 'spring', stiffness: 380, damping: 30 }}
              className="relative z-10 bg-surface border border-line rounded-2xl shadow-2xl shadow-black/40 p-8 w-full max-w-sm flex flex-col items-center gap-5 text-center"
            >
              {/* Spinning indicator */}
              <div className="relative w-16 h-16">
                <motion.div
                  className="absolute inset-0 rounded-full border-2 border-accent/30"
                  animate={{ rotate: 360 }}
                  transition={{ duration: 2, repeat: Infinity, ease: 'linear' }}
                >
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-2 h-2 rounded-full bg-accent-bright" />
                </motion.div>
                <div className="absolute inset-3 rounded-full bg-accent/10 flex items-center justify-center">
                  <IconPlay className="w-5 h-5 text-accent-bright" />
                </div>
              </div>

              <div>
                <h3 className="font-display font-semibold text-lg text-ink">
                  Starting…
                </h3>
                <p className="text-sm text-muted mt-1">
                  {launchingProject.name}
                </p>
              </div>

              {launchingProject.version && (
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-accent/10 border border-accent/20 text-[11px] font-medium text-accent-bright">
                  <IconPlay className="w-3 h-3" />
                  Godot {launchingProject.version}
                </span>
              )}

              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setConfirmingStop(true)}
                className="focus-ring cursor-pointer flex items-center gap-2 px-5 py-2.5 rounded-lg border border-danger/40 text-danger hover:bg-danger/10 hover:border-danger text-sm font-medium transition-colors"
              >
                <IconX className="w-4 h-4" />
                Stop Launch
              </motion.button>

              <p className="text-[10px] text-muted/50">
                Godot is launching in the background. This overlay will auto-dismiss.
              </p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Stop confirm dialog */}
      <AnimatePresence>
        {confirmingStop && launchingProject && (
          <ConfirmDialog
            title="Stop Launch"
            description={`Are you sure you want to cancel launching ${launchingProject.name}? Godot may already be starting up.`}
            confirmLabel="Stop"
            variant="danger"
            onConfirm={() => {
              api.stopProject(launchingProject.id).catch(() => {})
              setLaunchingProject(null)
              setConfirmingStop(false)
            }}
            onCancel={() => setConfirmingStop(false)}
          />
        )}
      </AnimatePresence>

      {/* Import overlay for drag-drop */}
      <AnimatePresence>
        {importingOverlay && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <div className="bg-surface border border-line rounded-2xl px-8 py-6 flex flex-col items-center gap-3 min-w-64">
              <IconRefresh className="w-6 h-6 animate-spin text-accent" />
              <p className="text-sm font-medium text-ink">
                {importingOverlay.type === 'version'
                  ? 'Importing version…'
                  : importingOverlay.total > 1
                    ? `Importing project ${importingOverlay.current}/${importingOverlay.total}…`
                    : 'Importing project…'}
              </p>
              {importingOverlay.total > 1 && (
                <div className="h-1.5 w-full rounded-full bg-line overflow-hidden">
                  <div
                    className="h-full bg-accent transition-all duration-200"
                    style={{
                      width: `${(importingOverlay.current / importingOverlay.total) * 100}%`,
                    }}
                  />
                </div>
              )}
              <button
                onClick={() => setImportingOverlay(null)}
                className="focus-ring cursor-pointer text-xs text-muted hover:text-ink transition-colors mt-1"
              >
                Resume in background
              </button>
            </div>
          </div>
        )}
      </AnimatePresence>

      {/* Error notification toast */}
      <AnimatePresence>
        {errorNotification && (
          <motion.div
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="fixed bottom-6 left-1/2 -translate-x-1/2 z-110 flex items-center gap-3 px-5 py-3 rounded-xl bg-danger/10 border border-danger/30 shadow-lg backdrop-blur-md max-w-lg"
          >
            <div className="w-8 h-8 rounded-full bg-danger/15 flex items-center justify-center shrink-0">
              <IconX className="w-4 h-4 text-danger" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-danger uppercase tracking-wide">
                Import failed
              </p>
              <p className="text-sm text-ink mt-0.5">
                {errorNotification}
              </p>
            </div>
            <button
              onClick={() => setErrorNotification(null)}
              className="focus-ring cursor-pointer shrink-0 p-1.5 rounded-lg text-muted hover:text-ink hover:bg-black/10 transition-colors"
              aria-label="Dismiss"
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default function App() {
  const { settings, update, loaded } = useSettings()
  const { loaded: workspacesLoaded } = useWorkspaces()

  if (!loaded || !workspacesLoaded) {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-base text-muted text-sm">
        Loading…
      </div>
    )
  }

  if (!settings.setup_complete) {
    return <OnboardingView settings={settings} onComplete={update} />
  }

  return (
    <GodotVersionsProvider>
      <AppContent />
    </GodotVersionsProvider>
  )
}
