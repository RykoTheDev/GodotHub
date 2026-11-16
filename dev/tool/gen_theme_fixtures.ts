import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import {
  ACCENT_PRESETS_DARK,
  ACCENT_PRESETS_LIGHT,
  BG_PRESETS_DARK,
  BG_PRESETS_LIGHT,
  DEFAULT_ACCENT,
  DEFAULT_BG,
  DEFAULT_BG_LIGHT,
  DEFAULT_RAISED_CONTRAST,
  RADIUS_MD_DEFAULT,
  THEME_PRESETS,
  buildCustomPalette,
  customThemeDefaults,
  isDarkColor,
  radiusVars,
  tagColor,
  type ThemeMode,
} from '../../src/lib/colors'
import { CATEGORY_COLORS } from '../../src/lib/categoryColors'
import { WORKSPACE_COLOR_PRESETS, WORKSPACE_ICON_KEYS } from '../../src/lib/workspaceIcons'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')

const edgeColors = ['#000000', '#ffffff', '#fff', '000', '#0f0', 'ABCDEF', '#7f7f7f', '#808080', '#123456', '#fe01ff', '#05fa0a']
const accents = [...new Set([...ACCENT_PRESETS_DARK, ...ACCENT_PRESETS_LIGHT, ...edgeColors])]
const backgrounds = [...new Set([...BG_PRESETS_DARK, ...BG_PRESETS_LIGHT, ...edgeColors])]
const modes: ThemeMode[] = ['dark', 'light']
const contrasts: (number | undefined)[] = [undefined, 0, 1, 8, 13, 25, 40]

const palettes = []
for (const mode of modes) {
  for (const raisedContrast of contrasts) {
    for (let i = 0; i < Math.max(accents.length, backgrounds.length); i++) {
      const accent = accents[i % accents.length]
      const background = backgrounds[i % backgrounds.length]
      palettes.push({ accent, background, mode, raisedContrast: raisedContrast ?? null, palette: buildCustomPalette(accent, background, mode, raisedContrast) })
    }
  }
}

const radii = []
for (let md = 0; md <= 20; md++) radii.push({ md, vars: radiusVars(md) })
for (const md of [0.5, 7.5, 12.25]) radii.push({ md, vars: radiusVars(md) })
radii.push({ md: null, vars: radiusVars() })

const tags = ['', 'a', 'godot', 'Game Jam', 'prototype-2026', 'ünïcödé', '日本語タグ', 'emoji 🎮🚀', 'x'.repeat(64), 'The quick brown fox jumps over the lazy dog 0123456789', 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ']
for (let i = 0; i < 200; i++) tags.push(`tag-${i}-${(i * 7919).toString(36)}`)

const fixtures = {
  defaults: {
    accent: DEFAULT_ACCENT,
    background: DEFAULT_BG,
    backgroundLight: DEFAULT_BG_LIGHT,
    raisedContrast: DEFAULT_RAISED_CONTRAST,
    radiusMd: RADIUS_MD_DEFAULT,
    customDark: customThemeDefaults('dark'),
    customLight: customThemeDefaults('light'),
  },
  palettes,
  presets: THEME_PRESETS,
  radii,
  tags: tags.map((tag) => ({ tag, color: tagColor(tag) })),
  isDark: [...accents, ...backgrounds].map((hex) => ({ hex, dark: isDarkColor(hex) })),
  swatches: {
    accentDark: ACCENT_PRESETS_DARK,
    accentLight: ACCENT_PRESETS_LIGHT,
    bgDark: BG_PRESETS_DARK,
    bgLight: BG_PRESETS_LIGHT,
    category: CATEGORY_COLORS,
    workspace: WORKSPACE_COLOR_PRESETS,
    workspaceIcons: WORKSPACE_ICON_KEYS,
  },
  density: [0.75, 0.8, 1, 1.05, 1.25].map((scale) => ({ scale, spacing: `${4 * scale}px` })),
  fontScale: [0.85, 1, 1.15, 1.3].map((scale) => ({ scale, fontSize: `${scale * 100}%` })),
}

writeFileSync(join(root, 'app/test/fixtures/theme_tokens.json'), JSON.stringify(fixtures, null, 1) + '\n')
console.log(`${palettes.length} palettes, ${radii.length} radii, ${fixtures.tags.length} tags`)
