import { useUiMotion } from '../../hooks/useUiMotion'

interface Props {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  disabled?: boolean
}

export function Toggle({ checked, onChange, label, disabled }: Props) {
  const {reduced, instant} = useUiMotion()
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`focus-ring relative shrink-0 inline-flex items-center h-7 w-12 rounded-full border transition-colors duration-200 rtl:-scale-x-100 ${
        checked ? 'bg-accent border-accent-dim' : 'bg-raised border-line'
      } ${disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer hover:brightness-110'}`}
    >
      <span
        style={{left: checked ? 23 : 3, transition: reduced || instant ? 'none' : 'left 160ms var(--ease-out)'}}
        className="absolute top-[3px] block w-5 h-5 rounded-full bg-white shadow-md"
      />
    </button>
  )
}
