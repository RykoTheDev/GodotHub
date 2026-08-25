import { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'framer-motion'
import {
  dismissToast,
  subscribeToasts,
  type ToastItem,
} from '../../lib/toast'
import { IconCheckCircle, IconX, IconAlertTriangle } from '../../lib/icons'

function ToastCard({ toast }: { toast: ToastItem }) {
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
    <motion.div
      layout
      initial={{ opacity: 0, y: 12, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: 8, scale: 0.96 }}
      transition={{ duration: 0.18, ease: 'easeOut' }}
      className="flex items-start gap-2.5 w-80 rounded-menu border border-outline/50 bg-surface/95 backdrop-blur shadow-lg shadow-black/20 px-3.5 py-3"
    >
      <Icon className={`w-4 h-4 mt-0.5 shrink-0 ${color}`} />
      <p className="flex-1 min-w-0 text-xs text-ink leading-snug wrap-break-word">
        {toast.message}
      </p>
      <button
        type="button"
        onClick={() => dismissToast(toast.id)}
        aria-label="Dismiss"
        className="cursor-pointer shrink-0 p-0.5 rounded text-muted/50 hover:text-ink hover:bg-raised transition-colors"
      >
        <IconX className="w-3.5 h-3.5" />
      </button>
    </motion.div>
  )
}

export function ToastContainer() {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  useEffect(() => subscribeToasts(setToasts), [])

  return createPortal(
    <div className="fixed bottom-4 right-4 z-9999 flex flex-col gap-2 items-end pointer-events-none">
      <AnimatePresence>
        {toasts.map((t) => (
          <div key={t.id} className="pointer-events-auto">
            <ToastCard toast={t} />
          </div>
        ))}
      </AnimatePresence>
    </div>,
    document.body,
  )
}
