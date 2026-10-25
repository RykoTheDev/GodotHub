import { useEffect, useRef, useState } from 'react'
import { api } from '../lib/api'
import type { GitStatus } from '../types'

const POLL_MS = 30000
const FRESH_MS = 5000

type Listener = (map: Record<string, GitStatus>) => void

let statusMap: Record<string, GitStatus> = {}
let lastFetchedAt = 0
let lastFetchedKey = ''
let inFlight: Promise<void> | null = null
const listeners = new Set<Listener>()
const activePaths = new Map<symbol, string[]>()
let pollTimer: ReturnType<typeof setInterval> | null = null

function mergeStatuses(next: Record<string, GitStatus>): Record<string, GitStatus> {
  const merged: Record<string, GitStatus> = {}
  for (const [path, status] of Object.entries(next)) {
    const previous = statusMap[path]
    merged[path] = previous && JSON.stringify(previous) === JSON.stringify(status) ? previous : status
  }
  return merged
}

function wantedPaths(): string[] {
  const all = new Set<string>()
  for (const paths of activePaths.values()) paths.forEach((p) => all.add(p))
  return [...all].sort()
}

function refresh(force: boolean): Promise<void> {
  if (inFlight) return inFlight.then(() => refresh(false))
  const paths = wantedPaths()
  if (paths.length === 0) return Promise.resolve()
  const key = paths.join('|')
  if (!force && key === lastFetchedKey && Date.now() - lastFetchedAt < FRESH_MS) {
    return Promise.resolve()
  }
  inFlight = api
    .batchGitStatus(paths)
    .then((statuses) => {
      statusMap = mergeStatuses(statuses)
      lastFetchedAt = Date.now()
      lastFetchedKey = key
      listeners.forEach((fn) => fn(statusMap))
    })
    .catch(() => {})
    .finally(() => {
      inFlight = null
    })
  return inFlight
}

let debounceTimer: ReturnType<typeof setTimeout> | null = null

function handleRefreshEvent() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => void refresh(true), 300)
}

function handleFocus() {
  void refresh(false)
}

function handleVisibility() {
  if (!document.hidden) void refresh(false)
}

function startPolling() {
  if (pollTimer !== null) return
  pollTimer = setInterval(() => {
    if (!document.hidden) void refresh(true)
  }, POLL_MS)
  window.addEventListener('app:refresh-git-status', handleRefreshEvent)
  window.addEventListener('focus', handleFocus)
  document.addEventListener('visibilitychange', handleVisibility)
}

function stopPolling() {
  if (pollTimer === null || activePaths.size > 0) return
  clearInterval(pollTimer)
  pollTimer = null
  if (debounceTimer) clearTimeout(debounceTimer)
  window.removeEventListener('app:refresh-git-status', handleRefreshEvent)
  window.removeEventListener('focus', handleFocus)
  document.removeEventListener('visibilitychange', handleVisibility)
}

export function useGitStatusMap(paths: string[], active: boolean) {
  const [map, setMap] = useState<Record<string, GitStatus>>(statusMap)
  const [loading, setLoading] = useState(lastFetchedAt === 0)
  const idRef = useRef(Symbol('git-status'))
  const pathsKey = paths.join('|')

  useEffect(() => {
    const listener: Listener = (next) => {
      setMap(next)
      setLoading(false)
    }
    listeners.add(listener)
    return () => {
      listeners.delete(listener)
    }
  }, [])

  useEffect(() => {
    const id = idRef.current
    if (!active) return
    const list = pathsKey ? pathsKey.split('|') : []
    if (list.length === 0) {
      setLoading(false)
      return
    }
    activePaths.set(id, list)
    setMap(statusMap)
    startPolling()
    void refresh(false).finally(() => setLoading(false))
    return () => {
      activePaths.delete(id)
      stopPolling()
    }
  }, [active, pathsKey])

  return { statusMap: map, loading }
}
