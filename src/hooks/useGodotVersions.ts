import { useCallback, useEffect, useRef, useState } from 'react'
import { api } from '../lib/api'
import { useTauriEvent } from '../lib/useTauriEvent'
import { useWorkspaces } from './useWorkspaces'
import { useSettings } from './useSettings'
import i18n from '../i18n'
import type {
  AliasBatchResult,
  AliasInfo,
  AliasRequest,
  CurrentVersionInfo,
  DownloadProgress,
  GodotRelease,
  InstalledGodotVersion,
  MiseStatus,
} from '../types'

export interface DownloadState extends DownloadProgress {
  status: 'queued' | 'downloading' | 'paused'
}

const keyOf = (tag: string, assetName: string) =>
  assetName.toLowerCase().includes('mono') ? `${tag}-mono` : tag

const sameInstalled = (
  a: InstalledGodotVersion[],
  b: InstalledGodotVersion[],
) => JSON.stringify(a) === JSON.stringify(b)

export function useGodotVersions() {
  const { activeId } = useWorkspaces()
  const { settings } = useSettings()
  const [installed, setInstalled] = useState<InstalledGodotVersion[]>([])
  const [current, setCurrent] = useState<CurrentVersionInfo | null>(null)
  const [aliases, setAliases] = useState<AliasInfo[]>([])
  const [aliasesDir, setAliasesDir] = useState('')
  const [available, setAvailable] = useState<GodotRelease[]>([])
  const [loadingAvailable, setLoadingAvailable] = useState(false)
  const [availableError, setAvailableError] = useState<string | null>(null)
  const [source, setSource] = useState<'github' | 'archive'>(() => {
    try {
      return localStorage.getItem('godothub_version_source') === 'archive'
        ? 'archive'
        : 'github'
    } catch {
      return 'github'
    }
  })
  const sourceRef = useRef(source)
  sourceRef.current = source

  useEffect(() => {
    try {
      localStorage.setItem('godothub_version_source', source)
    } catch {}
  }, [source])
  const [downloads, setDownloads] = useState<Record<string, DownloadState>>({})
  const [scanProgress, setScanProgress] = useState<{
    current: number
    total: number
  } | null>(null)
  const [miseStatus, setMiseStatus] = useState<MiseStatus | null>(null)
  const [miseInstalls, setMiseInstalls] = useState<Record<string, boolean>>({})

  const refreshCurrent = useCallback(async () => {
    try {
      setCurrent(await api.getCurrentGodotVersion())
    } catch {
      setCurrent(null)
    }
  }, [])

  const refreshAliases = useCallback(async () => {
    try {
      const next = await api.listVersionAliases()
      setAliases(next.aliases)
      setAliasesDir(next.aliases_dir)
    } catch {
      setAliases([])
    }
  }, [])

  const refreshInstalled = useCallback(async () => {
    const next = await api.listInstalledGodotVersions()
    setInstalled((prev) => (sameInstalled(prev, next) ? prev : next))
    await refreshCurrent()
    await refreshAliases()
  }, [refreshCurrent, refreshAliases])

  const refreshMiseStatus = useCallback(async () => {
    try {
      setMiseStatus(await api.miseStatus())
    } catch {
      setMiseStatus(null)
    }
  }, [])

  useEffect(() => {
    void refreshMiseStatus()
  }, [refreshMiseStatus, settings.use_mise])

  const refreshAvailable = useCallback(async (src?: string) => {
    const next = src === 'archive' || src === 'github' ? src : sourceRef.current
    setSource(next)
    sourceRef.current = next
    setLoadingAvailable(true)
    setAvailableError(null)
    try {
      setAvailable(await api.fetchAvailableGodotVersions(next))
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
    refreshInstalled()

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
  }, [refreshInstalled, activeId])

  useEffect(() => {
    refreshAvailable()
  }, [refreshAvailable, activeId])

  useTauriEvent<[number, number]>('version-scan-progress', ([current, total]) => {
    setScanProgress({ current, total })
    if (current >= total) {
      setTimeout(() => setScanProgress(null), 800)
    }
  })

  useTauriEvent('versions:aliases-changed', () => {
    void refreshAliases()
  }, [refreshAliases])

  useTauriEvent<string>('godot-download-queued', (key) => {
    setDownloads((prev) => ({
      ...prev,
      [key]: {
        tag: key,
        downloaded: prev[key]?.downloaded ?? 0,
        total: prev[key]?.total ?? 0,
        status: 'queued',
      },
    }))
  })

  useTauriEvent<DownloadProgress>('godot-download-progress', (payload) => {
    setDownloads((prev) => ({
      ...prev,
      [payload.tag]: { ...payload, status: 'downloading' },
    }))
  })

  useTauriEvent<string>('godot-download-paused', (key) => {
    setDownloads((prev) =>
      prev[key]
        ? { ...prev, [key]: { ...prev[key], status: 'paused' } }
        : prev,
    )
  })

  useTauriEvent<string>('godot-download-canceled', (key) => clearKey(key))

  useTauriEvent<{ tag: string; message: string }>('godot-download-error', (payload) => {
    clearKey(payload.tag)
  })

  useTauriEvent<string>('godot-download-complete', (key) => {
    clearKey(key)
    refreshInstalled()
    if (settings.desktop_notifications_enabled) {
      void api.notify(
        'GodotHub',
        i18n.t('notification_version_installed', { ns: 'common', tag: key }),
      )
    }
  }, [settings.desktop_notifications_enabled])

  const download = useCallback(
    async (tag: string, assetName: string, url: string) => {
      const key = keyOf(tag, assetName)
      // mise's asdf-godot plugin only ships non-mono release tags, so .NET builds
      // always come from GodotHub's own downloader.
      const viaMise =
        settings.use_mise &&
        !!miseStatus?.available &&
        !assetName.toLowerCase().includes('mono')

      if (viaMise) {
        setMiseInstalls((prev) => ({ ...prev, [key]: true }))
        try {
          await api.miseInstallGodotVersion(tag)
        } finally {
          setMiseInstalls((prev) => {
            const next = { ...prev }
            delete next[key]
            return next
          })
        }
        await refreshInstalled()
        return
      }

      setDownloads((prev) => ({
        ...prev,
        [key]: { tag: key, downloaded: 0, total: 0, status: 'queued' },
      }))
      await api.downloadGodotVersion(tag, assetName, url)
    },
    [settings.use_mise, miseStatus?.available, refreshInstalled],
  )

  const pause = useCallback((key: string) => api.pauseDownload(key), [])
  const resume = useCallback((key: string) => api.resumeDownload(key), [])
  const cancel = useCallback(async (key: string) => {
    await api.cancelDownload(key)
    clearKey(key)
  }, [])

  const remove = useCallback(
    async (tag: string) => {
      const target = installed.find((v) => v.tag === tag)
      if (target?.managed_by === 'mise') {
        // mise owns the files, so let it remove them from its own store.
        await api.miseUninstallGodotVersion(tag)
      } else {
        await api.deleteGodotVersion(tag)
      }
      await refreshInstalled()
    },
    [installed, refreshInstalled],
  )

  const syncMise = useCallback(async () => {
    await api.miseSyncVersions()
    await refreshInstalled()
  }, [refreshInstalled])

  const rename = useCallback(async (tag: string, customName: string | null) => {
    const updated = await api.renameGodotVersion(tag, customName)
    setInstalled((prev) => prev.map((v) => (v.tag === tag ? updated : v)))
    return updated
  }, [])

  const pinCurrent = useCallback(async (tag: string) => {
    const info = await api.setCurrentGodotVersion(tag)
    setCurrent(info)
    return info
  }, [])

  const unpinCurrent = useCallback(async () => {
    await api.clearCurrentGodotVersion()
    setCurrent(null)
  }, [])

  const createAliases = useCallback(
    async (entries: AliasRequest[]): Promise<AliasBatchResult> => {
      const result = await api.createVersionAliases(entries)
      await refreshAliases()
      return result
    },
    [refreshAliases],
  )

  const deleteAlias = useCallback(
    async (name: string) => {
      await api.deleteVersionAlias(name)
      await refreshAliases()
    },
    [refreshAliases],
  )

  return {
    installed,
    current,
    aliases,
    aliasesDir,
    setCurrent: pinCurrent,
    clearCurrent: unpinCurrent,
    createAliases,
    deleteAlias,
    refreshAliases,
    available,
    loadingAvailable,
    availableError,
    source,
    miseStatus,
    miseInstalls,
    refreshMiseStatus,
    syncMise,
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
