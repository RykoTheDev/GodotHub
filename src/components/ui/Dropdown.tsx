import { AnimatePresence, motion } from 'framer-motion'
import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type ComponentType,
  type MouseEvent as ReactMouseEvent,
  type KeyboardEvent,
  type ReactNode,
} from 'react'
import { createPortal } from 'react-dom'
import type { IconProps } from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'
import {
  MenuButton,
  MenuDivider,
  menuSurfaceClass,
  MENU_GAP,
  MENU_VIEWPORT_PAD,
  type MenuItem,
} from './menu'

export type NewDropdownItem = MenuItem

export interface NewDropdownHeaderItem {
  key: string
  icon: ComponentType<IconProps>
  label: string
  tooltip?: string
  onClick: () => void
}

interface NewDropdownProps {
  trigger: (props: { open: boolean; toggle: () => void }) => ReactNode
  items?: NewDropdownItem[]
  header?: NewDropdownHeaderItem[]
  align?: 'left' | 'right'
  side?: 'top' | 'bottom' | 'left'
  menuClassName?: string
  activeItemClassName?: string
  compact?: boolean
  children?: ReactNode
  onOpenChange?: (open: boolean) => void
}

const MENU_FALLBACK_HEIGHT = 220

const MENU_FALLBACK_WIDTH = 240

const SUBMENU_FALLBACK_HEIGHT = 260

const VIEWPORT_PAD = MENU_VIEWPORT_PAD

const SUBMENU_FALLBACK_WIDTH = 220

const GAP = MENU_GAP

export function Dropdown({
  trigger,
  items = [],
  header,
  align = 'right',
  side = 'bottom',
  menuClassName = '',
  activeItemClassName = 'text-ink bg-accent hover:bg-accent',
  compact = false,
  children,
  onOpenChange,
}: NewDropdownProps) {
  const [open, setOpen] = useState(false)
  const [openUp, setOpenUp] = useState(false)
  const [openSubmenuKey, setOpenSubmenuKey] = useState<string | null>(null)
  const [submenuSide, setSubmenuSide] = useState<'left' | 'right'>('right')
  const [submenuOffsetY, setSubmenuOffsetY] = useState(0)
  const [pos, setPos] = useState<{
    left: number
    top: number
    width: number
  } | null>(null)
  const ref = useRef<HTMLDivElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)
  const itemRefs = useRef<Record<string, HTMLDivElement | null>>({})

  const toggle = useCallback(() => setOpen((v) => {
    const next = !v
    onOpenChange?.(next)
    return next
  }), [onOpenChange])

  const closeAll = useCallback(() => {
    setOpen(false)
    setOpenSubmenuKey(null)
    onOpenChange?.(false)
  }, [onOpenChange])

  useEffect(() => {
    if (!open) return
    window.dispatchEvent(new CustomEvent('app:dropdown-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dropdown-close'))
    }
  }, [open])

  const measure = useCallback(() => {
    const el = ref.current
    if (!el) return
    const r = el.getBoundingClientRect()
    const mh = menuRef.current?.offsetHeight ?? MENU_FALLBACK_HEIGHT
    const mw = menuRef.current?.offsetWidth ?? MENU_FALLBACK_WIDTH

    if (side === 'left') {
      setOpenUp(false)
      let left = r.left - mw - GAP
      if (left < VIEWPORT_PAD) left = r.right + GAP
      let top = r.top
      if (top + mh > window.innerHeight - VIEWPORT_PAD) {
        top = window.innerHeight - mh - VIEWPORT_PAD
      }
      if (top < VIEWPORT_PAD) top = VIEWPORT_PAD
      setPos({ left, top, width: mw })
      return
    }

    const spaceBelow = window.innerHeight - r.bottom
    const spaceAbove = r.top
    const up = side === 'top' || (spaceBelow < mh && spaceAbove > spaceBelow)
    setOpenUp(up)

    const spaceLeft = r.right
    const spaceRight = window.innerWidth - r.left
    const leftSide =
      align === 'right'
        ? !(spaceLeft < mw && spaceRight > spaceLeft)
        : spaceRight < mw && spaceLeft > spaceRight

    let left = leftSide ? r.right - mw : r.left
    left = Math.max(VIEWPORT_PAD, Math.min(left, window.innerWidth - mw - VIEWPORT_PAD))

    let top = up ? r.top - mh - GAP : r.bottom + GAP
    if (up) {
      if (top < VIEWPORT_PAD) top = VIEWPORT_PAD
    } else {
      if (top + mh > window.innerHeight - VIEWPORT_PAD) {
        top = window.innerHeight - mh - VIEWPORT_PAD
      }
    }

    setPos({ left, top, width: mw })
  }, [align, side])

  const measureSubmenu = useCallback((itemKey: string) => {
    const itemEl = itemRefs.current[itemKey]
    if (!itemEl) return

    const r = itemEl.getBoundingClientRect()
    const spaceRight = window.innerWidth - r.right - GAP
    const spaceLeft = r.left - GAP
    const side: 'left' | 'right' =
      spaceRight < SUBMENU_FALLBACK_WIDTH && spaceLeft > spaceRight
        ? 'left'
        : 'right'

    const minTop = GAP
    const maxTop = window.innerHeight - SUBMENU_FALLBACK_HEIGHT - GAP
    const clampedTop = Math.min(Math.max(r.top, minTop), Math.max(minTop, maxTop))

    setSubmenuSide(side)
    setSubmenuOffsetY(clampedTop - r.top)
  }, [])

  useLayoutEffect(() => {
    if (open) measure()
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    const onScroll = () => closeAll()
    window.addEventListener('scroll', onScroll, true)
    window.addEventListener('resize', onScroll)
    return () => {
      window.removeEventListener('scroll', onScroll, true)
      window.removeEventListener('resize', onScroll)
    }
  }, [open, closeAll])

  useEffect(() => {
    if (!open) {
      setOpenSubmenuKey(null)
      setSubmenuOffsetY(0)
      setSubmenuSide('right')
    }
  }, [open])

  useEffect(() => {
    if (!open || !openSubmenuKey) return
    measureSubmenu(openSubmenuKey)
  }, [open, openSubmenuKey, measureSubmenu])

  useEffect(() => {
    if (!open || !openSubmenuKey) return
    const onReflow = () => measureSubmenu(openSubmenuKey)
    window.addEventListener('scroll', onReflow, true)
    window.addEventListener('resize', onReflow)
    return () => {
      window.removeEventListener('scroll', onReflow, true)
      window.removeEventListener('resize', onReflow)
    }
  }, [open, openSubmenuKey, measureSubmenu])

  useEffect(() => {
    if (!open) return
    const onDown = (e: globalThis.MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        if (menuRef.current?.contains(e.target as Node)) return
        closeAll()
      }
    }
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') closeAll()
    }
    document.addEventListener('mousedown', onDown)
    window.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDown)
      window.removeEventListener('keydown', onKey)
    }
  }, [open, closeAll])

  useEffect(() => {
    if (!open) return
    const first = menuRef.current?.querySelector<HTMLButtonElement>(
      'button[role="menuitem"]:not(:disabled)',
    )
    first?.focus()
  }, [open])

  const handleMenuKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const items = Array.from(
      menuRef.current?.querySelectorAll<HTMLButtonElement>('button[role="menuitem"]') ?? [],
    ).filter((b) => !b.disabled)
    if (items.length === 0) return
    const idx = items.indexOf(document.activeElement as HTMLButtonElement)
    let next = idx
    if (e.key === 'ArrowDown') next = (idx + 1) % items.length
    else if (e.key === 'ArrowUp') next = (idx - 1 + items.length) % items.length
    else if (e.key === 'Home') next = 0
    else if (e.key === 'End') next = items.length - 1
    else return
    e.preventDefault()
    items[next]?.focus()
  }

  const handleItemClick = (
    item: NewDropdownItem,
    e: ReactMouseEvent<HTMLButtonElement>,
  ) => {
    if (item.children?.length) {
      e.preventDefault()
      return
    }
    closeAll()
    item.onClick?.()
  }

  return (
    <>
      <div ref={ref} className="relative flex items-stretch w-fit">
        {trigger({ open, toggle })}
      </div>

      {createPortal(
        <AnimatePresence>
          {open && (
            <motion.div key="div-269"
              ref={menuRef}
              initial={{ opacity: 0, y: openUp ? 6 : -6, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: openUp ? 6 : -6, scale: 0.96 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              role="menu"
              onKeyDown={handleMenuKey}
              style={{ left: pos?.left, top: pos?.top, width: pos?.width }}
              className={`fixed z-50 ${menuSurfaceClass(compact)} ${
                openUp ? 'origin-bottom' : 'origin-top'
              } ${menuClassName}`}
              onMouseLeave={() => setOpenSubmenuKey(null)}
            >
              {header && header.length > 0 && (
                <div className={`flex items-center gap-1 ${compact ? 'p-0.5' : 'p-1'} border-b border-white/6 mb-1`}> 
                  {header.map((h) => (
                    <Tooltip key={h.key} content={h.tooltip ?? h.label} side="top">
                      <button
                        type="button"
                        onClick={() => { closeAll(); h.onClick() }}
                        className="focus-ring cursor-pointer flex items-center justify-center w-8 h-8 rounded-item text-muted hover:text-ink hover:bg-raised transition-colors"
                      >
                        <h.icon className="w-4 h-4" />
                      </button>
                    </Tooltip>
                  ))}
                </div>
              )}
              {children}
              {items.map((item) => (
                <div
                  key={item.key}
                  ref={(el) => {
                    itemRefs.current[item.key] = el
                  }}
                  className="relative"
                  onMouseEnter={() => {
                    if (item.children?.length) {
                      setOpenSubmenuKey(item.key)
                      measureSubmenu(item.key)
                    } else {
                      setOpenSubmenuKey(null)
                    }
                  }}
                >
                  <MenuButton
                    item={item}
                    compact={compact}
                    onSelect={(e) => handleItemClick(item, e)}
                    caret={Boolean(item.children?.length)}
                    activeItemClassName={activeItemClassName}
                  />
                  {item.children?.length && (
                    <AnimatePresence>
                      {openSubmenuKey === item.key && (
                        <div
                          className={`absolute top-0 z-60 ${
                            submenuSide === 'left'
                              ? 'right-full mr-1'
                              : 'left-full ml-1'
                          }`}
                          style={{ transform: `translateY(${submenuOffsetY}px)` }}
                        >
                          <motion.div
                            initial={{
                              opacity: 0,
                              x: submenuSide === 'left' ? 6 : -6,
                              scale: 0.97,
                            }}
                            animate={{ opacity: 1, x: 0, scale: 1 }}
                            exit={{
                              opacity: 0,
                              x: submenuSide === 'left' ? 6 : -6,
                              scale: 0.97,
                            }}
                            transition={{ duration: 0.15, ease: 'easeOut' }}
                            className={`min-w-52 rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/15 p-1 ${
                              submenuSide === 'left'
                                ? 'origin-right'
                                : 'origin-left'
                            }`}
                          >
                            {item.children.map((child) => (
                              <div key={child.key}>
                                <MenuButton
                                  item={child}
                                  compact={compact}
                                  onSelect={() => {
                                    closeAll()
                                    child.onClick?.()
                                  }}
                                  activeItemClassName={activeItemClassName}
                                />
                                {child.dividerAfter && (
                                  <MenuDivider compact={compact} />
                                )}
                              </div>
                            ))}
                          </motion.div>
                        </div>
                      )}
                    </AnimatePresence>
                  )}
                  {item.dividerAfter && (
                    <MenuDivider compact={compact} />
                  )}
                </div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </>
  )
}
