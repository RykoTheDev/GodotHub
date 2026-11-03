import { useId } from 'react'
import { useTranslation } from 'react-i18next'
import {
  WORKSPACE_COLOR_PRESETS,
  WORKSPACE_ICON_KEYS,
  getWorkspaceIcon,
} from '../../lib/workspaceIcons'
import { IconCheck } from '../../lib/icons'

export interface WorkspaceDraft {
  name: string
  icon: string
  color: string
}

export function workspaceNameError(
  name: string,
  takenNames: string[],
  t: (key: string) => string,
): string | null {
  const trimmed = name.trim()
  if (!trimmed) return t('workspace_name_required_error')
  const lower = trimmed.toLocaleLowerCase()
  if (takenNames.some((n) => n.trim().toLocaleLowerCase() === lower)) {
    return t('workspace_name_taken_error')
  }
  return null
}

export function WorkspaceForm({
  value,
  onChange,
  takenNames,
  showErrors,
  autoFocus = false,
  onSubmit,
  onNameBlur,
}: {
  value: WorkspaceDraft
  onChange: (next: WorkspaceDraft) => void
  takenNames: string[]
  showErrors: boolean
  autoFocus?: boolean
  onSubmit?: () => void
  onNameBlur?: () => void
}) {
  const { t } = useTranslation('common')
  const nameId = useId()
  const errorId = useId()
  const Icon = getWorkspaceIcon(value.icon)
  const error = showErrors ? workspaceNameError(value.name, takenNames, t) : null

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center gap-4 px-4 py-4 rounded-item bg-base/40 border border-outline/50">
        <span
          className="w-14 h-14 shrink-0 rounded-full border-2 flex items-center justify-center"
          style={{ backgroundColor: `${value.color}1f`, borderColor: value.color }}
        >
          <Icon className="w-6 h-6" style={{ color: value.color }} />
        </span>
        <div className="min-w-0">
          <span className="block font-display font-bold text-xl tracking-tight text-ink truncate">
            {value.name.trim() || t('workspace_name_placeholder')}
          </span>
          <span className="block text-3xs font-semibold uppercase tracking-wider text-muted/60 mt-0.5">
            {t('section_workspaces')}
          </span>
        </div>
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor={nameId} className="text-xs font-medium text-muted">
          {t('workspace_name_label')}
        </label>
        <input
          id={nameId}
          autoFocus={autoFocus}
          value={value.name}
          onChange={(e) => onChange({ ...value, name: e.target.value })}
          onBlur={onNameBlur}
          onKeyDown={(e) => {
            if (e.key === 'Enter') onSubmit?.()
          }}
          placeholder={t('workspace_name_placeholder')}
          aria-invalid={!!error}
          aria-describedby={error ? errorId : undefined}
          className={`focus-ring bg-base border rounded-btn px-3.5 py-2.5 text-sm outline-none ${
            error ? 'border-danger/60' : 'border-outline/50 focus:border-accent-dim'
          }`}
        />
        {error && (
          <p id={errorId} className="text-2xs text-danger">
            {error}
          </p>
        )}
      </div>

      <div className="grid gap-5 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <span className="text-xs font-medium text-muted">{t('icon_label')}</span>
          <div role="radiogroup" aria-label={t('icon_label')} className="grid grid-cols-6 gap-1.5">
            {WORKSPACE_ICON_KEYS.map((key) => {
              const KeyIcon = getWorkspaceIcon(key)
              const active = value.icon === key
              return (
                <button
                  key={key}
                  type="button"
                  role="radio"
                  aria-checked={active}
                  aria-label={key.replace(/_/g, ' ')}
                  onClick={() => onChange({ ...value, icon: key })}
                  className={`focus-ring cursor-pointer aspect-square rounded-tile border flex items-center justify-center ${
                    active
                      ? 'border-accent bg-accent/10 text-accent-bright'
                      : 'border-outline/50 text-muted hover:text-ink hover:bg-overlay'
                  }`}
                >
                  <KeyIcon className="w-3.5 h-3.5" />
                </button>
              )
            })}
          </div>
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-xs font-medium text-muted">{t('color_label')}</span>
          <div role="radiogroup" aria-label={t('color_label')} className="grid grid-cols-7 gap-1.5">
            {WORKSPACE_COLOR_PRESETS.map((c) => {
              const active = value.color === c
              return (
                <button
                  key={c}
                  type="button"
                  role="radio"
                  aria-checked={active}
                  aria-label={c}
                  onClick={() => onChange({ ...value, color: c })}
                  className={`focus-ring cursor-pointer aspect-square rounded-full flex items-center justify-center ${
                    active ? 'ring-2 ring-offset-2 ring-offset-raised ring-ink/80' : 'hover:scale-110'
                  }`}
                  style={{ backgroundColor: c }}
                >
                  {active && <IconCheck className="w-2.5 h-2.5 text-white" />}
                </button>
              )
            })}
          </div>
        </div>
      </div>
    </div>
  )
}
