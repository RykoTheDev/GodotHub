import { setThemeVars } from './themeVars'
import { radiusVars } from './colors'
import { setRtlLayout } from '../i18n'

export function applyRadius(mdPx: number) {
  setThemeVars(radiusVars(mdPx))
}

export function applyDensity(scale: number) {
  setThemeVars({ '--spacing': `${4 * scale}px` })
}

export function applyFontScale(scale: number) {
  setThemeVars({ 'font-size': `${scale * 100}%` })
}

const USER_CSS_ID = 'app-user-css'
const THEME_VARS_STYLE_ID = 'app-theme-vars'

export function applyCustomCss(css: string) {
  let style = document.getElementById(USER_CSS_ID) as HTMLStyleElement | null
  if (!css.trim()) {
    style?.remove()
    return
  }
  if (!style) {
    style = document.createElement('style')
    style.id = USER_CSS_ID
    const themeVars = document.getElementById(THEME_VARS_STYLE_ID)
    if (themeVars?.nextSibling) {
      document.head.insertBefore(style, themeVars.nextSibling)
    } else {
      document.head.appendChild(style)
    }
  }
  style.textContent = css
}

export function applyScrollbars(enabled: boolean) {
  document.documentElement.classList.toggle('hide-scrollbars', !enabled)
}

export function applyProjectIconOpacity(opacity: number) {
  const clamped = Math.max(0, Math.min(100, opacity))
  setThemeVars({ '--project-icon-opacity': String(clamped / 100) })
}

export function applyAppearance(settings: {
  corner_radius: number
  ui_density: number
  font_scale: number
  custom_css: string
  show_scrollbars: boolean
  project_icon_opacity: number
  rtl_layout?: boolean
}) {
  applyRadius(settings.corner_radius)
  applyDensity(settings.ui_density)
  applyFontScale(settings.font_scale)
  applyCustomCss(settings.custom_css)
  applyScrollbars(settings.show_scrollbars)
  applyProjectIconOpacity(settings.project_icon_opacity)
  setRtlLayout(settings.rtl_layout ?? false)
}
