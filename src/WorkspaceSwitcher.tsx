import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useWorkspaces } from './hooks/useWorkspaces'
import { IconPlus } from './components/Icons'
import { Tooltip } from './components/ui/Tooltip'
import { getWorkspaceIcon } from './lib/workspaceIcons'
import { CreateWorkspaceModal } from './components/modals/CreateWorkspaceModal'
import { WorkspaceEditModal } from './components/modals/WorkspaceEditModal'
import type { Workspace } from './types'

interface Props {
  collapsed: boolean
}

export function WorkspaceSwitcher({ collapsed }: Props) {
  const {
    workspaces,
    activeId,
    switchWorkspace,
    createWorkspace,
    renameWorkspace,
    updateWorkspaceStyle,
    deleteWorkspace,
  } = useWorkspaces()
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState<Workspace | null>(null)

  if (workspaces.length === 0) return null

  return (
    <>
      <div
        className={`flex flex-wrap gap-1.5 w-full ${collapsed ? 'justify-center' : ''}`}
      >
        {workspaces.map((w) => {
          const Icon = getWorkspaceIcon(w.icon)
          const active = w.id === activeId
          return (
            <Tooltip content={active ? `${w.name} (right-click to edit)` : w.name} side="right">
            <motion.button
              key={w.id}
              type="button"
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.94 }}
              onClick={() => switchWorkspace(w.id)}
              onContextMenu={(e) => {
                e.preventDefault()
                setEditing(w)
              }}
              aria-label={`Switch to ${w.name} workspace`}
              className={`focus-ring icon-wiggle cursor-pointer relative w-9 h-9 shrink-0 rounded-full flex items-center justify-center border-2 transition-all ${
                active
                  ? 'border-ink/70 shadow-sm'
                  : 'border-transparent opacity-60 hover:opacity-100'
              }`}
              style={{ backgroundColor: `${w.color}26` }}
            >
              <Icon className="w-3.5 h-3.5" style={{ color: w.color }} />
            </motion.button>
            </Tooltip>
          )
        })}
        <Tooltip content="Add workspace" side="right">
          <motion.button
            type="button"
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.94 }}
            onClick={() => setCreating(true)}
            aria-label="Add workspace"
            className="focus-ring cursor-pointer w-9 h-9 shrink-0 rounded-full flex items-center justify-center border-2 border-dashed border-line text-muted hover:text-ink hover:border-accent-dim transition-colors"
          >
            <IconPlus className="w-3 h-3" />
          </motion.button>
        </Tooltip>
      </div>

      <AnimatePresence>
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
            onClose={() => setEditing(null)}
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
              setEditing(null)
            }}
            onDelete={async () => {
              await deleteWorkspace(editing.id)
              setEditing(null)
            }}
          />
        )}
      </AnimatePresence>
    </>
  )
}
