import { motion, AnimatePresence } from 'framer-motion'
import { api } from '../../lib/api'
import { IconPlus, IconTrash, IconCheck } from '../Icons'

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
  defaultLabel = 'Default',
  fallbackDownloadPath = 'AppData\\Roaming\\com.ryko.godothub\\godot-versions\\',
  showFallbackDescription = false,
}: Props) {
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
              className="flex flex-col gap-2.5 px-3.5 py-2.5 rounded-lg bg-raised border border-line"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="text-xs font-mono text-ink truncate">
                  {dir}
                </span>
                <button
                  onClick={() => removeDir(dir)}
                  className="icon-wiggle cursor-pointer text-muted hover:text-danger transition-colors shrink-0"
                  aria-label="Remove folder"
                >
                  <IconTrash className="w-3.5 h-3.5" />
                </button>
              </div>
              {onSetDefault && (
                <div className="pt-2 border-t border-line/60">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <button
                      type="button"
                      role="checkbox"
                      aria-checked={isDefault}
                      onClick={() => toggleDefault(dir)}
                      className={
                        'focus-ring shrink-0 flex items-center justify-center w-4 h-4 rounded border transition-colors ' +
                        (isDefault
                          ? 'bg-accent border-accent-dim'
                          : 'bg-transparent border-line hover:border-accent-dim')
                      }
                    >
                      {isDefault && (
                        <IconCheck className="w-2.5 h-2.5 text-white" />
                      )}
                    </button>
                    <span
                      onClick={() => toggleDefault(dir)}
                      className={
                        'text-xs transition-colors ' +
                        (isDefault ? 'text-ink' : 'text-muted')
                      }
                    >
                      Use as {defaultLabel.toLowerCase()}
                    </span>
                  </label>

                  {!isDefault && showFallbackDescription && (
                    <p className="text-[10px] text-muted mt-1.5 leading-relaxed">
                      {hasDefault
                        ? `Downloads will go to "${defaultDir}"`
                        : `Default Downloads will go to "${fallbackDownloadPath}"`}
                    </p>
                  )}
                </div>
              )}
            </motion.div>
          )
        })}
      </AnimatePresence>
      <motion.button
        whileHover={{ y: -1 }}
        whileTap={{ scale: 0.96 }}
        onClick={addDir}
        className="icon-wiggle cursor-pointer focus-ring flex items-center gap-1.5 self-start px-3.5 py-2 rounded-lg border border-dashed border-line text-xs text-muted hover:text-accent-bright hover:border-accent-dim transition-colors"
      >
        <IconPlus className="w-3 h-3" />
        Add folder
      </motion.button>
    </div>
  )
}
