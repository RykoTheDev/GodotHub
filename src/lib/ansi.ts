/**
 * Minimal ANSI escape-sequence renderer for the built-in project console.
 *
 * Godot colourises its output with SGR codes, so we keep the colours (plus the
 * usual bold/dim/underline) instead of dumping escape junk into the window.
 */

export interface AnsiStyle {
  color?: string
  background?: string
  bold?: boolean
  dim?: boolean
  italic?: boolean
  underline?: boolean
}

export interface AnsiSpan extends AnsiStyle {
  text: string
}

/** xterm's default 16 colours, tuned for a dark terminal surface. */
const ANSI_16 = [
  '#3f4451',
  '#e05561',
  '#8cc265',
  '#d18f52',
  '#4aa5f0',
  '#c162de',
  '#42b3c2',
  '#d7dae0',
  '#4f5666',
  '#ff616e',
  '#a5e075',
  '#f0a45d',
  '#4dc4ff',
  '#de73ff',
  '#4cd1e0',
  '#e6e6e6',
]

const CUBE_STEPS = [0, 95, 135, 175, 215, 255]

function rgbToHex(r: number, g: number, b: number): string {
  const channel = (value: number) =>
    Math.max(0, Math.min(255, Math.round(value)))
      .toString(16)
      .padStart(2, '0')
  return `#${channel(r)}${channel(g)}${channel(b)}`
}

/** Maps an xterm 256-colour index to a CSS colour. */
export function ansi256Color(index: number): string | undefined {
  if (!Number.isFinite(index) || index < 0) return undefined
  if (index < 16) return ANSI_16[index]
  if (index < 232) {
    const offset = index - 16
    return rgbToHex(
      CUBE_STEPS[Math.floor(offset / 36) % 6],
      CUBE_STEPS[Math.floor(offset / 6) % 6],
      CUBE_STEPS[offset % 6],
    )
  }
  if (index < 256) {
    const grey = 8 + (index - 232) * 10
    return rgbToHex(grey, grey, grey)
  }
  return undefined
}

const NON_SGR_ESCAPE =
  // eslint-disable-next-line no-control-regex
  /\u001b\][^\u0007\u001b]*(?:\u0007|\u001b\\)|\u001b\[[0-9;?]*[A-Za-ln-~]|\u001b[@-Z\\_]/g

// eslint-disable-next-line no-control-regex
const SGR_WITH_STYLE = /\u001b\[[0-9;]*m/g

function stripEscapes(input: string): string {
  return input.replace(NON_SGR_ESCAPE, '')
}

export function stripAnsi(input: string): string {
  if (!input.includes('\u001b')) return input
  return stripEscapes(input.replace(SGR_WITH_STYLE, ''))
}

// eslint-disable-next-line no-control-regex
const SGR = /\u001b\[([0-9;]*)m/g

function applySgr(style: AnsiStyle, params: string): AnsiStyle {
  const codes = (params === '' ? '0' : params)
    .split(';')
    .map((part) => Number.parseInt(part, 10))
    .filter((value) => !Number.isNaN(value))

  let next: AnsiStyle = { ...style }

  for (let i = 0; i < codes.length; i += 1) {
    const code = codes[i]
    if (code === 0) {
      next = {}
    } else if (code === 1) {
      next.bold = true
    } else if (code === 2) {
      next.dim = true
    } else if (code === 3) {
      next.italic = true
    } else if (code === 4) {
      next.underline = true
    } else if (code === 22) {
      next.bold = false
      next.dim = false
    } else if (code === 23) {
      next.italic = false
    } else if (code === 24) {
      next.underline = false
    } else if (code >= 30 && code <= 37) {
      next.color = ANSI_16[code - 30]
    } else if (code === 39) {
      next.color = undefined
    } else if (code >= 40 && code <= 47) {
      next.background = ANSI_16[code - 40]
    } else if (code === 49) {
      next.background = undefined
    } else if (code >= 90 && code <= 97) {
      next.color = ANSI_16[code - 90 + 8]
    } else if (code >= 100 && code <= 107) {
      next.background = ANSI_16[code - 100 + 8]
    } else if (code === 38 || code === 48) {
      const target = code === 38 ? 'color' : 'background'
      if (codes[i + 1] === 5) {
        const resolved = ansi256Color(codes[i + 2])
        if (resolved) next[target] = resolved
        i += 2
      } else if (codes[i + 1] === 2) {
        const [r, g, b] = [codes[i + 2], codes[i + 3], codes[i + 4]]
        if (r != null && g != null && b != null) {
          next[target] = rgbToHex(r, g, b)
        }
        i += 4
      }
    }
  }

  return next
}

/** Splits a line into styled runs. Text with no styling comes back as one span. */
export function parseAnsi(input: string): AnsiSpan[] {
  if (!input) return []
  if (!input.includes('\u001b')) return [{ text: input }]

  const spans: AnsiSpan[] = []
  let style: AnsiStyle = {}
  let cursor = 0

  const push = (text: string) => {
    if (!text) return
    spans.push({ ...style, text })
  }

  SGR.lastIndex = 0
  let match: RegExpExecArray | null
  while ((match = SGR.exec(input)) !== null) {
    push(stripEscapes(input.slice(cursor, match.index)))
    style = applySgr(style, match[1])
    cursor = match.index + match[0].length
  }
  push(stripEscapes(input.slice(cursor)))

  return spans
}

export function ansiSpanStyle(span: AnsiStyle): {
  color?: string
  backgroundColor?: string
  fontWeight?: number
  opacity?: number
  fontStyle?: 'italic'
  textDecoration?: 'underline'
} {
  return {
    color: span.color,
    backgroundColor: span.background,
    fontWeight: span.bold ? 600 : undefined,
    opacity: span.dim ? 0.7 : undefined,
    fontStyle: span.italic ? 'italic' : undefined,
    textDecoration: span.underline ? 'underline' : undefined,
  }
}
