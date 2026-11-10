import { useRef, type MouseEvent } from 'react'

export function useBackdropDismiss(onDismiss?: () => void) {
  const pressedOnBackdrop = useRef(false)

  return {
    onMouseDown: (e: MouseEvent<HTMLElement>) => {
      pressedOnBackdrop.current = e.target === e.currentTarget
    },
    onClick: (e: MouseEvent<HTMLElement>) => {
      e.stopPropagation()
      const dismiss = pressedOnBackdrop.current && e.target === e.currentTarget
      pressedOnBackdrop.current = false
      if (dismiss) onDismiss?.()
    },
  }
}
