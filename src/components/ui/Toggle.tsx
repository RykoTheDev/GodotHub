
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
      className={`group/toggle focus-ring relative shrink-0 inline-flex items-center h-7 w-12 rounded-full border rtl:-scale-x-100 ${
        checked ? 'bg-accent border-accent-dim' : 'bg-raised border-line'
      } ${disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer hover:brightness-110'}`}
    >
      <span
        style={{ left: checked ? 'calc(100% - var(--spacing) * 5 - 3px)' : 3 }}
        className="absolute top-1/2 -translate-y-1/2 block w-5 h-5 rounded-full bg-white shadow-md transition-[left,scale] duration-500 ease-spring group-active/toggle:scale-x-125 group-active/toggle:scale-y-90"
      />
    </button>
  )
}
