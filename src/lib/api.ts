import { invoke } from '@tauri-apps/api/core'

const iconCache = new Map<string, string | null>()
const nameCache = new Map<string, string | null>()
export function getCachedProjectIcon(path: string): string | null {
  const cached = iconCache.get(path)
  return cached !== undefined ? cached : null
}
export function getCachedProjectName(path: string): string | null {
  const cached = nameCache.get(path)
  return cached !== undefined ? cached : null
}
import type {
  AppSettings,
  Category,
  ChangelogEntry,
  ChangelogNote,
  GitBranchInfo,
  GitChangedFile,
  GitDiffResult,
  GitLogEntry,
  GitStashEntry,
  GitStatus,
  GodotRelease,
  InstalledGodotVersion,
  NewsResponse,
  Project,
  ProjectSizeInfo,
  ProjectTemplate,
  ProjectUpdate,
  TemplateFileEntry,
  TemplateSyncResult,
  WorkspacesState,
} from '../types'

export const api = {
  fetchAvailableGodotVersions: () =>
    invoke<GodotRelease[]>('fetch_available_godot_versions'),
  downloadGodotVersion: (tag: string, assetName: string, downloadUrl: string) =>
    invoke<void>('download_godot_version', { tag, assetName, downloadUrl }),
  pauseDownload: (key: string) => invoke<void>('pause_download', { key }),
  resumeDownload: (key: string) => invoke<void>('resume_download', { key }),
  cancelDownload: (key: string) => invoke<void>('cancel_download', { key }),
  listInstalledGodotVersions: () =>
    invoke<InstalledGodotVersion[]>('list_installed_godot_versions'),
  renameGodotVersion: (tag: string, customName: string | null) =>
    invoke<InstalledGodotVersion>('rename_godot_version', { tag, customName }),
  deleteGodotVersion: (tag: string) =>
    invoke<void>('delete_godot_version', { tag }),

  listProjects: () => invoke<Project[]>('list_projects'),
  createProject: (name: string, location: string, godotVersion: string, iconPath?: string | null, templateId?: string | null, category?: string | null) =>
    invoke<Project>('create_project', { name, location, godotVersion, iconPath: iconPath ?? null, templateId: templateId ?? null, category: category ?? null }),
  importProject: (path: string, godotVersion: string) =>
    invoke<Project>('import_project', { path, godotVersion }),
  removeProject: (id: string, deleteFiles: boolean) =>
    invoke<void>('remove_project', { id, deleteFiles }),
  updateProject: (id: string, updates: ProjectUpdate) =>
    invoke<Project>('update_project', { id, updates }),
  reorderProjects: (orderedIds: string[]) =>
    invoke<void>('reorder_projects', { orderedIds }),
  openProject: (id: string, editor: boolean) =>
    invoke<void>('open_project', { id, editor }),
  stopProject: (id: string) =>
    invoke<void>('stop_project', { id }),
  openProjectFolder: (path: string) =>
    invoke<void>('open_project_folder', { path }),
  openInEditor: (path: string) =>
    invoke<void>('open_in_editor', { path }),

  getProjectSize: (path: string) =>
    invoke<ProjectSizeInfo>('get_project_size', { path }),

  pickFolder: () => invoke<string | null>('pick_folder'),
  pickFile: () => invoke<string | null>('pick_file'),
  getProjectIcon: (path: string) => {
    const cached = iconCache.get(path)
    if (cached !== undefined) return Promise.resolve(cached)
    return invoke<string | null>('get_project_icon', { path })
      .then((data) => { iconCache.set(path, data); return data })
  },
  getProjectName: (path: string) => {
    const cached = nameCache.get(path)
    if (cached !== undefined) return Promise.resolve(cached)
    return invoke<string | null>('get_project_name', { path })
      .then((data) => { nameCache.set(path, data); return data })
  },
  clearProjectIconCache: () => { iconCache.clear() },
  clearProjectNameCache: () => { nameCache.clear() },
  cloneRepo: (url: string, dest: string) =>
    invoke<string>('clone_repo', { url, dest }),
  getGitStatus: (path: string) =>
    invoke<GitStatus>('get_git_status', { path }),
  batchGitStatus: (paths: string[]) =>
    invoke<Record<string, GitStatus>>('batch_git_status', { paths }),
  openTerminal: (path: string) =>
    invoke<void>('open_terminal', { path }),
  gitPull: (path: string) =>
    invoke<string>('git_pull', { path }),
  gitFetch: (path: string) =>
    invoke<string>('git_fetch', { path }),
  gitPush: (path: string, force?: boolean) =>
    invoke<string>('git_push', { path, force: force ?? false }),
  gitPushForce: (path: string) =>
    invoke<string>('git_push', { path, force: true }),
  gitLog: (path: string) =>
    invoke<void>('git_log', { path }),
  gitLogEntries: (path: string) =>
    invoke<GitLogEntry[]>('git_log_entries', { path }),
  gitRemoteUrl: (path: string) =>
    invoke<string>('git_remote_url', { path }),
  gitListBranches: (path: string) =>
    invoke<GitBranchInfo[]>('git_list_branches', { path }),
  gitSwitchBranch: (path: string, name: string) =>
    invoke<void>('git_switch_branch', { path, name }),
  gitCreateBranch: (path: string, name: string) =>
    invoke<void>('git_create_branch', { path, name }),
  gitDeleteBranch: (path: string, name: string) =>
    invoke<void>('git_delete_branch', { path, name }),
  gitStashPush: (path: string) =>
    invoke<string>('git_stash_push', { path }),
  gitStashList: (path: string) =>
    invoke<GitStashEntry[]>('git_stash_list', { path }),
  gitStashApply: (path: string, index: number) =>
    invoke<void>('git_stash_apply', { path, index }),
  gitStashDrop: (path: string, index: number) =>
    invoke<void>('git_stash_drop', { path, index }),
  gitChangedFiles: (path: string) =>
    invoke<GitChangedFile[]>('git_changed_files', { path }),
  gitDiscardChanges: (path: string) =>
    invoke<void>('git_discard_changes', { path }),
  gitInit: (path: string) =>
    invoke<string>('git_init', { path }),
  gitStageFile: (path: string, filePath: string) =>
    invoke<void>('git_stage_file', { path, filePath }),
  gitUnstageFile: (path: string, filePath: string) =>
    invoke<void>('git_unstage_file', { path, filePath }),
  gitCommit: (path: string, message: string, amend?: boolean) =>
    invoke<string>('git_commit', { path, message, amend: amend ?? false }),
  gitSetRemote: (path: string, url: string) =>
    invoke<void>('git_set_remote', { path, url }),
  gitRemoveRemote: (path: string) =>
    invoke<void>('git_remove_remote', { path }),
  gitFileDiff: (path: string, filePath: string) =>
    invoke<GitDiffResult>('git_file_diff', { path, filePath }),
  gitUndoCommit: (path: string) =>
    invoke<void>('git_undo_commit', { path }),
  gitUndoPull: (path: string) =>
    invoke<void>('git_undo_pull', { path }),
  validateGodotFolder: (path: string) =>
    invoke<{ name: string; icon: string | null } | null>(
      'validate_godot_folder',
      { path },
    ),
  getSettings: () => invoke<AppSettings>('get_settings'),
  updateSettings: (settings: AppSettings) =>
    invoke<AppSettings>('update_settings', { settings }),
  resetSettings: () => invoke<AppSettings>('reset_settings'),
  resetAppData: () => invoke<void>('reset_app_data'),
  exportSettings: () => invoke<string>('export_settings'),
  importSettings: () => invoke<AppSettings>('import_settings'),
  scanForProjects: (dirs: string[], depth: number) =>
    invoke<Project[]>('scan_for_projects', { dirs, depth }),
  scanForVersions: (dirs: string[], depth: number) =>
    invoke<InstalledGodotVersion[]>('scan_for_versions', { dirs, depth }),
  importVersion: (path: string) =>
    invoke<InstalledGodotVersion[]>('import_version', { path }),
  importVersionZip: (zipPath: string) =>
    invoke<InstalledGodotVersion>('import_version_zip', { zipPath }),

  listTemplates: () => invoke<ProjectTemplate[]>('list_templates'),
  saveProjectAsTemplate: (projectId: string, name: string, description: string) =>
    invoke<ProjectTemplate>('save_project_as_template', { projectId, name, description }),
  deleteTemplate: (templateId: string) =>
    invoke<void>('delete_template', { templateId }),
  getTemplatePreview: (templateId: string) =>
    invoke<TemplateFileEntry[]>('get_template_preview', { templateId }),
  syncTemplatesWithScanDir: () =>
    invoke<TemplateSyncResult>('sync_templates_with_scan_dir'),
  restartWatchers: () => invoke<void>('restart_watchers'),
  refreshTrayMenu: () => invoke<void>('refresh_tray_menu'),

  fetchGodotNews: () => invoke<NewsResponse>('fetch_godot_news'),

  listCategories: () => invoke<Category[]>('list_categories'),
  createCategory: (name: string, color?: string) =>
    invoke<Category>('create_category', { name, color: color ?? null }),
  renameCategory: (id: string, name: string) =>
    invoke<Category>('rename_category', { id, name }),
  updateCategory: (id: string, name?: string | null, color?: string | null) =>
    invoke<Category>('update_category', { id, name: name ?? null, color: color ?? null }),
  deleteCategory: (id: string) => invoke<void>('delete_category', { id }),
  reorderCategories: (orderedIds: string[]) =>
    invoke<void>('reorder_categories', { orderedIds }),

  listChangelogEntries: () =>
    invoke<ChangelogEntry[]>('list_changelog_entries'),
  addChangelogEntry: (version: string, date: string, notes: ChangelogNote[]) =>
    invoke<ChangelogEntry>('add_changelog_entry', { version, date, notes }),
  updateChangelogEntry: (
    id: string,
    version: string,
    date: string,
    notes: ChangelogNote[],
  ) =>
    invoke<ChangelogEntry>('update_changelog_entry', {
      id,
      version,
      date,
      notes,
    }),
  deleteChangelogEntry: (id: string) =>
    invoke<void>('delete_changelog_entry', { id }),

  listWorkspaces: () => invoke<WorkspacesState>('list_workspaces'),
  createWorkspace: (name: string, icon: string, color: string) =>
    invoke<WorkspacesState>('create_workspace', { name, icon, color }),
  switchWorkspace: (id: string) =>
    invoke<WorkspacesState>('switch_workspace', { id }),
  updateWorkspace: (
    id: string,
    name: string | null,
    icon: string | null,
    color: string | null,
  ) => invoke<WorkspacesState>('update_workspace', { id, name, icon, color }),
  deleteWorkspace: (id: string) =>
    invoke<WorkspacesState>('delete_workspace', { id }),
}
