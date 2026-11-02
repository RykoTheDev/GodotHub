import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Project } from '../../types'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import { ModalShell } from '../modals/ModalShell'
import { IconBriefcase, IconPlus } from '../../lib/icons'
import { VaultSourceSection } from './VaultSourceSection'
import { TagEditor } from './TagEditor'

interface SourceDraft {
  key: number
  projectId: string | null
  selected: Set<string>
}

interface Props {
  projects: Project[]
  initialProjectId?: string | null
  onClose: () => void
  onSaved: () => void
}

export function SaveToVaultModal({
  projects,
  initialProjectId,
  onClose,
  onSaved,
}: Props) {
  const { t } = useTranslation('common')
  const [sources, setSources] = useState<SourceDraft[]>(() => [
    { key: 0, projectId: initialProjectId ?? null, selected: new Set() },
  ])
  const [nextKey, setNextKey] = useState(1)
  const [name, setName] = useState('')
  const [desc, setDesc] = useState('')
  const [tags, setTags] = useState<string[]>([])
  const [busy, setBusy] = useState(false)

  const updateSource = (key: number, patch: Partial<SourceDraft>) => {
    setSources((prev) =>
      prev.map((s) => (s.key === key ? { ...s, ...patch } : s)),
    )
  }

  const handleProjectChange = (key: number, id: string) => {
    updateSource(key, { projectId: id, selected: new Set() })
  }

  const handleToggle = (key: number, rel: string) => {
    setSources((prev) =>
      prev.map((s) => {
        if (s.key !== key) return s
        const next = new Set(s.selected)
        if (next.has(rel)) {
          next.delete(rel)
        } else {
          for (const existing of [...next]) {
            if (existing === rel || existing.startsWith(`${rel}/`))
              next.delete(existing)
          }
          next.add(rel)
        }
        return { ...s, selected: next }
      }),
    )
  }

  const addSource = () => {
    setSources((prev) => [
      ...prev,
      { key: nextKey, projectId: null, selected: new Set() },
    ])
    setNextKey((k) => k + 1)
  }

  const removeSource = (key: number) => {
    setSources((prev) => prev.filter((s) => s.key !== key))
  }

  const payloadSources = sources
    .filter((s) => s.projectId && s.selected.size > 0)
    .map((s) => ({ project_id: s.projectId as string, paths: [...s.selected] }))

  const canSave =
    name.trim().length > 0 && payloadSources.length > 0 && !busy

  const handleSave = async () => {
    if (!canSave) return
    setBusy(true)
    try {
      await api.saveToVault(name.trim(), desc.trim(), tags, payloadSources)
      pushToast('success', t('vault_saved_toast'))
      onSaved()
      onClose()
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconBriefcase className="w-4 h-4" />}
      title={t('vault_save_title')}
      description={t('vault_save_desc')}
      maxWidth="max-w-lg"
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
            disabled={!canSave}
            className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-xs font-semibold text-white transition-colors"
          >
            {busy ? t('saving') : t('vault_save_btn')}
          </button>
        </>
      }
    >
      <div className="p-6 pt-4 flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('vault_source_project_label')}
          </label>
          <div className="flex flex-col gap-2">
            {sources.map((source, index) => (
              <VaultSourceSection
                key={source.key}
                projects={projects}
                projectId={source.projectId}
                selected={source.selected}
                index={index}
                canRemove={sources.length > 1}
                onProjectChange={(id) => handleProjectChange(source.key, id)}
                onToggle={(rel) => handleToggle(source.key, rel)}
                onRemove={() => removeSource(source.key)}
              />
            ))}
          </div>
          <button
            type="button"
            onClick={addSource}
            className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 px-3 py-2 rounded-item border border-dashed border-outline/60 text-xs font-medium text-muted hover:text-ink hover:border-accent-dim transition-colors"
          >
            <IconPlus className="w-3.5 h-3.5" />
            {t('vault_add_source')}
          </button>
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('vault_item_name_label')}
          </label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder={t('vault_item_name_placeholder')}
            className="focus-ring w-full bg-raised border border-outline/50 rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
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
            rows={2}
            className="focus-ring w-full bg-raised border border-outline/50 rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors resize-none"
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
