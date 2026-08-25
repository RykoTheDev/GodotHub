import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Project } from '../../../types'
import { api } from '../../../lib/api'
import { pushToast } from '../../lib/toast'
import { ModalShell } from './ModalShell'
import { IconCopy } from '../../lib/icons'

interface Props {
  project: Project
  onClose: () => void
}

export function SaveAsTemplateModal({ project, onClose }: Props) {
  const { t } = useTranslation('common')
  const [name, setName] = useState('')
  const [desc, setDesc] = useState('')
  const [busy, setBusy] = useState(false)

  const displayName = project.name

  const handleSave = async () => {
    const trimmed = name.trim()
    if (!trimmed || busy) return
    setBusy(true)
    try {
      await api.saveProjectAsTemplate(project.id, trimmed, desc.trim())
      pushToast('success', t('template_saved_toast'))
      onClose()
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconCopy className="w-4 h-4" />}
      title={t('project_save_template_title')}
      description={t('project_save_template_desc', { name: displayName })}
      maxWidth="max-w-sm"
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-item text-xs font-medium text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={() => void handleSave()}
            disabled={busy || !name.trim()}
            className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-xs font-semibold text-white transition-colors"
          >
            {busy ? t('project_saving_template') : t('project_save_template_btn')}
          </button>
        </>
      }
    >
      <div className="p-6 pt-4 flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('project_template_name_label')}
          </label>
          <input
            autoFocus
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && name.trim()) void handleSave()
            }}
            placeholder={displayName}
            className="focus-ring w-full bg-raised border border-outline/50 rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('project_template_desc_label')}{' '}
            <span className="text-muted/60 font-normal">
              {t('project_template_desc_sublabel')}
            </span>
          </label>
          <textarea
            value={desc}
            onChange={(e) => setDesc(e.target.value)}
            placeholder={t('project_template_desc_placeholder')}
            rows={3}
            className="focus-ring w-full bg-raised border border-outline/50 rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors resize-none"
          />
        </div>
      </div>
    </ModalShell>
  )
}
