export function applyRadius(mdPx: number) {
  const root = document.documentElement.style
  const sm = mdPx * (0.25 / 0.375)
  const lg = mdPx * (0.5 / 0.375)
  const xl = mdPx * (0.75 / 0.375)
  root.setProperty('--radius-sm', `${sm}px`)
  root.setProperty('--radius-md', `${mdPx}px`)
  root.setProperty('--radius-lg', `${lg}px`)
  root.setProperty('--radius-xl', `${xl}px`)
}

export function applyDensity(scale: number) {
  document.documentElement.style.setProperty('--spacing', `${4 * scale}px`)
}

export function applyFontScale(scale: number) {
  document.documentElement.style.fontSize = `${scale * 100}%`
}

export function applyReducedMotion(enabled: boolean) {
  document.documentElement.classList.toggle('reduce-motion', enabled)
}

export function applyAppearance(settings: {
  corner_radius: number
  ui_density: number
  font_scale: number
  reduce_motion: boolean
}) {
  applyRadius(settings.corner_radius)
  applyDensity(settings.ui_density)
  applyFontScale(settings.font_scale)
  applyReducedMotion(settings.reduce_motion)
}
