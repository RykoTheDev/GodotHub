import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { WORKSPACE_ICON_KEYS, WORKSPACE_COLOR_PRESETS } from '../../lib/workspaceIcons'
import { ModalShell } from './ModalShell'
import { IconCheck, IconCopy, IconPlus, IconRocket } from '../../lib/icons'
import { WorkspaceForm, workspaceNameError, type WorkspaceDraft } from '../ui/WorkspaceForm'
import type { Workspace } from '../../types'

export type WorkspaceStart = 'copy' | 'fresh'

interface Props {
  takenNames: string[]
  copySource?: Workspace | null
  onClose: () => void
  onCreate: (draft: WorkspaceDraft, start: WorkspaceStart) => Promise<void>
}

export function CreateWorkspaceModal({ takenNames, copySource = null, onClose, onCreate }: Props) {
  const { t } = useTranslation('common')
  const [draft, setDraft] = useState<WorkspaceDraft>({
    name: '',
    icon: WORKSPACE_ICON_KEYS[0],
    color: WORKSPACE_COLOR_PRESETS[0],
  })
  const [start, setStart] = useState<WorkspaceStart>(copySource ? 'copy' : 'fresh')
  const [touched, setTouched] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const invalid = workspaceNameError(draft.name, takenNames, t) !== null

  const submit = async () => {
    setTouched(true)
    if (invalid || busy) return
    setBusy(true)
    setError(null)
    try {
      await onCreate({ ...draft, name: draft.name.trim() }, start)
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const options: { id: WorkspaceStart; icon: typeof IconCopy; title: string; desc: string }[] = copySource
    ? [
        {
          id: 'copy',
          icon: IconCopy,
          title: t('workspace_start_copy', { name: copySource.name }),
          desc: t('workspace_start_copy_desc'),
        },
        {
          id: 'fresh',
          icon: IconRocket,
          title: t('workspace_start_fresh'),
          desc: t('workspace_start_fresh_desc'),
        },
      ]
    : []

  return (
    <ModalShell
      icon={<IconPlus className="w-5 h-5 text-accent-bright" />}
      title={t('create_workspace_title')}
      maxWidth="max-w-lg"
      onClose={onClose}
      showClose={false}
      footer={
        <div className="ms-auto flex items-center gap-2.5">
          {error && <p className="me-2 text-xs text-danger">{error}</p>}
          <button
            type="button"
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={submit}
            disabled={busy || (touched && invalid)}
            className="focus-ring cursor-pointer px-5 py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white"
          >
            {busy ? t('creating') : t('create_workspace')}
          </button>
        </div>
      }
    >
      <div className="flex flex-col gap-6 p-6">
        <WorkspaceForm
          value={draft}
          onChange={setDraft}
          takenNames={takenNames}
          showErrors={touched}
          autoFocus
          onSubmit={submit}
          onNameBlur={() => draft.name && setTouched(true)}
        />

        {options.length > 0 && (
          <div className="flex flex-col gap-2">
            <span className="text-xs font-medium text-muted">{t('workspace_start_label')}</span>
            <div role="radiogroup" aria-label={t('workspace_start_label')} className="flex flex-col gap-1.5">
              {options.map(({ id, icon: OptionIcon, title, desc }) => {
                const active = start === id
                return (
                  <button
                    key={id}
                    type="button"
                    role="radio"
                    aria-checked={active}
                    onClick={() => setStart(id)}
                    className={`focus-ring cursor-pointer flex items-center gap-3 px-3.5 py-3 rounded-item border text-start ${
                      active
                        ? 'border-accent bg-accent/10'
                        : 'border-outline/50 bg-base/40 hover:border-accent-dim hover:bg-overlay/60'
                    }`}
                  >
                    <span
                      className={`w-8 h-8 shrink-0 rounded-tile flex items-center justify-center ${
                        active ? 'bg-accent/15 text-accent-bright' : 'bg-overlay text-muted'
                      }`}
                    >
                      <OptionIcon className="w-3.5 h-3.5" />
                    </span>
                    <span className="flex-1 min-w-0">
                      <span className="block text-sm font-medium text-ink truncate">{title}</span>
                      <span className="block text-2xs text-muted leading-relaxed">{desc}</span>
                    </span>
                    <span
                      className={`w-4.5 h-4.5 shrink-0 rounded-full border flex items-center justify-center ${
                        active ? 'bg-accent border-accent text-white' : 'border-outline/60'
                      }`}
                    >
                      {active && <IconCheck className="w-2.5 h-2.5" />}
                    </span>
                  </button>
                )
              })}
            </div>
          </div>
        )}
      </div>
    </ModalShell>
  )
}
