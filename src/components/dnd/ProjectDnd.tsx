import {
  useCallback,
  type Ref,
  type CSSProperties,
  type ReactNode,
} from 'react'
import {
  defaultDropAnimationSideEffects,
  useDndContext,
  type DropAnimation,
} from '@dnd-kit/core'
import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { DRAG_FEEL } from '../../lib/dragFeel'

export const PROJECT_DROP_ANIMATION: DropAnimation = {
  duration: DRAG_FEEL.drop.duration,
  easing: DRAG_FEEL.drop.easing,
  keyframes: ({ transform }) => [
    { transform: CSS.Transform.toString(transform.initial) },
    { transform: `${CSS.Transform.toString(transform.final)} scale(${1 / DRAG_FEEL.lift.scale})` },
  ],
  sideEffects: defaultDropAnimationSideEffects({ styles: { active: { opacity: '0' } } }),
}

const NO_DRAG_SELECTOR =
  'button, a, input, textarea, select, [role="button"], [contenteditable="true"], [data-drag-ignore]'

export interface SortableProjectItemProps {
  ref?: Ref<HTMLDivElement>
  id: string
  disabled?: boolean
  children: ReactNode
  className?: string
  static?: boolean
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
    transition: DRAG_FEEL.reflow,
    attributes: { role: 'group' },
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

  const setRefs = useCallback((node: HTMLDivElement | null) => {
    setNodeRef(node)
    if (typeof ref === 'function') ref(node)
    else if (ref) ref.current = node
  }, [ref, setNodeRef])
  const style: CSSProperties = {
    transform: isStatic ? undefined : CSS.Translate.toString(transform),
    transition: isStatic ? undefined : transition,
    zIndex: isDragging ? 40 : undefined,
  }

  return (
    <div ref={setRefs} style={style} className={`group/drag relative ${className}`} data-project-id={id}>
      <div
        ref={disabled ? undefined : setActivatorNodeRef}
        {...(disabled ? {} : attributes)}
        onKeyDown={disabled ? undefined : (listeners?.onKeyDown as React.KeyboardEventHandler | undefined)}
        onPointerDown={onPointerDown}
        onDragStart={(event) => event.preventDefault()}
        style={isDragging || carried ? { opacity: DRAG_FEEL.ghostOpacity } : undefined}
        className={`${fillHeight ? 'h-full' : ''} ${disabled ? '' : 'cursor-grab active:cursor-grabbing'} ${
          isDragging || carried ? 'rounded-item ring-1 ring-accent/30' : ''
        }`}
      >
        {children}
      </div>
    </div>
  )
}

export function ProjectDropLine({ ignorePrefix, placement, activeIds = [], reflows }: {
  ignorePrefix?: string
  placement?: React.RefObject<'before' | 'after'>
  activeIds?: string[]
  reflows?: (activeId: string, overId: string) => boolean
}) {
  const { active, over } = useDndContext()
  const { height, dot, glow } = DRAG_FEEL.dropLine

  if (!active) return null

  const activeId = String(active.id)
  const overId = over ? String(over.id) : null
  const overRect = over?.rect ?? null
  const activeRect = active.rect.current.translated

  const onZone =
    overId != null && ignorePrefix != null && overId.startsWith(ignorePrefix)
  const visible = overId != null && overId !== activeId && !activeIds.includes(overId) && !onZone && overRect != null &&
    !reflows?.(activeId, overId)

  const after = placement
    ? placement.current === 'after'
    : overRect != null && activeRect != null
      ? activeRect.top + activeRect.height / 2 >
        overRect.top + overRect.height / 2
      : false

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed z-40 flex -translate-y-1/2 items-center "
      style={{
        top: overRect ? (after ? overRect.bottom : overRect.top) : 0,
        left: overRect?.left ?? 0,
        width: overRect?.width ?? 0,
        opacity: visible ? 1 : 0,
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
        className="flex-1 origin-left rtl:origin-right rounded-full bg-accent-bright"
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
  return (
    <div
      ref={innerRef}
      aria-hidden="true"
      style={{ '--drag-lift': DRAG_FEEL.lift.scale } as CSSProperties}
      className={`motion-drag-lift pointer-events-none relative rounded-item bg-overlay shadow-2xl shadow-black/30 ring-1 ring-accent/30 ${className}`}
    >
      {children}
      {count > 1 && (
        <span className="pointer-events-none absolute -top-2 -end-2 z-30 min-w-6 h-6 px-1.5 rounded-full bg-accent-bright text-white text-2xs font-semibold flex items-center justify-center shadow-md shadow-black/30">
          {count}
        </span>
      )}
    </div>
  )
}
