import {
  useCallback,
  useLayoutEffect,
  type Ref,
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
import { DRAG_FEEL } from '../../lib/dragFeel'

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
      className={`focus-ring absolute top-1/2 z-20 flex h-9 w-6 -translate-y-1/2 cursor-grab touch-none items-center justify-center rounded-btn border transition-[opacity,color,background-color,border-color] duration-150 active:cursor-grabbing ${
        isDragging
          ? 'pointer-events-none border-accent bg-accent text-white opacity-100 shadow-md shadow-accent/40'
          : 'pointer-events-none border-line bg-raised text-muted/60 opacity-0 shadow-sm shadow-base group-hover/drag:pointer-events-auto group-hover/drag:opacity-100 group-focus-within/drag:pointer-events-auto group-focus-within/drag:opacity-100 hover:border-accent-dim hover:text-accent focus-visible:pointer-events-auto focus-visible:opacity-100'
      } ${className}`}
    >
      <IconGrip className="h-2.5 w-2.5" />
    </button>
  )
}

export interface SortableProjectItemProps {
  ref?: Ref<HTMLDivElement>
  id: string
  disabled?: boolean
  children: ReactNode
  className?: string
  static?: boolean
  gripClassName?: string
  carried?: boolean
  fillHeight?: boolean
}

export function SortableProjectItem({
  ref,
  id,
  disabled = false,
  children,
  className = '',
  static: isStatic = false,
  gripClassName = 'left-0.5',
  carried = false,
  fillHeight = true,
}: SortableProjectItemProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    setActivatorNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id,
    disabled,
    transition: isReducedMotion() ? null : DRAG_FEEL.reflow,
  })

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
  const setRefs = useCallback((node: HTMLDivElement | null) => {
    setNodeRef(node)
    if (typeof ref === 'function') ref(node)
    else if (ref) ref.current = node
  }, [ref, setNodeRef])
  const style: CSSProperties = {
    transform: isStatic ? undefined : CSS.Translate.toString(transform),
    transition: reduced ? undefined : transition,
    zIndex: isDragging ? 40 : undefined,
  }

  return (
    <div ref={setRefs} style={style} className={`group/drag relative ${className}`} data-project-id={id}>
      <div
        onPointerDown={onPointerDown}
        onDragStart={(event) => event.preventDefault()}
        style={isDragging || carried ? { opacity: DRAG_FEEL.ghostOpacity } : undefined}
        className={`${fillHeight ? 'h-full' : ''} ${disabled ? '' : 'cursor-grab active:cursor-grabbing'} ${
          isDragging || carried ? 'rounded-item ring-1 ring-accent/30' : ''
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

export function ProjectDropLine({ ignorePrefix, placement, activeIds = [] }: {
  ignorePrefix?: string
  placement?: React.RefObject<'before' | 'after'>
  activeIds?: string[]
}) {
  const { active, over } = useDndContext()
  const { height, dot, glow, transition } = DRAG_FEEL.dropLine

  if (!active) return null

  const activeId = String(active.id)
  const overId = over ? String(over.id) : null
  const overRect = over?.rect ?? null
  const activeRect = active.rect.current.translated

  const onZone =
    overId != null && ignorePrefix != null && overId.startsWith(ignorePrefix)
  const visible = overId != null && overId !== activeId && !activeIds.includes(overId) && !onZone && overRect != null

  const after = placement
    ? placement.current === 'after'
    : overRect != null && activeRect != null
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

export function ProjectDragOverlay({
  innerRef,
  children,
  count = 1,
  className = '',
}: {
  innerRef: React.RefObject<HTMLDivElement | null>
  children: ReactNode
  count?: number
  className?: string
}) {
  useLayoutEffect(() => {
    const el = innerRef.current
    if (el) el.style.transform = `rotate(0deg) scale(${isReducedMotion() ? 1 : DRAG_FEEL.lift.scale})`
  }, [innerRef])

  return (
    <div
      ref={innerRef}
      aria-hidden="true"
      className={`pointer-events-none relative rounded-item bg-overlay shadow-2xl shadow-black/30 ring-1 ring-accent/30 ${className}`}
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
