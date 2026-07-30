import { openUrl } from '@tauri-apps/plugin-opener'
import { useTranslation } from 'react-i18next'
import { useNews } from '../hooks/useNews'
import {
  IconNews,
  IconClock,
  IconExternalLink,
  IconRefresh,
  IconWifiOff,
} from '../components/Icons'
import { ScrollReveal } from '../components/ui/ScrollReveal'
import type { NewsItem } from '../types'

function formatDate(iso: string | null): string | null {
  if (!iso) return null
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return null
  return d.toLocaleDateString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

function NewsCard({ item }: { item: NewsItem }) {
  const date = formatDate(item.published)

  return (
    <button
      onClick={() => openUrl(item.link)}
      className="group focus-ring cursor-pointer text-left flex flex-col gap-3 rounded-xl border border-line bg-surface p-5 hover:border-accent-dim hover:bg-raised/40 transition-colors"
    >
      <div className="flex items-center justify-between gap-3">
        {item.category ? (
          <span className="text-[10px] font-medium uppercase tracking-wide text-accent-bright bg-accent/10 border border-accent/20 rounded-full px-2.5 py-1">
            {item.category}
          </span>
        ) : (
          <span />
        )}
        <IconExternalLink className="w-3 h-3 text-muted opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
      </div>

      <h3 className="font-display font-semibold text-sm leading-snug line-clamp-2">
        {item.title}
      </h3>

      {item.summary && (
        <p className="text-xs text-muted leading-relaxed line-clamp-3">
          {item.summary}
        </p>
      )}

      <div className="mt-auto pt-1 flex items-center gap-3 text-[11px] text-muted">
        {date && (
          <span className="flex items-center gap-1.5">
            <IconClock className="w-3 h-3" />
            {date}
          </span>
        )}
        {item.author && <span className="truncate">{item.author}</span>}
      </div>
    </button>
  )
}

function NewsCardSkeleton() {
  return (
    <div className="flex flex-col gap-3 rounded-xl border border-line bg-surface p-5 animate-pulse">
      <div className="h-4 w-16 rounded-full bg-raised" />
      <div className="h-4 w-4/5 rounded bg-raised" />
      <div className="h-3 w-full rounded bg-raised" />
      <div className="h-3 w-3/4 rounded bg-raised" />
      <div className="mt-auto pt-1 h-3 w-24 rounded bg-raised" />
    </div>
  )
}

export function NewsView() {
  const { t } = useTranslation('common')
  const { items, hasMore, loading, error, fromCache, showMore, reload } =
    useNews()

  return (
    <div className="p-10 pt-6 max-w-8xl mx-auto">
      <section>
        <div className="flex items-start justify-between gap-4 mb-5">
          <div>
            <h2 className="font-body font-semibold text-3xl tracking-tight">
              {t('news_title')}
            </h2>
            <p className="text-xs text-muted">
              {t('news_subtitle')}
            </p>
          </div>
          <button
            onClick={reload}
            disabled={loading}
            className="focus-ring cursor-pointer icon-wiggle shrink-0 flex items-center gap-2 px-3.5 py-2 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-xs font-medium text-muted hover:text-ink transition-colors disabled:opacity-50 disabled:cursor-default"
          >
            <IconRefresh
              className={`w-3 h-3 ${loading ? 'animate-spin' : ''}`}
            />
            {t('refresh')}
          </button>
        </div>

        {fromCache && (
          <div className="mb-5 flex items-center gap-2.5 rounded-lg border border-line bg-raised/60 px-4 py-2.5 text-xs text-muted">
            <IconWifiOff className="w-3.5 h-3.5 shrink-0" />
            {t('news_cached')}
          </div>
        )}

        {loading && items.length === 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <NewsCardSkeleton key={i} />
            ))}
          </div>
        ) : error && items.length === 0 ? (
          <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
            <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
              <IconWifiOff className="w-5 h-5 text-muted" />
            </div>
            <p className="text-sm text-muted max-w-xs leading-relaxed">
              {t('news_error')} {error}
            </p>
            <button
              onClick={reload}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm transition-colors"
            >
              <IconRefresh className="w-3.5 h-3.5" />
              {t('try_again')}
            </button>
          </div>
        ) : items.length === 0 ? (
          <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
            <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
              <IconNews className="w-5 h-5 text-muted" />
            </div>
            <p className="text-sm text-muted max-w-xs leading-relaxed">
              {t('news_empty')}
            </p>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {items.map((item, i) => (
                <ScrollReveal key={item.id} delay={i * 0.04}>
                  <NewsCard item={item} />
                </ScrollReveal>
              ))}
            </div>

            {hasMore && (
              <div className="flex justify-center mt-6">
                <button
                  onClick={showMore}
                  className="focus-ring cursor-pointer px-5 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
                >
                  {t('show_more')}
                </button>
              </div>
            )}
          </>
        )}
      </section>
    </div>
  )
}
