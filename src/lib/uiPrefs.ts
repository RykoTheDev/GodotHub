import { invoke } from '@tauri-apps/api/core'

interface UiPrefsSnapshot {
  migrated_from_local_storage: boolean
  values: Record<string, unknown>
}

const cache = new Map<string, string>()
let pendingWrites: Promise<unknown> = Promise.resolve()

function readLocalStorage(): Record<string, string> {
  const values: Record<string, string> = {}
  try {
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i)
      if (key === null) continue
      const value = localStorage.getItem(key)
      if (value !== null) values[key] = value
    }
  } catch {}
  return values
}

function fill(values: Record<string, unknown>): void {
  cache.clear()
  for (const [key, value] of Object.entries(values)) {
    if (value === null || value === undefined) continue
    cache.set(key, typeof value === 'string' ? value : JSON.stringify(value))
  }
}

export async function loadUiPrefs(): Promise<void> {
  try {
    let snapshot = await invoke<UiPrefsSnapshot>('get_ui_prefs')
    if (!snapshot.migrated_from_local_storage) {
      snapshot = await invoke<UiPrefsSnapshot>('import_ui_prefs', { values: readLocalStorage() })
    }
    fill(snapshot.values)
  } catch (error) {
    console.error('Failed to load UI preferences, using browser storage for this session', error)
    fill(readLocalStorage())
  }
}

function persist(command: string, args: Record<string, unknown>): void {
  pendingWrites = pendingWrites
    .then(() => invoke(command, args))
    .catch((error) => console.error(`Failed to save UI preference (${command})`, error))
}

export const uiPrefs = {
  getItem(key: string): string | null {
    return cache.get(key) ?? null
  },
  setItem(key: string, value: string): void {
    if (cache.get(key) === value) return
    cache.set(key, value)
    persist('set_ui_pref', { key, value })
  },
  removeItem(key: string): void {
    if (!cache.has(key)) return
    cache.delete(key)
    persist('remove_ui_pref', { key })
  },
}

export function flushUiPrefs(): Promise<unknown> {
  return pendingWrites
}
