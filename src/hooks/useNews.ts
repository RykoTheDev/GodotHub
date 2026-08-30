import { useCallback, useState } from 'react'
import { api } from '../lib/api'
import { useApiDataWithError } from '../lib/useApiData'
import type { NewsItem } from '../types'

const PAGE_SIZE = 10

export function useNews() {
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE)
  const [fromCache, setFromCache] = useState(false)

  const { data: items, loading, error, refresh: load } =
    useApiDataWithError(
      async () => {
        const res = await api.fetchGodotNews()
        setVisibleCount(PAGE_SIZE)
        setFromCache(res.from_cache)
        return res.items
      },
      [],
      [] as NewsItem[],
    )

  const showMore = useCallback(() => {
    setVisibleCount((c) => Math.min(c + PAGE_SIZE, items.length))
  }, [items.length])

  return {
    items: items.slice(0, visibleCount),
    hasMore: visibleCount < items.length,
    total: items.length,
    loading,
    error,
    fromCache,
    reload: load,
    showMore,
  }
}
