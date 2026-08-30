let pending: (() => Promise<void>) | null = null

export function registerPendingSave(fn: () => Promise<void>) {
  pending = fn
}

export async function flushPendingSave() {
  const fn = pending
  pending = null
  if (fn) await fn()
}
