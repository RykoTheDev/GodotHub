import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { api } from '../../../lib/api'
import { useTauriEvent } from '../../../lib/useTauriEvent'
import { formatDuration } from '../../lib/duration'
import { IconPlay, IconTerminal, IconX } from '../../lib/icons'

const TIMER_START_DELAY_MS = 3000

interface RunningProject {
  id: string
  name: string
  version: string
  startedAt: number
}

export function RunningProjectsChip() {
  const { t } = useTranslation('common')
  const [running, setRunning] = useState<RunningProject[]>([])
  const [open, setOpen] = useState(false)
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (running.length === 0) return
    const id = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [running.length])
  const [openUp, setOpenUp] = useState(false)
  const [openLeft, setOpenLeft] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  useTauriEvent<RunningProject>('project:launched', (p) => {
    setRunning((prev) =>
      prev.some((x) => x.id === p.id)
        ? prev
        : [...prev, { ...p, startedAt: Date.now() + TIMER_START_DELAY_MS }],
    )
  })

  useTauriEvent<{ id: string }>('project:exited', ({ id }) => {
    setRunning((prev) => prev.filter((x) => x.id !== id))
  })

  const measure = useCallback(() => {
    const el = ref.current
    if (!el) return
    const r = el.getBoundingClientRect()
    const mh = menuRef.current?.offsetHeight ?? 220
    const spaceBelow = window.innerHeight - r.bottom
    const spaceAbove = r.top
    setOpenUp(spaceBelow < mh && spaceAbove > spaceBelow)

    const mw = menuRef.current?.offsetWidth ?? 288
    const spaceRight = window.innerWidth - r.left
    const spaceLeft = r.right
    setOpenLeft(spaceRight < mw && spaceLeft > spaceRight)
  }, [])

  useLayoutEffect(() => {
    if (open) measure()
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    window.addEventListener('scroll', measure, true)
    window.addEventListener('resize', measure)
    return () => {
      window.removeEventListener('scroll', measure, true)
      window.removeEventListener('resize', measure)
    }
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    const onDown = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    window.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDown)
      window.removeEventListener('keydown', onKey)
    }
  }, [open])

  useEffect(() => {
    if (!open) return
    const first = menuRef.current?.querySelector<HTMLButtonElement>(
      'button[role="menuitem"]:not(:disabled)',
    )
    first?.focus()
  }, [open])

  const handleMenuKey = (e: React.KeyboardEvent<HTMLDivElement>) => {
    const items = Array.from(
      menuRef.current?.querySelectorAll<HTMLButtonElement>(
        'button[role="menuitem"]',
      ) ?? [],
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

  const stop = (id: string) => {
    api.stopProject(id).catch((e) => alert(String(e)))
  }

  const noDrag = (e: React.MouseEvent) => e.stopPropagation()

  return (
    <div ref={ref} className="relative shrink-0">
      <AnimatePresence>
        {running.length > 0 && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ type: 'spring', stiffness: 500, damping: 28 }}
            onMouseDown={noDrag}
            className="relative"
          >
            <motion.button
                type="button"
                onClick={() => setOpen((o) => !o)}
                aria-label={t('running')}
                aria-haspopup="menu"
                aria-expanded={open}
                whileHover={{ scale: 1.04 }}
                whileTap={{ scale: 0.94 }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:border-accent-dim transition-colors"
              >
                <span className="relative flex w-2 h-2">
                  <span className="absolute inline-flex h-full w-full rounded-full bg-mint opacity-60 animate-ping" />
                  <span className="relative inline-flex rounded-full w-2 h-2 bg-mint" />
                </span>
                <IconPlay className="w-3 h-3 text-mint" />
                <span className="text-[13px] font-semibold tabular-nums">
                  {running.length}
                </span>
              </motion.button>

            <AnimatePresence>
              {open && (
                <motion.div
                  ref={menuRef}
                  initial={{ opacity: 0, y: openUp ? 6 : -6, scale: 0.96 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: openUp ? 6 : -6, scale: 0.96 }}
                  transition={{ duration: 0.15, ease: 'easeOut' }}
                  onMouseDown={noDrag}
                  role="menu"
                  onKeyDown={handleMenuKey}
                  className={`absolute z-50 w-72 rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-1.5 ${
                    openUp
                      ? 'bottom-full mb-2 origin-bottom'
                      : `top-full mt-2 ${openLeft ? 'origin-top-right' : 'origin-top-left'}`
                  } ${openLeft ? 'right-0' : 'left-0'}`}
                >
                  <div className="px-2.5 py-2 border-b border-outline/50 mb-1">
                    <h3 className="text-xs font-semibold text-muted uppercase tracking-wide">
                      {t('running')}
                    </h3>
                    <p className="text-[10px] text-muted/50 mt-0.5">
                      {t('running_projects_desc', { count: running.length })}
                    </p>
                  </div>
                  <div className="flex flex-col max-h-[min(60vh,26rem)] overflow-y-auto">
                    <AnimatePresence mode="popLayout">
                      {running.map((p) => (
                        <motion.div
                          key={p.id}
                          layout
                          initial={{ opacity: 0, y: -6 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -6 }}
                          transition={{ duration: 0.15, ease: 'easeOut' }}
                          className="flex items-center gap-1 px-2.5 py-2 rounded-item text-muted transition-colors hover:bg-raised"
                        >
                          <span className="w-7 h-7 rounded-btn flex items-center justify-center shrink-0 bg-mint/10">
                            <IconTerminal className="w-3.5 h-3.5 text-mint" />
                          </span>
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-medium text-ink truncate">
                              {p.name}
                            </p>
                            <p className="text-[10px] text-muted/60 font-mono truncate">
                              {p.version ? `Godot ${p.version} · ` : ''}
                              {formatDuration(now - p.startedAt)}
                            </p>
                          </div>
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => stop(p.id)}
                              aria-label={`${t('stop')} ${p.name}`}
                              className="focus-ring cursor-pointer w-6 h-6 rounded-btn inline-flex items-center justify-center text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
                            >
                              <IconX className="w-3.5 h-3.5" />
                            </button>
                        </motion.div>
                      ))}
                    </AnimatePresence>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
