import { useCallback, useEffect, useState } from 'react'
import { api } from '../lib/api'
import type { NewsItem } from '../types'

const PAGE_SIZE = 10

export function useNews() {
  const [items, setItems] = useState<NewsItem[]>([])
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [fromCache, setFromCache] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await api.fetchGodotNews()
      setItems(res.items)
      setFromCache(res.from_cache)
      setVisibleCount(PAGE_SIZE)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

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
