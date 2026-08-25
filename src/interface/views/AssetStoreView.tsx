import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { api } from '../../lib/api'
import { useSettings } from '../../hooks/useSettings'
import type { AssetLibraryCategory } from '../../types'
import {
  sortKeysForSource,
  type AssetSortKey,
  type AssetSource,
} from '../../lib/assetSort'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { SearchBar } from '../components/ui/SearchBar'
import { Dropdown } from '../components/ui/Dropdown'
import { AssetStoreBrowser } from '../components/asset-library/AssetStoreBrowser'
import { IconChevronDown } from '../lib/icons'

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

const SOURCE_OPTIONS: { value: AssetSource; labelKey: string }[] = [
  { value: 'library', labelKey: 'asset_source_library' },
  { value: 'store', labelKey: 'asset_source_store' },
]

const STORE_SORT_KEYS: AssetSortKey[] = [
  'relevance',
  'updated_new',
  'updated_old',
  'rating_high',
  'rating_low',
]

const dropBtnClass =
  'focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors'

export function AssetStoreView({ connected = false }: { connected?: boolean }) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const [query, setQuery] = useState('')
  const [source, setSource] = useState<AssetSource>('store')
  const [categoryId, setCategoryId] = useState('')
  const [version, setVersion] = useState('')
  const [sort, setSort] = useState<AssetSortKey>('relevance')
  const [categories, setCategories] = useState<AssetLibraryCategory[]>([])
  const [stats, setStats] = useState({ loading: true, total: 0 })

  useEffect(() => {
    api
      .listAssetLibraryCategories()
      .then(setCategories)
      .catch(() => setCategories([]))
  }, [])

  const categoryOptions = useMemo(
    () =>
      categories
        .filter((c) => c.category_type === '0')
        .map((c) => ({ value: c.id, label: c.name })),
    [categories],
  )

  useEffect(() => {
    if (categoryId && !categoryOptions.some((c) => c.value === categoryId)) {
      setCategoryId('')
    }
  }, [categoryOptions, categoryId])

  useEffect(() => {
    const keys =
      source === 'store' ? STORE_SORT_KEYS : sortKeysForSource(source)
    if (!keys.includes(sort)) setSort('relevance')
  }, [source, sort])

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col gap-2">
      <ViewHeader
        connected={connected}
        title={t('asset_store')}
        metric={
          <>
            <h2 className="text-4xl font-bold text-muted">
              <AnimatedNumber value={stats.total} />
            </h2>
            <p className="text-lg font-medium uppercase text-muted">
              {tc('asset_store_count')}
            </p>
          </>
        }
      >
        <SearchBar
          value={query}
          onChange={setQuery}
          placeholderKey="asset_search_placeholder"
        />
      </ViewHeader>

      <div className="shrink-0 pr-6 flex items-center gap-2 flex-wrap">
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
                {tc(SOURCE_OPTIONS.find((o) => o.value === source)!.labelKey)}
              </span>
              <IconChevronDown className="w-3 h-3 text-muted" />
            </motion.button>
          )}
          items={SOURCE_OPTIONS.map((o) => ({
            key: o.value,
            label: tc(o.labelKey),
            active: source === o.value,
            onClick: () => setSource(o.value),
          }))}
        />
        {source === 'library' && (
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
                <span className="text-[16px] font-medium text-ink max-w-32 truncate">
                  {categoryId
                    ? (categoryOptions.find((c) => c.value === categoryId)
                        ?.label ?? categoryId)
                    : tc('asset_category_all')}
                </span>
                <IconChevronDown className="w-3 h-3 text-muted" />
              </motion.button>
            )}
            items={[
              {
                key: 'all',
                label: tc('asset_category_all'),
                active: categoryId === '',
                onClick: () => setCategoryId(''),
              },
              ...categoryOptions.map((c) => ({
                key: c.value,
                label: c.label,
                active: categoryId === c.value,
                onClick: () => setCategoryId(c.value),
              })),
            ]}
          />
        )}
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
                {source === 'store' ? tc(`asset_store_${sort}`) : tc(`asset_sort_${sort}`)}
              </span>
              <IconChevronDown className="w-3 h-3 text-muted" />
            </motion.button>
          )}
          items={(source === 'store' ? STORE_SORT_KEYS : sortKeysForSource(source)).map((k) => ({
            key: k,
            label: source === 'store' ? tc(`asset_store_${k}`) : tc(`asset_sort_${k}`),
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
                {version ? `Godot ${version}` : tc('asset_all_versions')}
              </span>
              <IconChevronDown className="w-3 h-3 text-muted" />
            </motion.button>
          )}
          items={[
            {
              key: 'all',
              label: tc('asset_all_versions'),
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
      </div>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        topButtonBottom="bottom-14"
      >
        <div className={`h-full ${connected ? 'pl-3' : ''} pr-5 pb-4`}>
          <AssetStoreBrowser
            query={query}
            source={source}
            categoryId={categoryId}
            version={version}
            sort={sort}
            onStatsChange={setStats}
          />
          <div className="shrink-0 h-4" aria-hidden="true" />
        </div>
      </OverlayScrollArea>
    </div>
  )
}
