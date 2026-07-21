function hexToRgb(hex: string): [number, number, number] {
  const clean = hex.replace('#', '')
  const full =
    clean.length === 3
      ? clean
          .split('')
          .map((c) => c + c)
          .join('')
      : clean
  const n = parseInt(full, 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

function rgbToHex(r: number, g: number, b: number): string {
  return (
    '#' +
    [r, g, b]
      .map((v) =>
        Math.max(0, Math.min(255, Math.round(v)))
          .toString(16)
          .padStart(2, '0'),
      )
      .join('')
  )
}

function shift(hex: string, amount: number): string {
  const [r, g, b] = hexToRgb(hex)
  return rgbToHex(r + amount, g + amount, b + amount)
}

export type ThemeMode = 'dark' | 'light'

const DARK_NEUTRALS = {
  overlay: '#3a3c43',
  ink: '#f2f3f5',
  muted: '#949ba4',
}

export function applyTheme(
  accent: string,
  background: string,
  mode: ThemeMode = 'dark',
) {
  const root = document.documentElement
  const style = root.style

  root.classList.add('theme-transitioning')
  setTimeout(() => root.classList.remove('theme-transitioning'), 450)

  style.setProperty('--color-accent', accent)
  style.setProperty('--color-accent-dim', shift(accent, -45))
  style.setProperty('--color-accent-bright', shift(accent, 35))

  if (mode === 'light') {
    style.setProperty('--color-base', background)
    style.setProperty('--color-surface', shift(background, 15))
    style.setProperty('--color-raised', shift(background, -6))
    style.setProperty('--color-overlay', shift(background, -12))
    style.setProperty('--color-line', shift(background, -18))
    style.setProperty('--color-ink', '#1b1c1f')
    style.setProperty('--color-muted', '#6b7280')
  } else {
    style.setProperty('--color-base', background)
    style.setProperty('--color-surface', shift(background, 9))
    style.setProperty('--color-raised', shift(background, 18))
    style.setProperty('--color-overlay', DARK_NEUTRALS.overlay)
    style.setProperty('--color-line', shift(background, 28))
    style.setProperty('--color-ink', DARK_NEUTRALS.ink)
    style.setProperty('--color-muted', DARK_NEUTRALS.muted)
  }
}
