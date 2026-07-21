import { useCallback, useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useSettings } from '../hooks/useSettings'
import { DirList } from '../components/ui/DirList'
import { Toggle } from '../components/ui/Toggle'
import { Slider } from '../components/ui/Slider'
import { ColorSwatchPicker } from '../components/ui/ColorSwatchPicker'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { IconSun, IconMoon, IconHeart, IconRocket, IconBug } from '../components/Icons'
import { api } from '../lib/api'
import { applyTheme } from '../lib/colors'
import {
  applyRadius,
  applyDensity,
  applyFontScale,
  applyReducedMotion,
} from '../lib/appearance'
import { SETTINGS_SEARCH_ITEMS } from '../components/modals/CommandPalette'
import { IconSearch, IconX, IconRefresh } from '../components/Icons'
import type { AppSettings } from '../types'

const DEFAULT_ACCENT = '#457ff2'
const DEFAULT_BG = '#15171c'
const DEFAULT_RADIUS = 5
const DEFAULT_DENSITY = 1.05
const DEFAULT_FONT_SCALE = 1.0

const SAVE_DEBOUNCE_MS = 350

const ACCENT_PRESETS_DARK = [
  '#457ff2',
  '#5865f2',
  '#7983f5',
  '#23a55a',
  '#f0b132',
  '#eb459e',
  '#00a8fc',
  '#2dd4bf',
  '#a78bfa',
  '#f97316',
  '#84cc16',
  '#e11d48',
  '#0ea5e9',
  '#facc15',
  '#8b5cf6',
  '#f23f42',
  '#22c55e',
  '#3b82f6',
  '#f43f5e',
]

const ACCENT_PRESETS_LIGHT = [
  '#457ff2',
  '#5b75e6',
  '#7480e8',
  '#36a05b',
  '#e0a832',
  '#d9458e',
  '#00a1e8',
  '#2dc4b4',
  '#9d7ae0',
  '#ec7031',
  '#78b820',
  '#d1263f',
  '#1b9ce0',
  '#e8c420',
  '#8470e8',
  '#e04244',
  '#28b45a',
  '#4285d4',
  '#d94562',
]

const BG_PRESETS_DARK = [
  '#15171c',
  '#10131a',
  '#1e1f22',
  '#111214',
  '#13151a',
  '#0f1115',
  '#20232a',
  '#171a21',
  '#1c1e24',
  '#1a1c23',
  '#0d0e11',
  '#232630',
  '#1b1d24',
  '#101114',
  '#191b20',
  '#181a1e',
  '#1f2127',
  '#1a1c21',
  '#0e1014',
  '#1c1e23',
  '#121418',
]

const BG_PRESETS_LIGHT = [
  '#f8f9fa',
  '#ffffff',
  '#f0f2f5',
  '#f5f5f5',
  '#fafafa',
  '#eceff1',
  '#f3f4f6',
  '#f9fafb',
  '#eef1f5',
  '#f8f6f3',
  '#f2f6fc',
  '#faf5ef',
  '#edf2f7',
  '#f6f8fa',
  '#f1f3f5',
  '#e8ecf1',
  '#faf6f0',
]

const DEFAULT_BG_LIGHT = '#f8f9fa'
const DEFAULT_BG_DARK = '#15171c'

function randomHex(): string {
  return (
    '#' +
    Math.floor(Math.random() * 0x1000000)
      .toString(16)
      .padStart(6, '0')
  )
}

function randomConstrainedHex(minSum: number, maxSum: number): string {
  for (let i = 0; i < 100; i++) {
    const hex = randomHex()
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    const sum = r + g + b
    if (sum >= minSum && sum <= maxSum) return hex
  }
  return '#808080'
}

type SettingsTab =
  'storage' | 'behavior' | 'display' | 'appearance' | 'advanced'

const TABS: { id: SettingsTab; label: string }[] = [
  { id: 'storage', label: 'Storage' },
  { id: 'behavior', label: 'Behavior' },
  { id: 'display', label: 'Display' },
  { id: 'appearance', label: 'Appearance' },
  { id: 'advanced', label: 'Advanced' },
]

function SectionCard({
  title,
  description,
  children,
}: {
  title: string
  description: string
  children: React.ReactNode
}) {
  return (
    <section className="flex flex-col gap-4 rounded-xl border border-line bg-surface/60 p-6">
      <div>
        <h3 className="font-display font-semibold">{title}</h3>
        <p className="text-xs text-muted mt-1.5 leading-relaxed">
          {description}
        </p>
      </div>
      {children}
    </section>
  )
}

type SaveState = 'idle' | 'saving' | 'saved'

function KeyRecorder({
  value,
  onChange,
  onReset,
}: {
  value: string
  onChange: (key: string) => void
  onReset?: () => void
}) {
  const [listening, setListening] = useState(false)
  const [confirmMsg, setConfirmMsg] = useState<string | null>(null)
  const confirmTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const btnRef = useRef<HTMLButtonElement>(null)
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange
  const mod = navigator.platform.includes('Mac') ? '⌘' : 'Ctrl+'

  useEffect(() => {
    if (!listening) return

    const handler = (e: KeyboardEvent) => {
      e.preventDefault()
      e.stopPropagation()

      if (e.key === 'Escape') {
        setListening(false)
        return
      }

      if (e.key.length !== 1) return

      const captured = e.key === ' ' ? ' ' : e.key.toLowerCase()
      onChangeRef.current(captured)
      setListening(false)

      const label = captured === ' ' ? 'Space' : captured.toUpperCase()
      setConfirmMsg(`✓ ${mod}${label}`)
      if (confirmTimer.current) clearTimeout(confirmTimer.current)
      confirmTimer.current = setTimeout(() => setConfirmMsg(null), 1500)
    }

    window.addEventListener('keydown', handler, true)
    return () => window.removeEventListener('keydown', handler, true)
  }, [listening])

  useEffect(() => {
    return () => {
      if (confirmTimer.current) clearTimeout(confirmTimer.current)
    }
  }, [])

  const displayKey =
    value === ' ' ? 'Space' : value ? value.toUpperCase() : '—'

  return (
    <label className="flex flex-col gap-2.5 pt-5 border-t border-line">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-muted block">
          Command palette shortcut
        </span>
        {value !== 'p' && onReset && (
          <button
            type="button"
            onClick={() => {
              onReset()
              setConfirmMsg(`✓ ${mod}P`)
              if (confirmTimer.current) clearTimeout(confirmTimer.current)
              confirmTimer.current = setTimeout(() => setConfirmMsg(null), 1500)
            }}
            className="focus-ring cursor-pointer text-[10px] font-medium text-muted/60 hover:text-accent transition-colors"
          >
            Reset to default
          </button>
        )}
      </div>
      <p className="text-[11px] text-muted mt-0.5 leading-relaxed">
        Click the button below, then press any key to rebind.{' '}
        Press{' '}
        <kbd className="font-mono text-[10px] px-1 py-0.5 rounded bg-raised border border-line">Esc</kbd>
        {' '}to cancel.
      </p>
      <div className="flex items-center gap-3">
        <button
          ref={btnRef}
          type="button"
          onClick={() => setListening((l) => !l)}
          className={`focus-ring cursor-pointer relative flex items-center justify-center gap-2 px-5 py-3 rounded-xl border text-sm font-mono font-semibold transition-all ${
            listening
              ? 'border-accent bg-accent/10 text-accent-bright'
              : 'border-line bg-raised text-ink hover:border-accent-dim hover:bg-raised/80'
          }`}
        >
          {listening ? (
            <>
              <span className="inline-block w-2 h-2 rounded-full bg-accent animate-pulse" />
              <span>Press a key…</span>
            </>
          ) : (
            <>
              <kbd className="text-xs px-2 py-0.5 rounded bg-surface border border-line/50">
                {mod}{displayKey}
              </kbd>
              <span className="text-xs font-normal text-muted">Click to rebind</span>
            </>
          )}
        </button>

        <AnimatePresence mode="wait">
          {confirmMsg && (
            <motion.span
              key={confirmMsg}
              initial={{ opacity: 0, x: -4 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 4 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
              className="text-xs text-accent font-medium shrink-0"
            >
              {confirmMsg}
            </motion.span>
          )}
        </AnimatePresence>
      </div>
    </label>
  )
}

function SaveStatus({ state }: { state: SaveState }) {
  return (
    <div className="h-4 flex items-center">
      <AnimatePresence mode="wait">
        {state === 'saving' && (
          <motion.span
            key="saving"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="text-xs text-muted"
          >
            Saving…
          </motion.span>
        )}
        {state === 'saved' && (
          <motion.span
            key="saved"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="text-xs text-accent"
          >
            Saved
          </motion.span>
        )}
      </AnimatePresence>
    </div>
  )
}

interface SettingsViewProps {
  highlightSetting?: string | null
  onHighlightDone?: () => void
}

export function SettingsView({
  highlightSetting,
  onHighlightDone,
}: SettingsViewProps = {}) {
  const { settings, update, resetToDefaults, loaded } = useSettings()
  const [current, setCurrent] = useState<AppSettings | null>(null)
  const [scanMessage, setScanMessage] = useState<string | null>(null)
  const [saveState, setSaveState] = useState<SaveState>('idle')
  const [confirmingReset, setConfirmingReset] = useState(false)
  const [confirmingWipe, setConfirmingWipe] = useState(false)
  const [tab, setTab] = useState<SettingsTab>('storage')
  const [settingsSearchQuery, setSettingsSearchQuery] = useState('')

  const [sidebarExpandedWidth, setSidebarExpandedWidth] = useState(() => {
    try {
      return Math.min(
        400,
        Math.max(160, Number(localStorage.getItem('sidebar_width_expanded'))),
      )
    } catch {}
    return 230
  })
  const [sidebarCollapsedWidth, setSidebarCollapsedWidth] = useState(() => {
    try {
      return Math.min(
        120,
        Math.max(50, Number(localStorage.getItem('sidebar_width_collapsed'))),
      )
    } catch {}
    return 76
  })

  const saveTimeout = useRef<ReturnType<typeof setTimeout> | null>(null)
  const savedIndicatorTimeout = useRef<ReturnType<typeof setTimeout> | null>(
    null,
  )

  useEffect(() => {
    if (!highlightSetting) return

    if (highlightSetting === 'feeling_lucky') {
      onHighlightDone?.()
      feelingLucky()
      return
    }
    if (highlightSetting === 'reset_colors') {
      onHighlightDone?.()
      resetThemeColors()
      return
    }

    const sectionMap: Record<string, { tab: SettingsTab; section: string }> = {
      project_scan_dirs: { tab: 'storage', section: 'storage-folders' },
      version_scan_dirs: { tab: 'storage', section: 'storage-folders' },
      default_project_location: { tab: 'storage', section: 'storage-folders' },
      download_dir: { tab: 'storage', section: 'storage-folders' },
      scan_depth: { tab: 'storage', section: 'storage-folders' },
      download_concurrency: { tab: 'storage', section: 'storage-folders' },
      close_on_project_open: { tab: 'behavior', section: 'behavior' },
      minimize_to_tray: { tab: 'behavior', section: 'behavior' },
      reopen_after_godot_closes: { tab: 'behavior', section: 'behavior' },              auto_scan_on_startup: { tab: 'behavior', section: 'behavior-projects' },
      auto_watch_project_dirs: { tab: 'behavior', section: 'behavior-projects' },
      auto_watch_version_dirs: { tab: 'behavior', section: 'behavior-projects' },
      auto_watch_template_dir: { tab: 'behavior', section: 'behavior-projects' },
      categories_enabled: { tab: 'behavior', section: 'behavior-projects' },
      workspaces_enabled: { tab: 'behavior', section: 'behavior-projects' },
      check_updates: { tab: 'advanced', section: 'advanced-updates' },
      export_settings: { tab: 'advanced', section: 'advanced-export' },
      import_settings: { tab: 'advanced', section: 'advanced-export' },
      tooltip_delay: { tab: 'behavior', section: 'behavior-projects' },
      tray_recent_projects_count: { tab: 'behavior', section: 'behavior' },
      command_palette_keybind: { tab: 'behavior', section: 'behavior' },
      last_opened_time_format: { tab: 'display', section: 'display' },
      last_opened_date_format: { tab: 'display', section: 'display' },
      theme_mode: { tab: 'appearance', section: 'appearance' },
      accent_color: { tab: 'appearance', section: 'appearance' },
      background_color: { tab: 'appearance', section: 'appearance' },
      corner_radius: { tab: 'appearance', section: 'appearance' },
      ui_density: { tab: 'appearance', section: 'appearance' },
      font_scale: { tab: 'appearance', section: 'appearance' },
      reduce_motion: { tab: 'appearance', section: 'appearance' },
      sidebar_width: { tab: 'appearance', section: 'appearance' },
      setup_wizard: { tab: 'advanced', section: 'advanced-setup' },
      reset_settings: { tab: 'advanced', section: 'advanced-reset' },
      delete_app_data: { tab: 'advanced', section: 'advanced-delete' },
    }

    const info = sectionMap[highlightSetting]
    if (!info) {
      onHighlightDone?.()
      return
    }
    setTab(info.tab)
    const t = setTimeout(() => {
      const el = document.querySelector(
        `[data-section-id="${info.section}"]`,
      )
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' })
        el.classList.add('setting-highlight')
        setTimeout(() => {
          el.classList.remove('setting-highlight')
          onHighlightDone?.()
        }, 1500)
      } else {
        onHighlightDone?.()
      }
    }, 200)
    return () => clearTimeout(t)
  }, [highlightSetting])

  useEffect(() => {
    if (loaded && current === null) {
      const projectDirs =
        settings.default_project_location &&
        !settings.project_scan_dirs.includes(settings.default_project_location)
          ? [...settings.project_scan_dirs, settings.default_project_location]
          : settings.project_scan_dirs
      const versionDirs =
        settings.download_dir &&
        !settings.version_scan_dirs.includes(settings.download_dir)
          ? [...settings.version_scan_dirs, settings.download_dir]
          : settings.version_scan_dirs
      setCurrent({
        ...settings,
        project_scan_dirs: projectDirs,
        version_scan_dirs: versionDirs,
      })
    }
  }, [loaded, settings])

  useEffect(() => {
    return () => {
      if (saveTimeout.current) clearTimeout(saveTimeout.current)
      if (savedIndicatorTimeout.current)
        clearTimeout(savedIndicatorTimeout.current)
    }
  }, [])

  const persist = useCallback(
    (next: AppSettings) => {
      if (saveTimeout.current) clearTimeout(saveTimeout.current)
      if (savedIndicatorTimeout.current)
        clearTimeout(savedIndicatorTimeout.current)
      setSaveState('saving')
      saveTimeout.current = setTimeout(async () => {
        await update(next)
        api.restartWatchers().catch(() => {})
        setSaveState('saved')
        savedIndicatorTimeout.current = setTimeout(
          () => setSaveState('idle'),
          1500,
        )
      }, SAVE_DEBOUNCE_MS)
    },
    [update],
  )

  const setField = <K extends keyof AppSettings>(
    key: K,
    value: AppSettings[K],
  ) => {
    setCurrent((prev) => {
      if (!prev) return prev
      const next = { ...prev, [key]: value }
      persist(next)
      return next
    })
  }

  const setFields = (patch: Partial<AppSettings>) => {
    setCurrent((prev) => {
      if (!prev) return prev
      const next = { ...prev, ...patch }
      persist(next)
      return next
    })
  }

  if (!loaded || !current)
    return <div className="p-10 text-sm text-muted">Loading settings…</div>

  const runScan = async () => {
    setScanMessage('Scanning…')
    const [projects, versions] = await Promise.all([
      current.project_scan_dirs.length
        ? api.scanForProjects(current.project_scan_dirs, current.scan_depth)
        : Promise.resolve([]),
      current.version_scan_dirs.length
        ? api.scanForVersions(current.version_scan_dirs, current.scan_depth)
        : Promise.resolve([]),
    ])
    setScanMessage(
      `Found ${projects.length} new project${projects.length === 1 ? '' : 's'} and ${versions.length} new version${versions.length === 1 ? '' : 's'}.`,
    )
  }

  const previewTheme = (
    accent: string,
    background: string,
    mode = current.theme_mode,
  ) => applyTheme(accent, background, mode)

  const feelingLucky = () => {
    const resolvedMode = current.theme_mode
    const bg =
      resolvedMode === 'light'
        ? randomConstrainedHex(576, 735)
        : randomConstrainedHex(48, 384)
    const accent = randomHex()
    setFields({ accent_color: accent, background_color: bg })
    previewTheme(accent, bg)
  }

  const resetThemeColors = () => {
    const resolvedMode = current.theme_mode
    const accent = DEFAULT_ACCENT
    const bg = resolvedMode === 'light' ? DEFAULT_BG_LIGHT : DEFAULT_BG_DARK
    setFields({ accent_color: accent, background_color: bg })
    previewTheme(accent, bg)
  }

  const setThemeMode = (mode: 'dark' | 'light') => {
    const bg = mode === 'light' ? DEFAULT_BG_LIGHT : DEFAULT_BG_DARK
    setFields({ theme_mode: mode, background_color: bg })
    previewTheme(current.accent_color, bg, mode)
  }
  const resetAppearance = () => {
    setFields({
      accent_color: DEFAULT_ACCENT,
      background_color: DEFAULT_BG,
      corner_radius: DEFAULT_RADIUS,
      ui_density: DEFAULT_DENSITY,
      font_scale: DEFAULT_FONT_SCALE,
      reduce_motion: false,
      theme_mode: 'dark',
    })
    previewTheme(DEFAULT_ACCENT, DEFAULT_BG, 'dark')
    applyRadius(DEFAULT_RADIUS)
    applyDensity(DEFAULT_DENSITY)
    applyFontScale(DEFAULT_FONT_SCALE)
    applyReducedMotion(false)
  }

  const resetAllSettings = async () => {
    if (saveTimeout.current) clearTimeout(saveTimeout.current)
    if (savedIndicatorTimeout.current)
      clearTimeout(savedIndicatorTimeout.current)
    setConfirmingReset(false)
    setSaveState('saving')
    const defaults = await resetToDefaults()
    setCurrent(defaults)
    setSaveState('saved')
    savedIndicatorTimeout.current = setTimeout(() => setSaveState('idle'), 1500)
  }

  const wipeAppData = async () => {
    setConfirmingWipe(false)
    await api.resetAppData()
    window.location.reload()
  }

  return (
    <div className="p-10 pt-15 max-w-8xl mx-auto gap-6 flex flex-col">        <div className="flex items-start justify-between">
        <div>
          <h2 className="font-body font-semibold text-3xl tracking-tight">
            SETTINGS
          </h2>
          <p className="text-xs text-muted">
            Storage locations, auto-scan folders, and appearance.
          </p>
        </div>
        <SaveStatus state={saveState} />
      </div>

      {/* Settings search */}
      <div className="relative">
        <div className="relative">
          <IconSearch className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted/50 pointer-events-none" />
          <input
            type="text"
            value={settingsSearchQuery}
            onChange={(e) => setSettingsSearchQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Escape') {
                setSettingsSearchQuery('')
                ;(e.target as HTMLInputElement).blur()
              }
            }}
            placeholder="Search settings…"
            className="focus-ring w-full bg-raised border border-line rounded-xl pl-10 pr-4 py-3 text-sm focus:border-accent-dim transition-colors"
          />
          {settingsSearchQuery && (
            <button
              onClick={() => setSettingsSearchQuery('')}
              className="focus-ring cursor-pointer absolute right-3 top-1/2 -translate-y-1/2 p-1 rounded-md text-muted hover:text-ink hover:bg-surface transition-colors"
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        {/* Search results dropdown */}
        {settingsSearchQuery.trim() && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            className="absolute left-0 right-0 top-full mt-2 bg-surface border border-line rounded-xl shadow-2xl shadow-black/30 overflow-hidden z-50"
          >
            {(() => {
              const q = settingsSearchQuery.trim().toLowerCase()
              const matches = SETTINGS_SEARCH_ITEMS.filter(
                (item) =>
                  item.label.toLowerCase().includes(q) ||
                  item.key.toLowerCase().includes(q),
              )
              if (matches.length === 0) {
                return (
                  <div className="px-4 py-6 text-center">
                    <p className="text-xs text-muted">
                      No settings match{' '}
                      <span className="font-mono text-ink">"{settingsSearchQuery}"</span>
                    </p>
                  </div>
                )
              }
              return (
                <div className="max-h-60 overflow-y-auto p-1.5">
                  {matches.map((item) => (
                    <button
                      key={item.key}
                      onClick={() => {
                        setSettingsSearchQuery('')
                        setTab(item.tab as SettingsTab)
                        // Dispatch to highlight the setting
                        window.dispatchEvent(
                          new CustomEvent('app:open-setting', { detail: item.key }),
                        )
                      }}
                      className="focus-ring cursor-pointer w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-left transition-colors hover:bg-raised text-muted hover:text-ink"
                    >
                      <span className="flex-1">{item.label}</span>
                      <span className="text-[10px] font-medium text-muted/50 uppercase tracking-wider">
                        {item.tab}
                      </span>
                    </button>
                  ))}
                </div>
              )
            })()}
          </motion.div>
        )}
      </div>

      {/* Tab bar */}
      <div className="inline-flex self-start rounded-lg border border-line bg-raised p-1 gap-1">
        {TABS.map(({ id, label }) => (
          <motion.button
            key={id}
            whileTap={{ scale: 0.96 }}
            onClick={() => setTab(id)}
            className={
              'focus-ring cursor-pointer px-4 py-1.5 rounded-md text-xs font-medium transition-colors ' +
              (tab === id
                ? 'bg-accent text-white shadow-sm'
                : 'text-muted hover:text-ink hover:bg-overlay/60')
            }
          >
            {label}
          </motion.button>
        ))}
      </div>

      <AnimatePresence mode="wait">
        {tab === 'storage' && (
          <motion.div
            key="storage"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.12 }}
          >
            <div data-section-id="storage-folders">
            <SectionCard
              title="Storage & Auto-scan"
              description="Folders GodotHub checks at startup. Star a folder to also use it as the default location for new projects/downloads."
            >
              <div className="flex flex-col gap-6">
                <div className="flex flex-col gap-2.5">
                  <span className="text-xs font-medium text-muted">
                    Projects
                  </span>
                  <DirList
                    dirs={current.project_scan_dirs}
                    onChange={(dirs) => setField('project_scan_dirs', dirs)}
                    emptyHint="No folders added, nothing will be scanned at startup, and new projects will ask where to save each time."
                    defaultDir={current.default_project_location}
                    onSetDefault={(dir) =>
                      setField('default_project_location', dir)
                    }
                    defaultLabel="New project default"
                    showFallbackDescription={false}
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    Scanned at startup for existing projects. The starred folder
                    pre-fills the "Location" field in the New Project dialog.
                  </p>
                </div>

                <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
                  <span className="text-xs font-medium text-muted">
                    Godot versions
                  </span>
                  <DirList
                    dirs={current.version_scan_dirs}
                    onChange={(dirs) => setField('version_scan_dirs', dirs)}
                    emptyHint="No folders added, nothing will be scanned at startup, and new downloads will use the app data folder."
                    defaultDir={current.download_dir}
                    onSetDefault={(dir) => setField('download_dir', dir)}
                    defaultLabel="Download folder"
                    showFallbackDescription={true}
                    fallbackDownloadPath="AppData\\Roaming\\com.ryko.godothub\\godot-versions\\"
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    Scanned at startup for installed Godot executables. The
                    starred folder is where new Godot versions are extracted
                    when you install them.
                  </p>
                </div>

                <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
                  <span className="text-xs font-medium text-muted">
                    Templates
                  </span>
                  <div className="flex items-center gap-2.5">
                    {current.template_scan_dir ? (
                      <>
                        <input
                          readOnly
                          value={current.template_scan_dir}
                          className="flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-xs font-mono"
                        />
                        <motion.button
                          whileHover={{ y: -1 }}
                          whileTap={{ scale: 0.96 }}
                          onClick={() => setField('template_scan_dir', null)}
                          className="focus-ring cursor-pointer px-3 py-2 rounded-lg border border-line text-xs text-muted hover:text-danger hover:border-danger/30 hover:bg-danger/10 transition-colors"
                        >
                          Clear
                        </motion.button>
                      </>
                    ) : (
                      <span className="text-xs text-muted">
                        No folder set. You can still import manually or use 'Save as Template'.
                      </span>
                    )}
                    <motion.button
                      whileHover={{ y: -1 }}
                      whileTap={{ scale: 0.96 }}
                      onClick={async () => {
                        const folder = await api.pickFolder()
                        if (folder) setField('template_scan_dir', folder)
                      }}
                      className="focus-ring cursor-pointer px-3.5 py-2 rounded-lg border border-line text-xs hover:border-accent-dim hover:bg-raised transition-colors"
                    >
                      Browse
                    </motion.button>
                  </div>
                  <p className="text-[11px] text-muted leading-relaxed">
                    Any subfolders inside this directory will be imported as
                    templates when you click 'Import from Directory' in the
                    Templates view.
                  </p>
                </div>

                <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
                  <div className="flex items-center justify-between gap-4">
                    <span className="text-xs font-medium text-muted">
                      Scan depth
                    </span>
                    <span className="text-xs text-ink tabular-nums">
                      {current.scan_depth} folder
                      {current.scan_depth === 1 ? '' : 's'} deep
                    </span>
                  </div>
                  <Slider
                    value={current.scan_depth}
                    min={1}
                    max={10}
                    onChange={(value) => setField('scan_depth', value)}
                    label="Scan depth"
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    How many folders deep to look inside each scan folder above.
                    Lower is faster and avoids picking up unrelated
                    projects/versions buried in nested subfolders; higher digs
                    further if yours are deeply nested.
                  </p>
                </div>

                <div className="flex flex-col gap-2.5 pt-5 border-t border-line">
                  <div className="flex items-center justify-between gap-4">
                    <span className="text-xs font-medium text-muted">
                      Simultaneous downloads
                    </span>
                    <span className="text-xs text-ink tabular-nums">
                      {current.download_concurrency} at once
                    </span>
                  </div>
                  <Slider
                    value={current.download_concurrency}
                    min={1}
                    max={10}
                    onChange={(value) =>
                      setField('download_concurrency', value)
                    }
                    label="Simultaneous downloads"
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    How many Godot versions can download at the same time. Extra
                    downloads wait in a queue and start automatically as slots
                    free up.
                  </p>
                </div>

                <div className="flex items-center gap-3 pt-5 border-t border-line">
                  <motion.button
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    onClick={runScan}
                    className="focus-ring cursor-pointer px-5 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                  >
                    Scan Now
                  </motion.button>
                  {scanMessage && (
                    <span className="text-xs text-muted">{scanMessage}</span>
                  )}
                </div>
              </div>
            </SectionCard>
            </div>
          </motion.div>
        )}

        {tab === 'behavior' && (
          <motion.div
            key="behavior"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.12 }}
            className="flex flex-col gap-6"
          >
            <div data-section-id="behavior">
            <SectionCard
              title="Behavior"
              description="How GodotHub acts when you launch a project."
            >
              <div className="flex flex-col gap-5">
                <label className="flex items-center justify-between gap-4">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Close application on project open
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Quits GodotHub automatically as soon as a project is
                      launched in Godot.
                    </p>
                  </div>
                  <Toggle
                    checked={current.close_on_project_open}
                    onChange={(checked) =>
                      setField('close_on_project_open', checked)
                    }
                    label="Close application on project open"
                  />
                </label>

                <label className="flex items-center justify-between gap-4 pt-5 border-t border-line">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Minimize to system tray on closing app
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Keeps GodotHub running in the system tray instead of
                      quitting when you close the window. Use the tray icon to
                      reopen or quit.
                    </p>
                  </div>
                  <Toggle
                    checked={current.minimize_to_tray}
                    onChange={(checked) =>
                      setField('minimize_to_tray', checked)
                    }
                    label="Minimize to system tray on closing app"
                  />
                </label>

                <AnimatePresence initial={false}>
                  {current.close_on_project_open &&
                    current.minimize_to_tray && (
                      <motion.label
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.2, ease: 'easeOut' }}
                        className="flex items-center justify-between gap-4 pt-5 border-t border-line overflow-hidden"
                      >
                        <div>
                          <span className="text-xs font-medium text-muted block">
                            Reopen after closing Godot
                          </span>
                          <p className="text-[11px] text-muted mt-1 leading-relaxed">
                            Brings GodotHub back out of the system tray
                            automatically once the Godot editor for that project
                            is closed.
                          </p>
                        </div>
                        <Toggle
                          checked={current.reopen_after_godot_closes}
                          onChange={(checked) =>
                            setField('reopen_after_godot_closes', checked)
                          }
                          label="Reopen after closing Godot"
                        />
                      </motion.label>
                    )}
                </AnimatePresence>

                <label className="flex flex-col gap-2.5 pt-5 border-t border-line">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-muted">
                      Tray recent projects
                    </span>
                    <span className="text-xs text-ink tabular-nums">
                      {current.tray_recent_projects_count} project{current.tray_recent_projects_count === 1 ? '' : 's'}
                    </span>
                  </div>
                  <Slider
                    value={current.tray_recent_projects_count}
                    min={1}
                    max={10}
                    onChange={(value) => {
                      setField('tray_recent_projects_count', value)
                      api.refreshTrayMenu().catch(() => {})
                    }}
                    label="Tray recent projects"
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    How many recently opened projects appear in the system tray
                    context menu. Set between 1 and 10.
                  </p>
                </label>

                <KeyRecorder
                  value={current.command_palette_keybind}
                  onChange={(value) => setField('command_palette_keybind', value)}
                  onReset={() => setField('command_palette_keybind', 'p')}
                />
              </div>
            </SectionCard>
            </div>

            <div data-section-id="behavior-projects">
            <SectionCard
              title="Projects"
              description="How projects are organized in GodotHub."
            >
              <div className="flex flex-col gap-5">
                <label className="flex items-center justify-between gap-4">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Auto-scan on startup
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Automatically scans your configured project and version
                      folders for new additions every time GodotHub starts. You
                      can still scan manually anytime from the Projects and
                      Versions views.
                    </p>
                  </div>
                  <Toggle
                    checked={current.auto_scan_on_startup}
                    onChange={(checked) =>
                      setField('auto_scan_on_startup', checked)
                    }
                    label="Auto-scan on startup"
                  />
                </label>

                <label className="flex items-center justify-between gap-4 pt-5 border-t border-line">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Use categories
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Turns off categories entirely, no Categories button, no
                      category filter, no Uncategorized bucket. Projects shows
                      one plain list. Existing category assignments are kept and
                      come back if you turn this on again.
                    </p>
                  </div>
                  <Toggle
                    checked={current.categories_enabled}
                    onChange={(checked) =>
                      setField('categories_enabled', checked)
                    }
                    label="Use categories"
                  />
                </label>

                <label className="flex items-center justify-between gap-4 pt-5 border-t border-line">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Use workspaces
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Turns off workspaces entirely, no workspace switcher, no
                      "add workspace" button. GodotHub behaves as if there were
                      only the one currently-active workspace. Existing
                      workspaces are kept and the switcher comes back if you
                      turn this on again.
                    </p>
                  </div>
                  <Toggle
                    checked={current.workspaces_enabled}
                    onChange={(checked) =>
                      setField('workspaces_enabled', checked)
                    }
                    label="Use workspaces"
                  />
                </label>

                <label className="flex flex-col gap-2.5 pt-5 border-t border-line">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-muted">
                      Tooltip delay
                    </span>
                    <span className="text-xs text-ink tabular-nums">
                      {current.tooltip_delay}ms
                    </span>
                  </div>
                  <Slider
                    value={current.tooltip_delay}
                    min={100}
                    max={1000}
                    step={50}
                    onChange={(value) =>
                      setField('tooltip_delay', value)
                    }
                    label="Tooltip delay"
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    How long to wait before showing tooltips when hovering over
                    buttons, icons, and sidebar items. Lower values feel more
                    responsive; higher values reduce distraction.
                  </p>
                </label>

              </div>
            </SectionCard>
            </div>

            <div data-section-id="behavior-watchers">
            <SectionCard
              title="File Watchers"
              description="Automatically detect changes in your scan folders and keep projects, versions, and templates up to date without clicking Sync."
            >
              <div className="flex flex-col gap-5">
                <label className="flex items-center justify-between gap-4">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Watch project folders
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Automatically scans for new or removed projects whenever
                      files change inside your configured project scan folders.
                      New project folders are added to your library; removed
                      ones are left in place but unregistered.
                    </p>
                  </div>
                  <Toggle
                    checked={current.auto_watch_project_dirs}
                    onChange={(checked) =>
                      setField('auto_watch_project_dirs', checked)
                    }
                    label="Watch project folders"
                  />
                </label>

                <label className="flex items-center justify-between gap-4 pt-5 border-t border-line">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Watch version folders
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Automatically scans for new or removed Godot executables
                      whenever files change inside your configured version scan
                      folders. New executables are added to your installed
                      versions list.
                    </p>
                  </div>
                  <Toggle
                    checked={current.auto_watch_version_dirs}
                    onChange={(checked) =>
                      setField('auto_watch_version_dirs', checked)
                    }
                    label="Watch version folders"
                  />
                </label>

                <label className="flex items-center justify-between gap-4 pt-5 border-t border-line">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Watch template directory
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Automatically syncs templates whenever files change inside
                      your template scan directory. Edit a template folder and
                      the template content updates automatically.
                    </p>
                  </div>
                  <Toggle
                    checked={current.auto_watch_template_dir}
                    onChange={(checked) =>
                      setField('auto_watch_template_dir', checked)
                    }
                    label="Watch template directory"
                  />
                </label>

                <p className="text-[10px] text-muted/50 mt-1 leading-relaxed">
                  Watchers use debounced file system events. Changes are detected within a
                  few seconds of the last file save. Disabling a watcher frees system resources.
                </p>
              </div>
            </SectionCard>
            </div>
          </motion.div>
        )}

        {tab === 'display' && (
          <motion.div
            key="display"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.12 }}
          >
            <div data-section-id="display">
            <SectionCard
              title="Last Opened Display"
              description={
                'Controls the "last opened" pill shown on project cards. Hidden entirely for projects that have never been opened.'
              }
            >
              <div className="flex flex-col gap-6">
                <div className="flex flex-col gap-2.5">
                  <span className="text-xs font-medium text-muted">
                    Time format (shown when opened today)
                  </span>
                  <div className="inline-flex self-start rounded-lg border border-line bg-raised p-1 gap-1">
                    {[
                      { value: '12h' as const, label: '12-hour (2:30 PM)' },
                      { value: '24h' as const, label: '24-hour (14:30)' },
                    ].map(({ value, label }) => {
                      const active = current.last_opened_time_format === value
                      return (
                        <motion.button
                          key={value}
                          whileTap={{ scale: 0.96 }}
                          onClick={() =>
                            setField('last_opened_time_format', value)
                          }
                          className={
                            'focus-ring cursor-pointer px-3.5 py-1.5 rounded-md text-xs font-medium transition-colors ' +
                            (active
                              ? 'bg-accent text-white'
                              : 'text-muted hover:text-ink hover:bg-overlay/60')
                          }
                        >
                          {label}
                        </motion.button>
                      )
                    })}
                  </div>
                </div>

                <div className="flex flex-col gap-2.5">
                  <span className="text-xs font-medium text-muted">
                    Date format (shown for any other day)
                  </span>
                  <div className="inline-flex self-start rounded-lg border border-line bg-raised p-1 gap-1">
                    {[
                      { value: 'DD-MM-YYYY' as const, label: 'DD-MM-YYYY' },
                      { value: 'MM-DD-YYYY' as const, label: 'MM-DD-YYYY' },
                      { value: 'YYYY-MM-DD' as const, label: 'YYYY-MM-DD' },
                    ].map(({ value, label }) => {
                      const active = current.last_opened_date_format === value
                      return (
                        <motion.button
                          key={value}
                          whileTap={{ scale: 0.96 }}
                          onClick={() =>
                            setField('last_opened_date_format', value)
                          }
                          className={
                            'focus-ring cursor-pointer px-3.5 py-1.5 rounded-md text-xs font-mono font-medium transition-colors ' +
                            (active
                              ? 'bg-accent text-white'
                              : 'text-muted hover:text-ink hover:bg-overlay/60')
                          }
                        >
                          {label}
                        </motion.button>
                      )
                    })}
                  </div>
                </div>
              </div>
            </SectionCard>
            </div>
          </motion.div>
        )}

        {tab === 'appearance' && (
          <motion.div
            key="appearance"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.12 }}
          >
            <div data-section-id="appearance">
            <SectionCard
              title="Appearance"
              description="Changes apply instantly across the whole app."
            >
              <div className="flex flex-col gap-7">
                <div className="flex flex-col gap-2.5">
                  <span className="text-xs font-medium text-muted">Theme</span>
                  <div className="flex items-center gap-3 flex-wrap">
                    {/* Dark / Light */}
                    <div className="inline-flex self-start rounded-lg border border-line bg-raised p-1 gap-1">
                      {[
                        { mode: 'dark' as const, label: 'Dark', Icon: IconMoon },
                        { mode: 'light' as const, label: 'Light', Icon: IconSun },
                      ].map(({ mode, label, Icon }) => {
                        const active = current.theme_mode === mode
                        return (
                          <motion.button
                            key={mode}
                            whileTap={{ scale: 0.96 }}
                            onClick={() => setThemeMode(mode)}
                            className={
                              'focus-ring cursor-pointer flex items-center gap-2 px-3.5 py-1.5 rounded-md text-sm font-medium transition-colors ' +
                              (active
                                ? 'bg-accent text-white'
                                : 'text-muted hover:text-ink hover:bg-overlay/60')
                            }
                          >
                            <Icon className="w-3.5 h-3.5" />
                            {label}
                          </motion.button>
                        )
                      })}
                    </div>

                    {/* Lucky / Reset */}
                    <div className="inline-flex self-start rounded-lg border border-line bg-raised p-1 gap-1">
                      <motion.button
                        whileHover={{ y: -1 }}
                        whileTap={{ scale: 0.96 }}
                        onClick={feelingLucky}
                        aria-label="I'm feeling lucky"
                        className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium text-muted hover:text-accent-bright hover:bg-overlay/60 transition-colors"
                      >
                        <IconRocket className="w-3.5 h-3.5" />
                        Lucky
                      </motion.button>
                      <motion.button
                        whileHover={{ y: -1 }}
                        whileTap={{ scale: 0.96 }}
                        onClick={resetThemeColors}
                        aria-label="Reset colors to default"
                        className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium text-muted hover:text-ink hover:bg-overlay/60 transition-colors"
                      >
                        <IconHeart className="w-3.5 h-3.5" />
                        Reset
                      </motion.button>
                    </div>
                  </div>
                </div>

                <div className="flex gap-8">
                  <ColorSwatchPicker
                    label="Accent color"
                    value={current.accent_color}
                    presets={
                      current.theme_mode === 'light'
                        ? ACCENT_PRESETS_LIGHT
                        : ACCENT_PRESETS_DARK
                    }
                    onChange={(hex) => {
                      setField('accent_color', hex)
                      previewTheme(hex, current.background_color)
                    }}
                  />
                  <ColorSwatchPicker
                    label="Background color"
                    value={current.background_color}
                    presets={
                      current.theme_mode === 'light'
                        ? BG_PRESETS_LIGHT
                        : BG_PRESETS_DARK
                    }
                    onChange={(hex) => {
                      setField('background_color', hex)
                      previewTheme(current.accent_color, hex)
                    }}
                  />
                </div>
                <p className="-mt-4 text-[11px] text-muted leading-relaxed">
                  Background color applies across all themes. In light mode
                  the app derives card surfaces, borders, and overlays from your
                  chosen background. In dark mode the background sets the base page color.
                </p>

                <label className="flex flex-col gap-2.5">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-muted">
                      Corner radius
                    </span>
                    <span className="text-xs font-mono text-ink bg-raised px-2 py-0.5 rounded-md">
                      {current.corner_radius}px
                    </span>
                  </div>
                  <Slider
                    min={0}
                    max={20}
                    step={1}
                    value={current.corner_radius}
                    label="Corner radius"
                    onChange={(v) => {
                      setField('corner_radius', v)
                      applyRadius(v)
                    }}
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    Controls every rounded corner in the app, cards, buttons,
                    inputs, and dropdowns. 0 for sharp, square corners.
                  </p>
                </label>

                <label className="flex flex-col gap-2.5">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-muted">
                      UI density
                    </span>
                    <span className="text-xs font-mono text-ink bg-raised px-2 py-0.5 rounded-md">
                      {Math.round(current.ui_density * 100)}%
                    </span>
                  </div>
                  <Slider
                    min={0.75}
                    max={1.25}
                    step={0.05}
                    value={current.ui_density}
                    label="UI density"
                    onChange={(v) => {
                      setField('ui_density', v)
                      applyDensity(v)
                    }}
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    Scales padding, margins, and spacing everywhere, lower for a
                    tighter, compact layout.
                  </p>
                </label>

                <label className="flex flex-col gap-2.5">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-muted">
                      Text size
                    </span>
                    <span className="text-xs font-mono text-ink bg-raised px-2 py-0.5 rounded-md">
                      {Math.round(current.font_scale * 100)}%
                    </span>
                  </div>
                  <Slider
                    min={0.85}
                    max={1.3}
                    step={0.05}
                    value={current.font_scale}
                    label="Text size"
                    onChange={(v) => {
                      setField('font_scale', v)
                      applyFontScale(v)
                    }}
                  />
                  <p className="text-[11px] text-muted leading-relaxed">
                    Scales all text (and anything sized relative to it) across
                    the app.
                  </p>
                </label>

                <label className="flex items-center justify-between gap-4">
                  <div>
                    <span className="text-xs font-medium text-muted block">
                      Reduce motion
                    </span>
                    <p className="text-[11px] text-muted mt-1 leading-relaxed">
                      Minimizes hover and UI transition animations.
                    </p>
                  </div>
                  <Toggle
                    checked={current.reduce_motion}
                    onChange={(checked) => {
                      setField('reduce_motion', checked)
                      applyReducedMotion(checked)
                    }}
                    label="Reduce motion"
                  />
                </label>

                <div className="pt-5 border-t border-line flex flex-col gap-5">
                  <div className="flex flex-col gap-2.5">
                    <div className="flex items-center justify-between gap-4">
                      <span className="text-xs font-medium text-muted">
                        Sidebar width (expanded)
                      </span>
                      <span className="text-xs font-mono text-ink bg-raised px-2 py-0.5 rounded-md">
                        {sidebarExpandedWidth}px
                      </span>
                    </div>
                    <Slider
                      value={sidebarExpandedWidth}
                      min={160}
                      max={400}
                      step={10}
                      label="Sidebar width (expanded)"
                      onChange={(v) => {
                        setSidebarExpandedWidth(v)
                        try {
                          localStorage.setItem(
                            'sidebar_width_expanded',
                            String(v),
                          )
                          window.dispatchEvent(
                            new Event('app:sidebar-width-changed'),
                          )
                        } catch {}
                      }}
                    />
                  </div>
                  <div className="flex flex-col gap-2.5">
                    <div className="flex items-center justify-between gap-4">
                      <span className="text-xs font-medium text-muted">
                        Sidebar width (collapsed)
                      </span>
                      <span className="text-xs font-mono text-ink bg-raised px-2 py-0.5 rounded-md">
                        {sidebarCollapsedWidth}px
                      </span>
                    </div>
                    <Slider
                      value={sidebarCollapsedWidth}
                      min={50}
                      max={120}
                      step={2}
                      label="Sidebar width (collapsed)"
                      onChange={(v) => {
                        setSidebarCollapsedWidth(v)
                        try {
                          localStorage.setItem(
                            'sidebar_width_collapsed',
                            String(v),
                          )
                          window.dispatchEvent(
                            new Event('app:sidebar-width-changed'),
                          )
                        } catch {}
                      }}
                    />
                  </div>
                </div>

                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={resetAppearance}
                  className="focus-ring cursor-pointer self-start px-4 py-2 rounded-lg border border-line text-muted hover:text-ink hover:bg-raised text-sm transition-colors"
                >
                  Reset appearance to default
                </motion.button>
              </div>
            </SectionCard>
            </div>
          </motion.div>
        )}

        {tab === 'advanced' && (
          <motion.div
            key="advanced"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.12 }}
            className="flex flex-col gap-6"
          >
            <div data-section-id="advanced-setup">
            <div className="rounded-xl border border-line bg-surface/60 p-6 flex items-center justify-between gap-6">
              <div className="min-w-0">
                <h3 className="font-display font-semibold">
                  Run Setup Wizard Again
                </h3>
                <p className="text-xs text-muted mt-1.5 leading-relaxed">
                  Reopens the first-time setup flow where you can reconfigure
                  scan folders, categories, accent color, and corner radius.
                  Settings already saved will be kept, you can always skip steps
                  you don&apos;t need to change.
                </p>
              </div>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setFields({ setup_complete: false })}
                className="focus-ring cursor-pointer shrink-0 px-5 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                Open Setup
              </motion.button>
            </div>
            </div>

            <div data-section-id="advanced-reset">
            <div className="rounded-xl border border-line bg-surface/60 p-6 flex items-center justify-between gap-6">
              <div className="min-w-0">
                <h3 className="font-display font-semibold">
                  Reset Settings to Default
                </h3>
                <p className="text-xs text-muted mt-1.5 leading-relaxed">
                  Restores every setting on this page; download folder, scan
                  folders, appearance and behavior back to their original
                  defaults. Scan folders and download locations are kept; only
                  toggles, sliders, and color picks are reset.
                </p>
              </div>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setConfirmingReset(true)}
                className="focus-ring cursor-pointer shrink-0 px-5 py-2.5 rounded-lg border border-line text-muted hover:text-danger hover:border-danger/40 hover:bg-danger/5 text-sm font-medium transition-colors"
              >
                Reset
              </motion.button>
            </div>
            </div>

            <div data-section-id="advanced-export">
            <div className="rounded-xl border border-line bg-surface/60 p-6 flex items-center justify-between gap-6">
              <div className="min-w-0">
                <h3 className="font-display font-semibold">
                  Export / Import Settings
                </h3>
                <p className="text-xs text-muted mt-1.5 leading-relaxed">
                  Save your current settings as a JSON file to back them up or
                  transfer them to another machine. Importing replaces all
                  current settings with those from the file.
                </p>
              </div>
              <div className="flex gap-2.5 shrink-0">
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={async () => {
                    try {
                      await api.exportSettings()
                      setSaveState('saved')
                      if (savedIndicatorTimeout.current)
                        clearTimeout(savedIndicatorTimeout.current)
                      savedIndicatorTimeout.current = setTimeout(
                        () => setSaveState('idle'),
                        1500,
                      )
                    } catch (e) {
                      if (String(e) !== 'Export cancelled') {
                        alert(String(e))
                      }
                    }
                  }}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                >
                  Export
                </motion.button>
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={async () => {
                    try {
                      const result = await api.importSettings()
                      setCurrent({
                        ...result,
                        project_scan_dirs:
                          result.default_project_location &&
                          !result.project_scan_dirs.includes(
                            result.default_project_location,
                          )
                            ? [
                                ...result.project_scan_dirs,
                                result.default_project_location,
                              ]
                            : result.project_scan_dirs,
                        version_scan_dirs:
                          result.download_dir &&
                          !result.version_scan_dirs.includes(result.download_dir)
                            ? [
                                ...result.version_scan_dirs,
                                result.download_dir,
                              ]
                            : result.version_scan_dirs,
                      })
                      setSaveState('saved')
                      if (savedIndicatorTimeout.current)
                        clearTimeout(savedIndicatorTimeout.current)
                      savedIndicatorTimeout.current = setTimeout(
                        () => setSaveState('idle'),
                        1500,
                      )
                    } catch (e) {
                      if (String(e) !== 'Import cancelled') {
                        alert(String(e))
                      }
                    }
                  }}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                >
                  Import
                </motion.button>
              </div>
            </div>
            </div>

            <div data-section-id="advanced-delete">
            <div className="rounded-xl border border-danger/30 bg-danger/4 p-6 flex items-center justify-between gap-6">
              <div className="min-w-0">
                <h3 className="font-display font-semibold text-danger">
                  Delete App Data
                </h3>
                <p className="text-xs text-muted mt-1.5 leading-relaxed">
                  Permanently wipes every workspace, project, category,
                  installed-version record, and setting GodotHub has stored. You
                  will be restarted at first-time setup. Your actual project
                  folders and Godot installs on disk are{' '}
                  <span className="text-ink font-medium">not</span> touched,
                  unless they live in the default download folder.
                </p>
              </div>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setConfirmingWipe(true)}
                className="focus-ring cursor-pointer shrink-0 px-5 py-2.5 rounded-lg border border-danger/40 text-danger hover:bg-danger/10 text-sm font-medium transition-colors"
              >
                Delete All
              </motion.button>
            </div>
            </div>

            <div data-section-id="advanced-updates" className="rounded-xl border border-line bg-surface/60 p-6 flex items-center justify-between gap-6">
              <div className="min-w-0">
                <h3 className="font-display font-semibold">Check for Updates</h3>
                <p className="text-xs text-muted mt-1.5 leading-relaxed">
                  Check if a new version of GodotHub is available. Updates are
                  downloaded and installed automatically, then applied on restart.
                </p>
              </div>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => {
                  window.dispatchEvent(new CustomEvent('app:check-updates'))
                }}
                className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                <IconRefresh className="w-4 h-4" />
                Check for Updates
              </motion.button>
            </div>

            <div className="rounded-xl border border-line bg-surface/60 p-6 flex items-center justify-between gap-6">
              <div className="min-w-0">
                <h3 className="font-display font-semibold">Report a Bug</h3>
                <p className="text-xs text-muted mt-1.5 leading-relaxed">
                  Help improve GodotHub by reporting issues on GitHub.
                </p>
              </div>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => {
                  window.dispatchEvent(new CustomEvent('app:report-bug'))
                }}
                className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                <IconBug className="w-4 h-4" />
                Report a Bug
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingReset && (
          <ConfirmDialog
            title="Reset all settings?"
            description="This restores every setting on this page, download folder, scan folders, appearance, and behavior, back to their defaults. This can't be undone."
            confirmLabel="Reset Settings"
            variant="danger"
            onConfirm={resetAllSettings}
            onCancel={() => setConfirmingReset(false)}
          />
        )}
        {confirmingWipe && (
          <ConfirmDialog
            title="Delete all app data?"
            description="This permanently deletes every workspace, project, category, installed-version record, and setting GodotHub has stored, and restarts you at first-time setup. Your actual project folders and Godot installs on disk are not touched, unless they live in the default download folder, in which case they're deleted too. This can't be undone."
            confirmLabel="Delete App Data"
            variant="danger"
            onConfirm={wipeAppData}
            onCancel={() => setConfirmingWipe(false)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
