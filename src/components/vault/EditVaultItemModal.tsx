import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { VaultItem } from '../../types'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import { ModalShell } from '../modals/ModalShell'
import { IconPencil } from '../../lib/icons'
import { TagEditor } from './TagEditor'

interface Props {
  item: VaultItem
  onClose: () => void
  onSaved: (item: VaultItem) => void
}

export function EditVaultItemModal({ item, onClose, onSaved }: Props) {
  const { t } = useTranslation('common')
  const [name, setName] = useState(item.name)
  const [desc, setDesc] = useState(item.description)
  const [tags, setTags] = useState<string[]>(item.tags)
  const [busy, setBusy] = useState(false)

  const handleSave = async () => {
    const trimmed = name.trim()
    if (!trimmed || busy) return
    setBusy(true)
    try {
      const updated = await api.updateVaultItem(
        item.id,
        trimmed,
        desc.trim(),
        tags,
      )
      pushToast('success', t('vault_item_updated_toast'))
      onSaved(updated)
      onClose()
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconPencil className="w-4 h-4" />}
      title={t('vault_edit_title')}
      maxWidth="max-w-sm"
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-item text-xs font-medium text-muted hover:text-ink hover:bg-raised "
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={() => void handleSave()}
            disabled={busy || !name.trim()}
            className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-xs font-semibold text-white "
          >
            {busy ? t('saving') : t('save')}
          </button>
        </>
      }
    >
      <div className="p-6 pt-4 flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('vault_item_name_label')}
          </label>
          <input
            autoFocus
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && name.trim()) void handleSave()
            }}
            className="focus-ring w-full bg-raised border border-outline/50 rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none "
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('vault_item_desc_label')}{' '}
            <span className="text-muted/60 font-normal">{t('optional')}</span>
          </label>
          <textarea
            value={desc}
            onChange={(e) => setDesc(e.target.value)}
            placeholder={t('vault_item_desc_placeholder')}
            rows={3}
            className="focus-ring w-full bg-raised border border-outline/50 rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none resize-none"
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('vault_item_tags_label')}{' '}
            <span className="text-muted/60 font-normal">{t('optional')}</span>
          </label>
          <TagEditor tags={tags} onChange={setTags} />
        </div>
      </div>
    </ModalShell>
  )
}
