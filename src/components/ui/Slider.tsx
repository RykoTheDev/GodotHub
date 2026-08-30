import type { ReactNode } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { IconRefresh } from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'
import { beginScaleSmoothing } from '../../lib/appearance'

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

  return (
    <div className="flex flex-col gap-2 w-full">
      {(label || display || canReset) && (
        <div className="flex items-center justify-between gap-4">
          {label && (
            <span className="text-xs font-medium text-muted">{label}</span>
          )}
          <span className="ml-auto flex items-center gap-1.5">
            {display && (
              <span className="shrink-0 inline-flex items-center px-2 py-0.5 rounded-tag bg-raised border border-outline/50">
                {display}
              </span>
            )}
            <span className="relative w-5 h-5 shrink-0">
              <AnimatePresence>
                {canReset && (
                    <Tooltip content={t('reset_to_default')} side="left">
                      <motion.button key="button-53"
                        type="button"
                        initial={{ opacity: 0, scale: 0.75, y: 1 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.75, y: 1 }}
                        transition={{ type: 'spring', stiffness: 350, damping: 26, mass: 0.9 }}
                        onClick={() => {
                          beginScaleSmoothing()
                          onChange(defaultValue)
                        }}
                        disabled={disabled}
                        aria-label={t('reset_to_default')}
                        className="focus-ring cursor-pointer w-full h-full flex items-center justify-center rounded-full bg-raised border border-outline/50 text-muted transition-colors duration-150 hover:text-accent-bright hover:border-accent-dim/70 hover:bg-overlay disabled:cursor-not-allowed disabled:opacity-50 absolute inset-0"
                      >
                        <IconRefresh className="w-3 h-3" />
                      </motion.button>
                    </Tooltip>
                )}
              </AnimatePresence>
            </span>
          </span>
        </div>
      )}

      <div
        className={`group relative flex items-center w-full h-5 ${disabled ? 'opacity-40' : ''}`}
      >
        <div
          className={`pointer-events-none absolute inset-x-0 top-1/2 -translate-y-1/2 h-6 rounded-md bg-raised border overflow-hidden transition-colors ${
            disabled ? 'border-line' : 'border-outline/50 group-hover:border-accent-dim'
          }`}
        >
          <div
            className="h-full bg-accent"
            style={{ width: `${percent}%` }}
          />
        </div>
        <div
          className="pointer-events-none absolute top-1/2 -translate-y-1/2 w-4 h-8 rounded-lg bg-white shadow-md border border-line transition-transform duration-150 group-active:scale-90 group-hover:scale-110"
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
          onChange={(e) => {
            beginScaleSmoothing()
            onChange(Number(e.target.value))
          }}
          className="focus-ring relative z-10 m-0 w-full h-6 appearance-none bg-transparent disabled:cursor-not-allowed cursor-pointer
          [&::-webkit-slider-runnable-track]:h-5 [&::-webkit-slider-runnable-track]:bg-transparent
          [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:bg-transparent [&::-webkit-slider-thumb]:border-0 [&::-webkit-slider-thumb]:cursor-pointer
          [&::-moz-range-track]:h-5 [&::-moz-range-track]:bg-transparent [&::-moz-range-progress]:bg-transparent
          [&::-moz-range-thumb]:appearance-none [&::-moz-range-thumb]:w-4 [&::-moz-range-thumb]:h-4 [&::-moz-range-thumb]:bg-transparent [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:cursor-pointer"
        />
      </div>
    </div>
  )
}
