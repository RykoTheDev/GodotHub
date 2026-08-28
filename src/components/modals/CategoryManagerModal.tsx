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
import type { Category } from '../../types'
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
      className={`group flex items-center gap-2.5 px-3 py-2.5 rounded-xl border transition-colors ${
        isDragging
          ? 'border-accent shadow-lg shadow-accent/10 scale-[1.02] z-10'
          : 'border-line/60 hover:border-accent-dim/40'
      } bg-raised`}
    >
      <DragHandle
        ref={setActivatorNodeRef}
        attributes={attributes}
        listeners={listeners}
        isDragging={isDragging}
        disabled={editing}
        className="!static !transform-none !opacity-100 !w-6 !h-6 !rounded-md"
      />
      {editing ? (
        <>
          <div className="flex-1 flex flex-col gap-2">
            <input
              autoFocus
              value={editValue}
              onChange={(e) => onEditValueChange(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') onSubmitEdit()
                if (e.key === 'Escape') onCancelEdit()
              }}
              className="focus-ring w-full bg-base border border-accent/40 rounded-lg px-2.5 py-1.5 text-sm focus:border-accent-dim transition-colors outline-none"
            />
            <ColorSwatchPicker
              label=""
              value={editColor}
              onChange={onEditColorChange}
              presets={CATEGORY_COLORS}
            />
          </div>
          <div className="flex flex-col gap-1 shrink-0">
            <button
              onClick={onSubmitEdit}
              aria-label={t('save')}
              className="focus-ring cursor-pointer p-1.5 rounded-md text-green-500 hover:bg-green-500/10 transition-colors"
            >
              <IconCheck className="w-4 h-4" />
            </button>
            <button
              onClick={onCancelEdit}
              aria-label={t('cancel')}
              className="focus-ring cursor-pointer p-1.5 rounded-md text-muted hover:bg-raised transition-colors"
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          </div>
        </>
      ) : (
        <>
          <span
            className="w-3 h-3 rounded-full shrink-0 ring-1 ring-black/10"
            style={{ backgroundColor: category.color }}
          />
          <span className="flex-1 text-sm truncate text-ink">{category.name}</span>
          <button
            onClick={onStartEdit}
            aria-label={t('edit_category', { name: category.name })}
            className="focus-ring cursor-pointer p-1.5 rounded-md text-muted opacity-0 group-hover:opacity-100 hover:text-ink hover:bg-base transition-colors"
          >
            <IconPencil className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={onConfirmDelete}
            aria-label={t('delete_category', { name: category.name })}
            className="focus-ring cursor-pointer p-1.5 rounded-md text-muted opacity-0 group-hover:opacity-100 hover:text-danger hover:bg-danger/10 transition-colors"
          >
            <IconTrash className="w-3.5 h-3.5" />
          </button>
        </>
      )}
    </div>
  )
}

interface Props {
  categories: Category[]
  onClose: () => void
  onCreate: (name: string, color?: string) => Promise<Category>
  onUpdate: (id: string, name?: string | null, color?: string | null) => Promise<Category>
  onDelete: (id: string) => Promise<void>
  onReorder: (orderedIds: string[]) => Promise<void>
}

export function CategoryManagerModal({
  categories,
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

  return (
    <ModalShell
      icon={<IconTags className="w-5 h-5 text-accent-bright" />}
      title={t('manage_categories_title')}
      description={t('manage_categories_desc')}
      maxWidth="max-w-lg"
      onClose={onClose}
      footer={
        <span className="text-xs text-muted/60">
          {categories.length === 0
            ? t('no_categories_yet')
            : t('tag_count', { count: categories.length })}
        </span>
      }
    >
      <div className="p-6 pt-0 flex flex-col gap-4">
        <div className="flex gap-2.5">
          <input
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') submitNew()
            }}
            placeholder={t('new_category_placeholder')}
            className="focus-ring flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors outline-none"
          />
          <motion.button
            whileHover={busy ? undefined : { scale: 1.03 }}
            whileTap={busy ? undefined : { scale: 0.96 }}
            onClick={submitNew}
            disabled={busy || !newName.trim()}
            className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white transition-colors"
          >
            <IconPlus className="w-3.5 h-3.5" />
            {t('add')}
          </motion.button>
        </div>
        <ColorSwatchPicker
          label={t('color_label')}
          value={newColor}
          onChange={setNewColor}
          presets={CATEGORY_COLORS}
        />

        {error && <p className="text-xs text-danger -mt-1">{error}</p>}

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
            <div className="flex flex-col gap-2 max-h-72 overflow-y-auto min-h-0">
              {categories.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 gap-2 text-muted/60">
                  <IconTags className="w-8 h-8 opacity-40" />
                  <p className="text-sm">{t('no_categories_yet')}</p>
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
              <div className="flex items-center gap-2.5 px-3 py-2.5 rounded-xl border border-accent bg-raised shadow-xl shadow-accent/10">
                <IconGrip className="w-3.5 h-3.5 text-muted/50 shrink-0" />
                <span
                  className="w-3 h-3 rounded-full shrink-0 ring-1 ring-black/10"
                  style={{ backgroundColor: draggedCategory.color }}
                />
                <span className="text-sm truncate text-ink">{draggedCategory.name}</span>
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
