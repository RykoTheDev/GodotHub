import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { IconChevronDown } from '../Icons'

export interface SplitButtonItem {
  label: string
  icon?: React.ComponentType<{ className?: string }>
  badge?: string
  onClick: () => void
}

interface Props {
  label: string
  icon?: React.ComponentType<{ className?: string }>
  onClick: () => void
  items: SplitButtonItem[]
  variant?: 'accent' | 'outline'
  disabled?: boolean
  menuLabel: string
  className?: string
}

const VARIANTS = {
  accent: {
    shell: 'text-white',
    half: 'bg-accent hover:bg-accent-bright font-medium disabled:bg-raised disabled:text-muted',
    seam: 'bg-black/20',
    primary: 'gap-1.5 pl-8 pr-7 py-3',
    caret: 'px-3 py-3',
  },
  outline: {
    shell: 'border border-line text-muted hover:border-mint/50',
    half: 'hover:bg-raised hover:text-mint disabled:text-muted/50',
    seam: 'bg-line',
    primary: 'gap-2 pl-4 pr-3.5 py-2',
    caret: 'px-2.5 py-2',
  },
}

export function SplitButton({
  label,
  icon: Icon,
  onClick,
  items,
  variant = 'accent',
  disabled = false,
  menuLabel,
  className = '',
}: Props) {
  const [open, setOpen] = useState(false)
  const [openUp, setOpenUp] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const caretRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    const handleKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape' || !open) return
      setOpen(false)
      caretRef.current?.focus()
    }
    document.addEventListener('mousedown', handleClick)
    document.addEventListener('keydown', handleKey)
    return () => {
      document.removeEventListener('mousedown', handleClick)
      document.removeEventListener('keydown', handleKey)
    }
  }, [open])

  const toggle = () => {
    const rect = caretRef.current?.getBoundingClientRect()
    if (rect) setOpenUp(window.innerHeight - rect.bottom < 120)
    setOpen((prev) => !prev)
  }

  const styles = VARIANTS[variant]
  const half = `focus-ring cursor-pointer flex items-center justify-center text-sm transition-colors disabled:cursor-not-allowed ${styles.half}`

  return (
    <div ref={ref} className={`relative shrink-0 ${className}`}>
      <motion.div
        whileHover={disabled ? undefined : { y: -1 }}
        whileTap={disabled ? undefined : { scale: 0.97 }}
        className={`flex items-stretch rounded-lg overflow-hidden transition-colors ${styles.shell}`}
      >
        <button
          type="button"
          disabled={disabled}
          onClick={onClick}
          className={`${half} ${styles.primary}`}
        >
          {Icon && <Icon className="w-3 h-3" />}
          {label}
        </button>

        <span
          className={`w-px self-stretch shrink-0 ${disabled ? 'bg-line' : styles.seam}`}
        />

        <button
          ref={caretRef}
          type="button"
          disabled={disabled}
          onClick={toggle}
          aria-haspopup="menu"
          aria-expanded={open}
          aria-label={menuLabel}
          className={`${half} ${styles.caret}`}
        >
          <motion.span
            animate={{ rotate: open ? 180 : 0 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            className="flex"
          >
            <IconChevronDown className="w-3 h-3" />
          </motion.span>
        </button>
      </motion.div>

      <AnimatePresence>
        {open && (
          <motion.div
            role="menu"
            initial={{ opacity: 0, y: openUp ? 4 : -4, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: openUp ? 4 : -4, scale: 0.96 }}
            transition={{ duration: 0.12, ease: 'easeOut' }}
            className={`absolute right-0 z-30 ${
              openUp ? 'bottom-full mb-1 origin-bottom' : 'mt-1 origin-top'
            } w-max min-w-52 max-w-72 rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-1.5`}
          >
            {items.map((item) => {
              const ItemIcon = item.icon
              return (
                <button
                  key={item.label}
                  type="button"
                  role="menuitem"
                  onClick={() => {
                    setOpen(false)
                    item.onClick()
                  }}
                  className="w-full flex items-center cursor-pointer gap-2.5 px-3 py-2 rounded-lg text-xs font-medium text-ink whitespace-nowrap hover:bg-raised transition-colors"
                >
                  {ItemIcon && <ItemIcon className="w-3.5 h-3.5 shrink-0 text-muted" />}
                  <span className="flex-1 text-left">{item.label}</span>
                  {item.badge && (
                    <span className="ml-2 text-[10px] uppercase tracking-[0.08em] text-muted/70">
                      {item.badge}
                    </span>
                  )}
                </button>
              )
            })}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
