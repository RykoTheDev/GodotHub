import { invoke } from '@tauri-apps/api/core'
import type { Category } from '../types'

export const categoriesApi = {
  list: () => invoke<Category[]>('list_categories'),
  create: (name: string, color?: string) =>
    invoke<Category>('create_category', { name, color: color ?? null }),
  rename: (id: string, name: string) =>
    invoke<Category>('rename_category', { id, name }),
  update: (id: string, name?: string | null, color?: string | null) =>
    invoke<Category>('update_category', { id, name: name ?? null, color: color ?? null }),
  delete: (id: string) => invoke<void>('delete_category', { id }),
  reorder: (orderedIds: string[]) =>
    invoke<void>('reorder_categories', { orderedIds }),
}
