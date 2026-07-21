import { useState, useCallback, useEffect } from 'react'
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
import { ColorSwatchPicker } from '../ui/ColorSwatchPicker'
import {
  IconCheck,
  IconGrip,
  IconPencil,
  IconPlus,
  IconTrash,
  IconX,
} from '../Icons'

const CATEGORY_COLORS = [
  '#457ff2', '#f28b45', '#45c97f', '#e74c8a', '#a855f7',
  '#22d3ee', '#f59e0b', '#ef4444', '#10b981', '#6366f1',
  '#ec4899', '#14b8a6', '#f97316', '#8b5cf6', '#06b6d4',
  '#84cc16', '#d946ef', '#0ea5e9', '#eab308', '#3b82f6',
]

interface Props {
  categories: Category[]
  onClose: () => void
  onCreate: (name: string, color?: string) => Promise<Category>
  onUpdate: (id: string, name?: string | null, color?: string | null) => Promise<Category>
  onDelete: (id: string) => Promise<void>
  onReorder: (orderedIds: string[]) => Promise<void>
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
  onEditColorChange: (color: string) => void
  onConfirmDelete: () => void
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
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
      className={`group flex items-center gap-2.5 px-3 py-2.5 rounded-lg border bg-raised transition-colors ${
        isDragging
          ? 'border-accent shadow-lg shadow-accent/10 scale-[1.02] z-10'
          : 'border-line'
      }`}
    >
      <IconGrip
        {...attributes}
        {...listeners}
        className="w-3.5 h-3.5 text-muted/50 shrink-0 cursor-grab active:cursor-grabbing touch-none"
      />
      {editing ? (
        <>
          <div className="flex-1 flex flex-col gap-2">
            <input
              autoFocus
              value={editValue}
              onChange={(e) => onEditValueChange(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && onSubmitEdit()}
              className="focus-ring w-full bg-surface border border-line rounded-md px-2.5 py-1.5 text-sm focus:border-accent-dim transition-colors"
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
              aria-label="Save"
              className="focus-ring cursor-pointer p-1.5 rounded-md text-mint hover:bg-surface transition-colors"
            >
              <IconCheck className="w-4 h-4" />
            </button>
            <button
              onClick={onCancelEdit}
              aria-label="Cancel"
              className="focus-ring cursor-pointer p-1.5 rounded-md text-muted hover:bg-surface transition-colors"
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
          <span className="flex-1 text-sm truncate">{category.name}</span>
          <button
            onClick={onStartEdit}
            aria-label={`Edit ${category.name}`}
            className="focus-ring cursor-pointer p-1.5 rounded-md text-muted opacity-0 group-hover:opacity-100 hover:text-ink hover:bg-surface transition-colors"
          >
            <IconPencil className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={onConfirmDelete}
            aria-label={`Delete ${category.name}`}
            className="focus-ring cursor-pointer p-1.5 rounded-md text-muted opacity-0 group-hover:opacity-100 hover:text-danger hover:bg-surface transition-colors"
          >
            <IconTrash className="w-3.5 h-3.5" />
          </button>
        </>
      )}
    </div>
  )
}

export function CategoryManagerModal({
  categories,
  onClose,
  onCreate,
  onUpdate,
  onDelete,
  onReorder,
}: Props) {
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

  useEffect(() => {
    if (!activeId) {
      setItems(categories.map((c) => c.id))
    }
  }, [categories, activeId])

  const submitNew = async () => {
    if (!newName.trim()) return
    setBusy(true)
    setError(null)
    try {
      const created = await onCreate(newName.trim(), newColor)
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
    if (!editValue.trim()) return
    setBusy(true)
    setError(null)
    try {
      await onUpdate(
        id,
        editValue !== categories.find((c) => c.id === id)?.name ? editValue : null,
        editColor !== categories.find((c) => c.id === id)?.color ? editColor : null,
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
        const newItems = arrayMove(items, oldIndex, newIndex)
        setItems(newItems)
        await onReorder(newItems)
      }
    },
    [items, onReorder],
  )

  const draggedCategory = activeId
    ? categories.find((c) => c.id === activeId)
    : null

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-7 w-full max-w-lg flex flex-col gap-6 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
        onPointerDown={(e) => e.stopPropagation()}
      >
        <div>
          <h3 className="font-display font-semibold text-lg">
            Manage Categories
          </h3>
          <p className="text-xs text-muted mt-1.5">
            Create your own categories, drag to reorder, and file projects into
            them from the Projects list.
          </p>
        </div>

        <div className="flex flex-col gap-3">
          <div className="flex gap-2.5">
            <input
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && submitNew()}
              placeholder="New category name…"
              className="focus-ring flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors"
            />
            <motion.button
              whileHover={busy ? undefined : { y: -1 }}
              whileTap={busy ? undefined : { scale: 0.96 }}
              onClick={submitNew}
              disabled={busy || !newName.trim()}
              className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white transition-colors"
            >
              <IconPlus className="w-3.5 h-3.5" />
              Add
            </motion.button>
          </div>
          <ColorSwatchPicker
            label="Color"
            value={newColor}
            onChange={setNewColor}
            presets={CATEGORY_COLORS}
          />
        </div>

        {error && <p className="text-xs text-danger -mt-3">{error}</p>}

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
            <div className="flex flex-col gap-2 max-h-72 overflow-y-auto">
              {categories.length === 0 ? (
                <p className="text-xs text-muted text-center py-6">
                  No categories yet, add one above.
                </p>
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
              <div className="flex items-center gap-2.5 px-3 py-2.5 rounded-lg border border-accent bg-raised shadow-xl shadow-accent/10">
                <IconGrip className="w-3.5 h-3.5 text-muted/50 shrink-0" />
                <span
                  className="w-3 h-3 rounded-full shrink-0 ring-1 ring-black/10"
                  style={{ backgroundColor: draggedCategory.color }}
                />
                <span className="text-sm truncate">{draggedCategory.name}</span>
              </div>
            ) : null}
          </DragOverlay>
        </DndContext>

        <div className="flex justify-end mt-1">
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            Done
          </motion.button>
        </div>
      </motion.div>

      {confirmDelete && (
        <div onClick={(e) => e.stopPropagation()}>
          <ConfirmDialog
            title="Delete category?"
            description={`"${confirmDelete.name}" will be removed. Projects filed under it move to Uncategorized, nothing on disk is touched.`}
            confirmLabel="Delete"
            variant="danger"
            onConfirm={() => {
              onDelete(confirmDelete.id)
              setConfirmDeleteId(null)
            }}
            onCancel={() => setConfirmDeleteId(null)}
          />
        </div>
      )}
    </motion.div>
  )
}
