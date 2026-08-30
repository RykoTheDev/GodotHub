import { useEffect, useRef, useState } from 'react'

const ANNOUNCE_EVENT = 'app:announce'

export function announce(message: string) {
  window.dispatchEvent(
    new CustomEvent(ANNOUNCE_EVENT, { detail: { message } }),
  )
}

export function ScreenReaderAnnouncer({
  enabled,
}: {
  enabled: boolean
}) {
  const [message, setMessage] = useState('')
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    const handler = (e: Event) => {
      const detail = (e as CustomEvent<{ message?: string }>).detail
      if (!detail?.message) return
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
      setMessage('')
      requestAnimationFrame(() => {
        setMessage(detail.message as string)
      })
      timeoutRef.current = setTimeout(() => setMessage(''), 3000)
    }
    window.addEventListener(ANNOUNCE_EVENT, handler)
    return () => {
      window.removeEventListener(ANNOUNCE_EVENT, handler)
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
    }
  }, [])

  if (!enabled) return null

  return (
    <div
      aria-live="polite"
      aria-atomic="true"
      className="sr-only"
      role="status"
    >
      {message}
    </div>
  )
}
