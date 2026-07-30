import { useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Workspace } from '../../types'
import { ColorSwatchPicker } from '../ui/ColorSwatchPicker'
import { ConfirmDialog } from './ConfirmDialog'
import {
  WORKSPACE_ICON_KEYS,
  WORKSPACE_COLOR_PRESETS,
  getWorkspaceIcon,
} from '../../lib/workspaceIcons'

interface Props {
  workspace: Workspace
  canDelete: boolean
  onClose: () => void
  onSave: (name: string, icon: string, color: string) => Promise<void>
  onDelete: () => Promise<void>
}

export function WorkspaceEditModal({
  workspace,
  canDelete,
  onClose,
  onSave,
  onDelete,
}: Props) {
  const { t } = useTranslation('common')
  const [name, setName] = useState(workspace.name)
  const [icon, setIcon] = useState(workspace.icon)
  const [color, setColor] = useState(workspace.color)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [confirmingDelete, setConfirmingDelete] = useState(false)

  const submit = async () => {
    if (!name.trim()) {
      setError(t('workspace_name_required_error'))
      return
    }
    setBusy(true)
    setError(null)
    try {
      await onSave(name, icon, color)
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-7 w-full max-w-md flex flex-col gap-6 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div>
          <h3 className="font-display font-semibold text-lg">{t('edit_workspace_title')}</h3>
          <p className="text-xs text-muted mt-1.5">
            {t('workspace_edit_desc')}
          </p>
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">{t('workspace_name_label')}</label>
          <input
            autoFocus
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && submit()}
            className="focus-ring bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors"
          />
        </div>

        <div className="flex flex-col gap-2.5">
          <span className="text-xs font-medium text-muted">{t('icon_label')}</span>
          <div className="flex flex-wrap gap-2">
            {WORKSPACE_ICON_KEYS.map((key) => {
              const Icon = getWorkspaceIcon(key)
              const active = icon === key
              return (
                <motion.button
                  key={key}
                  type="button"
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.94 }}
                  onClick={() => setIcon(key)}
                  aria-label={key}
                  className={`focus-ring cursor-pointer w-9 h-9 rounded-lg flex items-center justify-center border transition-colors ${
                    active
                      ? 'border-accent bg-raised text-ink'
                      : 'border-line text-muted hover:text-ink hover:bg-raised'
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                </motion.button>
              )
            })}
          </div>
        </div>

        <ColorSwatchPicker
          label={t('color_label')}
          value={color}
          onChange={setColor}
          presets={WORKSPACE_COLOR_PRESETS}
        />

        {error && <p className="text-xs text-danger">{error}</p>}

        <div className="flex items-center justify-between gap-2.5 mt-1">
          <motion.button
            whileHover={canDelete ? { y: -1 } : undefined}
            whileTap={canDelete ? { scale: 0.96 } : undefined}
            onClick={() => canDelete && setConfirmingDelete(true)}
            disabled={!canDelete}
            title={
              canDelete ? undefined : t('cant_delete_only_workspace')
            }
            className="focus-ring cursor-pointer disabled:cursor-not-allowed px-4 py-2.5 rounded-lg text-sm text-muted hover:text-danger hover:bg-danger/5 disabled:opacity-40 disabled:hover:text-muted disabled:hover:bg-transparent transition-colors"
          >
            {t('delete_workspace')}
          </motion.button>

          <div className="flex gap-2.5">
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={onClose}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
            >
              {t('cancel')}
            </motion.button>
            <motion.button
              whileHover={busy ? undefined : { y: -1 }}
              whileTap={busy ? undefined : { scale: 0.96 }}
              onClick={submit}
              disabled={busy}
              className="focus-ring px-4 cursor-pointer py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors"
            >
              {t('save')}
            </motion.button>
          </div>
        </div>
      </motion.div>

      {confirmingDelete && (
        <div onClick={(e) => e.stopPropagation()}>
          <ConfirmDialog
            title={t('delete_workspace_title')}
            description={t('delete_workspace_desc', { name: workspace.name })}
            confirmLabel={t('delete')}
            variant="danger"
            onConfirm={() => {
              setConfirmingDelete(false)
              onDelete()
            }}
            onCancel={() => setConfirmingDelete(false)}
          />
        </div>
      )}
    </motion.div>
  )
}
