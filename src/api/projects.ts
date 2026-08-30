import { invoke } from '@tauri-apps/api/core'
import type { Project, ProjectSizeInfo, ProjectUpdate } from '../types'

const iconCache = new Map<string, string | null>()
const nameCache = new Map<string, string | null>()

let resolutionEpoch = 0
const epochListeners = new Set<() => void>()

export function getResolutionEpoch(): number {
  return resolutionEpoch
}

export function subscribeResolutionEpoch(listener: () => void): () => void {
  epochListeners.add(listener)
  return () => {
    epochListeners.delete(listener)
  }
}

function bumpResolutionEpoch() {
  resolutionEpoch += 1
  epochListeners.forEach((l) => l())
}

export function getCachedProjectIcon(path: string): string | null {
  const cached = iconCache.get(path)
  return cached !== undefined ? cached : null
}

export function getCachedProjectName(path: string): string | null {
  const cached = nameCache.get(path)
  return cached !== undefined ? cached : null
}

export const projectsApi = {
  list: () => invoke<Project[]>('list_projects'),
  create: (name: string, location: string, godotVersion: string, iconPath?: string | null, templateId?: string | null, category?: string | null) =>
    invoke<Project>('create_project', { name, location, godotVersion, iconPath: iconPath ?? null, templateId: templateId ?? null, category: category ?? null }),
  remove: (id: string, deleteFiles: boolean) =>
    invoke<void>('remove_project', { id, deleteFiles }),
  update: (id: string, updates: ProjectUpdate) =>
    invoke<Project>('update_project', { id, updates }),
  reorder: (orderedIds: string[]) =>
    invoke<void>('reorder_projects', { orderedIds }),
  saveTags: (id: string, path: string, tags: string[]) =>
    invoke<Project>('write_project_tags', { id, path, tags }),
  import: (path: string, godotVersion: string, category?: string | null) =>
    invoke<Project>('import_project', { path, godotVersion, category: category ?? null }),
  open: (id: string, editor: boolean, withConsole?: boolean) =>
    invoke<void>('open_project', { id, editor, console: withConsole ?? null }),
  stop: (id: string) =>
    invoke<void>('stop_project', { id }),
  openFolder: (path: string) =>
    invoke<void>('open_project_folder', { path }),
  openInEditor: (path: string) =>
    invoke<void>('open_in_editor', { path }),
  getSize: (path: string) =>
    invoke<ProjectSizeInfo>('get_project_size', { path }),
  getFileTree: (path: string) =>
    invoke<Array<{ path: string; is_dir: boolean; size: number }>>('get_project_file_tree', { path }),
  pickFolder: () => invoke<string | null>('pick_folder'),
  pickFile: () => invoke<string | null>('pick_file'),
  pickSavePath: (defaultName: string) =>
    invoke<string | null>('pick_save_path', { defaultName }),
  pickDataFile: () => invoke<string | null>('pick_data_file'),
  exportProjectStats: (path: string) =>
    invoke<void>('export_project_stats', { path }),
  importProjectStats: (path: string) =>
    invoke<number>('import_project_stats', { path }),
  clearTimeStats: () => invoke<void>('clear_time_stats'),
  readImageFile: (path: string) =>
    invoke<string | null>('read_image_file', { path }),
  getIcon: (path: string) => {
    const cached = iconCache.get(path)
    if (cached !== undefined) return Promise.resolve(cached)
    return invoke<string | null>('get_project_icon', { path })
      .then((data) => { iconCache.set(path, data); return data })
  },
  getName: (path: string) => {
    const cached = nameCache.get(path)
    if (cached !== undefined) return Promise.resolve(cached)
    return invoke<string | null>('get_project_name', { path })
      .then((data) => { nameCache.set(path, data); return data })
  },
  reintroduceDismissed: (paths: string[]) =>
    invoke<Project[]>('reintroduce_dismissed_projects', { paths }),
  clearIconCache: () => { iconCache.clear(); bumpResolutionEpoch() },
  clearNameCache: () => { nameCache.clear(); bumpResolutionEpoch() },
}
