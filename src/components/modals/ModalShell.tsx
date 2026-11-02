import { useEffect, useId, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { ModalHeader } from './ModalHeader'

interface Props {
  icon: React.ReactNode
  title: string
  maxWidth?: string
  onClose?: () => void
  showClose?: boolean
  onKeyDown?: (e: React.KeyboardEvent) => void
  children: React.ReactNode
  footer?: React.ReactNode
  bodyClassName?: string
}

const FOCUSABLE =
  'a[href], button:not(:disabled), input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex]:not([tabindex="-1"])'

export function ModalShell({
  icon,
  title,
  maxWidth = 'max-w-2xl',
  onClose,
  showClose = true,
  onKeyDown,
  children,
  footer,
  bodyClassName,
}: Props) {
  const titleId = useId()
  const dialogRef = useRef<HTMLDivElement>(null)
  const openMenus = useRef(0)
  const [returnFocus] = useState(() => document.activeElement as HTMLElement | null)

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dialog-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dialog-close'))
    }
  }, [])

  useEffect(() => {
    const onMenuOpen = () => { openMenus.current += 1 }
    const onMenuClose = () => { openMenus.current = Math.max(0, openMenus.current - 1) }
    window.addEventListener('app:dropdown-open', onMenuOpen)
    window.addEventListener('app:dropdown-close', onMenuClose)
    return () => {
      window.removeEventListener('app:dropdown-open', onMenuOpen)
      window.removeEventListener('app:dropdown-close', onMenuClose)
    }
  }, [])

  useEffect(() => {
    const dialog = dialogRef.current
    const preferred = dialog?.querySelector<HTMLElement>('[data-autofocus]')
    if (preferred) preferred.focus({ preventScroll: true })
    else if (dialog && !dialog.contains(document.activeElement)) dialog.focus({ preventScroll: true })
    return () => {
      if (returnFocus?.isConnected) returnFocus.focus({ preventScroll: true })
    }
  }, [returnFocus])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    onKeyDown?.(e)
    if (e.isPropagationStopped() || e.defaultPrevented) return
    const dialog = dialogRef.current
    if (!dialog) return

    if (e.key === 'Escape') {
      if (openMenus.current > 0 || !onClose) return
      e.stopPropagation()
      onClose()
      return
    }

    if (e.key !== 'Tab') return
    const focusable = [...dialog.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
      (el) => !el.closest('[inert]') && el.getClientRects().length > 0,
    )
    if (focusable.length === 0) {
      e.preventDefault()
      return
    }
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    const active = document.activeElement
    if (e.shiftKey && (active === first || active === dialog)) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && active === last) {
      e.preventDefault()
      first.focus()
    }
  }

  return createPortal(
    <div


      className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4"
      onClick={(e) => {
        e.stopPropagation()
        onClose?.()
      }}
    >
      <div

        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className={`bg-surface rounded-modal w-full ${maxWidth} max-h-[88vh] flex flex-col shadow-2xl overflow-clip`}
        onClick={(e) => e.stopPropagation()}
        onKeyDown={handleKeyDown}
      >
        <ModalHeader
          icon={icon}
          title={title}
          onClose={showClose ? onClose : undefined}
          titleId={titleId}
        />

        <div className={`min-h-0 overflow-y-auto ${bodyClassName ?? 'flex-1'}`}>
          {children}
        </div>

        {footer && (
          <div
            className="flex items-center gap-2.5 p-4 border-t border-line shrink-0"
          >
            {footer}
          </div>
        )}
      </div>
    </div>,
    document.body,
  )
}
