import { invoke } from '@tauri-apps/api/core'
import type {
  AliasBatchResult,
  AliasRequest,
  CurrentVersionInfo,
  GodotRelease,
  InstalledGodotVersion,
  VersionAliases,
} from '../types'

export const versionsApi = {
  fetchAvailable: (source?: string) =>
    invoke<GodotRelease[]>('fetch_available_godot_versions', {
      source: source ?? 'github',
    }),
  download: (tag: string, assetName: string, downloadUrl: string) =>
    invoke<void>('download_godot_version', { tag, assetName, downloadUrl }),
  pauseDownload: (key: string) => invoke<void>('pause_download', { key }),
  resumeDownload: (key: string) => invoke<void>('resume_download', { key }),
  cancelDownload: (key: string) => invoke<void>('cancel_download', { key }),
  reorderDownloadQueue: (key: string, direction: number) =>
    invoke<void>('reorder_download_queue', { key, direction }),
  listInstalled: () =>
    invoke<InstalledGodotVersion[]>('list_installed_godot_versions'),
  rename: (tag: string, customName: string | null) =>
    invoke<InstalledGodotVersion>('rename_godot_version', { tag, customName }),
  delete: (tag: string) =>
    invoke<void>('delete_godot_version', { tag }),
  getCurrent: () => invoke<CurrentVersionInfo | null>('get_current_version'),
  setCurrent: (tag: string) =>
    invoke<CurrentVersionInfo>('set_current_version', { tag }),
  clearCurrent: () => invoke<void>('clear_current_version'),
  listAliases: () => invoke<VersionAliases>('list_version_aliases'),
  createAliases: (entries: AliasRequest[]) =>
    invoke<AliasBatchResult>('create_version_aliases', { entries }),
  deleteAlias: (name: string) =>
    invoke<void>('delete_version_alias', { name }),
  open: (tag: string, withConsole?: boolean) =>
    invoke<void>('open_godot_version', { tag, console: withConsole ?? null }),
  import: (path: string) =>
    invoke<InstalledGodotVersion[]>('import_version', { path }),
  importZip: (zipPath: string) =>
    invoke<InstalledGodotVersion>('import_version_zip', { zipPath }),
  scan: (dirs: string[], depth: number) =>
    invoke<InstalledGodotVersion[]>('scan_for_versions', { dirs, depth }),
  validateFolder: (path: string) =>
    invoke<{ name: string; icon: string | null } | null>('validate_godot_folder', { path }),
  testGithubToken: () =>
    invoke<{ remaining: number; limit: number; reset_at: number; used_token: boolean }>('test_github_token'),
  getGithubRateLimit: () =>
    invoke<{ remaining: number; limit: number; reset_at: number; used_token: boolean }>('get_github_rate_limit'),
}
