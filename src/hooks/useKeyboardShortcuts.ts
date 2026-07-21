import { useEffect, useCallback, useRef } from 'react'

export interface ShortcutHandlers {
  onNewProject: () => void
  onOpenSettings: () => void
  onSwitchTab: (tabIndex: number) => void
  onCommandPalette: () => void
  onEscape: () => void
}

export function useKeyboardShortcuts(
  handlers: ShortcutHandlers,
  paletteKey: string = 'p',
) {
  const h = useRef(handlers)
  h.current = handlers

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    const mod = e.metaKey || e.ctrlKey

    if (e.key === 'Escape') {
      e.preventDefault()
      h.current.onEscape()
      return
    }

    const target = e.target as HTMLElement
    const isInput =
      target.tagName === 'INPUT' ||
      target.tagName === 'TEXTAREA' ||
      target.isContentEditable

    if (mod) {
      switch (e.key.toLowerCase()) {
        case paletteKeyRef.current:
          e.preventDefault()
          h.current.onCommandPalette()
          break
        case 'n':
          if (!isInput) {
            e.preventDefault()
            h.current.onNewProject()
          }
          break
        case ',':
          if (!isInput && e.shiftKey === false) {
            e.preventDefault()
            h.current.onOpenSettings()
          }
          break
        case '1':
        case '2':
        case '3':
        case '4':
          if (!isInput) {
            e.preventDefault()
            h.current.onSwitchTab(parseInt(e.key) - 1)
          }
          break
      }
    }
  }, [])

  const paletteKeyRef = useRef(paletteKey)
  paletteKeyRef.current = paletteKey

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [handleKeyDown])
}
