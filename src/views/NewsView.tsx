import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { openUrl } from '@tauri-apps/plugin-opener'
import { useNews } from '../hooks/useNews'
import { useSettings } from '../hooks/useSettings'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ViewHeader } from '../components/reusables/ViewHeader'
import {
  IconClock,
  IconExternalLink,
  IconNews,
  IconRefresh,
  IconWifiOff,
} from '../lib/icons'
import { formatLocaleDate } from '../lib/locale'
import type { NewsItem } from '../types'

function formatDate(iso: string | null): string | null {
  if (!iso) return null
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return null
  return formatLocaleDate(d, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

function NewsCard({ item }: { item: NewsItem }) {
  const [imageFailed, setImageFailed] = useState(false)
  const date = formatDate(item.published)

  return (
    <motion.button
      type="button"
      onClick={() => openUrl(item.link).catch(() => {})}
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group focus-ring cursor-pointer text-left w-full flex flex-col gap-3 rounded-item border border-outline/50 bg-overlay p-5 mb-3 break-inside-avoid overflow-hidden hover:border-accent-dim/70 hover:bg-raised transition-colors"
    >
      {item.image && !imageFailed && (
        <div className="relative -mx-5 -mt-5 h-36 shrink-0 overflow-hidden">
          <img
            src={item.image}
            alt=""
            loading="lazy"
            decoding="async"
            className="absolute inset-0 w-full h-full object-cover"
            onError={() => setImageFailed(true)}
          />
          <div className="absolute inset-x-0 bottom-0 h-14 bg-gradient-to-t from-overlay to-transparent pointer-events-none" />
        </div>
      )}

      <div className="flex items-center justify-between gap-3">
        {item.category ? (
          <span className="text-[10px] font-semibold uppercase tracking-wider text-accent-bright bg-accent/10 border border-accent-dim/30 rounded-tag px-2.5 py-1">
            {item.category}
          </span>
        ) : (
          <span />
        )}
        <IconExternalLink className="w-3 h-3 text-muted opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
      </div>

      <h3 className="font-display font-medium text-lg leading-snug line-clamp-2">
        {item.title}
      </h3>

      {item.summary && (
        <p className="text-xs text-muted leading-relaxed line-clamp-3">
          {item.summary}
        </p>
      )}

      <div className="mt-auto pt-1 flex items-center gap-3 text-[11px] text-muted">
        {date && (
          <span className="inline-flex items-center gap-1.5">
            <IconClock className="w-3 h-3" />
            {date}
          </span>
        )}
        {item.author && <span className="truncate">{item.author}</span>}
      </div>
    </motion.button>
  )
}

function NewsCardSkeleton() {
  return (
    <div className="flex flex-col gap-3 rounded-item border border-outline/50 bg-overlay p-5 mb-3 break-inside-avoid overflow-hidden animate-pulse">
      <div className="-mx-5 -mt-5 h-36 bg-raised" />
      <div className="h-4 w-16 rounded-tag bg-raised" />
      <div className="h-4 w-4/5 rounded bg-raised" />
      <div className="h-3 w-full rounded bg-raised" />
      <div className="h-3 w-3/4 rounded bg-raised" />
      <div className="mt-auto pt-1 h-3 w-24 rounded bg-raised" />
    </div>
  )
}

export function NewsView({ connected = false }: { connected?: boolean }) {
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const {
    items,
    total,
    hasMore,
    loading,
    error,
    fromCache,
    showMore,
    reload,
  } = useNews()

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <ViewHeader
        connected={connected}
        className="mb-4"
        title={tc('news_title')}
        metric={
          <>
            <h2 className="text-4xl font-bold text-muted">
              <AnimatedNumber value={total} />
            </h2>
            <p className="text-lg font-medium uppercase text-muted">
              {tc('news_count')}
            </p>
          </>
        }
        actions={
          <motion.button
            type="button"
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={reload}
            disabled={loading}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-overlay border border-outline/50 text-xs font-medium text-muted hover:text-ink hover:bg-raised hover:border-accent-dim transition-colors disabled:opacity-40 disabled:cursor-default"
          >
            <IconRefresh
              className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`}
            />
            {tc('refresh')}
          </motion.button>
        }
      >
        <p className="text-xs text-muted flex items-center gap-1.5 flex-wrap">
          <span>{tc('news_subtitle')}</span>
          {fromCache && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-tag bg-overlay border border-outline/50 text-[10px] text-muted/70">
              <IconWifiOff className="w-3 h-3" />
              {tc('news_cached')}
            </span>
          )}
        </p>
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        topButtonBottom={'bottom-16'}
      >
        <div className={`h-full ${connected ? 'pl-3' : ''} pr-5 pb-4`}>
          {loading && items.length === 0 ? (
            <div className="columns-1 lg:columns-2 gap-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <NewsCardSkeleton key={i} />
              ))}
            </div>
          ) : error && items.length === 0 ? (
            <div className="border border-dashed border-danger/30 rounded-item py-24 flex flex-col items-center gap-4 text-center">
              <div className="w-12 h-12 rounded-tile bg-danger/10 border border-danger/30 flex items-center justify-center">
                <IconWifiOff className="w-5 h-5 text-danger" />
              </div>
              <p className="text-sm text-muted max-w-xs leading-relaxed">
                {tc('news_error')} {error}
              </p>
              <button
                onClick={reload}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2 rounded-item border border-outline/50 hover:bg-raised text-xs font-medium text-ink transition-colors"
              >
                <IconRefresh className="w-3.5 h-3.5" />
                {tc('try_again')}
              </button>
            </div>
          ) : items.length === 0 ? (
            <div className="border border-dashed border-outline/50 rounded-item py-24 flex flex-col items-center gap-4 text-center">
              <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
                <IconNews className="w-5 h-5 text-muted" />
              </div>
              <p className="text-sm text-muted max-w-xs leading-relaxed">
                {tc('news_empty')}
              </p>
            </div>
          ) : (
            <>
              <div className="columns-1 lg:columns-2 gap-3">
                {items.map((item) => (
                  <NewsCard key={item.id} item={item} />
                ))}
              </div>

              {hasMore && (
                <div className="flex justify-center mt-6">
                  <motion.button
                    type="button"
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    onClick={showMore}
                    className="focus-ring cursor-pointer h-9 px-5 rounded-item bg-overlay border border-outline/50 text-sm font-medium text-ink hover:bg-raised hover:border-accent-dim transition-colors"
                  >
                    {tc('show_more')}
                  </motion.button>
                </div>
              )}
            </>
          )}
          <div className="shrink-0 h-4" aria-hidden="true" />
        </div>
      </OverlayScrollArea>
    </div>
  )
}
