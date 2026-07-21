import { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useSettings } from '../hooks/useSettings'
import { api } from '../lib/api'
import { VersionBadge } from '../components/ui/VersionBadge'
import { ContextMenu, type ContextMenuSection } from '../components/ui/ContextMenu'
import { Tooltip } from '../components/ui/Tooltip'
import {
  IconDownload,
  IconTrash,
  IconPencil,
  IconX,
  IconRefresh,
  IconImport,
  IconChevronDown,
  IconPause,
  IconPlay,
  IconExternalLink,
} from '../components/Icons'
import { ScrollReveal } from '../components/ui/ScrollReveal'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'

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
  const m = tag
    .trim()
    .replace(/^v/, '')
    .match(/^(\d+)\.(\d+)/)
  return m ? `${m[1]}.${m[2]}` : 'Other'
}

const VERSION_FILTERS_KEY = 'godothub_version_filters'

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

function FilterDropdown({
  label,
  value,
  options,
  onChange,
}: {
  label: string
  value: string
  options: { value: string; label: string }[]
  onChange: (value: string) => void
}) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const selected = options.find((o) => o.value === value)

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={`focus-ring cursor-pointer flex items-center gap-2 pl-3 pr-2 py-1.5 rounded-lg bg-surface border text-xs text-ink transition-colors ${
          open ? 'border-accent' : 'border-line hover:border-accent-dim'
        }`}
      >
        <span className="text-muted">{label}:</span>
        <span className="font-medium">{selected?.label ?? ''}</span>
        <IconChevronDown
          className={`w-3 h-3 text-muted transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -4, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -4, scale: 0.97 }}
            transition={{ duration: 0.12, ease: 'easeOut' }}
            className="absolute z-20 mt-1.5 min-w-32 rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-1.5 origin-top"
          >
            {options.map((o) => (
              <button
                key={o.value}
                type="button"
                onClick={() => {
                  onChange(o.value)
                  setOpen(false)
                }}
                className={`w-full text-left px-3 py-1.5 rounded-lg text-xs transition-colors ${
                  value === o.value
                    ? 'bg-accent/20 text-accent-bright'
                    : 'text-ink hover:bg-raised'
                }`}
              >
                {o.label}
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export function VersionsView() {
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
    scanProgress,
  } = useGodotVersionsContext()
  const { settings } = useSettings()
  const [contextMenu, setContextMenu] = useState<{
    x: number
    y: number
    versionTag: string
  } | null>(null)
  const [scanning, setScanning] = useState(false)
  const [importing, setImporting] = useState(false)
  const [dialogMinimized, setDialogMinimized] = useState(false)
  const [collapsedGroups, setCollapsedGroups] = useState<
    Record<string, boolean>
  >({})
  const [visibleGroups, setVisibleGroups] = useState(5)
  const [filters, setFilters] = useState<VersionFilters>(loadVersionFilters)

  useEffect(() => {
    try {
      localStorage.setItem(VERSION_FILTERS_KEY, JSON.stringify(filters))
    } catch {}
  }, [filters])

  const handleImportVersion = async (folder?: string) => {
    const dir = folder ?? (await api.pickFolder())
    if (!dir) return
    if (scanning || importing) return
    setDialogMinimized(false)
    setImporting(true)
    try {
      const imported = await api.importVersion(dir)
      await refreshInstalled()
      if (imported.length > 1) {
        alert(`Imported ${imported.length} versions from that folder.`)
      }
    } catch (e) {
    } finally {
      setImporting(false)
    }
  }

  const importVersionRef = useRef(handleImportVersion)
  importVersionRef.current = handleImportVersion
  useEffect(() => {
    const handler = () => importVersionRef.current()
    window.addEventListener('app:import-version', handler)
    return () => window.removeEventListener('app:import-version', handler)
  }, [])

  const handleScanNow = async () => {
    if (scanning) return
    setDialogMinimized(false)
    setScanning(true)
    try {
      if (settings.version_scan_dirs.length) {
        await api.scanForVersions(
          settings.version_scan_dirs,
          settings.scan_depth,
        )
        await refreshInstalled()
      }
    } finally {
      setScanning(false)
    }
  }

  const scanNowRef = useRef(handleScanNow)
  scanNowRef.current = handleScanNow
  useEffect(() => {
    const handler = () => scanNowRef.current()
    window.addEventListener('app:scan-versions', handler)
    return () => window.removeEventListener('app:scan-versions', handler)
  }, [])

  const startEditing = (tag: string, current: string | null | undefined) => {
    const name = prompt('Rename version', current ?? tag)
    if (name !== null && name.trim()) {
      rename(tag, name.trim())
    }
  }

  return (
    <div className="p-10 pt-15 max-w-8xl mx-auto">
      <section>
        <div className="flex items-center justify-between">
          <h2 className="font-body font-semibold text-3xl tracking-tight">
            INSTALLED VERSIONS
          </h2>
          <div className="flex items-center gap-3">
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => handleImportVersion()}
              disabled={scanning || importing}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
            >
              <span className="icon-wiggle inline-flex">
                <IconImport className="w-4 h-4" />
              </span>
              {importing ? 'Importing…' : 'Import'}
            </motion.button>
            <Tooltip
              content="Add a scan folder in Settings first"
              side="bottom"
            >              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={handleScanNow}
                disabled={scanning || settings.version_scan_dirs.length === 0}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <span
                  className={`icon-wiggle inline-flex ${scanning ? 'animate-spin' : ''}`}
                >
                  <IconRefresh className="w-4 h-4" />
                </span>
                {scanning ? 'Scanning…' : 'Scan Now'}
              </motion.button>
            </Tooltip>
            </div>
        </div>
        <p className="text-xs text-muted mb-5 mt-[-3px]">
          Engines available to bind to a project.
        </p>

        {installed.length === 0 ? (
          <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center mb-5">
            <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
              <IconDownload className="w-5 h-5 text-muted" />
            </div>
            <p className="text-sm text-muted max-w-xs leading-relaxed">
              No versions installed. Download a version from below or drag and
              drop your existing version folder here.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-3 mb-5">
            {installed.map((v) => (
              <ScrollReveal key={v.tag} delay={0.03}>
              <div
                onContextMenu={(e) => {
                  e.preventDefault()
                  setContextMenu({ x: e.clientX, y: e.clientY, versionTag: v.tag })
                }}
                className="flex items-center justify-between border border-line rounded-xl px-5 py-4 bg-surface hover:border-accent-dim transition-all duration-200"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <VersionBadge
                    tag={v.tag}
                    state="installed"
                    customName={v.custom_name}
                  />
                  {v.is_mono && (
                    <span className="text-xs px-2 py-1 rounded-md bg-accent/10 text-accent-bright border border-accent-dim/40 shrink-0">
                      Mono
                    </span>
                  )}
                  <Tooltip content="Rename this version">
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        startEditing(v.tag, v.custom_name)
                      }}
                      aria-label="Rename version"
                      className="icon-wiggle focus-ring cursor-pointer p-1.5 rounded-lg text-muted/60 hover:text-ink hover:bg-raised transition-colors shrink-0"
                    >
                      <IconPencil className="w-3.5 h-3.5" />
                    </button>
                  </Tooltip>
                </div>
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={(e) => {
                    e.stopPropagation()
                    remove(v.tag)
                  }}
                  className="icon-wiggle cursor-pointer focus-ring flex items-center gap-2 px-3.5 py-2 rounded-lg border border-line text-muted hover:text-danger hover:border-danger/50 text-sm transition-colors shrink-0"
                >
                  <IconTrash className="w-3.5 h-3.5" />
                  Uninstall
                </motion.button>
              </div>
              </ScrollReveal>
            ))}
          </div>
        )}
      </section>

      <section>
        <h2 className="font-body font-semibold text-3xl tracking-tight">
          AVAILABLE VERSIONS
        </h2>
        <p className="text-xs text-muted mb-3">
          Pulled from Godot's official release builds.
        </p>

        <div className="flex flex-wrap items-center gap-3 mb-5 px-3.5 py-2.5 rounded-lg bg-raised border border-line">
          <FilterDropdown
            label="Type"
            value={filters.buildType}
            onChange={(v) =>
              setFilters((prev) => ({
                ...prev,
                buildType: v as VersionFilters['buildType'],
              }))
            }
            options={[
              { value: 'standard', label: 'Standard' },
              { value: 'mono', label: 'Mono' },
              { value: 'both', label: 'Both' },
            ]}
          />
          <FilterDropdown
            label="Channel"
            value={filters.channel}
            onChange={(v) =>
              setFilters((prev) => ({
                ...prev,
                channel: v as VersionFilters['channel'],
              }))
            }
            options={[
              { value: 'stable', label: 'Stable' },
              { value: 'unstable', label: 'Unstable' },
              { value: 'both', label: 'Both' },
            ]}
          />
        </div>

        {loadingAvailable ? (
          <p className="text-sm text-muted">Fetching releases…</p>
        ) : availableError ? (
          <div className="border border-dashed border-danger/50 rounded-2xl py-24 flex flex-col items-center gap-4 text-center px-6">
            <div className="w-12 h-12 rounded-xl bg-danger/10 border border-danger/30 flex items-center justify-center">
              <IconX className="w-5 h-5 text-danger" />
            </div>
            <p className="text-sm text-danger">
              Couldn't fetch available versions.
            </p>
            <p className="text-xs text-muted font-mono break-all max-w-md">
              {availableError}
            </p>
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => refreshAvailable()}
              className="focus-ring px-4 py-2 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
            >
              Retry
            </motion.button>
          </div>
        ) : (
          (() => {
            const groupEntries = Object.entries(
              available
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
                .reduce<
                  Record<
                    string,
                    {
                      tag: string
                      asset: (typeof available)[number]['assets'][number]
                    }[]
                  >
                >((groups, row) => {
                  ;(groups[minorGroup(row.tag)] ??= []).push(row)
                  return groups
                }, {}),
            ).sort(([a], [b]) =>
              b.localeCompare(a, undefined, { numeric: true }),
            )

            return (
              <>
                <div className="flex flex-col gap-6">
                  {groupEntries.slice(0, visibleGroups).map(([group, rows]) => {
                    const isCollapsed = collapsedGroups[group]
                    return (
                      <div key={group} className="flex flex-col gap-3">
                        <button
                          onClick={() =>
                            setCollapsedGroups((prev) => ({
                              ...prev,
                              [group]: !prev[group],
                            }))
                          }
                          className="focus-ring cursor-pointer flex items-center gap-1.5 text-xs font-semibold text-muted uppercase tracking-wide w-fit"
                        >
                          <IconChevronDown
                            className={`w-3 h-3 transition-transform ${isCollapsed ? '-rotate-90' : ''}`}
                          />
                          {group}
                        </button>
                        <AnimatePresence initial={false}>
                          {!isCollapsed && (
                            <motion.div
                              initial={{ opacity: 0, height: 0 }}
                              animate={{ opacity: 1, height: 'auto' }}
                              exit={{ opacity: 0, height: 0 }}
                              transition={{ duration: 0.15 }}
                              className="flex flex-col gap-3 overflow-hidden"
                            >
                              {rows.map(({ tag, asset }) => {
                                const progressKey = asset.is_mono
                                  ? `${tag}-mono`
                                  : tag
                                const isInstalled = installed.some(
                                  (v) =>
                                    (versionCore(v.tag) === versionCore(tag) ||
                                      versionCore(v.version) ===
                                        versionCore(tag)) &&
                                    v.is_mono === asset.is_mono,
                                )
                                const dl = downloads[progressKey]
                                return (
                                  <ScrollReveal key={progressKey} delay={0.02}>
                                  <div className="flex items-center justify-between border border-line rounded-xl px-5 py-4 bg-surface hover:border-accent-dim transition-colors"
                                  >
                                    <div className="flex items-center gap-3">
                                      <VersionBadge
                                        tag={tag}
                                        state={
                                          isInstalled
                                            ? 'installed'
                                            : dl
                                              ? 'downloading'
                                              : 'available'
                                        }
                                      />
                                      {asset.is_mono && (
                                        <span className="text-xs px-2 py-1 rounded-md bg-accent/10 text-accent-bright border border-accent-dim/40 shrink-0">
                                          Mono
                                        </span>
                                      )}
                                      <span className="text-xs text-muted font-mono">
                                        {(asset.size / 1024 / 1024).toFixed(0)}{' '}
                                        MB
                                      </span>
                                    </div>

                                    {dl ? (
                                      <div className="flex items-center gap-2">
                                        {dl.status === 'queued' ? (
                                          <span className="text-xs text-muted font-mono px-2">
                                            Queued…
                                          </span>
                                        ) : (
                                          <div className="w-60">
                                            <div className="h-2 bg-raised rounded-full overflow-hidden">
                                              <motion.div
                                                className={`h-full rounded-full ${dl.status === 'paused' ? 'bg-muted' : 'bg-amber'}`}
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
                                            <p className="text-xs text-muted font-mono mt-1.5">
                                              {dl.status === 'paused'
                                                ? 'Paused · '
                                                : ''}
                                              {(
                                                dl.downloaded /
                                                1024 /
                                                1024
                                              ).toFixed(1)}{' '}
                                              MB
                                              {dl.total
                                                ? ` / ${(dl.total / 1024 / 1024).toFixed(1)} MB`
                                                : ''}
                                            </p>
                                          </div>
                                        )}
                                        {dl.status === 'paused' ? (
                                          <Tooltip content="Resume download">
                                            <button
                                              onClick={() => resume(progressKey)}
                                              aria-label="Resume download"
                                              className="focus-ring cursor-pointer py-2 px-3 rounded-lg border border-line text-muted hover:text-mint hover:border-mint/50 transition-colors"
                                            >
                                              <IconPlay className="w-5 h-5" />
                                            </button>
                                          </Tooltip>
                                        ) : dl.status === 'downloading' ? (
                                          <Tooltip content="Pause download">
                                            <button
                                              onClick={() => pause(progressKey)}
                                              aria-label="Pause download"
                                              className="focus-ring cursor-pointer py-2 px-3 rounded-lg border border-line text-muted hover:text-ink hover:border-accent-dim transition-colors"
                                            >
                                              <IconPause className="w-5 h-5" />
                                            </button>
                                          </Tooltip>
                                        ) : null}
                                        <Tooltip content="Cancel download">
                                          <button
                                            onClick={() => cancel(progressKey)}
                                            aria-label="Cancel download"
                                            className="focus-ring cursor-pointer py-2 px-3 rounded-lg border border-line text-muted hover:text-danger hover:border-danger/50 transition-colors"
                                          >
                                            <IconX className="w-5 h-5" />
                                          </button>
                                        </Tooltip>
                                      </div>
                                    ) : isInstalled ? (
                                      <span className="text-xs text-mint font-medium px-2">
                                        Installed
                                      </span>
                                    ) : (
                                      <motion.button
                                        whileHover={{ y: -1 }}
                                        whileTap={{ scale: 0.96 }}
                                        onClick={() =>
                                          download(
                                            tag,
                                            asset.name,
                                            asset.download_url,
                                          )
                                        }
                                        className="icon-wiggle focus-ring cursor-pointer flex items-center gap-2 px-3.5 py-2 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-40 text-sm font-medium text-white transition-colors"
                                      >
                                        <IconDownload className="w-3.5 h-3.5" />
                                        Install
                                      </motion.button>
                                    )}
                                  </div>
                                  </ScrollReveal>
                                )
                              })}
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </div>
                    )
                  })}
                </div>
                {visibleGroups < groupEntries.length && (
                  <div className="flex justify-center mt-5">
                    <motion.button
                      whileHover={{ y: -1 }}
                      whileTap={{ scale: 0.96 }}
                      onClick={() => setVisibleGroups((v) => v + 5)}
                      className="focus-ring cursor-pointer px-5 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                    >
                      Show more
                    </motion.button>
                  </div>
                )}
              </>
            )
          })()
        )}
      </section>

      {(scanning || importing) && !dialogMinimized && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-surface border border-line rounded-2xl px-8 py-6 flex flex-col items-center gap-3 min-w-64">
            <IconRefresh className="w-6 h-6 animate-spin text-accent" />
            <p className="text-sm font-medium text-ink">
              {importing
                ? 'Importing version…'
                : scanProgress && scanProgress.total > 0
                  ? `Importing ${scanProgress.current}/${scanProgress.total} versions…`
                  : 'Scanning for versions…'}
            </p>
            {(scanProgress && scanProgress.total > 0) && (
              <div className="h-1.5 w-full rounded-full bg-line overflow-hidden">
                <div
                  className="h-full bg-accent transition-all duration-200"
                  style={{
                    width: `${(scanProgress.current / scanProgress.total) * 100}%`,
                  }}
                />
              </div>
            )}
            <button
              onClick={() => setDialogMinimized(true)}
              className="focus-ring cursor-pointer text-xs text-muted hover:text-ink transition-colors mt-1"
            >
              Resume in background
            </button>
          </div>
        </div>
      )}

      <AnimatePresence>
        {contextMenu && (
          <ContextMenu
            position={{ x: contextMenu.x, y: contextMenu.y }}
            onClose={() => setContextMenu(null)}
            items={buildVersionMenuItems(contextMenu.versionTag)}
          />
        )}
      </AnimatePresence>
    </div>
  )

  function buildVersionMenuItems(tag: string): ContextMenuSection[] {
    const version = installed.find((v) => v.tag === tag)
    const execPath = version?.executable_path
    return [
      {
        label: 'Rename',
        icon: IconPencil,
        onClick: () => startEditing(tag, version?.custom_name),
      },
      {
        label: 'Open Install Folder',
        icon: IconExternalLink,
        onClick: () => {
          if (execPath) {
            const dir = execPath.replace(/[/\\][^/\\]*$/, '')
            if (dir && dir !== execPath) api.openProjectFolder(dir).catch(() => {})
          }
        },
      },
      { type: 'separator' },
      {
        label: 'Uninstall',
        icon: IconTrash,
        variant: 'danger',
        onClick: () => remove(tag),
      },
    ]
  }
}
