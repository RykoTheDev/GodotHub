import {
  createContext,
  createElement,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import { api } from '../lib/api'
import { applyTheme } from '../lib/colors'
import { applyAppearance } from '../lib/appearance'
import { useWorkspaces } from './useWorkspaces'
import i18n from 'i18next'
import type { AppSettings } from '../types'

const DEFAULTS: AppSettings = {
  download_dir: null,
  default_project_location: null,
  project_scan_dirs: [],
  version_scan_dirs: [],
  scan_depth: 2,
  download_concurrency: 3,
  accent_color: '#457ff2',
  background_color: '#15171c',
  corner_radius: 5,
  ui_density: 1.05,
  font_scale: 1.0,
  reduce_motion: false,
  theme_mode: 'dark',
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
  template_scan_dir: null,
  auto_watch_project_dirs: true,
  auto_watch_version_dirs: true,
  auto_watch_template_dir: true,
  tooltip_delay: 350,
  tray_recent_projects_count: 5,
  show_support_button: true,
  show_star_button: true,
  show_scrollbars: true,
  project_icon_opacity: 14,
  language: 'en-US',
}

interface SettingsContextValue {
  settings: AppSettings
  loaded: boolean
  update: (next: AppSettings) => Promise<AppSettings>
  resetToDefaults: () => Promise<AppSettings>
}

const SettingsContext = createContext<SettingsContextValue | null>(null)

export function SettingsProvider({ children }: { children: ReactNode }) {
  const { activeId } = useWorkspaces()
  const [settings, setSettings] = useState<AppSettings>(DEFAULTS)
  const [loaded, setLoaded] = useState(false)

  useEffect(() => {
    let cancelled = false
    api.getSettings().then((s) => {
      if (cancelled) return
      setSettings(s)
      applyTheme(s.accent_color, s.background_color, s.theme_mode)
      applyAppearance(s)
      if (s.language && s.language !== i18n.language) {
        i18n.changeLanguage(s.language)
      }
      setLoaded(true)
    })
    return () => {
      cancelled = true
    }
  }, [activeId])

  const update = async (next: AppSettings) => {
    const saved = await api.updateSettings(next)
    setSettings(saved)
    applyTheme(saved.accent_color, saved.background_color, saved.theme_mode)
    if (saved.language) {
      localStorage.setItem('i18nextLng', saved.language)
    }
    applyAppearance(saved)
    return saved
  }

  const resetToDefaults = async () => {
    const defaults = await api.resetSettings()
    setSettings(defaults)
    applyTheme(
      defaults.accent_color,
      defaults.background_color,
      defaults.theme_mode,
    )
    applyAppearance(defaults)
    return defaults
  }

  return createElement(
    SettingsContext.Provider,
    { value: { settings, loaded, update, resetToDefaults } },
    children,
  )
}

export function useSettings() {
  const ctx = useContext(SettingsContext)
  if (!ctx)
    throw new Error('useSettings() must be used within a <SettingsProvider>')
  return ctx
}
