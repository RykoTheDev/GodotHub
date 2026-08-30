import { useCallback, useState } from 'react'
import { api } from '../lib/api'
import { useApiDataWithError } from '../lib/useApiData'
import type { UpdateEntry } from '../types'

export function useUpdates() {
  const [fromCache, setFromCache] = useState(false)
  const [fetchedAt, setFetchedAt] = useState(0)

  const { data: entries, loading, error, refresh } = useApiDataWithError(
    async () => {
      const res = await api.fetchUpdates()
      setFromCache(res.from_cache)
      setFetchedAt(res.fetched_at)
      return res.entries
    },
    [],
    [] as UpdateEntry[],
  )

  const reload = useCallback(() => {
    void refresh()
  }, [refresh])

  return { entries, loading, error, fromCache, fetchedAt, reload, refresh }
}
