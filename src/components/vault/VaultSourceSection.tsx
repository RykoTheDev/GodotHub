import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Project, VaultFileEntry } from '../../types'
import { api } from '../../lib/api'
import { IconTrash } from '../../lib/icons'
import { ProjectPicker } from './ProjectPicker'
import { SelectableVaultFileTree } from './VaultFileTree'

interface Props {
  projects: Project[]
  projectId: string | null
  selected: Set<string>
  index: number
  canRemove: boolean
  onProjectChange: (id: string) => void
  onToggle: (rel: string) => void
  onRemove: () => void
}

export function VaultSourceSection({
  projects,
  projectId,
  selected,
  index,
  canRemove,
  onProjectChange,
  onToggle,
  onRemove,
}: Props) {
  const { t } = useTranslation('common')
  const [tree, setTree] = useState<VaultFileEntry[]>([])
  const [treeLoading, setTreeLoading] = useState(false)
  const [treeError, setTreeError] = useState<string | null>(null)

  const project = projects.find((p) => p.id === projectId) ?? null

  useEffect(() => {
    if (!project) {
      setTree([])
      return
    }
    setTreeLoading(true)
    setTreeError(null)
    api
      .getProjectFileTree(project.path)
      .then((entries) => setTree(entries as VaultFileEntry[]))
      .catch((e) => setTreeError(String(e)))
      .finally(() => setTreeLoading(false))
  }, [project])

  return (
    <div className="flex flex-col gap-2 rounded-item border border-outline/50 bg-overlay/40 p-3">
      <div className="flex items-center gap-2">
        <span className="text-[10px] font-mono uppercase text-muted/60 shrink-0">
          {t('vault_source_n', { index: index + 1 })}
        </span>
        <div className="flex-1 min-w-0">
          <ProjectPicker
            projects={projects}
            selectedId={projectId}
            onSelect={onProjectChange}
          />
        </div>
        {canRemove && (
          <button
            type="button"
            onClick={onRemove}
            aria-label={t('vault_remove_source')}
            className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
          >
            <IconTrash className="w-3.5 h-3.5" />
          </button>
        )}
      </div>

      {project && (
        <div className="flex flex-col gap-1.5">
          <div className="flex items-center justify-between">
            <label className="text-xs font-medium text-muted">
              {t('vault_select_files_label')}
            </label>
            <span className="text-[10px] text-muted/60 font-mono">
              {t('vault_selected_count', { count: selected.size })}
            </span>
          </div>
          <div className="rounded-item border border-outline/50 bg-base max-h-56 overflow-y-auto p-1">
            {treeLoading ? (
              <div className="flex items-center justify-center py-10 text-xs text-muted">
                {t('loading')}
              </div>
            ) : treeError ? (
              <div className="flex items-center justify-center py-10 text-xs text-danger">
                {treeError}
              </div>
            ) : tree.length === 0 ? (
              <div className="flex items-center justify-center py-10 text-xs text-muted">
                {t('vault_project_empty')}
              </div>
            ) : (
              <SelectableVaultFileTree
                entries={tree}
                selected={selected}
                onToggle={onToggle}
              />
            )}
          </div>
        </div>
      )}
    </div>
  )
}
