import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type CollisionDetection,
  type DragEndEvent,
  type DragMoveEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { sortableKeyboardCoordinates } from '@dnd-kit/sortable'
import { isReducedMotion } from '../lib/appearance'
import { DRAG_FEEL } from '../lib/dragFeel'
import {
  resolveProjectDrop,
  type DroppablePrefixes,
} from '../lib/projectDrag'
import type { Category, Project } from '../types'

export interface UseProjectDndOptions {
  /** Draggable projects in DOM order (pinned projects excluded). */
  projects: Project[]
  categories: Category[]
  grouped: boolean
  prefixes: DroppablePrefixes
  collisionDetection?: CollisionDetection
  /**
   * Selection state. A drag that starts on a selected card carries the whole
   * selection, as long as every selected project is draggable.
   */
  selectedIds?: Set<string>
  onReorder?: (orderedIds: string[]) => Promise<void> | void
  onMoveProjects?: (
    ids: string[],
    category: string,
    destOrderedIds: string[],
  ) => Promise<void> | void
}

/**
 * Owns everything drag related for a projects surface: sensors, the active
 * card(s), the overlay transform, and the drop resolution.
 *
 * The tilt is written straight to the overlay's DOM node instead of React
 * state. Drag move fires many times a second, and re-rendering a list of cards
 * on every one of those would make the card visibly trail the pointer.
 */
export function useProjectDnd({
  projects,
  categories,
  grouped,
  prefixes,
  collisionDetection,
  selectedIds,
  onReorder,
  onMoveProjects,
}: UseProjectDndOptions) {
  const reducedMotion = isReducedMotion()
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
  const activeId = activeIds[0] ?? null

  const byId = useMemo(
    () => new Map(projects.map((p) => [p.id, p])),
    [projects],
  )

  const motion = useRef({ x: 0, t: 0, angle: 0 })

  const paintTilt = useCallback((angle: number) => {
    const el = overlayRef.current
    if (!el) return
    el.style.transform = `rotate(${angle}deg) scale(${DRAG_FEEL.lift.scale})`
  }, [])

  const handleDragStart = useCallback(
    (e: DragStartEvent) => {
      const id = String(e.active.id)
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
      motion.current = { x: 0, t: performance.now(), angle: 0 }
    },
    [projects, selectedIds],
  )

  const handleDragMove = useCallback(
    (e: DragMoveEvent) => {
      if (reducedMotion) return
      const now = performance.now()
      const dt = now - motion.current.t
      if (dt < DRAG_FEEL.tilt.sampleMs) return
      const vx = (e.delta.x - motion.current.x) / dt
      const { maxDeg, velocityScale, damping } = DRAG_FEEL.tilt
      const target = Math.max(-maxDeg, Math.min(maxDeg, vx * velocityScale))
      motion.current.x = e.delta.x
      motion.current.t = now
      motion.current.angle += (target - motion.current.angle) * damping
      paintTilt(motion.current.angle)
    },
    [reducedMotion, paintTilt],
  )

  const reset = useCallback(() => {
    setActiveIds([])
    motion.current = { x: 0, t: 0, angle: 0 }
    paintTilt(0)
  }, [paintTilt])

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
      })
      if (resolution.type === 'reorder') {
        await onReorder?.(resolution.orderedIds)
      } else if (resolution.type === 'move') {
        await onMoveProjects?.(
          resolution.activeIds,
          resolution.categoryName,
          resolution.destOrderedIds,
        )
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
    handleDragStart,
    handleDragMove,
    handleDragEnd,
    handleDragCancel,
  }
}
