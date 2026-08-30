import { useEffect, useRef, useState } from 'react'
import { openUrl } from '@tauri-apps/plugin-opener'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence, type Transition } from 'framer-motion'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { useSettings } from '../hooks/useSettings'
import { useTaskTray } from '../hooks/useTaskTray'
import { isReducedMotion } from '../lib/appearance'
import { api } from '../lib/api'
import type { GodotReleaseAsset } from '../types'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { SearchBar } from '../components/ui/SearchBar'
import { Dropdown } from '../components/ui/Dropdown'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ScanButton } from '../components/reusables/ScanButton'
import { ImportButton } from '../components/reusables/ImportButton'
import { Tooltip } from '../components/reusables/Tooltip'
import { InstalledVersionCard } from '../components/cards/InstalledVersionCard'
import {
  IconChevronDown,
  IconDownload,
  IconExternalLink,
  IconPause,
  IconPlay,
  IconSearch,
  IconSpinner,
  IconX,
} from '../lib/icons'

const VERSION_FILTERS_KEY = 'godothub_version_filters'
const VERSION_SORT_KEY = 'godothub_version_sort'

type VersionSortOption = 'latest' | 'oldest' | 'name_asc' | 'name_desc' | 'recently_installed' | 'oldest_installed'

const VERSION_SORT_OPTIONS: { value: VersionSortOption; labelKey: string }[] = [
  { value: 'latest', labelKey: 'sort_version_latest' },
  { value: 'oldest', labelKey: 'sort_version_oldest' },
  { value: 'recently_installed', labelKey: 'sort_version_recently_installed' },
  { value: 'oldest_installed', labelKey: 'sort_version_oldest_installed' },
  { value: 'name_asc', labelKey: 'sort_version_name_asc' },
  { value: 'name_desc', labelKey: 'sort_version_name_desc' },
]

const AVAILABLE_SORT_OPTIONS: { value: VersionSortOption; labelKey: string }[] = [
  { value: 'latest', labelKey: 'sort_version_latest' },
  { value: 'oldest', labelKey: 'sort_version_oldest' },
]

interface VersionFilters {
  buildType: 'standard' | 'mono' | 'both'
  channel: 'stable' | 'unstable' | 'both'
}
const DEFAULT_FILTERS: VersionFilters = { buildType: 'both', channel: 'both' }

function loadVersionFilters(): VersionFilters {
  try {
    const raw = localStorage.getItem(VERSION_FILTERS_KEY)
    if (raw) return { ...DEFAULT_FILTERS, ...JSON.parse(raw) }
  } catch {}
  return DEFAULT_FILTERS
}

function versionCore(raw: string): string {
  const parts = raw
    .trim()
    .toLowerCase()
    .replace(/^v/, '')
    .split(/[.\-]/)
    .filter(Boolean)
  const numeric: string[] = []
  let i = 0
  while (i < parts.length && /^\d+$/.test(parts[i])) {
    numeric.push(parts[i])
    i++
  }
  const channel = parts[i] ?? 'stable'
  return `${numeric.join('.')}-${channel}`
}

function minorGroup(tag: string): string {
  const m = tag.trim().replace(/^v/, '').match(/^(\d+)\.(\d+)/)
  return m ? `${m[1]}.${m[2]}` : 'Other'
}

function downloadKey(tag: string, assetName: string) {
  return assetName.toLowerCase().includes('mono') ? `${tag}-mono` : tag
}

function sourcePageUrl(source: string, tag: string): string {
  return source === 'archive'
    ? `https://godotengine.org/download/archive/${tag}/`
    : `https://github.com/godotengine/godot-builds/releases/tag/${tag}`
}

const STATE_DOT = {
  installed: 'bg-mint',
  available: 'bg-muted',
  downloading: 'bg-amber',
} as const

function VersionTag({
  tag,
  state,
  customName,
}: {
  tag: string
  state: keyof typeof STATE_DOT
  customName?: string | null
}) {
  const { t } = useTranslation('versions')
  return (
    <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-item bg-overlay border border-outline/50 font-mono text-xs text-ink shrink-0">
      <span
        className={`w-1.5 h-1.5 rounded-full ${STATE_DOT[state]} ${state === 'downloading' ? 'animate-pulse' : ''}`}
      />
      {customName ? (
        <>
          {customName}
          {customName !== tag && <span className="text-muted">({tag})</span>}
        </>
      ) : (
        tag || t('unbound')
      )}
    </span>
  )
}

function MonoBadge() {
  return (
    <span className="text-[10px] font-semibold px-2 py-0.5 rounded-tag bg-accent/10 text-accent-bright border border-accent-dim/40 shrink-0">
      .NET
    </span>
  )
}

export function VersionsView({
  onOpenSettings,
  connected = false,
}: {
  onOpenSettings?: () => void
  connected?: boolean
}) {
  const { t } = useTranslation('nav')
  const { t: tv } = useTranslation('versions')
  const { t: tc } = useTranslation('common')
  const {
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
    source,
  } = useGodotVersionsContext()
  const { settings } = useSettings()
  const { registerTask, updateTask, unregisterTask } = useTaskTray()

  const [query, setQuery] = useState('')
  const [filters, setFilters] = useState<VersionFilters>(loadVersionFilters)
  const [sortBy, setSortBy] = useState<VersionSortOption>(() => {
    try {
      const raw = localStorage.getItem(VERSION_SORT_KEY)
      if (raw === 'latest' || raw === 'oldest' || raw === 'name_asc' || raw === 'name_desc') return raw
    } catch {}
    return 'latest'
  })
  const [installedSortBy, setInstalledSortBy] = useState<VersionSortOption>(() => {
    try {
      const raw = localStorage.getItem(VERSION_SORT_KEY + '_installed')
      if (raw === 'latest' || raw === 'oldest' || raw === 'name_asc' || raw === 'name_desc' || raw === 'recently_installed' || raw === 'oldest_installed') return raw
    } catch {}
    return 'latest'
  })
  const [collapsedGroups, setCollapsedGroups] = useState<Record<string, boolean>>({})
  const [visibleGroups, setVisibleGroups] = useState(5)
  const [scanning, setScanning] = useState(false)

  useEffect(() => {
    try {
      localStorage.setItem(VERSION_FILTERS_KEY, JSON.stringify(filters))
    } catch {}
  }, [filters])

  useEffect(() => {
    try {
      localStorage.setItem(VERSION_SORT_KEY, sortBy)
    } catch {}
  }, [sortBy])

  useEffect(() => {
    try {
      localStorage.setItem(VERSION_SORT_KEY + '_installed', installedSortBy)
    } catch {}
  }, [installedSortBy])

  const handleImportVersion = async (folder: string) => {
    const taskId = `import-version-${Date.now()}`
    registerTask({
      id: taskId,
      type: 'import-versions',
      label: tv('importing_version'),
      description: folder,
      progress: null,
      status: 'running',
    })
    try {
      await api.importVersion(folder)
      await refreshInstalled()
      updateTask(taskId, { status: 'completed' })
      setTimeout(() => unregisterTask(taskId), 3000)
    } catch (e) {
      updateTask(taskId, { status: 'error', errorMessage: String(e) })
      setTimeout(() => unregisterTask(taskId), 6000)
    }
  }

  const handleScanNow = async () => {
    if (scanning) return
    if (!settings.version_scan_dirs.length) {
      if (onOpenSettings) onOpenSettings()
      else
        window.dispatchEvent(
          new CustomEvent('app:open-setting', { detail: 'version_scan_dirs' }),
        )
      return
    }
    setScanning(true)
    try {
      await api.scanForVersions(settings.version_scan_dirs, settings.scan_depth)
    } finally {
      setScanning(false)
    }
  }
  const scanRef = useRef(handleScanNow)
  scanRef.current = handleScanNow

  useEffect(() => {
    const onScan = () => scanRef.current()
    window.addEventListener('app:scan-versions', onScan)
    return () => {
      window.removeEventListener('app:scan-versions', onScan)
    }
  }, [])

  const openVersion = (tag: string, console?: boolean) => {
    api.openGodotVersion(tag, console).catch((err) => alert(String(err)))
  }

  const isSearching = query.trim().length > 0
  const q = query.trim().toLowerCase()

  const rateLimited =
    source === 'github' && /rate\s*limit/i.test(availableError || '')

  const filteredInstalled = (isSearching
    ? installed.filter(
        (v) =>
          v.tag.toLowerCase().includes(q) ||
          (v.custom_name && v.custom_name.toLowerCase().includes(q)),
      )
    : installed
  ).slice().sort((a, b) => {
    const tagA = a.custom_name || a.tag
    const tagB = b.custom_name || b.tag
    switch (installedSortBy) {
      case 'oldest':
        return a.tag.localeCompare(b.tag, undefined, { numeric: true })
      case 'name_asc':
        return tagA.localeCompare(tagB)
      case 'name_desc':
        return tagB.localeCompare(tagA)
      case 'recently_installed':
        return new Date(b.installed_at).getTime() - new Date(a.installed_at).getTime()
      case 'oldest_installed':
        return new Date(a.installed_at).getTime() - new Date(b.installed_at).getTime()
      case 'latest':
      default:
        return b.tag.localeCompare(a.tag, undefined, { numeric: true })
    }
  })

  const filteredAvailable = isSearching
    ? available
        .map((r) => ({
          ...r,
          assets: r.assets.filter(() => r.tag.toLowerCase().includes(q)),
        }))
        .filter((r) => r.assets.length > 0)
    : available

  const groupEntries = Object.entries(
    filteredAvailable
      .flatMap((r) => {
        const isStable = r.tag.toLowerCase().includes('stable')
        if (
          filters.channel !== 'both' &&
          (filters.channel === 'stable') !== isStable
        )
          return []
        return r.assets
          .filter(
            (a) =>
              filters.buildType === 'both' ||
              (filters.buildType === 'mono') === a.is_mono,
          )
          .map((asset) => ({ tag: r.tag, asset }))
      })
      .reduce<Record<string, { tag: string; asset: GodotReleaseAsset }[]>>(
        (groups, row) => {
          ;(groups[minorGroup(row.tag)] ??= []).push(row)
          return groups
        },
        {},
      ),
  ).sort(([a], [b]) => {
    switch (sortBy) {
      case 'oldest':
        return a.localeCompare(b, undefined, { numeric: true })
      case 'name_asc':
        return a.localeCompare(b, undefined, { numeric: true })
      case 'name_desc':
        return b.localeCompare(a, undefined, { numeric: true })
      case 'latest':
      default:
        return b.localeCompare(a, undefined, { numeric: true })
    }
  })

  const animate = !isReducedMotion()
  const entranceTransition: Transition = {
    type: 'tween',
    duration: animate ? 0.25 : 0,
    ease: 'easeOut',
  }

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col gap-2">
      <ViewHeader
        connected={connected}
        title={t('versions')}
          metric={
            <>
              <h2 className="text-4xl font-bold text-muted">
                <AnimatedNumber value={installed.length} />
              </h2>
              <p className="text-lg font-medium uppercase text-muted">
                {tv('installed_count', { count: installed.length })}
              </p>
            </>
          }
          actions={
            <>
              <ImportButton
                onImport={handleImportVersion}
                disabled={scanning}
                importEvent="app:import-version"
              />
              <ScanButton
                onOpenSettings={onOpenSettings}
                disabled={scanning}
                scanDirs={settings.version_scan_dirs}
                scan={() =>
                  api.scanForVersions(
                    settings.version_scan_dirs,
                    settings.scan_depth,
                  )
                }
                onComplete={() => {
                  refreshInstalled().catch(() => {})
                }}
                onScanStart={() => setScanning(true)}
                onScanEnd={() => setScanning(false)}
              />
            </>
          }
        >
          <SearchBar
            value={query}
            onChange={setQuery}
            placeholderKey="version_search_placeholder"
          />
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        topButtonBottom="bottom-18"
      >
        <div
          className={`h-full ${connected ? 'pl-5' : ''} pr-5 pb-4 flex flex-col gap-2`}
        >
        {installed.length === 0 && !isSearching ? (
          <div className="rounded-item border border-dashed border-outline/50 py-20 flex flex-col items-center gap-3 text-center px-6">
            <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
              <IconDownload className="w-5 h-5 text-muted" />
            </div>
            <p className="text-sm text-muted max-w-sm leading-relaxed">
              {tc('version_no_installed')}
            </p>
          </div>
        ) : filteredInstalled.length === 0 && isSearching ? (
          <div className="rounded-item border border-dashed border-outline/50 py-16 flex flex-col items-center gap-3 text-center">
            <IconSearch className="w-5 h-5 text-muted" />
            <p className="text-sm text-muted">
              {tv('no_versions_match')} <strong className="text-ink">"{query}"</strong>.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            <div className="flex items-center justify-between">
              <h3 className="text-[11px] font-semibold uppercase tracking-wider text-muted px-1">
                {tv('installed_title')}
              </h3>
              <Dropdown
                align="right"
                trigger={({ open, toggle }) => {
                  const activeOption = VERSION_SORT_OPTIONS.find((o) => o.value === installedSortBy)
                  return (
                    <motion.button
                      type="button"
                      aria-expanded={open}
                      whileHover={{ scale: 1.04 }}
                      whileTap={{ scale: 0.94 }}
                      onClick={toggle}
                      className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-7 px-3 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors"
                    >
                      <span className="text-[12px] text-muted">{tc('sort')}:</span>
                      <span className="text-[13px] font-medium text-ink">
                        {activeOption ? tv(activeOption.labelKey) : tc('sort')}
                      </span>
                      <IconChevronDown className="w-3 h-3 text-muted" />
                    </motion.button>
                  )
                }}
                items={VERSION_SORT_OPTIONS.map((opt) => ({
                  key: opt.value,
                  label: tv(opt.labelKey),
                  active: opt.value === installedSortBy,
                  onClick: () => setInstalledSortBy(opt.value),
                }))}
              />
            </div>
            <div className="flex flex-col gap-2">
              {filteredInstalled.map((v, i) => (
                <motion.div
                  key={v.tag}
                  initial={animate ? { opacity: 0, y: 10 } : false}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{
                    ...entranceTransition,
                    delay: animate ? Math.min(i * 0.05, 0.35) : 0,
                  }}
                >
                  <InstalledVersionCard
                    version={v}
                    onOpen={(console) => openVersion(v.tag, console)}
                    onRename={(name) => rename(v.tag, name)}
                    onUninstall={() => remove(v.tag)}
                  />
                </motion.div>
              ))}
            </div>
          </div>
        )}

        <section className="flex flex-col gap-2">
          <h3 className="text-[11px] font-semibold uppercase tracking-wider text-muted px-1">
            {tv('available_title')}
          </h3>
          <p className="text-xs text-muted px-1 -mt-1">{tv('available_subtitle')}</p>

          <div className="shrink-0 flex items-center gap-2">
            <Dropdown
              align="left"
              trigger={({ open, toggle }) => (
                <motion.button
                  type="button"
                  aria-expanded={open}
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.94 }}
                  onClick={toggle}
                  className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <span className="text-[13px] text-muted">{tv('source')}:</span>
                  <span className="text-[16px] font-medium text-ink">
                    {source === 'archive'
                      ? tv('source_archive')
                      : tv('source_github')}
                  </span>
                  <IconChevronDown className="w-3 h-3 text-muted" />
                </motion.button>
              )}
              items={[
                {
                  key: 'github',
                  label: tv('source_github'),
                  active: source === 'github',
                  onClick: () => refreshAvailable('github'),
                },
                {
                  key: 'archive',
                  label: tv('source_archive'),
                  active: source === 'archive',
                  onClick: () => {
                    refreshAvailable('archive')
                    setFilters((p) => ({ ...p, channel: 'stable' }))
                  },
                },
              ]}
            />
            <Dropdown
              align="left"
              trigger={({ open, toggle }) => (
                <motion.button
                  type="button"
                  aria-expanded={open}
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.94 }}
                  onClick={toggle}
                  className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <span className="text-[13px] text-muted">{tv('type')}:</span>
                  <span className="text-[16px] font-medium text-ink">
                    {filters.buildType === 'both'
                      ? tv('both')
                      : filters.buildType === 'mono'
                        ? tv('mono')
                        : tv('standard')}
                  </span>
                  <IconChevronDown className="w-3 h-3 text-muted" />
                </motion.button>
              )}
              items={[
                { key: 'standard', label: tv('standard'), active: filters.buildType === 'standard', onClick: () => setFilters((p) => ({ ...p, buildType: 'standard' })) },
                { key: 'mono', label: tv('mono'), active: filters.buildType === 'mono', onClick: () => setFilters((p) => ({ ...p, buildType: 'mono' })) },
                { key: 'both', label: tv('both'), active: filters.buildType === 'both', onClick: () => setFilters((p) => ({ ...p, buildType: 'both' })) },
              ]}
            />
            {source !== 'archive' && (
            <Dropdown
              align="left"
              trigger={({ open, toggle }) => (
                <motion.button
                  type="button"
                  aria-expanded={open}
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.94 }}
                  onClick={toggle}
                  className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <span className="text-[13px] text-muted">{tv('channel')}:</span>
                  <span className="text-[16px] font-medium text-ink">
                    {filters.channel === 'both'
                      ? tv('both')
                      : filters.channel === 'stable'
                        ? tv('stable')
                        : tv('unstable')}
                  </span>
                  <IconChevronDown className="w-3 h-3 text-muted" />
                </motion.button>
              )}
              items={[
                { key: 'stable', label: tv('stable'), active: filters.channel === 'stable', onClick: () => setFilters((p) => ({ ...p, channel: 'stable' })) },
                { key: 'unstable', label: tv('unstable'), active: filters.channel === 'unstable', onClick: () => setFilters((p) => ({ ...p, channel: 'unstable' })) },
                { key: 'both', label: tv('both'), active: filters.channel === 'both', onClick: () => setFilters((p) => ({ ...p, channel: 'both' })) },
              ]}
            />
            )}
            <Dropdown
              align="left"
              trigger={({ open, toggle }) => {
                const activeOption = VERSION_SORT_OPTIONS.find((o) => o.value === sortBy)
                return (
                  <motion.button
                    type="button"
                    aria-expanded={open}
                    whileHover={{ scale: 1.04 }}
                    whileTap={{ scale: 0.94 }}
                    onClick={toggle}
                    className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors"
                  >
                    <span className="text-[13px] text-muted">{tc('sort')}:</span>
                    <span className="text-[16px] font-medium text-ink">
                      {activeOption ? tv(activeOption.labelKey) : tc('sort')}
                    </span>
                    <IconChevronDown className="w-3 h-3 text-muted" />
                  </motion.button>
                )
              }}
              items={AVAILABLE_SORT_OPTIONS.map((opt) => ({
                key: opt.value,
                label: tv(opt.labelKey),
                active: opt.value === sortBy,
                onClick: () => setSortBy(opt.value),
              }))}
            />
          </div>

          {loadingAvailable ? (
            <div className="flex items-center gap-2 py-8 justify-center">
              <IconSpinner className="w-4 h-4 animate-spin text-muted" />
              <span className="text-sm text-muted">{tv('fetching')}</span>
            </div>
          ) : availableError ? (
            <div className="rounded-item border border-dashed border-danger/30 py-16 flex flex-col items-center gap-3 text-center px-6">
              <div className="w-12 h-12 rounded-tile bg-danger/10 border border-danger/30 flex items-center justify-center">
                <IconX className="w-5 h-5 text-danger" />
              </div>
              <p className="text-sm text-danger">{tv('fetch_error')}</p>
              <p className="text-xs text-muted font-mono break-all max-w-md">
                {availableError}
              </p>
              <motion.button
                type="button"
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => refreshAvailable()}
                className="focus-ring cursor-pointer px-4 py-2 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                {tv('retry')}
              </motion.button>
              {rateLimited && (
                <motion.button
                  type="button"
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={() => refreshAvailable('archive')}
                  className="focus-ring cursor-pointer px-4 py-2 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
                >
                  {tv('switch_to_archive')}
                </motion.button>
              )}
            </div>
          ) : isSearching && filteredAvailable.length === 0 ? (
            <p className="text-sm text-muted px-1">
              {tv('no_available_versions_match')}{" "}
              <strong className="text-ink">"{query}"</strong>.
            </p>
          ) : groupEntries.length === 0 ? (
            <p className="text-sm text-muted px-1">
              {tv('no_available_versions_match')}
            </p>
          ) : (
            <>
              <div className="flex flex-col gap-4">
                {groupEntries.slice(0, visibleGroups).map(([group, rows]) => {
                  const isCollapsed = collapsedGroups[group]
                  return (
                    <div key={group} className="flex flex-col gap-2">
                      <button
                        type="button"
                        onClick={() =>
                          setCollapsedGroups((prev) => ({
                            ...prev,
                            [group]: !prev[group],
                          }))
                        }
                        aria-expanded={!isCollapsed}
                        className="focus-ring cursor-pointer flex items-center gap-1.5 w-fit text-[11px] font-semibold uppercase tracking-wider text-muted hover:text-ink transition-colors"
                      >
                        <IconChevronDown
                          className={`w-3 h-3 transition-transform duration-200 ${
                            isCollapsed ? '-rotate-90' : ''
                          }`}
                        />
                        {group === 'Other' ? tv('other') : group}
                        <span className="text-[10px] font-medium text-muted/60">
                          {rows.length}
                        </span>
                      </button>
                      <AnimatePresence initial={false}>
                        {!isCollapsed && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            transition={{ duration: 0.18, ease: 'easeOut' }}
                            className="overflow-hidden"
                          >
                            <div className="flex flex-col gap-2">
                              {rows.map(({ tag, asset }, rowIndex) => {
                                const progressKey = downloadKey(tag, asset.name)
                                const isInstalled = installed.some(
                                  (v) =>
                                    (versionCore(v.tag) === versionCore(tag) ||
                                      versionCore(v.version) === versionCore(tag)) &&
                                    v.is_mono === asset.is_mono,
                                )
                                const dl = downloads[progressKey]
                                return (
                                  <motion.div
                                    key={progressKey}
                                    initial={animate ? { opacity: 0, y: 10 } : false}
                                    animate={{ opacity: 1, y: 0 }}
                                    transition={{
                                      ...entranceTransition,
                                      delay: animate
                                        ? Math.min(rowIndex * 0.05, 0.35)
                                        : 0,
                                    }}
                                  >
                                  <div
                                    className="flex items-center justify-between gap-3 rounded-item bg-overlay border border-outline/50 px-4 py-3 hover:border-accent-dim transition-colors"
                                  >
                                    <div className="flex items-center gap-2.5 min-w-0">
                                      <VersionTag
                                        tag={tag}
                                        state={
                                          isInstalled
                                            ? 'installed'
                                            : dl
                                              ? 'downloading'
                                              : 'available'
                                        }
                                      />
                                      {asset.is_mono && <MonoBadge />}
                                      <span className="text-xs text-muted font-mono shrink-0">
                                        {(asset.size / 1024 / 1024).toFixed(0)} {tv('mb')}
                                      </span>
                                    </div>

                                    {dl ? (
                                      <div className="flex items-center gap-2 shrink-0">
                                        {dl.status === 'queued' ? (
                                          <span className="text-xs text-muted font-mono px-2">
                                            {tv('queued')}
                                          </span>
                                        ) : (
                                          <div className="w-56">
                                            <div className="h-1.5 bg-raised rounded-full overflow-hidden">
                                              <motion.div
                                                className={`h-full rounded-full ${
                                                  dl.status === 'paused'
                                                    ? 'bg-muted'
                                                    : 'bg-amber'
                                                }`}
                                                animate={{
                                                  width: dl.total
                                                    ? `${(dl.downloaded / dl.total) * 100}%`
                                                    : '6%',
                                                }}
                                                transition={{
                                                  ease: 'easeOut',
                                                  duration: 0.3,
                                                }}
                                              />
                                            </div>
                                            <p className="text-[11px] text-muted font-mono mt-1 tabular-nums">
                                              {dl.status === 'paused'
                                                ? tv('paused_dot')
                                                : ''}
                                              {(dl.downloaded / 1024 / 1024).toFixed(1)}{' '}
                                              MB
                                              {dl.total
                                                ? ` / ${(dl.total / 1024 / 1024).toFixed(1)} MB`
                                                : ''}
                                            </p>
                                          </div>
                                        )}
                                        {dl.status === 'paused' ? (
                                          <Tooltip content={tv('resume_download')} side="top">
                                            <motion.button
                                              type="button"
                                              whileTap={{ scale: 0.9 }}
                                              onClick={() => resume(progressKey)}
                                              className="focus-ring cursor-pointer p-2 rounded-btn border border-outline/50 text-muted hover:text-mint hover:border-mint/40 transition-colors"
                                            >
                                              <IconPlay className="w-4 h-4" />
                                            </motion.button>
                                          </Tooltip>
                                        ) : dl.status === 'downloading' ? (
                                          <Tooltip content={tv('pause_download')} side="top">
                                            <motion.button
                                              type="button"
                                              whileTap={{ scale: 0.9 }}
                                              onClick={() => pause(progressKey)}
                                              className="focus-ring cursor-pointer p-2 rounded-btn border border-outline/50 text-muted hover:text-ink hover:border-accent-dim transition-colors"
                                            >
                                              <IconPause className="w-4 h-4" />
                                            </motion.button>
                                          </Tooltip>
                                        ) : null}
                                        <Tooltip content={tv('cancel_download')} side="top">
                                          <motion.button
                                            type="button"
                                            whileTap={{ scale: 0.9 }}
                                            onClick={() => cancel(progressKey)}
                                            className="focus-ring cursor-pointer p-2 rounded-btn border border-outline/50 text-muted hover:text-danger hover:border-danger/40 transition-colors"
                                          >
                                            <IconX className="w-4 h-4" />
                                          </motion.button>
                                        </Tooltip>
                                      </div>
                                    ) : isInstalled ? (
                                      <span className="text-xs text-mint font-medium shrink-0">
                                        {tv('installed_label')}
                                      </span>
                                    ) : (
                                      <div className="flex items-center gap-2 shrink-0">
                                          <motion.button
                                            type="button"
                                            whileHover={{ y: -1 }}
                                            whileTap={{ scale: 0.96 }}
                                            onClick={() =>
                                              openUrl(sourcePageUrl(source, tag))
                                            }
                                            className="focus-ring cursor-pointer flex items-center gap-1.5 h-9 px-3.5 rounded-item border border-outline/50 text-muted hover:text-ink hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                                          >
                                            <IconExternalLink className="w-3.5 h-3.5" />
                                          </motion.button>
                                        <motion.button
                                          type="button"
                                          whileHover={{ y: -1 }}
                                          whileTap={{ scale: 0.96 }}
                                          onClick={() =>
                                            download(tag, asset.name, asset.download_url)
                                          }
                                          className="focus-ring cursor-pointer flex items-center gap-1.5 h-9 px-4 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
                                        >
                                          <IconDownload className="w-3.5 h-3.5" />
                                          {tv('install')}
                                        </motion.button>
                                      </div>
                                    )}
                                  </div>
                                  </motion.div>
                                )
                              })}
                            </div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  )
                })}
              </div>
              {visibleGroups < groupEntries.length && (
                <div className="flex justify-center">
                  <motion.button
                    type="button"
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    onClick={() => setVisibleGroups((v) => v + 5)}
                    className="focus-ring cursor-pointer px-5 py-2.5 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                  >
                    {tv('show_more')}
                  </motion.button>
                </div>
              )}
            </>
          )}
        </section>
        <div className="shrink-0 h-4" aria-hidden="true" />
        </div>
      </OverlayScrollArea>

    </div>
  )
}
