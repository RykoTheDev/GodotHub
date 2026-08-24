import { setThemeVars } from './themeVars'
import { radiusVars } from './colors'

export function applyRadius(mdPx: number) {
  setThemeVars(radiusVars(mdPx))
}

let scaleSmoothTimer: ReturnType<typeof setTimeout> | null = null

export function beginScaleSmoothing() {
  document.documentElement.classList.add('ui-scaling')
  if (scaleSmoothTimer) clearTimeout(scaleSmoothTimer)
  scaleSmoothTimer = setTimeout(() => {
    document.documentElement.classList.remove('ui-scaling')
  }, 350)
}

export function applyDensity(scale: number) {
  setThemeVars({ '--spacing': `${4 * scale}px` })
}

export function applyFontScale(scale: number) {
  setThemeVars({ 'font-size': `${scale * 100}%` })
}

import { MotionGlobalConfig } from 'framer-motion'
import type { AnimationIntensity } from './motion'

let animationIntensity: AnimationIntensity = 'full'
let reducedMotionQuery: MediaQueryList | null = null

function reducedMotionMediaQuery(): MediaQueryList {
  reducedMotionQuery ??= window.matchMedia('(prefers-reduced-motion: reduce)')
  return reducedMotionQuery
}

function osPrefersReducedMotion(): boolean {
  return reducedMotionMediaQuery().matches
}

function shouldReduceMotion(): boolean {
  return osPrefersReducedMotion() || animationIntensity === 'none'
}

function applyReduceMotionState() {
  const enabled = shouldReduceMotion()
  document.documentElement.classList.toggle('reduce-motion', enabled)
  MotionGlobalConfig.instantAnimations = enabled
}

export function applyAnimationIntensity(intensity: AnimationIntensity) {
  animationIntensity = intensity
  applyReduceMotionState()
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

export function initReducedMotionDetection() {
  const mq = reducedMotionMediaQuery()
  const handler = () => applyReduceMotionState()
  if (typeof mq.addEventListener === 'function') {
    mq.addEventListener('change', handler)
  } else {
    mq.addListener(handler)
  }
  applyReduceMotionState()
  return () => {
    if (typeof mq.removeEventListener === 'function') {
      mq.removeEventListener('change', handler)
    } else {
      mq.removeListener(handler)
    }
  }
}

export function isReducedMotion(): boolean {
  return shouldReduceMotion()
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
  animation_intensity: AnimationIntensity
  show_scrollbars: boolean
  project_icon_opacity: number
}) {
  applyRadius(settings.corner_radius)
  applyDensity(settings.ui_density)
  applyFontScale(settings.font_scale)
  applyAnimationIntensity(settings.animation_intensity)
  applyCustomCss(settings.custom_css)
  applyScrollbars(settings.show_scrollbars)
  applyProjectIconOpacity(settings.project_icon_opacity)
}
