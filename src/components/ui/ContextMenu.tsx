import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type KeyboardEvent,
} from 'react'
import { createPortal } from 'react-dom'
import { motion } from 'framer-motion'
import {
  MenuButton,
  MenuDivider,
  menuSurfaceClass,
  MENU_VIEWPORT_PAD,
  type MenuItem,
} from './menu'

const FALLBACK_HEIGHT = 160
const FALLBACK_WIDTH = 240

/**
 * A right-click menu built from the same rows, surface and motion as
 * `Dropdown`, including the flip-into-view positioning, so it never feels like
 * a different kind of menu. Render it inside an `<AnimatePresence>` to get the
 * exit animation.
 */
export function ContextMenu({
  items,
  x,
  y,
  onClose,
  compact = false,
  label,
}: {
  items: MenuItem[]
  /** Viewport coordinates of the click that opened the menu. */
  x: number
  y: number
  onClose: () => void
  compact?: boolean
  label?: string
}) {
  const menuRef = useRef<HTMLDivElement>(null)
  const [pos, setPos] = useState<{ left: number; top: number } | null>(null)
  const [flipped, setFlipped] = useState(false)

  const measure = useCallback(() => {
    const height = menuRef.current?.offsetHeight ?? FALLBACK_HEIGHT
    const width = menuRef.current?.offsetWidth ?? FALLBACK_WIDTH

    const spaceBelow = window.innerHeight - y
    const spaceRight = window.innerWidth - x
    const up = spaceBelow < height + MENU_VIEWPORT_PAD && y > spaceBelow
    const leftwards = spaceRight < width + MENU_VIEWPORT_PAD && x > spaceRight

    const left = Math.max(
      MENU_VIEWPORT_PAD,
      Math.min(
        leftwards ? x - width : x,
        window.innerWidth - width - MENU_VIEWPORT_PAD,
      ),
    )
    const top = Math.max(
      MENU_VIEWPORT_PAD,
      Math.min(
        up ? y - height : y,
        window.innerHeight - height - MENU_VIEWPORT_PAD,
      ),
    )

    setFlipped(up)
    setPos({ left, top })
  }, [x, y])

  useLayoutEffect(() => {
    measure()
  }, [measure])

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dropdown-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dropdown-close'))
    }
  }, [])

  useEffect(() => {
    const onScroll = () => onClose()
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    const onDown = (e: globalThis.MouseEvent) => {
      if (e.button === 2) return
      if (!menuRef.current?.contains(e.target as Node)) onClose()
    }
    const onContext = (e: globalThis.MouseEvent) => {
      if (e.defaultPrevented) return
      if (!menuRef.current?.contains(e.target as Node)) onClose()
    }
    const onBlur = () => onClose()

    window.addEventListener('scroll', onScroll, true)
    window.addEventListener('resize', onScroll)
    window.addEventListener('blur', onBlur)
    window.addEventListener('keydown', onKey)
    document.addEventListener('mousedown', onDown)
    document.addEventListener('contextmenu', onContext)
    return () => {
      window.removeEventListener('scroll', onScroll, true)
      window.removeEventListener('resize', onScroll)
      window.removeEventListener('blur', onBlur)
      window.removeEventListener('keydown', onKey)
      document.removeEventListener('mousedown', onDown)
      document.removeEventListener('contextmenu', onContext)
    }
  }, [onClose])

  useEffect(() => {
    menuRef.current
      ?.querySelector<HTMLButtonElement>('button[role="menuitem"]:not(:disabled)')
      ?.focus()
  }, [])

  const handleMenuKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const entries = Array.from(
      menuRef.current?.querySelectorAll<HTMLButtonElement>(
        'button[role="menuitem"]',
      ) ?? [],
    ).filter((b) => !b.disabled)
    if (entries.length === 0) return
    const index = entries.indexOf(document.activeElement as HTMLButtonElement)
    let next = index
    if (e.key === 'ArrowDown') next = (index + 1) % entries.length
    else if (e.key === 'ArrowUp') next = (index - 1 + entries.length) % entries.length
    else if (e.key === 'Home') next = 0
    else if (e.key === 'End') next = entries.length - 1
    else return
    e.preventDefault()
    entries[next]?.focus()
  }

  return createPortal(
    <motion.div
      ref={menuRef}
      initial={{ opacity: 0, y: flipped ? 6 : -6, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: flipped ? 6 : -6, scale: 0.96 }}
      transition={{ duration: 0.15, ease: 'easeOut' }}
      role="menu"
      aria-label={label}
      onKeyDown={handleMenuKey}
      onContextMenu={(e) => e.preventDefault()}
      style={{ left: pos?.left, top: pos?.top }}
      className={`fixed z-50 ${menuSurfaceClass(compact)} ${
        flipped ? 'origin-bottom' : 'origin-top'
      }`}
    >
      {items.map((item) => (
        <div key={item.key}>
          <MenuButton
            item={item}
            compact={compact}
            onSelect={() => {
              onClose()
              item.onClick?.()
            }}
            caret={Boolean(item.children?.length)}
          />
          {item.dividerAfter && <MenuDivider compact={compact} />}
        </div>
      ))}
    </motion.div>,
    document.body,
  )
}
