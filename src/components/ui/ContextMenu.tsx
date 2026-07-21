import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { IconChevronRight } from '../Icons'

export interface ContextMenuAction {
  label: string
  icon?: React.ComponentType<{ className?: string }>
  onClick: () => void
  variant?: 'default' | 'danger'
  disabled?: boolean
  shortcut?: string
}

export interface ContextMenuSub {
  label: string
  icon?: React.ComponentType<{ className?: string }>
  children: ContextMenuSection[]
}

export type ContextMenuSection =
  | ContextMenuAction
  | { type: 'separator' }
  | ContextMenuSub

interface ContextMenuProps {
  items: ContextMenuSection[]
  position: { x: number; y: number }
  onClose: () => void
}

function isSub(item: ContextMenuSection): item is ContextMenuSub {
  return 'children' in item && !('onClick' in item)
}

function isAction(item: ContextMenuSection): item is ContextMenuAction {
  return 'onClick' in item
}

function FloatingSubMenu({
  items,
  anchorRect,
  onClose,
}: {
  items: ContextMenuSection[]
  anchorRect: DOMRect
  onClose: () => void
}) {
  const menuRef = useRef<HTMLDivElement>(null)
  const [openSub, setOpenSub] = useState<string | null>(null)
  const closeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    if (!menuRef.current) return
    const rect = menuRef.current.getBoundingClientRect()
    let left = anchorRect.right + 4
    let top = anchorRect.top - 4

    const PAD = 8
    if (left + rect.width > window.innerWidth - PAD) {
      left = anchorRect.left - rect.width - 4
    }
    if (top + rect.height > window.innerHeight - PAD) {
      top = window.innerHeight - rect.height - PAD
    }
    if (top < PAD) top = PAD

    menuRef.current.style.left = `${left}px`
    menuRef.current.style.top = `${top}px`
  }, [anchorRect])

  const handleItemEnter = (label: string) => {
    if (closeTimerRef.current) clearTimeout(closeTimerRef.current)
    setOpenSub(label)
  }

  const handleItemLeave = () => {
    closeTimerRef.current = setTimeout(() => setOpenSub(null), 150)
  }

  return (
    <motion.div
      ref={menuRef}
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.96 }}
      transition={{ duration: 0.1, ease: 'easeOut' }}
      className="fixed min-w-44 rounded-xl border border-line bg-surface shadow-2xl shadow-black/50 py-1.5 z-60"
      onMouseEnter={() => {
        if (closeTimerRef.current) clearTimeout(closeTimerRef.current)
      }}
      onMouseLeave={() => setOpenSub(null)}
    >
      {items.map((item, i) => {
        if ('type' in item && item.type === 'separator') {
          return <div key={`sep-${i}`} className="mx-2 my-1 h-px bg-line" />
        }
        if (isSub(item)) {
          const SubIcon = item.icon
          const isOpen = openSub === item.label
          return (
            <div
              key={item.label}
              onMouseEnter={() => handleItemEnter(item.label)}
              onMouseLeave={handleItemLeave}
            >
              <div
                className={`focus-ring cursor-pointer w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium transition-colors ${
                  isOpen ? 'bg-raised text-ink' : 'text-ink hover:bg-raised'
                }`}
              >
                {SubIcon && (
                  <span className="w-4 h-4 shrink-0 flex items-center justify-center text-muted">
                    <SubIcon className="w-3.5 h-3.5" />
                  </span>
                )}
                <span className="flex-1 text-left">{item.label}</span>
                <IconChevronRight className="w-3 h-3 text-muted/60 shrink-0" />
              </div>
              <AnimatePresence>
                {isOpen && (
                  <div onMouseEnter={() => { if (closeTimerRef.current) clearTimeout(closeTimerRef.current); setOpenSub(item.label) }}>
                    <FloatingSubMenu
                      items={item.children}
                      anchorRect={menuRef.current?.getBoundingClientRect() ?? anchorRect}
                      onClose={onClose}
                    />
                  </div>
                )}
              </AnimatePresence>
            </div>
          )
        }
        if (isAction(item)) {
          const action = item
          const Icon = action.icon
          return (
            <button
              key={action.label}
              type="button"
              disabled={action.disabled}
              onClick={() => { action.onClick(); onClose() }}
              className={`focus-ring cursor-pointer w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium transition-colors ${
                action.disabled
                  ? 'text-muted/40 cursor-not-allowed'
                  : action.variant === 'danger'
                    ? 'text-danger hover:bg-danger/10'
                    : 'text-ink hover:bg-raised'
              }`}
            >
              {Icon && (
                <span className={`w-4 h-4 shrink-0 flex items-center justify-center ${action.variant === 'danger' ? 'text-danger' : 'text-muted'}`}>
                  <Icon className="w-3.5 h-3.5" />
                </span>
              )}
              <span className="flex-1 text-left">{action.label}</span>
              {action.shortcut && (
                <span className="text-[10px] text-muted/60 font-mono ml-4">{action.shortcut}</span>
              )}
            </button>
          )
        }
        return null
      })}
    </motion.div>
  )
}

export function ContextMenu({ items, position, onClose }: ContextMenuProps) {
  const menuRef = useRef<HTMLDivElement>(null)
  const [openSub, setOpenSub] = useState<string | null>(null)
  const [itemRects, setItemRects] = useState<Map<string, DOMRect>>(new Map())
  const closeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    const clickHandler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        onClose()
      }
    }
    const keyHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    const raf = requestAnimationFrame(() => {
      document.addEventListener('mousedown', clickHandler)
      document.addEventListener('keydown', keyHandler)
    })
    return () => {
      cancelAnimationFrame(raf)
      document.removeEventListener('mousedown', clickHandler)
      document.removeEventListener('keydown', keyHandler)
    }
  }, [onClose])

  const handleItemEnter = (label: string, e: React.MouseEvent) => {
    if (closeTimerRef.current) clearTimeout(closeTimerRef.current)
    const el = (e.currentTarget.closest('[data-menu-item]') || e.currentTarget) as HTMLElement
    const rect = el.getBoundingClientRect()
    setItemRects((prev) => {
      const next = new Map(prev)
      next.set(label, rect)
      return next
    })
    setOpenSub(label)
  }

  const handleItemLeave = () => {
    closeTimerRef.current = setTimeout(() => setOpenSub(null), 150)
  }

  const [adjustedPos, setAdjustedPos] = useState(position)

  useLayoutEffect(() => {
    if (!menuRef.current) return
    const rect = menuRef.current.getBoundingClientRect()
    let cx = position.x
    let cy = position.y
    const PAD = 16
    const overflowX = cx + rect.width - window.innerWidth + PAD
    const overflowY = cy + rect.height - window.innerHeight + PAD
    if (overflowX > 0) cx = Math.max(PAD, position.x - rect.width)
    if (overflowY > 0) cy = Math.max(PAD, position.y - rect.height)
    setAdjustedPos({ x: cx, y: cy })
  }, [position])

  return (
    <div className="fixed inset-0 z-50 pointer-events-none">
      <div
        ref={menuRef}
        className="pointer-events-auto absolute min-w-44 rounded-xl border border-line bg-surface shadow-2xl shadow-black/50 py-1.5 origin-top"
        style={{ left: adjustedPos.x, top: adjustedPos.y }}
      >
        {items.map((item, i) => {
          if ('type' in item && item.type === 'separator') {
            return <div key={`sep-${i}`} className="mx-2 my-1 h-px bg-line" />
          }
          if (isSub(item)) {
            const SubIcon = item.icon
            const isOpen = openSub === item.label
            return (
              <div
                key={item.label}
                data-menu-item
                onMouseEnter={(e) => handleItemEnter(item.label, e)}
                onMouseLeave={handleItemLeave}
              >
                <div
                  className={`focus-ring cursor-pointer w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium transition-colors ${
                    isOpen ? 'bg-raised text-ink' : 'text-ink hover:bg-raised'
                  }`}
                >
                  {SubIcon && (
                    <span className="w-4 h-4 shrink-0 flex items-center justify-center text-muted">
                      <SubIcon className="w-3.5 h-3.5" />
                    </span>
                  )}
                  <span className="flex-1 text-left">{item.label}</span>
                  <IconChevronRight className="w-3 h-3 text-muted/60 shrink-0" />
                </div>
                <AnimatePresence>
                  {isOpen && itemRects.has(item.label) && (
                    <div key={item.label}
                      onMouseEnter={() => {
                        if (closeTimerRef.current) clearTimeout(closeTimerRef.current)
                        setOpenSub(item.label)
                      }}
                    >
                      <FloatingSubMenu
                        items={item.children}
                        anchorRect={itemRects.get(item.label)!}
                        onClose={onClose}
                      />
                    </div>
                  )}
                </AnimatePresence>
              </div>
            )
          }
          if (isAction(item)) {
            const action = item
            const Icon = action.icon
            return (
              <button
                key={action.label}
                type="button"
                disabled={action.disabled}
                onClick={() => { action.onClick(); onClose() }}
                className={`focus-ring cursor-pointer w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium transition-colors ${
                  action.disabled
                    ? 'text-muted/40 cursor-not-allowed'
                    : action.variant === 'danger'
                      ? 'text-danger hover:bg-danger/10'
                      : 'text-ink hover:bg-raised'
                }`}
              >
                {Icon && (
                  <span className={`w-4 h-4 shrink-0 flex items-center justify-center ${action.variant === 'danger' ? 'text-danger' : 'text-muted'}`}>
                    <Icon className="w-3.5 h-3.5" />
                  </span>
                )}
                <span className="flex-1 text-left">{action.label}</span>
                {action.shortcut && (
                  <span className="text-[10px] text-muted/60 font-mono ml-4">{action.shortcut}</span>
                )}
              </button>
            )
          }
          return null
        })}
      </div>
    </div>
  )
}
