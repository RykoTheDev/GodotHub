import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { createPortal } from 'react-dom'
import {
  dismissToast,
  subscribeToasts,
  type ToastItem,
} from '../../lib/toast'
import { IconCheckCircle, IconX, IconAlertTriangle } from '../../lib/icons'
import { gsap } from '../../lib/motion'

function ToastCard({ toast, leaving, onGone }: { toast: ToastItem; leaving: boolean; onGone: (id: number) => void }) {
  const { t } = useTranslation('common')
  const cardRef = useRef<HTMLDivElement>(null)
  useLayoutEffect(() => {
    const el = cardRef.current
    if (!leaving || !el) return
    gsap.killTweensOf(el)
    const tween = gsap.to(el, {
      x: document.documentElement.dir === 'rtl' ? -80 : 80,
      opacity: 0,
      scale: 0.9,
      height: 0,
      paddingTop: 0,
      paddingBottom: 0,
      marginTop: -9,
      duration: 0.45,
      ease: 'power3.in',
      onComplete: () => onGone(toast.id),
    })
    return () => {
      tween.kill()
    }
  }, [leaving, onGone, toast.id])
  const Icon =
    toast.type === 'success'
      ? IconCheckCircle
      : toast.type === 'error'
        ? IconAlertTriangle
        : IconCheckCircle
  const color =
    toast.type === 'success'
      ? 'text-mint'
      : toast.type === 'error'
        ? 'text-danger'
        : 'text-accent-bright'
  return (
    <div
      ref={cardRef}
      data-motion="toast"
      className="pointer-events-auto flex items-start gap-2.5 w-80 rounded-menu border border-outline/50 bg-surface/95 backdrop-blur shadow-lg shadow-black/20 px-3.5 py-3 overflow-hidden"
    >
      <Icon className={`w-4 h-4 mt-0.5 shrink-0 ${color}`} />
      <p className="flex-1 min-w-0 text-xs text-ink leading-snug wrap-break-word">
        {toast.message}
      </p>
      {toast.action && (
        <button
          type="button"
          onClick={() => {
            dismissToast(toast.id)
            toast.action?.onClick()
          }}
          className="cursor-pointer shrink-0 text-xs font-semibold text-accent-bright hover:text-ink hover:bg-raised px-2 py-1 rounded-tag "
        >
          {toast.action.label}
        </button>
      )}
      <button
        type="button"
        onClick={() => dismissToast(toast.id)}
        aria-label={t('dismiss')}
        className="cursor-pointer shrink-0 p-0.5 rounded text-muted/50 hover:text-ink hover:bg-raised "
      >
        <IconX className="w-3.5 h-3.5" />
      </button>
    </div>
  )
}

export function ToastContainer() {
  const [toasts, setToasts] = useState<ToastItem[]>([])
  const [leaving, setLeaving] = useState<ToastItem[]>([])
  const current = useRef<ToastItem[]>([])

  useEffect(
    () =>
      subscribeToasts((next) => {
        const gone = current.current.filter((prev) => !next.some((item) => item.id === prev.id))
        current.current = next
        setToasts(next)
        if (gone.length) setLeaving((list) => [...list, ...gone])
      }),
    [],
  )

  const removeLeaving = useCallback((id: number) => setLeaving((list) => list.filter((item) => item.id !== id)), [])

  const rendered = [
    ...toasts.map((toast) => ({ toast, leaving: false })),
    ...leaving.map((toast) => ({ toast, leaving: true })),
  ].sort((a, b) => a.toast.id - b.toast.id)

  return createPortal(
    <div className="fixed bottom-4 end-4 z-9999 flex flex-col gap-2 items-end pointer-events-none">
      {rendered.map(({ toast, leaving: isLeaving }) => (
        <ToastCard key={toast.id} toast={toast} leaving={isLeaving} onGone={removeLeaving} />
      ))}
    </div>,
    document.body,
  )
}
