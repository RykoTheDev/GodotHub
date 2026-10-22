import { useEffect, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { IconAlertTriangle, IconTrash } from '../../lib/icons'
import { ModalShell } from '../modals/ModalShell'

interface Props {
  untrackedFiles: string[]
  busy?: boolean
  onDiscardTracked: () => void
  onRemoveUntracked: () => void
  onStash: () => void
  onCancel: () => void
}

export function DiscardChangesDialog({
  untrackedFiles,
  busy = false,
  onDiscardTracked,
  onRemoveUntracked,
  onStash,
  onCancel,
}: Props) {
  const { t } = useTranslation('git')
  const { t: tc } = useTranslation('common')
  const safeRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    safeRef.current?.focus()
  }, [])

  const hasUntracked = untrackedFiles.length > 0

  return (
    <ModalShell
      icon={<IconAlertTriangle className="w-5 h-5 text-amber" />}
      title={t('discard_dialog_title')}
      description={t('discard_dialog_tracked_desc')}
      maxWidth="max-w-md"
      onClose={busy ? undefined : onCancel}
      footer={
        <button
          type="button"
          data-press-feedback
          disabled={busy}
          onClick={onCancel}
          className="ms-auto focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-50"
        >
          {tc('cancel')}
        </button>
      }
    >
      <div className="px-6 pb-6 pt-0 space-y-4">
        {hasUntracked ? (
          <section>
            <div className="text-xs font-medium text-muted mb-1.5">
              {t('discard_dialog_untracked_heading', { n: untrackedFiles.length })}
            </div>
            <ul className="max-h-40 overflow-y-auto rounded-item border border-line bg-raised/40 p-2 text-xs font-mono text-ink/80 space-y-0.5">
              {untrackedFiles.map((file) => (
                <li key={file} className="truncate">
                  {file}
                </li>
              ))}
            </ul>
          </section>
        ) : (
          <div className="text-xs text-muted">{t('discard_dialog_no_untracked')}</div>
        )}

        <div className="space-y-2">
          <button
            ref={safeRef}
            type="button"
            data-press-feedback
            disabled={busy}
            onClick={onDiscardTracked}
            className="focus-ring w-full text-start cursor-pointer rounded-btn px-3.5 py-3 bg-accent/10 border border-accent/40 hover:bg-accent/15 transition-colors disabled:opacity-50"
          >
            <div className="text-sm font-medium text-ink">{t('discard_opt_tracked')}</div>
            <div className="text-xs text-muted mt-0.5">{t('discard_opt_tracked_hint')}</div>
          </button>

          <button
            type="button"
            data-press-feedback
            disabled={busy || !hasUntracked}
            onClick={onRemoveUntracked}
            className="focus-ring w-full text-start cursor-pointer rounded-btn px-3.5 py-3 border border-danger/40 hover:bg-danger/10 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <div className="flex items-center gap-1.5 text-sm font-medium text-danger">
              <IconTrash className="w-3.5 h-3.5 shrink-0" />
              {t('discard_opt_untracked')}
            </div>
            <div className="text-xs text-muted mt-0.5">{t('discard_opt_untracked_hint')}</div>
          </button>

          <button
            type="button"
            data-press-feedback
            disabled={busy}
            onClick={onStash}
            className="focus-ring w-full text-start cursor-pointer rounded-btn px-3.5 py-3 border border-line hover:bg-raised transition-colors disabled:opacity-50"
          >
            <div className="text-sm font-medium text-ink">{t('discard_opt_stash')}</div>
            <div className="text-xs text-muted mt-0.5">{t('discard_opt_stash_hint')}</div>
          </button>
        </div>
      </div>
    </ModalShell>
  )
}
