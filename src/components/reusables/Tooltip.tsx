import { useRef, useState, useCallback, useEffect, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { useSettings } from '../../hooks/useSettings'

interface TooltipProps {
  content: ReactNode
  children: ReactNode
  side?: 'top' | 'bottom' | 'left' | 'right'
  className?: string
  maxWidth?: number
  delay?: number
}

const VIEWPORT_PAD = 12
const GAP = 8

export function Tooltip({
  content,
  children,
  side: sideProp,
  className,
  maxWidth = 280,
  delay: delayProp,
}: TooltipProps) {
  const { settings } = useSettings()
  const delay = delayProp ?? settings.tooltip_delay ?? 350

  const [open, setOpen] = useState(false)
  const [pos, setPos] = useState({ x: 0, y: 0 })
  const [arrow, setArrow] = useState<'top' | 'bottom' | 'left' | 'right'>('bottom')

  const triggerRef = useRef<HTMLDivElement>(null)
  const tipRef = useRef<HTMLDivElement>(null)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const positioned = useRef(false)

  /* ---- positioning logic ---- */

  const calc = useCallback(
    (tr: DOMRect, tw: number, th: number) => {
      const space = {
        top: tr.top - VIEWPORT_PAD - GAP,
        bottom: window.innerHeight - tr.bottom - VIEWPORT_PAD - GAP,
        left: tr.left - VIEWPORT_PAD - GAP,
        right: window.innerWidth - tr.right - VIEWPORT_PAD - GAP,
      }

      const pick = (): 'top' | 'bottom' | 'left' | 'right' => {
        if (sideProp) return sideProp

        const ranked = (
          ['bottom', 'top', 'right', 'left'] as const
        )
          .map((s) => ({ s, space: space[s] }))
          .filter((c) => c.space >= (c.s === 'top' || c.s === 'bottom' ? th : tw) + GAP)
          .sort((a, b) => b.space - a.space)

        if (ranked.length) return ranked[0].s

        return (
          Object.entries(space) as [keyof typeof space, number][]
        ).sort((a, b) => b[1] - a[1])[0][0] as 'top' | 'bottom' | 'left' | 'right'
      }

      const side = pick()

      let x: number
      let y: number

      if (side === 'bottom') {
        x = tr.left + tr.width / 2 - tw / 2
        y = tr.bottom + GAP
      } else if (side === 'top') {
        x = tr.left + tr.width / 2 - tw / 2
        y = tr.top - th - GAP
      } else if (side === 'right') {
        x = tr.right + GAP
        y = tr.top + tr.height / 2 - th / 2
      } else {
        x = tr.left - tw - GAP
        y = tr.top + tr.height / 2 - th / 2
      }

      const maxX = window.innerWidth - tw - VIEWPORT_PAD
      const maxY = window.innerHeight - th - VIEWPORT_PAD
      x = Math.max(VIEWPORT_PAD, Math.min(x, maxX))
      y = Math.max(VIEWPORT_PAD, Math.min(y, maxY))

      return { x, y, side }
    },
    [sideProp],
  )

  const getTriggerRect = useCallback(() => {
    const el = triggerRef.current
    if (!el) return null
    if (el.childElementCount === 1 && el.firstElementChild) {
      return el.firstElementChild.getBoundingClientRect()
    }
    return el.getBoundingClientRect()
  }, [])

  /* ---- hover handlers ---- */

  const show = useCallback(() => {
    timer.current = setTimeout(() => {
      const tr = getTriggerRect()
      if (!tr) return
      positioned.current = false
      setPos({ x: -9999, y: -9999 })
      setOpen(true)

      requestAnimationFrame(() => {
        if (!tipRef.current) return
        const tw = tipRef.current.offsetWidth
        const th = tipRef.current.offsetHeight
        const r = calc(tr, tw, th)
        setPos({ x: r.x, y: r.y })
        setArrow(r.side)
        positioned.current = true
      })
    }, delay)
  }, [getTriggerRect, calc, delay])

  const hide = useCallback(() => {
    if (timer.current) clearTimeout(timer.current)
    setOpen(false)
    positioned.current = false
  }, [])

  /* reposition on scroll / resize while open */
  useEffect(() => {
    if (!open) return
    const reposition = () => {
      if (!tipRef.current || !positioned.current) return
      const tr = getTriggerRect()
      if (!tr) return
      const tw = tipRef.current.offsetWidth
      const th = tipRef.current.offsetHeight
      const r = calc(tr, tw, th)
      setPos({ x: r.x, y: r.y })
      setArrow(r.side)
    }
    window.addEventListener('scroll', reposition, true)
    window.addEventListener('resize', reposition)
    return () => {
      window.removeEventListener('scroll', reposition, true)
      window.removeEventListener('resize', reposition)
    }
  }, [open, getTriggerRect, calc])

  /* cleanup on unmount */
  useEffect(() => {
    return () => {
      if (timer.current) clearTimeout(timer.current)
    }
  }, [])

  /* ---- arrow style ---- */

  const arrowStyle = (side: string): React.CSSProperties => {
    const base: React.CSSProperties = {
      position: 'absolute',
      width: 8,
      height: 8,
      background: 'var(--color-raised)',
      transform: 'rotate(45deg)',
      zIndex: -1,
    }
    if (side === 'top') {
      base.bottom = -4
      base.left = '50%'
      base.marginLeft = -4
    } else if (side === 'bottom') {
      base.top = -4
      base.left = '50%'
      base.marginLeft = -4
    } else if (side === 'left') {
      base.right = -4
      base.top = '50%'
      base.marginTop = -4
    } else {
      base.left = -4
      base.top = '50%'
      base.marginTop = -4
    }
    return base
  }

  /* ---- animation offsets ---- */

  const enterFrom = () => {
    const d = 6
    switch (arrow) {
      case 'top':
        return { y: d }
      case 'bottom':
        return { y: -d }
      case 'left':
        return { x: d }
      case 'right':
        return { x: -d }
    }
  }

  const exitTo = () => {
    const d = 4
    switch (arrow) {
      case 'top':
        return { y: d }
      case 'bottom':
        return { y: -d }
      case 'left':
        return { x: d }
      case 'right':
        return { x: -d }
    }
  }

  const effectiveMax = Math.min(maxWidth, window.innerWidth - VIEWPORT_PAD * 2)

  return (
    <div
      ref={triggerRef}
      onMouseEnter={show}
      onMouseLeave={hide}
      onFocus={show}
      onBlur={hide}
      className={className}
      style={{ display: 'inline-flex' }}
    >
      {children}

      {createPortal(
        <AnimatePresence>
          {open && (
            <motion.div key="div-237"
              ref={tipRef}
              initial={{ opacity: 0, scale: 0.92, ...enterFrom() }}
              animate={{ opacity: 1, scale: 1, x: 0, y: 0 }}
              exit={{ opacity: 0, scale: 0.92, ...exitTo() }}
              transition={{ type: 'spring', stiffness: 480, damping: 26, mass: 0.7 }}
              className="fixed z-9999 pointer-events-none"
              style={{ left: pos.x, top: pos.y }}
            >
              {/* arrow */}
              <div style={arrowStyle(arrow)} />

              {/* bubble */}
              <div
                className="relative px-3 py-1.5 rounded-tag bg-raised border border-line text-[11px] text-muted font-medium leading-snug shadow-md shadow-base"
                style={{
                  maxWidth: effectiveMax,
                  wordBreak: 'break-word',
                  overflowWrap: 'break-word',
                }}
              >
                {content}
              </div>
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </div>
  )
}
