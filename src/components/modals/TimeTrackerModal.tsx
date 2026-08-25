import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Project } from '../../types'
import { api } from '../../lib/api'
import { effectiveTotalMs } from '../../lib/projectSort'
import { formatDuration } from '../../lib/duration'
import { formatLocaleDate } from '../../lib/locale'
import { ModalShell } from './ModalShell'

import { IconStopwatch, IconClock, IconHistory } from '../../lib/icons'

interface Props {
  project: Project
  onClose: () => void
}

function isSameLocalDay(aMs: number, bMs: number): boolean {
  const a = new Date(aMs)
  const b = new Date(bMs)
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

function startOfLocalWeek(ms: number): number {
  const d = new Date(ms)
  const day = (d.getDay() + 6) % 7
  d.setHours(0, 0, 0, 0)
  d.setDate(d.getDate() - day)
  return d.getTime()
}

function isSameLocalWeek(aMs: number, bMs: number): boolean {
  return startOfLocalWeek(aMs) === startOfLocalWeek(bMs)
}

function dayLabel(key: string): string {
  return formatLocaleDate(new Date(`${key}T00:00:00`), {
    weekday: 'short',
  })
}

export function TimeTrackerModal({ project, onClose }: Props) {
  const { t } = useTranslation('common')

  const sessionStart = project.session_started_at_ms
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (!sessionStart) return
    setNow(Date.now())
    const id = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [sessionStart])

  const liveElapsed = sessionStart ? Math.max(0, now - sessionStart) : 0
  const allMs = effectiveTotalMs(project, now)
  const todayMs =
    (project.time_today_seconds ?? 0) * 1000 +
    (sessionStart && isSameLocalDay(sessionStart, Date.now())
      ? liveElapsed
      : 0)
  const weekMs =
    (project.time_week_seconds ?? 0) * 1000 +
    (sessionStart && isSameLocalWeek(sessionStart, Date.now())
      ? liveElapsed
      : 0)

  const [weekly, setWeekly] = useState<[string, number][]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    api
      .getProjectActivity(project.id)
      .then((d) => {
        if (cancelled) return
        setWeekly(d)
        setLoading(false)
      })
      .catch(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [project.id])

  const weekTotal = weekly.reduce((acc, [, s]) => acc + s, 0)
  const max = Math.max(...weekly.map(([, s]) => s), 1)

  return (
    <ModalShell
      icon={<IconStopwatch className="w-5 h-5 text-accent-bright" />}
      title={t('time_tracked_title')}
      description={project.name}
      maxWidth="max-w-xl"
      onClose={onClose}
    >
      <div className="p-6 pt-4 flex flex-col gap-6">
        <div className="grid grid-cols-3 gap-3">
          <div className="flex flex-col gap-1.5 px-4 py-3.5 rounded-xl bg-raised border border-line/60">
            <span className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted/60">
              <IconClock className="w-3 h-3" />
              {t('time_today')}
            </span>
            <span className="text-lg font-semibold text-ink tabular-nums">
              {formatDuration(todayMs)}
            </span>
          </div>
          <div className="flex flex-col gap-1.5 px-4 py-3.5 rounded-xl bg-raised border border-line/60">
            <span className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted/60">
              <IconHistory className="w-3 h-3" />
              {t('time_this_week')}
            </span>
            <span className="text-lg font-semibold text-ink tabular-nums">
              {formatDuration(weekMs)}
            </span>
          </div>
          <div className="flex flex-col gap-1.5 px-4 py-3.5 rounded-xl bg-raised border border-line/60">
            <span className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted/60">
              <IconStopwatch className="w-3 h-3" />
              {t('time_all_time')}
            </span>
            <span className="text-lg font-semibold text-ink tabular-nums">
              {formatDuration(allMs)}
            </span>
          </div>
        </div>

        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <h4 className="text-[11px] font-semibold uppercase tracking-wider text-muted/60">
              {t('time_weekly_chart')}
            </h4>
            <span className="text-[11px] text-muted/60 tabular-nums">
              {t('time_week_total', { total: formatDuration(weekTotal * 1000) })}
            </span>
          </div>

          {loading ? (
            <div className="flex items-end gap-1.5 h-32 animate-pulse">
              {Array.from({ length: 7 }).map((_, i) => (
                <div key={i} className="flex-1 flex flex-col items-center gap-1 h-full">
                  <div className="flex-1 w-full rounded bg-raised" />
                </div>
              ))}
            </div>
          ) : weekTotal === 0 ? (
            <div className="flex flex-col items-center justify-center gap-2 py-10 text-muted/60">
              <IconStopwatch className="w-7 h-7 opacity-40" />
              <p className="text-sm">{t('time_weekly_empty')}</p>
            </div>
          ) : (
            <div className="flex items-end gap-1.5 h-32">
              {weekly.map(([key, seconds]) => {
                const pct = seconds > 0 ? Math.max((seconds / max) * 100, 6) : 0
                return (
                  <div key={key} className="flex-1 flex flex-col items-center gap-1 h-full min-w-0">
                    <div className="flex-1 w-full flex items-end rounded-md overflow-hidden bg-raised">
                        <div
                          title={formatDuration(seconds * 1000)}
                          className="w-full rounded-t bg-accent/50 hover:bg-accent-bright transition-colors w-full h-full flex items-end"
                          style={{ height: `${pct}%` }}
                        />
                    </div>
                    <span className="text-[9px] text-muted/60 shrink-0">
                      {dayLabel(key)}
                    </span>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </ModalShell>
  )
}
