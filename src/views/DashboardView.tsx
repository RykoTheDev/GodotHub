import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { useTranslation } from 'react-i18next'
import { TodoDueTile } from '../components/cards/TodoDueTile'
import { useProjectsContext } from '../hooks/projectsContext'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { useSettings } from '../hooks/useSettings'
import { useTauriEvent } from '../lib/useTauriEvent'
import { api, getCachedProjectIcon } from '../lib/api'
import { pushToast } from '../lib/toast'
import {
  formatDate,
  formatLastOpened,
  formatTime,
  type LastOpenedTimeFormat,
} from '../lib/lastOpened'
import { formatDuration } from '../lib/duration'
import { formatLocaleDate } from '../lib/locale'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { Tooltip } from '../components/reusables/Tooltip'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import {
  IconArrowUpDown,
  IconCheck,
  IconCheckCircle,
  IconChevronRight,
  IconClock,
  IconFolder,
  IconFolderPlus,
  IconGamepad,
  IconHistory,
  IconImport,
  IconPencil,
  IconPin,
  IconPlay,
  IconRefresh,
  IconRocket,
  IconStar,
  IconStopwatch,
  IconTerminal,
  IconX,
} from '../lib/icons'
import type { Project, TimeInsights } from '../types'

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

function weekdayName(weekday: number): string {
  return formatLocaleDate(new Date(2026, 0, 5 + weekday), { weekday: 'long' })
}

const ACTIVITY_RANGES = ['daily', 'weekly', 'monthly', 'yearly'] as const
type ActivityRange = (typeof ACTIVITY_RANGES)[number]

function activityLabel(
  range: ActivityRange,
  key: string,
  timeFormat: LastOpenedTimeFormat,
): string {
  if (range === 'daily') {
    const hour = Number(key.slice(11, 13))
    if (timeFormat === '24h') return `${String(hour).padStart(2, '0')}`
    const suffix = hour >= 12 ? 'p' : 'a'
    const h12 = hour % 12 === 0 ? 12 : hour % 12
    return `${h12}${suffix}`
  }
  if (range === 'yearly') {
    return formatLocaleDate(new Date(`${key}-01T00:00:00`), { month: 'short' })
  }
  const d = new Date(`${key}T00:00:00`)
  return range === 'weekly'
    ? formatLocaleDate(d, { weekday: 'short' })
    : String(d.getDate())
}

function Panel({
  title,
  icon,
  action,
  delay = 0,
  className = '',
  children,
}: {
  title: string
  icon: ReactNode
  action?: ReactNode
  delay?: number
  className?: string
  children: ReactNode
}) {
  return (
    <section
      style={{ animationDelay: `${delay}ms` }}
      className={`dash-rise flex flex-col gap-4 rounded-card bg-surface border border-outline/40 p-5 shadow-sm shadow-black/10 ${className}`}
    >
      <header className="flex items-center gap-2.5 min-w-0">
        <span className="grid place-items-center w-7 h-7 shrink-0 rounded-tile bg-overlay border border-outline/50 text-accent-bright">
          {icon}
        </span>
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted truncate">
          {title}
        </h2>
        <div className="flex-1 h-px bg-outline/40 min-w-2" />
        {action}
      </header>
      {children}
    </section>
  )
}

function EmptyCard({ text }: { text: string }) {
  return (
    <p className="text-xs text-muted/70 leading-relaxed rounded-item bg-overlay border border-dashed border-outline/50 px-4 py-8 text-center">
      {text}
    </p>
  )
}

function ProjectAvatar({ project }: { project: Project }) {
  const [icon, setIcon] = useState<string | null>(() =>
    getCachedProjectIcon(project.path),
  )

  useEffect(() => {
    let cancelled = false
    setIcon(getCachedProjectIcon(project.path))
    api
      .getProjectIcon(project.path)
      .then((value) => {
        if (!cancelled) setIcon(value)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [project.path])

  if (icon) {
    return (
      <span className="relative w-9 h-9 shrink-0 rounded-tile overflow-hidden bg-surface border border-outline/50 shadow-sm shadow-black/20">
        <img src={icon} alt="" aria-hidden="true" className="w-full h-full object-cover" />
      </span>
    )
  }

  const letter = (project.name.trim()[0] || '?').toUpperCase()
  return (
    <span className="relative w-9 h-9 shrink-0 grid place-items-center rounded-tile bg-linear-to-br from-accent to-accent-dim text-ink text-sm font-bold border border-accent-bright/30 shadow-sm shadow-accent/20">
      {letter}
    </span>
  )
}

function ProjectRow({
  project,
  timeFormat,
  showOpened = true,
}: {
  project: Project
  timeFormat: LastOpenedTimeFormat
  showOpened?: boolean
}) {
  const { t: tc } = useTranslation('dashboard')
  const openedAt = showOpened ? formatLastOpened(project.last_opened, timeFormat) : null
  return (
    <button
      type="button"
      onClick={() => dispatch('app:open-project', project.id)}
      className="group focus-ring cursor-pointer w-full flex items-center gap-3 p-2.5 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 text-start"
    >
      <ProjectAvatar project={project} />
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-medium text-ink truncate">
          {project.name}
        </span>
        <span className="block text-2xs text-muted/70 truncate font-mono">
          {project.path}
        </span>
      </span>
      {openedAt && (
        <span className="shrink-0 text-3xs text-muted/60 tabular-nums">
          {tc('dashboard_opened_at', { time: openedAt })}
        </span>
      )}
      <IconChevronRight className="rtl:rotate-180 w-3.5 h-3.5 shrink-0 text-muted/30 group-hover:text-accent-bright" />
    </button>
  )
}

function QuickActions() {
  const { t: tc } = useTranslation('dashboard')
  const actions = [
    {
      key: 'new',
      label: tc('dashboard_new_project'),
      Icon: IconFolderPlus,
      onClick: () => dispatch('app:new-project-request'),
      primary: true,
    },
    {
      key: 'import',
      label: tc('dashboard_import_project'),
      Icon: IconImport,
      onClick: () => dispatch('app:import-project-request'),
      primary: false,
    },
    {
      key: 'scan',
      label: tc('dashboard_scan_projects'),
      Icon: IconRefresh,
      onClick: () => dispatch('app:scan-projects'),
      primary: false,
    },
  ]
  return (
    <div className="flex items-center gap-2.5 flex-wrap">
      {actions.map((a) => (
        <button
          key={a.key}
          type="button"
          onClick={a.onClick}
          className={`focus-ring cursor-pointer inline-flex items-center gap-2 h-11 px-5 rounded-item font-semibold text-sm shadow-md shadow-black/10 border border-outline/50 ${
            a.primary
              ? 'bg-accent text-ink hover:bg-accent-bright'
              : 'bg-overlay text-ink hover:bg-raised hover:border-accent-dim/60'
          }`}
        >
          <a.Icon className={`w-4 h-4 ${a.primary ? 'text-ink' : 'text-accent-bright'}`} />
          {a.label}
        </button>
      ))}
    </div>
  )
}

function KpiCard({
  label,
  hint,
  Icon,
  value,
  animate,
  sub,
  subTone,
  grad,
  onClick,
  delay = 0,
}: {
  label: string
  hint?: string
  Icon: React.ComponentType<{ className?: string }>
  value: ReactNode
  animate?: number
  sub?: string
  subTone?: 'up' | 'down'
  grad: string
  onClick?: () => void
  delay?: number
}) {
  const Tag = onClick ? 'button' : 'div'
  return (
    <Tag
      {...(onClick ? { type: 'button' as const, onClick } : {})}
      style={{ animationDelay: `${delay}ms` }}
      className={`dash-rise group relative overflow-hidden text-start rounded-card bg-surface border border-outline/40 px-5 py-4 flex flex-col shadow-sm shadow-black/10 ${
        onClick ? 'focus-ring cursor-pointer hover:border-outline hover:-translate-y-0.5' : ''
      }`}
    >
      <Icon className="pointer-events-none absolute -bottom-7 -inset-e-7 w-28 h-28 rotate-12 text-ink/4.5" />
      <div className="relative z-10 flex items-start justify-between gap-2">
        <span className="pt-1 truncate text-3xs font-semibold uppercase tracking-wider text-muted/70">
          {label}
        </span>
        <span className="grid place-items-center w-9 h-9 shrink-0 -rotate-6 rounded-tile bg-overlay border border-outline/50 text-accent-bright group-hover:rotate-0">
          <Icon className="w-4 h-4" />
        </span>
      </div>
      <span className="relative z-10 mt-3 block text-[1.6rem] leading-none font-bold tabular-nums text-ink">
        {animate !== undefined ? <AnimatedNumber value={animate} /> : value}
      </span>
      <span
        aria-hidden="true"
        className={`relative z-10 mt-2.5 block h-1 w-9 origin-left rtl:origin-right rounded-full bg-linear-to-r ${grad}`}
      />
      <span
        className={`relative z-10 mt-auto pt-3 inline-flex items-center gap-1 text-3xs font-medium ${
          sub
            ? subTone === 'down'
              ? 'text-danger'
              : 'text-mint'
            : 'text-muted/40 group-hover:text-muted'
        }`}
      >
        {sub ?? hint ?? label}
        {onClick && !sub && <IconChevronRight className="rtl:rotate-180 w-3 h-3" />}
      </span>
    </Tag>
  )
}

function ActivityPanel({
  insights,
  timeFormat,
  active,
}: {
  insights: TimeInsights | null
  timeFormat: LastOpenedTimeFormat
  active: boolean
}) {
  const { t: tc } = useTranslation('dashboard')
  const [range, setRange] = useState<ActivityRange>('weekly')
  const [data, setData] = useState<[string, number][]>([])
  const [loading, setLoading] = useState(true)
  const [revealed, setRevealed] = useState(false)

  useEffect(() => {
    if (!active) return
    let cancelled = false
    setLoading(true)
    setRevealed(false)
    api
      .getActivity(range)
      .then((d) => {
        if (cancelled) return
        setData(Array.isArray(d) ? d : [])
        setLoading(false)
        requestAnimationFrame(() =>
          requestAnimationFrame(() => {
            if (!cancelled) setRevealed(true)
          }),
        )
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
  const labelStep = data.length > 14 ? Math.ceil(data.length / 7) : 1

  const toggle = (
    <div className="flex items-center gap-1 p-1 rounded-btn bg-overlay border border-outline/50">
      {ACTIVITY_RANGES.map((r) => (
        <button
          key={r}
          type="button"
          onClick={() => setRange(r)}
          aria-pressed={range === r}
          className={`focus-ring cursor-pointer px-2.5 h-7 rounded-btn text-2xs font-semibold ${
            range === r
              ? 'bg-accent text-ink shadow-sm shadow-black/20'
              : 'text-muted hover:text-ink hover:bg-raised'
          }`}
        >
          {tc(`dashboard_range_${r}`)}
        </button>
      ))}
    </div>
  )

  const bars = range === 'monthly' ? 30 : range === 'yearly' ? 12 : range === 'daily' ? 24 : 7

  return (
    <Panel
      title={tc(`dashboard_${range}`)}
      icon={<IconClock className="w-3.5 h-3.5" />}
      action={toggle}
      delay={120}
    >
      {loading ? (
        <div className="flex items-end gap-1.5 h-56">
          {Array.from({ length: bars }).map((_, i) => (
            <div key={i} className="flex-1 h-full rounded-md bg-raised animate-pulse" />
          ))}
        </div>
      ) : total === 0 ? (
        <EmptyCard text={tc(`dashboard_${range}_empty`)} />
      ) : (
        <div className="relative">
          <div
            aria-hidden="true"
            className="absolute inset-x-0 top-0 bottom-5 flex flex-col justify-between pointer-events-none"
          >
            {[0, 1, 2, 3].map((i) => (
              <div key={i} className="h-px w-full bg-outline/25" />
            ))}
          </div>
          <div className="relative flex items-end gap-1.5 h-56">
            {data.map(([key, seconds], i) => {
              const pct = seconds > 0 ? Math.max((seconds / max) * 100, 3) : 0
              const show = i % labelStep === 0
              return (
                <Tooltip
                  key={key}
                  side="top"
                  delay={80}
                  className="flex-1 min-w-0 h-full"
                  content={
                    <span className="flex items-center gap-1.5 tabular-nums">
                      <span className="text-muted/70">
                        {activityLabel(range, key, timeFormat)}
                      </span>
                      <span className="font-semibold text-ink">
                        {formatDuration(seconds * 1000)}
                      </span>
                    </span>
                  }
                >
                  <div className="group/bar w-full h-full flex flex-col justify-end items-center gap-2">
                    <div className="relative w-full flex-1 flex items-end">
                      <div
                        className="w-full origin-bottom rounded-t-md bg-linear-to-t from-accent-dim to-accent-bright opacity-80 group-hover/bar:opacity-100"
                        style={{
                          height: `${pct}%`,
                          transform: revealed ? 'scaleY(1)' : 'scaleY(0)',
                          transition: 'transform 700ms var(--ease-out-expo)',
                          transitionDelay: `${i * 16}ms`,
                        }}
                        aria-label={tc('dashboard_weekly_aria', {
                          label: formatDuration(seconds * 1000),
                        })}
                      />
                    </div>
                    <span className="h-3 text-4xs text-muted/60 shrink-0 tabular-nums truncate max-w-full">
                      {show ? activityLabel(range, key, timeFormat) : ''}
                    </span>
                  </div>
                </Tooltip>
              )
            })}
          </div>
        </div>
      )}

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 pt-1">
        <InsightChip
          icon={<IconClock className="w-3.5 h-3.5" />}
          label={tc('dashboard_activity_tracked')}
          value={total > 0 ? formatDuration(total * 1000) : '-'}
          tone="text-accent-bright"
        />
        <InsightChip
          icon={<IconStopwatch className="w-3.5 h-3.5" />}
          label={tc('dashboard_activity_peak')}
          value={total > 0 ? formatDuration(max * 1000) : '-'}
          tone="text-violet-400"
        />
        <InsightChip
          icon={<IconStar className="w-3.5 h-3.5" />}
          label={tc('dashboard_insights_longest_streak')}
          value={tc('dashboard_insights_days', {
            count: insights?.longest_streak_days ?? 0,
          })}
          tone="text-amber"
        />
        <InsightChip
          icon={<IconGamepad className="w-3.5 h-3.5" />}
          label={tc('dashboard_insights_productive_day')}
          value={
            insights == null || insights.most_productive_weekday === null
              ? '-'
              : weekdayName(insights.most_productive_weekday)
          }
          tone="text-mint"
        />
      </div>
    </Panel>
  )
}

function InsightChip({
  icon,
  label,
  value,
  tone,
}: {
  icon: ReactNode
  label: string
  value: string
  tone: string
}) {
  return (
    <div className="flex items-start gap-2.5 p-3 rounded-item bg-overlay border border-outline/50">
      <span className={`grid place-items-center w-7 h-7 shrink-0 rounded-btn bg-raised border border-outline/50 ${tone}`}>
        {icon}
      </span>
      <span className="min-w-0">
        <span className="block text-3xs font-semibold uppercase tracking-wider text-muted/60 truncate">
          {label}
        </span>
        <span className="block text-sm font-semibold text-ink truncate mt-0.5">
          {value}
        </span>
      </span>
    </div>
  )
}

function TopByTime({ projects }: { projects: Project[] }) {
  const { t: tc } = useTranslation('dashboard')
  const top = useMemo(
    () =>
      [...projects]
        .filter((p) => (p.total_time_seconds ?? 0) > 0)
        .sort((a, b) => (b.total_time_seconds ?? 0) - (a.total_time_seconds ?? 0))
        .slice(0, 6),
    [projects],
  )
  const max = Math.max(...top.map((p) => p.total_time_seconds ?? 0), 1)

  return (
    <Panel
      title={tc('dashboard_top_time')}
      icon={<IconStopwatch className="w-3.5 h-3.5" />}
      delay={180}
    >
      {top.length === 0 ? (
        <EmptyCard text={tc('dashboard_top_time_empty')} />
      ) : (
        <div className="flex flex-col gap-2.5">
          {top.map((p, i) => (
            <button
              key={p.id}
              type="button"
              onClick={() => dispatch('app:open-project', p.id)}
              className="group focus-ring cursor-pointer w-full flex items-center gap-3 p-2.5 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 text-start"
            >
              <span className="grid place-items-center w-6 h-6 shrink-0 rounded-btn bg-raised border border-outline/50 text-3xs font-bold tabular-nums text-muted group-hover:text-accent-bright">
                {i + 1}
              </span>
              <span className="min-w-0 flex-1">
                <span className="flex items-center justify-between gap-2">
                  <span className="block text-sm font-medium text-ink truncate">
                    {p.name}
                  </span>
                  <span className="shrink-0 text-2xs text-muted/70 tabular-nums">
                    {formatDuration((p.total_time_seconds ?? 0) * 1000)}
                  </span>
                </span>
                <span className="block h-1.5 rounded-full bg-raised mt-2 overflow-hidden">
                  <span
                    className="block h-full rounded-full bg-linear-to-r from-accent-dim to-accent-bright"
                    style={{
                      width: `${Math.max(((p.total_time_seconds ?? 0) / max) * 100, 3)}%`,
                    }}
                  />
                </span>
              </span>
            </button>
          ))}
        </div>
      )}
    </Panel>
  )
}

interface RunningProject {
  id: string
  name: string
  version: string
  startedAt: number
}

function RunningPanel({
  running,
  onStop,
  active,
}: {
  running: RunningProject[]
  onStop: (id: string) => void
  active: boolean
}) {
  const { t: tc } = useTranslation('dashboard')
  const [now, setNow] = useState(() => Date.now())

  useEffect(() => {
    if (!active || running.length === 0) return
    setNow(Date.now())
    const id = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [active, running.length])

  return (
    <Panel
      title={tc('dashboard_running')}
      icon={<IconPlay className="w-3.5 h-3.5" />}
      delay={220}
    >
      {running.length === 0 ? (
        <EmptyCard text={tc('dashboard_running_empty')} />
      ) : (
        <div className="flex flex-col gap-2">
          {running.map((p) => (
            <div
              key={p.id}
              className="flex items-center gap-3 p-2.5 rounded-item bg-overlay border border-mint/25"
            >
              <span className="relative flex w-2 h-2 shrink-0">
                <span className="relative inline-flex rounded-full w-2 h-2 bg-mint" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-medium text-ink truncate">
                  {p.name}
                </span>
                <span className="block text-2xs text-muted/70 tabular-nums">
                  {p.version ? `Godot ${p.version} · ` : ''}
                  {formatDuration(now - p.startedAt)}
                </span>
              </span>
              <button
                type="button"
                onClick={() => onStop(p.id)}
                aria-label={`${tc('stop')} ${p.name}`}
                className="focus-ring cursor-pointer w-6 h-6 rounded-btn inline-flex items-center justify-center text-muted/50 hover:text-danger hover:bg-danger/10 shrink-0"
              >
                <IconX className="w-3.5 h-3.5" />
              </button>
            </div>
          ))}
        </div>
      )}
    </Panel>
  )
}

function Clock({
  active,
  timeFormat,
  dateFormat,
}: {
  active: boolean
  timeFormat: LastOpenedTimeFormat
  dateFormat: 'DD-MM-YYYY' | 'MM-DD-YYYY' | 'YYYY-MM-DD'
}) {
  const { t: tc } = useTranslation('dashboard')
  const [now, setNow] = useState(() => new Date())

  useEffect(() => {
    if (!active) return
    setNow(new Date())
    const id = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(id)
  }, [active])

  return (
    <div className="ms-auto shrink-0 flex flex-col items-end gap-1">
      <span
        className="font-display text-3xl font-semibold text-ink leading-none tabular-nums"
        aria-label={tc('dashboard_clock_aria')}
      >
        {formatTime(now, timeFormat)}
      </span>
      <span className="text-sm text-muted/70 leading-none">
        {formatDate(now, dateFormat)}
      </span>
    </div>
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
  const installed = useGodotVersionsContext((v) => v.installed)

  const [osName, setOsName] = useState<string | null>(null)
  const [greetingHour, setGreetingHour] = useState(() => new Date().getHours())
  const [insights, setInsights] = useState<TimeInsights | null>(null)
  const [running, setRunning] = useState<RunningProject[]>([])

  const [editingName, setEditingName] = useState(false)
  const [nameDraft, setNameDraft] = useState('')
  const nameInputRef = useRef<HTMLInputElement>(null)
  const nameCancelRef = useRef(false)

  useEffect(() => {
    api.getOsUsername().then(setOsName).catch(() => setOsName(null))
  }, [])

  useEffect(() => {
    if (!active) return
    let cancelled = false
    api
      .getTimeInsights()
      .then((d) => {
        if (!cancelled) setInsights(d)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [active])

  useEffect(() => {
    if (!active) return
    const id = setInterval(() => {
      const h = new Date().getHours()
      setGreetingHour((prev) => (prev === h ? prev : h))
    }, 30000)
    return () => clearInterval(id)
  }, [active])

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
    api.stopProject(id).catch((e) => pushToast('error', String(e)))
  }, [])

  const openEngine = (tag: string) => {
    api.openGodotVersion(tag).catch((err) => pushToast('error', String(err)))
  }

  const timeFormat = settings.last_opened_time_format
  const displayName = (settings.dashboard_custom_name || osName || '').slice(0, 40)
  const greeting = tc(`greeting_${greetingKey(greetingHour)}`)

  const recent = useMemo(
    () =>
      [...projects]
        .filter((p) => p.last_opened)
        .sort(
          (a, b) =>
            new Date(b.last_opened!).getTime() - new Date(a.last_opened!).getTime(),
        )
        .slice(0, 6),
    [projects],
  )
  const pinned = useMemo(() => projects.filter((p) => p.pinned).slice(0, 6), [projects])
  const totalMs = useMemo(
    () => projects.reduce((acc, p) => acc + (p.total_time_seconds ?? 0) * 1000, 0),
    [projects],
  )

  const monthDelta =
    insights && insights.last_month_seconds > 0
      ? Math.round(
          ((insights.this_month_seconds - insights.last_month_seconds) /
            insights.last_month_seconds) *
            100,
        )
      : null

  const commitName = () => {
    setEditingName(false)
    if (nameCancelRef.current) {
      nameCancelRef.current = false
      return
    }
    update({ ...settings, dashboard_custom_name: nameDraft.trim() || null })
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

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <section
        className={`shrink-0 relative overflow-hidden px-6 py-7 flex flex-col gap-2 bg-raised mb-4 ${
          connected ? 'rounded-none' : 'rounded-card'
        }`}
      >
        <span
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-0 top-0 h-px bg-linear-to-r from-transparent via-accent/60 to-transparent"
        />
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
                    <button
                      type="button"
                      onClick={commitName}
                      aria-label={tc('dashboard_rename_save')}
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-accent hover:bg-accent/10"
                    >
                      <IconCheck className="w-4 h-4" />
                    </button>
                  </Tooltip>
                  <Tooltip content={tc('cancel')} side="top">
                    <button
                      type="button"
                      onClick={cancelNameEdit}
                      aria-label={tc('cancel')}
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/60 hover:text-ink hover:bg-surface"
                    >
                      <IconX className="w-4 h-4" />
                    </button>
                  </Tooltip>
                </div>
              ) : (
                <h1 className="font-display text-5xl font-bold leading-tight text-ink min-w-0">
                  {displayName ? (
                    <>
                      {greeting}
                      {', '}
                      <span className="text-accent-bright">{displayName}</span>
                    </>
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
                      className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 hover:text-ink hover:bg-surface shrink-0 opacity-0 group-hover:opacity-100 group-focus-within:opacity-100"
                    >
                      <IconPencil className="w-3.5 h-3.5" />
                    </button>
                  </Tooltip>
                  {settings.dashboard_custom_name && (
                    <Tooltip content={tc('dashboard_rename_reset')} side="right">
                      <button
                        type="button"
                        onClick={() => update({ ...settings, dashboard_custom_name: null })}
                        aria-label={tc('dashboard_rename_reset')}
                        className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 hover:text-danger hover:bg-danger/10 shrink-0 opacity-0 group-hover:opacity-100 group-focus-within:opacity-100"
                      >
                        <IconX className="w-3.5 h-3.5" />
                      </button>
                    </Tooltip>
                  )}
                </>
              )}
            </span>
          </div>

          <Clock
            active={active}
            timeFormat={timeFormat}
            dateFormat={settings.last_opened_date_format}
          />
        </header>
      </section>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-ms-2 -me-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
      >
        <div className={`flex flex-col gap-5 ${connected ? 'ps-3' : 'ps-2'} pe-5 pb-4`}>
          <div className="mt-1.5">
            <QuickActions />
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <KpiCard
              label={tc('dashboard_stat_projects')}
              Icon={IconFolder}
              value={projects.length}
              animate={projects.length}
              grad="from-[#7aa0ff] to-[#4f7cff]"
              onClick={() => dispatch('app:set-tab', 'projects')}
              delay={0}
            />
            <KpiCard
              label={tc('dashboard_stat_total_time')}
              hint={tc('dashboard_stat_total_time_hint')}
              Icon={IconClock}
              value={formatDuration(totalMs)}
              grad="from-[#a78bfa] to-[#8b5cf6]"
              delay={40}
            />
            <KpiCard
              label={tc('dashboard_insights_current_streak')}
              Icon={IconRocket}
              value={tc('dashboard_insights_days', {
                count: insights?.current_streak_days ?? 0,
              })}
              grad="from-[#4ade80] to-[#2fbf71]"
              delay={80}
            />
            <KpiCard
              label={tc('dashboard_insights_this_month')}
              Icon={IconArrowUpDown}
              value={formatDuration((insights?.this_month_seconds ?? 0) * 1000)}
              sub={
                monthDelta === null
                  ? undefined
                  : monthDelta >= 0
                    ? tc('dashboard_insights_delta_up', { pct: monthDelta })
                    : tc('dashboard_insights_delta_down', { pct: Math.abs(monthDelta) })
              }
              subTone={monthDelta !== null && monthDelta < 0 ? 'down' : 'up'}
              grad="from-[#fbbf24] to-[#f0b132]"
              delay={120}
            />
          </div>

          <ActivityPanel insights={insights} timeFormat={timeFormat} active={active} />

          {settings.project_todos_enabled && (
            <Panel
              title={tc('dashboard_todos')}
              icon={<IconCheckCircle className="w-3.5 h-3.5" />}
              delay={160}
            >
              <TodoDueTile />
            </Panel>
          )}

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
            <div className="lg:col-span-7">
              <TopByTime projects={projects} />
            </div>
            <div className="lg:col-span-5">
              <Panel
                title={tc('dashboard_recent')}
                icon={<IconHistory className="w-3.5 h-3.5" />}
                delay={200}
              >
                {recent.length > 0 ? (
                  <div className="flex flex-col gap-2">
                    {recent.map((p) => (
                      <ProjectRow key={p.id} project={p} timeFormat={timeFormat} />
                    ))}
                  </div>
                ) : (
                  <EmptyCard text={tc('dashboard_recent_empty')} />
                )}
              </Panel>
            </div>

            <div className="lg:col-span-4">
              <RunningPanel running={running} onStop={stopProject} active={active} />
            </div>
            <div className="lg:col-span-4">
              <Panel
                title={tc('dashboard_pinned')}
                icon={<IconPin className="w-3.5 h-3.5" />}
                delay={260}
              >
                {pinned.length > 0 ? (
                  <div className="flex flex-col gap-2">
                    {pinned.map((p) => (
                      <ProjectRow
                        key={p.id}
                        project={p}
                        timeFormat={timeFormat}
                        showOpened={false}
                      />
                    ))}
                  </div>
                ) : (
                  <EmptyCard text={tc('dashboard_pinned_empty')} />
                )}
              </Panel>
            </div>
            <div className="lg:col-span-4">
              <Panel
                title={tc('dashboard_engines')}
                icon={<IconRocket className="w-3.5 h-3.5" />}
                delay={300}
              >
                {installed.length > 0 ? (
                  <div className="flex flex-col gap-2">
                    {installed.slice(0, 4).map((v) => (
                      <div
                        key={v.tag}
                        className="group flex items-center gap-3 p-2.5 rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60"
                      >
                        <span className="min-w-0 flex-1">
                          <span className="block text-sm font-medium text-ink truncate font-mono">
                            {v.custom_name || v.tag}
                          </span>
                          <span className="block text-2xs text-muted/70 truncate font-mono">
                            {v.executable_path}
                          </span>
                        </span>
                        <button
                          type="button"
                          onClick={() => openEngine(v.tag)}
                          aria-label={v.custom_name || v.tag}
                          className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/60 hover:text-ink hover:bg-surface shrink-0"
                        >
                          <IconTerminal className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>
                ) : (
                  <EmptyCard text={tc('dashboard_engines_empty')} />
                )}
              </Panel>
            </div>
          </div>

          <div className="shrink-0 h-2" aria-hidden="true" />
        </div>
      </OverlayScrollArea>
    </div>
  )
}
