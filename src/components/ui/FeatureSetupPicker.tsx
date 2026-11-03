import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import {
  CORE_FEATURES,
  FEATURES,
  SETUP_PROFILES,
  enabledFeatures,
  matchProfile,
  withFeatures,
  type FeatureId,
  type SetupProfileId,
} from '../../lib/features'
import { IconCheck, IconPencil } from '../../lib/icons'
import { Toggle } from './Toggle'
import type { AppSettings } from '../../types'

const LABEL_KEYS: Record<FeatureId | 'projects' | 'versions', string> = {
  projects: 'nav:projects',
  versions: 'nav:versions',
  dashboard: 'nav:dashboard',
  templates: 'nav:templates',
  vault: 'nav:vault',
  storage: 'nav:storage_view',
  'asset-store': 'nav:asset_store',
  news: 'nav:news',
  categories: 'common:categories',
  workspaces: 'common:section_workspaces',
}

const DESC_KEYS: Record<FeatureId | 'projects' | 'versions', string> = {
  projects: 'common:onboarding_keep_organized',
  versions: 'common:onboarding_download_manage',
  dashboard: 'settings:feature_desc_dashboard',
  templates: 'settings:feature_desc_templates',
  vault: 'settings:feature_desc_vault',
  storage: 'settings:feature_desc_storage',
  'asset-store': 'settings:feature_desc_asset_store',
  news: 'common:onboarding_stay_current',
  categories: 'settings:feature_desc_categories',
  workspaces: 'settings:feature_desc_workspaces',
}

export function featureLabel(t: (key: string) => string, id: FeatureId | 'projects' | 'versions') {
  return t(LABEL_KEYS[id])
}

type CardId = SetupProfileId | 'custom'

export function FeatureSetupPicker({
  value,
  onChange,
}: {
  value: AppSettings
  onChange: (next: AppSettings) => void
}) {
  const { t } = useTranslation('settings')
  const enabled = enabledFeatures(value)
  const matched = matchProfile(enabled)
  const [customizing, setCustomizing] = useState(matched === null)
  const selected: CardId = customizing ? 'custom' : matched ?? 'custom'

  const pick = (id: CardId) => {
    if (id === 'custom') {
      setCustomizing(true)
      return
    }
    setCustomizing(false)
    const profile = SETUP_PROFILES.find((p) => p.id === id)
    if (profile) onChange(withFeatures(value, profile.features))
  }

  const toggle = (id: FeatureId, on: boolean) => {
    const next = new Set(enabled)
    if (on) next.add(id)
    else next.delete(id)
    onChange(withFeatures(value, next))
  }

  return (
    <div className="flex flex-col gap-4 w-full">
      <div role="radiogroup" aria-label={t('features_title')} className="flex flex-col gap-2.5">
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-2.5">
          {SETUP_PROFILES.map(({ id, features }) => {
            const active = selected === id
            const included = new Set(features)
            return (
              <button
                key={id}
                type="button"
                role="radio"
                aria-checked={active}
                onClick={() => pick(id)}
                className={`focus-ring cursor-pointer flex flex-col gap-2 p-3.5 rounded-item border text-start ${
                  active
                    ? 'border-accent bg-accent/10'
                    : 'border-outline/50 bg-base/40 hover:border-accent-dim hover:bg-overlay/60'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span className="text-sm font-semibold text-ink">
                    {t(`setup_profile_${id}`)}
                  </span>
                  <RadioDot active={active} />
                </span>
                <span className="text-2xs text-muted leading-relaxed">
                  {t(`setup_profile_${id}_desc`)}
                </span>
                <span className="mt-auto pt-1 flex flex-wrap items-center gap-1" aria-hidden="true">
                  {CORE_FEATURES.map(({ id: coreId, icon: Icon }) => (
                    <span
                      key={coreId}
                      className="w-5 h-5 flex items-center justify-center rounded-tag bg-accent/15 text-accent-bright"
                    >
                      <Icon className="w-3 h-3" />
                    </span>
                  ))}
                  {FEATURES.map(({ id: featureId, icon: Icon }) => (
                    <span
                      key={featureId}
                      className={`w-5 h-5 flex items-center justify-center rounded-tag ${
                        included.has(featureId)
                          ? 'bg-overlay border border-outline/50 text-ink'
                          : 'text-muted/30'
                      }`}
                    >
                      <Icon className="w-3 h-3" />
                    </span>
                  ))}
                </span>
              </button>
            )
          })}
        </div>
        <button
          type="button"
          role="radio"
          aria-checked={selected === 'custom'}
          onClick={() => pick('custom')}
          className={`focus-ring cursor-pointer flex items-center gap-3 px-3.5 py-3 rounded-item border text-start ${
            selected === 'custom'
              ? 'border-accent bg-accent/10'
              : 'border-dashed border-outline/60 hover:border-accent-dim hover:bg-overlay/60'
          }`}
        >
          <span className="w-8 h-8 shrink-0 flex items-center justify-center rounded-tile bg-overlay text-muted">
            <IconPencil className="w-3.5 h-3.5" />
          </span>
          <span className="flex-1 min-w-0">
            <span className="block text-sm font-semibold text-ink">{t('setup_profile_custom')}</span>
            <span className="block text-2xs text-muted leading-relaxed">
              {t('setup_profile_custom_desc')}
            </span>
          </span>
          <span className="shrink-0 text-3xs font-medium text-muted tabular-nums">
            {t('features_enabled_count', { count: enabled.size + CORE_FEATURES.length })}
          </span>
          <RadioDot active={selected === 'custom'} />
        </button>
      </div>

      {customizing && (
        <div className="flex flex-col gap-1.5">
          <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70 px-1">
            {t('features_always_on')}
          </span>
          {CORE_FEATURES.map(({ id, icon: Icon }) => (
            <FeatureRow
              key={id}
              icon={<Icon className="w-3.5 h-3.5" />}
              label={t(LABEL_KEYS[id])}
              description={t(DESC_KEYS[id])}
              checked
              disabled
            />
          ))}
          <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70 px-1 pt-2">
            {t('features_optional')}
          </span>
          {FEATURES.map(({ id, icon: Icon }) => (
            <FeatureRow
              key={id}
              icon={<Icon className="w-3.5 h-3.5" />}
              label={t(LABEL_KEYS[id])}
              description={t(DESC_KEYS[id])}
              checked={enabled.has(id)}
              onChange={(on) => toggle(id, on)}
            />
          ))}
        </div>
      )}
    </div>
  )
}

function RadioDot({ active }: { active: boolean }) {
  return (
    <span
      className={`ms-auto w-4.5 h-4.5 shrink-0 flex items-center justify-center rounded-full border ${
        active ? 'bg-accent border-accent text-white' : 'border-outline/60'
      }`}
    >
      {active && <IconCheck className="w-2.5 h-2.5" />}
    </span>
  )
}

function FeatureRow({
  icon,
  label,
  description,
  checked,
  disabled,
  onChange,
}: {
  icon: React.ReactNode
  label: string
  description: string
  checked: boolean
  disabled?: boolean
  onChange?: (checked: boolean) => void
}) {
  return (
    <div className="flex items-center gap-3 px-3.5 py-2.5 rounded-item bg-base/40 border border-outline/50">
      <span
        className={`w-8 h-8 shrink-0 flex items-center justify-center rounded-tile ${
          checked ? 'bg-accent/10 text-accent-bright' : 'bg-overlay text-muted'
        }`}
      >
        {icon}
      </span>
      <span className="flex-1 min-w-0">
        <span className="block text-xs font-medium text-ink">{label}</span>
        <span className="block text-2xs text-muted leading-relaxed">{description}</span>
      </span>
      <Toggle
        checked={checked}
        disabled={disabled}
        onChange={(next) => onChange?.(next)}
        label={label}
      />
    </div>
  )
}
