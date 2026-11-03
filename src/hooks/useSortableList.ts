import { useCallback, useEffect, useState } from 'react'
import {
  KeyboardSensor,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { arrayMove, sortableKeyboardCoordinates } from '@dnd-kit/sortable'
import { AUTO_SCROLL_CONFIG, DRAG_FEEL } from '../lib/dragFeel'

export function useDragSensors() {
  return useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: DRAG_FEEL.activationDistance },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  )
}

export function useGrabbingCursor(active: boolean) {
  useEffect(() => {
    if (!active) return
    const { body } = document
    const prevCursor = body.style.cursor
    const prevSelect = body.style.userSelect
    body.style.cursor = 'grabbing'
    body.style.userSelect = 'none'
    return () => {
      body.style.cursor = prevCursor
      body.style.userSelect = prevSelect
    }
  }, [active])
}

export function useSortableList<T>({
  items,
  getId,
  onReorder,
}: {
  items: T[]
  getId: (item: T) => string
  onReorder: (orderedIds: string[], activeId: string, overId: string) => void
}) {
  const sensors = useDragSensors()
  const [activeId, setActiveId] = useState<string | null>(null)
  useGrabbingCursor(activeId !== null)

  const ids = items.map(getId)

  const onDragStart = useCallback((e: DragStartEvent) => {
    setActiveId(String(e.active.id))
  }, [])

  const onDragCancel = useCallback(() => setActiveId(null), [])

  const onDragEnd = (e: DragEndEvent) => {
    setActiveId(null)
    const { active, over } = e
    if (!over || active.id === over.id) return
    const from = ids.indexOf(String(active.id))
    const to = ids.indexOf(String(over.id))
    if (from === -1 || to === -1) return
    onReorder(arrayMove(ids, from, to), String(active.id), String(over.id))
  }

  return {
    ids,
    activeId,
    activeItem: activeId === null ? null : items.find((item) => getId(item) === activeId) ?? null,
    contextProps: {
      sensors,
      collisionDetection: closestCenter,
      autoScroll: AUTO_SCROLL_CONFIG,
      onDragStart,
      onDragEnd,
      onDragCancel,
    },
  }
}
