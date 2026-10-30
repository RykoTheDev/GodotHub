import { useSyncExternalStore } from 'react'
import { pushToast } from './toast'

const STORAGE_KEY = 'godothub_debug_unlocked'
const CLICKS_TO_UNLOCK = 5
const CLICK_WINDOW_MS = 2000

const listeners = new Set<() => void>()
let clicks: number[] = []

function readUnlocked(): boolean {
  try {
    return localStorage.getItem(STORAGE_KEY) === '1'
  } catch {
    return false
  }
}

let unlocked = readUnlocked()

export function setDebugUnlocked(value: boolean) {
  unlocked = value
  try {
    if (value) localStorage.setItem(STORAGE_KEY, '1')
    else localStorage.removeItem(STORAGE_KEY)
  } catch {}
  listeners.forEach((fn) => fn())
}

export function registerSettingsClick() {
  if (unlocked) return
  const now = Date.now()
  clicks = [...clicks.filter((t) => now - t < CLICK_WINDOW_MS), now]
  if (clicks.length >= CLICKS_TO_UNLOCK) {
    clicks = []
    setDebugUnlocked(true)
    pushToast('info', 'Debug settings unlocked')
  }
}

function subscribe(fn: () => void) {
  listeners.add(fn)
  return () => {
    listeners.delete(fn)
  }
}

export function useDebugUnlocked(): boolean {
  return useSyncExternalStore(subscribe, () => unlocked)
}
