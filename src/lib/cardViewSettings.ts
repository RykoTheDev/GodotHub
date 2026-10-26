import type { AppSettings, CardViewSettings, ProjectViewMode } from '../types'

const LIST_KEY_MAP: Record<keyof CardViewSettings, keyof AppSettings> = {
  show_size: 'card_show_size',
  show_time: 'card_show_time',
  blur_path: 'card_blur_path',
  show_path: 'card_show_path',
  show_tags: 'card_show_tags',
  show_last_opened: 'card_show_last_opened',
  show_play: 'card_show_play',
  show_console: 'card_show_console',
  show_session_timer: 'card_show_session_timer',
}

export function getCardViewSettings(
  settings: AppSettings,
  viewMode: ProjectViewMode,
): CardViewSettings {
  const result: CardViewSettings = {
    show_size: settings.card_show_size,
    show_time: settings.card_show_time,
    blur_path: settings.card_blur_path,
    show_path: settings.card_show_path,
    show_tags: settings.card_show_tags,
    show_last_opened: settings.card_show_last_opened,
    show_play: settings.card_show_play,
    show_console: settings.card_show_console,
    show_session_timer: settings.card_show_session_timer ?? true,
  }
  if (viewMode === 'list') return result
  const override = settings.card_view_overrides?.[viewMode]
  for (const key of Object.keys(LIST_KEY_MAP) as (keyof CardViewSettings)[]) {
    const value = override?.[key]
    if (typeof value === 'boolean') result[key] = value
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
