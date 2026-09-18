import {
  useEffect,
  useState,
  type MouseEvent as ReactMouseEvent,
  type ReactNode,
} from 'react'
import { useDndContext, useDroppable } from '@dnd-kit/core'
import { useTranslation } from 'react-i18next'
import { AnimatedNumber } from '../reusables/AnimatedNumber'
import { IconChevronDown, IconEye, IconEyeSlash } from '../../lib/icons'
import type { Category } from '../../types'

export interface HiddenCategoryEntry {
  category: Category
  count: number
}

export function ProjectCategorySection({
  title,
  color,
  count,
  defaultOpen = true,
  disableAnimation = false,
  droppableId,
  variant = 'list',
  onContextMenu,
  children,
}: {
  title: string
  color?: string
  count: number
  defaultOpen?: boolean
  disableAnimation?: boolean
  droppableId?: string
  variant?: 'list' | 'grid'
  onContextMenu?: (e: ReactMouseEvent<HTMLElement>) => void
  children: ReactNode
}) {
  const { t } = useTranslation('common')
  const [open, setOpen] = useState(defaultOpen)
  const [dropOpen, setDropOpen] = useState(false)
  const isEmpty = count === 0
  const { active } = useDndContext()

  const headerIsZone = !open || dropOpen
  const bodyIsZone = open && isEmpty && !dropOpen

  const { isOver, setNodeRef } = useDroppable({
    id: droppableId ?? `cat-${title}`,
    disabled: !headerIsZone && !bodyIsZone,
  })

  useEffect(() => {
    if (!active) {
      setDropOpen(false)
      return
    }
    if (!isOver || open) return
    setDropOpen(true)
    setOpen(true)
  }, [active, isOver, open])

  const hint = (
    <span
      className={`text-xs select-none ${
        isOver ? 'text-accent-bright font-medium' : 'text-muted/40'
      }`}
    >
      {isOver ? t('release_to_drop') : t('empty_category')}
    </span>
  )

  const body = (
    <div
      ref={bodyIsZone ? setNodeRef : undefined}
      className={
        variant === 'grid'
          ? `rounded-item transition-all duration-150 ${
              bodyIsZone && isOver
                ? 'bg-accent/10 border-2 border-dashed border-accent/50 min-h-[100px] flex items-center justify-center'
                : ''
            }`
          : `flex flex-col gap-2 pt-2 pb-0.5 rounded-item transition-colors duration-150 ${
              bodyIsZone && isOver ? 'bg-accent/10 ring-1 ring-accent/30' : ''
            }`
      }
    >
      {children}
      {isEmpty &&
        (variant === 'grid' ? (
          <div
            className={`rounded-item min-h-[100px] flex items-center justify-center ${
              isOver
                ? 'bg-accent/10 border-2 border-dashed border-accent/50'
                : 'bg-overlay/30 border border-dashed border-outline/30'
            }`}
          >
            {hint}
          </div>
        ) : (
          <div className="flex items-center justify-center py-6">{hint}</div>
        ))}
    </div>
  )

  return (
    <div className={variant === 'grid' ? 'flex flex-col mb-6' : 'flex flex-col'}>
      <button
        type="button"
        ref={headerIsZone ? setNodeRef : undefined}
        onClick={() => setOpen((v) => !v)}
        onContextMenu={
          onContextMenu
            ? (e) => {
                e.preventDefault()
                onContextMenu(e)
              }
            : undefined
        }
        aria-expanded={open}
        className={`focus-ring cursor-pointer w-full flex items-center gap-1.5 rounded-item text-left transition-colors group ${
          variant === 'grid' ? 'px-1 py-1.5 mb-1' : 'px-1 py-1'
        } ${
          headerIsZone && isOver
            ? 'bg-accent/10 ring-1 ring-accent/30'
            : 'hover:bg-raised/60'
        }`}
      >
        <IconChevronDown
          className={`w-3 h-3 text-muted/50 shrink-0 transition-transform duration-200 ${
            open ? '' : '-rotate-90'
          }`}
        />
        {color && (
          <span
            className="w-2 h-2 rounded-full shrink-0"
            style={{ backgroundColor: color }}
          />
        )}
        <span className="text-xs font-semibold uppercase tracking-wider text-muted/50 group-hover:text-muted transition-colors truncate">
          {title}
        </span>
        <div className="flex-1 h-px bg-outline/30 mx-1.5" />
        {headerIsZone && isOver && (
          <span className="text-[10px] font-medium text-accent-bright shrink-0">
            {t('release_to_drop')}
          </span>
        )}
        <span className="text-[10px] font-medium text-muted/50 tabular-nums shrink-0">
          · <AnimatedNumber value={count} />
        </span>
      </button>

      <div
        className={`grid ${
          disableAnimation
            ? ''
            : 'transition-[grid-template-rows] duration-200 ease-out'
        } ${open ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'}`}
      >
        <div className="overflow-hidden min-h-0">{body}</div>
      </div>
    </div>
  )
}

export function HiddenCategoriesSection({
  entries,
  onUnhide,
  className = '',
}: {
  entries: HiddenCategoryEntry[]
  onUnhide: (id: string) => void
  className?: string
}) {
  const { t } = useTranslation('common')
  const [open, setOpen] = useState(false)

  if (entries.length === 0) return null

  return (
    <div className={`flex flex-col ${className}`}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-1 py-1 rounded-item text-left hover:bg-raised/60 transition-colors group"
      >
        <IconChevronDown
          className={`w-3 h-3 text-muted/50 shrink-0 transition-transform duration-200 ${
            open ? '' : '-rotate-90'
          }`}
        />
        <IconEyeSlash className="w-3 h-3 text-muted/60 shrink-0" />
        <span className="text-xs font-semibold uppercase tracking-wider text-muted/50 group-hover:text-muted transition-colors">
          {t('hidden_categories')}
        </span>
        <div className="flex-1 h-px bg-outline/30 mx-1.5" />
        <span className="text-[10px] font-medium text-muted/50 tabular-nums shrink-0">
          · <AnimatedNumber value={entries.length} />
        </span>
      </button>

      <div
        className={`grid transition-[grid-template-rows] duration-200 ease-out ${
          open ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'
        }`}
      >
        <div className="overflow-hidden min-h-0">
          <div className="flex flex-col gap-1.5 pt-2 pb-0.5">
            <p className="px-1 text-[11px] text-muted/70">
              {t('hidden_categories_hint')}
            </p>
            {entries.map(({ category, count }) => (
              <div
                key={category.id}
                className="flex items-center gap-2 px-2.5 py-2 rounded-item bg-overlay/60 border border-outline/40"
              >
                <span
                  className="w-2 h-2 rounded-full shrink-0 ring-1 ring-black/10"
                  style={{ backgroundColor: category.color }}
                />
                <span className="flex-1 min-w-0 text-xs text-ink truncate">
                  {category.name}
                </span>
                <span className="text-[11px] tabular-nums text-muted/70 shrink-0">
                  {t('hidden_category_projects', { count })}
                </span>
                <button
                  type="button"
                  onClick={() => onUnhide(category.id)}
                  aria-label={t('unhide_category_aria', { name: category.name })}
                  className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-2.5 py-1 rounded-btn border border-line text-[11px] text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
                >
                  <IconEye className="w-3 h-3" />
                  {t('unhide')}
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
