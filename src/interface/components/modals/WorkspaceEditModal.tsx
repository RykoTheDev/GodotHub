import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Workspace } from '../../../types'
import { getWorkspaceIcon } from '../../lib/workspaceIcons'
import { ModalShell } from './ModalShell'
import { IconPencil } from '../../lib/icons'
import { ConfirmDialog } from './ConfirmDialog'
import { WorkspaceStylePicker } from '../ui/WorkspaceStylePicker'

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

  const PreviewIcon = getWorkspaceIcon(icon)
  const previewName = name.trim() || workspace.name

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
    <>
    <ModalShell
        icon={<IconPencil className="w-5 h-5 text-accent-bright" />}
        title={t('edit_workspace_title')}
        description={t('workspace_edit_desc')}
        maxWidth="max-w-md"
        onClose={onClose}
        showClose={false}
        footer={
          <>
            <motion.button
              whileHover={canDelete ? { y: -1 } : undefined}
              whileTap={canDelete ? { scale: 0.96 } : undefined}
              onClick={() => canDelete && setConfirmingDelete(true)}
              disabled={!canDelete}
              title={canDelete ? undefined : t('cant_delete_only_workspace')}
              className="focus-ring cursor-pointer disabled:cursor-not-allowed px-4 py-2.5 rounded-btn text-sm text-muted hover:text-danger hover:bg-danger/5 disabled:opacity-40 disabled:hover:text-muted disabled:hover:bg-transparent transition-colors"
            >
              {t('delete_workspace')}
            </motion.button>
            <div className="ml-auto flex gap-2.5">
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={onClose}
                className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
              >
                {t('cancel')}
              </motion.button>
              <motion.button
                whileHover={busy ? undefined : { y: -1 }}
                whileTap={busy ? undefined : { scale: 0.96 }}
                onClick={submit}
                disabled={busy}
                className="focus-ring px-5 cursor-pointer py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors"
              >
                {t('save')}
              </motion.button>
            </div>
          </>
        }
      >
          <div className="flex flex-col gap-5 p-6">
            <div className="relative overflow-hidden rounded-btn border border-outline/50 bg-overlay p-4 flex items-center gap-3">
              <div
                className="absolute -top-10 -right-10 w-32 h-32 rounded-full blur-2xl opacity-40 transition-colors duration-300"
                style={{ backgroundColor: color }}
                aria-hidden="true"
              />
              <motion.span
                key={icon}
                initial={{ scale: 0.6, rotate: -12, opacity: 0 }}
                animate={{ scale: 1, rotate: 0, opacity: 1 }}
                transition={{ type: 'spring', stiffness: 380, damping: 22 }}
                className="relative w-12 h-12 rounded-full border-2 flex items-center justify-center shrink-0"
                style={{ backgroundColor: `${color}26`, borderColor: color }}
              >
                <PreviewIcon className="w-5 h-5" style={{ color }} />
              </motion.span>
              <div className="relative min-w-0">
                <span className="block font-display font-semibold text-base text-ink truncate">
                  {previewName}
                </span>
                <span className="block text-[10px] font-semibold uppercase tracking-wider text-muted/60 mt-0.5">
                  {t('workspaces_section')}
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-medium text-muted">
                {t('workspace_name_label')}
              </label>
              <input
                autoFocus
                value={name}
                onChange={(e) => setName(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && submit()}
                className="focus-ring bg-raised border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors"
              />
            </div>

            <WorkspaceStylePicker
              icon={icon}
              onIconChange={setIcon}
              color={color}
              onColorChange={setColor}
            />

            {error && <p className="text-xs text-danger">{error}</p>}
          </div>
    </ModalShell>

    <AnimatePresence>
      {confirmingDelete && (
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
      )}
    </AnimatePresence>
    </>
  )
}
