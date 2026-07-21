import { useCallback, useEffect, useState } from 'react'
import { api } from '../lib/api'
import type { ChangelogEntry, ChangelogNote } from '../types'

export function useChangelog() {
  const [entries, setEntries] = useState<ChangelogEntry[]>([])
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    setLoading(true)
    try {
      setEntries(await api.listChangelogEntries())
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    refresh()
  }, [refresh])

  const addEntry = useCallback(
    async (version: string, date: string, notes: ChangelogNote[]) => {
      await api.addChangelogEntry(version, date, notes)
      await refresh()
    },
    [refresh],
  )

  const updateEntry = useCallback(
    async (
      id: string,
      version: string,
      date: string,
      notes: ChangelogNote[],
    ) => {
      await api.updateChangelogEntry(id, version, date, notes)
      await refresh()
    },
    [refresh],
  )

  const removeEntry = useCallback(
    async (id: string) => {
      await api.deleteChangelogEntry(id)
      await refresh()
    },
    [refresh],
  )

  return { entries, loading, refresh, addEntry, updateEntry, removeEntry }
}
