import { useCallback, useEffect, useState } from 'react'
import { listen } from '@tauri-apps/api/event'
import { api } from '../lib/api'
import type {
  DownloadProgress,
  GodotRelease,
  InstalledGodotVersion,
} from '../types'

export interface DownloadState extends DownloadProgress {
  status: 'queued' | 'downloading' | 'paused'
}

const keyOf = (tag: string, assetName: string) =>
  assetName.toLowerCase().includes('mono') ? `${tag}-mono` : tag

export function useGodotVersions() {
  const [installed, setInstalled] = useState<InstalledGodotVersion[]>([])
  const [available, setAvailable] = useState<GodotRelease[]>([])
  const [loadingAvailable, setLoadingAvailable] = useState(false)
  const [availableError, setAvailableError] = useState<string | null>(null)
  const [downloads, setDownloads] = useState<Record<string, DownloadState>>({})
  const [scanProgress, setScanProgress] = useState<{
    current: number
    total: number
  } | null>(null)
  const refreshInstalled = useCallback(
    async () => setInstalled(await api.listInstalledGodotVersions()),
    [],
  )

  const refreshAvailable = useCallback(async () => {
    setLoadingAvailable(true)
    setAvailableError(null)
    try {
      setAvailable(await api.fetchAvailableGodotVersions())
    } catch (e) {
      setAvailableError(String(e))
    } finally {
      setLoadingAvailable(false)
    }
  }, [])

  const clearKey = (key: string) =>
    setDownloads((prev) => {
      const next = { ...prev }
      delete next[key]
      return next
    })

  useEffect(() => {
    const interval = setInterval(() => {
      if (document.visibilityState === 'visible') {
        refreshInstalled()
      }
    }, 15000)

    const onVisibility = () => {
      if (document.visibilityState === 'visible') {
        refreshInstalled()
      }
    }
    document.addEventListener('visibilitychange', onVisibility)

    return () => {
      clearInterval(interval)
      document.removeEventListener('visibilitychange', onVisibility)
    }
  }, [])

  useEffect(() => {
    refreshInstalled()
    refreshAvailable()

    const unlistenScan = listen<[number, number]>(
      'version-scan-progress',
      (e) => {
        const [current, total] = e.payload
        setScanProgress({ current, total })
        if (current >= total) {
          setTimeout(() => setScanProgress(null), 800)
        }
      },
    )
    const unlistenQueued = listen<string>('godot-download-queued', (e) => {
      setDownloads((prev) => ({
        ...prev,
        [e.payload]: {
          tag: e.payload,
          downloaded: prev[e.payload]?.downloaded ?? 0,
          total: prev[e.payload]?.total ?? 0,
          status: 'queued',
        },
      }))
    })
    const unlistenProgress = listen<DownloadProgress>(
      'godot-download-progress',
      (e) => {
        setDownloads((prev) => ({
          ...prev,
          [e.payload.tag]: { ...e.payload, status: 'downloading' },
        }))
      },
    )
    const unlistenPaused = listen<string>('godot-download-paused', (e) => {
      setDownloads((prev) =>
        prev[e.payload]
          ? { ...prev, [e.payload]: { ...prev[e.payload], status: 'paused' } }
          : prev,
      )
    })
    const unlistenCanceled = listen<string>('godot-download-canceled', (e) =>
      clearKey(e.payload),
    )
    const unlistenError = listen<{ tag: string; message: string }>(
      'godot-download-error',
      (e) => {
        clearKey(e.payload.tag)
      },
    )
    const unlistenComplete = listen<string>('godot-download-complete', (e) => {
      clearKey(e.payload)
      refreshInstalled()
    })
    return () => {
      unlistenQueued.then((f) => f())
      unlistenProgress.then((f) => f())
      unlistenPaused.then((f) => f())
      unlistenCanceled.then((f) => f())
      unlistenError.then((f) => f())
      unlistenComplete.then((f) => f())
      unlistenScan.then((f) => f())
    }
  }, [refreshInstalled, refreshAvailable])

  const download = useCallback(
    async (tag: string, assetName: string, url: string) => {
      const key = keyOf(tag, assetName)
      setDownloads((prev) => ({
        ...prev,
        [key]: { tag: key, downloaded: 0, total: 0, status: 'queued' },
      }))
      await api.downloadGodotVersion(tag, assetName, url)
    },
    [],
  )

  const pause = useCallback(async (key: string) => api.pauseDownload(key), [])
  const resume = useCallback(async (key: string) => api.resumeDownload(key), [])
  const cancel = useCallback(async (key: string) => {
    await api.cancelDownload(key)
    clearKey(key)
  }, [])

  const remove = useCallback(
    async (tag: string) => {
      await api.deleteGodotVersion(tag)
      await refreshInstalled()
    },
    [refreshInstalled],
  )

  const rename = useCallback(async (tag: string, customName: string | null) => {
    const updated = await api.renameGodotVersion(tag, customName)
    setInstalled((prev) => prev.map((v) => (v.tag === tag ? updated : v)))
    return updated
  }, [])

  return {
    installed,
    available,
    loadingAvailable,
    availableError,
    downloads,
    download,
    pause,
    resume,
    cancel,
    remove,
    rename,
    refreshAvailable,
    refreshInstalled,
    scanProgress,
  }
}
