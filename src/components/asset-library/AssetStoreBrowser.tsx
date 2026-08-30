import { useCallback, useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { openUrl } from '@tauri-apps/plugin-opener'
import { api } from '../../lib/api'
import { useProjectsContext } from '../../hooks/projectsContext'
import {
  assetSortParams,
  storeServerSort,
  type AssetSortKey,
  type AssetSource,
} from '../../lib/assetSort'
import type { AssetLibraryAsset } from '../../types'
import { cachedAssetSearch } from '../../lib/assetSearchCache'
import { isReducedMotion } from '../../lib/appearance'
import { OpenButton } from '../reusables/OpenButton'
import { AssetCard } from './AssetCard'
import {
  InstallAssetModal,
  type AssetInstallOutcome,
} from '../modals/InstallAssetModal'
import {
  IconCheck,
  IconChevronLeft,
  IconChevronRight,
  IconCircleCheck,
  IconCloudArrowDown,
  IconStore,
} from '../../lib/icons'

const PAGE_SIZE = 12

const VERSION_OPTIONS = [
  '4.7',
  '4.6',
  '4.5',
  '4.4',
  '4.3',
  '4.2',
  '4.1',
  '4.0',
]

function dirname(path: string): string {
  const idx = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'))
  return idx > 0 ? path.slice(0, idx) : path
}

function parseStoreId(id: string): [string, string] {
  const rest = id.startsWith('store:') ? id.slice('store:'.length) : id
  const idx = rest.indexOf('/')
  return idx > 0 ? [rest.slice(0, idx), rest.slice(idx + 1)] : [rest, '']
}

interface Props {
  query: string
  source: AssetSource
  categoryId: string
  version: string
  sort: AssetSortKey
  onStatsChange?: (stats: { loading: boolean; total: number }) => void
}

export function AssetStoreBrowser({
  query,
  source,
  categoryId,
  version,
  sort,
  onStatsChange,
}: Props) {
  const { t } = useTranslation('common')
  const { refresh: refreshProjects } = useProjectsContext()
  const [assets, setAssets] = useState<AssetLibraryAsset[]>([])
  const [loading, setLoading] = useState(true)
  const [paging, setPaging] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(0)
  const [pages, setPages] = useState(0)
  const [total, setTotal] = useState(0)
  const [installAsset, setInstallAsset] = useState<AssetLibraryAsset | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [installed, setInstalled] = useState<Set<string>>(new Set())
  const [downloaded, setDownloaded] = useState<Set<string>>(new Set())
  const [notice, setNotice] = useState<string | null>(null)
  const searchTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const noticeTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const requestSeq = useRef(0)
  const rootRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    onStatsChange?.({ loading, total })
  }, [loading, total, onStatsChange])

  const showNotice = (message: string) => {
    setNotice(message)
    if (noticeTimer.current) clearTimeout(noticeTimer.current)
    noticeTimer.current = setTimeout(() => setNotice(null), 5000)
  }

  useEffect(
    () => () => {
      if (noticeTimer.current) clearTimeout(noticeTimer.current)
    },
    [],
  )

  const load = useCallback(
    async (nextPage: number): Promise<number> => {
      const seq = ++requestSeq.current
      try {
        const { sort: librarySort, reverse } = assetSortParams(sort)
        const storeSort = storeServerSort(sort)
        const res =
          source === 'library'
            ? await cachedAssetSearch(
                `lib|${query.trim()}|${version || ''}|${nextPage}|${categoryId}|${librarySort}|${reverse}`,
                () =>
                  api.searchAssetLibrary(
                    query.trim() || null,
                    version || VERSION_OPTIONS[0],
                    nextPage,
                    PAGE_SIZE,
                    'addon',
                    categoryId || null,
                    librarySort,
                    reverse,
                  ),
              )
            : await cachedAssetSearch(
                `store|${query.trim()}|${version || ''}|${nextPage}|${storeSort}`,
                () =>
                  api.searchAssetStore(
                    query.trim() || null,
                    version || null,
                    nextPage,
                    PAGE_SIZE,
                    storeSort,
                  ),
              )

        if (requestSeq.current !== seq) return seq
        setAssets(res.assets)
        setPages(res.pages)
        setTotal(res.total)
        setPage(Math.min(nextPage, Math.max(0, res.pages - 1)))
        setError(null)
      } catch (e) {
        if (requestSeq.current !== seq) return seq
        setError(String(e))
      }
      return seq
    },
    [query, version, categoryId, sort, source],
  )

  useEffect(() => {
    setError(null)
    if (searchTimer.current) clearTimeout(searchTimer.current)
    searchTimer.current = setTimeout(async () => {
      setLoading(true)
      const seq = await load(0)
      if (requestSeq.current === seq) setLoading(false)
    }, 250)
    return () => {
      if (searchTimer.current) clearTimeout(searchTimer.current)
    }
  }, [query, version, categoryId, sort, source, load])

  const navigate = async (target: number) => {
    if (paging) return
    const clamped = Math.max(0, Math.min(target, pages - 1))
    setPaging(true)
    await load(clamped)
    setPaging(false)
    const viewport = rootRef.current?.closest('.new-ui-scroll-viewport')
    viewport?.scrollTo({
      top: 0,
      behavior: isReducedMotion() ? 'auto' : 'smooth',
    })
  }

  const pageItems = (): (number | 'ellipsis')[] => {
    const items: (number | 'ellipsis')[] = []
    if (pages <= 7) {
      for (let i = 0; i < pages; i++) items.push(i)
      return items
    }
    items.push(0)
    if (page > 2) items.push('ellipsis')
    const start = Math.max(1, page - 1)
    const end = Math.min(pages - 2, page + 1)
    for (let i = start; i <= end; i++) items.push(i)
    if (page < pages - 3) items.push('ellipsis')
    items.push(pages - 1)
    return items
  }

  const handleInstalled = (outcome: AssetInstallOutcome) => {
    setInstalled((prev) => new Set(prev).add(outcome.assetId))
    if (outcome.targetType === 'project') {
      refreshProjects()
    } else {
      window.dispatchEvent(new Event('app:refresh-templates'))
    }
    showNotice(
      outcome.targetType === 'project'
        ? t('asset_install_success_project', { target: outcome.targetName })
        : t('asset_install_success_template', { target: outcome.targetName }),
    )
  }

  const handleDownload = async (asset: AssetLibraryAsset) => {
    if (busyId) return
    setBusyId(asset.asset_id)
    try {
      const path = await api.downloadAsset(asset.asset_id)
      setDownloaded((prev) => new Set(prev).add(asset.asset_id))
      api.openProjectFolder(dirname(path)).catch(() => {})
      showNotice(`${t('asset_downloaded_to')} ${dirname(path)}`)
    } catch {
      showNotice(t('asset_download_error'))
    } finally {
      setBusyId(null)
    }
  }

  const handleStoreDownload = async (asset: AssetLibraryAsset) => {
    if (busyId) return
    setBusyId(asset.asset_id)
    try {
      const [publisherSlug, assetSlug] = parseStoreId(asset.asset_id)
      const path = await api.downloadStoreAsset(
        publisherSlug,
        assetSlug,
        asset.title,
      )
      setDownloaded((prev) => new Set(prev).add(asset.asset_id))
      api.openProjectFolder(dirname(path)).catch(() => {})
      showNotice(`${t('asset_downloaded_to')} ${dirname(path)}`)
    } catch {
      showNotice(t('asset_download_error'))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <div ref={rootRef} className="flex flex-col gap-3">
      <AnimatePresence>
        {notice && (
          <motion.div
            initial={{ opacity: 0, y: -6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -6 }}
            className="flex items-center gap-2 px-3.5 py-2.5 rounded-item border border-mint/20 bg-mint/10 text-xs text-mint"
          >
            <IconCheck className="w-3.5 h-3.5 shrink-0" />
            <span className="min-w-0 wrap-break-word">{notice}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="border border-outline/50 rounded-item bg-overlay overflow-hidden flex flex-col animate-pulse"
            >
              <div className="h-24 bg-raised" />
              <div className="p-4 flex flex-col gap-2.5 flex-1">
                <div className="h-4 w-3/4 rounded bg-raised" />
                <div className="h-3 w-1/2 rounded bg-raised" />
                <div className="flex gap-1.5 mt-1">
                  <div className="h-5 w-16 rounded-tag bg-raised" />
                  <div className="h-5 w-12 rounded-tag bg-raised" />
                </div>
              </div>
              <div className="px-4 pb-4 pt-1 flex justify-end gap-1.5">
                <div className="h-8 w-9 rounded-item bg-raised" />
                <div className="h-8 w-20 rounded-item bg-raised" />
              </div>
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="rounded-item border border-dashed border-danger/30 py-20 flex flex-col items-center gap-4 text-center">
          <IconStore className="w-6 h-6 text-muted" />
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {t('asset_load_error')}
          </p>
          <button
            onClick={() => load(0)}
            className="focus-ring cursor-pointer px-4 py-2 rounded-item border border-outline/50 hover:bg-raised text-xs font-medium text-ink transition-colors"
          >
            {t('retry')}
          </button>
        </div>
      ) : assets.length === 0 ? (
        <div className="rounded-item border border-dashed border-outline/50 py-20 flex flex-col items-center gap-4 text-center">
          <IconStore className="w-6 h-6 text-muted" />
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {t('asset_no_results')}
          </p>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            <AnimatePresence mode="popLayout">
              {assets.map((asset) => {
                const isInstalled = installed.has(asset.asset_id)
                const isDownloaded = downloaded.has(asset.asset_id)
                const isBusy = busyId === asset.asset_id
                const isStore = asset.source === 'store'
                return (
                  <AssetCard
                    key={asset.asset_id}
                    asset={asset}
                    onOpenPage={
                      asset.browse_url
                        ? () => openUrl(asset.browse_url!).catch(() => {})
                        : undefined
                    }
                    actions={
                      <div className="w-full flex justify-end">
                        <OpenButton
                          label={
                            isInstalled
                              ? t('asset_installed')
                              : t('asset_install_inside')
                          }
                          disabled={isInstalled || isBusy}
                          onOpen={() => setInstallAsset(asset)}
                          moreAriaLabel={t('asset_more_aria')}
                          className="px-8"
                          items={[
                            {
                              key: 'download',
                              label: isDownloaded
                                ? t('asset_downloaded')
                                : t('asset_download_outside'),
                              icon: isDownloaded
                                ? IconCircleCheck
                                : IconCloudArrowDown,
                              disabled: isBusy,
                              onClick: () =>
                                isStore
                                  ? handleStoreDownload(asset)
                                  : handleDownload(asset),
                            },
                          ]}
                        />
                      </div>
                    }
                  />
                )
              })}
            </AnimatePresence>
          </div>

          {(page > 0 || page + 1 < pages) && (
            <div className="flex items-center justify-center gap-1.5 flex-wrap">
                <motion.button
                  type="button"
                  whileTap={{ scale: 0.94 }}
                  onClick={() => navigate(page - 1)}
                  disabled={page <= 0 || paging}
                  aria-label={t('asset_prev_page')}
                  className="focus-ring cursor-pointer flex items-center justify-center w-9 h-9 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed shrink-0"
                >
                  <IconChevronLeft className="w-4 h-4" />
                </motion.button>
              {pageItems().map((item, i) =>
                item === 'ellipsis' ? (
                  <span
                    key={`e${i}`}
                    className="w-6 text-center text-xs text-muted/50 select-none shrink-0"
                    aria-hidden="true"
                  >
                    …
                  </span>
                ) : (
                  <motion.button
                    key={item}
                    type="button"
                    whileTap={{ scale: 0.94 }}
                    onClick={() => navigate(item)}
                    disabled={paging}
                    aria-label={t('asset_page_x_of_y', {
                      page: item + 1,
                      total: pages,
                    })}
                    aria-current={item === page ? 'page' : undefined}
                    className={`focus-ring cursor-pointer min-w-9 h-9 px-2.5 flex items-center justify-center rounded-item text-xs font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed shrink-0 ${
                      item === page
                        ? 'bg-accent text-white'
                        : 'bg-overlay border border-outline/50 text-muted hover:text-ink hover:bg-raised'
                    }`}
                  >
                    {item + 1}
                  </motion.button>
                ),
              )}
                <motion.button
                  type="button"
                  whileTap={{ scale: 0.94 }}
                  onClick={() => navigate(page + 1)}
                  disabled={page + 1 >= pages || paging}
                  aria-label={t('asset_next_page')}
                  className="focus-ring cursor-pointer flex items-center justify-center w-9 h-9 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed shrink-0"
                >
                  <IconChevronRight className="w-4 h-4" />
                </motion.button>
            </div>
          )}
        </>
      )}

      <AnimatePresence>
        {installAsset && (
          <InstallAssetModal
            asset={installAsset}
            onClose={() => setInstallAsset(null)}
            onInstalled={handleInstalled}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
