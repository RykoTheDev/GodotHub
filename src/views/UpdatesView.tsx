import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { openUrl } from '@tauri-apps/plugin-opener'
import { MarkdownBody } from '../components/reusables/MarkdownBody'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ScanButton } from '../components/reusables/ScanButton'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { useSettings } from '../hooks/useSettings'
import { useUpdates } from '../hooks/useUpdates'
import { useUpdatesBadge } from '../hooks/useUpdatesBadge'
import type { UpdateEntry, UpdateKind } from '../types'
import {
  IconAlertTriangle,
  IconBell,
  IconBomb,
  IconCheck,
  IconCheckCircle,
  IconClock,
  IconCopy,
  IconExternalLink,
  IconPalette,
  IconPin,
  IconRocket,
} from '../lib/icons'

const KIND_STYLES: Record<
  UpdateKind,
  { node: string; chip: string; icon: typeof IconBell }
> = {
  announcement: {
    node: 'bg-amber',
    chip: 'bg-amber/10 text-amber border-amber/20',
    icon: IconPalette,
  },
  'new-feature': {
    node: 'bg-mint',
    chip: 'bg-mint/10 text-mint border-mint/20',
    icon: IconRocket,
  },
  improvement: {
    node: 'bg-accent-bright',
    chip: 'bg-accent/15 text-accent-bright border-accent-dim/30',
    icon: IconCheckCircle,
  },
  'breaking-change': {
    node: 'bg-danger',
    chip: 'bg-danger text-white border-danger',
    icon: IconBomb,
  },
  'known-issue': {
    node: 'bg-danger',
    chip: 'bg-danger/10 text-danger border-danger/20',
    icon: IconAlertTriangle,
  },
}

const KIND_LABEL_KEYS: Record<UpdateKind, string> = {
  announcement: 'updates_tag',
  'new-feature': 'updates_kind_new_feature',
  improvement: 'updates_kind_improvement',
  'breaking-change': 'updates_kind_breaking_change',
  'known-issue': 'updates_known_issue',
}

function formatDate(at: number): string {
  if (!at) return ''
  const d = new Date(at * 1000)
  if (Number.isNaN(d.getTime())) return ''
  return d.toLocaleDateString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

function formatTimeAgo(at: number): string {
  if (!at) return ''
  const seconds = Math.max(1, Math.floor(Date.now() / 1000 - at))
  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ['year', 31536000],
    ['month', 2592000],
    ['week', 604800],
    ['day', 86400],
    ['hour', 3600],
    ['minute', 60],
  ]
  for (const [unit, secondsPer] of units) {
    const value = Math.floor(seconds / secondsPer)
    if (value >= 1) {
      return new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' }).format(
        -value,
        unit,
      )
    }
  }
  return new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' }).format(
    -seconds,
    'second',
  )
}

function CardContent({
  entry,
  featured = false,
}: {
  entry: UpdateEntry
  featured?: boolean
}) {
  const { t } = useTranslation('common')
  const [copied, setCopied] = useState(false)
  const copyTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const style = KIND_STYLES[entry.kind] ?? KIND_STYLES.announcement

  useEffect(
    () => () => {
      if (copyTimer.current) clearTimeout(copyTimer.current)
    },
    [],
  )

  const copyCommand = async () => {
    if (!entry.command) return
    try {
      await navigator.clipboard.writeText(entry.command)
      setCopied(true)
      if (copyTimer.current) clearTimeout(copyTimer.current)
      copyTimer.current = setTimeout(() => setCopied(false), 1600)
    } catch {}
  }

  return (
    <div className="min-w-0 flex-1">
      <div className="flex items-center gap-2 mb-2 flex-wrap">
        {featured && (
          <span className="inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-tag bg-accent/15 text-accent-bright border border-accent-dim/40">
            <IconPin className="w-3 h-3" />
            {t('updates_featured')}
          </span>
        )}
        <span
          className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-tag border ${style.chip}`}
        >
          {t(KIND_LABEL_KEYS[entry.kind] ?? 'updates_tag')}
        </span>
        {entry.is_new && (
          <span className="text-[10px] font-semibold uppercase tracking-wider px-2 py-0.5 rounded-tag bg-accent/15 text-accent-bright border border-accent-dim/30">
            {t('updates_new')}
          </span>
        )}
        {entry.created_at > 0 && (
          <span className="ml-auto inline-flex items-center gap-1 text-[10px] text-muted/60 shrink-0">
            <IconClock className="w-3 h-3" />
            {formatDate(entry.created_at)}
          </span>
        )}
      </div>

      <h2
        className={`font-display font-semibold leading-snug ${
          featured ? 'text-xl' : 'text-lg'
        }`}
      >
        {entry.title}
      </h2>

      <div className="mt-2">
        <MarkdownBody>{entry.body}</MarkdownBody>
      </div>

      {entry.command && (
        <div className="mt-3 flex items-center gap-2 rounded-btn bg-base border border-outline/50 px-3 py-2.5">
          <code className="flex-1 min-w-0 font-mono text-xs text-ink whitespace-pre-wrap break-all">
            {entry.command}
          </code>
          <button
              onClick={copyCommand}
              aria-label={copied ? t('updates_copied') : t('updates_copy')}
              className="focus-ring cursor-pointer shrink-0 p-1.5 rounded-btn text-muted/60 hover:text-ink hover:bg-raised transition-colors"
            >
              {copied ? (
                <IconCheck className="w-3.5 h-3.5 text-mint" />
              ) : (
                <IconCopy className="w-3.5 h-3.5" />
              )}
            </button>
        </div>
      )}
    </div>
  )
}

function CardMeta({
  entry,
  featured,
}: {
  entry: UpdateEntry
  featured?: boolean
}) {
  const { t } = useTranslation('common')
  const style = KIND_STYLES[entry.kind] ?? KIND_STYLES.announcement
  const Icon = style.icon

  return (
    <div className="flex flex-col items-end gap-2 shrink-0">
      <span
        className={`w-9 h-9 rounded-tile border flex items-center justify-center ${
          featured
            ? 'bg-accent/15 text-accent-bright border-accent-dim/40'
            : style.chip
        }`}
      >
        {featured ? <IconPin className="w-4 h-4" /> : <Icon className="w-4 h-4" />}
      </span>
      {entry.link && /^https?:\/\//i.test(entry.link) && (
        <button
          onClick={() => openUrl(entry.link!).catch(() => {})}
          className="focus-ring cursor-pointer flex items-center gap-1 px-2 py-1 rounded-tag border border-outline/50 text-[10px] font-medium text-muted hover:text-ink hover:border-accent-dim transition-colors"
        >
          <IconExternalLink className="w-3 h-3" />
          {t('updates_open')}
        </button>
      )}
    </div>
  )
}

function FeaturedCard({ entry }: { entry: UpdateEntry }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="relative overflow-hidden rounded-item border border-accent-dim/50 bg-linear-to-br from-raised via-surface to-accent-dim/10 p-6 hover:border-accent-dim/80 transition-colors"
    >
      <div className="absolute -top-24 -right-24 w-64 h-64 rounded-full bg-accent/10 blur-3xl pointer-events-none" />
      <div className="relative flex items-start gap-4">
        <CardContent entry={entry} featured />
        <CardMeta entry={entry} featured />
      </div>
    </motion.div>
  )
}

function EntryCard({ entry, isLast }: { entry: UpdateEntry; isLast: boolean }) {
  const style = KIND_STYLES[entry.kind] ?? KIND_STYLES.announcement

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group relative flex gap-5"
    >
      <div className="flex flex-col items-center pt-1.5 shrink-0">
        <span className={`w-2.5 h-2.5 rounded-full shrink-0 ${style.node}`} />
        {!isLast && <span className="w-px flex-1 bg-line mt-1.5" />}
      </div>

      <div className={`flex-1 min-w-0 ${isLast ? '' : 'pb-9'}`}>
        <div className="rounded-item border border-outline/50 bg-overlay p-5 hover:border-accent-dim/70 hover:bg-raised transition-colors">
          <div className="flex items-start justify-between gap-4">
            <CardContent entry={entry} />
            <CardMeta entry={entry} />
          </div>
        </div>
      </div>
    </motion.div>
  )
}

export function UpdatesView({ connected = false }: { connected?: boolean }) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const { entries, loading, fromCache, fetchedAt, refresh } = useUpdates()
  const { markSeen } = useUpdatesBadge()

  useEffect(() => {
    if (!loading && entries.length > 0) markSeen()
  }, [loading, entries, markSeen])

  const featured = entries.filter((e) => e.featured)
  const regular = entries.filter((e) => !e.featured)

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <ViewHeader
        connected={connected}
        className="mb-4"
        title={t('updates')}
        actions={
          <ScanButton
            requiresDirs={false}
            scanDirs={[]}
            scan={refresh}
          />
        }
      >
        <p className="text-xs text-muted flex items-center gap-1.5 flex-wrap">
          <span>{tc('updates_subtitle')}</span>
          {fromCache && (
            <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-tag bg-overlay border border-outline/50 text-[10px] text-muted/70">
              {tc('updates_from_cache')}
              {fetchedAt > 0 && (
                <span className="text-muted/50">
                  {tc('updates_from_cache_ago', {
                    time: formatTimeAgo(fetchedAt),
                  })}
                </span>
              )}
            </span>
          )}
        </p>
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
      >
        <div className={`h-full ${connected ? 'pl-3' : ''} pr-5 pb-4`}>
      {loading && entries.length === 0 ? (
        <div className="flex flex-col gap-4">
          {Array.from({ length: 2 }).map((_, i) => (
            <div
              key={i}
              className="h-32 rounded-item border border-outline/50 bg-overlay animate-pulse"
            />
          ))}
        </div>
      ) : entries.length === 0 ? (
        <div className="border border-dashed border-outline/50 rounded-item py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
            <IconBell className="w-5 h-5 text-muted" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {tc('updates_no_entries')}
          </p>
        </div>
      ) : (
        <div>
          {featured.length > 0 && (
            <div className="flex flex-col gap-4 mb-8">
              {featured.map((entry) => (
                <FeaturedCard key={entry.id} entry={entry} />
              ))}
            </div>
          )}
          {regular.map((entry, i) => (
            <EntryCard
              key={entry.id}
              entry={entry}
              isLast={i === regular.length - 1}
            />
          )          )}
        </div>
      )}
      <div className="shrink-0 h-4" aria-hidden="true" />
      </div>
    </OverlayScrollArea>
    </div>
  )
}
