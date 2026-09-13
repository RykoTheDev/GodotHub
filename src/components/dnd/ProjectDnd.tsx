import {
  useCallback,
  useLayoutEffect,
  type CSSProperties,
  type ReactNode,
} from 'react'
import {
  useDndContext,
  type DraggableAttributes,
  type DraggableSyntheticListeners,
} from '@dnd-kit/core'
import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { useTranslation } from 'react-i18next'
import { IconGrip } from '../../lib/icons'
import { isReducedMotion } from '../../lib/appearance'
import { DRAG_FEEL, REFLOW_TRANSITION } from '../../lib/dragFeel'

/**
 * Interactive elements should keep their own behaviour. A drag only starts
 * when the pointer goes down on the card body itself.
 */
const NO_DRAG_SELECTOR =
  'button, a, input, textarea, select, [role="button"], [contenteditable="true"], [data-drag-ignore]'

function DragGrip({
  ref,
  attributes,
  listeners,
  isDragging,
  className = '',
}: {
  ref: (node: HTMLElement | null) => void
  attributes: DraggableAttributes
  listeners: DraggableSyntheticListeners | undefined
  isDragging: boolean
  className?: string
}) {
  const { t } = useTranslation('common')
  return (
    <button
      ref={ref}
      type="button"
      {...attributes}
      {...listeners}
      aria-label={t('drag_to_reorder')}
      className={`focus-ring absolute top-1/2 z-20 flex h-9 w-[18px] -translate-y-1/2 cursor-grab touch-none items-center justify-center rounded-full border transition-all duration-150 active:cursor-grabbing ${
        isDragging
          ? 'pointer-events-none border-accent bg-accent text-white opacity-100 shadow-md shadow-accent/40'
          : 'pointer-events-none border-line bg-raised text-muted/40 opacity-0 shadow-sm shadow-base group-hover/drag:pointer-events-auto group-hover/drag:opacity-100 hover:border-accent-dim hover:text-accent focus-visible:pointer-events-auto focus-visible:opacity-100'
      } ${className}`}
    >
      <IconGrip className="h-2.5 w-2.5" />
    </button>
  )
}

export interface SortableProjectItemProps {
  id: string
  disabled?: boolean
  children: ReactNode
  className?: string
  /** Skip dnd-kit's translate transform (used by the masonry grid). */
  static?: boolean
  /** Position of the grip affordance inside the item. */
  gripClassName?: string
}

/**
 * A whole-card draggable wrapper. The card body starts the drag, buttons and
 * inputs keep working, and the grip doubles as the keyboard activator.
 *
 * Deliberately subscribes to no drag state: the list can hold hundreds of
 * cards and none of them should re-render just because a drag is in flight.
 */
export function SortableProjectItem({
  id,
  disabled = false,
  children,
  className = '',
  static: isStatic = false,
  gripClassName = 'left-0.5',
}: SortableProjectItemProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    setActivatorNodeRef,
    transform,
    isDragging,
  } = useSortable({ id, disabled })

  const onPointerDown = useCallback(
    (e: React.PointerEvent) => {
      if (disabled) return
      const target = e.target as HTMLElement | null
      if (target?.closest(NO_DRAG_SELECTOR)) return
      const handler = listeners?.onPointerDown as
        | ((event: React.PointerEvent) => void)
        | undefined
      handler?.(e)
    },
    [disabled, listeners],
  )

  const reduced = isReducedMotion()
  const style: CSSProperties = {
    transform: isStatic ? undefined : CSS.Translate.toString(transform),
    transition: reduced ? undefined : REFLOW_TRANSITION,
    zIndex: isDragging ? 40 : undefined,
  }

  return (
    <div ref={setNodeRef} style={style} className={`group/drag relative ${className}`}>
      <div
        onPointerDown={onPointerDown}
        style={isDragging ? { opacity: DRAG_FEEL.ghostOpacity } : undefined}
        className={`h-full ${disabled ? '' : 'cursor-grab active:cursor-grabbing'} ${
          isDragging ? 'rounded-item ring-1 ring-accent/30' : ''
        }`}
      >
        {!disabled && (
          <DragGrip
            ref={setActivatorNodeRef}
            attributes={attributes}
            listeners={listeners}
            isDragging={isDragging}
            className={gripClassName}
          />
        )}
        {children}
      </div>
    </div>
  )
}

/**
 * The accent insertion line, drawn once per surface in a fixed layer.
 *
 * It subscribes to dnd-kit directly, so the only component re-rendering while
 * the pointer moves is this thin strip of pixels.
 */
export function ProjectDropLine({ ignorePrefix }: { ignorePrefix?: string }) {
  const { active, over } = useDndContext()
  const { height, dot, glow, transition } = DRAG_FEEL.dropLine

  if (!active) return null

  const activeId = String(active.id)
  const overId = over ? String(over.id) : null
  const overRect = over?.rect ?? null
  const activeRect = active.rect.current.translated

  const onZone =
    overId != null && ignorePrefix != null && overId.startsWith(ignorePrefix)
  const visible = overId != null && overId !== activeId && !onZone && overRect != null

  const after =
    overRect != null && activeRect != null
      ? activeRect.top + activeRect.height / 2 >
        overRect.top + overRect.height / 2
      : false

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed z-40 flex -translate-y-1/2 items-center transition-opacity ease-out"
      style={{
        top: overRect ? (after ? overRect.bottom : overRect.top) : 0,
        left: overRect?.left ?? 0,
        width: overRect?.width ?? 0,
        opacity: visible ? 1 : 0,
        transitionDuration: `${transition}ms`,
      }}
    >
      <span
        style={{ width: dot, height: dot }}
        className="shrink-0 rounded-full bg-accent-bright"
      />
      <span
        style={{
          height,
          boxShadow: glow ? '0 0 10px var(--color-accent-bright)' : undefined,
        }}
        className="flex-1 origin-left rounded-full bg-accent-bright"
      />
    </div>
  )
}

/**
 * The floating preview rendered inside dnd-kit's <DragOverlay>. The hook writes
 * the lean (and lift scale) straight onto this node via `innerRef`, so moving
 * the pointer never triggers a React render.
 */
export function ProjectDragOverlay({
  innerRef,
  children,
  count = 1,
  className = '',
}: {
  innerRef: React.RefObject<HTMLDivElement | null>
  children: ReactNode
  /** Number of cards travelling; more than one shows a badge. */
  count?: number
  className?: string
}) {
  useLayoutEffect(() => {
    const el = innerRef.current
    if (el) el.style.transform = `rotate(0deg) scale(${DRAG_FEEL.lift.scale})`
  }, [innerRef])

  return (
    <div
      ref={innerRef}
      className={`relative rounded-item bg-overlay/95 shadow-2xl shadow-black/40 ring-1 ring-accent/25 backdrop-blur-sm ${className}`}
      style={{
        transformOrigin: 'center',
        transition: isReducedMotion()
          ? undefined
          : `transform ${DRAG_FEEL.tilt.easeMs}ms ease-out`,
      }}
    >
      {children}
      {count > 1 && (
        <span className="pointer-events-none absolute -top-2 -right-2 z-30 min-w-6 h-6 px-1.5 rounded-full bg-accent-bright text-white text-[11px] font-semibold flex items-center justify-center shadow-md shadow-black/30">
          {count}
        </span>
      )}
    </div>
  )
}
