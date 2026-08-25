import { useCallback } from 'react'
import { api } from '../lib/api'
import { useApiData } from '../lib/useApiData'
import type { ChangelogEntry, ChangelogNote } from '../types'

export function useChangelog() {
  const { data: entries, loading, refresh } = useApiData(
    () => api.listChangelogEntries(),
    [],
    [] as ChangelogEntry[],
  )

  const addEntry = useCallback(
    async (
      version: string,
      date: string,
      notes: ChangelogNote[],
      knownIssues: string[],
    ) => {
      await api.addChangelogEntry(version, date, notes, knownIssues)
      await refresh()
      window.dispatchEvent(new CustomEvent('app:changelog-entry-added'))
    },
    [refresh],
  )

  const updateEntry = useCallback(
    async (
      id: string,
      version: string,
      date: string,
      notes: ChangelogNote[],
      knownIssues: string[],
    ) => {
      await api.updateChangelogEntry(id, version, date, notes, knownIssues)
      await refresh()
      window.dispatchEvent(new CustomEvent('app:changelog-entry-added'))
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
