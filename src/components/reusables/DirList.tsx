import { useTranslation } from 'react-i18next'
import { api } from '../../lib/api'
import { IconFolder, IconFolderPlus, IconPencil, IconTrash } from '../../lib/icons'
import { Tooltip } from './Tooltip'
import { Checkbox } from '../ui/Checkbox'

interface Props {
  dirs: string[]
  onChange: (dirs: string[]) => void
  emptyHint: string
  defaultDir?: string | null
  onSetDefault?: (dir: string | null) => void
  defaultLabel?: string
  fallbackDownloadPath?: string
  showFallbackDescription?: boolean
  single?: boolean
}

const iconBtn =
  'focus-ring cursor-pointer w-7 h-7 shrink-0 flex items-center justify-center rounded-tag text-muted hover:text-ink hover:bg-overlay'

export function DirList({
  dirs,
  onChange,
  emptyHint,
  defaultDir,
  onSetDefault,
  defaultLabel: defaultLabelProp,
  fallbackDownloadPath = 'AppData/Ryko.GodotHub/godot-versions/',
  showFallbackDescription = false,
  single = false,
}: Props) {
  const { t } = useTranslation('common')
  const defaultLabel = defaultLabelProp ?? t('default_folder')
  const makeDefaultLabel = t('make_this_default', { label: defaultLabel.toLowerCase() })

  const addDir = async () => {
    const folder = await api.pickFolder()
    if (!folder) return
    if (single) onChange([folder])
    else if (!dirs.includes(folder)) onChange([...dirs, folder])
  }

  const removeDir = (dir: string) => {
    onChange(dirs.filter((d) => d !== dir))
    if (onSetDefault && defaultDir === dir) onSetDefault(null)
  }

  const toggleDefault = (dir: string) => {
    if (!onSetDefault) return
    onSetDefault(defaultDir === dir ? null : dir)
  }

  if (dirs.length === 0) {
    return (
      <button
        type="button"
        onClick={addDir}
        className="focus-ring cursor-pointer group flex items-center gap-3 px-3.5 py-3 rounded-item border border-dashed border-outline/60 text-start hover:border-accent-dim hover:bg-overlay/40"
      >
        <span className="w-8 h-8 shrink-0 flex items-center justify-center rounded-tile bg-overlay text-muted group-hover:text-accent-bright">
          <IconFolderPlus className="w-4 h-4" />
        </span>
        <span className="flex-1 min-w-0">
          <span className="block text-xs font-medium text-ink group-hover:text-accent-bright">
            {t('add_folder')}
          </span>
          <span className="block text-2xs text-muted leading-relaxed">{emptyHint}</span>
        </span>
      </button>
    )
  }

  return (
    <div className="flex flex-col gap-1.5">
      {dirs.map((dir) => {
        const isDefault = !!onSetDefault && defaultDir === dir
        return (
          <div
            key={dir}
            className={`group flex flex-col rounded-item border ${
              isDefault ? 'border-accent-dim/60 bg-accent/5' : 'border-outline/50 bg-base/40'
            }`}
          >
          <div className="flex items-center gap-2.5 ps-2 pe-1.5 py-1.5">
            <span
              className={`w-8 h-8 shrink-0 flex items-center justify-center rounded-tile ${
                isDefault ? 'bg-accent/15 text-accent-bright' : 'bg-overlay text-muted'
              }`}
            >
              <IconFolder className="w-3.5 h-3.5" />
            </span>
            <Tooltip content={dir}>
              <button
                type="button"
                onClick={() => api.openProjectFolder(dir).catch(() => {})}
                aria-label={`${t('open_folder')}: ${dir}`}
                className="focus-ring cursor-pointer min-w-0 flex-1 text-start text-xs font-mono text-ink truncate hover:text-accent-bright"
              >
                {dir}
              </button>
            </Tooltip>
            {isDefault && (
              <span className="shrink-0 text-4xs font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-tag bg-accent/15 text-accent-bright">
                {t('default_folder')}
              </span>
            )}
            <div className="shrink-0 flex items-center gap-0.5">
              {single && (
                <Tooltip content={t('browse')}>
                  <button type="button" onClick={addDir} aria-label={t('browse')} className={iconBtn}>
                    <IconPencil className="w-3.5 h-3.5" />
                  </button>
                </Tooltip>
              )}
              <Tooltip content={t('remove_folder')}>
                <button
                  type="button"
                  onClick={() => removeDir(dir)}
                  aria-label={t('remove_folder')}
                  className={`${iconBtn} hover:text-danger hover:bg-danger/10`}
                >
                  <IconTrash className="w-3.5 h-3.5" />
                </button>
              </Tooltip>
            </div>
          </div>
          {onSetDefault && (
            <div className="mx-2 mb-1.5 pt-1.5 px-1 border-t border-outline/40">
              <Checkbox checked={isDefault} onChange={() => toggleDefault(dir)} className="m-0! py-1.5">
                <span className={isDefault ? 'text-accent-bright' : 'text-muted'}>
                  {makeDefaultLabel}
                </span>
              </Checkbox>
            </div>
          )}
          </div>
        )
      })}

      {!single && (
        <button
          type="button"
          onClick={addDir}
          className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 px-3.5 py-2 rounded-item border border-dashed border-outline/60 text-xs text-muted hover:text-accent-bright hover:border-accent-dim hover:bg-overlay/40"
        >
          <IconFolderPlus className="w-3.5 h-3.5" />
          {t('add_folder')}
        </button>
      )}

      {showFallbackDescription && onSetDefault && !defaultDir && (
        <p className="text-3xs text-muted leading-relaxed px-1">
          {t('default_downloads_go_to', { path: fallbackDownloadPath })}
        </p>
      )}
    </div>
  )
}
