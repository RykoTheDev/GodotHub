import { useState, useCallback, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  KeyboardSensor,
  useSensor,
  useSensors,
  closestCorners,
  type DragStartEvent,
  type DragEndEvent,
} from '@dnd-kit/core'
import {
  SortableContext,
  useSortable,
  verticalListSortingStrategy,
  arrayMove,
  sortableKeyboardCoordinates,
} from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import type { Category, Project } from '../../types'
import { ConfirmDialog } from './ConfirmDialog'
import { ModalShell } from './ModalShell'
import { ColorSwatchPicker } from '../ui/ColorSwatchPicker'
import { DragHandle } from '../reusables/DragHandle'
import {
  IconCheck,
  IconGrip,
  IconPencil,
  IconPlus,
  IconTags,
  IconTrash,
  IconX,
} from '../../lib/icons'

const CATEGORY_COLORS = [
  '#457ff2', '#f28b45', '#45c97f', '#e74c8a', '#a855f7',
  '#22d3ee', '#f59e0b', '#ef4444', '#10b981', '#6366f1',
  '#ec4899', '#14b8a6', '#f97316', '#8b5cf6', '#06b6d4',
  '#84cc16', '#d946ef', '#0ea5e9', '#eab308', '#3b82f6',
]

function normalizeCategoryName(value: string): string {
  return value.trim().toLocaleLowerCase()
}

function SortableCategoryItem({
  category,
  projects,
  editing,
  editValue,
  editColor,
  onStartEdit,
  onSubmitEdit,
  onCancelEdit,
  onEditValueChange,
  onEditColorChange,
  onConfirmDelete,
}: {
  category: Category
  projects: Project[]
  editing: boolean
  editValue: string
  editColor: string
  onStartEdit: () => void
  onSubmitEdit: () => void
  onCancelEdit: () => void
  onEditValueChange: (value: string) => void
  onEditColorChange: (value: string) => void
  onConfirmDelete: () => void
}) {
  const { t } = useTranslation('common')
  const {
    attributes,
    listeners,
    setNodeRef,
    setActivatorNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: category.id,
    disabled: editing,
  })

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`group flex flex-col rounded-xl border transition-all ${
        isDragging
          ? 'border-accent shadow-lg shadow-accent/10 scale-[1.02] z-10'
          : 'border-line/60 hover:border-accent-dim/50 hover:shadow-sm'
      } bg-raised`}
    >
      <div className="flex items-center gap-3 px-3 py-3">
        <DragHandle
          ref={setActivatorNodeRef}
          attributes={attributes}
          listeners={listeners}
          isDragging={isDragging}
          disabled={editing}
          className="!static !transform-none !opacity-100 !w-7 !h-7 !rounded-lg"
        />
        {editing ? (
          <>
            <div className="flex-1 flex flex-col gap-2.5">
              <input
                autoFocus
                value={editValue}
                onChange={(e) => onEditValueChange(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') onSubmitEdit()
                  if (e.key === 'Escape') onCancelEdit()
                }}
                className="focus-ring w-full bg-base border border-accent/40 rounded-lg px-3 py-2 text-sm focus:border-accent-dim transition-colors outline-none"
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
                className="focus-ring cursor-pointer p-2 rounded-lg text-green-500 hover:bg-green-500/10 transition-colors"
              >
                <IconCheck className="w-4 h-4" />
              </button>
              <button
                onClick={onCancelEdit}
                aria-label={t('cancel')}
                className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:bg-raised transition-colors"
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
                  <span className="text-[11px] text-muted/60">
                    {projects.length} {projects.length === 1 ? 'project' : 'projects'}
                  </span>
                )}
              </div>
            </div>
            <div className="flex items-center gap-1 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                onClick={onStartEdit}
                aria-label={t('edit_category', { name: category.name })}
                className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:text-ink hover:bg-base transition-colors"
              >
                <IconPencil className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={onConfirmDelete}
                aria-label={t('delete_category', { name: category.name })}
                className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:text-danger hover:bg-danger/10 transition-colors"
              >
                <IconTrash className="w-3.5 h-3.5" />
              </button>
            </div>
          </>
        )}
      </div>
      {projects.length > 0 && !editing && (
        <div className="px-12 pb-3 pt-0">
          <div className="flex flex-wrap gap-1.5">
            {projects.slice(0, 8).map((p) => (
              <div
                key={p.id}
                className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-overlay/60 border border-outline/20 max-w-[160px] hover:bg-overlay transition-colors"
              >
                <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: category.color }} />
                <span className="text-[11px] text-muted truncate">{p.name}</span>
              </div>
            ))}
            {projects.length > 8 && (
              <div className="flex items-center px-2.5 py-1">
                <span className="text-[11px] text-muted/50">+{projects.length - 8} more</span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

interface Props {
  categories: Category[]
  projects?: Project[]
  onClose: () => void
  onCreate: (name: string, color?: string) => Promise<Category>
  onUpdate: (id: string, name?: string | null, color?: string | null) => Promise<Category>
  onDelete: (id: string) => Promise<void>
  onReorder: (orderedIds: string[]) => Promise<void>
}

export function CategoryManagerModal({
  categories,
  projects = [],
  onClose,
  onCreate,
  onUpdate,
  onDelete,
  onReorder,
}: Props) {
  const { t } = useTranslation('common')
  const [newName, setNewName] = useState('')
  const [newColor, setNewColor] = useState(CATEGORY_COLORS[0])
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editValue, setEditValue] = useState('')
  const [editColor, setEditColor] = useState('')
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null)
  const [activeId, setActiveId] = useState<string | null>(null)
  const [items, setItems] = useState<string[]>(() => categories.map((c) => c.id))

  const hasDuplicateName = useCallback(
    (name: string, excludeId?: string) => {
      const normalized = normalizeCategoryName(name)
      return categories.some(
        (c) => c.id !== excludeId && normalizeCategoryName(c.name) === normalized,
      )
    },
    [categories],
  )

  useEffect(() => {
    if (!activeId) {
      setItems(categories.map((c) => c.id))
    }
  }, [categories, activeId])

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
      const created = await onCreate(trimmed, newColor)
      setNewName('')
      setNewColor(CATEGORY_COLORS[0])
      setItems((prev) => [...prev, created.id])
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const startEdit = (c: Category) => {
    setEditingId(c.id)
    setEditValue(c.name)
    setEditColor(c.color)
    setError(null)
  }

  const submitEdit = async (id: string) => {
    const trimmed = editValue.trim()
    if (!trimmed) {
      setError('Category name is required.')
      return
    }
    if (hasDuplicateName(trimmed, id)) {
      setError('A category with this name already exists.')
      return
    }

    setBusy(true)
    setError(null)
    try {
      const current = categories.find((c) => c.id === id)
      await onUpdate(
        id,
        trimmed !== current?.name ? trimmed : null,
        editColor !== current?.color ? editColor : null,
      )
      setEditingId(null)
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const confirmDelete = confirmDeleteId
    ? categories.find((c) => c.id === confirmDeleteId)
    : null

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 4 } }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  )

  const handleDragStart = useCallback((e: DragStartEvent) => {
    setActiveId(e.active.id as string)
  }, [])

  const handleDragEnd = useCallback(
    async (e: DragEndEvent) => {
      const { active, over } = e
      setActiveId(null)

      if (!over || active.id === over.id) return

      const oldIndex = items.indexOf(active.id as string)
      const newIndex = items.indexOf(over.id as string)

      if (oldIndex !== -1 && newIndex !== -1 && oldIndex !== newIndex) {
        const prevItems = items
        const newItems = arrayMove(items, oldIndex, newIndex)
        setItems(newItems)
        try {
          await onReorder(newItems)
        } catch (e) {
          setItems(prevItems)
          setError(String(e))
        }
      }
    },
    [items, onReorder],
  )

  const draggedCategory = activeId
    ? categories.find((c) => c.id === activeId)
    : null

  const totalProjects = projects.length

  return (
    <ModalShell
      icon={<IconTags className="w-5 h-5 text-accent-bright" />}
      title={t('manage_categories_title')}
      description={t('manage_categories_desc')}
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
        {/* New category form */}
        <div className="flex flex-col gap-3">
          <div className="flex gap-2.5">
            <input
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') submitNew()
              }}
              placeholder={t('new_category_placeholder')}
              className="focus-ring flex-1 bg-raised border border-line rounded-xl px-4 py-3 text-sm focus:border-accent-dim transition-colors outline-none"
            />
            <motion.button
              whileHover={busy ? undefined : { scale: 1.02 }}
              whileTap={busy ? undefined : { scale: 0.97 }}
              onClick={submitNew}
              disabled={busy || !newName.trim()}
              className="focus-ring cursor-pointer shrink-0 flex items-center gap-2 px-5 py-3 rounded-xl bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white transition-colors"
            >
              <IconPlus className="w-4 h-4" />
              {t('add')}
            </motion.button>
          </div>
          <ColorSwatchPicker
            label={t('color_label')}
            value={newColor}
            onChange={setNewColor}
            presets={CATEGORY_COLORS}
          />
        </div>

        {error && (
          <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-danger/10 border border-danger/20">
            <p className="text-xs text-danger">{error}</p>
          </div>
        )}

        {/* Categories list */}
        <DndContext
          sensors={sensors}
          collisionDetection={closestCorners}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          <SortableContext
            items={items}
            strategy={verticalListSortingStrategy}
          >
            <div className="flex flex-col gap-2 max-h-80 overflow-y-auto min-h-0 pr-1">
              {categories.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 gap-3 text-muted/50">
                  <div className="w-14 h-14 rounded-2xl bg-overlay border border-dashed border-outline/40 flex items-center justify-center">
                    <IconTags className="w-6 h-6 opacity-40" />
                  </div>
                  <div className="text-center">
                    <p className="text-sm font-medium text-muted/70">{t('no_categories_yet')}</p>
                    <p className="text-xs text-muted/40 mt-1">Create one above to organize your projects</p>
                  </div>
                </div>
              ) : (
                <AnimatePresence initial={false}>
                  {items.map((id) => {
                    const cat = categories.find((c) => c.id === id)
                    if (!cat) return null
                    return (
                      <SortableCategoryItem
                        key={cat.id}
                        category={cat}
                        projects={projects.filter((p) => p.category === cat.name)}
                        editing={editingId === cat.id}
                        editValue={editingId === cat.id ? editValue : ''}
                        editColor={editingId === cat.id ? editColor : ''}
                        onStartEdit={() => startEdit(cat)}
                        onSubmitEdit={() => submitEdit(cat.id)}
                        onCancelEdit={() => setEditingId(null)}
                        onEditValueChange={setEditValue}
                        onEditColorChange={setEditColor}
                        onConfirmDelete={() => setConfirmDeleteId(cat.id)}
                      />
                    )
                  })}
                </AnimatePresence>
              )}
            </div>
          </SortableContext>

          <DragOverlay
            dropAnimation={{
              duration: 250,
              easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
          >
            {draggedCategory ? (
              <div className="flex items-center gap-3 px-4 py-3 rounded-xl border border-accent bg-raised shadow-xl shadow-accent/10">
                <IconGrip className="w-4 h-4 text-muted/50 shrink-0" />
                <span
                  className="w-4 h-4 rounded-full shrink-0 ring-2 ring-black/10 shadow-sm"
                  style={{ backgroundColor: draggedCategory.color }}
                />
                <span className="text-sm font-medium truncate text-ink">{draggedCategory.name}</span>
              </div>
            ) : null}
          </DragOverlay>
        </DndContext>
      </div>

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
              setError(null)
              void onDelete(confirmDelete.id)
                .then(() => setConfirmDeleteId(null))
                .catch((e) => setError(String(e)))
                .finally(() => setBusy(false))
            }}
            onCancel={() => setConfirmDeleteId(null)}
          />
        </div>
      )}
    </ModalShell>
  )
}
