import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { CurrentVersionInfo } from '../../types'
import { api } from '../../lib/api'
import { IconCheck, IconCopy, IconExternalLink, IconPin } from '../../lib/icons'
import { ModalShell } from './ModalShell'

type CopyTarget = 'alias' | 'dir'

export function CurrentVersionModal({
  info,
  onClose,
}: {
  info: CurrentVersionInfo
  onClose: () => void
}) {
  const { t: tv } = useTranslation('versions')
  const { t: tc } = useTranslation('common')
  const [copied, setCopied] = useState<CopyTarget | null>(null)

  const copy = async (target: CopyTarget, value: string) => {
    try {
      await navigator.clipboard.writeText(value)
      setCopied(target)
      setTimeout(() => setCopied(null), 1500)
    } catch {}
  }

  const pathRow = (target: CopyTarget, label: string, value: string) => (
    <div className="flex items-center gap-3 px-3 py-2.5 rounded-item bg-overlay border border-outline/50">
      <div className="min-w-0 flex-1">
        <p className="text-[11px] font-semibold uppercase tracking-wider text-muted">
          {label}
        </p>
        <p className="font-mono text-xs text-ink truncate mt-0.5" title={value}>
          {value}
        </p>
      </div>
      <button
        type="button"
        onClick={() => copy(target, value)}
        aria-label={tv(`current_copy_${target}`)}
        className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-btn border border-line text-xs text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
      >
        {copied === target ? (
          <IconCheck className="w-3.5 h-3.5 text-mint" />
        ) : (
          <IconCopy className="w-3.5 h-3.5" />
        )}
        {copied === target ? tv('current_copied') : tv('current_copy')}
      </button>
    </div>
  )

  return (
    <ModalShell
      icon={<IconPin className="w-5 h-5 text-accent-bright" />}
      title={tv('current_set_title')}
      description={tv('current_set_desc', { tag: info.tag })}
      maxWidth="max-w-xl"
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={() => api.openProjectFolder(info.aliases_dir).catch(() => {})}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
          >
            <IconExternalLink className="w-4 h-4" />
            {tv('current_open_folder')}
          </button>
          <button
            type="button"
            onClick={onClose}
            className="focus-ring cursor-pointer ml-auto px-4 py-2.5 rounded-item bg-accent hover:bg-accent/90 text-sm font-medium text-white transition-colors"
          >
            {tc('close')}
          </button>
        </>
      }
    >
      <div className="px-6 pb-6 flex flex-col gap-3">
        {pathRow('alias', tv('current_alias_label'), info.alias_path)}
        {pathRow('dir', tv('current_dir_label'), info.aliases_dir)}
        <p className="text-xs text-muted leading-relaxed">
          {tv('current_path_hint')}
        </p>
        {info.method === 'shim' && (
          <p className="text-xs text-amber leading-relaxed">
            {tv('current_shim_note')}
          </p>
        )}
      </div>
    </ModalShell>
  )
}
