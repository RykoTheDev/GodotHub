import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  KeyboardSensor,
  PointerSensor,
  closestCenter,
  pointerWithin,
  rectIntersection,
  useSensor,
  useSensors,
  type CollisionDetection,
  type Collision,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { sortableKeyboardCoordinates } from '@dnd-kit/sortable'
import { DRAG_FEEL } from '../lib/dragFeel'
import { pushToast } from '../lib/toast'
import {
  resolveProjectDrop,
  categoryKeyOf,
  type DropPlacement,
  type DroppablePrefixes,
} from '../lib/projectDrag'
import type { Category, Project } from '../types'

export interface UseProjectDndOptions {
  projects: Project[]
  categories: Category[]
  grouped: boolean
  prefixes: DroppablePrefixes
  selectedIds?: Set<string>
  onReorder?: (orderedIds: string[]) => Promise<void> | void
  onMoveProjects?: (
    ids: string[],
    category: string,
    destOrderedIds: string[],
  ) => Promise<void> | void
}

export function useProjectDnd({
  projects,
  categories,
  grouped,
  prefixes,
  selectedIds,
  onReorder,
  onMoveProjects,
}: UseProjectDndOptions) {
  const overlayRef = useRef<HTMLDivElement | null>(null)

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: DRAG_FEEL.activationDistance },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  )

  const [activeIds, setActiveIds] = useState<string[]>([])
  const [activeId, setActiveId] = useState<string | null>(null)
  const placementRef = useRef<DropPlacement>('before')

  const byId = useMemo(
    () => new Map(projects.map((p) => [p.id, p])),
    [projects],
  )

  const collisionDetection = useCallback<CollisionDetection>((args) => {
    const zones = args.droppableContainers.filter((c) => String(c.id).startsWith(prefixes.category))
    const cards = args.droppableContainers.filter((c) => !String(c.id).startsWith(prefixes.category))
    let hits: Collision[]
    if (args.pointerCoordinates) {
      hits = pointerWithin({ ...args, droppableContainers: cards })
      if (hits.length === 0) {
        const zoneHits = pointerWithin({ ...args, droppableContainers: zones })
        const zone = zoneHits[0]
        if (zone) {
          const zoneRect = args.droppableRects.get(zone.id)
          const inside = cards.filter((c) => {
            const rect = args.droppableRects.get(c.id)
            return rect && zoneRect && rect.top >= zoneRect.top && rect.bottom <= zoneRect.bottom &&
              rect.left >= zoneRect.left && rect.right <= zoneRect.right
          })
          const y = args.pointerCoordinates.y
          const betweenCards = inside.some((c) => {
            const rect = args.droppableRects.get(c.id)!
            return y >= rect.top - 12 && y <= rect.bottom + 12
          })
          hits = betweenCards
            ? closestCenter({ ...args, droppableContainers: inside })
            : zoneHits
        } else {
          // Allow the small gaps between cards, but never snap to a distant target.
          const { x, y } = args.pointerCoordinates
          const nearby = cards.filter((c) => {
            const rect = args.droppableRects.get(c.id)
            return rect && x >= rect.left && x <= rect.right &&
              y >= rect.top - 12 && y <= rect.bottom + 12
          })
          hits = closestCenter({ ...args, droppableContainers: nearby })
        }
      }
    } else {
      const cardHits = rectIntersection({ ...args, droppableContainers: cards })
      const zoneHits = rectIntersection({ ...args, droppableContainers: zones })
      hits = cardHits.length > 0
        ? cardHits
        : zoneHits.length > 0
          ? zoneHits
          : closestCenter({ ...args, droppableContainers: cards })
    }
    const target = hits[0]
    const dragged = byId.get(String(args.active.id))
    const overProject = target ? byId.get(String(target.id)) : undefined
    const rect = target ? args.droppableRects.get(target.id) : undefined
    let next: DropPlacement = 'before'
    if (dragged && overProject && activeIds.length <= 1 &&
      (!grouped || categoryKeyOf(dragged) === categoryKeyOf(overProject))) {
      next = projects.indexOf(dragged) < projects.indexOf(overProject) ? 'after' : 'before'
    } else if (rect) {
      const y = args.pointerCoordinates?.y ?? args.collisionRect.top + args.collisionRect.height / 2
      next = y > rect.top + rect.height / 2 ? 'after' : 'before'
    }
    placementRef.current = next
    return hits
  }, [prefixes.category, byId, activeIds.length, grouped, projects])

  const handleDragStart = useCallback(
    (e: DragStartEvent) => {
      const id = String(e.active.id)
      setActiveId(id)
      const draggable = new Set(projects.map((p) => p.id))
      const carriesSelection =
        selectedIds != null &&
        selectedIds.size > 1 &&
        selectedIds.has(id) &&
        [...selectedIds].every((selected) => draggable.has(selected))

      setActiveIds(
        carriesSelection
          ? projects.filter((p) => selectedIds.has(p.id)).map((p) => p.id)
          : [id],
      )
    },
    [projects, selectedIds],
  )

  const reset = useCallback(() => {
    setActiveIds([])
    setActiveId(null)
  }, [])

  const handleDragCancel = useCallback(() => reset(), [reset])

  const handleDragEnd = useCallback(
    async (e: DragEndEvent) => {
      const { active, over } = e
      const group = activeIds.length > 0 ? activeIds : [String(active.id)]
      reset()
      if (!over) return
      const resolution = resolveProjectDrop({
        activeId: String(active.id),
        activeIds: group,
        overId: String(over.id),
        projects,
        categories,
        grouped,
        prefixes,
        placement: placementRef.current,
      })
      try {
        if (resolution.type === 'reorder') {
          await onReorder?.(resolution.orderedIds)
        } else if (resolution.type === 'move') {
          await onMoveProjects?.(
            resolution.activeIds,
            resolution.categoryName,
            resolution.destOrderedIds,
          )
        }
      } catch (error) {
        pushToast('error', String(error))
      }
    },
    [
      activeIds,
      reset,
      projects,
      categories,
      grouped,
      prefixes,
      onReorder,
      onMoveProjects,
    ],
  )

  useEffect(() => {
    if (activeIds.length === 0) return
    const { body } = document
    const prevCursor = body.style.cursor
    const prevSelect = body.style.userSelect
    body.style.cursor = 'grabbing'
    body.style.userSelect = 'none'
    return () => {
      body.style.cursor = prevCursor
      body.style.userSelect = prevSelect
    }
  }, [activeIds.length])

  const activeProject = activeId ? byId.get(activeId) ?? null : null

  return {
    sensors,
    activeId,
    activeIds,
    activeProject,
    overlayRef,
    collisionDetection,
    placementRef,
    handleDragStart,
    handleDragEnd,
    handleDragCancel,
  }
}
