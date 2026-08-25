import {
  createContext,
  createElement,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { api } from '../lib/api'
import {
  applyTheme,
  getThemePreset,
  isDarkColor,
  resolveThemeMode,
  DEFAULT_ACCENT,
  DEFAULT_BG,
  DEFAULT_BG_LIGHT,
} from '../lib/colors'
import {
  applyAppearance,
  applyAnimationIntensity,
  applyCustomCss,
  applyDensity,
  applyFontScale,
  applyProjectIconOpacity,
  applyRadius,
  applyScrollbars,
} from '../lib/appearance'
import { registerPendingSave } from '../lib/pendingSave'
import { useWorkspaces } from './useWorkspaces'
import { defaultCornerRadius } from '../lib/platform'
import i18n from 'i18next'
import type { AppSettings } from '../types'

const SAVE_DEBOUNCE_MS = 250

const DEFAULTS: AppSettings = {
  download_dir: null,
  default_project_location: null,
  project_scan_dirs: [],
  version_scan_dirs: [],
  scan_depth: 2,
  icon_scan_depth: 4,
  download_concurrency: 3,
  accent_color: DEFAULT_ACCENT,
  background_color: DEFAULT_BG,
  corner_radius: defaultCornerRadius,
  raised_contrast: 8,
  ui_density: 1.05,
  font_scale: 1.0,
  theme_mode: 'dark',
  custom_css: '',
  animation_intensity: 'full',
  view_entrance: 'fade',
  launch_with_console: false,
  close_on_project_open: false,
  minimize_to_tray: false,
  reopen_after_godot_closes: false,
  last_opened_time_format: '12h',
  last_opened_date_format: 'DD-MM-YYYY',
  setup_complete: false,
  categories_enabled: true,
  workspaces_enabled: true,
  auto_scan_on_startup: true,
  command_palette_keybind: 'p',
  external_editor_path: null,
  github_token: null,
  discord_app_id: null,
  discord_rpc_enabled: true,
  discord_rpc_show_projects: true,
  discord_rpc_excluded_projects: [],
  discord_rpc_project_presences: [],
  template_scan_dir: null,
  auto_watch_project_dirs: true,
  auto_watch_version_dirs: true,
  auto_watch_template_dir: true,
  tooltip_delay: 350,
  tray_recent_projects_count: 5,
  show_support_button: true,
  show_star_button: true,
  show_scrollbars: true,
  animated_numbers: true,
  screen_reader_announcements: true,
  project_icon_opacity: 14,
  animation_threshold: 20,
  language: 'en-US',
  use_os_decorations: false,
  directory_naming_convention: 'keep',
  theme_preset: 'custom',
  git_init_new_projects: false,
  open_after_import: true,
  card_layout: true,
  dashboard_custom_name: null,
  default_landing_tab: 'projects',
  dashboard_sections: [],
  dashboard_section_order: [],
  dashboard_section_spans: [],
  dashboard_tall_sections: [],
  dashboard_custom_presets: [],
  auto_backup_interval_minutes: 0,
}

interface SettingsContextValue {
  settings: AppSettings
  loaded: boolean
  settingsWorkspaceId: string
  update: (next: AppSettings) => Promise<AppSettings>
  resetToDefaults: () => Promise<AppSettings>
}

const SettingsContext = createContext<SettingsContextValue | null>(null)

function applySettingsAppearance(prev: AppSettings, next: AppSettings) {
  if (
    next.accent_color !== prev.accent_color ||
    next.background_color !== prev.background_color ||
    next.theme_mode !== prev.theme_mode ||
    next.theme_preset !== prev.theme_preset ||
    next.raised_contrast !== prev.raised_contrast
  ) {
    applyTheme(
      next.accent_color,
      next.background_color,
      resolveThemeMode(next.theme_mode),
      getThemePreset(next.theme_preset),
      next.raised_contrast,
    )
  }
  if (next.corner_radius !== prev.corner_radius) applyRadius(next.corner_radius)
  if (next.ui_density !== prev.ui_density) applyDensity(next.ui_density)
  if (next.font_scale !== prev.font_scale) applyFontScale(next.font_scale)
  if (next.animation_intensity !== prev.animation_intensity) {
    applyAnimationIntensity(next.animation_intensity)
  }
  if (next.custom_css !== prev.custom_css) applyCustomCss(next.custom_css)
  if (next.show_scrollbars !== prev.show_scrollbars) applyScrollbars(next.show_scrollbars)
  if (next.project_icon_opacity !== prev.project_icon_opacity) {
    applyProjectIconOpacity(next.project_icon_opacity)
  }
  if (next.language && next.language !== prev.language) {
    localStorage.setItem('i18nextLng', next.language)
    if (next.language !== i18n.language) i18n.changeLanguage(next.language)
  }
}

export function SettingsProvider({ children }: { children: ReactNode }) {
  const { activeId } = useWorkspaces()
  const [settings, setSettings] = useState<AppSettings>(DEFAULTS)
  const [loaded, setLoaded] = useState(false)
  const [settingsWorkspaceId, setSettingsWorkspaceId] = useState('')

  const pendingSettingsRef = useRef<AppSettings | null>(null)
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const savingSettingsRef = useRef(false)
  const savePromiseRef = useRef<Promise<void> | null>(null)

  useEffect(() => {
    if (!activeId) return
    let cancelled = false
    api.getSettings().then((s) => {
      if (cancelled) return
      setSettings(s)
      setSettingsWorkspaceId(activeId)
      applyTheme(
        s.accent_color,
        s.background_color,
        resolveThemeMode(s.theme_mode),
        getThemePreset(s.theme_preset),
        s.raised_contrast,
      )
      applyAppearance(s)
      if (s.language && s.language !== i18n.language) {
        i18n.changeLanguage(s.language)
      }
      setLoaded(true)
    })
    return () => {
      cancelled = true
      if (saveTimerRef.current) {
        clearTimeout(saveTimerRef.current)
        saveTimerRef.current = null
      }
      pendingSettingsRef.current = null
    }
  }, [activeId])

  useEffect(() => {
    if (settings.theme_mode !== 'system') return
    const mq = window.matchMedia('(prefers-color-scheme: light)')
    const apply = () => {
      const resolved = resolveThemeMode('system')
      const targetDark = resolved === 'dark'
      const clash =
        settings.theme_preset === 'custom' &&
        isDarkColor(settings.background_color) !== targetDark
      if (clash) {
        update({
          ...settings,
          background_color: targetDark ? DEFAULT_BG : DEFAULT_BG_LIGHT,
        })
        return
      }
      applyTheme(
        settings.accent_color,
        settings.background_color,
        resolved,
        getThemePreset(settings.theme_preset),
        settings.raised_contrast,
      )
    }
    apply()
    const handler = () => apply()
    if (typeof mq.addEventListener === 'function') {
      mq.addEventListener('change', handler)
      return () => mq.removeEventListener('change', handler)
    }
    mq.addListener(handler)
    return () => mq.removeListener(handler)
  }, [
    settings.theme_mode,
    settings.accent_color,
    settings.background_color,
    settings.theme_preset,
    settings.raised_contrast,
  ])

  const flushPending = (): Promise<void> => {
    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current)
      saveTimerRef.current = null
    }
    if (savingSettingsRef.current) {
      return savePromiseRef.current ?? Promise.resolve()
    }
    const pending = pendingSettingsRef.current
    if (!pending) return Promise.resolve()
    pendingSettingsRef.current = null
    const cycle = (async () => {
      savingSettingsRef.current = true
      try {
        const saved = await api.updateSettings(pending)
        if (pendingSettingsRef.current === null) {
          setSettings(saved)
          applyTheme(
            saved.accent_color,
            saved.background_color,
            resolveThemeMode(saved.theme_mode),
            getThemePreset(saved.theme_preset),
            saved.raised_contrast,
          )
          if (saved.language) {
            localStorage.setItem('i18nextLng', saved.language)
          }
          applyAppearance(saved)
        }
      } finally {
        savingSettingsRef.current = false
      }
    })()
    savePromiseRef.current = cycle
    return cycle
  }

  const update = async (next: AppSettings) => {
    setSettings(next)
    applySettingsAppearance(settings, next)

    pendingSettingsRef.current = next
    registerPendingSave(flushPending)
    if (savingSettingsRef.current) {
      if (saveTimerRef.current) clearTimeout(saveTimerRef.current)
      saveTimerRef.current = setTimeout(() => {
        void flushPending()
      }, SAVE_DEBOUNCE_MS)
      return next
    }
    await flushPending()
    return next
  }

  const resetToDefaults = async () => {
    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current)
      saveTimerRef.current = null
    }
    if (savePromiseRef.current) await savePromiseRef.current
    pendingSettingsRef.current = null
    const defaults = await api.resetSettings()
    setSettings(defaults)
    applyTheme(
      defaults.accent_color,
      defaults.background_color,
      resolveThemeMode(defaults.theme_mode),
      getThemePreset(defaults.theme_preset),
      defaults.raised_contrast,
    )
    applyAppearance(defaults)
    return defaults
  }

  return createElement(
    SettingsContext.Provider,
    { value: { settings, loaded, settingsWorkspaceId, update, resetToDefaults } },
    children,
  )
}

export function useSettings() {
  const ctx = useContext(SettingsContext)
  if (!ctx)
    throw new Error('useSettings() must be used within a <SettingsProvider>')
  return ctx
}
