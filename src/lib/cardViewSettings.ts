import type { AppSettings, CardViewSettings, ProjectViewMode } from '../types'

const DEFAULT_CARD_SETTINGS: CardViewSettings = {
  show_size: true,
  show_time: true,
  blur_path: false,
  show_path: true,
  show_tags: true,
  show_last_opened: true,
  show_play: true,
  show_console: true,
}

const LIST_KEY_MAP: Record<keyof CardViewSettings, keyof AppSettings> = {
  show_size: 'card_show_size',
  show_time: 'card_show_time',
  blur_path: 'card_blur_path',
  show_path: 'card_show_path',
  show_tags: 'card_show_tags',
  show_last_opened: 'card_show_last_opened',
  show_play: 'card_show_play',
  show_console: 'card_show_console',
}

export function getCardViewSettings(
  settings: AppSettings,
  viewMode: ProjectViewMode,
): CardViewSettings {
  if (viewMode === 'list') {
  return {
    show_size: settings.card_show_size,
    show_time: settings.card_show_time,
    blur_path: settings.card_blur_path,
    show_path: settings.card_show_path,
    show_tags: settings.card_show_tags,
    show_last_opened: settings.card_show_last_opened,
    show_play: settings.card_show_play,
    show_console: settings.card_show_console,
  }
  }

  const override = settings.card_view_overrides?.[viewMode]
  if (!override) return { ...DEFAULT_CARD_SETTINGS }

  const result = { ...DEFAULT_CARD_SETTINGS }
  for (const k of Object.keys(LIST_KEY_MAP) as (keyof CardViewSettings)[]) {
    if (k in override) {
      result[k] = override[k]!
    } else {
      result[k] = settings[LIST_KEY_MAP[k]] as boolean
    }
  }
  return result
}

export function setCardViewOverride(
  settings: AppSettings,
  viewMode: ProjectViewMode,
  key: keyof CardViewSettings,
  value: boolean,
): AppSettings {
  if (viewMode === 'list') {
    return { ...settings, [LIST_KEY_MAP[key]]: value }
  }

  const existing = settings.card_view_overrides?.[viewMode] ?? {}
  return {
    ...settings,
    card_view_overrides: {
      ...settings.card_view_overrides,
      [viewMode]: { ...existing, [key]: value },
    },
  }
}
