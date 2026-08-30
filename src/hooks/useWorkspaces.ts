import {
  createContext,
  createElement,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import { api } from '../lib/api'
import { flushPendingSave } from '../lib/pendingSave'
import type { Workspace, WorkspacesState } from '../types'

interface WorkspacesContextValue {
  workspaces: Workspace[]
  activeId: string
  loaded: boolean
  refresh: () => Promise<void>
  switchWorkspace: (id: string) => Promise<void>
  createWorkspace: (name: string, icon: string, color: string) => Promise<void>
  renameWorkspace: (id: string, name: string) => Promise<void>
  updateWorkspaceStyle: (
    id: string,
    icon: string,
    color: string,
  ) => Promise<void>
  deleteWorkspace: (id: string) => Promise<void>
}

const WorkspacesContext = createContext<WorkspacesContextValue | null>(null)

export function WorkspacesProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<WorkspacesState>({
    workspaces: [],
    active_id: '',
  })
  const [loaded, setLoaded] = useState(false)

  useEffect(() => {
    api
      .listWorkspaces()
      .then((s) => setState(s))
      .catch(() => {})
      .finally(() => setLoaded(true))
  }, [])

  const refresh = async () => {
    const s = await api.listWorkspaces()
    setState(s)
  }

  const switchWorkspace = async (id: string) => {
    if (id === state.active_id) return
    await flushPendingSave()
    setState(await api.switchWorkspace(id))
  }

  const createWorkspace = async (name: string, icon: string, color: string) => {
    await flushPendingSave()
    setState(await api.createWorkspace(name, icon, color))
  }

  const renameWorkspace = async (id: string, name: string) => {
    setState(await api.updateWorkspace(id, name, null, null))
  }

  const updateWorkspaceStyle = async (
    id: string,
    icon: string,
    color: string,
  ) => {
    setState(await api.updateWorkspace(id, null, icon, color))
  }

  const deleteWorkspace = async (id: string) => {
    await flushPendingSave()
    setState(await api.deleteWorkspace(id))
  }

  return createElement(
    WorkspacesContext.Provider,
    {
      value: {
        workspaces: state.workspaces,
        activeId: state.active_id,
        loaded,
        refresh,
        switchWorkspace,
        createWorkspace,
        renameWorkspace,
        updateWorkspaceStyle,
        deleteWorkspace,
      },
    },
    children,
  )
}

export function useWorkspaces() {
  const ctx = useContext(WorkspacesContext)
  if (!ctx)
    throw new Error(
      'useWorkspaces() must be used within a <WorkspacesProvider>',
    )
  return ctx
}
