import { useState, useCallback } from 'react'
import { useTranslation } from 'react-i18next'
import type { Category, Project } from '../../types'
import { ModalShell } from './ModalShell'
import { ColorSwatchPicker } from '../ui/ColorSwatchPicker'
import { CATEGORY_COLORS } from '../../lib/categoryColors'
import {
  SortableCategoryList,
  normalizeCategoryName,
} from '../reusables/SortableCategoryList'
import { IconFolder, IconPlus, IconTags } from '../../lib/icons'

interface Props {
  categories: Category[]
  projects?: Project[]
  onClose: () => void
  onCreate: (name: string, color?: string) => Promise<Category>
  onUpdate: (id: string, name?: string | null, color?: string | null) => Promise<Category>
  onDelete: (id: string) => Promise<void>
  onReorder: (orderedIds: string[]) => Promise<void>
  onAssignFolder: (id: string, folder: string) => Promise<Category>
  onUnassignFolder: (id: string, folder: string) => Promise<Category>
}

export function CategoryManagerModal({
  categories,
  projects = [],
  onClose,
  onCreate,
  onUpdate,
  onDelete,
  onReorder,
  onAssignFolder,
  onUnassignFolder,
}: Props) {
  const { t } = useTranslation('common')
  const [newName, setNewName] = useState('')
  const [newColor, setNewColor] = useState(CATEGORY_COLORS[0])
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const hasDuplicateName = useCallback(
    (name: string) => {
      const normalized = normalizeCategoryName(name)
      return categories.some((c) => normalizeCategoryName(c.name) === normalized)
    },
    [categories],
  )

  const submitNew = async () => {
    const trimmed = newName.trim()
    if (!trimmed) {
      setError('Category name is required.')
      return
    }
    if (hasDuplicateName(trimmed)) {
      setError('A category with this name already exists.')
      return
    }

    setBusy(true)
    setError(null)
    try {
      await onCreate(trimmed, newColor)
      setNewName('')
      setNewColor(CATEGORY_COLORS[0])
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const totalProjects = projects.length

  return (
    <ModalShell
      icon={<IconTags className="w-5 h-5 text-accent-bright" />}
      title={t('manage_categories')}
      maxWidth="max-w-2xl"
      onClose={onClose}
      footer={
        <div className="flex items-center justify-between w-full">
          <span className="text-xs text-muted/60">
            {categories.length === 0
              ? t('no_categories_yet')
              : `${categories.length} ${categories.length === 1 ? 'category' : 'categories'} · ${totalProjects} ${totalProjects === 1 ? 'project' : 'projects'}`}
          </span>
        </div>
      }
    >
      <div className="p-6 pt-0 flex flex-col gap-5">
        {categories.length > 0 && (
          <div className="flex items-start gap-2.5 px-3.5 py-2.5 rounded-lg bg-overlay/40 border border-outline/25">
            <IconFolder className="w-3.5 h-3.5 text-muted/60 shrink-0 mt-0.5" />
            <p className="text-2xs text-muted leading-relaxed">
              {t('category_folders_hint')}
            </p>
          </div>
        )}

        <div className="flex flex-col gap-3">
          <div className="flex gap-2.5">
            <div className="flex-1 min-w-0 flex items-center bg-raised border border-line rounded-xl focus-within:border-accent-dim">
              <ColorSwatchPicker
                value={newColor}
                onChange={setNewColor}
                presets={CATEGORY_COLORS}
                trigger={({ open, toggle }) => (
                  <button
                    type="button"
                    onClick={toggle}
                    aria-expanded={open}
                    aria-label={t('color_label')}
                    className="focus-ring cursor-pointer ms-3 w-6 h-6 rounded-full border border-black/20 shadow-inner shrink-0 hover:scale-110"
                    style={{ backgroundColor: newColor }}
                  />
                )}
              />
              <input
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') submitNew()
                }}
                placeholder={t('new_category_placeholder')}
                className="flex-1 min-w-0 bg-transparent px-3 py-3 text-sm outline-none"
              />
            </div>
            <button
              onClick={submitNew}
              disabled={busy || !newName.trim()}
              className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-3 rounded-xl bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white "
            >
              <IconPlus className="w-4 h-4" />
              {t('add')}
            </button>
          </div>
        </div>

        {error && (
          <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-danger/10 border border-danger/20">
            <p className="text-xs text-danger">{error}</p>
          </div>
        )}

        {categories.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 gap-3 text-muted/50">
            <div className="w-14 h-14 rounded-2xl bg-overlay border border-dashed border-outline/40 flex items-center justify-center">
              <IconTags className="w-6 h-6 opacity-40" />
            </div>
            <div className="text-center">
              <p className="text-sm font-medium text-muted/70">{t('no_categories_yet')}</p>
              <p className="text-xs text-muted/40 mt-1">{t('category_empty_hint')}</p>
            </div>
          </div>
        ) : (
          <SortableCategoryList
            categories={categories}
            projects={projects}
            onUpdate={onUpdate}
            onDelete={onDelete}
            onReorder={onReorder}
            onAssignFolder={onAssignFolder}
            onUnassignFolder={onUnassignFolder}
            onError={setError}
          />
        )}
      </div>
    </ModalShell>
  )
}
