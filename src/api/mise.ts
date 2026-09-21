import { invoke } from '@tauri-apps/api/core'
import type { InstalledGodotVersion, MiseStatus } from '../types'

export const miseApi = {
  status: () => invoke<MiseStatus>('mise_status'),
  syncVersions: () =>
    invoke<InstalledGodotVersion[]>('mise_sync_godot_versions'),
  install: (tag: string) =>
    invoke<InstalledGodotVersion[]>('mise_install_godot_version', { tag }),
  uninstall: (tag: string) =>
    invoke<void>('mise_uninstall_godot_version', { tag }),
}
