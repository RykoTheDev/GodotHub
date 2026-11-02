import {
  createContext,
  createElement,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import { useApiData } from '../lib/useApiData'
import { api } from '../lib/api'
import type { ChangelogEntry } from '../types'

const SEEN_KEY = 'changelog_seen_ids'

interface ChangelogBadgeContextValue {
  hasNewEntry: boolean
  markSeen: () => void
}

const ChangelogBadgeContext = createContext<ChangelogBadgeContextValue | null>(
  null,
)

function readSeen(): string[] | null {
  try {
    const saved = JSON.parse(localStorage.getItem(SEEN_KEY) ?? 'null')
    return Array.isArray(saved) ? saved.filter((id): id is string => typeof id === 'string') : null
  } catch {
    return null
  }
}

export function ChangelogBadgeProvider({ children }: { children: ReactNode }) {
  const [seen, setSeen] = useState(readSeen)

  const { data: entries, loaded, refresh } = useApiData(
    () => api.listChangelogEntries(),
    [],
    [] as ChangelogEntry[],
  )

  const markSeen = useCallback(() => {
    if (!loaded) return
    const ids = entries.map((entry) => entry.id)
    setSeen(ids)
    try {
      localStorage.setItem(SEEN_KEY, JSON.stringify(ids))
    } catch {}
  }, [entries, loaded])

  useEffect(() => {
    if (loaded && seen === null) markSeen()
  }, [loaded, seen, markSeen])

  useEffect(() => {
    const handleEntryAdded = () => refresh()
    window.addEventListener('app:changelog-entry-added', handleEntryAdded)
    return () =>
      window.removeEventListener('app:changelog-entry-added', handleEntryAdded)
  }, [refresh])

  const hasNewEntry = !!seen && entries.some((entry) => !seen.includes(entry.id))

  return createElement(
    ChangelogBadgeContext.Provider,
    { value: { hasNewEntry, markSeen } },
    children,
  )
}

export function useChangelogBadge() {
  const ctx = useContext(ChangelogBadgeContext)
  if (!ctx)
    throw new Error(
      'useChangelogBadge() must be used within a <ChangelogBadgeProvider>',
    )
  return ctx
}
