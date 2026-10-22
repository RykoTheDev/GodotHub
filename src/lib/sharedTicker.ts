type Listener = (now: number) => void

const listeners = new Set<Listener>()
let intervalId: ReturnType<typeof setInterval> | null = null
let current = Date.now()

function start() {
  if (intervalId !== null || listeners.size === 0) return
  current = Date.now()
  intervalId = setInterval(() => {
    current = Date.now()
    listeners.forEach((fn) => fn(current))
  }, 1000)
}

function stop() {
  if (intervalId !== null && listeners.size === 0) {
    clearInterval(intervalId)
    intervalId = null
  }
}

export function currentTick(): number {
  return current
}

export function subscribeTick(fn: Listener): () => void {
  listeners.add(fn)
  start()
  return () => {
    listeners.delete(fn)
    stop()
  }
}
