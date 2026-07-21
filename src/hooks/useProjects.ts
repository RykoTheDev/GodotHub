import { useCallback, useEffect, useState } from 'react'
import { listen } from '@tauri-apps/api/event'
import { api } from '../lib/api'
import type { Project } from '../types'

export function useProjects() {
  const [projects, setProjects] = useState<Project[]>([])
  const [loaded, setLoaded] = useState(false)

  const refresh = useCallback(
    async () => {
      try {
        const list = await api.listProjects()
        setProjects(list)
        api.refreshTrayMenu().catch(() => {})
        return list
      } catch {
        setProjects([])
      } finally {
        setLoaded(true)
      }
    },
    [],
  )

  const [scanProgress, setScanProgress] = useState<{
    current: number
    total: number
  } | null>(null)

  useEffect(() => {
    const unlisten = listen<[number, number]>('project-scan-progress', (e) => {
      const [current, total] = e.payload
      setScanProgress({ current, total })
      if (current >= total) {
        setTimeout(() => setScanProgress(null), 800)
      }
    })
    return () => {
      unlisten.then((f) => f())
    }
  }, [])

  useEffect(() => {
    refresh()
    const unlisten = listen('godot-download-complete', () => refresh())
    return () => {
      unlisten.then((f) => f())
    }
  }, [refresh])

  const remove = useCallback(
    async (id: string, deleteFiles: boolean) => {
      await api.removeProject(id, deleteFiles)
      await refresh()
    },
    [refresh],
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
      await api.updateProject(id, { pinned })
      await refresh()
    },
    [refresh],
  )

  const setCategory = useCallback(
    async (id: string, category: string) => {
      await api.updateProject(id, { category })
      await refresh()
    },
    [refresh],
  )

  const moveProject = useCallback(
    async (id: string, category: string, destOrderedIds: string[]) => {
      setProjects((prev) => {
        const rank = new Map(destOrderedIds.map((pid, i) => [pid, i]))
        return prev.map((p) => {
          if (p.id === id) {
            return {
              ...p,
              category: category || null,
              sort_order: rank.get(id) ?? p.sort_order,
            }
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
    [],
  )

  const reorder = useCallback(async (orderedIds: string[]) => {
    setProjects((prev) => {
      const rank = new Map(orderedIds.map((id, i) => [id, i]))
      return prev.map((p) =>
        rank.has(p.id) ? { ...p, sort_order: rank.get(p.id)! } : p,
      )
    })
    await api.reorderProjects(orderedIds)
  }, [])

  return {
    projects,
    loaded,
    refresh,
    remove,
    updateVersion,
    setPinned,
    setCategory,
    moveProject,
    reorder,
    scanProgress,
  }
}
