import { useTranslation } from 'react-i18next'
import {
  DARK_THEME_PRESETS,
  LIGHT_THEME_PRESETS,
} from '../../../lib/colors'
import { ModalShell } from './ModalShell'
import { IconCheck, IconMoon, IconSun } from '../../lib/icons'
import { ThemePresetPreview } from '../reusables/ThemePresetPreview'

interface Props {
  mode: 'light' | 'dark'
  currentId: string
  onSelect: (id: string) => void
  onClose: () => void
}

export function ThemePresetsModal({
  mode,
  currentId,
  onSelect,
  onClose,
}: Props) {
  const { t: ts } = useTranslation('settings')
  const presets =
    mode === 'light' ? LIGHT_THEME_PRESETS : DARK_THEME_PRESETS
  const Icon = mode === 'light' ? IconSun : IconMoon
  const title =
    mode === 'light' ? ts('preset_light_group') : ts('preset_dark_group')

  return (
    <ModalShell
      icon={<Icon className="w-5 h-5 text-accent-bright" />}
      title={title}
      description={String(presets.length)}
      maxWidth="max-w-2xl"
      onClose={onClose}
    >
        <div className="p-4">
          <div className="grid grid-cols-[repeat(auto-fill,minmax(170px,1fr))] gap-2">
            {presets.map((preset) => {
              const active = preset.id === currentId
              return (
                <button
                  key={preset.id}
                  type="button"
                  onClick={() => onSelect(preset.id)}
                  className={`focus-ring cursor-pointer flex flex-col items-start gap-2 rounded-btn border p-3 text-left transition-colors ${
                    active
                      ? 'border-accent bg-accent/10'
                      : 'border-outline/50 hover:border-accent-dim hover:bg-raised'
                  }`}
                >
                  <ThemePresetPreview preset={preset} />
                  <span className="text-xs font-medium text-ink flex items-center gap-1 w-full min-w-0">
                    {active && (
                      <IconCheck className="w-3 h-3 text-accent-bright shrink-0" />
                    )}
                    <span className="truncate">{preset.name}</span>
                  </span>
                </button>
              )
            })}
          </div>
        </div>
    </ModalShell>
  )
}
