import { invoke } from '@tauri-apps/api/core'

export const updatesApi = {
  isPortableInstall: () => invoke<boolean>('is_portable_install'),
}
