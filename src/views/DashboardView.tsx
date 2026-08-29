import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  motion,
  useMotionValue,
  useSpring,
  useTransform,
} from 'framer-motion'
import { useTranslation } from 'react-i18next'
import Masonry from 'react-masonry-css'
import { useProjectsContext } from '../hooks/projectsContext'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { useSettings } from '../hooks/useSettings'
import { useTauriEvent } from '../lib/useTauriEvent'
import { api } from '../lib/api'
import {
  formatDate,
  formatLastOpened,
  formatTime,
  type LastOpenedTimeFormat,
} from '../lib/lastOpened'
import { formatDuration } from '../lib/duration'
import { formatLocaleDate } from '../lib/locale'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import {
  IconArrowUpDown,
  IconCheck,
  IconChevronDown,
  IconChevronRight,
  IconChevronUp,
  IconClock,
  IconCopy,
  IconFolder,
  IconFolderPlus,
  IconGamepad,
  IconGear,
  IconGitBranch,
  IconHardDrive,
  IconImport,
  IconLayoutGrid,
  IconNode,
  IconPencil,
  IconPin,
  IconPlus,
  IconRefresh,
  IconRocket,
  IconTerminal,
  IconX,
} from '../lib/icons'
import {
  DASHBOARD_PRESETS,
  DASHBOARD_TILE_IDS,
  addTileId,
  buildDashboardSegments,
  createCustomPreset,
  deleteCustomPreset,
  enabledTileIds,
  moveTileId,
  orderedTileIds,
  presetToSettings,
  removeTileId,
  settingsMatchPreset,
  tileCanSpan,
  tileCanTall,
  toggleTileSpan,
  toggleTileTall,
  type DashboardTileId,
} from '../lib/dashboardSections'
import type { GitStatus, Project, TimeInsights } from '../types'
import { Tooltip } from '../components/reusables/Tooltip'

function dispatch(event: string, detail?: unknown) {
  window.dispatchEvent(
    detail === undefined
      ? new Event(event)
      : new CustomEvent(event, { detail }),
  )
}

function greetingKey(hour: number): 'morning' | 'afternoon' | 'evening' | 'night' {
  if (hour >= 5 && hour < 12) return 'morning'
  if (hour >= 12 && hour < 17) return 'afternoon'
  if (hour >= 17 && hour < 21) return 'evening'
  return 'night'
}

function formatBytes(bytes: number): string {
  if (bytes >= 1024 ** 3) return `${(bytes / 1024 ** 3).toFixed(1)} GB`
  if (bytes >= 1024 ** 2) return `${(bytes / 1024 ** 2).toFixed(1)} MB`
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${bytes} B`
}

function Section({
  title,
  icon,
  action,
  onTitleClick,
  titleHint,
  children,
}: {
  title: string
  icon?: React.ReactNode
  action?: React.ReactNode
  onTitleClick?: () => void
  titleHint?: string
  children: React.ReactNode
}) {
  return (
    <section className="flex flex-col gap-2.5 min-w-0">
      <header className="flex items-center gap-2">
        {icon && <span className="text-accent-bright">{icon}</span>}
        {onTitleClick ? (
          <button
            type="button"
            onClick={onTitleClick}
            aria-label={titleHint}
            className="focus-ring group/title flex items-center gap-1.5 cursor-pointer rounded-btn -mx-1 px-1 py-0.5 transition-colors hover:text-ink"
          >
            <h2 className="text-xs font-semibold uppercase tracking-wider text-muted group-hover/title:text-ink transition-colors">
              {title}
            </h2>
            <IconRefresh className="w-3 h-3 text-muted/40 group-hover/title:text-accent-bright group-hover/title:rotate-180 transition-all duration-300 shrink-0" />
          </button>
        ) : (
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted">
            {title}
          </h2>
        )}
        <div className="flex-1 h-px bg-outline/50" />
        {action}
      </header>
      {children}
    </section>
  )
}

function EmptyCard({ text }: { text: string }) {
  return (
    <p className="text-xs text-muted/70 leading-relaxed rounded-item bg-overlay border border-dashed border-outline/50 px-4 py-6 text-center">
      {text}
    </p>
  )
}

function TileEditControls({
  index,
  total,
  canSpan,
  spanning,
  onToggleSpan,
  canTall,
  tall,
  onToggleTall,
  onMove,
  onRemove,
}: {
  index: number
  total: number
  canSpan: boolean
  spanning: boolean
  onToggleSpan: () => void
  canTall: boolean
  tall: boolean
  onToggleTall: () => void
  onMove: (dir: -1 | 1) => void
  onRemove: () => void
}) {
  const { t: tc } = useTranslation('dashboard')
  const btnClass =
    'focus-ring cursor-pointer p-1 rounded-btn text-muted/50 hover:text-ink hover:bg-raised transition-colors'
  const activeBtnClass =
    'focus-ring cursor-pointer p-1 rounded-btn text-accent-bright bg-accent/10 hover:bg-accent/20 transition-colors'
  return (
    <div className="flex items-center gap-0.5 shrink-0">
      <Tooltip content={tc('dashboard_tile_move_up')} side="top">
          <button
            type="button"
            onClick={() => onMove(-1)}
            disabled={index === 0}
            aria-label={tc('dashboard_tile_move_up')}
            className={`${btnClass} disabled:opacity-30 disabled:cursor-not-allowed`}
          >
            <IconChevronUp className="w-3 h-3" />
          </button>
        </Tooltip>
      <Tooltip content={tc('dashboard_tile_move_down')} side="top">
          <button
            type="button"
            onClick={() => onMove(1)}
            disabled={index === total - 1}
            aria-label={tc('dashboard_tile_move_down')}
            className={`${btnClass} disabled:opacity-30 disabled:cursor-not-allowed`}
          >
            <IconChevronDown className="w-3 h-3" />
          </button>
        </Tooltip>
      {canSpan && (
        <Tooltip content={tc(spanning ? 'dashboard_tile_span_off' : 'dashboard_tile_span')} side="top">
          <button
              type="button"
              onClick={onToggleSpan}
              aria-label={tc(spanning ? 'dashboard_tile_span_off' : 'dashboard_tile_span')}
              aria-pressed={spanning}
              className={spanning ? activeBtnClass : btnClass}
            >
              <IconLayoutGrid className="w-3 h-3" />
            </button>
        </Tooltip>
      )}
      {canTall && (
        <Tooltip content={tc(tall ? 'dashboard_tile_tall_off' : 'dashboard_tile_tall')} side="top">
          <button
              type="button"
              onClick={onToggleTall}
              aria-label={tc(tall ? 'dashboard_tile_tall_off' : 'dashboard_tile_tall')}
              aria-pressed={tall}
              className={tall ? activeBtnClass : btnClass}
            >
              <IconArrowUpDown className="w-3 h-3" />
            </button>
        </Tooltip>
      )}
      <Tooltip content={tc('dashboard_tile_remove')} side="top">
          <button
            type="button"
            onClick={onRemove}
            aria-label={tc('dashboard_tile_remove')}
            className="focus-ring cursor-pointer p-1 rounded-btn text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors"
          >
            <IconX className="w-3 h-3" />
          </button>
        </Tooltip>
    </div>
  )
}

function ProjectRow({ project }: { project: Project }) {
  const { t: tc } = useTranslation('dashboard')
  const openedAt = formatLastOpened(project.last_opened)

  return (
    <motion.button
      type="button"
      onClick={() => dispatch('app:open-project', project.id)}
      className="group focus-ring cursor-pointer w-full flex items-center gap-3 p-3 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 transition-colors text-left"
    >
      <span className="w-9 h-9 shrink-0 rounded-btn bg-surface border border-outline/60 flex items-center justify-center overflow-hidden">
        <IconNode className="w-4 h-4 text-muted/60" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-medium text-ink truncate">
          {project.name}
        </span>
        <span className="block text-[11px] text-muted/70 truncate font-mono">
          {project.path}
        </span>
      </span>
      {openedAt && (
        <span className="shrink-0 text-[10px] text-muted/60 tabular-nums">
          {tc('dashboard_opened_at', { time: openedAt })}
        </span>
      )}
    </motion.button>
  )
}

function QuickActions() {
  const { t: tc } = useTranslation('dashboard')
  const actions = [
    {
      key: 'new',
      label: tc('dashboard_new_project'),
      icon: IconFolderPlus,
      onClick: () => dispatch('app:new-project-request'),
      primary: true,
    },
    {
      key: 'import',
      label: tc('dashboard_import_project'),
      icon: IconImport,
      onClick: () => dispatch('app:import-project-request'),
    },
    {
      key: 'scan',
      label: tc('dashboard_scan_projects'),
      icon: IconRefresh,
      onClick: () => dispatch('app:scan-projects'),
    },
  ]
  return (
    <div className="flex items-center gap-2.5 flex-wrap">
      {actions.map((a) => (
        <motion.button
          key={a.key}
          type="button"
          whileHover={{ y: -1 }}
          whileTap={{ scale: 0.97 }}
          onClick={a.onClick}
          className={`focus-ring cursor-pointer inline-flex items-center gap-2 h-11 px-5 rounded-item font-semibold text-sm shadow-md shadow-black/10 border transition-colors ${
            a.primary
              ? 'bg-accent text-ink hover:bg-accent-bright border-outline/50'
              : 'bg-overlay text-ink hover:bg-raised hover:border-accent-dim/60 border-outline/50'
          }`}
        >
          <a.icon
            className={`w-4 h-4 ${a.primary ? 'text-ink' : 'text-accent-bright'}`}
          />
          {a.label}
        </motion.button>
      ))}
    </div>
  )
}

function StatsRow({
  projects,
  templates,
  engines,
  totalMs,
}: {
  projects: number
  templates: number
  engines: number
  totalMs: number
}) {
  const { t: tc } = useTranslation('dashboard')
  const stats: Array<{
    key: string
    label: string
    value: number
    display?: string
    tab: 'projects' | 'templates' | 'versions' | null
    hint?: string
    Icon: React.ComponentType<{ className?: string }>
    grad: string
    sticker: string
    hoverBorder: string
  }> = [
    {
      key: 'projects',
      label: tc('dashboard_stat_projects'),
      value: projects,
      tab: 'projects',
      Icon: IconFolder,
      grad: 'from-[#7aa0ff] to-[#4f7cff]',
      sticker: 'text-accent-bright bg-accent/10 border-accent-dim/40',
      hoverBorder: 'group-hover:border-accent/60',
    },
    {
      key: 'templates',
      label: tc('dashboard_stat_templates'),
      value: templates,
      tab: 'templates',
      Icon: IconCopy,
      grad: 'from-[#4ade80] to-[#2fbf71]',
      sticker: 'text-mint bg-mint/10 border-mint/40',
      hoverBorder: 'group-hover:border-mint/60',
    },
    {
      key: 'engines',
      label: tc('dashboard_stat_engines'),
      value: engines,
      tab: 'versions',
      Icon: IconRocket,
      grad: 'from-[#fbbf24] to-[#f0b132]',
      sticker: 'text-amber bg-amber/10 border-amber/40',
      hoverBorder: 'group-hover:border-amber/60',
    },
    {
      key: 'time',
      label: tc('dashboard_stat_total_time'),
      value: totalMs,
      display: formatDuration(totalMs),
      tab: null,
      hint: tc('dashboard_stat_total_time_hint'),
      Icon: IconClock,
      grad: 'from-[#a78bfa] to-[#8b5cf6]',
      sticker: 'text-violet-400 bg-violet-400/10 border-violet-400/40',
      hoverBorder: 'group-hover:border-violet-400/60',
    },
  ]
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
      {stats.map(({ key, ...s }, i) => (
        <StatCard key={key} index={i} {...s} />
      ))}
    </div>
  )
}

function StatCard({
  index,
  label,
  value,
  display,
  tab,
  hint,
  Icon,
  grad,
  sticker,
  hoverBorder,
}: {
  index: number
  label: string
  value: number
  display?: string
  tab: 'projects' | 'templates' | 'versions' | null
  hint?: string
  Icon: React.ComponentType<{ className?: string }>
  grad: string
  sticker: string
  hoverBorder: string
}) {
  const mx = useMotionValue(0)
  const my = useMotionValue(0)
  const tiltSpring = { stiffness: 220, damping: 18 }
  const rotateX = useSpring(useTransform(my, [-0.5, 0.5], [9, -9]), tiltSpring)
  const rotateY = useSpring(useTransform(mx, [-0.5, 0.5], [-9, 9]), tiltSpring)

  const handleMove = (e: React.MouseEvent<HTMLButtonElement>) => {
    const r = e.currentTarget.getBoundingClientRect()
    mx.set((e.clientX - r.left) / r.width - 0.5)
    my.set((e.clientY - r.top) / r.height - 0.5)
  }
  const handleLeave = () => {
    mx.set(0)
    my.set(0)
  }

  return (
    <motion.button
      type="button"
      initial={{ y: 26, opacity: 0, scale: 0.9, rotate: -1.5 }}
      animate={{ y: 0, opacity: 1, scale: 1, rotate: 0 }}
      transition={{
        type: 'spring',
        stiffness: 240,
        damping: 20,
        delay: 0.08 * index,
      }}
      whileHover={{ y: -4 }}
      whileTap={{ scale: 0.96 }}
      onClick={tab ? () => dispatch('app:set-tab', tab) : undefined}
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
      style={{ rotateX, rotateY, transformPerspective: 700 }}
      className={`group relative overflow-hidden text-left cursor-pointer focus-ring rounded-card bg-overlay border border-outline/50 px-5 py-4 flex flex-col transition-colors duration-200 hover:border-outline ${hoverBorder}`}
    >
      <Icon
        aria-hidden="true"
        className="pointer-events-none absolute -bottom-8 -right-8 w-32 h-32 rotate-12 text-ink/5 transition-transform duration-500 group-hover:rotate-6 group-hover:scale-110"
      />

      <div className="relative z-10 flex items-start justify-between gap-2">
        <span className="pt-1 truncate text-[10px] font-semibold uppercase tracking-wider text-muted/70">
          {label}
        </span>
        <span
          className={`w-9 h-9 shrink-0 -rotate-6 rounded-tile border flex items-center justify-center transition-transform duration-300 group-hover:rotate-0 group-hover:scale-110 ${sticker}`}
        >
          <Icon className="w-4 h-4" />
        </span>
      </div>

      <span className="relative z-10 mt-3 block text-[26px] leading-none font-bold tabular-nums text-ink">
        {display ?? <AnimatedNumber value={value} />}
      </span>
      <span
        aria-hidden="true"
        className={`relative z-10 mt-2.5 block h-1 w-8 rounded-full bg-linear-to-r ${grad} transition-all duration-300 group-hover:w-12`}
      />

      <span className="relative z-10 mt-auto pt-3 inline-flex items-center gap-1 text-[10px] font-medium text-muted/40 transition-colors duration-200 group-hover:text-muted">
        {hint ?? label}
        {tab && (
          <IconChevronRight className="w-3 h-3 transition-transform duration-300 group-hover:translate-x-0.5" />
        )}
      </span>
    </motion.button>
  )
}

type ActivityRange = 'weekly' | 'monthly' | 'yearly' | 'daily'

const ACTIVITY_RANGE_CYCLE: ActivityRange[] = [
  'weekly',
  'monthly',
  'yearly',
  'daily',
]

function activityLabel(
  range: ActivityRange,
  key: string,
  timeFormat: LastOpenedTimeFormat,
): string {
  if (range === 'daily') {
    const hour = Number(key.slice(11, 13))
    if (timeFormat === '24h') {
      return `${String(hour).padStart(2, '0')}h`
    }
    const suffix = hour >= 12 ? 'PM' : 'AM'
    const h12 = hour % 12 === 0 ? 12 : hour % 12
    return `${h12} ${suffix}`
  }
  if (range === 'yearly') {
    return formatLocaleDate(new Date(`${key}-01T00:00:00`), {
      month: 'short',
    })
  }
  const d = new Date(`${key}T00:00:00`)
  return range === 'weekly'
    ? formatLocaleDate(d, { weekday: 'short' })
    : String(d.getDate())
}

function ActivityChart({
  range,
  tall = false,
  active = true,
}: {
  range: ActivityRange
  tall?: boolean
  active?: boolean
}) {
  const { t: tc } = useTranslation('dashboard')
  const { settings } = useSettings()
  const [data, setData] = useState<[string, number][]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!active) return
    let cancelled = false
    setLoading(true)
    api
      .getActivity(range)
      .then((d) => {
        if (cancelled) return
        setData(d)
        setLoading(false)
      })
      .catch(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [active, range])

  const total = data.reduce((acc, [, s]) => acc + s, 0)
  const max = Math.max(...data.map(([, s]) => s), 1)

  if (loading) {
    const bars = range === 'monthly' ? 30 : range === 'yearly' ? 12 : range === 'daily' ? 24 : 7
    return (
      <div className={`flex items-end gap-1.5 animate-pulse ${tall ? 'h-48' : 'h-32'}`}>
        {Array.from({ length: bars }).map((_, i) => (
          <div key={i} className="flex-1 flex flex-col items-center gap-1 h-full">
            <div className="flex-1 w-full rounded bg-raised" />
          </div>
        ))}
      </div>
    )
  }

  if (total === 0) {
    return <EmptyCard text={tc(`dashboard_${range}_empty`)} />
  }

  return (
    <div className={`flex items-end gap-1.5 ${tall ? 'h-68' : 'h-45'}`}>
      {data.map(([key, seconds]) => {
        const label = activityLabel(range, key, settings.last_opened_time_format)
        const pct = seconds > 0 ? Math.max((seconds / max) * 100, 6) : 0
        return (
          <div key={key} className="flex-1 flex flex-col items-center gap-1 h-full min-w-0">
            <div className="flex-1 w-full flex items-end rounded-md overflow-hidden bg-raised">
              <div
                  className="w-full rounded-t bg-accent/50 hover:bg-accent-bright transition-colors"
                  style={{ height: `${pct}%` }}
                  title={formatDuration(seconds * 1000)}
                  aria-label={tc('dashboard_weekly_aria', {
                    label: formatDuration(seconds * 1000),
                  })}
                />
            </div>
            <span className="text-[9px] text-muted/60 shrink-0">{label}</span>
          </div>
        )
      })}
    </div>
  )
}

function weekdayName(weekday: number): string {
  return formatLocaleDate(new Date(2026, 0, 5 + weekday), {
    weekday: 'long',
  })
}

function InsightsTile({ active = true }: { active?: boolean }) {
  const { t: tc } = useTranslation('dashboard')
  const [insights, setInsights] = useState<TimeInsights | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!active) return
    let cancelled = false
    api
      .getTimeInsights()
      .then((d) => {
        if (cancelled) return
        setInsights(d)
        setLoading(false)
      })
      .catch(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [active])

  if (loading) {
    return (
      <div className="grid grid-cols-2 gap-2 animate-pulse">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-20 rounded-item bg-raised" />
        ))}
      </div>
    )
  }

  if (!insights || insights.total_seconds === 0) {
    return <EmptyCard text={tc('dashboard_insights_empty')} />
  }

  const delta =
    insights.last_month_seconds > 0
      ? Math.round(
          ((insights.this_month_seconds - insights.last_month_seconds) /
            insights.last_month_seconds) *
            100,
        )
      : null

  const stats: Array<{
    label: string
    value: string
    sub?: string
    Icon: React.ComponentType<{ className?: string }>
    accent: string
  }> = [
    {
      label: tc('dashboard_insights_longest_streak'),
      value: tc('dashboard_insights_days', {
        count: insights.longest_streak_days,
      }),
      Icon: IconRocket,
      accent: 'text-amber',
    },
    {
      label: tc('dashboard_insights_current_streak'),
      value: tc('dashboard_insights_days', {
        count: insights.current_streak_days,
      }),
      Icon: IconClock,
      accent: 'text-mint',
    },
    {
      label: tc('dashboard_insights_productive_day'),
      value:
        insights.most_productive_weekday === null
          ? '—'
          : weekdayName(insights.most_productive_weekday),
      Icon: IconGamepad,
      accent: 'text-accent-bright',
    },
    {
      label: tc('dashboard_insights_this_month'),
      value: formatDuration(insights.this_month_seconds * 1000),
      sub:
        delta === null
          ? undefined
          : delta >= 0
            ? tc('dashboard_insights_delta_up', { pct: delta })
            : tc('dashboard_insights_delta_down', { pct: Math.abs(delta) }),
      Icon: IconArrowUpDown,
      accent: delta !== null && delta < 0 ? 'text-danger' : 'text-violet-400',
    },
  ]

  return (
    <div className="grid grid-cols-2 gap-2">
      {stats.map((s) => (
        <div
          key={s.label}
          className="flex items-start gap-2.5 p-3 rounded-item bg-overlay border border-outline/50"
        >
          <span className="w-7 h-7 shrink-0 rounded-btn bg-raised border border-outline/50 flex items-center justify-center">
            <s.Icon className={`w-3.5 h-3.5 ${s.accent}`} />
          </span>
          <span className="min-w-0">
            <span className="block text-[10px] font-semibold uppercase tracking-wider text-muted/60 truncate">
              {s.label}
            </span>
            <span className="block text-sm font-semibold text-ink truncate mt-0.5">
              {s.value}
            </span>
            {s.sub && (
              <span className="block text-[10px] text-muted/60 truncate mt-0.5">
                {s.sub}
              </span>
            )}
          </span>
        </div>
      ))}
    </div>
  )
}

function TopProjectsByTime({
  projects,
  tall = false,
  spanning = false,
}: {
  projects: Project[]
  tall?: boolean
  spanning?: boolean
}) {
  const { t: tc } = useTranslation('dashboard')
  const top = useMemo(
    () =>
      [...projects]
        .filter((p) => (p.total_time_seconds ?? 0) > 0)
        .sort((a, b) => (b.total_time_seconds ?? 0) - (a.total_time_seconds ?? 0))
        .slice(0, tall ? 8 : 5),
    [projects, tall],
  )
  const max = Math.max(...top.map((p) => p.total_time_seconds ?? 0), 1)

  if (top.length === 0) {
    return <EmptyCard text={tc('dashboard_top_time_empty')} />
  }

  return (
    <div
      className={`gap-2 ${
        spanning ? 'grid grid-cols-1 md:grid-cols-2' : 'flex flex-col'
      }`}
    >
      {top.map((p) => (
        <motion.button
          key={p.id}
          type="button"
          onClick={() => dispatch('app:open-project', p.id)}
          className="group focus-ring cursor-pointer w-full flex items-center gap-3 p-3 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 transition-colors text-left"
        >
          <span className="min-w-0 flex-1">
            <span className="flex items-center justify-between gap-2">
              <span className="block text-sm font-medium text-ink truncate">
                {p.name}
              </span>
              <span className="shrink-0 text-[11px] text-muted/70 tabular-nums">
                {formatDuration((p.total_time_seconds ?? 0) * 1000)}
              </span>
            </span>
            <span className="block h-1.5 rounded-full bg-raised mt-1.5 overflow-hidden">
              <span
                className="block h-full rounded-full bg-accent/50"
                style={{
                  width: `${Math.max(((p.total_time_seconds ?? 0) / max) * 100, 2)}%`,
                }}
              />
            </span>
          </span>
        </motion.button>
      ))}
    </div>
  )
}

function GitOverview({ tall = false, active = true }: { tall?: boolean; active?: boolean }) {
  const { t: tc } = useTranslation('dashboard')
  const { projects } = useProjectsContext()
  const [statusMap, setStatusMap] = useState<Record<string, GitStatus>>({})
  const [loading, setLoading] = useState(true)
  const fetchingRef = useRef(false)

  const fetchStatuses = useCallback(async () => {
    if (fetchingRef.current) return
    if (projects.length === 0) {
      setLoading(false)
      return
    }
    fetchingRef.current = true
    try {
      const statuses = await api.batchGitStatus(projects.map((p) => p.path))
      setStatusMap(statuses)
    } catch {
    } finally {
      fetchingRef.current = false
      setLoading(false)
    }
  }, [projects])

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  useEffect(() => {
    if (!active) return
    fetchStatuses()
    const interval = setInterval(fetchStatuses, 30000)
    const handleRefresh = () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
      debounceRef.current = setTimeout(fetchStatuses, 300)
    }
    window.addEventListener('app:refresh-git-status', handleRefresh)
    return () => {
      clearInterval(interval)
      if (debounceRef.current) clearTimeout(debounceRef.current)
      window.removeEventListener('app:refresh-git-status', handleRefresh)
    }
  }, [active, fetchStatuses])

  const dirty = useMemo(
    () =>
      projects.filter((p) => {
        const s = statusMap[p.path]
        return s && s.is_repo && s.has_uncommitted
      }),
    [projects, statusMap],
  )
  const repoCount = useMemo(
    () => projects.filter((p) => statusMap[p.path]?.is_repo).length,
    [projects, statusMap],
  )

  if (loading) {
    return (
      <div className="flex flex-col gap-2 animate-pulse">
        <div className="h-10 rounded-item bg-raised" />
        <div className="h-10 rounded-item bg-raised" />
      </div>
    )
  }

  if (repoCount === 0) {
    return <EmptyCard text={tc('dashboard_git_empty')} />
  }

  return (
    <div className="flex flex-col gap-2">
      <p className="text-[11px] text-muted/70">
        {dirty.length === 0
          ? tc('dashboard_git_clean')
          : dirty.length === 1
            ? tc('dashboard_git_dirty_one')
            : tc('dashboard_git_dirty', { count: dirty.length })}
      </p>
      {dirty.length > 0 && (
        <div className="flex flex-col gap-2">
          {dirty.slice(0, tall ? 8 : 5).map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() =>
                window.dispatchEvent(
                  new CustomEvent('app:show-git-sidebar', {
                    detail: { project: p, gitStatus: statusMap[p.path] ?? null },
                  }),
                )
              }
              className="focus-ring cursor-pointer w-full flex items-center gap-3 p-3 rounded-item bg-overlay border border-amber/25 hover:bg-raised hover:border-amber/40 transition-colors text-left"
            >
              <IconGitBranch className="w-3.5 h-3.5 text-amber shrink-0" />
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-medium text-ink truncate">
                  {p.name}
                </span>
                {statusMap[p.path]?.branch && (
                  <span className="block text-[11px] text-muted/70 truncate font-mono">
                    {tc('dashboard_git_branch', {
                      branch: statusMap[p.path]!.branch!,
                    })}
                  </span>
                )}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function StorageUsage({ tall = false, active = true }: { tall?: boolean; active?: boolean }) {
  const { t: tc } = useTranslation('dashboard')
  const { projects } = useProjectsContext()
  const [sizes, setSizes] = useState<Record<string, number>>({})
  const [measuring, setMeasuring] = useState(true)
  const measuredRef = useRef(false)

  const targets = useMemo(() => projects.slice(0, 8), [projects])

  useEffect(() => {
    if (!active) return
    let cancelled = false
    if (!measuredRef.current) setMeasuring(true)
    Promise.all(
      targets.map(async (p) => {
        try {
          const info = await api.getProjectSize(p.path)
          return [p.id, info.total_size] as const
        } catch {
          return [p.id, 0] as const
        }
      }),
    ).then((entries) => {
      if (cancelled) return
      measuredRef.current = true
      setSizes(Object.fromEntries(entries))
      setMeasuring(false)
    })
    return () => {
      cancelled = true
    }
  }, [active, targets])

  const rows = useMemo(
    () =>
      targets
        .map((p) => ({ project: p, size: sizes[p.id] ?? 0 }))
        .filter((r) => r.size > 0)
        .sort((a, b) => b.size - a.size)
        .slice(0, tall ? 8 : 5),
    [targets, sizes, tall],
  )
  const max = Math.max(...rows.map((r) => r.size), 1)
  const total = rows.reduce((acc, r) => acc + r.size, 0)

  if (measuring) {
    return <EmptyCard text={tc('dashboard_storage_loading')} />
  }

  if (rows.length === 0) {
    return <EmptyCard text={tc('dashboard_storage_empty')} />
  }

  return (
    <div className="flex flex-col gap-2">
      <p className="text-[11px] text-muted/70">
        {tc('dashboard_storage_total', { size: formatBytes(total) })}
      </p>
      <div className="flex flex-col gap-2">
        {rows.map(({ project, size }) => (
          <div
            key={project.id}
            className="w-full flex items-center gap-3 p-3 rounded-item bg-overlay border border-outline/50 hover:bg-raised transition-colors"
          >
            <IconHardDrive className="w-3.5 h-3.5 text-muted/50 shrink-0" />
            <span className="min-w-0 flex-1">
              <span className="flex items-center justify-between gap-2">
                <span className="block text-sm font-medium text-ink truncate">
                  {project.name}
                </span>
                <span className="shrink-0 text-[11px] text-muted/70 tabular-nums">
                  {formatBytes(size)}
                </span>
              </span>
              <span className="block h-1.5 rounded-full bg-raised mt-1.5 overflow-hidden">
                <span
                  className="block h-full rounded-full bg-accent/50"
                  style={{ width: `${Math.max((size / max) * 100, 2)}%` }}
                />
              </span>
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}


interface RunningProject {
  id: string
  name: string
  version: string
  startedAt: number
}

function Clock({ active = true }: { active?: boolean }) {
  const { t: tc } = useTranslation('dashboard')
  const { settings } = useSettings()
  const [now, setNow] = useState(() => new Date())

  useEffect(() => {
    if (!active) return
    const id = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(id)
  }, [active])

  const timeString = formatTime(now, settings.last_opened_time_format)
  const dateString = formatDate(now, settings.last_opened_date_format)

  return (
    <div className="ml-auto shrink-0 flex flex-col items-end gap-1">
      <span
        className="font-display text-3xl font-semibold text-ink leading-none"
        aria-label={tc('dashboard_clock_aria')}
      >
        {timeString}
      </span>
      <span className="text-sm text-muted/70 leading-none">
        {dateString}
      </span>
    </div>
  )
}

function RunningNow({
  running,
  onStop,
  editControls,
  active = true,
}: {
  running: RunningProject[]
  onStop: (id: string) => void
  editControls?: React.ReactNode
  active?: boolean
}) {
  const { t: tc } = useTranslation(['dashboard'])
  const [now, setNow] = useState(() => Date.now())

  useEffect(() => {
    if (!active || running.length === 0) return
    const id = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [active, running.length])

  return (
    <Section
      title={tc('dashboard_running')}
      icon={<IconFolder className="w-3.5 h-3.5" />}
      action={editControls}
    >
      {running.length > 0 ? (
        <div className="flex flex-col gap-2">
          {running.map((p) => (
            <div
              key={p.id}
              className="flex items-center gap-3 p-3 rounded-item bg-overlay border border-outline/50 hover:bg-raised transition-colors"
            >
              <span className="relative flex w-2 h-2 shrink-0">
                <span className="absolute inline-flex h-full w-full rounded-full bg-mint opacity-60 animate-ping" />
                <span className="relative inline-flex rounded-full w-2 h-2 bg-mint" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-medium text-ink truncate">
                  {p.name}
                </span>
                <span className="block text-[11px] text-muted/70 tabular-nums">
                  {p.version ? `Godot ${p.version} · ` : ''}
                  {formatDuration(now - p.startedAt)}
                </span>
              </span>
                <button
                  type="button"
                  onClick={() => onStop(p.id)}
                  aria-label={`${tc('stop')} ${p.name}`}
                  className="focus-ring cursor-pointer w-6 h-6 rounded-btn inline-flex items-center justify-center text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
                >
                  <IconX className="w-3.5 h-3.5" />
                </button>
            </div>
          ))}
        </div>
      ) : (
        <EmptyCard text={tc('dashboard_running_empty')} />
      )}
    </Section>
  )
}

export function DashboardView({
  connected = false,
  active = true,
}: {
  connected?: boolean
  active?: boolean
}) {
  const { t: tc } = useTranslation(['dashboard'])
  const { settings, update } = useSettings()
  const { projects } = useProjectsContext()
  const { installed } = useGodotVersionsContext()

  const [osName, setOsName] = useState<string | null>(null)
  const [templates, setTemplates] = useState(0)
  const [greetingHour, setGreetingHour] = useState(() => new Date().getHours())
  const [editingName, setEditingName] = useState(false)
  const [nameDraft, setNameDraft] = useState('')
  const nameInputRef = useRef<HTMLInputElement>(null)
  const nameCancelRef = useRef(false)
  const [editingTiles, setEditingTiles] = useState(false)
  const [presetDraft, setPresetDraft] = useState('')
  const [running, setRunning] = useState<RunningProject[]>([])
  const [activityRange, setActivityRange] = useState<ActivityRange>('weekly')

  const cycleActivityRange = useCallback(() => {
    setActivityRange((prev) => {
      const i = ACTIVITY_RANGE_CYCLE.indexOf(prev)
      return ACTIVITY_RANGE_CYCLE[(i + 1) % ACTIVITY_RANGE_CYCLE.length]
    })
  }, [])

  useEffect(() => {
    api.getOsUsername().then(setOsName).catch(() => setOsName(null))
  }, [])

  useEffect(() => {
    api
      .listTemplates()
      .then((list) => setTemplates(Array.isArray(list) ? list.length : 0))
      .catch(() => setTemplates(0))
  }, [])

  useEffect(() => {
    if (!active) return
    const id = setInterval(() => {
      const h = new Date().getHours()
      setGreetingHour((prev) => (prev === h ? prev : h))
    }, 30000)
    return () => clearInterval(id)
  }, [active])

  useEffect(() => {
    const handleRefreshTemplates = () => {
      api
        .listTemplates()
        .then((list) => setTemplates(Array.isArray(list) ? list.length : 0))
        .catch(() => {})
    }
    window.addEventListener('app:refresh-templates', handleRefreshTemplates)
    return () =>
      window.removeEventListener('app:refresh-templates', handleRefreshTemplates)
  }, [])

  useEffect(() => {
    if (!active) return
    let cancelled = false
    api
      .listRunningProjects()
      .then((list) => {
        if (cancelled) return
        setRunning(
          list.map((p) => ({
            id: p.id,
            name: p.name,
            version: p.version,
            startedAt: (p.launched_at_ms || Date.now()) + 3000,
          })),
        )
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [active])

  useTauriEvent<RunningProject>('project:launched', (p) => {
    if (!active) return
    setRunning((prev) =>
      prev.some((x) => x.id === p.id)
        ? prev
        : [...prev, { ...p, startedAt: Date.now() + 3000 }],
    )
  })

  useTauriEvent<{ id: string }>('project:exited', ({ id }) => {
    if (!active) return
    setRunning((prev) => prev.filter((x) => x.id !== id))
  })

  const stopProject = useCallback((id: string) => {
    api.stopProject(id).catch((e) => alert(String(e)))
  }, [])

  const displayName = (settings.dashboard_custom_name || osName || '').slice(0, 40)
  const greeting = tc(`greeting_${greetingKey(greetingHour)}`)

  const isEnabled = (id: string) =>
    settings.dashboard_sections.length === 0 ||
    settings.dashboard_sections.includes(id)

  const enabledTiles = useMemo(
    () => enabledTileIds(settings.dashboard_sections),
    [settings.dashboard_sections],
  )
  const orderedTiles = useMemo(() => {
    const all = orderedTileIds(settings.dashboard_section_order)
    return all.filter((id) => enabledTiles.includes(id))
  }, [settings.dashboard_section_order, enabledTiles])
  const hiddenTiles = useMemo(
    () => DASHBOARD_TILE_IDS.filter((id) => !enabledTiles.includes(id)),
    [enabledTiles],
  )

  const activityTitle: Record<ActivityRange, string> = {
    weekly: tc('dashboard_weekly'),
    monthly: tc('dashboard_monthly'),
    yearly: tc('dashboard_yearly'),
    daily: tc('dashboard_daily'),
  }
  const nextActivityRange =
    ACTIVITY_RANGE_CYCLE[
      (ACTIVITY_RANGE_CYCLE.indexOf(activityRange) + 1) %
        ACTIVITY_RANGE_CYCLE.length
    ]

  const tileTitle: Record<DashboardTileId, string> = {
    weekly: activityTitle[activityRange],
    top_time: tc('dashboard_top_time'),
    insights: tc('dashboard_insights'),
    git: tc('dashboard_git'),
    storage: tc('dashboard_storage'),
    recent: tc('dashboard_recent'),
    pinned: tc('dashboard_pinned'),
    engines: tc('dashboard_engines'),
    running: tc('dashboard_running'),
  }

  const spanSet = useMemo(
    () => new Set(settings.dashboard_section_spans),
    [settings.dashboard_section_spans],
  )
  const tallSet = useMemo(
    () => new Set(settings.dashboard_tall_sections),
    [settings.dashboard_tall_sections],
  )

  const moveTile = (id: DashboardTileId, dir: -1 | 1) => {
    update({
      ...settings,
      dashboard_section_order: moveTileId(
        settings.dashboard_section_order,
        id,
        dir,
      ),
    })
  }
  const removeTile = (id: DashboardTileId) => {
    update({
      ...settings,
      dashboard_sections: removeTileId(settings.dashboard_sections, id),
    })
  }
  const addTile = (id: DashboardTileId) => {
    update({
      ...settings,
      dashboard_sections: addTileId(settings.dashboard_sections, id),
    })
  }
  const toggleSpan = (id: DashboardTileId) => {
    update({
      ...settings,
      dashboard_section_spans: toggleTileSpan(
        settings.dashboard_section_spans,
        id,
      ),
    })
  }
  const toggleTall = (id: DashboardTileId) => {
    update({
      ...settings,
      dashboard_tall_sections: toggleTileTall(
        settings.dashboard_tall_sections,
        id,
      ),
    })
  }
  const savePreset = () => {
    const next = createCustomPreset(
      settings.dashboard_custom_presets,
      presetDraft,
      settings.dashboard_sections,
      settings.dashboard_section_order,
      settings.dashboard_section_spans,
      settings.dashboard_tall_sections,
    )
    if (next.length === settings.dashboard_custom_presets.length) return
    update({ ...settings, dashboard_custom_presets: next })
    setPresetDraft('')
  }
  const removePreset = (id: string) => {
    update({
      ...settings,
      dashboard_custom_presets: deleteCustomPreset(
        settings.dashboard_custom_presets,
        id,
      ),
    })
  }

  const recent = useMemo(
    () =>
      [...projects]
        .filter((p) => p.last_opened)
        .sort(
          (a, b) =>
            new Date(b.last_opened!).getTime() -
            new Date(a.last_opened!).getTime(),
        )
        .slice(0, 3),
    [projects],
  )
  const pinned = useMemo(
    () => projects.filter((p) => p.pinned).slice(0, 3),
    [projects],
  )
  const totalMs = useMemo(
    () =>
      projects.reduce(
        (acc, p) => acc + (p.total_time_seconds ?? 0) * 1000,
        0,
      ),
    [projects],
  )

  const commitName = () => {
    setEditingName(false)
    if (nameCancelRef.current) {
      nameCancelRef.current = false
      return
    }
    const trimmed = nameDraft.trim()
    update({ ...settings, dashboard_custom_name: trimmed || null })
  }

  const cancelNameEdit = () => {
    nameCancelRef.current = true
    setEditingName(false)
  }

  const startEditingName = () => {
    setNameDraft(settings.dashboard_custom_name || osName || '')
    setEditingName(true)
    requestAnimationFrame(() => {
      nameInputRef.current?.focus()
      nameInputRef.current?.select()
    })
  }

  const openEngine = (tag: string, console?: boolean) => {
    api.openGodotVersion(tag, console).catch((err) => alert(String(err)))
  }

  const editControls = (id: DashboardTileId, index: number) =>
    editingTiles ? (
      <TileEditControls
        index={index}
        total={orderedTiles.length}
        canSpan={tileCanSpan(id)}
        spanning={spanSet.has(id)}
        onToggleSpan={() => toggleSpan(id)}
        canTall={tileCanTall(id)}
        tall={tallSet.has(id)}
        onToggleTall={() => toggleTall(id)}
        onMove={(dir) => moveTile(id, dir)}
        onRemove={() => removeTile(id)}
      />
    ) : undefined

  const renderTile = (id: DashboardTileId, index: number): React.ReactNode => {
    const controls = editControls(id, index)
    const spanning = spanSet.has(id)
    const tall = tallSet.has(id)
    switch (id) {
      case 'weekly':
        return (
          <Section
            title={activityTitle[activityRange]}
            icon={<IconClock className="w-3.5 h-3.5" />}
            onTitleClick={cycleActivityRange}
            titleHint={tc('dashboard_activity_cycle', {
              next: activityTitle[nextActivityRange],
            })}
            action={controls}
          >
            <ActivityChart range={activityRange} tall={tall} active={active} />
          </Section>
        )
      case 'top_time':
        return (
          <Section
            title={tc('dashboard_top_time')}
            icon={<IconNode className="w-3.5 h-3.5" />}
            action={controls}
          >
            <TopProjectsByTime projects={projects} tall={tall} spanning={spanning} />
          </Section>
        )
      case 'insights':
        return (
          <Section
            title={tc('dashboard_insights')}
            icon={<IconRocket className="w-3.5 h-3.5" />}
            action={controls}
          >
            <InsightsTile active={active} />
          </Section>
        )
      case 'git':
        return (
          <Section
            title={tc('dashboard_git')}
            icon={<IconGitBranch className="w-3.5 h-3.5" />}
            action={controls}
          >
            <GitOverview tall={tall} active={active} />
          </Section>
        )
      case 'storage':
        return (
          <Section
            title={tc('dashboard_storage')}
            icon={<IconHardDrive className="w-3.5 h-3.5" />}
            action={controls}
          >
            <StorageUsage tall={tall} active={active} />
          </Section>
        )
      case 'recent':
        return (
          <Section
            title={tc('dashboard_recent')}
            icon={<IconClock className="w-3.5 h-3.5" />}
            action={controls}
          >
            {recent.length > 0 ? (
              <div className="flex flex-col gap-2">
                {recent.map((p) => (
                  <ProjectRow key={p.id} project={p} />
                ))}
              </div>
            ) : (
              <EmptyCard text={tc('dashboard_recent_empty')} />
            )}
          </Section>
        )
      case 'pinned':
        return (
          <Section
            title={tc('dashboard_pinned')}
            icon={<IconPin className="w-3.5 h-3.5" />}
            action={controls}
          >
            {pinned.length > 0 ? (
              <div className="flex flex-col gap-2">
                {pinned.map((p) => (
                  <ProjectRow key={p.id} project={p} />
                ))}
              </div>
            ) : (
              <EmptyCard text={tc('dashboard_pinned_empty')} />
            )}
          </Section>
        )
      case 'engines':
        return (
          <Section
            title={tc('dashboard_engines')}
            icon={<IconRocket className="w-3.5 h-3.5" />}
            action={controls}
          >
            {installed.length > 0 ? (
              <div className="flex flex-col gap-2">
                {installed.slice(0, 3).map((v) => (
                  <div
                    key={v.tag}
                    className="flex items-center gap-3 p-3 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 transition-colors"
                  >
                    <span className="min-w-0 flex-1">
                      <span className="block text-sm font-medium text-ink truncate font-mono">
                        {v.custom_name || v.tag}
                      </span>
                      <span className="block text-[11px] text-muted/70 truncate font-mono">
                        {v.executable_path}
                      </span>
                    </span>
                      <motion.button
                        type="button"
                        whileTap={{ scale: 0.92 }}
                        onClick={() => openEngine(v.tag)}
                        className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/60 hover:text-ink hover:bg-raised transition-colors"
                      >
                        <IconTerminal className="w-3.5 h-3.5" />
                      </motion.button>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyCard text={tc('dashboard_engines_empty')} />
            )}
          </Section>
        )
      case 'running':
        return (
          <RunningNow running={running} onStop={stopProject} editControls={controls} active={active} />
        )
    }
  }

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <section
        className={`shrink-0 px-6 py-7 flex flex-col gap-2 ${
          connected ? 'rounded-none' : 'rounded-card'
        } bg-raised mb-4`}
      >
        <header className="shrink-0 flex flex-row items-center gap-3">
          <div className="flex items-center gap-1.5 min-w-0">
            <span className="group relative flex items-center gap-1.5 min-w-0">
            {editingName ? (
              <div className="flex items-center gap-1.5">
                <input
                  ref={nameInputRef}
                  type="text"
                  value={nameDraft}
                  onChange={(e) => setNameDraft(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') commitName()
                    if (e.key === 'Escape') cancelNameEdit()
                  }}
                  onBlur={commitName}
                  maxLength={15}
                  placeholder={tc('dashboard_name_placeholder')}
                  className="focus-ring w-64 bg-base border border-accent rounded-btn px-3 py-2 text-xl font-medium text-ink outline-none"
                />
                  <Tooltip content={tc('dashboard_rename_save')} side="top">
                    <motion.button
                      type="button"
                      whileTap={{ scale: 0.92 }}
                      onClick={commitName}
                      aria-label={tc('dashboard_rename_save')}
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-accent hover:bg-accent/10 transition-colors"
                    >
                      <IconCheck className="w-4 h-4" />
                    </motion.button>
                  </Tooltip>
                  <Tooltip content={tc('cancel')} side="top">
                    <motion.button
                      type="button"
                      whileTap={{ scale: 0.92 }}
                      onClick={cancelNameEdit}
                      aria-label={tc('cancel')}
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/60 hover:text-ink hover:bg-raised transition-colors"
                    >
                      <IconX className="w-4 h-4" />
                    </motion.button>
                  </Tooltip>
              </div>
            ) : (
              <h1 className="font-display text-5xl font-bold leading-13 text-ink min-w-0">
                {displayName ? (
                  <>
                    {greeting}
                    {', '}
                    <span className="text-accent-bright">{displayName}</span>                    </>
                ) : (
                  greeting
                )}
              </h1>
            )}

            {!editingName && (
              <>
                  <Tooltip content={tc('dashboard_rename_aria')} side="right">
                    <button
                      type="button"
                      onClick={startEditingName}
                      aria-label={tc('dashboard_rename_aria')}
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 hover:text-ink hover:bg-raised shrink-0 opacity-0 group-hover:opacity-100 group-focus-within:opacity-100 transition-opacity duration-150"
                    >
                      <IconPencil className="w-3.5 h-3.5" />
                    </button>
                  </Tooltip>
                {settings.dashboard_custom_name && (
                    <Tooltip content={tc('dashboard_rename_reset')} side="right">
                      <button
                        type="button"
                        onClick={() =>
                          update({ ...settings, dashboard_custom_name: null })
                        }
                        aria-label={tc('dashboard_rename_reset')}
                        className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 hover:text-danger hover:bg-danger/10 shrink-0 opacity-0 group-hover:opacity-100 group-focus-within:opacity-100 transition-opacity duration-150"
                      >
                        <IconX className="w-3.5 h-3.5" />
                      </button>
                    </Tooltip>
                )}
              </>
            )}
            </span>
          </div>

          <Clock active={active} />
        </header>
      </section>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
      >
        <div className={`flex flex-col gap-6 ${connected ? 'pl-3' : ''} pr-5 pb-4`}>
          <div className="mt-1.5 flex items-center justify-between gap-3 flex-wrap">
            {isEnabled('quick_actions') ? (
              <QuickActions />
            ) : (
              <span />
            )}
              <motion.button
                type="button"
                whileTap={{ scale: 0.94 }}
                onClick={() => setEditingTiles((v) => !v)}
                aria-label={tc(editingTiles ? 'dashboard_done_customizing' : 'dashboard_customize')}
                className={`focus-ring cursor-pointer flex items-center gap-1.5 h-11 px-5 rounded-item text-sm font-semibold border transition-colors ${
                  editingTiles
                    ? 'bg-accent text-ink border-outline/50'
                    : 'text-muted hover:text-ink hover:bg-raised border-outline/50'
                }`}
              >
                <IconGear className="w-4 h-4" />
                {tc(editingTiles ? 'dashboard_done_customizing' : 'dashboard_customize')}
              </motion.button>
          </div>

          {isEnabled('stats') && (
            <StatsRow
              projects={projects.length}
              templates={templates}
              engines={installed.length}
              totalMs={totalMs}
            />
          )}

          {editingTiles && (
            <div className="rounded-item bg-overlay border border-outline/50 p-4 flex flex-col gap-3">
              <p className="text-[11px] text-muted/70 leading-relaxed">
                {tc('dashboard_customize_hint')}
              </p>
              <div className="flex flex-col gap-2.5">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-muted">
                  {tc('dashboard_presets')}
                </p>
                <div className="flex flex-wrap gap-2">
                  {DASHBOARD_PRESETS.map((preset) => {
                    const active = settingsMatchPreset(
                      preset,
                      settings.dashboard_sections,
                      settings.dashboard_section_order,
                      settings.dashboard_section_spans,
                      settings.dashboard_tall_sections,
                    )
                    return (
                        <button
                          key={preset.id}
                          type="button"
                          onClick={() => {
                            const next = presetToSettings(preset)
                            update({ ...settings, ...next })
                          }}
                          aria-pressed={active}
                          className={`focus-ring cursor-pointer flex items-center gap-1.5 px-3 h-8 rounded-btn text-xs font-semibold border transition-colors ${
                            active
                              ? 'bg-accent text-ink border-outline/50'
                              : 'text-muted hover:text-ink hover:bg-raised border-outline/50'
                          }`}
                        >
                          {active && <IconCheck className="w-3 h-3" />}
                          {tc(preset.labelKey)}
                        </button>
                    )
                  })}
                </div>
              </div>

              {settings.dashboard_custom_presets.length > 0 && (
                <div className="flex flex-col gap-2.5">
                  <p className="text-[11px] font-semibold uppercase tracking-wider text-muted">
                    {tc('dashboard_custom_presets')}
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {settings.dashboard_custom_presets.map((preset) => {
                      const active = settingsMatchPreset(
                        preset,
                        settings.dashboard_sections,
                        settings.dashboard_section_order,
                        settings.dashboard_section_spans,
                        settings.dashboard_tall_sections,
                      )
                      return (
                        <span
                          key={preset.id}
                          className="inline-flex items-center rounded-btn border border-outline/50 transition-colors"
                        >
                          <button
                            type="button"
                            onClick={() => {
                              const next = presetToSettings({
                                sections: preset.sections,
                                order: preset.order,
                                spans: preset.spans,
                                tall: preset.tall,
                              })
                              update({ ...settings, ...next })
                            }}
                            aria-pressed={active}
                            className={`focus-ring cursor-pointer flex items-center gap-1.5 pl-3 pr-1.5 h-8 rounded-btn text-xs font-semibold transition-colors ${
                              active
                                ? 'bg-accent text-ink'
                                : 'text-muted hover:text-ink hover:bg-raised'
                            }`}
                          >
                            {active && <IconCheck className="w-3 h-3" />}
                            {preset.name}
                          </button>
                            <Tooltip content={tc('dashboard_preset_delete')} side="left">
                              <button
                                type="button"
                                onClick={() => removePreset(preset.id)}
                                aria-label={tc('dashboard_preset_delete')}
                                className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors"
                              >
                                <IconX className="w-3 h-3" />
                              </button>
                            </Tooltip>
                        </span>
                      )
                    })}
                  </div>
                </div>
              )}

              <div className="flex flex-col gap-2 pt-2 border-t border-outline/50">
                <label className="text-[11px] font-semibold uppercase tracking-wider text-muted">
                  {tc('dashboard_preset_save')}
                </label>
                <div className="flex gap-2">
                  <input
                    value={presetDraft}
                    onChange={(e) => setPresetDraft(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') savePreset()
                    }}
                    placeholder={tc('dashboard_preset_name_placeholder')}
                    className="focus-ring bg-overlay border border-outline/50 rounded-item px-3.5 py-2 text-sm font-body text-ink placeholder:text-muted/70 transition-colors focus:border-accent-dim flex-1 min-w-0"
                  />
                  <motion.button
                    type="button"
                    whileTap={{ scale: 0.96 }}
                    onClick={savePreset}
                    disabled={!presetDraft.trim()}
                    className="focus-ring cursor-pointer px-4 py-2 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-40 disabled:cursor-default text-xs font-semibold text-ink transition-colors shrink-0"
                  >
                    {tc('dashboard_preset_save')}
                  </motion.button>
                </div>
                <p className="text-[11px] text-muted/60">
                  {tc('dashboard_preset_save_hint')}
                </p>
              </div>
            </div>
          )}

          {buildDashboardSegments(orderedTiles, settings.dashboard_section_spans).map(
            (segment) =>
              segment.span ? (
                <div key={segment.tiles[0].id} className="w-full min-w-0">
                  {renderTile(segment.tiles[0].id, segment.tiles[0].index)}
                </div>
              ) : (
                <Masonry
                  key={segment.tiles[0].id}
                  breakpointCols={{ default: 2, 1024: 1 }}
                  className="dashboard-masonry"
                  columnClassName="dashboard-masonry-column"
                >
                  {segment.tiles.map((t) => (
                    <div key={t.id} className="min-w-0">
                      {renderTile(t.id, t.index)}
                    </div>
                  ))}
                </Masonry>
              ),
          )}

          {editingTiles && hiddenTiles.length > 0 && (
            <div className="rounded-item bg-overlay border border-dashed border-outline/60 p-4">
              <p className="text-[11px] font-semibold uppercase tracking-wider text-muted mb-2.5">
                {tc('dashboard_hidden_tiles')}
              </p>
              <div className="flex flex-wrap gap-2">
                {hiddenTiles.map((id) => (
                  <button
                    key={id}
                    type="button"
                    onClick={() => addTile(id)}
                    className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 h-8 rounded-tag text-xs font-medium text-muted hover:text-accent-bright hover:bg-raised border border-outline/50 transition-colors"
                  >
                    <IconPlus className="w-3 h-3" />
                    {tileTitle[id]}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className="shrink-0 h-2" aria-hidden="true" />
        </div>
      </OverlayScrollArea>
    </div>
  )
}
