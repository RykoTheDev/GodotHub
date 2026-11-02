import { useEffect } from 'react'
import { listen } from '@tauri-apps/api/event'

type EventHandler<T> = (payload: T) => void

export function useTauriEvent<T = unknown>(
  event: string,
  handler: EventHandler<T>,
  deps: unknown[] = [],
) {
  useEffect(() => {
    const unlisten = listen<T>(event, (e) => handler(e.payload))
    return () => {
      unlisten.then((fn) => fn())
    }
  }, [event, ...deps])
}
