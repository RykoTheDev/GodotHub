import {
  createContext,
  createElement,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import { api } from '../lib/api'
import type { UpdateEntry } from '../types'

const SEEN_KEY = 'godothub:updates-seen-ids'
const REFRESH_MS = 5 * 60 * 1000

function loadSeenIds(): string[] {
  try {
    const raw = localStorage.getItem(SEEN_KEY)
    if (!raw) return []
    const parsed: unknown = JSON.parse(raw)
    return Array.isArray(parsed)
      ? parsed.filter((x): x is string => typeof x === 'string')
      : []
  } catch {
    return []
  }
}

function saveSeenIds(ids: string[]) {
  try {
    localStorage.setItem(SEEN_KEY, JSON.stringify(ids))
  } catch {}
}

interface UpdatesBadgeContextValue {
  hasUnseen: boolean
  markSeen: () => void
}

const UpdatesBadgeContext = createContext<UpdatesBadgeContextValue | null>(
  null,
)

export function UpdatesBadgeProvider({ children }: { children: ReactNode }) {
  const [entries, setEntries] = useState<UpdateEntry[]>([])
  const [hasUnseen, setHasUnseen] = useState(false)

  useEffect(() => {
    let cancelled = false
    const check = () => {
      api
        .fetchUpdates()
        .then((res) => {
          if (cancelled) return
          setEntries(res.entries)
          const seen = new Set(loadSeenIds())
          setHasUnseen(
            res.entries.some((e) => e.is_new && !seen.has(e.id)),
          )
        })
        .catch(() => {})
    }
    check()
    const id = setInterval(check, REFRESH_MS)
    return () => {
      cancelled = true
      clearInterval(id)
    }
  }, [])

  const markSeen = useCallback(() => {
    setHasUnseen(false)
    saveSeenIds(entries.map((e) => e.id))
  }, [entries])

  return createElement(
    UpdatesBadgeContext.Provider,
    { value: { hasUnseen, markSeen } },
    children,
  )
}

export function useUpdatesBadge() {
  const ctx = useContext(UpdatesBadgeContext)
  if (!ctx)
    throw new Error('useUpdatesBadge() must be used within a <UpdatesBadgeProvider>')
  return ctx
}
