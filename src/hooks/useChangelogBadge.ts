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

interface ChangelogBadgeContextValue {
  hasNewEntry: boolean
  markSeen: () => void
}

const ChangelogBadgeContext = createContext<ChangelogBadgeContextValue | null>(
  null,
)

export function ChangelogBadgeProvider({ children }: { children: ReactNode }) {
  const [hasNewEntry, setHasNewEntry] = useState(false)
  const [previousCount, setPreviousCount] = useState<number | null>(null)

  const { data: entries } = useApiData(
    () => api.listChangelogEntries(),
    [],
    [] as ChangelogEntry[],
  )

  useEffect(() => {
    if (previousCount === null) {
      setPreviousCount(entries.length)
      return
    }
    if (entries.length > previousCount) {
      setHasNewEntry(true)
    }
    setPreviousCount(entries.length)
  }, [entries.length, previousCount])

  useEffect(() => {
    const handleEntryAdded = () => setHasNewEntry(true)
    window.addEventListener('app:changelog-entry-added', handleEntryAdded)
    return () =>
      window.removeEventListener('app:changelog-entry-added', handleEntryAdded)
  }, [])

  const markSeen = useCallback(() => {
    setHasNewEntry(false)
  }, [])

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
