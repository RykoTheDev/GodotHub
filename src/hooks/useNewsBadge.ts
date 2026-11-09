import { useCallback, useEffect, useState } from 'react'
import { api } from '../lib/api'
import { useApiData } from '../lib/useApiData'
import type { NewsItem } from '../types'
import { uiPrefs } from '../lib/uiPrefs'

const SEEN_KEY = 'news_seen_ids'

function readSeen(): string[] | null {
  try {
    const saved = JSON.parse(uiPrefs.getItem(SEEN_KEY) ?? 'null')
    return Array.isArray(saved) ? saved.filter((id): id is string => typeof id === 'string') : null
  } catch {
    return null
  }
}

function writeSeen(ids: string[]) {
  try {
    uiPrefs.setItem(SEEN_KEY, JSON.stringify(ids))
  } catch {}
}

export function useNewsBadge(viewing: boolean, enabled: boolean) {
  const [seen, setSeen] = useState(readSeen)
  const { data: items } = useApiData(
    async () => (enabled ? (await api.fetchGodotNews())?.items ?? [] : []),
    [enabled],
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
