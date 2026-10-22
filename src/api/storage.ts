import { invoke } from '@tauri-apps/api/core'
import type { ReclaimItem, ReclaimResult, StorageReport } from '../types'

export const storageApi = {
  report: () => invoke<StorageReport>('get_storage_report'),
  reclaim: (items: ReclaimItem[]) =>
    invoke<ReclaimResult>('reclaim_storage', { items }),
}
