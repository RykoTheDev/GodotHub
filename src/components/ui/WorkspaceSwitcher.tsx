import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useWorkspaces } from '../../hooks/useWorkspaces'
import { getWorkspaceIcon } from '../../lib/workspaceIcons'
import { IconPencil, IconPlus } from '../../lib/icons'
import { CreateWorkspaceModal } from '../modals/CreateWorkspaceModal'
import { WorkspaceEditModal } from '../modals/WorkspaceEditModal'
import type { Workspace } from '../../types'
import type { MenuItem } from './menu'

const requestEdit = (id: string) =>
  window.dispatchEvent(new CustomEvent('app:edit-workspace-request', { detail: id }))

const requestCreate = () => window.dispatchEvent(new CustomEvent('app:create-workspace-request'))

function WorkspaceBadge({ workspace }: { workspace: Workspace }) {
  const Icon = getWorkspaceIcon(workspace.icon)
  return (
    <span
      className="w-6 h-6 rounded-full flex items-center justify-center border shrink-0"
      style={{
        backgroundColor: `${workspace.color}26`,
        borderColor: `${workspace.color}55`,
      }}
    >
      <Icon className="w-3 h-3" style={{ color: workspace.color }} />
    </span>
  )
}

function MenuBadge({ workspace }: { workspace: Workspace }) {
  return (
    <span className="w-7 h-7 flex items-center justify-center">
      <WorkspaceBadge workspace={workspace} />
    </span>
  )
}

export function useWorkspaceMenuItem(): MenuItem | null {
  const { t } = useTranslation('common')
  const { workspaces, activeId, switchWorkspace } = useWorkspaces()
  const active = workspaces.find((w) => w.id === activeId) ?? workspaces[0]
  if (!active) return null

  return {
    key: 'workspace',
    label: active.name,
    leading: <MenuBadge workspace={active} />,
    dividerAfter: true,
    action: { icon: IconPencil, label: t('edit_workspace_title'), onClick: () => requestEdit(active.id) },
    children: [
      ...workspaces.map((w, index) => ({
        key: w.id,
        label: w.name,
        leading: <MenuBadge workspace={w} />,
        active: w.id === active.id,
        dividerAfter: index === workspaces.length - 1,
        onClick: () => switchWorkspace(w.id),
      })),
      { key: 'create', label: t('create_workspace'), icon: IconPlus, onClick: requestCreate },
    ],
  }
}

export function WorkspaceModals() {
  const {
    workspaces,
    createWorkspace,
    renameWorkspace,
    updateWorkspaceStyle,
    deleteWorkspace,
  } = useWorkspaces()
  const [creating, setCreating] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const editing = workspaces.find((w) => w.id === editingId) ?? null

  useEffect(() => {
    const openCreate = () => setCreating(true)
    const openEdit = (e: Event) => {
      const id = (e as CustomEvent).detail
      if (typeof id === 'string') setEditingId(id)
    }
    window.addEventListener('app:create-workspace-request', openCreate)
    window.addEventListener('app:edit-workspace-request', openEdit)
    return () => {
      window.removeEventListener('app:create-workspace-request', openCreate)
      window.removeEventListener('app:edit-workspace-request', openEdit)
    }
  }, [])

  return (
    <>

        {creating && (
          <CreateWorkspaceModal
            onClose={() => setCreating(false)}
            onCreate={async (name, icon, color) => {
              await createWorkspace(name, icon, color)
              setCreating(false)
            }}
          />
        )}



        {editing && (
          <WorkspaceEditModal
            workspace={editing}
            canDelete={workspaces.length > 1}
            onClose={() => setEditingId(null)}
            onSave={async (name, icon, color) => {
              const renamed =
                name.trim() !== editing.name
                  ? renameWorkspace(editing.id, name)
                  : Promise.resolve()
              const restyled =
                icon !== editing.icon || color !== editing.color
                  ? updateWorkspaceStyle(editing.id, icon, color)
                  : Promise.resolve()
              await Promise.all([renamed, restyled])
              setEditingId(null)
            }}
            onDelete={async () => {
              await deleteWorkspace(editing.id)
              setEditingId(null)
            }}
          />
        )}

    </>
  )
}
