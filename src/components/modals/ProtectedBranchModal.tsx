import { useId, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { IconLock, IconSpinner } from '../../lib/icons'
import { ModalShell } from './ModalShell'

interface Props {
  branch: string
  suggestedBranch: string
  onCommitAnyway: () => void
  onCreatePullRequest: (branch: string) => Promise<void>
  onClose: () => void
}

export function ProtectedBranchModal({
  branch,
  suggestedBranch,
  onCommitAnyway,
  onCreatePullRequest,
  onClose,
}: Props) {
  const { t } = useTranslation('git')
  const { t: tc } = useTranslation('common')
  const formId = useId()
  const branchId = useId()
  const [newBranch, setNewBranch] = useState(suggestedBranch)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submit = async (event: React.FormEvent) => {
    event.preventDefault()
    const name = newBranch.trim()
    if (!name || busy) return
    setBusy(true)
    setError(null)
    try {
      await onCreatePullRequest(name)
    } catch (e) {
      setError(String(e))
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconLock className="w-5 h-5 text-amber" />}
      title={t('protected_branch_title')}
      maxWidth="max-w-md"
      onClose={busy ? undefined : onClose}
      onKeyDown={(event) => {
        if (event.key === 'Escape' && !busy) { event.stopPropagation(); onClose() }
      }}
      footer={<div className="ms-auto flex items-center gap-2.5">
        <button type="button" onClick={onClose} disabled={busy}
          className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised disabled:opacity-40 disabled:cursor-not-allowed">{tc('cancel')}</button>
        <button type="button" onClick={onCommitAnyway} disabled={busy}
          className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn border border-line text-sm text-ink hover:bg-raised disabled:opacity-40 disabled:cursor-not-allowed">{t('protected_branch_commit_anyway')}</button>
        <button type="submit" form={formId} data-autofocus disabled={!newBranch.trim() || busy}
          className="focus-ring cursor-pointer inline-flex items-center gap-2 px-4 py-2.5 rounded-btn bg-accent text-sm font-medium text-white hover:bg-accent-bright disabled:opacity-40 disabled:cursor-not-allowed">
          {busy && <IconSpinner className="w-3.5 h-3.5 animate-spin" />}
          {busy ? t('protected_branch_creating_pr') : t('protected_branch_create_pr')}
        </button>
      </div>}
    >
      <form id={formId} onSubmit={submit} aria-busy={busy} className="flex flex-col gap-4 p-6 pt-0">
        <p className="text-sm text-muted leading-relaxed wrap-break-word">
          {t('protected_branch_desc', { branch })}
        </p>
        <div className="flex flex-col gap-2">
          <label htmlFor={branchId} className="text-xs font-medium text-muted">{t('protected_branch_new_label')}</label>
          <input id={branchId} dir="ltr" required value={newBranch} onChange={e => setNewBranch(e.target.value)} disabled={busy}
            className="focus-ring bg-raised border border-line rounded-item px-3.5 py-2.5 text-sm font-mono text-ink placeholder:text-muted/50 focus:border-accent-dim disabled:opacity-50" />
        </div>
        {error && <p role="alert" className="rounded-item border border-danger/25 bg-danger/10 p-3 text-xs text-danger wrap-break-word">{error}</p>}
      </form>
    </ModalShell>
  )
}
