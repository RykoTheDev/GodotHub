import { invoke } from '@tauri-apps/api/core'
import type { WorkspacesState, WorkspaceScanDirs } from '../types'

export const workspacesApi = {
  list: () => invoke<WorkspacesState>('list_workspaces'),
  scanDirs: () => invoke<WorkspaceScanDirs[]>('list_workspace_scan_dirs'),
  create: (name: string, icon: string, color: string) =>
    invoke<WorkspacesState>('create_workspace', { name, icon, color }),
  switch: (id: string) =>
    invoke<WorkspacesState>('switch_workspace', { id }),
  update: (id: string, name: string | null, icon: string | null, color: string | null) =>
    invoke<WorkspacesState>('update_workspace', { id, name, icon, color }),
  delete: (id: string) =>
    invoke<WorkspacesState>('delete_workspace', { id }),
}
