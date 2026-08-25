import { motion, AnimatePresence } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { api } from '../../../lib/api'
import { IconPlus, IconTrash, IconCheck } from '../../lib/icons'

interface Props {
  dirs: string[]
  onChange: (dirs: string[]) => void
  emptyHint: string
  defaultDir?: string | null
  onSetDefault?: (dir: string | null) => void
  defaultLabel?: string
  fallbackDownloadPath?: string
  showFallbackDescription?: boolean
}

export function DirList({
  dirs,
  onChange,
  emptyHint,
  defaultDir,
  onSetDefault,
  defaultLabel: defaultLabelProp,
  fallbackDownloadPath = 'AppData/Ryko.GodotHub/godot-versions/',
  showFallbackDescription = false,
}: Props) {
  const { t } = useTranslation('common')
  const defaultLabel = defaultLabelProp ?? t('default_folder')
  const addDir = async () => {
    const folder = await api.pickFolder()
    if (folder && !dirs.includes(folder)) onChange([...dirs, folder])
  }

  const removeDir = (dir: string) => {
    onChange(dirs.filter((d) => d !== dir))
    if (onSetDefault && defaultDir === dir) onSetDefault(null)
  }

  const toggleDefault = (dir: string) => {
    if (!onSetDefault) return
    onSetDefault(defaultDir === dir ? null : dir)
  }

  const hasDefault = onSetDefault && defaultDir !== null

  return (
    <div className="flex flex-col gap-2.5">
      {dirs.length === 0 && <p className="text-xs text-muted">{emptyHint}</p>}
      <AnimatePresence initial={false}>
        {dirs.map((dir) => {
          const isDefault = onSetDefault ? defaultDir === dir : false
          return (
            <motion.div
              key={dir}
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.15 }}
              className={`flex flex-col gap-2.5 px-3.5 py-2.5 rounded-item bg-base border transition-colors ${
                isDefault ? 'border-accent-dim/60 bg-accent/5' : 'border-outline/50'
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2 min-w-0">
                  <span className="text-xs font-mono text-ink truncate">
                    {dir}
                  </span>
                  {isDefault && (
                    <span className="shrink-0 text-[9px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-tag bg-accent/15 text-accent-bright border border-accent-dim/40">
                      {t('default_folder')}
                    </span>
                  )}
                </div>
                <button
                  type="button"
                  onClick={() => removeDir(dir)}
                  className="icon-wiggle cursor-pointer text-muted hover:text-danger transition-colors shrink-0"
                  aria-label={t('remove_folder')}
                >
                  <IconTrash className="w-3.5 h-3.5" />
                </button>
              </div>
              {onSetDefault && (
                <div className="pt-2 border-t border-outline/50">
                  <label
                    className={`flex items-center gap-2.5 cursor-pointer select-none rounded-item px-2.5 py-2 -mx-2.5 transition-colors ${
                      isDefault ? 'bg-accent/10' : 'hover:bg-overlay/50'
                    }`}
                  >
                    <button
                      type="button"
                      role="checkbox"
                      aria-checked={isDefault}
                      aria-label={t('make_this_default', {
                        label: defaultLabel.toLowerCase(),
                      })}
                      onClick={() => toggleDefault(dir)}
                      className={`focus-ring shrink-0 flex items-center justify-center w-5 h-5 rounded-md border-2 transition-all ${
                        isDefault
                          ? 'bg-accent border-accent shadow-sm shadow-accent/40'
                          : 'bg-transparent border-outline/60 hover:border-accent-dim'
                      }`}
                    >
                      {isDefault && (
                        <IconCheck className="w-3 h-3 text-white" />
                      )}
                    </button>
                    <span
                      onClick={() => toggleDefault(dir)}
                      className={`text-xs font-medium transition-colors ${
                        isDefault ? 'text-accent-bright' : 'text-muted hover:text-ink'
                      }`}
                    >
                      {t('make_this_default', {
                        label: defaultLabel.toLowerCase(),
                      })}
                    </span>
                  </label>

                  {!isDefault && showFallbackDescription && (
                    <p className="text-[10px] text-muted mt-1.5 leading-relaxed px-0.5">
                      {hasDefault
                        ? t('downloads_will_go_to', { path: defaultDir })
                        : t('default_downloads_go_to', { path: fallbackDownloadPath })}
                    </p>
                  )}
                </div>
              )}
            </motion.div>
          )
        })}
      </AnimatePresence>

      <motion.button
        type="button"
        whileHover={{ y: -1 }}
        whileTap={{ scale: 0.96 }}
        onClick={addDir}
        className="icon-wiggle cursor-pointer focus-ring flex items-center gap-1.5 self-start px-3.5 py-2 rounded-item border border-dashed border-outline/60 text-xs text-muted hover:text-accent-bright hover:border-accent-dim transition-colors"
      >
        <IconPlus className="w-3 h-3" />
        {t('add_folder')}
      </motion.button>
    </div>
  )
}
