interface SegmentedProps {
  value: string
  onChange: (value: string) => void
  options: { value: string; label: string; mono?: boolean }[]
}

export function Segmented({ value, onChange, options }: SegmentedProps) {
  return (
    <div className="inline-flex self-start rounded-btn border border-outline/50 bg-overlay p-1 gap-1">
      {options.map(({ value: v, label, mono }) => {
        const active = value === v
        return (
          <button
            key={v}
            type="button"
            onClick={() => onChange(v)}
            className={`focus-ring cursor-pointer px-3.5 py-1.5 rounded-btn text-xs font-medium transition-colors ${
              mono ? 'font-mono' : ''
            } ${active ? 'bg-accent text-white' : 'text-muted hover:text-ink hover:bg-raised'}`}
          >
            {label}
          </button>
        )
      })}
    </div>
  )
}
