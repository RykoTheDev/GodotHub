import type { ReactNode } from 'react'
import { motion } from 'framer-motion'
import { IconCheck, IconMinus } from '../../lib/icons'

interface Props {
  checked: boolean
  indeterminate?: boolean
  onChange: (checked: boolean) => void
  label?: string
  disabled?: boolean
  children?: ReactNode
  className?: string
}

export function Checkbox({ checked, indeterminate = false, onChange, label, disabled, children, className = '' }: Props) {
  const active = checked || indeterminate
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={indeterminate ? 'mixed' : checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`focus-ring inline-flex items-center gap-2.5 select-none rounded-md -m-1 p-1 transition-colors ${
        disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer'
      } ${className}`}
    >
      <span
        className={`shrink-0 inline-flex items-center justify-center w-[18px] h-[18px] rounded-sm border transition-colors duration-150 ${
          active
            ? 'bg-accent border-accent-dim text-white'
            : 'bg-raised border-line text-transparent hover:border-accent-dim'
        }`}
      >
        <motion.span
          initial={false}
          animate={{ scale: active ? 1 : 0, opacity: active ? 1 : 0 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          className="flex items-center justify-center"
        >
          {indeterminate ? <IconMinus className="w-3 h-3" /> : <IconCheck className="w-3 h-3" />}
        </motion.span>
      </span>
      {children && <span className="min-w-0 text-left text-xs font-medium text-ink">{children}</span>}
    </button>
  )
}
