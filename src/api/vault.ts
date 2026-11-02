import { invoke } from '@tauri-apps/api/core'
import type {
  VaultItem,
  VaultProjectImportResult,
  VaultSaveSource,
} from '../types'

export const vaultApi = {
  list: () => invoke<VaultItem[]>('list_vault_items'),
  saveToVault: (
    name: string,
    description: string,
    tags: string[],
    sources: VaultSaveSource[],
  ) =>
    invoke<VaultItem>('save_to_vault', {
      name,
      description,
      tags,
      sources,
    }),
  addToProjects: (itemId: string, projectIds: string[], overwrite: boolean) =>
    invoke<VaultProjectImportResult[]>('add_vault_item_to_projects', {
      itemId,
      projectIds,
      overwrite,
    }),
  delete: (itemId: string) => invoke<void>('delete_vault_item', { itemId }),
  update: (itemId: string, name: string, description: string, tags: string[]) =>
    invoke<VaultItem>('update_vault_item', { itemId, name, description, tags }),
}
