import { useRef, useState, useLayoutEffect } from 'react'
import { motion } from 'framer-motion'

interface SegmentedProps {
  value: string
  onChange: (value: string) => void
  options: { value: string; label: string; mono?: boolean }[]
}

export function Segmented({ value, onChange, options }: SegmentedProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const [indicator, setIndicator] = useState<{ left: number; width: number }>({
    left: 0,
    width: 0,
  })

  useLayoutEffect(() => {
    const container = containerRef.current
    if (!container) return
    const activeIdx = options.findIndex((o) => o.value === value)
    const buttons = container.querySelectorAll<HTMLButtonElement>('button')
    const btn = buttons[activeIdx]
    if (!btn) return
    const containerRect = container.getBoundingClientRect()
    const btnRect = btn.getBoundingClientRect()
    setIndicator({
      left: btnRect.left - containerRect.left,
      width: btnRect.width,
    })
  }, [value, options])

  return (
    <div
      ref={containerRef}
      className="inline-flex self-start rounded-btn border border-outline/50 bg-overlay p-1 gap-1 relative isolate"
    >
      <motion.div
        className="absolute top-1 bottom-1 rounded-btn bg-accent"
        animate={{ left: indicator.left, width: indicator.width }}
        transition={{ type: 'spring', stiffness: 500, damping: 35, mass: 0.8 }}
      />
      {options.map(({ value: v, label, mono }) => {
        const active = value === v
        return (
          <button
            key={v}
            type="button"
            onClick={() => onChange(v)}
            className={`focus-ring cursor-pointer px-3.5 py-1.5 rounded-btn text-xs font-medium transition-colors relative z-10 ${
              mono ? 'font-mono' : ''
            } ${active ? 'text-white' : 'text-muted hover:text-ink hover:bg-raised/50'}`}
          >
            {label}
          </button>
        )
      })}
    </div>
  )
}
