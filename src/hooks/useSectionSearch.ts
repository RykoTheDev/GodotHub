import { useCallback, useRef, useState } from 'react'

export function matchesSearch(
  query: string,
  ...terms: (string | undefined)[]
) {
  const q = query.trim().toLowerCase()
  if (!q) return true
  const hay = terms.filter(Boolean).join(' ').toLowerCase()
  return q.split(/\s+/).every((part) => hay.includes(part))
}

export function useSectionSearch() {
  const [query, setQuery] = useState('')
  const [visible, setVisible] = useState<Set<string> | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const reportMatch = useCallback((id: string, matched: boolean) => {
    setVisible((prev) => {
      if (!prev) return new Set(matched ? [id] : [])
      const next = new Set(prev)
      if (matched) next.add(id)
      else next.delete(id)
      return next
    })
  }, [])

  const noResults =
    query.trim() !== '' && visible !== null && visible.size === 0

  const clear = useCallback(() => {
    setQuery('')
    requestAnimationFrame(() => inputRef.current?.focus())
  }, [inputRef, setQuery])

  const reset = useCallback(() => setVisible(null), [])

  return { query, setQuery, visible, reportMatch, noResults, inputRef, clear, reset }
}
