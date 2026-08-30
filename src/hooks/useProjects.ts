import { useCallback, useState } from 'react'
import { api } from '../lib/api'
import { useApiData } from '../lib/useApiData'
import { useTauriEvent } from '../lib/useTauriEvent'
import { useWorkspaces } from './useWorkspaces'
import type { Project } from '../types'

export function useProjects() {
  const { activeId } = useWorkspaces()
  const { data: projects, loaded, refresh, setData } = useApiData(
    () => api.listProjects().then((list) => { api.refreshTrayMenu().catch(() => {}); return list }),
    [activeId],
    [] as Project[],
  )

  const [scanProgress, setScanProgress] = useState<{
    current: number
    total: number
  } | null>(null)

  useTauriEvent<[number, number]>('project-scan-progress', ([current, total]) => {
    setScanProgress({ current, total })
    if (current >= total) {
      setTimeout(() => setScanProgress(null), 800)
    }
  })

  useTauriEvent('watcher:project-scan-done', () => refresh(), [refresh])

  useTauriEvent('godot-download-complete', () => refresh(), [refresh])

  const remove = useCallback(
    async (id: string, deleteFiles: boolean) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        return prev.filter((p) => p.id !== id)
      })
      try {
        await api.removeProject(id, deleteFiles)
      } catch (e) {
        await refresh()
        throw e
      }
    },
    [refresh, setData],
  )

  const updateVersion = useCallback(
    async (id: string, godot_version: string) => {
      await api.updateProject(id, { godot_version })
      await refresh()
    },
    [refresh],
  )

  const setPinned = useCallback(
    async (id: string, pinned: boolean) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        return prev.map((p) => (p.id === id ? { ...p, pinned } : p))
      })
      try {
        await api.updateProject(id, { pinned })
      } catch (e) {
        await refresh()
        throw e
      }
    },
    [refresh, setData],
  )

  const updateTags = useCallback(
    async (id: string, tags: string[]) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        return prev.map((p) => (p.id === id ? { ...p, tags } : p))
      })
    },
    [setData],
  )

  const setCategory = useCallback(
    async (id: string, category: string) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        return prev.map((p) => (p.id === id ? { ...p, category: category || null } : p))
      })
      try {
        await api.updateProject(id, { category })
      } catch (e) {
        await refresh()
        throw e
      }
    },
    [refresh, setData],
  )

  const moveProject = useCallback(
    async (id: string, category: string, destOrderedIds: string[]) => {
      setData((prev) => {
        if (!Array.isArray(prev)) return prev
        const rank = new Map(destOrderedIds.map((pid, i) => [pid, i]))
        return prev.map((p) => {
          if (p.id === id) {
            return { ...p, category: category || null, sort_order: rank.get(id) ?? p.sort_order }
          }
          if (rank.has(p.id)) {
            return { ...p, sort_order: rank.get(p.id)! }
          }
          return p
        })
      })
      await api.updateProject(id, { category })
      await api.reorderProjects(destOrderedIds)
    },
    [setData],
  )

  const reorder = useCallback(async (orderedIds: string[]) => {
    setData((prev) => {
      if (!Array.isArray(prev)) return prev
      const rank = new Map(orderedIds.map((id, i) => [id, i]))
      return prev.map((p) =>
        rank.has(p.id) ? { ...p, sort_order: rank.get(p.id)! } : p,
      )
    })
    await api.reorderProjects(orderedIds)
  }, [setData])

  return {
    projects,
    loaded,
    refresh,
    remove,
    updateVersion,
    setPinned,
    updateTags,
    setCategory,
    moveProject,
    reorder,
    scanProgress,
  }
}
