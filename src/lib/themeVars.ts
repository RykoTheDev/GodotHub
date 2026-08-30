const THEME_VARS_STYLE_ID = 'app-theme-vars'

let themeVars: Record<string, string> = {}

function flushThemeVars() {
  const entries = Object.entries(themeVars)
  const style = document.getElementById(
    THEME_VARS_STYLE_ID,
  ) as HTMLStyleElement | null
  if (entries.length === 0) {
    style?.remove()
    return
  }
  const css = `:root{${entries
    .map(([key, value]) => `${key}:${value}`)
    .join(';')}}`
  if (!style) {
    const el = document.createElement('style')
    el.id = THEME_VARS_STYLE_ID
    document.head.appendChild(el)
    el.textContent = css
  } else {
    style.textContent = css
  }
}

export function setThemeVars(vars: Record<string, string>) {
  themeVars = { ...themeVars, ...vars }
  flushThemeVars()
}

export function removeThemeVars(keys: string[]) {
  for (const key of keys) {
    delete themeVars[key]
  }
  flushThemeVars()
}
