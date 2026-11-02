import { setThemeVars } from './themeVars'
import { radiusVars } from './colors'
import { setRtlLayout } from '../i18n'
import { configureMotion } from './motion'
import type { AppSettings } from '../types'

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

type MotionSettings = Pick<
  AppSettings,
  | 'animation_intensity'
  | 'animation_speed'
  | 'view_entrance'
  | 'animation_threshold'
  | 'motion_scroll_reveal'
  | 'motion_card_tilt'
  | 'motion_click_ripple'
  | 'motion_press_bounce'
>

export function applyMotion(settings: MotionSettings) {
  configureMotion({
    intensity: settings.animation_intensity,
    speed: settings.animation_speed,
    entrance: settings.view_entrance,
    threshold: settings.animation_threshold,
    scrollReveal: settings.motion_scroll_reveal,
    tilt: settings.motion_card_tilt,
    ripple: settings.motion_click_ripple,
    press: settings.motion_press_bounce,
  })
}

export function motionSettingsChanged(prev: MotionSettings, next: MotionSettings) {
  return (
    prev.animation_intensity !== next.animation_intensity ||
    prev.animation_speed !== next.animation_speed ||
    prev.view_entrance !== next.view_entrance ||
    prev.animation_threshold !== next.animation_threshold ||
    prev.motion_scroll_reveal !== next.motion_scroll_reveal ||
    prev.motion_card_tilt !== next.motion_card_tilt ||
    prev.motion_click_ripple !== next.motion_click_ripple ||
    prev.motion_press_bounce !== next.motion_press_bounce
  )
}

export function applyAppearance(settings: MotionSettings & {
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
  applyMotion(settings)
}
