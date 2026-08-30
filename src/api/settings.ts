import { invoke } from '@tauri-apps/api/core'
import type { AppSettings, Project, ScanResult, TimeInsights } from '../types'

export const settingsApi = {
  get: () => invoke<AppSettings>('get_settings'),
  update: (settings: AppSettings) =>
    invoke<AppSettings>('update_settings', { settings }),
  reset: () => invoke<AppSettings>('reset_settings'),
  exportSettings: (path: string) =>
    invoke<void>('export_settings', { path }),
  importSettings: (path: string) =>
    invoke<AppSettings>('import_settings', { path }),
  exportWorkspaceBackup: (path: string) =>
    invoke<void>('export_workspace_backup', { path }),
  importWorkspaceBackup: (path: string) =>
    invoke<AppSettings>('import_workspace_backup', { path }),
  exportAppBackup: (path: string) =>
    invoke<void>('export_app_backup', { path }),
  importAppBackup: (path: string) =>
    invoke<AppSettings>('import_app_backup', { path }),
  gistSyncPush: () =>
    invoke<{ gist_url: string; gist_id: string; pushed_at: string }>(
      'gist_sync_push',
    ),
  gistSyncPull: () => invoke<AppSettings>('gist_sync_pull'),
  gistSyncGetInfo: () =>
    invoke<{ gist_url: string; gist_id: string; pushed_at: string } | null>(
      'gist_sync_get_info',
    ),
  gistSyncPullByUrl: (gistUrl: string) =>
    invoke<AppSettings>('gist_sync_pull_by_url', { gistUrl }),
  gistSyncSaveGistUrl: (gistUrl: string) =>
    invoke<void>('gist_sync_save_gist_url', { gistUrl }),
  gistSyncFetchBackup: () =>
    invoke<{
      workspace_count: number
      workspace_names: string[]
      project_count: number
      category_count: number
      template_count: number
      has_time_stats: boolean
      version_scan_dirs: string[]
      project_scan_dirs: string[]
    }>('gist_sync_fetch_backup'),
  getTimeInsights: () =>
    invoke<TimeInsights>('get_time_insights'),
  resetData: () => invoke<void>('reset_app_data'),
  scanForProjects: (dirs: string[], depth: number) =>
    invoke<Project[]>('scan_for_projects', { dirs, depth }),
  scanForProjectsWithInfo: (dirs: string[], depth: number) =>
    invoke<ScanResult>('scan_for_projects_with_info', { dirs, depth }),
  refreshTrayMenu: () => invoke<void>('refresh_tray_menu'),
  restartWatchers: () => invoke<void>('restart_watchers'),
  getOsUsername: () => invoke<string | null>('get_os_username'),
}
