import { useEffect, useState } from 'react'
import { IconCheck } from '../../lib/icons'
import { HsvColorPicker } from './HsvColorPicker'
import { Dropdown } from './Dropdown'

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
  const [hexDraft, setHexDraft] = useState(value)

  useEffect(() => setHexDraft(value), [value])

  return (
    <Dropdown
      align="left"
      side="bottom"
      trigger={({ open, toggle }) => (
        <div className="flex flex-col gap-2 min-w-0 w-full">
          <span className="text-xs font-medium text-muted">{label}</span>
          <button
            type="button"
            onClick={toggle}
            aria-expanded={open}
            className="focus-ring cursor-pointer flex items-center gap-3 px-3 py-2.5 rounded-btn bg-overlay border border-outline/50 hover:border-accent-dim transition-colors w-full"
          >
            <span
              className="w-8 h-8 rounded-tile border border-line shadow-inner shrink-0"
              style={{ backgroundColor: value }}
            />
            <span className="text-xs font-mono text-ink truncate ml-auto">
              {value.toLowerCase()}
            </span>
          </button>
        </div>
      )}
    >
      <div className="p-3 flex flex-col gap-3 min-w-[440px]">
        <div className="flex gap-3">
          {/* HSV Picker + hex input */}
          <div className="flex flex-col gap-3">
            <HsvColorPicker
              value={value}
              onChange={(hex) => {
                onChange(hex)
                setHexDraft(hex)
              }}
              size={180}
            />
            <div className="flex items-center gap-2">
              <span
                className="w-7 h-7 rounded-item border border-line shadow-inner shrink-0"
                style={{ backgroundColor: value }}
              />
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
                placeholder="#000000"
                className="focus-ring w-20 bg-overlay border border-outline/50 rounded-item px-2.5 py-2 text-xs font-mono text-ink focus:border-accent-dim transition-colors"
              />
            </div>
          </div>

          {/* Preset swatches */}
          <div className="border-l border-line pl-3 flex flex-col">
            <span className="text-[10px] font-medium text-muted/60 uppercase tracking-wider mb-2 block">Presets</span>
            <div className="grid grid-cols-6 gap-1.5">
              {presets.map((preset) => {
                const isSelected = preset.toLowerCase() === value.toLowerCase()
                return (
                  <button
                    key={preset}
                    type="button"
                    onClick={() => {
                      onChange(preset)
                      setHexDraft(preset)
                    }}
                    aria-label={preset}
                    title={preset}
                    className={`relative w-7 h-7 rounded-btn cursor-pointer border transition-all hover:scale-125 hover:z-10 ${
                      isSelected
                        ? 'ring-2 ring-offset-1 ring-offset-surface ring-ink scale-110'
                        : 'border-black/20 hover:border-white/40'
                    }`}
                    style={{ backgroundColor: preset }}
                  >
                    {isSelected && (
                      <IconCheck className="absolute inset-0 m-auto w-2.5 h-2.5" style={{ color: preset === '#ffffff' || preset === '#f8f9fa' || preset === '#fafafa' || preset === '#fdf6e3' || preset === '#fbf1c7' ? '#000' : '#fff' }} />
                    )}
                  </button>
                )
              })}
            </div>
          </div>
        </div>
      </div>
    </Dropdown>
  )
}
