import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Workspace } from '../../types'
import { ModalShell } from './ModalShell'
import { IconPencil } from '../../lib/icons'
import { ConfirmDialog } from './ConfirmDialog'
import { WorkspaceForm, workspaceNameError, type WorkspaceDraft } from '../ui/WorkspaceForm'

interface Props {
  workspace: Workspace
  takenNames: string[]
  canDelete: boolean
  onClose: () => void
  onSave: (name: string, icon: string, color: string) => Promise<void>
  onDelete: () => Promise<void>
}

export function WorkspaceEditModal({
  workspace,
  takenNames,
  canDelete,
  onClose,
  onSave,
  onDelete,
}: Props) {
  const { t } = useTranslation('common')
  const [draft, setDraft] = useState<WorkspaceDraft>({
    name: workspace.name,
    icon: workspace.icon,
    color: workspace.color,
  })
  const [touched, setTouched] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [confirmingDelete, setConfirmingDelete] = useState(false)

  const invalid = workspaceNameError(draft.name, takenNames, t) !== null

  const submit = async () => {
    setTouched(true)
    if (invalid || busy) return
    setBusy(true)
    setError(null)
    try {
      await onSave(draft.name.trim(), draft.icon, draft.color)
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <>
      <ModalShell
        icon={<IconPencil className="w-5 h-5 text-accent-bright" />}
        title={t('edit_workspace_title')}
        maxWidth="max-w-lg"
        onClose={onClose}
        showClose={false}
        footer={
          <>
            <button
              type="button"
              onClick={() => canDelete && setConfirmingDelete(true)}
              disabled={!canDelete}
              title={canDelete ? undefined : t('cant_delete_only_workspace')}
              className="focus-ring cursor-pointer disabled:cursor-not-allowed px-4 py-2.5 rounded-btn text-sm text-muted hover:text-danger hover:bg-danger/5 disabled:opacity-40 disabled:hover:text-muted disabled:hover:bg-transparent"
            >
              {t('delete')}
            </button>
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
                {t('save')}
              </button>
            </div>
          </>
        }
      >
        <div className="p-6">
          <WorkspaceForm
            value={draft}
            onChange={setDraft}
            takenNames={takenNames}
            showErrors={touched}
            autoFocus
            onSubmit={submit}
            onNameBlur={() => setTouched(true)}
          />
        </div>
      </ModalShell>

      {confirmingDelete && (
        <ConfirmDialog
          title={t('delete_workspace_title')}
          description={t('delete_workspace_desc', { name: workspace.name })}
          confirmLabel={t('delete')}
          variant="danger"
          onConfirm={() => {
            setConfirmingDelete(false)
            onDelete()
          }}
          onCancel={() => setConfirmingDelete(false)}
        />
      )}
    </>
  )
}
