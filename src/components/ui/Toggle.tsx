import { motion } from 'framer-motion'

interface Props {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  disabled?: boolean
}

export function Toggle({ checked, onChange, label, disabled }: Props) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`focus-ring relative shrink-0 inline-flex items-center h-7 w-12 rounded-full border transition-colors duration-200 ${
        checked ? 'bg-accent border-accent-dim' : 'bg-raised border-line'
      } ${disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer hover:brightness-110'}`}
    >
      <motion.span
        layout
        transition={{ type: 'spring', stiffness: 500, damping: 32 }}
        className="block w-5 h-5 rounded-full bg-white shadow-md"
        style={{ marginLeft: checked ? 'calc(100% - 22px)' : '2px' }}
      />
    </button>
  )
}
