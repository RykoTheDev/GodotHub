import type { Ref } from 'react'
import { useTranslation } from 'react-i18next'
import { CORE_FEATURES, FEATURES, isFeatureEnabled } from '../../lib/features'
import { featureLabel } from '../ui/FeatureSetupPicker'
import { getWorkspaceIcon } from '../../lib/workspaceIcons'
import type { AppSettings, Project, Workspace } from '../../types'

const MAX_TILES = 9
const VersionsIcon = CORE_FEATURES[1].icon

export function MiniAppPreview({
  ref,
  settings,
  workspace,
  projects,
  versionCount,
}: {
  ref?: Ref<HTMLDivElement>
  settings: AppSettings
  workspace: Workspace | null
  projects: Project[]
  versionCount: number
}) {
  const { t } = useTranslation('onboarding')
  const { t: ts } = useTranslation('settings')
  const pages = [
    ...CORE_FEATURES,
    ...FEATURES.filter((f) => !f.flag && isFeatureEnabled(settings, f.id)),
  ]
  const WorkspaceIcon = workspace ? getWorkspaceIcon(workspace.icon) : null
  const tiles = projects.slice(0, MAX_TILES)
  const extra = projects.length - tiles.length

  return (
    <div className="shrink-0 m-3 mt-0 p-2.5 rounded-item bg-base/40 border border-outline/50 flex flex-col gap-2">
      <span className="px-0.5 text-3xs font-semibold uppercase tracking-wide text-muted/70">
        {t('preview_heading')}
      </span>

      <div
        ref={ref}
        aria-hidden="true"
        className="h-40 flex gap-1 p-1 rounded-tile bg-base border border-outline/50 overflow-hidden"
      >
        <div className="w-[42%] shrink-0 flex flex-col gap-1 p-1 rounded-tag bg-raised overflow-hidden">
          {workspace && WorkspaceIcon && (
            <span key={`${workspace.icon}-${workspace.name}`} className="dash-rise flex items-center gap-1 px-1 py-0.5 rounded-tag bg-overlay">
              <span className="w-3.5 h-3.5 shrink-0 rounded-full border border-outline/50 bg-raised flex items-center justify-center text-muted">
                <WorkspaceIcon className="w-2 h-2" />
              </span>
              <span className="min-w-0 truncate text-4xs font-semibold text-ink">{workspace.name}</span>
            </span>
          )}
          {pages.map(({ id, icon: Icon }) => (
            <span key={id} className="dash-rise flex items-center gap-1 px-1 py-px text-4xs text-ink/70">
              <Icon className="w-2 h-2 shrink-0 text-muted" />
              <span className="min-w-0 truncate">{featureLabel(ts, id)}</span>
            </span>
          ))}
        </div>

        <div className="flex-1 min-w-0 flex flex-col gap-1 p-1">
          <span className="h-1.5 w-2/3 rounded-full bg-raised" />
          <div className="grid grid-cols-3 gap-1">
            {tiles.length > 0
              ? tiles.map((p) => (
                  <span
                    key={p.id}
                    className="dash-rise aspect-square rounded-tag bg-raised border border-outline/40 flex items-center justify-center text-4xs font-bold text-muted"
                  >
                    {p.name.trim().charAt(0).toUpperCase() || '?'}
                  </span>
                ))
              : [0, 1, 2].map((i) => (
                  <span key={i} className="aspect-square rounded-tag border border-dashed border-outline/40" />
                ))}
          </div>
          <span className="mt-auto flex items-center gap-1 text-4xs text-muted tabular-nums">
            {extra > 0 && <span>+{extra}</span>}
            {versionCount > 0 && (
              <span key={versionCount} className="dash-rise ms-auto inline-flex items-center gap-1 text-accent-bright">
                <VersionsIcon className="w-2 h-2" />
                {versionCount}
              </span>
            )}
          </span>
        </div>
      </div>
    </div>
  )
}
