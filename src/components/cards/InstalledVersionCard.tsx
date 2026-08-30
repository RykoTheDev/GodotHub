import { useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { InstalledGodotVersion } from '../../types'
import { api } from '../../lib/api'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { OpenButton } from '../reusables/OpenButton'
import {
  IconCheck,
  IconExternalLink,
  IconPencil,
  IconRocket,
  IconTerminal,
  IconTrash,
} from '../../lib/icons'

interface InstalledVersionCardProps {
  version: InstalledGodotVersion
  onOpen: (console?: boolean) => void
  onRename: (name: string | null) => void
  onUninstall: () => void
}

export function InstalledVersionCard({
  version: v,
  onOpen,
  onRename,
  onUninstall,
}: InstalledVersionCardProps) {
  const { t: tc } = useTranslation('common')
  const { t: tv } = useTranslation('versions')

  const [editing, setEditing] = useState(false)
  const [editValue, setEditValue] = useState('')
  const editInputRef = useRef<HTMLInputElement>(null)
  const [confirmingUninstall, setConfirmingUninstall] = useState(false)

  const startEditing = () => {
    setEditing(true)
    setEditValue(v.custom_name ?? v.tag)
    requestAnimationFrame(() => editInputRef.current?.focus())
  }

  const commitEdit = () => {
    if (editing) {
      const trimmed = editValue.trim()
      onRename(trimmed || null)
    }
    setEditing(false)
    setEditValue('')
  }

  const cancelEdit = () => {
    setEditing(false)
    setEditValue('')
  }

  const installedDir = (path?: string) =>
    path ? path.replace(/[/\\][^/\\]*$/, '') : null

  const openInstallFolder = () => {
    const dir = installedDir(v.executable_path)
    if (dir) api.openProjectFolder(dir).catch(() => {})
  }

  return (
    <div className="group relative flex items-center gap-3.5 p-3.5 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 transition-colors">
      <div className="min-w-0 flex-1">
        {editing ? (
          <div className="flex items-center gap-1.5">
            <input
              ref={editInputRef}
              type="text"
              value={editValue}
              onChange={(e) => setEditValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') commitEdit()
                if (e.key === 'Escape') cancelEdit()
              }}
              onBlur={commitEdit}
              className="focus-ring w-48 bg-raised border border-accent rounded-btn px-3 py-2 text-sm font-mono text-ink outline-none"
            />
            <motion.button
              type="button"
              whileTap={{ scale: 0.92 }}
              onClick={commitEdit}
              aria-label={tc('version_save_name_aria')}
              className="focus-ring cursor-pointer p-1.5 rounded-btn text-accent hover:bg-accent/10 transition-colors"
            >
              <IconCheck className="w-4 h-4" />
            </motion.button>
          </div>
        ) : (
          <>
            <div className="min-w-0">
              <div className="flex items-center gap-1.5 flex-wrap min-w-0">
                <h3 className="font-display font-medium text-xl text-ink truncate">
                  {v.custom_name || v.tag}
                </h3>
                  <motion.button
                    type="button"
                    whileTap={{ scale: 0.92 }}
                    onClick={startEditing}
                    aria-label={tc('version_rename_aria')}
                    className="focus-ring cursor-pointer p-1 rounded-btn text-muted/60 hover:text-ink hover:bg-raised transition-colors shrink-0"
                  >
                    <IconPencil className="w-3.5 h-3.5" />
                  </motion.button>
                <span
                  className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-tag text-[10px] font-semibold shrink-0 border ${
                    v.is_mono
                      ? 'bg-accent/10 text-accent-bright border-accent-dim/40'
                      : 'bg-black/15 text-muted border-outline/40'
                  }`}
                >
                  {v.is_mono ? tv('mono') : tv('standard')}
                </span>
                {v.supports_console && (
                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-tag bg-mint/10 text-mint border border-mint/30 text-[10px] font-semibold shrink-0">
                    {tv('console_label')}
                  </span>
                )}
              </div>
              {v.custom_name && v.custom_name !== v.tag && (
                <p className="text-xs font-mono text-muted truncate mt-1">
                  {tv('original_name')}: {v.tag}
                </p>
              )}
            </div>
          </>
        )}
      </div>

      <OpenButton
        label={tv('open')}
        onOpen={onOpen}
        consoleSupported={v.supports_console}
        moreAriaLabel={tv('more_editor_launch_options')}
        items={[
          {
            key: 'rename',
            label: tv('rename'),
            icon: IconPencil,
            onClick: startEditing,
          },
          {
            key: 'open',
            label: tv('open_editor'),
            icon: IconRocket,
            onClick: () => onOpen(),
          },
          ...(v.supports_console
            ? [
                {
                  key: 'open-console',
                  label: tv('open_editor_with_console'),
                  icon: IconTerminal,
                  onClick: () => onOpen(true),
                },
              ]
            : []),
          {
            key: 'folder',
            label: tv('open_install_folder'),
            icon: IconExternalLink,
            onClick: openInstallFolder,
          },
          {
            key: 'uninstall',
            label: tv('uninstall'),
            icon: IconTrash,
            danger: true,
            dividerAfter: true,
            onClick: () => setConfirmingUninstall(true),
          },
        ]}
      />

      <AnimatePresence>
        {confirmingUninstall && (
          <ConfirmDialog
            title={tc('version_uninstall_title')}
            description={tc('version_uninstall_desc', { tag: v.tag })}
            confirmLabel={tc('version_uninstall_confirm')}
            variant="danger"
            onConfirm={() => {
              setConfirmingUninstall(false)
              onUninstall()
            }}
            onCancel={() => setConfirmingUninstall(false)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
