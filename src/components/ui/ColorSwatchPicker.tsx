import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'

interface Props {
  label: string
  value: string
  onChange: (hex: string) => void
  presets: string[]
}

function isValidHex(hex: string) {
  return /^#([0-9a-fA-F]{6})$/.test(hex)
}

export function ColorSwatchPicker({ label, value, onChange, presets }: Props) {
  const [open, setOpen] = useState(false)
  const [hexDraft, setHexDraft] = useState(value)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => setHexDraft(value), [value])

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div ref={ref} className="relative flex flex-col gap-2">
      <span className="text-xs font-medium text-muted">{label}</span>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="focus-ring cursor-pointer icon-wiggle group flex items-center gap-3 px-3.5 py-2.5 rounded-lg bg-raised border border-line hover:border-accent-dim transition-colors"
      >
        <span
          className="w-8 h-8 rounded-md border border-line shadow-inner shrink-0 transition-transform group-hover:scale-105"
          style={{ backgroundColor: value }}
        />
        <span className="text-xs font-mono text-ink">
          {value.toLowerCase()}
        </span>
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -6, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -6, scale: 0.97 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            className="absolute z-30 top-full mt-2 left-0 w-64 rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-4 flex flex-col gap-3"
          >
            <div className="grid grid-cols-8 gap-2">
              {presets.map((preset) => (
                <button
                  key={preset}
                  type="button"
                  onClick={() => {
                    onChange(preset)
                    setHexDraft(preset)
                  }}
                  aria-label={preset}
                  className={`w-6 h-6 rounded-full cursor-pointer border transition-transform hover:scale-125 hover:z-10 ${
                    preset.toLowerCase() === value.toLowerCase()
                      ? 'border-2 border-ink scale-110'
                      : 'border-black/20'
                  }`}
                  style={{ backgroundColor: preset }}
                />
              ))}
            </div>

            <div className="flex items-center gap-2 pt-1 border-t border-line">
              <label className="relative w-9 h-9 rounded-md border border-line overflow-hidden shrink-0 cursor-pointer hover:border-accent-dim transition-colors">
                <span
                  className="absolute inset-0"
                  style={{ backgroundColor: value }}
                />
                <input
                  type="color"
                  value={value}
                  onChange={(e) => {
                    onChange(e.target.value)
                    setHexDraft(e.target.value)
                  }}
                  className="absolute inset-0 opacity-0 cursor-pointer"
                />
              </label>
              <input
                value={hexDraft}
                onChange={(e) => {
                  const v = e.target.value.startsWith('#')
                    ? e.target.value
                    : `#${e.target.value}`
                  setHexDraft(v)
                  if (isValidHex(v)) onChange(v)
                }}
                onBlur={() => {
                  if (!isValidHex(hexDraft)) setHexDraft(value)
                }}
                spellCheck={false}
                className="focus-ring flex-1 min-w-0 bg-raised border border-line rounded-md px-2.5 py-1.5 text-xs font-mono text-ink focus:border-accent-dim transition-colors"
              />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
