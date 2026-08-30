import themeDefaults from '../../src-tauri/theme-defaults.json'
import { setThemeVars } from './themeVars'

export const DEFAULT_ACCENT = themeDefaults.accent
export const DEFAULT_BG = themeDefaults.background
export const DEFAULT_BG_LIGHT = '#f8f9fa'
export const DEFAULT_RAISED_CONTRAST = 8

export const RADIUS_MD_DEFAULT = 12

export const RADIUS_SCALE: Record<string, number> = {
  '--radius-sm': 0.8,
  '--radius-md': 1.0,
  '--radius-lg': 1.4,
  '--radius-xl': 2.0,
  '--radius-tag': 1.0,
  '--radius-btn': 1.6,
  '--radius-dropdown-btn': 1.3,
  '--radius-dropdown': 1.3,
  '--radius-item': 2.2,
  '--radius-tile': 1.6,
  '--radius-menu': 2.4,
  '--radius-card': 2.4,
  '--radius-modal': 3.0,
}

export function radiusVars(mdPx: number = RADIUS_MD_DEFAULT): Record<string, string> {
  const vars: Record<string, string> = {}
  for (const [name, scale] of Object.entries(RADIUS_SCALE)) {
    vars[name] = `${mdPx * scale}px`
  }
  return vars
}

export function customThemeDefaults(mode: ThemeMode) {
  return {
    accent_color: DEFAULT_ACCENT,
    background_color: mode === 'light' ? DEFAULT_BG_LIGHT : DEFAULT_BG,
  }
}

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

export function isDarkColor(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex)
  const lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
  return lum < 0.5
}

export type ThemeMode = 'dark' | 'light'

export type ThemeModeSetting = ThemeMode | 'system'

export function resolveThemeMode(mode: ThemeModeSetting): ThemeMode {
  if (mode === 'system') {
    return window.matchMedia('(prefers-color-scheme: light)').matches
      ? 'light'
      : 'dark'
  }
  return mode
}

const DARK_NEUTRALS = {
  overlay: '#222329',
  ink: '#f2f3f5',
  muted: '#949ba4',
}

const TAG_COLORS = [
  '#457ff2', '#f28b45', '#45c97f', '#e74c8a', '#a855f7',
  '#22d3ee', '#f59e0b', '#ef4444', '#10b981', '#6366f1',
  '#ec4899', '#14b8a6', '#f97316', '#8b5cf6', '#06b6d4',
  '#84cc16', '#d946ef', '#0ea5e9', '#eab308', '#3b82f6',
]

export function tagColor(tag: string): string {
  let hash = 0
  for (let i = 0; i < tag.length; i++) {
    hash = tag.charCodeAt(i) + ((hash << 5) - hash)
  }
  return TAG_COLORS[Math.abs(hash) % TAG_COLORS.length]
}

export const ACCENT_PRESETS_DARK = [
  '#457ff2', '#5865f2', '#7983f5', '#23a55a', '#f0b132', '#eb459e',
  '#00a8fc', '#2dd4bf', '#a78bfa', '#f97316', '#84cc16', '#e11d48',
  '#0ea5e9', '#facc15', '#8b5cf6', '#f23f42', '#22c55e', '#3b82f6', '#f43f5e',
]

export const ACCENT_PRESETS_LIGHT = [
  '#457ff2', '#5b75e6', '#7480e8', '#36a05b', '#e0a832', '#d9458e',
  '#00a1e8', '#2dc4b4', '#9d7ae0', '#ec7031', '#78b820', '#d1263f',
  '#1b9ce0', '#e8c420', '#8470e8', '#e04244', '#28b45a', '#4285d4', '#d94562',
]

export const BG_PRESETS_DARK = [
  '#15171c', '#1a1c23', '#10131a', '#1e1f22', '#111214', '#13151a', '#0f1115',
  '#20232a', '#171a21', '#1c1e24', '#0d0e11', '#232630',
  '#1b1d24', '#101114', '#191b20', '#181a1e', '#1f2127', '#1a1c21',
  '#0e1014', '#1c1e23', '#121418',
]

export const BG_PRESETS_LIGHT = [
  '#f8f9fa', '#ffffff', '#f0f2f5', '#f5f5f5', '#fafafa', '#eceff1',
  '#f3f4f6', '#f9fafb', '#eef1f5', '#f8f6f3', '#f2f6fc', '#faf5ef',
  '#edf2f7', '#f6f8fa', '#f1f3f5', '#e8ecf1', '#faf6f0',
]

export interface ThemePreset {
  id: string
  name: string
  mode: ThemeMode
  base: string
  surface: string
  raised: string
  overlay: string
  line: string
  outline: string
  ink: string
  muted: string
  accent: string
  accentDim: string
  accentBright: string
  mint: string
  amber: string
  danger: string
}

export const THEME_PRESETS: ThemePreset[] = [
  {
    id: 'atom-one-dark',
    name: 'Atom One Dark',
    mode: 'dark',
    base: '#282c34',
    surface: '#21252b',
    raised: '#2c313a',
    overlay: '#2c313a',
    line: '#3e4451',
    outline: '#3e4451',
    ink: '#abb2bf',
    muted: '#5c6370',
    accent: '#61afef',
    accentDim: '#4b8bbd',
    accentBright: '#82aaff',
    mint: '#98c379',
    amber: '#e5c07b',
    danger: '#e06c75',
  },
  {
    id: 'nord',
    name: 'Nord',
    mode: 'dark',
    base: '#2e3440',
    surface: '#272c36',
    raised: '#3b4252',
    overlay: '#3b4252',
    line: '#434c5e',
    outline: '#434c5e',
    ink: '#eceff4',
    muted: '#8a94ad',
    accent: '#88c0d0',
    accentDim: '#5e81ac',
    accentBright: '#8fbcbb',
    mint: '#a3be8c',
    amber: '#ebcb8b',
    danger: '#bf616a',
  },
  {
    id: 'catppuccin-latte',
    name: 'Catppuccin Latte',
    mode: 'light',
    base: '#eff1f5',
    surface: '#e6e9ef',
    raised: '#dce0e8',
    overlay: '#e6e9ef',
    line: '#ccd0da',
    outline: '#ccd0da',
    ink: '#4c4f69',
    muted: '#6c6f85',
    accent: '#1e66f5',
    accentDim: '#7287fd',
    accentBright: '#04a5e5',
    mint: '#40a02b',
    amber: '#df8e1d',
    danger: '#d20f39',
  },
  {
    id: 'catppuccin-mocha',
    name: 'Catppuccin Mocha',
    mode: 'dark',
    base: '#1e1e2e',
    surface: '#313244',
    raised: '#45475a',
    overlay: '#313244',
    line: '#45475a',
    outline: '#45475a',
    ink: '#cdd6f4',
    muted: '#a6adc8',
    accent: '#89b4fa',
    accentDim: '#7287fd',
    accentBright: '#b4befe',
    mint: '#a6e3a1',
    amber: '#f9e2af',
    danger: '#f38ba8',
  },
  {
    id: 'dracula',
    name: 'Dracula',
    mode: 'dark',
    base: '#282a36',
    surface: '#21222c',
    raised: '#343746',
    overlay: '#343746',
    line: '#44475a',
    outline: '#44475a',
    ink: '#f8f8f2',
    muted: '#6272a4',
    accent: '#bd93f9',
    accentDim: '#9a6fe0',
    accentBright: '#d6b4ff',
    mint: '#50fa7b',
    amber: '#f1fa8c',
    danger: '#ff5555',
  },
  {
    id: 'github-dark',
    name: 'GitHub Dark',
    mode: 'dark',
    base: '#0d1117',
    surface: '#161b22',
    raised: '#21262d',
    overlay: '#161b22',
    line: '#30363d',
    outline: '#30363d',
    ink: '#e6edf3',
    muted: '#8b949e',
    accent: '#58a6ff',
    accentDim: '#388bfd',
    accentBright: '#79c0ff',
    mint: '#3fb950',
    amber: '#d29922',
    danger: '#f85149',
  },
  {
    id: 'solarized-dark',
    name: 'Solarized Dark',
    mode: 'dark',
    base: '#002b36',
    surface: '#073642',
    raised: '#0a3a46',
    overlay: '#073642',
    line: '#0a3a46',
    outline: '#0a3a46',
    ink: '#93a1a1',
    muted: '#657b83',
    accent: '#268bd2',
    accentDim: '#2aa198',
    accentBright: '#6c71c4',
    mint: '#859900',
    amber: '#b58900',
    danger: '#dc322f',
  },
  {
    id: 'gruvbox',
    name: 'Gruvbox',
    mode: 'dark',
    base: '#282828',
    surface: '#1d2021',
    raised: '#32302f',
    overlay: '#32302f',
    line: '#3c3836',
    outline: '#3c3836',
    ink: '#ebdbb2',
    muted: '#928374',
    accent: '#d65d0e',
    accentDim: '#b57614',
    accentBright: '#fe8019',
    mint: '#b8bb26',
    amber: '#fabd2f',
    danger: '#fb4934',
  },
  {
    id: 'atom-one-light',
    name: 'Atom One Light',
    mode: 'light',
    base: '#fafafa',
    surface: '#f0f0f0',
    raised: '#e6e6e6',
    overlay: '#ececec',
    line: '#d8d8d8',
    outline: '#d8d8d8',
    ink: '#383a42',
    muted: '#a0a1a7',
    accent: '#4078f2',
    accentDim: '#3158b8',
    accentBright: '#0184bc',
    mint: '#50a14f',
    amber: '#c18401',
    danger: '#e45649',
  },
  {
    id: 'nord-light',
    name: 'Nord Light',
    mode: 'light',
    base: '#e5e9f0',
    surface: '#eceff4',
    raised: '#d8dee9',
    overlay: '#eceff4',
    line: '#c8d0dc',
    outline: '#c8d0dc',
    ink: '#2e3440',
    muted: '#4c566a',
    accent: '#5e81ac',
    accentDim: '#81a1c1',
    accentBright: '#88c0d0',
    mint: '#a3be8c',
    amber: '#ebcb8b',
    danger: '#bf616a',
  },
  {
    id: 'github-light',
    name: 'GitHub Light',
    mode: 'light',
    base: '#ffffff',
    surface: '#f6f8fa',
    raised: '#eaeef2',
    overlay: '#f6f8fa',
    line: '#d0d7de',
    outline: '#d0d7de',
    ink: '#1f2328',
    muted: '#656d76',
    accent: '#0969da',
    accentDim: '#0550ae',
    accentBright: '#218bff',
    mint: '#1a7f37',
    amber: '#9a6700',
    danger: '#cf222e',
  },
  {
    id: 'solarized-light',
    name: 'Solarized Light',
    mode: 'light',
    base: '#fdf6e3',
    surface: '#eee8d5',
    raised: '#e3dcc8',
    overlay: '#f0ead9',
    line: '#d8d1bd',
    outline: '#d8d1bd',
    ink: '#657b83',
    muted: '#93a1a1',
    accent: '#268bd2',
    accentDim: '#2aa198',
    accentBright: '#6c71c4',
    mint: '#859900',
    amber: '#b58900',
    danger: '#dc322f',
  },
  {
    id: 'gruvbox-light',
    name: 'Gruvbox Light',
    mode: 'light',
    base: '#fbf1c7',
    surface: '#f2e5bc',
    raised: '#ebdbb2',
    overlay: '#f2e5bc',
    line: '#d5c4a1',
    outline: '#d5c4a1',
    ink: '#3c3836',
    muted: '#928374',
    accent: '#458588',
    accentDim: '#689d6a',
    accentBright: '#83a598',
    mint: '#98971a',
    amber: '#d79921',
    danger: '#cc241d',
  },
  {
    id: 'tokyo-night-day',
    name: 'Tokyo Night Day',
    mode: 'light',
    base: '#e1e2e7',
    surface: '#d4d6de',
    raised: '#c8cbd6',
    overlay: '#d4d6de',
    line: '#b6b9c8',
    outline: '#b6b9c8',
    ink: '#2f3b54',
    muted: '#6b7394',
    accent: '#2e7de9',
    accentDim: '#2653b8',
    accentBright: '#007197',
    mint: '#587539',
    amber: '#8c6c3e',
    danger: '#f52a65',
  },
  {
    id: 'rose-pine-dawn',
    name: 'Rosé Pine Dawn',
    mode: 'light',
    base: '#faf4ed',
    surface: '#fffaf3',
    raised: '#f2e9e1',
    overlay: '#fffaf3',
    line: '#ece5dd',
    outline: '#ece5dd',
    ink: '#575279',
    muted: '#9893a5',
    accent: '#286983',
    accentDim: '#56949f',
    accentBright: '#907aa9',
    mint: '#56949f',
    amber: '#ea9d34',
    danger: '#b4637a',
  },
  {
    id: 'everforest-light',
    name: 'Everforest Light',
    mode: 'light',
    base: '#f4ead5',
    surface: '#efe3cb',
    raised: '#e9dcc0',
    overlay: '#efe3cb',
    line: '#d9cdbb',
    outline: '#d9cdbb',
    ink: '#5c6a72',
    muted: '#859289',
    accent: '#3a94c5',
    accentDim: '#2e7fae',
    accentBright: '#df69ba',
    mint: '#8da101',
    amber: '#dfa000',
    danger: '#f85552',
  },
  {
    id: 'ayu-light',
    name: 'Ayu Light',
    mode: 'light',
    base: '#fafafa',
    surface: '#f3f4f5',
    raised: '#e8e9ea',
    overlay: '#f3f4f5',
    line: '#d6d8da',
    outline: '#d6d8da',
    ink: '#5c6773',
    muted: '#8a9199',
    accent: '#399ee6',
    accentDim: '#55b4d4',
    accentBright: '#ff9940',
    mint: '#86b300',
    amber: '#ffb454',
    danger: '#f07178',
  },
]

export const LIGHT_THEME_PRESETS = THEME_PRESETS.filter(
  (p) => p.mode === 'light',
)

export const DARK_THEME_PRESETS = THEME_PRESETS.filter(
  (p) => p.mode === 'dark',
)

export function getThemePreset(id: string): ThemePreset | undefined {
  return THEME_PRESETS.find((p) => p.id === id)
}

function applyPaletteVars(
  palette: ThemePreset,
  root: HTMLElement = document.documentElement,
) {
  const vars = {
    '--color-base': palette.base,
    '--color-surface': palette.surface,
    '--color-raised': palette.raised,
    '--color-overlay': palette.overlay,
    '--color-line': palette.line,
    '--color-outline': palette.outline,
    '--color-ink': palette.ink,
    '--color-muted': palette.muted,
    '--color-accent': palette.accent,
    '--color-accent-dim': palette.accentDim,
    '--color-accent-bright': palette.accentBright,
    '--color-mint': palette.mint,
    '--color-amber': palette.amber,
    '--color-danger': palette.danger,
  }
  if (root === document.documentElement) {
    setThemeVars(vars)
    return
  }
  const style = root.style
  for (const [name, value] of Object.entries(vars)) {
    style.setProperty(name, value)
  }
}

export function applyThemePreset(
  preset: ThemePreset,
  root: HTMLElement = document.documentElement,
) {
  applyPaletteVars(preset, root)
}

export function applyTheme(
  accent: string,
  background: string,
  mode: ThemeMode = 'dark',
  preset?: ThemePreset,
  raisedContrast?: number,
) {
  const root = document.documentElement

  root.classList.add('theme-transitioning')
  setTimeout(() => root.classList.remove('theme-transitioning'), 450)

  if (preset) {
    applyThemePreset(preset, root)
    return
  }

  const palette = buildCustomPalette(accent, background, mode, raisedContrast)
  applyPaletteVars(palette, root)
}

const CUSTOM_FALLBACKS = {
  mint: '#2fbf71',
  amber: '#f0b132',
  danger: '#f2555a',
}

export function buildCustomPalette(
  accent: string,
  background: string,
  mode: ThemeMode = 'dark',
  raisedContrast?: number,
): ThemePreset {
  const light = mode === 'light'
  const contrast = raisedContrast ?? 8
  const raisedShift = light ? -contrast : contrast
  const line = shift(background, light ? -18 : 28)
  return {
    id: 'custom',
    name: 'Custom',
    mode,
    base: background,
    surface: shift(background, light ? 15 : 9),
    raised: shift(background, raisedShift),
    overlay: light ? shift(background, -12) : DARK_NEUTRALS.overlay,
    line,
    outline: '#3a3d46',
    ink: light ? '#1b1c1f' : DARK_NEUTRALS.ink,
    muted: light ? '#6b7280' : DARK_NEUTRALS.muted,
    accent,
    accentDim: shift(accent, -45),
    accentBright: shift(accent, 35),
    mint: CUSTOM_FALLBACKS.mint,
    amber: CUSTOM_FALLBACKS.amber,
    danger: CUSTOM_FALLBACKS.danger,
  }
}
