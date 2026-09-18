import { useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { ModalShell } from './ModalShell'
import { IconCopy, IconFolder } from '../../lib/icons'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import type { Project } from '../../types'

interface Props {
  project: Project
  onClose: () => void
  onDuplicated: () => void
}

function defaultDest(project: Project): string {
  const idx = project.path.lastIndexOf('/')
  const idxWin = project.path.lastIndexOf('\\')
  const cut = Math.max(idx, idxWin)
  return cut > 0 ? project.path.slice(0, cut) : project.path
}

export function DuplicateProjectModal({
  project,
  onClose,
  onDuplicated,
}: Props) {
  const { t } = useTranslation('common')
  const [name, setName] = useState(`${project.name} ${t('copy_suffix')}`)
  const [dest, setDest] = useState(defaultDest(project))
  const [busy, setBusy] = useState(false)

  const pickDest = async () => {
    const picked = await api.pickFolder()
    if (picked) setDest(picked)
  }

  const duplicate = async () => {
    const trimmed = name.trim()
    if (!trimmed || busy) return
    setBusy(true)
    try {
      await api.duplicateProject(project.id, trimmed, dest)
      pushToast('success', t('project_duplicated'))
      onDuplicated()
      onClose()
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconCopy className="w-5 h-5" />}
      title={t('duplicate_project_title')}
      description={t('duplicate_project_desc')}
      maxWidth="max-w-md"
      onClose={onClose}
      footer={
        <>
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors ml-auto"
          >
            {t('cancel')}
          </motion.button>
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={() => void duplicate()}
            disabled={!name.trim() || busy}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {t('duplicate')}
          </motion.button>
        </>
      }
    >
      <div className="flex flex-col gap-4 p-6 pt-0">
        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('new_project_name')}
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder={t('new_project_name')}
            className="focus-ring w-full bg-base border border-outline/50 rounded-item px-3 py-2 text-sm text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
          />
        </div>
        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">
            {t('destination_folder')}
          </label>
          <div className="flex gap-2">
            <div className="flex-1 min-w-0 flex items-center gap-2 px-3 py-2 rounded-item bg-base border border-outline/50">
              <IconFolder className="w-3.5 h-3.5 text-muted shrink-0" />
              <span className="text-xs font-mono text-ink truncate">{dest}</span>
            </div>
            <button
              type="button"
              onClick={() => void pickDest()}
              className="focus-ring cursor-pointer shrink-0 px-3 rounded-item bg-raised border border-outline/50 text-xs font-medium text-muted hover:text-ink hover:border-accent-dim transition-colors"
            >
              {t('browse')}
            </button>
          </div>
        </div>
      </div>
    </ModalShell>
  )
}