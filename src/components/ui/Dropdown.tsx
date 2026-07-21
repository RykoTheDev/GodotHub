import { useCallback, useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { IconChevronDown } from '../Icons'

export interface DropdownOption {
  value: string
  label: string
  dotClassName?: string
  dotColor?: string
}

interface Props {
  value: string
  options: DropdownOption[]
  onChange: (value: string) => void
  emptyLabel?: string
  className?: string
  openUp?: boolean
}

export function Dropdown({
  value,
  options,
  onChange,
  emptyLabel = 'Choose Version',
  className = '',
  openUp,
}: Props) {
  const [open, setOpen] = useState(false)
  const [computedOpenUp, setComputedOpenUp] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const handleToggle = useCallback(() => {
    if (!open) {
      if (ref.current) {
        const btn = ref.current.querySelector('button')
        if (btn) {
          const rect = btn.getBoundingClientRect()
          const spaceBelow = window.innerHeight - rect.bottom
          setComputedOpenUp(spaceBelow < 160)
        }
      }
    }
    setOpen((o) => !o)
  }, [open])

  const dir = openUp !== undefined ? openUp : computedOpenUp

  const selected = options.find((o) => o.value === value)

  return (
    <div ref={ref} className={`relative ${className}`}>
      <button
        type="button"
        onClick={handleToggle}
        className={`focus-ring cursor-pointer w-full flex items-center justify-between gap-2 px-3.5 py-2.5 rounded-lg bg-raised border text-xs text-ink transition-colors ${
          open ? 'border-accent' : 'border-line hover:border-accent-dim'
        }`}
      >
        <span className="flex items-center gap-2 truncate">
          {selected?.dotColor ? (
            <span
              className="w-2 h-2 rounded-full shrink-0 ring-1 ring-black/10"
              style={{ backgroundColor: selected.dotColor }}
            />
          ) : (
            <span
              className={`w-2 h-2 rounded-full shrink-0 ${selected?.dotClassName ?? 'bg-line'}`}
            />
          )}
          <span className="truncate font-mono">
            {selected ? selected.label : emptyLabel}
          </span>
        </span>
        <IconChevronDown
          className={`w-3.5 h-3.5 text-muted shrink-0 transition-transform duration-200 ${open ? 'rotate-180 text-accent' : ''}`}
        />
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: dir ? 6 : -6, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: dir ? 6 : -6, scale: 0.97 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            className={`absolute z-20 ${dir ? 'bottom-full mb-2 origin-bottom' : 'mt-2 origin-top'} w-full min-w-44 rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-1.5 max-h-60 overflow-y-auto`}
          >
            <button
              type="button"
              onClick={() => {
                onChange('')
                setOpen(false)
              }}
              className={`w-full flex items-center cursor-pointer gap-2 text-left px-3 py-2 rounded-lg text-xs font-mono transition-colors ${
                value === ''
                  ? 'bg-accent/20 text-accent-bright'
                  : 'text-muted hover:bg-raised hover:text-ink'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-line" />
              {emptyLabel}
            </button>
            {options.map((o) => (
              <button
                key={o.value}
                type="button"
                onClick={() => {
                  onChange(o.value)
                  setOpen(false)
                }}
                className={`w-full flex items-center cursor-pointer gap-2 text-left px-3 py-2 rounded-lg text-xs font-mono transition-colors ${
                  value === o.value
                    ? 'bg-accent/20 text-accent-bright'
                    : 'text-ink hover:bg-raised'
                }`}
              >
                {o.dotColor ? (
                <span
                  className="w-2 h-2 rounded-full shrink-0 ring-1 ring-black/10"
                  style={{ backgroundColor: o.dotColor }}
                />
              ) : (
                <span
                  className={`w-2 h-2 rounded-full shrink-0 ${o.dotClassName ?? 'bg-line'}`}
                />
              )}
                {o.label}
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
