import {
  useEffect,
  useRef,
  useState,
  type ComponentType,
  type ReactNode,
} from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { Toggle } from '../components/ui/Toggle'
import { Segmented } from '../components/reusables/Segmented'
import { Slider } from '../components/ui/Slider'
import { viewTransition } from '../lib/motion'
import { formatLocaleDateTime, formatLocaleTime } from '../lib/locale'
import { useSettings } from '../hooks/useSettings'
import { openUrl } from '@tauri-apps/plugin-opener'
import { useProjectsContext } from '../hooks/projectsContext'
import { useCategoriesContext } from '../hooks/categoriesContext'
import { useWorkspaces } from '../hooks/useWorkspaces'
import { useAppVersion } from '../hooks/useAppVersion'
import { useContributors } from '../hooks/useContributors'
import { ContributorPRsModal } from '../components/ContributorPRsModal'

import { api } from '../lib/api'
import {
  ACCENT_PRESETS_DARK,
  ACCENT_PRESETS_LIGHT,
  BG_PRESETS_DARK,
  BG_PRESETS_LIGHT,
  DEFAULT_BG,
  DEFAULT_BG_LIGHT,
  DEFAULT_RAISED_CONTRAST,
  LIGHT_THEME_PRESETS,
  DARK_THEME_PRESETS,
  customThemeDefaults,
  getThemePreset,
  isDarkColor,
  resolveThemeMode,
} from '../lib/colors'
import { ColorSwatchPicker } from '../components/ui/ColorSwatchPicker'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { DirList } from '../components/reusables/DirList'

import { KeyRecorder } from '../components/ui/KeyRecorder'
import { matchesSearch, useSectionSearch } from '../hooks/useSectionSearch'
import { Dropdown } from '../components/ui/Dropdown'
import { SearchBar } from '../components/ui/SearchBar'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { CheckForUpdatesModal } from '../components/modals/CheckForUpdatesModal'
import { BugReportModal } from '../components/modals/BugReportModal'
import { ThemePresetsModal } from '../components/modals/ThemePresetsModal'
import { RestoreProgressModal } from '../components/modals/RestoreProgressModal'
import { defaultCornerRadius, isMac, isWindows } from '../lib/platform'
import { relaunch } from '@tauri-apps/plugin-process'
import { flushPendingSave } from '../lib/pendingSave'
import {
  IconCheck,
  IconPalette,
  IconSun,
  IconMoon,
  IconHardDrive,
  IconGear,
  IconChevronDown,
  IconSearch,
  IconRefresh,
  IconBug,
  IconHeart,
  IconFlask,
  IconBomb,
  IconPlug,
  IconUniversalAccess,
  IconGitBranch,
  IconPlus,
  IconTrash,
  IconX,
  IconCloudArrowDown,
  IconExternalLink,
} from '../lib/icons'
import type { IconProps } from '../lib/icons'
import type { AppSettings, GitAuthState } from '../types'
import { GitAuthModal } from '../components/modals/GitAuthModal'

type SettingsCat =
  | 'appearance'
  | 'display'
  | 'storage'
  | 'behavior'
  | 'integrations'
  | 'accessibility'
  | 'advanced'
  | 'credits'

interface CatDef {
  id: SettingsCat
  icon: ComponentType<IconProps>
}

const CATEGORIES: CatDef[] = [
  { id: 'appearance', icon: IconPalette },
  { id: 'display', icon: IconSun },
  { id: 'storage', icon: IconHardDrive },
  { id: 'behavior', icon: IconGear },
  { id: 'integrations', icon: IconPlug },
  { id: 'accessibility', icon: IconUniversalAccess },
  { id: 'advanced', icon: IconFlask },
]

const DEFAULT_RADIUS = defaultCornerRadius
const DEFAULT_DENSITY = 1.05
const DEFAULT_FONT_SCALE = 1.0
const DEFAULT_PROJECT_ICON_OPACITY = 14

const LANDING_TABS: { id: string; label: string }[] = [
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'projects', label: 'Projects' },
  { id: 'versions', label: 'Versions' },
  { id: 'news', label: 'Godot News' },
]

function Subsection({
  id,
  title,
  description,
  children,
  searchText,
  query,
  onMatch,
}: {
  id: string
  title: ReactNode
  description?: string
  children: ReactNode
  searchText?: string
  query: string
  onMatch?: (id: string, matched: boolean) => void
}) {
  const matches = matchesSearch(
    query,
    typeof title === 'string' ? title : undefined,
    description,
    searchText,
  )

  useEffect(() => {
    onMatch?.(id, matches)
    return () => onMatch?.(id, false)
  }, [id, matches, onMatch])

  if (!matches) return null

  return (
    <section className="flex flex-col gap-3 rounded-item bg-overlay px-4 py-4">
      <div>
        <h3 className="text-sm font-medium text-ink">{title}</h3>
        {description && (
          <p className="text-xs text-muted mt-1 leading-relaxed">{description}</p>
        )}
      </div>
      {children}
    </section>
  )
}

function SettingRow({
  label,
  description,
  children,
  divider = false,
}: {
  label: string
  description?: string
  children: ReactNode
  divider?: boolean
}) {
  return (
    <div
      className={`flex items-center justify-between gap-4 ${
        divider ? 'pt-4 border-t border-line' : ''
      }`}
    >
      <div>
        <span className="text-xs font-medium text-muted block">{label}</span>
        {description && (
          <p className="text-[11px] text-muted mt-1 leading-relaxed">
            {description}
          </p>
        )}
      </div>
      {children}
    </div>
  )
}

export function SettingsView({ connected = false }: { connected?: boolean }) {
  const { t } = useTranslation('nav')
  const { t: ts } = useTranslation('settings')
  const { settings, update, resetToDefaults } = useSettings()
  const appVersion = useAppVersion()
  const { contributors } = useContributors()
  const [selectedContributor, setSelectedContributor] = useState<{ login: string; avatar_url: string } | null>(null)
  const { projects, refresh: refreshProjects } = useProjectsContext()
  const { refresh: refreshCategories } = useCategoriesContext()
  const { refresh: refreshWorkspaces } = useWorkspaces()
  const [cat, setCat] = useState<SettingsCat>('appearance')
  const [presetModal, setPresetModal] = useState<'light' | 'dark' | null>(null)
  const [statsBusy, setStatsBusy] = useState<'export' | 'import' | null>(null)
  const [statsMessage, setStatsMessage] = useState<string | null>(null)
  const [confirmClearStats, setConfirmClearStats] = useState(false)
  const [settingsBusy, setSettingsBusy] = useState<'export' | 'import' | null>(null)
  const [settingsMessage, setSettingsMessage] = useState<string | null>(null)
  const [wsBackupBusy, setWsBackupBusy] = useState<'export' | 'import' | null>(null)
  const [wsBackupMessage, setWsBackupMessage] = useState<string | null>(null)
  const [appBackupBusy, setAppBackupBusy] = useState<
    'export' | 'import' | null
  >(null)
  const [appBackupMessage, setAppBackupMessage] = useState<string | null>(null)
  const [syncBusy, setSyncBusy] = useState<'push' | 'pull' | null>(null)
  const [syncMessage, setSyncMessage] = useState<string | null>(null)
  const [syncUrl, setSyncUrl] = useState<string | null>(null)
  const [manualGistUrl, setManualGistUrl] = useState('')
  const [manualPullBusy, setManualPullBusy] = useState(false)
  const [showRestoreModal, setShowRestoreModal] = useState(false)
  const [cssDraft, setCssDraft] = useState(settings.custom_css)
  const [cssStatus, setCssStatus] = useState<'idle' | 'applied'>('idle')
  const [scanMessage, setScanMessage] = useState<string | null>(null)
  const [tokenTestState, setTokenTestState] = useState<
    'idle' | 'testing' | 'success' | 'warning' | 'error'
  >('idle')
  const [tokenTestMsg, setTokenTestMsg] = useState<string | null>(null)
  const tokenTestTimeout = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [confirmingReset, setConfirmingReset] = useState(false)
  const [confirmingWipe, setConfirmingWipe] = useState(false)
  const [confirmingOsDec, setConfirmingOsDec] = useState<boolean | null>(null)
  const [confirmingRestart, setConfirmingRestart] = useState(false)
  const [showUpdates, setShowUpdates] = useState(false)
  const [showBugReport, setShowBugReport] = useState(false)
  const [gitAuth, setGitAuth] = useState<GitAuthState | null>(null)
  const [gitAuthFlow, setGitAuthFlow] = useState<'github' | 'gitlab' | null>(
    null,
  )
  const [gitAuthInstance, setGitAuthInstance] = useState<{
    baseUrl: string
    clientId: string
  } | null>(null)
  const [gitlabUrl, setGitlabUrl] = useState('')
  const [gitlabClientId, setGitlabClientId] = useState('')
  const [patOpen, setPatOpen] = useState(false)
  const [patHost, setPatHost] = useState('')
  const [patUser, setPatUser] = useState('')
  const [patToken, setPatToken] = useState('')
  const [patMsg, setPatMsg] = useState<string | null>(null)
  const {
    query: searchQuery,
    setQuery: setSearchQuery,
    reportMatch,
    noResults,
    inputRef: searchRef,
    clear: clearSearch,
    reset: resetSearch,
  } = useSectionSearch()

  useEffect(() => {
    setCssDraft(settings.custom_css)
  }, [settings.custom_css])

  const [lastPushedAt, setLastPushedAt] = useState<string | null>(null)

  const autoBackupOptions = [
    { value: 0, label: ts('sync_auto_backup_off') },
    { value: 15, label: ts('sync_auto_backup_15m') },
    { value: 30, label: ts('sync_auto_backup_30m') },
    { value: 60, label: ts('sync_auto_backup_1h') },
    { value: 360, label: ts('sync_auto_backup_6h') },
    { value: 720, label: ts('sync_auto_backup_12h') },
    { value: 1440, label: ts('sync_auto_backup_24h') },
  ]

  useEffect(() => {
    api.gistSyncGetInfo().then((info) => {
      if (info) {
        setSyncUrl(info.gist_url)
        if (info.pushed_at) {
          try {
            setLastPushedAt(formatLocaleDateTime(new Date(info.pushed_at)))
          } catch {}
        }
      }
    })
  }, [])

  const [lastAutoBackup, setLastAutoBackup] = useState<string | null>(null)
  const autoBackupRef = useRef<ReturnType<typeof setInterval> | null>(null)

  useEffect(() => {
    if (autoBackupRef.current) {
      clearInterval(autoBackupRef.current)
      autoBackupRef.current = null
    }
    const minutes = settings.auto_backup_interval_minutes
    if (minutes <= 0) return
    autoBackupRef.current = setInterval(async () => {
      try {
        const res = await api.gistSyncPush()
        setSyncUrl(res.gist_url)
        setLastAutoBackup(formatLocaleTime(new Date()))
      } catch (e) {
        console.error('[auto-backup] failed:', e)
      }
    }, minutes * 60 * 1000)
    return () => {
      if (autoBackupRef.current) clearInterval(autoBackupRef.current)
    }
  }, [settings.auto_backup_interval_minutes])

  const handleApplyCss = () => {
    update({ ...settings, custom_css: cssDraft })
    setCssStatus('applied')
    setTimeout(() => setCssStatus('idle'), 1500)
  }

  const handleExportStats = async () => {
    setStatsBusy('export')
    setStatsMessage(null)
    try {
      const path = await api.pickSavePath('godothub-time-stats.json')
      if (!path) return
      await api.exportProjectStats(path)
      setStatsMessage(ts('stats_exported'))
    } catch (e) {
      setStatsMessage(String(e))
    } finally {
      setStatsBusy(null)
    }
  }

  const handleImportStats = async () => {
    setStatsBusy('import')
    setStatsMessage(null)
    try {
      const path = await api.pickDataFile()
      if (!path) return
      const count = await api.importProjectStats(path)
      await refreshProjects()
      setStatsMessage(ts('stats_imported', { count }))
    } catch (e) {
      setStatsMessage(String(e))
    } finally {
      setStatsBusy(null)
    }
  }

  const handleClearStats = async () => {
    setConfirmClearStats(false)
    setStatsBusy('import')
    setStatsMessage(null)
    try {
      await api.clearTimeStats()
      await refreshProjects()
      setStatsMessage(ts('stats_cleared'))
    } catch (e) {
      setStatsMessage(String(e))
    } finally {
      setStatsBusy(null)
    }
  }

  const handleExportSettings = async () => {
    setSettingsBusy('export')
    setSettingsMessage(null)
    try {
      const path = await api.pickSavePath('godothub-settings.json')
      if (!path) return
      await api.exportSettings(path)
      setSettingsMessage(ts('settings_exported'))
    } catch (e) {
      setSettingsMessage(String(e))
    } finally {
      setSettingsBusy(null)
    }
  }

  const handleImportSettings = async () => {
    setSettingsBusy('import')
    setSettingsMessage(null)
    try {
      const path = await api.pickDataFile()
      if (!path) return
      const imported = await api.importSettings(path)
      await update(imported)
      await refreshProjects()
      setSettingsMessage(ts('settings_imported'))
    } catch (e) {
      setSettingsMessage(String(e))
    } finally {
      setSettingsBusy(null)
    }
  }

  const handleExportWorkspace = async () => {
    setWsBackupBusy('export')
    setWsBackupMessage(null)
    try {
      const path = await api.pickSavePath('godothub-workspace-backup.json')
      if (!path) return
      await api.exportWorkspaceBackup(path)
      setWsBackupMessage(ts('workspace_backup_exported'))
    } catch (e) {
      setWsBackupMessage(String(e))
    } finally {
      setWsBackupBusy(null)
    }
  }

  const handleImportWorkspace = async () => {
    setWsBackupBusy('import')
    setWsBackupMessage(null)
    try {
      const path = await api.pickDataFile()
      if (!path) return
      const imported = await api.importWorkspaceBackup(path)
      await update(imported)
      await refreshProjects()
      await refreshCategories()
      window.dispatchEvent(new Event('app:refresh-templates'))
      setWsBackupMessage(ts('workspace_backup_imported'))
    } catch (e) {
      setWsBackupMessage(String(e))
    } finally {
      setWsBackupBusy(null)
    }
  }

  const handleExportApp = async () => {
    setAppBackupBusy('export')
    setAppBackupMessage(null)
    try {
      const path = await api.pickSavePath('godothub-full-backup.json')
      if (!path) return
      await api.exportAppBackup(path)
      setAppBackupMessage(ts('app_backup_exported'))
    } catch (e) {
      setAppBackupMessage(String(e))
    } finally {
      setAppBackupBusy(null)
    }
  }

  const handleImportApp = async () => {
    setAppBackupBusy('import')
    setAppBackupMessage(null)
    try {
      const path = await api.pickDataFile()
      if (!path) return
      const imported = await api.importAppBackup(path)
      await update(imported)
      await refreshProjects()
      await refreshCategories()
      await refreshWorkspaces()
      window.dispatchEvent(new Event('app:refresh-templates'))
      setAppBackupMessage(ts('app_backup_imported'))
    } catch (e) {
      setAppBackupMessage(String(e))
    } finally {
      setAppBackupBusy(null)
    }
  }

  const handleSyncPush = async () => {
    setSyncBusy('push')
    setSyncMessage(null)
    try {
      const res = await api.gistSyncPush()
      setSyncUrl(res.gist_url)
      setLastPushedAt(formatLocaleDateTime(new Date(res.pushed_at)))
      setSyncMessage(ts('sync_push_done'))
    } catch (e) {
      setSyncMessage(String(e))
    } finally {
      setSyncBusy(null)
    }
  }

  const handleSyncPull = () => {
    setShowRestoreModal(true)
  }

  const handleManualPull = async () => {
    if (!manualGistUrl.trim()) return
    setManualPullBusy(true)
    try {
      await api.gistSyncSaveGistUrl(manualGistUrl.trim())
      const info = await api.gistSyncGetInfo()
      if (info) setSyncUrl(info.gist_url)
      setShowRestoreModal(true)
    } catch (e) {
      setSyncMessage(String(e))
    } finally {
      setManualPullBusy(false)
    }
  }

  const selectCustom = () =>
    update({
      ...settings,
      theme_preset: 'custom',
      ...customThemeDefaults(resolveThemeMode(settings.theme_mode)),
    })

  const setThemeMode = (mode: 'dark' | 'light' | 'system') => {
    const resolved = resolveThemeMode(mode)
    const targetDark = resolved === 'dark'
    const bg = isDarkColor(settings.background_color) === targetDark
      ? settings.background_color
      : targetDark ? DEFAULT_BG : DEFAULT_BG_LIGHT
    update({ ...settings, theme_mode: mode, background_color: bg })
  }

  const selectPreset = (id: string) => {
    if (id === settings.theme_preset) return
    if (id === 'custom') {
      const defaults = customThemeDefaults(resolveThemeMode(settings.theme_mode))
      update({ ...settings, theme_preset: id, ...defaults })
    } else {
      const preset = getThemePreset(id)
      if (preset) update({ ...settings, theme_preset: id, theme_mode: preset.mode })
    }
  }

  const runScan = async () => {
    setScanMessage(ts('scanning'))
    const [projects, versions] = await Promise.all([
      settings.project_scan_dirs.length
        ? api.scanForProjects(settings.project_scan_dirs, settings.scan_depth)
        : Promise.resolve([]),
      settings.version_scan_dirs.length
        ? api.scanForVersions(settings.version_scan_dirs, settings.scan_depth)
        : Promise.resolve([]),
    ])
    setScanMessage(
      ts('scan_result', { projects: projects.length, versions: versions.length }),
    )
    await refreshProjects()
  }

  const resetThemeColors = () => {
    const resolvedMode = resolveThemeMode(settings.theme_mode)
    const defaults = customThemeDefaults(resolvedMode)
    update({ ...settings, ...defaults })
  }

  const resetAppearance = () => {
    const defaults = customThemeDefaults(resolveThemeMode(settings.theme_mode))
    update({
      ...settings,
      ...defaults,
      corner_radius: DEFAULT_RADIUS,
      ui_density: DEFAULT_DENSITY,
      font_scale: DEFAULT_FONT_SCALE,
      theme_mode: 'dark',
      custom_css: '',
      animation_intensity: 'full',
      view_entrance: 'fade',
      project_icon_opacity: DEFAULT_PROJECT_ICON_OPACITY,
      raised_contrast: DEFAULT_RAISED_CONTRAST,
      theme_preset: 'custom',
    })
    setCssDraft('')
  }

  const testGithubToken = async () => {
    if (tokenTestTimeout.current) clearTimeout(tokenTestTimeout.current)
    try {
      setTokenTestState('testing')
      const info = await api.testGithubToken()
      const mins = Math.max(
        1,
        Math.round((info.reset_at - Date.now() / 1000) / 60),
      )
      const status = info.used_token
        ? `${info.remaining}/${info.limit} (resets ~${mins}min)`
        : `${info.remaining}/${info.limit}`
      setTokenTestState(info.remaining > 0 ? 'success' : 'warning')
      setTokenTestMsg(ts('token_valid', { status }))
    } catch (e) {
      setTokenTestState('error')
      setTokenTestMsg(ts('test_failed', { error: e }))
    }
    tokenTestTimeout.current = setTimeout(() => {
      setTokenTestState('idle')
      setTokenTestMsg(null)
    }, 5000)
  }

  const resetAllSettings = async () => {
    setConfirmingReset(false)
    await resetToDefaults()
  }

  const wipeAppData = async () => {
    setConfirmingWipe(false)
    await api.resetAppData()
    window.location.reload()
  }

  const handleOsDecConfirm = async () => {
    const value = confirmingOsDec
    setConfirmingOsDec(null)
    if (value === null) return
    await update({ ...settings, use_os_decorations: value })
    await flushPendingSave()
    await relaunch()
  }

  const handleRestart = async () => {
    setConfirmingRestart(false)
    await flushPendingSave()
    await relaunch()
  }

  useEffect(() => {
    return () => {
      void flushPendingSave()
    }
  }, [])

  const renderAppearance = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="appearance-layout"
        title={ts('card_layout_label')}
        description={ts('card_layout_desc')}
        searchText={`${ts('card_layout_label')} ${ts('card_layout_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <SettingRow label={ts('card_layout_label')}>
          <Toggle
            checked={settings.card_layout ?? true}
            onChange={(checked) =>
              update({ ...settings, card_layout: checked })
            }
            label={ts('card_layout_label')}
          />
        </SettingRow>
      </Subsection>

      <Subsection
        id="appearance-landing"
        title={ts('landing_tab_label')}
        description={ts('landing_tab_desc')}
        searchText={`${ts('landing_tab_label')} ${ts('landing_tab_desc')} ${LANDING_TABS.map((l) => l.label).join(' ')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <SettingRow label={ts('landing_tab_label')}>
          <Dropdown
            align="right"
            trigger={({ open, toggle }) => (
              <button
                type="button"
                onClick={toggle}
                aria-expanded={open}
                className="focus-ring cursor-pointer inline-flex items-center gap-2 px-3.5 py-2 rounded-btn bg-overlay border border-outline/50 text-xs font-medium text-ink hover:border-accent-dim transition-colors"
              >
                {LANDING_TABS.find((l) => l.id === settings.default_landing_tab)?.label ??
                  LANDING_TABS[0].label}
                <IconChevronDown
                  className={`w-3 h-3 text-muted transition-transform duration-200 ${
                    open ? 'rotate-180' : ''
                  }`}
                />
              </button>
            )}
            items={LANDING_TABS.map((l) => ({
              key: l.id,
              label: l.label,
              active: settings.default_landing_tab === l.id,
              onClick: () => update({ ...settings, default_landing_tab: l.id }),
            }))}
          />
        </SettingRow>
      </Subsection>

      <Subsection
        id="appearance-presets"
        title={ts('theme_preset_label')}
        description={ts('theme_preset_desc')}
        searchText={`${ts('theme_preset_label')} ${ts('theme_preset_custom')} ${ts('preset_light_group')} ${ts('preset_dark_group')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-4">
          {([
            { mode: 'light' as const, label: ts('preset_light_group'), Icon: IconSun, presets: LIGHT_THEME_PRESETS },
            { mode: 'dark' as const, label: ts('preset_dark_group'), Icon: IconMoon, presets: DARK_THEME_PRESETS },
          ]).map(({ mode, label, Icon, presets }) => (
            <button
              key={mode}
              type="button"
              onClick={() => setPresetModal(mode)}
              className="focus-ring cursor-pointer flex items-center gap-3 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-raised px-4 py-3.5 transition-colors"
            >
              <Icon className="w-4 h-4 text-muted shrink-0" />
              <span className="text-xs font-medium text-ink">{label}</span>
              <span className="text-[10px] font-medium text-muted/60">
                {presets.length}
              </span>
              <IconChevronDown className="w-3.5 h-3.5 text-muted -rotate-90 ml-auto" />
            </button>
          ))}

          <button
            type="button"
            onClick={selectCustom}
            className={`focus-ring cursor-pointer flex items-center gap-3 rounded-btn border px-4 py-3.5 transition-colors ${
              settings.theme_preset === 'custom'
                ? 'border-accent bg-accent/10'
                : 'border-outline/50 hover:border-accent-dim hover:bg-raised'
            }`}
          >
            <IconPalette className="w-4 h-4 text-muted shrink-0" />
            <span className="text-xs font-medium text-ink">
              {ts('theme_preset_custom')}
            </span>
            {settings.theme_preset === 'custom' ? (
              <IconCheck className="w-3.5 h-3.5 text-accent-bright ml-auto" />
            ) : (
              <IconChevronDown className="w-3.5 h-3.5 text-muted -rotate-90 ml-auto" />
            )}
          </button>
        </div>

        {settings.theme_preset === 'custom' && (
          <div className="flex flex-col gap-3 pt-4 border-t border-line">
            <div className="flex flex-col gap-2">
              <span className="text-xs font-medium text-muted">{ts('theme')}</span>
              {settings.theme_mode === 'system' && (
                <p className="text-[11px] text-muted leading-relaxed">
                  {ts('theme_follow_desc')}
                </p>
              )}
              <div className="flex items-center gap-2 flex-wrap">
                <Segmented
                  value={settings.theme_mode}
                  onChange={(v) => setThemeMode(v as 'dark' | 'light' | 'system')}
                  options={[
                    { value: 'dark', label: ts('dark') },
                    { value: 'light', label: ts('light') },
                    { value: 'system', label: ts('system') },
                  ]}
                />
                <button
                  type="button"
                  onClick={resetThemeColors}
                  aria-label={ts('reset_colors')}
                  className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-btn text-xs font-medium text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconHeart className="w-3.5 h-3.5" />
                  {ts('reset')}
                </button>
              </div>
            </div>

            <div className="flex flex-wrap gap-8">
              <ColorSwatchPicker
                label={ts('setting_accent_color')}
                value={settings.accent_color}
                presets={
                  resolveThemeMode(settings.theme_mode) === 'light'
                    ? ACCENT_PRESETS_LIGHT
                    : ACCENT_PRESETS_DARK
                }
                onChange={(hex) => update({ ...settings, accent_color: hex })}
              />
              <ColorSwatchPicker
                label={ts('setting_background_color')}
                value={settings.background_color}
                presets={
                  resolveThemeMode(settings.theme_mode) === 'light'
                    ? BG_PRESETS_LIGHT
                    : BG_PRESETS_DARK
                }
                onChange={(hex) => update({ ...settings, background_color: hex })}
              />
            </div>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('background_color_desc')}
            </p>

            <div className="flex flex-col gap-2">
              <Slider
                label={ts('raised_contrast_label')}
                display={
                  <span className="text-xs font-medium text-ink tabular-nums">
                    {ts('raised_contrast_value', {
                      value: settings.raised_contrast,
                    })}
                  </span>
                }
                value={settings.raised_contrast}
                min={0}
                max={40}
                step={1}
                defaultValue={DEFAULT_RAISED_CONTRAST}
                onChange={(value) =>
                  update({ ...settings, raised_contrast: value })
                }
              />
              <p className="text-[11px] text-muted leading-relaxed">
                {ts('raised_contrast_desc')}
              </p>
            </div>
          </div>
        )}
      </Subsection>

      <Subsection
        id="appearance-radius"
        title={ts('corner_radius_label')}
        description={ts('corner_radius_desc')}
        searchText={`${ts('corner_radius_label')} ${ts('corner_radius_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('corner_radius_label')}
            display={
              <span className="text-xs font-mono text-ink tabular-nums">
                {settings.corner_radius}px
              </span>
            }
            value={settings.corner_radius}
            min={0}
            max={20}
            step={1}
            defaultValue={DEFAULT_RADIUS}
            onChange={(v) => update({ ...settings, corner_radius: v })}
          />
        </div>
      </Subsection>

      <Subsection
        id="appearance-view-entrance"
        title={ts('view_entrance_label')}
        description={ts('view_entrance_desc')}
        searchText={`${ts('view_entrance_label')} ${ts('view_entrance_desc')} ${ts('entrance_fade')} ${ts('entrance_slide')} ${ts('entrance_scale')} ${ts('entrance_none')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-3">
          <SettingRow label={ts('view_entrance_label')}>
            <Segmented
              value={settings.view_entrance}
              onChange={(v) =>
                update({
                  ...settings,
                  view_entrance: v as AppSettings['view_entrance'],
                })
              }
              options={[
                { value: 'fade', label: ts('entrance_fade') },
                { value: 'slide', label: ts('entrance_slide') },
                { value: 'scale', label: ts('entrance_scale') },
                { value: 'none', label: ts('entrance_none') },
              ]}
            />
          </SettingRow>
          <p className="text-[11px] text-muted leading-relaxed">
            {ts('view_entrance_desc')}
          </p>
        </div>
      </Subsection>

      <Subsection
        id="appearance-animation-threshold"
        title={ts('animation_threshold_label')}
        description={ts('animation_threshold_desc')}
        searchText={`${ts('animation_threshold_label')} ${ts('animation_threshold_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('animation_threshold_label')}
            display={
              <span className="text-xs font-medium text-ink tabular-nums">
                {ts('n_projects', { count: settings.animation_threshold })}
              </span>
            }
            value={settings.animation_threshold}
            min={10}
            max={100}
            step={5}
            defaultValue={20}
            onChange={(value) =>
              update({ ...settings, animation_threshold: value })
            }
          />
        </div>
      </Subsection>

      <Subsection
        id="appearance-animated-numbers"
        title={ts('animated_numbers_label')}
        description={ts('animated_numbers_desc')}
        searchText={`${ts('animated_numbers_label')} ${ts('animated_numbers_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <SettingRow label={ts('animated_numbers_label')}>
          <Toggle
            checked={settings.animated_numbers}
            onChange={(checked) =>
              update({ ...settings, animated_numbers: checked })
            }
            label={ts('animated_numbers_label')}
          />
        </SettingRow>
      </Subsection>

      <Subsection
        id="appearance-icon-opacity"
        title={ts('project_icon_opacity_label')}
        description={ts('icon_opacity_desc')}
        searchText={`${ts('project_icon_opacity_label')} ${ts('icon_opacity_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('project_icon_opacity_label')}
            display={
              <span className="text-xs font-mono text-ink tabular-nums">
                {settings.project_icon_opacity}%
              </span>
            }
            value={settings.project_icon_opacity}
            min={0}
            max={50}
            step={1}
            defaultValue={DEFAULT_PROJECT_ICON_OPACITY}
            onChange={(v) =>
              update({ ...settings, project_icon_opacity: v })
            }
          />
        </div>
      </Subsection>

      <Subsection
        id="appearance-css"
        title={ts('custom_css_label')}
        description={ts('custom_css_desc')}
        searchText={`${ts('custom_css_label')} ${ts('custom_css_desc')} ${ts('custom_css_apply')} ${ts('custom_css_clear')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <textarea
            value={cssDraft}
            onChange={(e) => {
              setCssDraft(e.target.value)
              setCssStatus('idle')
            }}
            spellCheck={false}
            placeholder={ts('custom_css_placeholder')}
            className="focus-ring w-full h-40 resize-y bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono text-ink placeholder:text-muted/50 transition-colors focus:border-accent-dim"
          />
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleApplyCss}
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-btn bg-accent text-white text-xs font-medium hover:bg-accent-dim transition-colors"
            >
              {ts('custom_css_apply')}
            </button>
            {settings.custom_css && (
              <button
                type="button"
                onClick={() => {
                  setCssDraft('')
                  update({ ...settings, custom_css: '' })
                  setCssStatus('applied')
                  setTimeout(() => setCssStatus('idle'), 1500)
                }}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3.5 rounded-btn bg-overlay border border-outline/50 text-muted text-xs font-medium hover:text-ink hover:bg-raised transition-colors"
              >
                {ts('custom_css_clear')}
              </button>
            )}
            {cssStatus === 'applied' && (
              <span className="text-xs text-mint font-medium">
                {ts('custom_css_applied')}
              </span>
            )}
          </div>
        </div>
      </Subsection>

      <button
        type="button"
        onClick={resetAppearance}
        className="focus-ring cursor-pointer self-start inline-flex items-center gap-1.5 px-4 py-2 rounded-btn border border-outline/50 text-muted hover:text-ink hover:bg-raised text-xs font-medium transition-colors"
      >
        <IconRefresh className="w-3.5 h-3.5" />
        {ts('reset_appearance')}
      </button>
    </div>
  )

  const renderDisplay = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="display-formats"
        title={ts('last_opened_title')}
        description={ts('last_opened_desc')}
        searchText={`${ts('last_opened_title')} ${ts('last_opened_desc')} ${ts('time_format_label')} ${ts('date_format_label')} ${ts('12h')} ${ts('24h')} ${ts('dd_mm_yyyy')} ${ts('mm_dd_yyyy')} ${ts('yyyy_mm_dd')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <div className="flex flex-col gap-2.5">
            <span className="text-xs font-medium text-muted">
              {ts('time_format_label')}
            </span>
            <Segmented
              value={settings.last_opened_time_format}
              onChange={(v) =>
                update({
                  ...settings,
                  last_opened_time_format: v as AppSettings['last_opened_time_format'],
                })
              }
              options={[
                { value: '12h', label: ts('12h') },
                { value: '24h', label: ts('24h') },
              ]}
            />
          </div>

          <div className="flex flex-col gap-2.5">
            <span className="text-xs font-medium text-muted">
              {ts('date_format_label')}
            </span>
            <Segmented
              value={settings.last_opened_date_format}
              onChange={(v) =>
                update({
                  ...settings,
                  last_opened_date_format: v as AppSettings['last_opened_date_format'],
                })
              }
              options={[
                { value: 'DD-MM-YYYY', label: ts('dd_mm_yyyy'), mono: true },
                { value: 'MM-DD-YYYY', label: ts('mm_dd_yyyy'), mono: true },
                { value: 'YYYY-MM-DD', label: ts('yyyy_mm_dd'), mono: true },
              ]}
            />
          </div>

        </div>
      </Subsection>

      {!isMac && (
        <Subsection
          id="display-os-decorations"
          title={ts('use_os_decorations')}
          description={ts('use_os_decorations_desc')}
          searchText={`${ts('use_os_decorations')} ${ts('use_os_decorations_desc')}`}
          query={searchQuery}
          onMatch={reportMatch}
        >
          <SettingRow label={ts('use_os_decorations')}>
            <Toggle
              checked={settings.use_os_decorations}
              onChange={(checked) => setConfirmingOsDec(checked)}
              label={ts('use_os_decorations')}
            />
          </SettingRow>
        </Subsection>
      )}

      <Subsection
        id="display-titlebar"
        title={ts('titlebar_buttons')}
        description={ts('titlebar_buttons_desc')}
        searchText={`${ts('titlebar_buttons')} ${ts('titlebar_buttons_desc')} ${ts('show_support_label')} ${ts('show_star_label')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-4">
          <SettingRow label={ts('show_support_label')}>
            <Toggle
              checked={settings.show_support_button}
              onChange={(checked) =>
                update({ ...settings, show_support_button: checked })
              }
              label={ts('show_support_label')}
            />
          </SettingRow>
          <SettingRow label={ts('show_star_label')}>
            <Toggle
              checked={settings.show_star_button}
              onChange={(checked) =>
                update({ ...settings, show_star_button: checked })
              }
              label={ts('show_star_label')}
            />
          </SettingRow>
          <SettingRow label={ts('show_bug_label')}>
            <Toggle
              checked={settings.show_bug_button}
              onChange={(checked) =>
                update({ ...settings, show_bug_button: checked })
              }
              label={ts('show_bug_label')}
            />
          </SettingRow>
          <SettingRow label={ts('show_tray_label')}>
            <Toggle
              checked={settings.show_tray_button}
              onChange={(checked) =>
                update({ ...settings, show_tray_button: checked })
              }
              label={ts('show_tray_label')}
            />
          </SettingRow>
          <SettingRow label={ts('show_language_label')} divider>
            <Toggle
              checked={settings.show_language_button}
              onChange={(checked) =>
                update({ ...settings, show_language_button: checked })
              }
              label={ts('show_language_label')}
            />
          </SettingRow>
        </div>
      </Subsection>
    </div>
  )

  const renderStorage = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="storage-folders"
        title={ts('storage_title')}
        description={ts('storage_desc')}
        searchText={`${ts('storage_title')} ${ts('storage_desc')} ${ts('section_projects')} ${ts('section_godot_versions')} ${ts('section_templates')} ${ts('new_project_default')} ${ts('download_folder')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <div className="flex flex-col gap-2.5">
            <span className="text-xs font-medium text-muted">
              {ts('section_projects')}
            </span>
            <DirList
              dirs={settings.project_scan_dirs}
              onChange={(dirs) => update({ ...settings, project_scan_dirs: dirs })}
              emptyHint={ts('empty_hint_projects')}
              defaultDir={settings.default_project_location}
              onSetDefault={(dir) =>
                update({ ...settings, default_project_location: dir })
              }
              defaultLabel={ts('new_project_default')}
            />
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('projects_desc')}
            </p>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('section_godot_versions')}
            </span>
            <DirList
              dirs={settings.version_scan_dirs}
              onChange={(dirs) => update({ ...settings, version_scan_dirs: dirs })}
              emptyHint={ts('empty_hint_versions')}
              defaultDir={settings.download_dir}
              onSetDefault={(dir) => update({ ...settings, download_dir: dir })}
              defaultLabel={ts('download_folder')}
              showFallbackDescription
              fallbackDownloadPath="AppData/Ryko.GodotHub/godot-versions/"
            />
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('godot_versions_desc')}
            </p>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('section_templates')}
            </span>
            <div className="flex items-center gap-2.5">
              {settings.template_scan_dir ? (
                <>
                  <input
                    readOnly
                    value={settings.template_scan_dir}
                    className="flex-1 bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono text-ink"
                  />
                  <button
                    type="button"
                    onClick={() => update({ ...settings, template_scan_dir: null })}
                    className="focus-ring cursor-pointer px-3 py-2 rounded-btn border border-outline/50 text-xs text-muted hover:text-danger hover:border-danger/30 hover:bg-danger/10 transition-colors"
                  >
                    {ts('clear')}
                  </button>
                </>
              ) : (
                <span className="text-xs text-muted">{ts('no_folder_set')}</span>
              )}
              <button
                type="button"
                onClick={async () => {
                  const folder = await api.pickFolder()
                  if (folder) update({ ...settings, template_scan_dir: folder })
                }}
                className="focus-ring cursor-pointer px-3.5 py-2 rounded-btn border border-outline/50 text-xs hover:border-accent-dim hover:bg-raised transition-colors"
              >
                {ts('browse')}
              </button>
            </div>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('template_scan_desc')}
            </p>
          </div>
        </div>
      </Subsection>

      <Subsection
        id="storage-scan-depth"
        title={ts('scan_depth_label')}
        description={ts('scan_depth_desc')}
        searchText={`${ts('scan_depth_label')} ${ts('scan_depth_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('scan_depth_label')}
            display={
              <span className="text-xs font-medium text-ink tabular-nums">
                {ts('folders_deep', { count: settings.scan_depth })}
              </span>
            }
            value={settings.scan_depth}
            min={1}
            max={10}
            defaultValue={2}
            onChange={(value) => update({ ...settings, scan_depth: value })}
          />
        </div>
      </Subsection>

      <Subsection
        id="storage-icon-scan-depth"
        title={ts('icon_scan_depth_label')}
        description={ts('icon_scan_depth_desc')}
        searchText={`${ts('icon_scan_depth_label')} ${ts('icon_scan_depth_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('icon_scan_depth_label')}
            display={
              <span className="text-xs font-medium text-ink tabular-nums">
                {ts('folders_deep', { count: settings.icon_scan_depth })}
              </span>
            }
            value={settings.icon_scan_depth}
            min={1}
            max={20}
            defaultValue={4}
            onChange={(value) => update({ ...settings, icon_scan_depth: value })}
          />
        </div>
      </Subsection>

      <Subsection
        id="storage-concurrency"
        title={ts('download_concurrency_label')}
        description={ts('download_concurrency_desc')}
        searchText={`${ts('download_concurrency_label')} ${ts('download_concurrency_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('download_concurrency_label')}
            display={
              <span className="text-xs font-medium text-ink tabular-nums">
                {ts('at_once', { count: settings.download_concurrency })}
              </span>
            }
            value={settings.download_concurrency}
            min={1}
            max={10}
            defaultValue={3}
            onChange={(value) =>
              update({ ...settings, download_concurrency: value })
            }
          />
        </div>
      </Subsection>

      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={runScan}
          className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-5 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
        >
          <IconRefresh className="w-4 h-4" />
          {ts('scan_now')}
        </button>
        {scanMessage && (
          <span className="text-xs text-muted">{scanMessage}</span>
        )}
      </div>
    </div>
  )

  const renderBehavior = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="behavior-launch"
        title={ts('behavior_title')}
        description={ts('behavior_desc')}
        searchText={`${ts('behavior_title')} ${ts('behavior_desc')} ${ts('launch_console_label')} ${ts('close_on_open_label')} ${ts('minimize_tray_label')} ${ts('reopen_label')} ${ts('tray_recent_label')} ${ts('palette_shortcut')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <SettingRow
            label={ts('launch_console_label')}
            description={
              isWindows
                ? ts('launch_console_desc_windows')
                : ts('launch_console_desc')
            }
          >
            <Toggle
              checked={settings.launch_with_console}
              onChange={(checked) =>
                update({ ...settings, launch_with_console: checked })
              }
              label={ts('launch_console_label')}
            />
          </SettingRow>

          <SettingRow
            label={ts('close_on_open_label')}
            description={
              isMac ? ts('close_on_open_desc_mac') : ts('close_on_open_desc')
            }
            divider
          >
            <Toggle
              checked={settings.close_on_project_open}
              onChange={(checked) =>
                update({ ...settings, close_on_project_open: checked })
              }
              label={ts('close_on_open_label')}
            />
          </SettingRow>

          {!isMac && (
            <SettingRow
              label={ts('minimize_tray_label')}
              description={ts('minimize_tray_desc')}
              divider
            >
              <Toggle
                checked={settings.minimize_to_tray}
                onChange={(checked) =>
                  update({ ...settings, minimize_to_tray: checked })
                }
                label={ts('minimize_tray_label')}
              />
            </SettingRow>
          )}

          <AnimatePresence initial={false}>
            {settings.close_on_project_open &&
              (isMac || settings.minimize_to_tray) && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.2, ease: 'easeOut' }}
                  className="overflow-hidden"
                >
                  <SettingRow
                    label={ts('reopen_label')}
                    description={
                      isMac ? ts('reopen_desc_mac') : ts('reopen_desc')
                    }
                    divider
                  >
                    <Toggle
                      checked={settings.reopen_after_godot_closes}
                      onChange={(checked) =>
                        update({ ...settings, reopen_after_godot_closes: checked })
                      }
                      label={ts('reopen_label')}
                    />
                  </SettingRow>
                </motion.div>
              )}
          </AnimatePresence>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <Slider
              label={ts('tray_recent_label')}
              display={
                <span className="text-xs text-ink tabular-nums">
                  {ts('n_projects', {
                    count: settings.tray_recent_projects_count,
                  })}
                </span>
              }
              value={settings.tray_recent_projects_count}
              min={1}
              max={10}
              defaultValue={5}
              onChange={(value) => {
                update({ ...settings, tray_recent_projects_count: value })
                api.refreshTrayMenu().catch(() => {})
              }}
            />
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('tray_recent_desc')}
            </p>
          </div>

          <KeyRecorder
            value={settings.command_palette_keybind}
            onChange={(value) =>
              update({ ...settings, command_palette_keybind: value })
            }
            onReset={() =>
              update({ ...settings, command_palette_keybind: 'p' })
            }
          />
        </div>
      </Subsection>

      <Subsection
        id="behavior-projects"
        title={ts('behavior_projects_title')}
        description={ts('behavior_projects_desc')}
        searchText={`${ts('behavior_projects_title')} ${ts('behavior_projects_desc')} ${ts('auto_scan_label')} ${ts('use_workspaces_label')} ${ts('git_init_new_projects_label')} ${ts('naming_convention_label')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <SettingRow
            label={ts('auto_scan_label')}
            description={ts('auto_scan_desc')}
          >
            <Toggle
              checked={settings.auto_scan_on_startup}
              onChange={(checked) =>
                update({ ...settings, auto_scan_on_startup: checked })
              }
              label={ts('auto_scan_label')}
            />
          </SettingRow>

          <SettingRow
            label={ts('use_workspaces_label')}
            description={ts('workspaces_off_desc')}
            divider
          >
            <Toggle
              checked={settings.workspaces_enabled}
              onChange={(checked) =>
                update({ ...settings, workspaces_enabled: checked })
              }
              label={ts('use_workspaces_label')}
            />
          </SettingRow>

          <SettingRow
            label={ts('git_init_new_projects_label')}
            description={ts('git_init_new_projects_desc')}
            divider
          >
            <Toggle
              checked={settings.git_init_new_projects}
              onChange={(checked) =>
                update({ ...settings, git_init_new_projects: checked })
              }
              label={ts('git_init_new_projects_label')}
            />
          </SettingRow>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('naming_convention_label')}
            </span>
            {(() => {
              const conventionOptions = [
                { value: 'keep' as const, label: ts('naming_keep') },
                { value: 'kebab-case' as const, label: ts('naming_kebab') },
                { value: 'snake_case' as const, label: ts('naming_snake') },
                { value: 'camelCase' as const, label: ts('naming_camel') },
                { value: 'PascalCase' as const, label: ts('naming_pascal') },
                { value: 'Title Case' as const, label: ts('naming_title') },
              ]
              const currentLabel =
                conventionOptions.find(
                  (o) => o.value === settings.directory_naming_convention,
                )?.label ?? conventionOptions[0].label
              return (
                <Dropdown
                  align="right"
                  trigger={({ open, toggle }) => (
                    <button
                      type="button"
                      onClick={toggle}
                      aria-expanded={open}
                      className="focus-ring cursor-pointer inline-flex items-center gap-2 px-3.5 py-2 rounded-btn bg-overlay border border-outline/50 text-xs font-medium text-ink hover:border-accent-dim transition-colors"
                    >
                      {currentLabel}
                      <IconChevronDown
                        className={`w-3 h-3 text-muted transition-transform duration-200 ${
                          open ? 'rotate-180' : ''
                        }`}
                      />
                    </button>
                  )}
                  items={conventionOptions.map(({ value, label }) => ({
                    key: value,
                    label,
                    active: settings.directory_naming_convention === value,
                    onClick: () =>
                      update({ ...settings, directory_naming_convention: value }),
                  }))}
                />
              )
            })()}
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('naming_convention_desc')}
            </p>
          </div>

        </div>
      </Subsection>

      <Subsection
        id="behavior-watchers"
        title={ts('file_watchers_title')}
        description={ts('file_watchers_desc')}
        searchText={`${ts('file_watchers_title')} ${ts('file_watchers_desc')} ${ts('watch_projects_label')} ${ts('watch_versions_label')} ${ts('watch_template_label')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <SettingRow
            label={ts('watch_projects_label')}
            description={ts('watch_projects_desc')}
          >
            <Toggle
              checked={settings.auto_watch_project_dirs}
              onChange={(checked) => {
                update({ ...settings, auto_watch_project_dirs: checked })
                api.restartWatchers().catch(() => {})
              }}
              label={ts('watch_projects_label')}
            />
          </SettingRow>

          <SettingRow
            label={ts('watch_versions_label')}
            description={ts('watch_versions_desc')}
            divider
          >
            <Toggle
              checked={settings.auto_watch_version_dirs}
              onChange={(checked) => {
                update({ ...settings, auto_watch_version_dirs: checked })
                api.restartWatchers().catch(() => {})
              }}
              label={ts('watch_versions_label')}
            />
          </SettingRow>

          <SettingRow
            label={ts('watch_template_label')}
            description={ts('watch_template_desc')}
            divider
          >
            <Toggle
              checked={settings.auto_watch_template_dir}
              onChange={(checked) => {
                update({ ...settings, auto_watch_template_dir: checked })
                api.restartWatchers().catch(() => {})
              }}
              label={ts('watch_template_label')}
            />
          </SettingRow>

          <p className="text-[10px] text-muted/50 mt-1 leading-relaxed">
            {ts('watcher_footer_desc')}
          </p>
        </div>
      </Subsection>
    </div>
  )

  const refreshGitAuth = async () => {
    try {
      setGitAuth(await api.gitAuthGetState())
    } catch {}
  }

  useEffect(() => {
    void refreshGitAuth()
  }, [])

  const handleSavePat = async () => {
    setPatMsg(null)
    try {
      await api.gitAuthSavePat(patHost, patUser, patToken)
      setPatHost('')
      setPatUser('')
      setPatToken('')
      setPatOpen(false)
      await refreshGitAuth()
    } catch (e) {
      setPatMsg(String(e))
    }
  }

  const renderIntegrations = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="integrations-git"
        title={
          <span className="inline-flex items-center gap-2">
            <IconGitBranch className="w-3.5 h-3.5 text-muted" />
            Git
          </span>
        }
        description={ts('github_token_desc')}
        searchText={`${ts('git_sign_in_github')} ${ts('git_sign_in_gitlab')} ${ts('git_pat_title')} ${ts('github_token_title')} ${ts('github_token_desc')} ${ts('test')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <div className="flex flex-col gap-2.5">
            <span className="text-xs font-medium text-muted">GitHub</span>
            <div className="flex items-center justify-between gap-4">
              <span className="text-xs text-muted">
                {gitAuth?.github
                  ? ts('git_connected_as', {
                      username: gitAuth.github.username,
                    })
                  : ts('git_oauth_hint')}
              </span>
              {gitAuth?.github ? (
                <button
                  type="button"
                  onClick={async () => {
                    await api.gitAuthDisconnect('github')
                    await refreshGitAuth()
                  }}
                  className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item border border-outline/50 text-muted hover:text-danger hover:border-danger/40 hover:bg-danger/5 text-xs font-medium transition-colors"
                >
                  {ts('git_disconnect')}
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => setGitAuthFlow('github')}
                  className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
                >
                  <IconGitBranch className="w-3.5 h-3.5" />
                  {ts('git_sign_in_github')}
                </button>
              )}
            </div>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">GitLab</span>
            <div className="flex items-center justify-between gap-4">
              <span className="text-xs text-muted">
                {gitAuth?.gitlab
                  ? gitAuth.gitlab.host
                    ? ts('git_connected_to', {
                        host: gitAuth.gitlab.host,
                        username: gitAuth.gitlab.username,
                      })
                    : ts('git_connected_as', {
                        username: gitAuth.gitlab.username,
                      })
                  : ts('git_oauth_hint')}
              </span>
              {gitAuth?.gitlab ? (
                <button
                  type="button"
                  onClick={async () => {
                    await api.gitAuthDisconnect('gitlab')
                    await refreshGitAuth()
                  }}
                  className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item border border-outline/50 text-muted hover:text-danger hover:border-danger/40 hover:bg-danger/5 text-xs font-medium transition-colors"
                >
                  {ts('git_disconnect')}
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => setGitAuthFlow('gitlab')}
                  className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
                >
                  <IconGitBranch className="w-3.5 h-3.5" />
                  {ts('git_sign_in_gitlab')}
                </button>
              )}
            </div>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('git_self_hosted_title')}
            </span>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('git_self_hosted_desc')}
            </p>
            <div className="grid grid-cols-2 gap-2">
              <input
                value={gitlabUrl}
                onChange={(e) => setGitlabUrl(e.target.value)}
                placeholder={ts('git_self_hosted_url_placeholder')}
                className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono focus:border-accent-dim transition-colors outline-none"
              />
              <input
                value={gitlabClientId}
                onChange={(e) => setGitlabClientId(e.target.value)}
                placeholder={ts('git_self_hosted_client_id')}
                className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono focus:border-accent-dim transition-colors outline-none"
              />
            </div>
            <button
              type="button"
              disabled={!gitlabUrl.trim() || !gitlabClientId.trim()}
              onClick={() => {
                setGitAuthInstance({
                  baseUrl: gitlabUrl.trim(),
                  clientId: gitlabClientId.trim(),
                })
                setGitAuthFlow('gitlab')
              }}
              className="focus-ring cursor-pointer inline-flex items-center justify-center gap-1.5 h-8 px-4 rounded-item border border-outline/50 text-muted hover:text-ink hover:border-accent-dim hover:bg-raised disabled:opacity-40 disabled:cursor-not-allowed text-xs font-medium transition-colors w-fit"
            >
              <IconGitBranch className="w-3.5 h-3.5" />
              {ts('git_sign_in_self_hosted')}
            </button>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('git_pat_title')}
            </span>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('git_pat_desc')}
            </p>

            {(gitAuth?.pats.length ?? 0) === 0 && !patOpen && (
              <span className="text-xs text-muted/60">
                {ts('git_pat_empty')}
              </span>
            )}

            <div className="flex flex-col gap-2">
              {(gitAuth?.pats ?? []).map((pat) => (
                <div
                  key={pat.host}
                  className="flex items-center justify-between gap-3 rounded-btn bg-base border border-outline/50 px-3.5 py-2.5"
                >
                  <div className="min-w-0 flex items-center gap-2">
                    <span className="text-xs font-medium text-ink font-mono">
                      {pat.host}
                    </span>
                    <span className="text-[11px] text-muted">
                      {pat.username}
                    </span>
                  </div>
                    <button
                      type="button"
                      aria-label={ts('git_pat_remove')}
                      title={ts('git_pat_remove')}
                      onClick={async () => {
                        await api.gitAuthRemovePat(pat.host)
                        await refreshGitAuth()
                      }}
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/60 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
                    >
                      <IconTrash className="w-3.5 h-3.5" />
                    </button>
                </div>
              ))}
            </div>

            {patOpen ? (
              <div className="flex flex-col gap-2.5">
                <div className="grid grid-cols-2 gap-2">
                  <input
                    value={patHost}
                    onChange={(e) => setPatHost(e.target.value)}
                    placeholder={ts('git_pat_host_placeholder')}
                    className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono focus:border-accent-dim transition-colors outline-none"
                  />
                  <input
                    value={patUser}
                    onChange={(e) => setPatUser(e.target.value)}
                    placeholder={ts('git_pat_username')}
                    className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono focus:border-accent-dim transition-colors outline-none"
                  />
                </div>
                <input
                  type="password"
                  value={patToken}
                  onChange={(e) => setPatToken(e.target.value)}
                  placeholder={ts('git_pat_token')}
                  className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono focus:border-accent-dim transition-colors outline-none"
                />
                {patMsg && (
                  <span className="text-[11px] text-danger">{patMsg}</span>
                )}
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={handleSavePat}
                    className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
                  >
                    {ts('git_pat_save')}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setPatOpen(false)
                      setPatMsg(null)
                    }}
                    className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3.5 rounded-item border border-outline/50 text-muted hover:text-ink hover:bg-raised text-xs font-medium transition-colors"
                  >
                    {ts('cancel', { ns: 'common' })}
                  </button>
                </div>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => setPatOpen(true)}
                className="focus-ring cursor-pointer self-start inline-flex items-center gap-1.5 h-8 px-4 rounded-item border border-outline/50 text-muted hover:text-ink hover:border-accent-dim hover:bg-raised text-xs font-medium transition-colors"
              >
                <IconPlus className="w-3.5 h-3.5" />
                {ts('git_pat_add')}
              </button>
            )}
          </div>

          {!gitAuth?.github && (
            <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
              <span className="text-xs font-medium text-muted">
                {ts('github_token_title')}
              </span>
              <div className="relative">
                <input
                  type="password"
                  value={settings.github_token ?? ''}
                  onChange={(e) =>
                    update({ ...settings, github_token: e.target.value || null })
                  }
                  placeholder={ts('setting_token_placeholder', { ns: 'common' })}
                  className="focus-ring w-full bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm font-mono focus:border-accent-dim transition-colors pr-20"
                />
                <button
                  type="button"
                  onClick={testGithubToken}
                  className="focus-ring cursor-pointer absolute right-1.5 top-1/2 -translate-y-1/2 px-3 py-1.5 rounded-md bg-overlay border border-outline/50 text-xs font-medium text-muted hover:text-ink hover:border-accent-dim transition-colors"
                >
                  {tokenTestState === 'testing' ? ts('testing') : ts('test')}
                </button>
              </div>
              {tokenTestMsg && (
                <span
                  className={`text-[11px] ${
                    tokenTestState === 'success'
                      ? 'text-mint'
                      : tokenTestState === 'warning'
                        ? 'text-amber'
                        : tokenTestState === 'error'
                          ? 'text-danger'
                          : 'text-muted'
                  }`}
                >
                  {tokenTestMsg}
                </span>
              )}
              <p className="text-[11px] text-muted leading-relaxed">
                {ts('token_help_desc')}{' '}
                <a
                  href="https://github.com/settings/tokens"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-accent hover:text-accent-bright underline underline-offset-2"
                >
                  github.com/settings/tokens
                </a>
                .
              </p>
            </div>
          )}
        </div>
      </Subsection>

      {gitAuth?.github && (
      <Subsection
        id="integrations-sync"
        title={
          <span className="inline-flex items-center gap-2">
            <IconCloudArrowDown className="w-3.5 h-3.5 text-muted" />
            {ts('sync_title')}
          </span>
        }
        description={ts('sync_desc')}
        searchText={`${ts('sync_title')} ${ts('sync_desc')} ${ts('sync_push_btn')} ${ts('sync_pull_btn')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between gap-4">
            <div className="min-w-0">
              {syncMessage && (
                <p className="text-xs text-muted mt-1.5 wrap-break-word">
                  {syncMessage}
                </p>
              )}
              {syncUrl && (
                <button
                  type="button"
                  onClick={() => openUrl(syncUrl)}
                  className="focus-ring cursor-pointer mt-1.5 inline-flex items-center gap-1.5 text-xs text-accent-bright hover:underline"
                >
                  <IconExternalLink className="w-3 h-3" />
                  {ts('sync_open_gist')}
                </button>
              )}
              {lastPushedAt && (
                <p className="text-[11px] text-muted mt-1">
                  {ts('sync_last_pushed', { time: lastPushedAt })}
                </p>
              )}
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <button
                type="button"
                onClick={handleSyncPush}
                disabled={syncBusy !== null}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <IconCloudArrowDown className="w-4 h-4" />
                {syncBusy === 'push'
                  ? ts('saving')
                  : ts('sync_push_btn')}
              </button>
              <button
                type="button"
                onClick={handleSyncPull}
                disabled={syncBusy !== null}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {syncBusy === 'pull'
                  ? ts('saving')
                  : ts('sync_pull_btn')}
              </button>
            </div>
          </div>
          <div className="border-t border-outline/30 pt-3">
            <p className="text-xs text-muted mb-2">
              {ts('sync_manual_hint')}
            </p>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={manualGistUrl}
                onChange={(e) => setManualGistUrl(e.target.value)}
                placeholder={ts('sync_manual_placeholder')}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleManualPull()
                }}
                className="focus-ring flex-1 bg-base border border-outline/50 rounded-btn px-3 py-2 text-xs focus:border-accent-dim transition-colors"
              />
              <button
                type="button"
                onClick={handleManualPull}
                disabled={manualPullBusy || !manualGistUrl.trim()}
                className="focus-ring cursor-pointer px-4 py-2 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-xs font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {manualPullBusy ? ts('saving') : ts('sync_manual_pull_btn')}
              </button>
            </div>
          </div>
          <div className="border-t border-outline/30 pt-3">
            <div className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                <p className="text-xs font-medium text-ink">
                  {ts('sync_auto_backup_label')}
                </p>
                <p className="text-xs text-muted mt-0.5">
                  {ts('sync_auto_backup_desc')}
                </p>
                {lastAutoBackup && (
                  <p className="text-[11px] text-muted mt-1">
                    {ts('sync_auto_backup_last', { time: lastAutoBackup })}
                  </p>
                )}
              </div>
              <Dropdown
                align="right"
                compact
                trigger={({ open, toggle }) => (
                  <button
                    type="button"
                    onClick={toggle}
                    className="focus-ring cursor-pointer flex items-center gap-2 px-3 py-2 rounded-btn border border-outline/50 bg-base hover:border-accent-dim text-xs font-medium transition-colors"
                  >
                    {autoBackupOptions.find(
                      (o) => o.value === settings.auto_backup_interval_minutes,
                    )?.label ?? ts('sync_auto_backup_off')}
                    <IconChevronDown
                      className={`w-3 h-3 text-muted transition-transform ${open ? 'rotate-180' : ''}`}
                    />
                  </button>
                )}
                items={autoBackupOptions.map((o) => ({
                  key: String(o.value),
                  label: o.label,
                  active: settings.auto_backup_interval_minutes === o.value,
                  onClick: () =>
                    update({
                      ...settings,
                      auto_backup_interval_minutes: o.value,
                    }),
                }))}
              />
            </div>
          </div>
        </div>
      </Subsection>
      )}

      <Subsection
        id="integrations-discord"
        title={ts('discord_rpc_label')}
        description={ts('discord_rpc_desc')}
        searchText={`${ts('discord_rpc_label')} ${ts('discord_rpc_desc')} ${ts('discord_app_id_label')} ${ts('discord_app_id_desc')} ${ts('discord_developer_portal')} ${ts('discord_show_projects_label')} ${ts('discord_show_projects_desc')} ${ts('discord_excluded_label')} ${ts('discord_excluded_desc')} ${ts('discord_custom_label')} ${ts('discord_custom_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-5">
          <SettingRow label={ts('discord_rpc_label')}>
            <Toggle
              checked={settings.discord_rpc_enabled}
              onChange={(checked) =>
                update({ ...settings, discord_rpc_enabled: checked })
              }
              label={ts('discord_rpc_label')}
            />
          </SettingRow>

          <div className="flex flex-col gap-2.5">
            <span className="text-xs font-medium text-muted">
              {ts('discord_app_id_label')}
            </span>
            <input
              type="text"
              value={settings.discord_app_id ?? ''}
              onChange={(e) =>
                update({ ...settings, discord_app_id: e.target.value || null })
              }
              placeholder={ts('discord_app_id_placeholder')}
              className="focus-ring w-full bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm font-mono focus:border-accent-dim transition-colors"
            />
            {!settings.discord_app_id?.trim() && (
              <span className="text-[11px] text-mint font-medium">
                {ts('discord_builtin_hint')}
              </span>
            )}
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('discord_app_id_desc')}{' '}
              <a
                href="https://discord.com/developers/applications"
                target="_blank"
                rel="noopener noreferrer"
                className="text-accent hover:text-accent-bright underline underline-offset-2"
              >
                {ts('discord_developer_portal')}
              </a>
              .
            </p>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <SettingRow label={ts('discord_show_projects_label')}>
              <Toggle
                checked={settings.discord_rpc_show_projects}
                onChange={(checked) =>
                  update({ ...settings, discord_rpc_show_projects: checked })
                }
                label={ts('discord_show_projects_label')}
              />
            </SettingRow>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('discord_show_projects_desc')}
            </p>
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('discord_excluded_label')}
            </span>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('discord_excluded_desc')}
            </p>
            <Dropdown
              trigger={({ toggle }) => (
                <button
                  type="button"
                  onClick={toggle}
                  className="focus-ring cursor-pointer self-start inline-flex items-center gap-1.5 h-8 px-4 rounded-item border border-outline/50 text-muted hover:text-ink hover:border-accent-dim hover:bg-raised text-xs font-medium transition-colors"
                >
                  <IconPlus className="w-3.5 h-3.5" />
                  {ts('discord_exclude_project')}
                </button>
              )}
              items={projects
                .filter(
                  (p) =>
                    !settings.discord_rpc_excluded_projects.includes(p.id),
                )
                .map((p) => ({
                  key: p.id,
                  label: p.name,
                  onClick: () =>
                    update({
                      ...settings,
                      discord_rpc_excluded_projects: [
                        ...settings.discord_rpc_excluded_projects,
                        p.id,
                      ],
                    }),
                }))}
            />
            {settings.discord_rpc_excluded_projects.length > 0 ? (
              <div className="flex flex-col gap-1.5">
                {settings.discord_rpc_excluded_projects.map((id) => {
                  const proj = projects.find((p) => p.id === id)
                  return (
                    <div
                      key={id}
                      className="flex items-center justify-between gap-3 rounded-item bg-raised border border-line px-3 py-2"
                    >
                      <span className="text-xs text-ink truncate">
                        {proj?.name ?? id}
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          update({
                            ...settings,
                            discord_rpc_excluded_projects:
                              settings.discord_rpc_excluded_projects.filter(
                                (x) => x !== id,
                              ),
                          })
                        }
                        aria-label={ts('discord_excluded_remove')}
                        className="focus-ring cursor-pointer shrink-0 w-6 h-6 rounded-md flex items-center justify-center text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                      >
                        <IconX className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  )
                })}
              </div>
            ) : (
              <p className="text-[11px] text-muted/70">
                {ts('discord_excluded_empty')}
              </p>
            )}
          </div>

          <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
            <span className="text-xs font-medium text-muted">
              {ts('discord_custom_label')}
            </span>
            <p className="text-[11px] text-muted leading-relaxed">
              {ts('discord_custom_desc')}
            </p>
            <Dropdown
              trigger={({ toggle }) => (
                <button
                  type="button"
                  onClick={toggle}
                  className="focus-ring cursor-pointer self-start inline-flex items-center gap-1.5 h-8 px-4 rounded-item border border-outline/50 text-muted hover:text-ink hover:border-accent-dim hover:bg-raised text-xs font-medium transition-colors"
                >
                  <IconPlus className="w-3.5 h-3.5" />
                  {ts('discord_custom_add')}
                </button>
              )}
              items={projects
                .filter(
                  (p) =>
                    !settings.discord_rpc_project_presences.some(
                      (pr) => pr.id === p.id,
                    ) &&
                    !settings.discord_rpc_excluded_projects.includes(p.id),
                )
                .map((p) => ({
                  key: p.id,
                  label: p.name,
                  onClick: () =>
                    update({
                      ...settings,
                      discord_rpc_project_presences: [
                        ...settings.discord_rpc_project_presences,
                        { id: p.id, details: null, state: null },
                      ],
                    }),
                }))}
            />
            {settings.discord_rpc_project_presences.length > 0 && (
              <div className="flex flex-col gap-2">
                {settings.discord_rpc_project_presences.map((pr) => {
                  const proj = projects.find((p) => p.id === pr.id)
                  const setPresence = (
                    field: 'details' | 'state',
                    value: string,
                  ) =>
                    update({
                      ...settings,
                      discord_rpc_project_presences:
                        settings.discord_rpc_project_presences.map((x) =>
                          x.id === pr.id
                            ? { ...x, [field]: value || null }
                            : x,
                        ),
                    })
                  return (
                    <div
                      key={pr.id}
                      className="rounded-item bg-raised border border-line p-3 flex flex-col gap-2"
                    >
                      <div className="flex items-center justify-between gap-3">
                        <span className="text-xs font-medium text-ink truncate">
                          {proj?.name ?? pr.id}
                        </span>
                        <button
                          type="button"
                          onClick={() =>
                            update({
                              ...settings,
                              discord_rpc_project_presences:
                                settings.discord_rpc_project_presences.filter(
                                  (x) => x.id !== pr.id,
                                ),
                            })
                          }
                          aria-label={ts('discord_custom_remove')}
                          className="focus-ring cursor-pointer shrink-0 w-6 h-6 rounded-md flex items-center justify-center text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                        >
                          <IconX className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <div className="flex flex-col gap-1.5">
                        <input
                          type="text"
                          value={pr.details ?? ''}
                          onChange={(e) =>
                            setPresence('details', e.target.value)
                          }
                          placeholder={ts('discord_custom_details_placeholder')}
                          className="focus-ring w-full bg-base border border-outline/50 rounded-btn px-3 py-2 text-xs focus:border-accent-dim transition-colors"
                        />
                        <input
                          type="text"
                          value={pr.state ?? ''}
                          onChange={(e) => setPresence('state', e.target.value)}
                          placeholder={ts('discord_custom_state_placeholder')}
                          className="focus-ring w-full bg-base border border-outline/50 rounded-btn px-3 py-2 text-xs focus:border-accent-dim transition-colors"
                        />
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      </Subsection>
    </div>
  )

  const renderAccessibility = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="accessibility-density"
        title={ts('ui_density_label')}
        description={ts('density_desc')}
        searchText={`${ts('ui_density_label')} ${ts('density_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('ui_density_label')}
            display={
              <span className="text-xs font-mono text-ink tabular-nums">
                {Math.round(settings.ui_density * 100)}%
              </span>
            }
            value={settings.ui_density}
            min={0.75}
            max={1.25}
            step={0.05}
            defaultValue={DEFAULT_DENSITY}
            onChange={(v) => update({ ...settings, ui_density: v })}
          />
        </div>
      </Subsection>

      <Subsection
        id="accessibility-text-size"
        title={ts('text_size_label')}
        description={ts('text_size_desc')}
        searchText={`${ts('text_size_label')} ${ts('text_size_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('text_size_label')}
            display={
              <span className="text-xs font-mono text-ink tabular-nums">
                {Math.round(settings.font_scale * 100)}%
              </span>
            }
            value={settings.font_scale}
            min={0.85}
            max={1.3}
            step={0.05}
            defaultValue={DEFAULT_FONT_SCALE}
            onChange={(v) => update({ ...settings, font_scale: v })}
          />
        </div>
      </Subsection>

      <Subsection
        id="accessibility-screen-reader"
        title={ts('screen_reader_label')}
        description={ts('screen_reader_desc')}
        searchText={`${ts('screen_reader_label')} ${ts('screen_reader_desc')} ${ts('screen_reader_beta_desc')} ${ts('accessibility')} ${ts('accessibility_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <SettingRow label={ts('screen_reader_label')}>
          <Toggle
            checked={settings.screen_reader_announcements}
            onChange={(checked) =>
              update({ ...settings, screen_reader_announcements: checked })
            }
            label={ts('screen_reader_label')}
          />
        </SettingRow>
        <p className="text-[11px] text-amber/90 leading-relaxed mt-1">
          {ts('screen_reader_beta_desc')}
        </p>
      </Subsection>

      <Subsection
        id="accessibility-motion"
        title={ts('animation_intensity_label')}
        description={ts('animation_intensity_desc')}
        searchText={`${ts('animation_intensity_label')} ${ts('animation_intensity_desc')} ${ts('animation_full')} ${ts('animation_subtle')} ${ts('animation_none')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <SettingRow label={ts('animation_intensity_label')}>
          <Segmented
            value={settings.animation_intensity}
            onChange={(v) =>
              update({
                ...settings,
                animation_intensity: v as AppSettings['animation_intensity'],
              })
            }
            options={[
              { value: 'full', label: ts('animation_full') },
              { value: 'subtle', label: ts('animation_subtle') },
              { value: 'none', label: ts('animation_none') },
            ]}
          />
        </SettingRow>
      </Subsection>

      <Subsection
        id="accessibility-scrollbars"
        title={ts('show_scrollbar_label')}
        description={ts('scrollbar_desc')}
        searchText={`${ts('show_scrollbar_label')} ${ts('scrollbar_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <SettingRow label={ts('show_scrollbar_label')}>
          <Toggle
            checked={settings.show_scrollbars}
            onChange={(checked) =>
              update({ ...settings, show_scrollbars: checked })
            }
            label={ts('show_scrollbar_label')}
          />
        </SettingRow>
      </Subsection>

      <Subsection
        id="accessibility-tooltip-delay"
        title={ts('tooltip_delay_label')}
        description={ts('tooltip_delay_desc')}
        searchText={`${ts('tooltip_delay_label')} ${ts('tooltip_delay_desc')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex flex-col gap-2">
          <Slider
            label={ts('tooltip_delay_label')}
            display={
              <span className="text-xs text-ink tabular-nums">
                {settings.tooltip_delay}ms
              </span>
            }
            value={settings.tooltip_delay}
            min={100}
            max={1000}
            step={50}
            defaultValue={350}
            onChange={(value) =>
              update({ ...settings, tooltip_delay: value })
            }
          />
        </div>
      </Subsection>
    </div>
  )

  const renderAdvanced = () => (
    <div className="flex flex-col gap-3">
      <Subsection
        id="advanced-setup"
        title={ts('setup_wizard_again')}
        description={ts('setup_wizard_desc')}
        searchText={`${ts('setup_wizard_again')} ${ts('setup_wizard_desc')} ${ts('open_setup')}`}
        query={searchQuery}
        onMatch={reportMatch}
      >
        <div className="flex justify-end">
          <button
            type="button"
            onClick={() => update({ ...settings, setup_complete: false })}
            className="focus-ring cursor-pointer shrink-0 px-5 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
          >
            {ts('open_setup')}
          </button>
        </div>
      </Subsection>

      <div className="flex flex-col gap-3">
        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('check_updates_title')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('updates_desc')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setShowUpdates(true)}
            className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
          >
            <IconRefresh className="w-4 h-4" />
            {ts('check_updates')}
          </button>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('restart_app')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('restart_app_desc')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setConfirmingRestart(true)}
            className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
          >
            <IconRefresh className="w-4 h-4" />
            {ts('restart_app')}
          </button>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('report_bug_title')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('report_bug_desc')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setShowBugReport(true)}
            className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
          >
            <IconBug className="w-4 h-4" />
            {ts('report_bug')}
          </button>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('settings_backup_title')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('settings_backup_desc')}
            </p>
            {settingsMessage && (
              <span className="text-xs text-muted block mt-1.5">
                {settingsMessage}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={handleExportSettings}
              disabled={settingsBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {settingsBusy === 'export'
                ? ts('saving')
                : ts('export_settings_btn')}
            </button>
            <button
              type="button"
              onClick={handleImportSettings}
              disabled={settingsBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {settingsBusy === 'import'
                ? ts('saving')
                : ts('import_settings_btn')}
            </button>
          </div>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('workspace_backup_title')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('workspace_backup_desc')}
            </p>
            {wsBackupMessage && (
              <span className="text-xs text-muted block mt-1.5">
                {wsBackupMessage}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={handleExportWorkspace}
              disabled={wsBackupBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {wsBackupBusy === 'export'
                ? ts('saving')
                : ts('workspace_backup_export_btn')}
            </button>
            <button
              type="button"
              onClick={handleImportWorkspace}
              disabled={wsBackupBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {wsBackupBusy === 'import'
                ? ts('saving')
                : ts('workspace_backup_restore_btn')}
            </button>
          </div>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('app_backup_title')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('app_backup_desc')}
            </p>
            {appBackupMessage && (
              <span className="text-xs text-muted block mt-1.5">
                {appBackupMessage}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={handleExportApp}
              disabled={appBackupBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {appBackupBusy === 'export'
                ? ts('saving')
                : ts('app_backup_export_btn')}
            </button>
            <button
              type="button"
              onClick={handleImportApp}
              disabled={appBackupBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {appBackupBusy === 'import'
                ? ts('saving')
                : ts('app_backup_restore_btn')}
            </button>
          </div>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('reset_settings')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('reset_settings_desc')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setConfirmingReset(true)}
            className="focus-ring cursor-pointer shrink-0 px-5 py-2.5 rounded-item border border-outline/50 text-muted hover:text-danger hover:border-danger/40 hover:bg-danger/5 text-sm font-medium transition-colors"
          >
            {ts('reset')}
          </button>
        </div>

        <div className="rounded-item bg-overlay px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-ink">
              {ts('time_tracking_title')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('time_tracking_desc')}
            </p>
            {statsMessage && (
              <span className="text-xs text-muted block mt-1.5">
                {statsMessage}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={handleExportStats}
              disabled={statsBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {statsBusy === 'export' ? ts('saving') : ts('export_stats_btn')}
            </button>
            <button
              type="button"
              onClick={handleImportStats}
              disabled={statsBusy !== null}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {statsBusy === 'import' ? ts('saving') : ts('import_stats_btn')}
            </button>
          </div>
        </div>

        <div className="rounded-item border border-danger/30 bg-danger/4 px-4 py-4 flex items-center justify-between gap-6">
          <div className="min-w-0">
            <h3 className="text-sm font-medium text-danger">
              {ts('delete_app_data')}
            </h3>
            <p className="text-xs text-muted mt-1.5 leading-relaxed">
              {ts('delete_data_desc')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setConfirmingWipe(true)}
            className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-2.5 rounded-item border border-danger/40 text-danger hover:bg-danger/10 text-sm font-medium transition-colors"
          >
            <IconBomb className="w-4 h-4" />
            {ts('delete_all')}
          </button>
        </div>
      </div>
    </div>
  )

  const renderCredits = () => (
    <div className="flex flex-col gap-3">
      <section className="flex flex-col gap-5 rounded-item bg-overlay px-5 py-5">
        <div>
          <h3 className="font-display font-semibold text-sm">{ts('credits_title')}</h3>
          <p className="text-[11px] text-muted mt-1">{ts('credits_desc')}</p>
        </div>

        <button
          type="button"
          onClick={() => openUrl('https://github.com/RykoTheDev')}
          className="focus-ring cursor-pointer flex items-center gap-4 px-5 py-4 rounded-item border border-outline/50 bg-raised/40 hover:bg-raised transition-colors text-left w-full"
        >
          <img
            src="https://github.com/RykoTheDev.png?size=80"
            alt="RykoTheDev"
            className="w-11 h-11 rounded-full ring-2 ring-accent/20"
            onError={(e) => {
              const img = e.currentTarget
              img.style.display = 'none'
              const fallback = img.nextElementSibling as HTMLElement
              if (fallback) fallback.style.display = 'flex'
            }}
          />
          <span className="w-11 h-11 rounded-full bg-accent/15 border border-accent-dim/30 items-center justify-center text-sm font-bold text-accent hidden">
            R
          </span>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-ink">RykoTheDev</p>
            <p className="text-[11px] text-muted">{ts('credits_developer')}</p>
          </div>
        </button>

        <div className="grid grid-cols-2 gap-3">
          <div className="flex flex-col gap-1 px-4 py-3 rounded-item border border-outline/50 bg-raised/30">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/50">{ts('credits_license')}</span>
            <span className="text-sm font-medium text-ink">MIT</span>
          </div>
          <div className="flex flex-col gap-1 px-4 py-3 rounded-item border border-outline/50 bg-raised/30">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/50">{ts('credits_built_with')}</span>
            <span className="text-sm font-medium text-ink">Tauri + React + TypeScript</span>
          </div>
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/50">{ts('credits_contributors')}</span>
          <div className="flex flex-wrap gap-2">
            {contributors.filter((c) => c.login !== 'RykoTheDev').map((c) => (
              <button
                key={c.login}
                type="button"
                onClick={() => setSelectedContributor({ login: c.login, avatar_url: c.avatar_url })}
                className="focus-ring cursor-pointer inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-outline/50 bg-raised/60 hover:bg-raised transition-colors"
              >
                <img
                  src={c.avatar_url}
                  alt={c.login}
                  className="w-5 h-5 rounded-full"
                  onError={(e) => {
                    const img = e.currentTarget
                    img.style.display = 'none'
                    const fallback = img.nextElementSibling as HTMLElement
                    if (fallback) fallback.style.display = 'flex'
                  }}
                />
                <span className="w-5 h-5 rounded-full bg-accent/15 border border-accent-dim/30 items-center justify-center text-[9px] font-bold text-accent hidden">
                  {c.login[0].toUpperCase()}
                </span>
                <span className="text-xs font-medium text-ink">{c.login}</span>
              </button>
            ))}
          </div>
        </div>
      </section>
    </div>
  )

  const renderContent = () => {
    switch (cat) {
      case 'appearance':
        return renderAppearance()
      case 'display':
        return renderDisplay()
      case 'storage':
        return renderStorage()
      case 'behavior':
        return renderBehavior()
      case 'integrations':
        return renderIntegrations()
      case 'accessibility':
        return renderAccessibility()
      case 'advanced':
        return renderAdvanced()
      case 'credits':
        return renderCredits()
    }
  }

  const activeDef = CATEGORIES.find((c) => c.id === cat)
  const railRefs = useRef<(HTMLButtonElement | null)[]>([])

  const handleCatChange = (next: SettingsCat) => {
    resetSearch()
    setCat(next)
  }

  const handleRailKeyDown = (e: React.KeyboardEvent) => {
    if (e.key !== 'ArrowUp' && e.key !== 'ArrowDown') return
    e.preventDefault()
    const idx = CATEGORIES.findIndex((c) => c.id === cat)
    const next =
      e.key === 'ArrowDown'
        ? CATEGORIES[(idx + 1) % CATEGORIES.length]
        : CATEGORIES[(idx - 1 + CATEGORIES.length) % CATEGORIES.length]
    handleCatChange(next.id)
    railRefs.current[CATEGORIES.findIndex((c) => c.id === next.id)]?.focus()
  }

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <ViewHeader
        connected={connected}
        title={t('settings')}
      >
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder={ts('search_placeholder')}
          inputRef={searchRef}
        />
      </ViewHeader>

      <div className="flex-1 min-h-0 flex gap-4 mt-2">
        <nav
          onKeyDown={handleRailKeyDown}
          aria-label={ts('settings_title')}
          className={`shrink-0 w-52 flex flex-col gap-1 ${connected ? 'pl-3' : ''}`}
        >
          {CATEGORIES.map(({ id, icon: Icon }, railIndex) => {
            const active = cat === id
            return (
              <button
                key={id}
                ref={(el) => {
                  railRefs.current[railIndex] = el
                }}
                type="button"
                onClick={() => handleCatChange(id)}
                className={`focus-ring cursor-pointer relative flex items-center gap-2.5 px-3 py-2.5 rounded-item text-sm font-medium transition-colors ${
                  active
                    ? 'text-ink'
                    : 'text-muted hover:text-ink hover:bg-raised/60'
                }`}
              >
                {active && (
                  <motion.span
                    layoutId="new-ui-settings-cat-pill"
                    transition={{ type: 'spring', stiffness: 650, damping: 38 }}
                    className="absolute inset-0 rounded-item bg-overlay border border-outline/50 shadow-md shadow-black/10 pointer-events-none"
                  />
                )}
                <Icon
                  className={`relative w-4 h-4 shrink-0 transition-colors duration-200 ${
                    active ? 'text-accent' : 'text-muted'
                  }`}
                />
                <span className={`relative ${active ? 'text-ink' : ''}`}>
                  {ts(id)}
                </span>
              </button>
            )
          })}
          {appVersion && (
            <div className="mt-auto pt-6 pl-1">
              <button
                type="button"
                onClick={() => handleCatChange('credits' as SettingsCat)}
                className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1 ${connected ? 'mb-3' : ''} rounded-full border border-outline/50 bg-raised/60 hover:bg-raised text-[10px] font-mono text-muted/60 hover:text-muted transition-colors`}
              >
                {ts('app_version_label', { version: appVersion })}
              </button>
            </div>
          )}
        </nav>

        <div
          className={`flex-1 min-w-0 flex bg-raised overflow-hidden ${
            connected ? 'rounded-tl-tag' : 'rounded-card'
          }`}
        >
          <OverlayScrollArea
            className="flex-1 min-w-0"
            hideThumb={!settings.show_scrollbars}
            hideTopButton
            scrollToTopOn={cat}
          >
            <div className="min-h-full px-5 pb-4">
              <div className="sticky top-0 z-10 -mx-5 px-5 pt-4 pb-3 bg-raised border-b border-line/60 mb-3 flex items-center gap-3">
                {activeDef && (
                  <div className="w-9 h-9 rounded-tile bg-accent/10 border border-accent-dim/30 flex items-center justify-center shrink-0">
                    <activeDef.icon className="w-4.5 h-4.5 text-accent-bright" />
                  </div>
                )}
                <div className="min-w-0">
                  <h2 className="font-display text-lg font-semibold text-ink leading-tight">
                    {ts(cat)}
                  </h2>
                  <p className="text-xs text-muted leading-relaxed">
                    {ts(`${cat}_desc`)}
                  </p>
                </div>
              </div>

              {noResults ? (
                <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
                  <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
                    <IconSearch className="w-5 h-5 text-muted/50" />
                  </div>
                  <p className="text-sm text-muted">{ts('no_settings_match')}</p>
                  <button
                    type="button"
                    onClick={clearSearch}
                    className="focus-ring cursor-pointer text-xs font-medium text-accent hover:text-accent-bright transition-colors"
                  >
                    {ts('clear')}
                  </button>
                </div>
              ) : (
                <motion.div
                  key={cat}
                  {...viewTransition(settings.view_entrance, settings.animation_intensity)}
                >
                  {renderContent()}
                </motion.div>
              )}
            </div>
          </OverlayScrollArea>
        </div>
      </div>

      <AnimatePresence>
        {presetModal && (
          <ThemePresetsModal
            mode={presetModal}
            currentId={settings.theme_preset}
            onSelect={(id) => selectPreset(id)}
            onClose={() => setPresetModal(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingReset && (
          <ConfirmDialog
            title={ts('reset_all_title')}
            description={ts('reset_all_desc')}
            confirmLabel={ts('reset_settings')}
            variant="danger"
            onConfirm={resetAllSettings}
            onCancel={() => setConfirmingReset(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingWipe && (
          <ConfirmDialog
            title={ts('delete_all_title')}
            description={ts('delete_all_desc')}
            confirmLabel={ts('delete_app_data')}
            variant="danger"
            onConfirm={wipeAppData}
            onCancel={() => setConfirmingWipe(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingOsDec !== null && (
          <ConfirmDialog
            title={ts('restart_required_title', { ns: 'common' })}
            description={ts('restart_required_desc', { ns: 'common' })}
            confirmLabel={ts('restart_now', { ns: 'common' })}
            variant="default"
            onConfirm={handleOsDecConfirm}
            onCancel={() => setConfirmingOsDec(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingRestart && (
          <ConfirmDialog
            title={ts('restart_app_confirm_title')}
            description={ts('restart_app_confirm_desc')}
            confirmLabel={ts('restart_app')}
            variant="default"
            onConfirm={handleRestart}
            onCancel={() => setConfirmingRestart(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmClearStats && (
          <ConfirmDialog
            title={ts('clear_stats_confirm_title')}
            description={ts('clear_stats_confirm_desc')}
            confirmLabel={ts('clear_stats_confirm_btn')}
            variant="danger"
            onConfirm={handleClearStats}
            onCancel={() => setConfirmClearStats(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showUpdates && (
          <CheckForUpdatesModal
            onClose={() => setShowUpdates(false)}
            onOpenTokenSettings={() => {
              handleCatChange('integrations')
              setSearchQuery('')
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showBugReport && (
          <BugReportModal onClose={() => setShowBugReport(false)} />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {gitAuthFlow && (
          <GitAuthModal
            provider={gitAuthFlow}
            baseUrl={gitAuthInstance?.baseUrl ?? null}
            clientId={gitAuthInstance?.clientId ?? null}
            onClose={() => {
              setGitAuthFlow(null)
              setGitAuthInstance(null)
            }}
            onConnected={() => {
              void refreshGitAuth()
            }}
          />
        )}
      </AnimatePresence>

      {selectedContributor && (
        <ContributorPRsModal
          login={selectedContributor.login}
          avatarUrl={selectedContributor.avatar_url}
          onClose={() => setSelectedContributor(null)}
        />
      )}

      <AnimatePresence>
        {showRestoreModal && (
          <RestoreProgressModal onClose={() => setShowRestoreModal(false)} />
        )}
      </AnimatePresence>
    </div>
  )
}
