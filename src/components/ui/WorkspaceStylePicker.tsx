import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import {
  WORKSPACE_COLOR_PRESETS,
  WORKSPACE_ICON_KEYS,
  getWorkspaceIcon,
} from '../../lib/workspaceIcons'

interface Props {
  icon: string
  onIconChange: (key: string) => void
  color: string
  onColorChange: (color: string) => void
}

export function WorkspaceStylePicker({
  icon,
  onIconChange,
  color,
  onColorChange,
}: Props) {
  const { t } = useTranslation('common')

  return (
    <>
      <div className="flex flex-col gap-2.5">
        <span className="text-xs font-medium text-muted">{t('icon_label')}</span>
        <div className="grid grid-cols-6 gap-1.5">
          {WORKSPACE_ICON_KEYS.map((key) => {
            const Icon = getWorkspaceIcon(key)
            const active = icon === key
            return (
              <motion.button
                key={key}
                type="button"
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.94 }}
                onClick={() => onIconChange(key)}
                aria-label={key}
                aria-pressed={active}
                className={`focus-ring cursor-pointer aspect-square rounded-tile flex items-center justify-center border transition-colors ${
                  active
                    ? 'border-accent bg-raised text-ink shadow-sm shadow-black/10'
                    : 'border-outline text-muted hover:text-ink hover:bg-raised'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
              </motion.button>
            )
          })}
        </div>
      </div>

      <div className="flex flex-col gap-2.5">
        <span className="text-xs font-medium text-muted">{t('color_label')}</span>
        <div className="grid grid-cols-7 gap-1.5">
          {WORKSPACE_COLOR_PRESETS.map((c) => {
            const active = color === c
            return (
              <motion.button
                key={c}
                type="button"
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.9 }}
                onClick={() => onColorChange(c)}
                aria-label={c}
                aria-pressed={active}
                className={`focus-ring cursor-pointer aspect-square rounded-full border-2 transition-transform ${
                  active
                    ? 'border-ink scale-110'
                    : 'border-transparent hover:scale-110'
                }`}
                style={{ backgroundColor: c }}
              />
            )
          })}
        </div>
      </div>
    </>
  )
}
