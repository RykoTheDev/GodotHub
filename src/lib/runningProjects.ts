import { api } from './api'
import type { RunningProjectInfo } from '../types'

const RETRY_DELAYS_MS = [0, 1200, 3000, 6000]

export async function fetchRunningProjects(): Promise<RunningProjectInfo[]> {
  let found: RunningProjectInfo[] = []
  for (const delay of RETRY_DELAYS_MS) {
    if (delay > 0) {
      await new Promise((resolve) => setTimeout(resolve, delay))
    }
    try {
      found = await api.listRunningProjects()
    } catch {
      return found
    }
    if (found.length > 0) return found
  }
  return found
}
