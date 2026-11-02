import { useEffect, useId, useRef } from 'react'

interface PopupOpenDetail {
  id: string
  origin: Element | null
}

export function useExclusivePopup(
  open: boolean,
  close: () => void,
  surface: () => Element | null,
  origin: () => Element | null = surface,
) {
  const id = useId()
  const latest = useRef({ close, surface, origin })
  latest.current = { close, surface, origin }

  useEffect(() => {
    if (!open) return
    const onOtherOpen = (event: Event) => {
      const detail = (event as CustomEvent<PopupOpenDetail | undefined>).detail
      if (!detail || detail.id === id) return
      if (detail.origin && latest.current.surface()?.contains(detail.origin)) return
      latest.current.close()
    }
    window.addEventListener('app:dropdown-open', onOtherOpen)
    window.dispatchEvent(
      new CustomEvent<PopupOpenDetail>('app:dropdown-open', {
        detail: { id, origin: latest.current.origin() },
      }),
    )
    return () => {
      window.removeEventListener('app:dropdown-open', onOtherOpen)
      window.dispatchEvent(new CustomEvent('app:dropdown-close'))
    }
  }, [open, id])
}
