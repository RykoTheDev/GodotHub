export type ToastType = 'success' | 'error' | 'info'

export interface ToastAction {
  label: string
  onClick: () => void
}

export interface ToastItem {
  id: number
  type: ToastType
  message: string
  action?: ToastAction
}

type Listener = (toasts: ToastItem[]) => void

let nextId = 1
let toasts: ToastItem[] = []
const listeners = new Set<Listener>()

function emit() {
  for (const l of listeners) l(toasts)
}

export function pushToast(
  type: ToastType,
  message: string,
  ttlMs = 4000,
  action?: ToastAction,
) {
  const id = nextId++
  toasts = [...toasts, { id, type, message, action }]
  emit()
  window.setTimeout(() => {
    toasts = toasts.filter((t) => t.id !== id)
    emit()
  }, ttlMs)
}

export function dismissToast(id: number) {
  toasts = toasts.filter((t) => t.id !== id)
  emit()
}

export function subscribeToasts(listener: Listener): () => void {
  listeners.add(listener)
  listener(toasts)
  return () => {
    listeners.delete(listener)
  }
}