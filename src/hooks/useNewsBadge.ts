import { useCallback, useEffect, useState } from 'react'
import { api } from '../lib/api'
import { useApiData } from '../lib/useApiData'
import type { NewsItem } from '../types'

const SEEN_KEY = 'news_seen_ids'

function readSeen(): string[] | null {
  try {
    const saved = JSON.parse(localStorage.getItem(SEEN_KEY) ?? 'null')
    return Array.isArray(saved) ? saved.filter((id): id is string => typeof id === 'string') : null
  } catch {
    return null
  }
}

function writeSeen(ids: string[]) {
  try {
    localStorage.setItem(SEEN_KEY, JSON.stringify(ids))
  } catch {}
}

export function useNewsBadge(viewing: boolean) {
  const [seen, setSeen] = useState(readSeen)
  const { data: items } = useApiData(
    async () => (await api.fetchGodotNews())?.items ?? [],
    [],
    [] as NewsItem[],
  )

  const markSeen = useCallback(() => {
    if (items.length === 0) return
    const ids = items.map((item) => item.id)
    setSeen(ids)
    writeSeen(ids)
  }, [items])

  const unread = seen ? items.filter((item) => !seen.includes(item.id)).length : 0

  useEffect(() => {
    if (items.length > 0 && (seen === null || (viewing && unread > 0))) markSeen()
  }, [items, viewing, seen, unread, markSeen])

  return unread
}
