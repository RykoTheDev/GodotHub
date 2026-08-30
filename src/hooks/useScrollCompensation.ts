import { useCallback, useEffect, useRef } from 'react'

export function useScrollCompensation() {
  const viewportRef = useRef<HTMLDivElement | null>(null)
  const savedScrollTopRef = useRef(0)

  useEffect(() => {
    const el = viewportRef.current
    if (!el) return
    const trackScroll = () => {
      savedScrollTopRef.current = el.scrollTop
    }
    trackScroll()
    el.addEventListener('scroll', trackScroll, { passive: true })
    return () => el.removeEventListener('scroll', trackScroll)
  }, [])

  const restoreScroll = useCallback(() => {
    const el = viewportRef.current
    if (!el) return
    const max = el.scrollHeight - el.clientHeight
    el.scrollTop = Math.min(savedScrollTopRef.current, Math.max(0, max))
  }, [])

  return { viewportRef, restoreScroll }
}
