import type { DraggableAttributes, DraggableSyntheticListeners } from '@dnd-kit/core'
import { useTranslation } from 'react-i18next'
import { IconGrip } from '../../lib/icons'

interface DragHandleProps {
  ref: (node: HTMLElement | null) => void
  attributes: DraggableAttributes
  listeners: DraggableSyntheticListeners | undefined
  isDragging: boolean
  disabled?: boolean
  className?: string
}

export function DragHandle({
  ref,
  attributes,
  listeners,
  isDragging,
  disabled = false,
  className = '',
}: DragHandleProps) {
  const { t } = useTranslation('common')
  if (disabled) return null

  return (
    <button
      ref={ref}
      {...attributes}
      {...listeners}
      aria-label={t('drag_to_reorder')}
      className={`focus-ring z-20 w-5 h-10 rounded-full border flex items-center justify-center cursor-grab active:cursor-grabbing touch-none transition-all duration-200 ${
        isDragging
          ? 'bg-accent border-accent text-white scale-110 shadow-md shadow-accent/30 opacity-100'
          : 'bg-raised border-line shadow-md shadow-base text-muted/50 opacity-0 group-hover/drag:opacity-100 hover:border-accent-dim hover:text-accent hover:scale-110'
      } ${className}`}
    >
      <IconGrip className="w-2 h-2" />
    </button>
  )
}
