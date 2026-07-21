import { useCallback, useEffect, useState } from 'react'
import { api } from '../lib/api'
import type { Category } from '../types'

export function useCategories() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loaded, setLoaded] = useState(false)

  const refresh = useCallback(
    async () => {
      try {
        const list = await api.listCategories()
        setCategories(list)
        return list
      } catch {
        setCategories([])
      } finally {
        setLoaded(true)
      }
    },
    [],
  )

  useEffect(() => {
    refresh()
  }, [refresh])

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
    async (id: string, name?: string | null, color?: string | null) => {
      const result = await api.updateCategory(id, name, color)
      await refresh()
      return result
    },
    [refresh],
  )

  const remove = useCallback(
    async (id: string) => {
      await api.deleteCategory(id)
      await refresh()
    },
    [refresh],
  )

  const reorder = useCallback(async (orderedIds: string[]) => {
    setCategories((prev) => {
      const rank = new Map(orderedIds.map((id, i) => [id, i]))
      return [...prev].sort(
        (a, b) => (rank.get(a.id) ?? 0) - (rank.get(b.id) ?? 0),
      )
    })
    await api.reorderCategories(orderedIds)
  }, [])

  return { categories, loaded, refresh, create, rename, update, remove, reorder }
}
