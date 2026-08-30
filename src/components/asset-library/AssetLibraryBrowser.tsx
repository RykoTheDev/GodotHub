import { useCallback, useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { openUrl } from '@tauri-apps/plugin-opener'
import { api } from '../../lib/api'
import type {
  AssetLibraryAsset,
  AssetLibraryResponse,
} from '../../types'
import { cachedAssetSearch } from '../../lib/assetSearchCache'
import { isReducedMotion } from '../../lib/appearance'
import {
  ASSET_SORT_KEYS,
  assetSortParams,
  rankByRelevance,
  type AssetSortKey,
} from '../../lib/assetSort'
import { Dropdown } from '../ui/Dropdown'
import { AssetCard } from './AssetCard'
import {
  IconCheck,
  IconChevronDown,
  IconChevronLeft,
  IconChevronRight,
  IconDownload,
  IconSpinner,
  IconStore,
  IconX,
} from '../../lib/icons'
import { ConfirmDialog } from '../modals/ConfirmDialog'

const PAGE_SIZE = 12

// Module-level set to persist installing state across component mounts
const installingAssets = new Set<string>()

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

function versionMatches(assetVersion: string, target: string): boolean {
  const a = assetVersion.trim().replace(/^v/, '').split(/[.\-+]/)
  const t = target.trim().split('.')
  return a[0] === t[0] && (a[1] ?? '') === (t[1] ?? '')
}

const MAX_EMPTY_SKIP = 15
const PROBE_DEPTH = 5
const GATHER_LIMIT = PAGE_SIZE * 3
const GATHER_EMPTY_RUN = 5

export function AssetLibraryBrowser({
  query,
  onStatsChange,
  installedTemplateNames = [],
}: {
  query: string
  onStatsChange?: (stats: { loading: boolean; total: number }) => void
  installedTemplateNames?: string[]
}) {
  const { t } = useTranslation('common')
  const [assets, setAssets] = useState<AssetLibraryAsset[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [version, setVersion] = useState('')
  const [sort, setSort] = useState<AssetSortKey>('relevance')
  const [page, setPage] = useState(0)
  const [pages, setPages] = useState(0)
  const [total, setTotal] = useState(0)
  const [installing, setInstalling] = useState<string | null>(() => {
    // Restore from module-level set on mount
    const values = Array.from(installingAssets)
    return values.length > 0 ? values[0] : null
  })
  const [installed, setInstalled] = useState<Set<string>>(new Set())
  const [paging, setPaging] = useState(false)
  const [duplicateAsset, setDuplicateAsset] = useState<AssetLibraryAsset | null>(null)
  const searchTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const rootRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    onStatsChange?.({ loading, total })
  }, [loading, total, onStatsChange])

  const isExactVersion = useCallback(
    (a: AssetLibraryAsset) =>
      version === '' || versionMatches(a.godot_version, version),
    [version],
  )

  const pagesRef = useRef(pages)
  pagesRef.current = pages

  const fetchPage = useCallback(
    async (nextPage: number): Promise<AssetLibraryResponse | null> => {
      try {
        const { sort: sortParam, reverse } = assetSortParams(sort)
        return await cachedAssetSearch(
          `lib|${query.trim()}|${version || ''}|${nextPage}|${sortParam}|${reverse}`,
          () =>
            api.searchAssetLibrary(
              query.trim() || null,
              version || VERSION_OPTIONS[0],
              nextPage,
              PAGE_SIZE,
              null,
              null,
              sortParam,
              reverse,
            ),
        )
      } catch (e) {
        setError(String(e))
        return null
      }
    },
    [query, version, sort],
  )

  const load = useCallback(
    async (nextPage: number): Promise<AssetLibraryResponse | null> => {
      const res = await fetchPage(nextPage)
      if (!res) return null
      const filtered = res.assets.filter(isExactVersion)
      setAssets(
        sort === 'relevance' && query.trim()
          ? rankByRelevance(filtered, query)
          : filtered,
      )
      setPages(res.pages)
      setTotal(res.total)
      setPage(Math.min(res.page, Math.max(0, res.pages - 1)))
      setError(null)
      return res
    },
    [fetchPage, query, sort, isExactVersion],
  )

  const [canPrev, setCanPrev] = useState(false)
  const [canNext, setCanNext] = useState(false)

  const probeNeighbors = useCallback(
    async (cursor: number) => {
      if (version === '') {
        setCanPrev(cursor > 0)
        setCanNext(cursor + 1 < pagesRef.current)
        return
      }
      let prev = false
      let next = false
      for (let i = 1; i <= PROBE_DEPTH && !(prev && next); i++) {
        if (!prev && cursor - i >= 0) {
          const r = await fetchPage(cursor - i)
          if (r && r.assets.some(isExactVersion)) prev = true
        }
        if (!next && cursor + i < pagesRef.current) {
          const r = await fetchPage(cursor + i)
          if (r && r.assets.some(isExactVersion)) next = true
        }
      }
      setCanPrev(prev)
      setCanNext(next)
    },
    [version, fetchPage, isExactVersion],
  )

  const gatherAll = useCallback(
    async (startPage: number) => {
      let collected: AssetLibraryAsset[] = []
      let emptyRun = 0
      let cursor = startPage
      for (
        let i = 0;
        i <= MAX_EMPTY_SKIP && collected.length < GATHER_LIMIT;
        i++
      ) {
        const res = await fetchPage(cursor)
        if (!res) break
        const matched = res.assets.filter(isExactVersion)
        if (matched.length > 0) {
          collected = collected.concat(matched)
          emptyRun = 0
        } else {
          emptyRun += 1
          if (collected.length > 0 && emptyRun >= GATHER_EMPTY_RUN) break
        }
        cursor += 1
        if (cursor >= res.pages) break
      }
      setAssets(
        sort === 'relevance' && query.trim()
          ? rankByRelevance(collected, query)
          : collected,
      )
      setTotal(collected.length)
      setPages(1)
      setPage(0)
      setCanPrev(false)
      setCanNext(false)
    },
    [fetchPage, isExactVersion, sort, query],
  )

  const runSearch = useCallback(async () => {
    setLoading(true)
    let cursor = 0
    let landedPage = 0
    let landedRes: AssetLibraryResponse | null = null
    for (let i = 0; i <= MAX_EMPTY_SKIP; i++) {
      const res = await load(cursor)
      if (res) {
        landedPage = Math.min(res.page, Math.max(0, res.pages - 1))
        landedRes = res
      }
      if (!res || res.assets.some(isExactVersion)) break
      cursor += 1
    }
    if (version !== '' && landedRes) {
      const firstCount = landedRes.assets.filter(isExactVersion).length
      if (firstCount > 0 && firstCount < PAGE_SIZE) {
        await gatherAll(landedPage)
        setLoading(false)
        return
      }
    }
    setLoading(false)
    await probeNeighbors(landedPage)
  }, [load, isExactVersion, version, gatherAll, probeNeighbors])

  useEffect(() => {
    setError(null)
    if (searchTimer.current) clearTimeout(searchTimer.current)
    searchTimer.current = setTimeout(runSearch, 250)
    return () => {
      if (searchTimer.current) clearTimeout(searchTimer.current)
    }
  }, [query, version, sort, runSearch])

  const navigate = async (target: number) => {
    if (paging || pages <= 1) return
    const clamped = Math.max(0, Math.min(target, pages - 1))
    const dir = clamped >= page ? 1 : -1
    setPaging(true)
    let cursor = clamped
    let landedPage = clamped
    for (let i = 0; i <= MAX_EMPTY_SKIP; i++) {
      const res = await load(cursor)
      if (res) landedPage = Math.min(res.page, Math.max(0, res.pages - 1))
      if (!res || res.assets.some(isExactVersion)) break
      cursor += dir
      if (cursor < 0 || cursor >= pages) break
    }
    await probeNeighbors(landedPage)
    setPaging(false)
    const viewport = rootRef.current?.closest('.new-ui-scroll-viewport')
    viewport?.scrollTo({
      top: 0,
      behavior: isReducedMotion() ? 'auto' : 'smooth',
    })
  }

  const isAlreadyInstalled = (asset: AssetLibraryAsset) =>
    installedTemplateNames.some(
      (name) => name.toLowerCase() === asset.title.toLowerCase(),
    )

  const doInstall = async (asset: AssetLibraryAsset) => {
    if (installing || installingAssets.has(asset.asset_id)) return
    installingAssets.add(asset.asset_id)
    setInstalling(asset.asset_id)
    setDuplicateAsset(null)
    try {
      await api.installAssetAsTemplate(asset.asset_id)
      setInstalled((prev) => new Set(prev).add(asset.asset_id))
      window.dispatchEvent(new Event('app:refresh-templates'))
    } catch {
    } finally {
      installingAssets.delete(asset.asset_id)
      setInstalling(null)
    }
  }

  const install = (asset: AssetLibraryAsset) => {
    if (isAlreadyInstalled(asset)) {
      setDuplicateAsset(asset)
      return
    }
    doInstall(asset)
  }

  const dropBtnClass =
    'focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors'

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

  return (
    <div ref={rootRef} className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        <Dropdown
          align="left"
          trigger={({ open, toggle }) => (
            <motion.button
              type="button"
              aria-expanded={open}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.94 }}
              onClick={toggle}
              className={dropBtnClass}
            >
              <span className="text-[16px] font-medium text-ink">
                {t(`asset_store_${sort}`)}
              </span>
              <IconChevronDown className="w-3 h-3 text-muted" />
            </motion.button>
          )}
          items={ASSET_SORT_KEYS.map((k) => ({
            key: k,
            label: t(`asset_store_${k}`),
            active: sort === k,
            onClick: () => setSort(k),
          }))}
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
              className={dropBtnClass}
            >
              <span className="text-[16px] font-medium text-ink">
                {version ? `Godot ${version}` : t('asset_all_versions')}
              </span>
              <IconChevronDown className="w-3 h-3 text-muted" />
            </motion.button>
          )}
          items={[
            {
              key: 'all',
              label: t('asset_all_versions'),
              active: version === '',
              onClick: () => setVersion(''),
            },
            ...VERSION_OPTIONS.map((v) => ({
              key: v,
              label: `Godot ${v}`,
              active: version === v,
              onClick: () => setVersion(v),
            })),
          ]}
        />
        {!loading && (
          <span className="text-[11px] text-muted/60 shrink-0 ml-auto">
            {t('asset_result_count', { count: total })}
          </span>
        )}
      </div>

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
              <div className="px-4 pb-4 pt-1">
                <div className="h-9 w-full rounded-item bg-raised" />
              </div>
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="rounded-item border border-dashed border-danger/30 py-20 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-tile bg-danger/10 border border-danger/30 flex items-center justify-center">
            <IconX className="w-5 h-5 text-danger" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">{t('asset_load_error')}</p>
          <button
            onClick={() => runSearch()}
            className="focus-ring cursor-pointer px-4 py-2 rounded-item border border-outline/50 hover:bg-raised text-xs font-medium text-ink transition-colors"
          >
            {t('retry')}
          </button>
        </div>
      ) : assets.length === 0 ? (
        <div className="rounded-item border border-dashed border-outline/50 py-20 flex flex-col items-center gap-4 text-center">
          <IconStore className="w-6 h-6 text-muted" />
          <p className="text-sm text-muted max-w-xs leading-relaxed">{t('asset_no_results')}</p>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            <AnimatePresence mode="popLayout">
              {assets.map((asset) => {
                const isInstalled = installed.has(asset.asset_id)
                const isAlreadyPresent = isAlreadyInstalled(asset)
                const isInstalling = installing === asset.asset_id || installingAssets.has(asset.asset_id)
                return (
                  <AssetCard
                    key={asset.asset_id}
                    asset={asset}
                    onOpenPage={
                      asset.browse_url
                        ? () => openUrl(asset.browse_url!)
                        : undefined
                    }
                    actions={
                      <motion.button key="button-440"
                        whileHover={isInstalled || isInstalling ? undefined : { scale: 1.04 }}
                        whileTap={isInstalled || isInstalling ? undefined : { scale: 0.94 }}
                        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                        onClick={() => install(asset)}
                        disabled={isInstalling}
                        className={`focus-ring cursor-pointer flex items-center justify-center gap-1.5 w-full h-12 px-6 rounded-dropdown-btn font-semibold text-[17px] shadow-md shadow-black/10 border transition-colors disabled:cursor-default ${
                          isInstalled || isAlreadyPresent
                            ? 'bg-mint/10 text-mint border-mint/20'
                            : 'bg-accent text-ink hover:bg-accent-bright border-outline/50'
                        }`}
                      >
                        {isInstalling ? (
                          <>
                            <IconSpinner className="w-3.5 h-3.5 animate-spin" />
                            {t('asset_installing')}
                          </>
                        ) : isInstalled || isAlreadyPresent ? (
                          <>
                            <IconCheck className="w-3.5 h-3.5" />
                            {t('asset_installed')}
                          </>
                        ) : (
                          <>
                            <IconDownload className="w-3.5 h-3.5" />
                            {t('asset_install')}
                          </>
                        )}
                      </motion.button>
                    }
                  />
                )
              })}
            </AnimatePresence>
          </div>

          {version === '' ? (
            (page > 0 || page + 1 < pages) && (
              <div className="flex items-center justify-center gap-1.5 flex-wrap">
                <motion.button key="button-479"
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
            )
          ) : (
            (canPrev || canNext) && (
              <div className="flex items-center justify-center gap-1.5">
                <motion.button
                    type="button"
                    whileTap={{ scale: 0.94 }}
                    onClick={() => navigate(page - 1)}
                    disabled={!canPrev || paging}
                    aria-label={t('asset_prev_page')}
                    className="focus-ring cursor-pointer flex items-center justify-center w-9 h-9 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed shrink-0"
                  >
                    <IconChevronLeft className="w-4 h-4" />
                  </motion.button>
                <motion.button
                    type="button"
                    whileTap={{ scale: 0.94 }}
                    onClick={() => navigate(page + 1)}
                    disabled={!canNext || paging}
                    aria-label={t('asset_next_page')}
                    className="focus-ring cursor-pointer flex items-center justify-center w-9 h-9 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed shrink-0"
                  >
                    <IconChevronRight className="w-4 h-4" />
                  </motion.button>
              </div>
            )
          )}
        </>
      )}

      {duplicateAsset && (
        <ConfirmDialog
          title={t('asset_duplicate_title')}
          description={t('asset_duplicate_desc', { name: duplicateAsset.title })}
          confirmLabel={t('asset_install')}
          onConfirm={() => doInstall(duplicateAsset)}
          onCancel={() => setDuplicateAsset(null)}
        />
      )}
    </div>
  )
}
