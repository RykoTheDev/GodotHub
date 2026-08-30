export const DASHBOARD_TILE_IDS = [
  'weekly',
  'top_time',
  'insights',
  'git',
  'storage',
  'recent',
  'pinned',
  'engines',
  'running',
] as const

export type DashboardTileId = (typeof DASHBOARD_TILE_IDS)[number]

export function enabledTileIds(enabled: string[]): DashboardTileId[] {
  if (enabled.length === 0) return [...DASHBOARD_TILE_IDS]
  return DASHBOARD_TILE_IDS.filter((id) => enabled.includes(id))
}

export function orderedTileIds(order: string[]): DashboardTileId[] {
  if (order.length === 0) return [...DASHBOARD_TILE_IDS]
  const present = new Set(order)
  const extras = DASHBOARD_TILE_IDS.filter((id) => !present.has(id))
  return [...(order.filter((id) => DASHBOARD_TILE_IDS.includes(id as DashboardTileId)) as DashboardTileId[]), ...extras]
}

export function materializeEnabled(enabled: string[]): DashboardTileId[] {
  return enabledTileIds(enabled)
}

export function removeTileId(enabled: string[], id: DashboardTileId): DashboardTileId[] {
  return enabledTileIds(enabled).filter((x) => x !== id)
}

export function addTileId(enabled: string[], id: DashboardTileId): DashboardTileId[] {
  const current = enabledTileIds(enabled)
  if (current.includes(id)) return current
  return [...current, id]
}

export function moveTileId(
  order: string[],
  id: DashboardTileId,
  dir: -1 | 1,
): DashboardTileId[] {
  const current = orderedTileIds(order)
  const from = current.indexOf(id)
  const to = from + dir
  if (from === -1 || to < 0 || to >= current.length) return current
  const next = [...current]
  ;[next[from], next[to]] = [next[to], next[from]]
  return next
}

export const TILE_LAYOUT_OPTIONS: Partial<Record<DashboardTileId, { span?: boolean; tall?: boolean }>> = {
  weekly: { span: true, tall: true },
  top_time: { span: true, tall: true },
  insights: { span: true },
  git: { span: true, tall: true },
  storage: { span: true, tall: true },

}

export function tileCanSpan(id: DashboardTileId): boolean {
  return !!TILE_LAYOUT_OPTIONS[id]?.span
}

export function tileCanTall(id: DashboardTileId): boolean {
  return !!TILE_LAYOUT_OPTIONS[id]?.tall
}

export function toggleTileSpan(spans: string[], id: DashboardTileId): string[] {
  return spans.includes(id)
    ? spans.filter((x) => x !== id)
    : [...spans, id]
}

export function toggleTileTall(tall: string[], id: DashboardTileId): string[] {
  return tall.includes(id)
    ? tall.filter((x) => x !== id)
    : [...tall, id]
}

export interface DashboardPreset {
  id: string
  labelKey: string
  descriptionKey: string
  sections: string[]
  order: string[]
  spans: string[]
  tall: string[]
}

export const DASHBOARD_PRESETS: DashboardPreset[] = [
  {
    id: 'default',
    labelKey: 'dashboard_preset_default',
    descriptionKey: 'dashboard_preset_default_desc',
    sections: [],
    order: [],
    spans: [],
    tall: [],
  },
  {
    id: 'overview',
    labelKey: 'dashboard_preset_overview',
    descriptionKey: 'dashboard_preset_overview_desc',
    sections: [
      'quick_actions',
      'stats',
      'recent',
      'pinned',
      'engines',
      'running',
    ],
    order: ['recent', 'pinned', 'engines', 'running'],
    spans: [],
    tall: [],
  },
  {
    id: 'analytics',
    labelKey: 'dashboard_preset_analytics',
    descriptionKey: 'dashboard_preset_analytics_desc',
    sections: [
      'quick_actions',
      'stats',
      'weekly',
      'top_time',
      'storage',
      'categories',
    ],
    order: ['weekly', 'top_time', 'storage'],
    spans: ['weekly', 'storage'],
    tall: ['weekly', 'top_time', 'storage'],
  },
  {
    id: 'development',
    labelKey: 'dashboard_preset_development',
    descriptionKey: 'dashboard_preset_development_desc',
    sections: [
      'quick_actions',
      'stats',
      'git',
      'running',
      'engines',
      'recent',
      'pinned',
    ],
    order: ['git', 'running', 'engines', 'recent', 'pinned'],
    spans: ['git'],
    tall: ['git'],
  },
]

export interface CustomDashboardPreset {
  id: string
  name: string
  sections: string[]
  order: string[]
  spans: string[]
  tall: string[]
}

export function createCustomPreset(
  presets: CustomDashboardPreset[],
  name: string,
  sections: string[],
  order: string[],
  spans: string[],
  tall: string[],
): CustomDashboardPreset[] {
  const trimmed = name.trim()
  if (!trimmed) return presets
  const preset: CustomDashboardPreset = {
    id: `custom-${Date.now().toString(36)}`,
    name: trimmed,
    sections: [...sections],
    order: [...order],
    spans: [...spans],
    tall: [...tall],
  }
  return [...presets, preset]
}

export function deleteCustomPreset(
  presets: CustomDashboardPreset[],
  id: string,
): CustomDashboardPreset[] {
  return presets.filter((p) => p.id !== id)
}

export function presetToSettings(preset: {
  sections: string[]
  order: string[]
  spans: string[]
  tall: string[]
}): {
  dashboard_sections: string[]
  dashboard_section_order: string[]
  dashboard_section_spans: string[]
  dashboard_tall_sections: string[]
} {
  return {
    dashboard_sections: [...preset.sections],
    dashboard_section_order: [...preset.order],
    dashboard_section_spans: [...preset.spans],
    dashboard_tall_sections: [...preset.tall],
  }
}

export function settingsMatchPreset(
  preset: {
    sections: string[]
    order: string[]
    spans: string[]
    tall: string[]
  },
  sections: string[],
  order: string[],
  spans: string[],
  tall: string[],
): boolean {
  const allSections = [...DASHBOARD_TILE_IDS, 'quick_actions', 'stats']
  const sec = sections.length === 0 ? allSections : sections
  const presetSec =
    preset.sections.length === 0 ? allSections : preset.sections
  const ord = order.length === 0 ? [...DASHBOARD_TILE_IDS] : order
  const presetOrd =
    preset.order.length === 0 ? [...DASHBOARD_TILE_IDS] : preset.order
  return (
    [...sec].sort().join(',') === [...presetSec].sort().join(',') &&
    ord.join(',') === presetOrd.join(',') &&
    [...spans].sort().join(',') === [...preset.spans].sort().join(',') &&
    [...tall].sort().join(',') === [...preset.tall].sort().join(',')
  )
}

export interface DashboardSegment {
  tiles: { id: DashboardTileId; index: number }[]
  span: boolean
}

export function buildDashboardSegments(
  ordered: DashboardTileId[],
  spans: string[],
): DashboardSegment[] {
  const segments: DashboardSegment[] = []
  let pending: { id: DashboardTileId; index: number }[] = []
  const flush = () => {
    if (pending.length === 0) return
    segments.push({ tiles: pending, span: false })
    pending = []
  }
  ordered.forEach((id, index) => {
    if (spans.includes(id)) {
      flush()
      segments.push({ tiles: [{ id, index }], span: true })
    } else {
      pending.push({ id, index })
    }
  })
  flush()
  return segments
}
