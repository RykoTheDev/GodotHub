import { useId, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { api } from '../../lib/api'
import { defaultWorktreePath } from '../../lib/worktreePaths'
import { IconClone, IconFolder, IconSpinner } from '../../lib/icons'
import { ModalShell } from './ModalShell'

interface Props {
  repositoryPath: string
  onClose: () => void
  onCreated: () => void
}

export function CreateWorktreeModal({ repositoryPath, onClose, onCreated }: Props) {
  const { t } = useTranslation('git')
  const { t: tc } = useTranslation('common')
  const formId = useId()
  const pathId = useId()
  const branchId = useId()
  const [path, setPath] = useState(() => defaultWorktreePath(repositoryPath))
  const [branch, setBranch] = useState('')
  const [busy, setBusy] = useState(false)
  const [picking, setPicking] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const create = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!path.trim() || busy || picking) return
    setBusy(true)
    setError(null)
    try {
      await api.gitWorktreeAdd(repositoryPath, path.trim(), branch.trim() || undefined)
      onCreated()
    } catch (error) {
      setError(String(error))
      setBusy(false)
    }
  }

  const browse = async () => {
    setPicking(true)
    setError(null)
    try {
      const parent = await api.pickFolder()
      if (parent) {
        const folder = path.replace(/\\/g, '/').replace(/\/+$/, '').split('/').pop()
        setPath(`${parent.replace(/[\\/]+$/, '')}/${folder || 'worktree'}`)
      }
    } catch (error) { setError(String(error)) }
    finally { setPicking(false) }
  }

  return (
    <ModalShell
      icon={<IconClone className="w-5 h-5" />}
      title={t('create_worktree_title')}
      description={t('create_worktree_desc')}
      maxWidth="max-w-lg"
      onClose={busy || picking ? undefined : onClose}
      onKeyDown={(event) => {
        if (event.key === 'Escape' && !busy && !picking) { event.stopPropagation(); onClose() }
      }}
      footer={<div className="ml-auto flex items-center gap-2.5">
        <button type="button" onClick={onClose} disabled={busy || picking}
          className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed">{tc('cancel')}</button>
        <button type="submit" form={formId} disabled={!path.trim() || busy || picking}
          className="focus-ring cursor-pointer inline-flex items-center gap-2 px-4 py-2.5 rounded-btn bg-accent text-sm font-medium text-white hover:bg-accent-bright transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
          {busy && <IconSpinner className="w-3.5 h-3.5 animate-spin" />}
          {busy ? t('worktree_creating') : t('add_worktree_btn')}
        </button>
      </div>}
    >
      <form id={formId} onSubmit={create} aria-busy={busy} className="flex flex-col gap-5 p-6 pt-0">
        <div className="flex flex-col gap-2">
          <label htmlFor={pathId} className="text-xs font-medium text-muted">{t('worktree_location_label')}</label>
          <div className="flex gap-2">
            <input id={pathId} dir="ltr" autoFocus required value={path} onChange={e => setPath(e.target.value)} disabled={busy || picking}
              aria-describedby={`${pathId}-hint`} placeholder={t('worktree_path_placeholder')}
              className="focus-ring min-w-0 flex-1 bg-raised border border-line rounded-item px-3.5 py-2.5 text-sm font-mono text-ink placeholder:text-muted/50 focus:border-accent-dim transition-colors disabled:opacity-50" />
            <button type="button" onClick={() => void browse()} disabled={busy || picking} title={t('worktree_browse_parent')} aria-label={t('worktree_browse_parent')}
              className="focus-ring cursor-pointer flex items-center justify-center w-11 shrink-0 rounded-item border border-line text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
              {picking ? <IconSpinner className="w-4 h-4 animate-spin" /> : <IconFolder className="w-4 h-4" />}
            </button>
          </div>
          <p id={`${pathId}-hint`} className="text-[11px] text-muted/70 leading-relaxed">{t('worktree_location_hint')}</p>
        </div>
        <div className="flex flex-col gap-2">
          <label htmlFor={branchId} className="text-xs font-medium text-muted">{t('worktree_branch_label')}</label>
          <input id={branchId} dir="ltr" value={branch} onChange={e => setBranch(e.target.value)} disabled={busy}
            aria-describedby={`${branchId}-hint`} placeholder={t('worktree_branch_placeholder')}
            className="focus-ring bg-raised border border-line rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted/50 focus:border-accent-dim transition-colors disabled:opacity-50" />
          <p id={`${branchId}-hint`} className="text-[11px] text-muted/70 leading-relaxed">{t('worktree_branch_hint')}</p>
        </div>
        {error && <p role="alert" className="rounded-item border border-danger/25 bg-danger/10 p-3 text-xs text-danger wrap-break-word">{error}</p>}
      </form>
    </ModalShell>
  )
}
