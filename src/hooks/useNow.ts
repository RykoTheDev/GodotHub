import { useEffect, useState } from 'react'
import { currentTick, subscribeTick } from '../lib/sharedTicker'

export function useNow(active: boolean): number {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (!active) return
    setNow(currentTick())
    return subscribeTick(setNow)
  }, [active])
  return now
}
