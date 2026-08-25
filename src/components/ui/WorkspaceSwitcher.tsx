import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { useWorkspaces } from '../../hooks/useWorkspaces'
import { getWorkspaceIcon } from '../../lib/workspaceIcons'
import {
  IconCheck,
  IconChevronDown,
  IconPencil,
  IconPlus,
} from '../../lib/icons'
import { CreateWorkspaceModal } from '../modals/CreateWorkspaceModal'
import { WorkspaceEditModal } from '../modals/WorkspaceEditModal'
import type { Workspace } from '../../types'

const GAP = 8
const EDGE_PADDING = 8
const MENU_WIDTH = 232
const OPEN_UP_THRESHOLD = 300

export function WorkspaceSwitcher({ collapsed = false }: { collapsed?: boolean }) {
  const { t } = useTranslation('common')
  const {
    workspaces,
    activeId,
    switchWorkspace,
    createWorkspace,
    renameWorkspace,
    updateWorkspaceStyle,
    deleteWorkspace,
  } = useWorkspaces()
  const [open, setOpen] = useState(false)
  const [dir, setDir] = useState(false)
  const [pos, setPos] = useState<{ left: number; top: number } | null>(null)
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState<Workspace | null>(null)
  const ref = useRef<HTMLDivElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        if (listRef.current?.contains(e.target as Node)) return
        setOpen(false)
      }
    }
    const keyHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    document.addEventListener('keydown', keyHandler)
    return () => {
      document.removeEventListener('mousedown', handler)
      document.removeEventListener('keydown', keyHandler)
    }
  }, [])

  useEffect(() => {
    const openCreate = () => setCreating(true)
    window.addEventListener('app:create-workspace-request', openCreate)
    return () =>
      window.removeEventListener('app:create-workspace-request', openCreate)
  }, [])

  const measure = useCallback(() => {
    const el = ref.current
    if (!el || !listRef.current) return
    const r = el.getBoundingClientRect()
    const spaceBelow = window.innerHeight - r.bottom
    const d = spaceBelow < OPEN_UP_THRESHOLD
    const h = listRef.current.offsetHeight
    setDir(d)
    setPos({
      left: Math.max(EDGE_PADDING, r.left),
      top: Math.max(EDGE_PADDING, d ? r.top - h - GAP : r.bottom + GAP),
    })
  }, [])

  useLayoutEffect(() => {
    if (open) measure()
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    const reposition = () => measure()
    window.addEventListener('scroll', reposition, true)
    window.addEventListener('resize', reposition)
    return () => {
      window.removeEventListener('scroll', reposition, true)
      window.removeEventListener('resize', reposition)
    }
  }, [open, measure])

  const active = workspaces.find((w) => w.id === activeId) ?? workspaces[0]
  if (!active) return null

  const ActiveIcon = getWorkspaceIcon(active.icon)

  const pick = (w: Workspace) => {
    const Icon = getWorkspaceIcon(w.icon)
    return (
      <span
        className="w-5 h-5 rounded-full flex items-center justify-center border shrink-0"
        style={{
          backgroundColor: `${w.color}26`,
          borderColor: `${w.color}55`,
        }}
      >
        <Icon className="w-2.5 h-2.5" style={{ color: w.color }} />
      </span>
    )
  }

  return (
    <>
      <div ref={ref} className="w-full">
        <button
          type="button"
          onClick={() => setOpen((o) => !o)}
          aria-label={t('switch_workspace')}
          aria-expanded={open}
          aria-haspopup="menu"
          className={`focus-ring cursor-pointer w-full flex items-center gap-2 rounded-item text-sm font-medium border border-transparent transition-colors hover:bg-raised/60 hover:text-ink ${
            collapsed ? 'w-11 h-11 shrink-0 justify-center' : 'px-3 py-2.5'
          } ${open ? 'text-ink bg-raised/60' : 'text-muted'}`}
        >
          <span
            className="w-6 h-6 rounded-full flex items-center justify-center border shrink-0"
            style={{
              backgroundColor: `${active.color}26`,
              borderColor: `${active.color}55`,
            }}
          >
            <ActiveIcon className="w-3 h-3" style={{ color: active.color }} />
          </span>
          {!collapsed && (
            <>
              <span className="truncate">{active.name}</span>
              <IconChevronDown
                className={`w-3.5 h-3.5 ml-auto shrink-0 transition-transform duration-200 ${
                  open ? 'rotate-180' : ''
                }`}
              />
            </>
          )}
        </button>
      </div>

      {createPortal(
        <AnimatePresence>
          {open && (
            <motion.div
              ref={listRef}
              initial={{ opacity: 0, y: dir ? 6 : -6, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: dir ? 6 : -6, scale: 0.96 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              role="menu"
              className={`fixed z-50 ${
                dir ? 'origin-bottom' : 'origin-top'
              } rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-1.5`}
              style={{ left: pos?.left, top: pos?.top, width: MENU_WIDTH }}
            >
              <div className="px-2.5 pt-1.5 pb-1 text-[10px] font-semibold uppercase tracking-wider text-muted/50">
                {t('current_workspace')}
              </div>
              {workspaces.map((w) => {
                const isActive = w.id === activeId
                return (
                  <button
                    key={w.id}
                    type="button"
                    role="menuitem"
                    onClick={() => {
                      switchWorkspace(w.id)
                      setOpen(false)
                    }}
                    onContextMenu={(e) => {
                      e.preventDefault()
                      setOpen(false)
                      setEditing(w)
                    }}
                    className={`focus-ring cursor-pointer w-full flex items-center gap-2 text-left px-2.5 py-2 rounded-item text-xs transition-colors ${
                      isActive
                        ? 'bg-accent/15 text-accent-bright'
                        : 'text-muted hover:bg-raised hover:text-ink'
                    }`}
                  >
                    {pick(w)}
                    <span className="truncate">{w.name}</span>
                    {isActive && <IconCheck className="w-3.5 h-3.5 ml-auto shrink-0" />}
                  </button>
                )
              })}

              <div className="mt-1 pt-1.5 border-t border-outline/40 flex flex-col gap-0.5">
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => {
                    setCreating(true)
                    setOpen(false)
                  }}
                  className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs text-muted hover:bg-raised hover:text-ink transition-colors"
                >
                  <IconPlus className="w-3.5 h-3.5 shrink-0" />
                  {t('create_workspace')}
                </button>
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => {
                    setEditing(active)
                    setOpen(false)
                  }}
                  className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs text-muted hover:bg-raised hover:text-ink transition-colors"
                >
                  <IconPencil className="w-3.5 h-3.5 shrink-0" />
                  {t('edit_workspace_title')}
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}

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
      </AnimatePresence>

      <AnimatePresence>
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
