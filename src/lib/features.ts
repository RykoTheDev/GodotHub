import type { ComponentType } from 'react'
import {
  IconBriefcase,
  IconCloudArrowDown,
  IconFolder,
  IconHardDrive,
  IconHouse,
  IconLayoutGrid,
  IconNews,
  IconRocket,
  IconStore,
  IconTags,
  type IconProps,
} from './icons'
import type { AppSettings } from '../types'

export type FeatureId =
  | 'dashboard'
  | 'templates'
  | 'vault'
  | 'storage'
  | 'asset-store'
  | 'news'
  | 'categories'
  | 'workspaces'

type FeatureFlag = 'categories_enabled' | 'workspaces_enabled'

export interface FeatureDef {
  id: FeatureId
  icon: ComponentType<IconProps>
  flag?: FeatureFlag
}

export const CORE_FEATURES = [
  { id: 'projects', icon: IconFolder },
  { id: 'versions', icon: IconCloudArrowDown },
] as const

export const FEATURES: FeatureDef[] = [
  { id: 'asset-store', icon: IconStore },
  { id: 'templates', icon: IconRocket },
  { id: 'categories', icon: IconTags, flag: 'categories_enabled' },
  { id: 'dashboard', icon: IconHouse },
  { id: 'vault', icon: IconBriefcase },
  { id: 'storage', icon: IconHardDrive },
  { id: 'workspaces', icon: IconLayoutGrid, flag: 'workspaces_enabled' },
  { id: 'news', icon: IconNews },
]

export type SetupProfileId = 'minimal' | 'essentials' | 'studio' | 'complete'

const ESSENTIALS: FeatureId[] = ['asset-store', 'templates', 'categories']

export const SETUP_PROFILES: { id: SetupProfileId; features: FeatureId[] }[] = [
  { id: 'minimal', features: [] },
  { id: 'essentials', features: ESSENTIALS },
  { id: 'studio', features: [...ESSENTIALS, 'dashboard', 'vault', 'storage', 'workspaces'] },
  { id: 'complete', features: FEATURES.map((f) => f.id) },
]

const FEATURE_IDS = new Set<string>(FEATURES.map((f) => f.id))

export function isFeatureEnabled(settings: AppSettings, id: string): boolean {
  if (!FEATURE_IDS.has(id)) return true
  const def = FEATURES.find((f) => f.id === id)
  return def?.flag ? settings[def.flag] : !settings.disabled_features.includes(id)
}

export function enabledFeatures(settings: AppSettings): Set<FeatureId> {
  return new Set(FEATURES.filter((f) => isFeatureEnabled(settings, f.id)).map((f) => f.id))
}

export function withFeatures(settings: AppSettings, enabled: Iterable<FeatureId>): AppSettings {
  const on = new Set(enabled)
  const next: AppSettings = {
    ...settings,
    disabled_features: FEATURES.filter((f) => !f.flag && !on.has(f.id)).map((f) => f.id),
  }
  for (const f of FEATURES) {
    if (f.flag) next[f.flag] = on.has(f.id)
  }
  return next
}

export function matchProfile(enabled: Set<FeatureId>): SetupProfileId | null {
  return (
    SETUP_PROFILES.find(
      (p) => p.features.length === enabled.size && p.features.every((id) => enabled.has(id)),
    )?.id ?? null
  )
}
