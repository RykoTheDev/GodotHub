import { useCallback, useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { useProjectsContext } from './hooks/projectsContext'
import { useGodotVersionsContext } from './hooks/godotVersionsContext'
import { useKeyboardShortcuts } from './hooks/useKeyboardShortcuts'
import { api } from './lib/api'
import { viewTransition } from './lib/motion'
import type { GitStatus, Project } from './types'

import { Sidebar } from './components/ui/Sidebar'
import { GitSidebar } from './components/git/GitSidebar'
import { Titlebar } from './components/titlebar/Titlebar'
import { OverlayScrollArea } from './components/reusables/OverlayScrollArea'
import { ConfirmDialog } from './components/modals/ConfirmDialog'
import { CreateProjectModal } from './components/modals/CreateProjectModal'
import { BugReportModal } from './components/modals/BugReportModal'
import { CheckForUpdatesModal } from './components/modals/CheckForUpdatesModal'
import { CommandPalette } from './components/modals/CommandPalette'
import { ToastContainer } from './components/reusables/ToastContainer'
import { SplashScreen, type SplashPhase } from './components/reusables/SplashScreen'
import { ProjectsView } from './views/ProjectsView'
import { VersionsView } from './views/VersionsView'
import { TemplatesView } from './views/TemplatesView'
import { SettingsView } from './views/SettingsView'
import { UpdatesView } from './views/UpdatesView'
import { ChangelogView } from './views/ChangelogView'
import { NewsView } from './views/NewsView'
import { AssetStoreView } from './views/AssetStoreView'
import { DashboardView } from './views/DashboardView'
import { useSettings } from './hooks/useSettings'
import { useCategoriesContext } from './hooks/categoriesContext'
import { OnboardingView as Onboarding } from './views/OnboardingView'
import { useTauriEvent } from './lib/useTauriEvent'
import { useDiscordRpc } from './hooks/useDiscordRpc'
import { ChangelogBadgeProvider } from './hooks/useChangelogBadge'
import { ScreenReaderAnnouncer } from './lib/screenReader'
import { relaunch } from '@tauri-apps/plugin-process'
import {
  clearUiSwitchToSettings,
  markSplashConsumed,
  shouldOpenSettingsAfterSwitch,
  shouldShowSplash,
} from './lib/uiTransition'
import {
  IconBell,
  IconBookOpen,
  IconCloudArrowDown,
  IconFolder,
  IconGear,
  IconHouse,
  IconNews,
  IconRocket,
  IconStore,
} from './lib/icons'

const TABS = [
  { id: 'dashboard', navKey: 'dashboard', icon: IconHouse, hidden: true },
  { id: 'projects', navKey: 'projects', icon: IconFolder },
  { id: 'versions', navKey: 'versions', icon: IconCloudArrowDown },
  { id: 'templates', navKey: 'templates', icon: IconRocket },
  { id: 'asset-store', navKey: 'asset_store', icon: IconStore },
  { id: 'news', navKey: 'news', icon: IconNews },
  { id: 'settings', navKey: 'settings', icon: IconGear, footer: true },
  { id: 'updates', navKey: 'updates', icon: IconBell, footer: true },
  { id: 'changelog', navKey: 'changelog', icon: IconBookOpen, footer: true, iconOnly: true },
] as const

export type NewTab = (typeof TABS)[number]['id']

export function App() {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings, loaded: settingsLoaded, update: updateSettings } = useSettings()
  const cardLayout = settings.card_layout ?? true
  const { projects, refresh: refreshProjects } = useProjectsContext()
  const projectsRef = useRef(projects)
  projectsRef.current = projects
  const [splashPhase, setSplashPhase] = useState<SplashPhase | 'done'>(() =>
    shouldShowSplash() ? 'enter' : 'done',
  )
  const [uiSwitchIntent] = useState(() => shouldOpenSettingsAfterSwitch())
  const [tab, setTab] = useState<NewTab>(uiSwitchIntent ? 'settings' : 'projects')
  const landingTabRef = useRef<string | null>(null)

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
  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false)
  const [bugReportOpen, setBugReportOpen] = useState(false)
  const [createProjectOpen, setCreateProjectOpen] = useState(false)
  const [updatesModalOpen, setUpdatesModalOpen] = useState(false)
  const [updatesModalMode, setUpdatesModalMode] = useState<
    'manual' | 'preview'
  >('manual')
  const { installed } = useGodotVersionsContext()
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
        alert(String(err))
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
    if (splashPhase === 'enter') {
      const t = setTimeout(() => setSplashPhase('fly'), 1200)
      return () => clearTimeout(t)
    }
    if (splashPhase === 'fly') {
      const t = setTimeout(() => setSplashPhase('fade'), 600)
      return () => clearTimeout(t)
    }
    if (splashPhase === 'fade') {
      const t = setTimeout(() => {
        setSplashPhase('done')
      }, 450)
      return () => clearTimeout(t)
    }
  }, [splashPhase])

  useEffect(() => {
    const handleOpenSetting = () => setTab('settings')
    window.addEventListener('app:open-setting', handleOpenSetting)
    return () =>
      window.removeEventListener('app:open-setting', handleOpenSetting)
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
        const tabs: NewTab[] = ['projects', 'versions', 'news', 'templates']
        if (tabs[i]) setTab(tabs[i])
      },
      onCommandPalette: () => setCommandPaletteOpen((o) => !o),
      onRestart: () => {
        void relaunch()
      },
      onEscape: () => {
        setGitSidebarProject(null)
        setCommandPaletteOpen(false)
        setBugReportOpen(false)
      },
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

  const tabs = TABS.filter((tab) => !('hidden' in tab) || !tab.hidden).map((tab) => ({
    id: tab.id,
    label: t(tab.navKey),
    icon: tab.icon,
    footer: 'footer' in tab ? tab.footer : undefined,
    iconOnly: 'iconOnly' in tab ? tab.iconOnly : undefined,
  }))

  const renderView = () => {
    switch (tab) {
      case 'dashboard':
        return <DashboardView connected={!cardLayout} active={tab === 'dashboard'} />
      case 'projects':
        return (
          <ProjectsView
            onOpenSettings={() => setTab('settings')}
            connected={!cardLayout}
            gitSidebarOpen={!!gitSidebarProject}
          />
        )
      case 'versions':
        return (
          <VersionsView
            onOpenSettings={() => setTab('settings')}
            connected={!cardLayout}
          />
        )
      case 'news':
        return <NewsView connected={!cardLayout} />
      case 'updates':
        return <UpdatesView connected={!cardLayout} />
      case 'templates':
        return (
          <TemplatesView
            onOpenSettings={() => setTab('settings')}
            connected={!cardLayout}
          />
        )
      case 'asset-store':
        return <AssetStoreView connected={!cardLayout} />
      case 'settings':
        return <SettingsView connected={!cardLayout} />
      case 'changelog':
        return <ChangelogView connected={!cardLayout} />
    }
  }

  if (settingsLoaded && !settings.setup_complete) {
    return (
      <Onboarding
        settings={settings}
        onComplete={updateSettings}
      />
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
    <ChangelogBadgeProvider>
    <div className="new-ui h-screen w-screen flex flex-col bg-base text-ink font-body">
      <ScreenReaderAnnouncer enabled={settings.screen_reader_announcements} />
      <ToastContainer />
      <Titlebar />

      <div
        className={`relative flex-1 flex min-h-0 ${
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

        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={tab}
            className="flex-1 min-w-0 h-full"
            {...viewTransition(
              settings.view_entrance,
              settings.animation_intensity,
            )}
          >
            {tab === 'dashboard' ||
            tab === 'projects' ||
            tab === 'settings' ||
            tab === 'versions' ||
            tab === 'news' ||
            tab === 'asset-store' ||
            tab === 'templates' ||
            tab === 'updates' ||
            tab === 'changelog' ? (
              renderView()
            ) : (
              <main
                className={`flex-1 min-w-0 relative overflow-hidden h-full ${
                  cardLayout ? 'rounded-card bg-raised' : 'bg-raised'
                }`}
              >
                <OverlayScrollArea
                  className="absolute inset-0"
                  hideThumb={!settings.show_scrollbars}
                >
                  <div className="min-h-full px-6 py-4">
                    {renderView()}
                  </div>
                </OverlayScrollArea>
              </main>
            )}
          </motion.div>
        </AnimatePresence>

        <AnimatePresence>
          {gitSidebarProject && (
            <>
              <motion.div
                key="git-backdrop"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
                className="absolute inset-0 z-40 bg-black/30"
                onClick={() => setGitSidebarProject(null)}
              />
              <motion.aside
                key="git-panel"
                initial={{ x: '100%', opacity: 0 }}
                animate={{
                  x: 0,
                  opacity: 1,
                  transition: { type: 'spring', stiffness: 350, damping: 32 },
                }}
                exit={{
                  x: '100%',
                  opacity: 0,
                  transition: { duration: 0.15, ease: 'easeOut' },
                }}
                className="absolute top-2 right-2 bottom-2 z-50 w-80 overflow-hidden rounded-xl shadow-2xl shadow-black/40"
              >
                <GitSidebar
                  project={gitSidebarProject.project}
                  gitStatus={gitSidebarProject.gitStatus}
                  onClose={() => setGitSidebarProject(null)}
                  onRefresh={() => refreshProjects()}
                  connected={!cardLayout}
                />
              </motion.aside>
            </>
          )}
        </AnimatePresence>

      </div>

      <AnimatePresence>
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
      </AnimatePresence>

      <AnimatePresence>
        {commandPaletteOpen && (
          <CommandPalette
            onClose={() => setCommandPaletteOpen(false)}
            currentTab={tab}
            onNavigate={(id) => setTab(id as NewTab)}
            projects={projects}
            installedVersions={installed}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
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
      </AnimatePresence>

      <AnimatePresence>
        {bugReportOpen && <BugReportModal onClose={() => setBugReportOpen(false)} />}
      </AnimatePresence>

      <AnimatePresence>
        {updatesModalOpen && (
          <CheckForUpdatesModal
            mode={updatesModalMode}
            onClose={() => setUpdatesModalOpen(false)}
          />
        )}
      </AnimatePresence>
    </div>
    {splashPhase !== 'done' && <SplashScreen phase={splashPhase} />}
    </ChangelogBadgeProvider>
  )
}
