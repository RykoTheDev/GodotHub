import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import i18n from '../../../i18n'
import {
  LANGUAGES,
  languageStatusLabelKey,
  type LanguageStatus,
} from '../../../i18n/languages'
import { IconLanguage, IconCheck } from '../../lib/icons'
import { useSettings } from '../../../hooks/useSettings'
import { LanguageFlag } from '../reusables/LanguageFlag'
import { Tooltip } from '../reusables/Tooltip'

const STATUS_BADGE_CLASS: Record<LanguageStatus, string> = {
  complete: 'bg-mint/10 text-mint border-mint/30',
  beta: 'bg-amber/10 text-amber border-amber/30',
  incomplete: 'bg-black/15 text-muted border-outline/40',
}

const GAP = 8
const EDGE_PADDING = 8
const MENU_WIDTH = 240
const OPEN_UP_THRESHOLD = 220

export function LanguageMenu() {
  const { t: ts } = useTranslation('settings')
  const { settings, update } = useSettings()

  const badge = (status: LanguageStatus) => (
    <span
      className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-tag border shrink-0 ${STATUS_BADGE_CLASS[status]}`}
    >
      {ts(languageStatusLabelKey(status))}
    </span>
  )
  const [open, setOpen] = useState(false)
  const [dir, setDir] = useState(false)
  const [pos, setPos] = useState<{ left: number; top: number } | null>(null)
  const ref = useRef<HTMLDivElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        if (listRef.current?.contains(e.target as Node)) return
        setOpen(false)
      }
    }
    const keyHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    document.addEventListener('keydown', keyHandler)
    return () => {
      document.removeEventListener('mousedown', handler)
      document.removeEventListener('keydown', keyHandler)
    }
  }, [])

  const measure = useCallback(() => {
    const el = ref.current
    if (!el || !listRef.current) return
    const r = el.getBoundingClientRect()
    const spaceBelow = window.innerHeight - r.bottom
    const d = spaceBelow < OPEN_UP_THRESHOLD
    const h = listRef.current.offsetHeight
    setDir(d)
    setPos({
      left: Math.max(EDGE_PADDING, r.right - MENU_WIDTH),
      top: Math.max(EDGE_PADDING, d ? r.top - h - GAP : r.bottom + GAP),
    })
  }, [])

  useLayoutEffect(() => {
    if (open) measure()
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    const reposition = () => measure()
    window.addEventListener('scroll', reposition, true)
    window.addEventListener('resize', reposition)
    return () => {
      window.removeEventListener('scroll', reposition, true)
      window.removeEventListener('resize', reposition)
    }
  }, [open, measure])

  const isActive = (value: string) =>
    i18n.language === value || i18n.language.startsWith(value.split('-')[0])

  const select = (value: string) => {
    i18n.changeLanguage(value)
    update({ ...settings, language: value })
    setOpen(false)
  }

  const noDrag = (e: React.MouseEvent) => e.stopPropagation()

  return (
    <>
      <div ref={ref} className="flex items-stretch shrink-0">
        <Tooltip content={ts('language_label')}>
        <motion.button
            type="button"
            onClick={() => setOpen((o) => !o)}
            onMouseDown={noDrag}
            aria-label={ts('language_label')}
            aria-expanded={open}
            aria-haspopup="menu"
            whileHover={{ scale: 1.08 }}
            whileTap={{ scale: 0.9 }}
            transition={{ type: 'spring', stiffness: 500, damping: 30 }}
            className="focus-ring cursor-pointer relative w-9 h-8 flex items-center justify-center rounded-item text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
          >
            <IconLanguage className="w-4 h-4" />
          </motion.button>
        </Tooltip>
      </div>

      {createPortal(
        <AnimatePresence>
          {open && (
            <motion.div
              ref={listRef}
              initial={{ opacity: 0, y: dir ? 6 : -6, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: dir ? 6 : -6, scale: 0.96 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              role="menu"
              className={`fixed z-50 ${
                dir ? 'origin-bottom' : 'origin-top'
              } rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-1.5`}
              style={{ left: pos?.left, top: pos?.top, width: MENU_WIDTH }}
            >
              <div className="px-2.5 pt-1.5 pb-1 text-[10px] font-semibold uppercase tracking-wider text-muted/50">
                {ts('language_label')}
              </div>
              {LANGUAGES.map((lang) => {
                const active = isActive(lang.value)
                return (
                  <button
                    key={lang.value}
                    type="button"
                    role="menuitem"
                    onClick={() => select(lang.value)}
                    className={`focus-ring cursor-pointer w-full flex items-center justify-between gap-2 text-left px-2.5 py-2 rounded-item text-xs transition-colors ${
                      active
                        ? 'bg-accent/15 text-accent-bright'
                        : 'text-muted hover:bg-raised hover:text-ink'
                    }`}
                  >
                    <span className="flex items-center gap-1.5 min-w-0">
                      <LanguageFlag country={lang.country} />
                      <span className="truncate">{lang.label}</span>
                      {badge(lang.status)}
                    </span>
                    {active && <IconCheck className="w-3.5 h-3.5" />}
                  </button>
                )
              })}
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </>
  )
}
