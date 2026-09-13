import { useCallback } from 'react'
import { api } from '../lib/api'
import { useApiData } from '../lib/useApiData'
import { useWorkspaces } from './useWorkspaces'
import type { Category } from '../types'

export function useCategories() {
  const { activeId } = useWorkspaces()
  const { data: categories, loaded, refresh, setData } = useApiData(
    () => api.listCategories(),
    [activeId],
    [] as Category[],
  )

  const create = useCallback(
    async (name: string, color?: string) => {
      const category = await api.createCategory(name, color)
      await refresh()
      return category
    },
    [refresh],
  )

  const rename = useCallback(
    async (id: string, name: string) => {
      await api.renameCategory(id, name)
      await refresh()
    },
    [refresh],
  )

  const update = useCallback(
    async (
      id: string,
      name?: string | null,
      color?: string | null,
      hidden?: boolean | null,
    ) => {
      const result = await api.updateCategory(id, name, color, hidden)
      await refresh()
      return result
    },
    [refresh],
  )

  const setHidden = useCallback(
    async (id: string, hidden: boolean) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        return prev.map((c) => (c.id === id ? { ...c, hidden } : c))
      })
      try {
        await api.updateCategory(id, null, null, hidden)
      } finally {
        await refresh()
      }
    },
    [refresh, setData],
  )

  const remove = useCallback(
    async (id: string) => {
      await api.deleteCategory(id)
      await refresh()
    },
    [refresh],
  )

  const reorder = useCallback(
    async (orderedIds: string[]) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        const rank = new Map(orderedIds.map((id, i) => [id, i]))
        return [...prev].sort(
          (a, b) => (rank.get(a.id) ?? 0) - (rank.get(b.id) ?? 0),
        )
      })
      await api.reorderCategories(orderedIds)
    },
    [setData],
  )

  return {
    categories,
    loaded,
    refresh,
    create,
    rename,
    update,
    remove,
    reorder,
    setHidden,
  }
}
