import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { DndContext, DragOverlay } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable'
import type { Category, Project } from '../../types'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { ColorSwatchPicker } from '../ui/ColorSwatchPicker'
import { CATEGORY_COLORS } from '../../lib/categoryColors'
import { DROP_ANIMATION, DragLiftOverlay, SortableItem } from '../dnd/SortableDnd'
import { useSortableList } from '../../hooks/useSortableList'
import { api } from '../../lib/api'
import {
  IconCheck,
  IconFolder,
  IconFolderPlus,
  IconPencil,
  IconTrash,
  IconX,
} from '../../lib/icons'

export function normalizeCategoryName(value: string): string {
  return value.trim().toLocaleLowerCase()
}

function CategoryRow({
  category,
  projects,
  editing,
  busy,
  editValue,
  editColor,
  onStartEdit,
  onSubmitEdit,
  onCancelEdit,
  onEditValueChange,
  onEditColorChange,
  onConfirmDelete,
  onAssignFolder,
  onRemoveFolder,
}: {
  category: Category
  projects: Project[]
  editing: boolean
  busy: boolean
  editValue: string
  editColor: string
  onStartEdit: () => void
  onSubmitEdit: () => void
  onCancelEdit: () => void
  onEditValueChange: (value: string) => void
  onEditColorChange: (value: string) => void
  onConfirmDelete: () => void
  onAssignFolder: () => void
  onRemoveFolder: (folder: string) => void
}) {
  const { t } = useTranslation('common')

  return (
    <div className="group flex flex-col rounded-item border border-outline/50 bg-raised hover:border-accent-dim/50">
      <div className="flex items-center gap-3 px-4 py-3">
        {editing ? (
          <>
            <div className="flex-1 flex flex-col gap-2.5">
              <input
                autoFocus
                value={editValue}
                onChange={(e) => onEditValueChange(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') onSubmitEdit()
                  if (e.key === 'Escape') {
                    e.stopPropagation()
                    onCancelEdit()
                  }
                }}
                className="focus-ring w-full bg-base border border-accent/40 rounded-lg px-3 py-2 text-sm focus:border-accent-dim outline-none"
              />
              <ColorSwatchPicker
                label=""
                value={editColor}
                onChange={onEditColorChange}
                presets={CATEGORY_COLORS}
              />
            </div>
            <div className="flex flex-col gap-1.5 shrink-0">
              <button
                onClick={onSubmitEdit}
                aria-label={t('save')}
                className="focus-ring cursor-pointer p-2 rounded-lg text-green-500 hover:bg-green-500/10 "
              >
                <IconCheck className="w-4 h-4" />
              </button>
              <button
                onClick={onCancelEdit}
                aria-label={t('cancel')}
                className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:bg-raised "
              >
                <IconX className="w-3.5 h-3.5" />
              </button>
            </div>
          </>
        ) : (
          <>
            <div className="flex items-center gap-3 flex-1 min-w-0">
              <span
                className="w-4 h-4 rounded-full shrink-0 ring-2 ring-black/10 shadow-sm"
                style={{ backgroundColor: category.color }}
              />
              <div className="flex-1 min-w-0">
                <span className="text-sm font-medium truncate text-ink block">{category.name}</span>
                {projects.length > 0 && (
                  <span className="text-2xs text-muted/60">
                    {projects.length} {projects.length === 1 ? 'project' : 'projects'}
                  </span>
                )}
              </div>
            </div>
            <div className="flex items-center gap-1 shrink-0 opacity-0 group-hover:opacity-100 ">
              <button
                onClick={onStartEdit}
                aria-label={t('edit_category', { name: category.name })}
                className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:text-ink hover:bg-base "
              >
                <IconPencil className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={onConfirmDelete}
                aria-label={t('delete_category', { name: category.name })}
                className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:text-danger hover:bg-danger/10 "
              >
                <IconTrash className="w-3.5 h-3.5" />
              </button>
            </div>
          </>
        )}
      </div>
      {!editing && (
        <div className={`ps-11 pe-4 pt-0 ${projects.length > 0 ? 'pb-1' : 'pb-3'}`}>
          <div className="flex flex-wrap items-center gap-1.5">
            {category.folders.map((folder) => (
              <span
                key={folder}
                className="flex items-center gap-1.5 ps-2.5 pe-1 py-1 rounded-lg bg-base/70 border border-outline/25 max-w-[240px]"
              >
                <IconFolder className="w-3 h-3 text-muted/60 shrink-0" />
                <span
                  className="text-2xs text-muted truncate font-mono"
                  title={folder}
                >
                  {folder}
                </span>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => onRemoveFolder(folder)}
                  aria-label={t('unassign_folder_aria', { folder })}
                  className="focus-ring cursor-pointer shrink-0 p-1 rounded-md text-muted/50 hover:text-danger hover:bg-danger/10 disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  <IconX className="w-2.5 h-2.5" />
                </button>
              </span>
            ))}
            <button
              type="button"
              disabled={busy}
              onClick={onAssignFolder}
              aria-label={t('assign_folder_to_category', { name: category.name })}
              className="focus-ring cursor-pointer flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-dashed border-outline/50 text-2xs text-muted hover:text-accent-bright hover:border-accent-dim disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <IconFolderPlus className="w-3 h-3" />
              {t('assign_folder')}
            </button>
          </div>
        </div>
      )}
      {projects.length > 0 && !editing && (
        <div className="ps-11 pe-4 pb-3 pt-0">
          <div className="flex flex-wrap gap-1.5">
            {projects.slice(0, 8).map((p) => (
              <div
                key={p.id}
                className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-overlay/60 border border-outline/20 max-w-[160px] hover:bg-overlay "
              >
                <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: category.color }} />
                <span className="text-2xs text-muted truncate">{p.name}</span>
              </div>
            ))}
            {projects.length > 8 && (
              <div className="flex items-center px-2.5 py-1">
                <span className="text-2xs text-muted/50">+{projects.length - 8} more</span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

export function SortableCategoryList({
  categories,
  projects = [],
  onUpdate,
  onDelete,
  onReorder,
  onAssignFolder,
  onUnassignFolder,
  onError,
}: {
  categories: Category[]
  projects?: Project[]
  onUpdate: (id: string, name?: string | null, color?: string | null) => Promise<Category>
  onDelete: (id: string) => Promise<void>
  onReorder: (orderedIds: string[]) => Promise<void>
  onAssignFolder: (id: string, folder: string) => Promise<Category>
  onUnassignFolder: (id: string, folder: string) => Promise<Category>
  onError: (message: string | null) => void
}) {
  const { t } = useTranslation('common')
  const [busy, setBusy] = useState(false)
  const [folderBusyId, setFolderBusyId] = useState<string | null>(null)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editValue, setEditValue] = useState('')
  const [editColor, setEditColor] = useState('')
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null)
  const [ordered, setOrdered] = useState<Category[]>(categories)

  const sortable = useSortableList({
    items: ordered,
    getId: (c) => c.id,
    onReorder: (orderedIds) => {
      const prev = ordered
      const rank = new Map(orderedIds.map((id, i) => [id, i]))
      setOrdered([...ordered].sort((a, b) => (rank.get(a.id) ?? 0) - (rank.get(b.id) ?? 0)))
      onReorder(orderedIds).catch((e) => {
        setOrdered(prev)
        onError(String(e))
      })
    },
  })

  useEffect(() => {
    if (!sortable.activeId) setOrdered(categories)
  }, [categories, sortable.activeId])

  const assignFolder = async (category: Category) => {
    const folder = await api.pickFolder()
    if (!folder) return
    setFolderBusyId(category.id)
    onError(null)
    try {
      await onAssignFolder(category.id, folder)
    } catch (e) {
      onError(String(e))
    } finally {
      setFolderBusyId(null)
    }
  }

  const removeFolder = async (category: Category, folder: string) => {
    setFolderBusyId(category.id)
    onError(null)
    try {
      await onUnassignFolder(category.id, folder)
    } catch (e) {
      onError(String(e))
    } finally {
      setFolderBusyId(null)
    }
  }

  const startEdit = (c: Category) => {
    setEditingId(c.id)
    setEditValue(c.name)
    setEditColor(c.color)
    onError(null)
  }

  const submitEdit = async (id: string) => {
    const trimmed = editValue.trim()
    if (!trimmed) {
      onError('Category name is required.')
      return
    }
    const normalized = normalizeCategoryName(trimmed)
    if (categories.some((c) => c.id !== id && normalizeCategoryName(c.name) === normalized)) {
      onError('A category with this name already exists.')
      return
    }

    setBusy(true)
    onError(null)
    try {
      const current = categories.find((c) => c.id === id)
      await onUpdate(
        id,
        trimmed !== current?.name ? trimmed : null,
        editColor !== current?.color ? editColor : null,
      )
      setEditingId(null)
    } catch (e) {
      onError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const confirmDelete = confirmDeleteId
    ? categories.find((c) => c.id === confirmDeleteId)
    : null

  const renderRow = (cat: Category) => (
    <CategoryRow
      category={cat}
      projects={projects.filter((p) => p.category === cat.name)}
      editing={editingId === cat.id}
      busy={folderBusyId === cat.id}
      editValue={editingId === cat.id ? editValue : ''}
      editColor={editingId === cat.id ? editColor : ''}
      onStartEdit={() => startEdit(cat)}
      onSubmitEdit={() => submitEdit(cat.id)}
      onCancelEdit={() => setEditingId(null)}
      onEditValueChange={setEditValue}
      onEditColorChange={setEditColor}
      onConfirmDelete={() => setConfirmDeleteId(cat.id)}
      onAssignFolder={() => void assignFolder(cat)}
      onRemoveFolder={(folder) => void removeFolder(cat, folder)}
    />
  )

  return (
    <>
      <DndContext {...sortable.contextProps}>
        <SortableContext items={sortable.ids} strategy={verticalListSortingStrategy}>
          <div className="flex flex-col gap-2">
            {ordered.map((cat) => (
              <SortableItem key={cat.id} id={cat.id} disabled={editingId === cat.id}>
                {renderRow(cat)}
              </SortableItem>
            ))}
          </div>
        </SortableContext>

        <DragOverlay dropAnimation={DROP_ANIMATION}>
          {sortable.activeItem ? (
            <DragLiftOverlay>{renderRow(sortable.activeItem)}</DragLiftOverlay>
          ) : null}
        </DragOverlay>
      </DndContext>

      {confirmDelete && (
        <div onClick={(e) => e.stopPropagation()}>
          <ConfirmDialog
            title={t('delete_category_title')}
            description={t('delete_category_desc', { name: confirmDelete.name })}
            confirmLabel={t('delete')}
            variant="danger"
            onConfirm={() => {
              if (busy) return
              setBusy(true)
              onError(null)
              void onDelete(confirmDelete.id)
                .then(() => setConfirmDeleteId(null))
                .catch((e) => onError(String(e)))
                .finally(() => setBusy(false))
            }}
            onCancel={() => setConfirmDeleteId(null)}
          />
        </div>
      )}
    </>
  )
}
