import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Project, VaultItem, VaultProjectImportResult } from '../../types'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import { ModalShell } from '../modals/ModalShell'
import { IconFolderPlus, IconAlertTriangle, IconCheck, IconFolder } from '../../lib/icons'

interface Props {
  item: VaultItem
  projects: Project[]
  onClose: () => void
}

export function AddVaultItemModal({ item, projects, onClose }: Props) {
  const { t } = useTranslation('common')
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [busy, setBusy] = useState(false)
  const [conflicts, setConflicts] = useState<VaultProjectImportResult[] | null>(
    null,
  )

  const toggleProject = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const conflictProjects = (conflicts ?? []).filter(
    (r) => r.conflicts.length > 0,
  )
  const totalConflicts = conflictProjects.reduce(
    (sum, r) => sum + r.conflicts.length,
    0,
  )

  const projectName = (id: string) =>
    projects.find((p) => p.id === id)?.name ?? id

  const finish = (results: VaultProjectImportResult[]) => {
    const count = results.filter((r) => !r.skipped).length
    pushToast('success', t('vault_added_to_projects_toast', { count }))
    onClose()
  }

  const runAdd = async (overwrite: boolean) => {
    const ids = [...selectedIds]
    if (ids.length === 0 || busy) return
    setBusy(true)
    try {
      const results = await api.addVaultItemToProjects(item.id, ids, overwrite)
      if (!overwrite) {
        const withConflicts = results.filter((r) => r.conflicts.length > 0)
        if (withConflicts.length > 0) {
          setConflicts(results)
          return
        }
        const applied = await api.addVaultItemToProjects(item.id, ids, true)
        finish(applied)
        return
      }
      finish(results)
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconFolderPlus className="w-4 h-4" />}
      title={t('vault_add_title')}
      description={t('vault_add_desc', { name: item.name })}
      maxWidth="max-w-md"
      onClose={onClose}
      footer={
        conflicts ? (
          <>
            <button
              type="button"
              onClick={() => setConflicts(null)}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-item text-xs font-medium text-muted hover:text-ink hover:bg-raised "
            >
              {t('cancel')}
            </button>
            <button
              type="button"
              onClick={() => void runAdd(true)}
              disabled={busy}
              className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-item bg-danger hover:bg-danger/90 disabled:opacity-50 disabled:cursor-not-allowed text-xs font-semibold text-white "
            >
              {busy ? t('vault_adding') : t('vault_overwrite_btn')}
            </button>
          </>
        ) : (
          <>
            <button
              type="button"
              onClick={onClose}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-item text-xs font-medium text-muted hover:text-ink hover:bg-raised "
            >
              {t('cancel')}
            </button>
            <button
              type="button"
              onClick={() => void runAdd(false)}
              disabled={selectedIds.size === 0 || busy}
              className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-xs font-semibold text-white "
            >
              {busy ? t('vault_adding') : t('vault_add_btn')}
            </button>
          </>
        )
      }
    >
      <div className="p-6 pt-4 flex flex-col gap-4">
        {conflicts ? (
          <div className="flex flex-col gap-3">
            <div className="flex items-start gap-2.5 rounded-item border border-danger/30 bg-danger/10 p-3">
              <IconAlertTriangle className="w-4 h-4 text-danger shrink-0 mt-0.5" />
              <p className="text-xs text-ink leading-relaxed">
                {t('vault_conflict_summary_desc', { count: totalConflicts })}
              </p>
            </div>
            <div className="rounded-item border border-outline/50 bg-base max-h-56 overflow-y-auto p-2 flex flex-col gap-2">
              {conflictProjects.map((result) => (
                <div key={result.project_id} className="flex flex-col gap-0.5">
                  <span className="text-2xs font-semibold text-ink px-1">
                    {projectName(result.project_id)}
                  </span>
                  {result.conflicts.map((path) => (
                    <span
                      key={path}
                      className="text-2xs font-mono text-muted truncate px-1 py-0.5 ps-3"
                    >
                      {path}
                    </span>
                  ))}
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            <div className="flex items-center justify-between">
              <label className="text-xs font-medium text-muted">
                {t('vault_target_projects_label')}
              </label>
              <span className="text-3xs text-muted/60 font-mono">
                {t('vault_selected_count', { count: selectedIds.size })}
              </span>
            </div>
            <div className="rounded-item border border-outline/50 bg-base max-h-64 overflow-y-auto p-1 flex flex-col">
              {projects.length === 0 ? (
                <div className="flex items-center justify-center py-10 text-xs text-muted">
                  {t('vault_select_project')}
                </div>
              ) : (
                projects.map((p) => {
                  const checked = selectedIds.has(p.id)
                  return (
                    <button
                      key={p.id}
                      type="button"
                      onClick={() => toggleProject(p.id)}
                      aria-pressed={checked}
                      className="focus-ring cursor-pointer flex items-center gap-2 px-2 py-1.5 rounded-item text-xs hover:bg-raised/60 text-start"
                    >
                      <span
                        className={`shrink-0 w-4 h-4 rounded-[5px] border flex items-center justify-center  ${
                          checked
                            ? 'bg-accent border-accent text-white'
                            : 'bg-base border-outline/60'
                        }`}
                      >
                        {checked && <IconCheck className="w-3 h-3" />}
                      </span>
                      <IconFolder className="w-3.5 h-3.5 text-muted shrink-0" />
                      <span
                        className={`flex-1 min-w-0 truncate ${
                          checked ? 'text-ink' : 'text-muted'
                        }`}
                      >
                        {p.name}
                      </span>
                    </button>
                  )
                })
              )}
            </div>
          </div>
        )}
      </div>
    </ModalShell>
  )
}
