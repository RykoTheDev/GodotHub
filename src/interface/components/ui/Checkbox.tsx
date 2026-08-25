import type { ReactNode } from 'react'
import { motion } from 'framer-motion'
import { IconCheck } from '../../lib/icons'

interface Props {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  disabled?: boolean
  children?: ReactNode
}

export function Checkbox({ checked, onChange, label, disabled, children }: Props) {
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`focus-ring inline-flex items-center gap-2.5 select-none rounded-md -m-1 p-1 transition-colors ${
        disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer'
      }`}
    >
      <span
        className={`shrink-0 inline-flex items-center justify-center w-[18px] h-[18px] rounded-sm border transition-colors duration-150 ${
          checked
            ? 'bg-accent border-accent-dim text-white'
            : 'bg-raised border-line text-transparent hover:border-accent-dim'
        }`}
      >
        <motion.span
          initial={false}
          animate={{ scale: checked ? 1 : 0, opacity: checked ? 1 : 0 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          className="flex items-center justify-center"
        >
          <IconCheck className="w-3 h-3" />
        </motion.span>
      </span>
      {children && <span className="text-xs font-medium text-ink">{children}</span>}
    </button>
  )
}
