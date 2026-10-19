import { useId } from 'react'
import { motion } from 'framer-motion'
import { useUiMotion } from '../../hooks/useUiMotion'

interface SegmentedProps {
  value: string
  onChange: (value: string) => void
  options: { value: string; label: string; mono?: boolean }[]
}

export function Segmented({ value, onChange, options }: SegmentedProps) {
  // Scoped per instance so two Segmented controls on one screen don't share a pill.
  const indicatorId = useId()
  const {instant, reduced, transition} = useUiMotion()

  return (
    <div className="inline-flex self-start rounded-btn border border-outline/50 bg-overlay p-1 gap-1 relative isolate">
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
            {active && (
              <motion.div
                layoutId={instant || reduced ? undefined : indicatorId}
                transition={transition('press')}
                className="absolute inset-0 z-0 rounded-btn bg-accent"
              />
            )}
            <span className="relative z-10">{label}</span>
          </button>
        )
      })}
    </div>
  )
}
