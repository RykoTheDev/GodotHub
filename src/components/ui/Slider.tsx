import { useEffect, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { IconRefresh } from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'

interface Props {
  value: number
  min: number
  max: number
  step?: number
  onChange: (value: number) => void
  disabled?: boolean
  label?: string
  display?: ReactNode
  defaultValue?: number
}

export function Slider({
  value,
  min,
  max,
  step = 1,
  onChange,
  disabled,
  label,
  display,
  defaultValue,
}: Props) {
  const { t } = useTranslation('settings')
  const percent = ((value - min) / (max - min)) * 100
  const thumbSize = 16
  const canReset =
    defaultValue !== undefined && Math.abs(value - defaultValue) >= step / 2
  const [dragging, setDragging] = useState(false)
  const [resetAtDragStart, setResetAtDragStart] = useState(canReset)
  const showReset = dragging ? resetAtDragStart : canReset

  useEffect(() => {
    if (!dragging) return
    const stop = () => setDragging(false)
    window.addEventListener('pointerup', stop)
    window.addEventListener('pointercancel', stop)
    return () => {
      window.removeEventListener('pointerup', stop)
      window.removeEventListener('pointercancel', stop)
    }
  }, [dragging])

  return (
    <div className="flex items-center gap-3 w-full">
      {label && (
        <span className="shrink-0 text-xs font-medium text-muted">{label}</span>
      )}
      <div
        dir="ltr"
        className={`group relative flex-1 min-w-0 flex items-center h-5 ${disabled ? 'opacity-40' : ''}`}
      >
        <div
          className={`pointer-events-none absolute inset-x-0 top-1/2 -translate-y-1/2 h-6 rounded-md bg-raised border overflow-hidden  ${
            disabled ? 'border-line' : 'border-outline/50 group-hover:border-accent-dim'
          }`}
        >
          <div
            className="h-full bg-accent"
            style={{ width: `${percent}%` }}
          />
        </div>
        <div
          className="pointer-events-none absolute top-1/2 -translate-y-1/2 w-4 h-8 rounded-lg bg-white shadow-md border border-line  "
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
          onPointerDown={() => {
            setResetAtDragStart(canReset)
            setDragging(true)
          }}
          onChange={(e) => {
            onChange(Number(e.target.value))
          }}
          className="focus-ring relative z-10 m-0 w-full h-6 rounded-md appearance-none bg-transparent disabled:cursor-not-allowed cursor-pointer
          [&::-webkit-slider-runnable-track]:h-5 [&::-webkit-slider-runnable-track]:bg-transparent
          [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:bg-transparent [&::-webkit-slider-thumb]:border-0 [&::-webkit-slider-thumb]:cursor-pointer
          [&::-moz-range-track]:h-5 [&::-moz-range-track]:bg-transparent [&::-moz-range-progress]:bg-transparent
          [&::-moz-range-thumb]:appearance-none [&::-moz-range-thumb]:w-4 [&::-moz-range-thumb]:h-4 [&::-moz-range-thumb]:bg-transparent [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:cursor-pointer"
        />
      </div>
      <span className="shrink-0 flex items-center">
        <span
          aria-hidden={!showReset}
          className={`flex overflow-hidden transition-[width,margin,opacity] duration-300 ease-out-expo ${
            showReset ? 'w-6 me-1 opacity-100' : 'w-0 me-0 opacity-0'
          }`}
        >
        <Tooltip content={t('reset_to_default')} side="left">
          <button
            type="button"
            onClick={() => {
              if (defaultValue === undefined) return
              onChange(defaultValue)
            }}
            disabled={disabled || !canReset}
            aria-label={t('reset_to_default')}
            className={`focus-ring cursor-pointer h-6 w-6 flex items-center justify-center rounded-full border overflow-hidden shrink-0 ${canReset ? 'bg-raised border-outline/50 text-muted hover:text-accent-bright hover:border-accent-dim/70 hover:bg-overlay' : 'bg-transparent border-transparent text-transparent'}`}
          >
            <IconRefresh className="w-3 h-3" />
          </button>
        </Tooltip>
        </span>
        {display && (
          <span className="shrink-0 inline-flex items-center justify-center min-w-14 px-2 h-6 bg-raised border border-outline/50 text-xs font-mono text-ink tabular-nums rounded-tag">
            {display}
          </span>
        )}
      </span>
    </div>
  )
}
