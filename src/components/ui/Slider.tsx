interface Props {
  value: number
  min: number
  max: number
  step?: number
  onChange: (value: number) => void
  disabled?: boolean
  label?: string
}

export function Slider({
  value,
  min,
  max,
  step = 1,
  onChange,
  disabled,
  label,
}: Props) {
  const percent = ((value - min) / (max - min)) * 100
  const thumbSize = 16

  return (
    <div
      className={`group relative flex items-center w-full h-5 ${disabled ? 'opacity-40' : ''}`}
    >
      <div
        className={`pointer-events-none absolute inset-x-0 top-1/2 -translate-y-1/2 h-1.5 rounded-full bg-raised border overflow-hidden transition-colors ${
          disabled ? 'border-line' : 'border-line group-hover:border-accent-dim'
        }`}
      >
        <div
          className="h-full bg-accent rounded-full"
          style={{ width: `${percent}%` }}
        />
      </div>
      <div
        className="pointer-events-none absolute top-1/2 -translate-y-1/2 w-4 h-4 rounded-full bg-white shadow-md border border-line transition-transform duration-150 group-active:scale-90 group-hover:scale-110"
        style={{ left: `calc(${percent}% - ${(percent / 100) * thumbSize}px)` }}
      />
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        disabled={disabled}
        aria-label={label}
        onChange={(e) => onChange(Number(e.target.value))}
        className="focus-ring relative z-10 m-0 w-full h-5 appearance-none bg-transparent disabled:cursor-not-allowed cursor-pointer
          [&::-webkit-slider-runnable-track]:h-5 [&::-webkit-slider-runnable-track]:bg-transparent
          [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:bg-transparent [&::-webkit-slider-thumb]:border-0 [&::-webkit-slider-thumb]:cursor-pointer
          [&::-moz-range-track]:h-5 [&::-moz-range-track]:bg-transparent [&::-moz-range-progress]:bg-transparent
          [&::-moz-range-thumb]:appearance-none [&::-moz-range-thumb]:w-4 [&::-moz-range-thumb]:h-4 [&::-moz-range-thumb]:bg-transparent [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:cursor-pointer"
      />
    </div>
  )
}
