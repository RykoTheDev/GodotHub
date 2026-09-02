import { useCallback, useRef, useState, useEffect } from 'react'

interface HsvColorPickerProps {
  value: string
  onChange: (hex: string) => void
  size?: number
}

function hexToHsv(hex: string): { h: number; s: number; v: number } {
  const clean = hex.replace('#', '')
  const r = parseInt(clean.substring(0, 2), 16) / 255
  const g = parseInt(clean.substring(2, 4), 16) / 255
  const b = parseInt(clean.substring(4, 6), 16) / 255

  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  const d = max - min

  let h = 0
  if (d !== 0) {
    if (max === r) h = ((g - b) / d) % 6
    else if (max === g) h = (b - r) / d + 2
    else h = (r - g) / d + 4
    h = Math.round(h * 60)
    if (h < 0) h += 360
  }

  const s = max === 0 ? 0 : Math.round((d / max) * 100)
  const v = Math.round(max * 100)

  return { h, s, v }
}

function hsvToHex(h: number, s: number, v: number): string {
  s /= 100
  v /= 100

  const c = v * s
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1))
  const m = v - c

  let r = 0, g = 0, b = 0
  if (h < 60) { r = c; g = x; b = 0 }
  else if (h < 120) { r = x; g = c; b = 0 }
  else if (h < 180) { r = 0; g = c; b = x }
  else if (h < 240) { r = 0; g = x; b = c }
  else if (h < 300) { r = x; g = 0; b = c }
  else { r = c; g = 0; b = x }

  const toHex = (n: number) =>
    Math.round((n + m) * 255)
      .toString(16)
      .padStart(2, '0')

  return `#${toHex(r)}${toHex(g)}${toHex(b)}`
}

export function HsvColorPicker({ value, onChange, size = 200 }: HsvColorPickerProps) {
  const hsv = hexToHsv(value)
  const [dragging, setDragging] = useState<'sv' | 'hue' | null>(null)
  const svRef = useRef<HTMLDivElement>(null)
  const hueRef = useRef<HTMLDivElement>(null)

  const updateFromSV = useCallback(
    (clientX: number, clientY: number) => {
      const el = svRef.current
      if (!el) return
      const rect = el.getBoundingClientRect()
      const s = Math.max(0, Math.min(100, ((clientX - rect.left) / rect.width) * 100))
      const v = Math.max(0, Math.min(100, 100 - ((clientY - rect.top) / rect.height) * 100))
      onChange(hsvToHex(hsv.h, s, v))
    },
    [hsv.h, onChange],
  )

  const updateFromHue = useCallback(
    (clientX: number) => {
      const el = hueRef.current
      if (!el) return
      const rect = el.getBoundingClientRect()
      const h = Math.max(0, Math.min(359, ((clientX - rect.left) / rect.width) * 360))
      onChange(hsvToHex(h, hsv.s, hsv.v))
    },
    [hsv.s, hsv.v, onChange],
  )

  useEffect(() => {
    if (!dragging) return

    const onMove = (e: MouseEvent) => {
      e.preventDefault()
      if (dragging === 'sv') updateFromSV(e.clientX, e.clientY)
      else if (dragging === 'hue') updateFromHue(e.clientX)
    }
    const onUp = () => setDragging(null)

    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [dragging, updateFromSV, updateFromHue])

  const svThumbX = (hsv.s / 100) * size
  const svThumbY = ((100 - hsv.v) / 100) * size
  const hueX = (hsv.h / 360) * size

  return (
    <div className="flex flex-col gap-3 select-none">
      {/* Saturation / Brightness panel */}
      <div
        ref={svRef}
        className="relative rounded-lg cursor-crosshair overflow-hidden border border-line"
        style={{
          width: size,
          height: size,
          background: `linear-gradient(to top, #000, transparent),
                        linear-gradient(to right, #fff, hsl(${hsv.h}, 100%, 50%))`,
        }}
        onMouseDown={(e) => {
          setDragging('sv')
          updateFromSV(e.clientX, e.clientY)
        }}
      >
        {/* Thumb */}
        <div
          className="absolute w-4 h-4 rounded-full border-2 border-white shadow-md pointer-events-none -translate-x-1/2 -translate-y-1/2"
          style={{
            left: svThumbX,
            top: svThumbY,
            boxShadow: '0 0 0 1px rgba(0,0,0,0.3), 0 2px 4px rgba(0,0,0,0.3)',
          }}
        />
      </div>

      {/* Hue slider */}
      <div
        ref={hueRef}
        className="relative rounded-lg cursor-pointer overflow-hidden border border-line"
        style={{
          width: size,
          height: 14,
          background: 'linear-gradient(to right, #f00, #ff0, #0f0, #0ff, #00f, #f0f, #f00)',
        }}
        onMouseDown={(e) => {
          setDragging('hue')
          updateFromHue(e.clientX)
        }}
      >
        <div
          className="absolute top-1/2 -translate-y-1/2 w-2 h-5 rounded-sm border-2 border-white pointer-events-none"
          style={{
            left: hueX,
            transform: `translateX(-50%) translateY(-50%)`,
            boxShadow: '0 0 0 1px rgba(0,0,0,0.3), 0 1px 3px rgba(0,0,0,0.2)',
          }}
        />
      </div>
    </div>
  )
}
