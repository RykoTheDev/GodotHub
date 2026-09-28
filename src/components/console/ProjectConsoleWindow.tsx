import {
  memo,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { api } from '../../lib/api'
import { useTauriEvent } from '../../lib/useTauriEvent'
import { ansiSpanStyle, parseAnsi, stripAnsi } from '../../lib/ansi'
import {
  annotateConsoleLines,
  countConsoleLevels,
  CONSOLE_LEVELS,
  type ConsoleLevel,
} from '../../lib/consoleLog'
import {
  IconChevronDown,
  IconClone,
  IconGrip,
  IconMinus,
  IconSquare,
  IconTerminal,
  IconTrash,
  IconWindowMaximize,
  IconWindowRestore,
  IconX,
} from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'
import type { ConsoleLine } from '../../types'

const POLL_MS = 180
/** Slower cadence while the pill is up; the buffer is caught up on reopen. */
const POLL_MS_IDLE = 1000
/** Rows painted at once; the buffer keeps more, it just isn't all on screen. */
const MAX_RENDERED_LINES = 2000
/** Where the minimised pill is parked between sessions. */
const PILL_STORAGE_KEY = 'new_ui_console_pill'
/** Gap the pill keeps from the edge of the app frame. */
const PILL_MARGIN = 10
/** Release the pill within this distance of an edge and it snaps to it. */
const SNAP_DISTANCE = 56

interface ConsoleState {
  lines: ConsoleLine[]
  nextSeq: number
  running: boolean
  exitCode: number | null
  /** True once the backend says the process is gone and the buffer is final. */
  done: boolean
  name: string
}

interface LaunchedPayload {
  id: string
  name: string
  version: string
  console?: boolean
}

interface Point {
  x: number
  y: number
}

interface Size {
  w: number
  h: number
}

const LEVEL_PILL_ACTIVE: Record<ConsoleLevel, string> = {
  error: 'bg-danger/15 text-danger border-danger/35',
  warning: 'bg-amber/15 text-amber border-amber/35',
  info: 'bg-raised text-ink border-line',
}

function clampPill(pos: Point, frame: Size, size: Size): Point {
  const maxX = Math.max(PILL_MARGIN, frame.w - size.w - PILL_MARGIN)
  const maxY = Math.max(PILL_MARGIN, frame.h - size.h - PILL_MARGIN)
  return {
    x: Math.min(Math.max(pos.x, PILL_MARGIN), maxX),
    y: Math.min(Math.max(pos.y, PILL_MARGIN), maxY),
  }
}

/** Keeps the pill in frame and pulls it to the nearest edge when let go near one. */
function snapPill(pos: Point, frame: Size, size: Size): Point {
  const clamped = clampPill(pos, frame, size)
  const maxX = Math.max(PILL_MARGIN, frame.w - size.w - PILL_MARGIN)
  const maxY = Math.max(PILL_MARGIN, frame.h - size.h - PILL_MARGIN)
  const x =
    clamped.x - PILL_MARGIN < SNAP_DISTANCE
      ? PILL_MARGIN
      : maxX - clamped.x < SNAP_DISTANCE
        ? maxX
        : clamped.x
  const y =
    clamped.y - PILL_MARGIN < SNAP_DISTANCE
      ? PILL_MARGIN
      : maxY - clamped.y < SNAP_DISTANCE
        ? maxY
        : clamped.y
  return { x, y }
}

const spanCache = new WeakMap<ConsoleLine, ReturnType<typeof parseAnsi>>()

const ConsoleRow = memo(function ConsoleRow({
  line,
  level,
}: {
  line: ConsoleLine
  level: ConsoleLevel
}) {
  let spans = spanCache.get(line)
  if (!spans) {
    spans = parseAnsi(line.text)
    spanCache.set(line, spans)
  }
  // Leave colourised output alone; only tint plain lines by severity.
  const tone = line.text.includes('\u001b')
    ? undefined
    : level === 'error'
      ? 'text-danger/85'
      : level === 'warning'
        ? 'text-amber/85'
        : undefined
  return (
    <div className={tone}>
      {spans.length === 0
        ? '\u00a0'
        : spans.map((span, index) => (
            <span key={index} style={ansiSpanStyle(span)}>
              {span.text}
            </span>
          ))}
    </div>
  )
})

function emptyState(name: string): ConsoleState {
  return {
    lines: [],
    nextSeq: 0,
    running: true,
    exitCode: null,
    done: false,
    name,
  }
}

export function ProjectConsoleWindow() {
  const { t } = useTranslation('common')
  const [open, setOpen] = useState(false)
  const [minimized, setMinimized] = useState(false)
  const [fullscreen, setFullscreen] = useState(true)
  const [activeId, setActiveId] = useState<string | null>(null)
  const [states, setStates] = useState<Record<string, ConsoleState>>({})
  const [hiddenLevels, setHiddenLevels] = useState<Record<ConsoleLevel, boolean>>(
    { error: false, warning: false, info: false },
  )
  const [pillPos, setPillPos] = useState<Point | null>(() => {
    try {
      const raw = localStorage.getItem(PILL_STORAGE_KEY)
      if (!raw) return null
      const parsed = JSON.parse(raw) as Point
      return typeof parsed?.x === 'number' && typeof parsed?.y === 'number'
        ? parsed
        : null
    } catch {
      return null
    }
  })
  const [frame, setFrame] = useState<Size>({ w: 0, h: 0 })
  const [pillSize, setPillSize] = useState<Size>({ w: 0, h: 0 })

  const wrapRef = useRef<HTMLDivElement>(null)
  const pillRef = useRef<HTMLButtonElement>(null)
  const dragRef = useRef<{
    pointerId: number
    offsetX: number
    offsetY: number
    startX: number
    startY: number
    moved: boolean
  } | null>(null)
  const statesRef = useRef(states)
  statesRef.current = states
  const scrollRef = useRef<HTMLDivElement>(null)
  const pinnedRef = useRef(true)

  const openConsole = useCallback((id: string, name?: string) => {
    setStates((prev) =>
      prev[id] ? prev : { ...prev, [id]: emptyState(name ?? id) },
    )
    setActiveId(id)
    setOpen(true)
    setMinimized(false)
    pinnedRef.current = true
  }, [])

  useTauriEvent<LaunchedPayload>('project:launched', (payload) => {
    if (!payload.console) return
    setStates((prev) => ({
      ...prev,
      [payload.id]: emptyState(payload.name),
    }))
    setActiveId(payload.id)
    setOpen(true)
    // A fresh run is worth reading, so surface the window even from the pill.
    setMinimized(false)
    pinnedRef.current = true
  })

  useTauriEvent<{ id: string; code: number | null }>(
    'project:console-exit',
    ({ id, code }) => {
      setStates((prev) =>
        prev[id]
          ? { ...prev, [id]: { ...prev[id], running: false, exitCode: code } }
          : prev,
      )
    },
  )

  useEffect(() => {
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as
        | string
        | { id?: string; name?: string }
      const id = typeof detail === 'string' ? detail : detail?.id
      if (!id) return
      const name = typeof detail === 'string' ? undefined : detail?.name
      openConsole(id, name)
    }
    window.addEventListener('app:open-console', handler)
    return () => window.removeEventListener('app:open-console', handler)
  }, [openConsole])

  const activeState = activeId ? states[activeId] : undefined

  // The app frame is the drag boundary, and it resizes with the window.
  useEffect(() => {
    const wrap = wrapRef.current
    if (!wrap) return
    const measure = () => {
      const rect = wrap.getBoundingClientRect()
      setFrame({ w: rect.width, h: rect.height })
      const pill = pillRef.current
      if (pill) {
        setPillSize({ w: pill.offsetWidth, h: pill.offsetHeight })
      }
    }
    measure()
    const observer = new ResizeObserver(measure)
    observer.observe(wrap)
    return () => observer.disconnect()
  }, [])

  // The pill's width decides how far right it may sit, so measure it when shown.
  useEffect(() => {
    if (!open || !minimized) return
    const pill = pillRef.current
    if (!pill) return
    const measure = () =>
      setPillSize({ w: pill.offsetWidth, h: pill.offsetHeight })
    measure()
    const observer = new ResizeObserver(measure)
    observer.observe(pill)
    return () => observer.disconnect()
  }, [open, minimized])

  useEffect(() => {
    if (!open || !activeId) return
    let cancelled = false

    const tick = async () => {
      const current = statesRef.current[activeId]
      if (current?.done) return
      try {
        const snapshot = await api.getProjectConsole(
          activeId,
          current?.nextSeq ?? 0,
        )
        if (cancelled) return
        setStates((prev) => {
          const existing = prev[activeId]
          // A relaunch resets the backend buffer's sequence numbers.
          const restarted = existing
            ? snapshot.next_seq < existing.nextSeq
            : false
          const lines = restarted || !existing
            ? snapshot.lines
            : [...existing.lines, ...snapshot.lines]
          return {
            ...prev,
            [activeId]: {
              lines,
              nextSeq: snapshot.next_seq,
              running: snapshot.running,
              exitCode: snapshot.exit_code,
              done: !snapshot.running,
              name: existing?.name ?? activeId,
            },
          }
        })
      } catch {
        if (cancelled) return
        setStates((prev) =>
          prev[activeId]
            ? {
                ...prev,
                [activeId]: { ...prev[activeId], running: false, done: true },
              }
            : prev,
        )
      }
    }

    void tick()
    // Keep the pill's counts live, just at a lower rate than the open window.
    const interval = setInterval(
      () => void tick(),
      minimized ? POLL_MS_IDLE : POLL_MS,
    )
    return () => {
      cancelled = true
      clearInterval(interval)
    }
  }, [open, minimized, activeId])

  const entries = useMemo(() => {
    if (!activeState) return []
    const lines = activeState.lines.slice(-MAX_RENDERED_LINES)
    return annotateConsoleLines(lines)
  }, [activeState])

  const counts = useMemo(() => countConsoleLevels(entries), [entries])
  const visibleEntries = useMemo(
    () => entries.filter((entry) => !hiddenLevels[entry.level]),
    [entries, hiddenLevels],
  )
  const trimmed = (activeState?.lines.length ?? 0) - entries.length
  const filteredOut = entries.length - visibleEntries.length

  useEffect(() => {
    if (!open || minimized || !pinnedRef.current) return
    const el = scrollRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [open, minimized, activeId, visibleEntries.length])

  const handleScroll = () => {
    const el = scrollRef.current
    if (!el) return
    pinnedRef.current = el.scrollHeight - el.scrollTop - el.clientHeight < 24
  }

  const toggleLevel = (level: ConsoleLevel) => {
    setHiddenLevels((prev) => ({ ...prev, [level]: !prev[level] }))
    pinnedRef.current = true
  }

  const closeTab = (id: string) => {
    setStates((prev) => {
      const next = { ...prev }
      delete next[id]
      const remaining = Object.keys(next)
      setActiveId((current) => {
        if (current !== id) return current
        const fallback = remaining[remaining.length - 1] ?? null
        if (!fallback) setOpen(false)
        return fallback
      })
      return next
    })
  }

  const copyLog = () => {
    if (!activeState) return
    const text = activeState.lines.map((line) => stripAnsi(line.text)).join('\n')
    void navigator.clipboard?.writeText(text).catch(() => {})
  }

  const clearLog = () => {
    if (!activeId) return
    pinnedRef.current = true
    setStates((prev) =>
      prev[activeId]
        ? { ...prev, [activeId]: { ...prev[activeId], lines: [] } }
        : prev,
    )
    void api.clearProjectConsole(activeId).catch(() => {})
  }

  const stopProject = () => {
    if (!activeId) return
    void api.stopProject(activeId).catch((e) => alert(String(e)))
  }

  const persistPill = useCallback((pos: Point) => {
    try {
      localStorage.setItem(PILL_STORAGE_KEY, JSON.stringify(pos))
    } catch {
      // Position is cosmetic; a full or blocked storage just means no memory.
    }
  }, [])

  const pillDragStart = (e: React.PointerEvent<HTMLButtonElement>) => {
    const wrap = wrapRef.current
    const pill = pillRef.current
    if (!wrap || !pill) return
    const wrapRect = wrap.getBoundingClientRect()
    const pillRect = pill.getBoundingClientRect()
    // Switch from the CSS default corner to an explicit spot so it can move.
    setPillPos({ x: pillRect.left - wrapRect.left, y: pillRect.top - wrapRect.top })
    dragRef.current = {
      pointerId: e.pointerId,
      offsetX: e.clientX - pillRect.left,
      offsetY: e.clientY - pillRect.top,
      startX: e.clientX,
      startY: e.clientY,
      moved: false,
    }
    e.currentTarget.setPointerCapture(e.pointerId)
  }

  const pillDragMove = (e: React.PointerEvent<HTMLButtonElement>) => {
    const drag = dragRef.current
    const wrap = wrapRef.current
    if (!drag || !wrap || drag.pointerId !== e.pointerId) return
    if (
      !drag.moved &&
      Math.abs(e.clientX - drag.startX) + Math.abs(e.clientY - drag.startY) > 4
    ) {
      drag.moved = true
    }
    const wrapRect = wrap.getBoundingClientRect()
    setPillPos(
      clampPill(
        {
          x: e.clientX - wrapRect.left - drag.offsetX,
          y: e.clientY - wrapRect.top - drag.offsetY,
        },
        frame,
        pillSize,
      ),
    )
  }

  const pillDragEnd = (e: React.PointerEvent<HTMLButtonElement>) => {
    const drag = dragRef.current
    if (!drag) return
    dragRef.current = null
    if (e.currentTarget.hasPointerCapture(drag.pointerId)) {
      e.currentTarget.releasePointerCapture(drag.pointerId)
    }
    // A tap (not a drag) opens the window again.
    if (!drag.moved) {
      setMinimized(false)
      pinnedRef.current = true
      return
    }
    setPillPos((prev) => {
      if (!prev) return prev
      const snapped = snapPill(prev, frame, pillSize)
      persistPill(snapped)
      return snapped
    })
  }

  const tabs = useMemo(() => Object.keys(states), [states])

  const status = (() => {
    if (!activeState) return null
    if (activeState.running) {
      return { label: t('console_running'), tone: 'running' as const }
    }
    if (activeState.exitCode == null) {
      return { label: t('console_finished'), tone: 'neutral' as const }
    }
    return activeState.exitCode === 0
      ? { label: t('console_exit_ok'), tone: 'ok' as const }
      : {
          label: t('console_exit_code', { code: activeState.exitCode }),
          tone: 'error' as const,
        }
  })()

  const pillStyle = pillPos
    ? {
        left: clampPill(pillPos, frame, pillSize).x,
        top: clampPill(pillPos, frame, pillSize).y,
      }
    : undefined

  return (
    <div ref={wrapRef} className="absolute inset-0 z-50 pointer-events-none">
      <AnimatePresence>
        {open && !minimized && (
          <motion.section
            initial={{ opacity: 0, y: 12, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 12, scale: 0.98 }}
            transition={{ duration: 0.16, ease: 'easeOut' }}
            aria-label={t('console_title')}
            className={`pointer-events-auto absolute flex flex-col overflow-hidden rounded-xl border border-outline/60 bg-raised shadow-2xl shadow-black/40 ${
              fullscreen
                ? 'inset-3'
                : 'bottom-2 left-2 h-96 max-h-[calc(100%-1rem)] w-[42rem] max-w-[calc(100%-1rem)]'
            }`}
          >
            <header className="shrink-0 flex items-center gap-2 px-3 h-11 border-b border-outline/50 bg-overlay/60">
              <IconTerminal className="w-3.5 h-3.5 text-muted shrink-0" />
              <span className="text-xs font-semibold uppercase tracking-wider text-muted/80 shrink-0">
                {t('console_title')}
              </span>
              {status && (
                <span
                  className={`shrink-0 inline-flex items-center gap-1.5 px-2 py-0.5 rounded-tag text-[10px] font-semibold ${
                    status.tone === 'running'
                      ? 'bg-mint/10 text-mint'
                      : status.tone === 'ok'
                        ? 'bg-accent/10 text-accent-bright'
                        : status.tone === 'error'
                          ? 'bg-danger/10 text-danger'
                          : 'bg-overlay text-muted'
                  }`}
                >
                  {status.tone === 'running' && (
                    <span className="relative flex w-1.5 h-1.5">
                      <span className="absolute inline-flex h-full w-full rounded-full bg-mint opacity-60 animate-ping" />
                      <span className="relative inline-flex rounded-full w-1.5 h-1.5 bg-mint" />
                    </span>
                  )}
                  {status.label}
                </span>
              )}
              <div className="flex-1" />
              {activeState?.running && (
                <Tooltip content={t('stop')} side="bottom">
                  <button
                    type="button"
                    onClick={stopProject}
                    aria-label={t('stop')}
                    className="focus-ring cursor-pointer w-7 h-7 rounded-btn inline-flex items-center justify-center text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                  >
                    <IconSquare className="w-3 h-3" />
                  </button>
                </Tooltip>
              )}
              <Tooltip content={t('console_clear')} side="bottom">
                <button
                  type="button"
                  onClick={clearLog}
                  aria-label={t('console_clear')}
                  className="focus-ring cursor-pointer w-7 h-7 rounded-btn inline-flex items-center justify-center text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconTrash className="w-3 h-3" />
                </button>
              </Tooltip>
              <Tooltip content={t('console_copy')} side="bottom">
                <button
                  type="button"
                  onClick={copyLog}
                  aria-label={t('console_copy')}
                  className="focus-ring cursor-pointer w-7 h-7 rounded-btn inline-flex items-center justify-center text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconClone className="w-3 h-3" />
                </button>
              </Tooltip>
              <Tooltip
                content={fullscreen ? t('console_collapse') : t('console_expand')}
                side="bottom"
              >
                <button
                  type="button"
                  onClick={() => setFullscreen((v) => !v)}
                  aria-label={
                    fullscreen ? t('console_collapse') : t('console_expand')
                  }
                  className="focus-ring cursor-pointer w-7 h-7 rounded-btn inline-flex items-center justify-center text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  {fullscreen ? (
                    <IconWindowRestore className="w-3 h-3" />
                  ) : (
                    <IconWindowMaximize className="w-3 h-3" />
                  )}
                </button>
              </Tooltip>
              <Tooltip content={t('console_minimize')} side="bottom">
                <button
                  type="button"
                  onClick={() => setMinimized(true)}
                  aria-label={t('console_minimize')}
                  className="focus-ring cursor-pointer w-7 h-7 rounded-btn inline-flex items-center justify-center text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconMinus className="w-3 h-3" />
                </button>
              </Tooltip>
              <Tooltip content={t('close')} side="bottom">
                <button
                  type="button"
                  onClick={() => setOpen(false)}
                  aria-label={t('close')}
                  className="focus-ring cursor-pointer w-7 h-7 rounded-btn inline-flex items-center justify-center text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconX className="w-3.5 h-3.5" />
                </button>
              </Tooltip>
            </header>

            <div className="shrink-0 flex items-center gap-2 px-2 h-10 border-b border-outline/50 bg-overlay/30">
              {tabs.length > 0 && (
                <div className="flex items-center gap-1 min-w-0 overflow-x-auto">
                  {tabs.map((id) => (
                    <button
                      key={id}
                      type="button"
                      onClick={() => {
                        setActiveId(id)
                        pinnedRef.current = true
                      }}
                      className={`cursor-pointer shrink-0 inline-flex items-center gap-1.5 h-6 px-2 rounded-btn text-[11px] font-medium transition-colors ${
                        id === activeId
                          ? 'bg-accent/15 text-accent-bright'
                          : 'text-muted hover:text-ink hover:bg-raised'
                      }`}
                    >
                      <span className="max-w-32 truncate">
                        {states[id].name}
                      </span>
                      <span
                        role="button"
                        tabIndex={-1}
                        aria-label={`${t('close')} ${states[id].name}`}
                        onClick={(e) => {
                          e.stopPropagation()
                          closeTab(id)
                        }}
                        className="shrink-0 opacity-60 hover:opacity-100"
                      >
                        <IconX className="w-2.5 h-2.5" />
                      </span>
                    </button>
                  ))}
                </div>
              )}
              <div className="flex-1 min-w-2" />
              <div className="shrink-0 flex items-center gap-1">
                {CONSOLE_LEVELS.map((level) => {
                  const active = !hiddenLevels[level]
                  const label =
                    level === 'error'
                      ? t('console_filter_errors')
                      : level === 'warning'
                        ? t('console_filter_warnings')
                        : t('console_filter_info')
                  return (
                    <Tooltip key={level} content={label} side="bottom">
                      <button
                        type="button"
                        onClick={() => toggleLevel(level)}
                        aria-pressed={active}
                        aria-label={label}
                        className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 h-6 px-2 rounded-full border text-[10px] font-semibold transition-colors ${
                          active
                            ? LEVEL_PILL_ACTIVE[level]
                            : 'bg-transparent text-muted/45 border-line/50 hover:text-muted'
                        }`}
                      >
                        <span
                          aria-hidden="true"
                          className={`w-1.5 h-1.5 rounded-full bg-current ${
                            active ? '' : 'opacity-50'
                          }`}
                        />
                        {label}
                        <span
                          className={`tabular-nums font-mono ${
                            active ? 'opacity-80' : 'opacity-60'
                          }`}
                        >
                          {counts[level]}
                        </span>
                      </button>
                    </Tooltip>
                  )
                })}
              </div>
            </div>

            <div
              ref={scrollRef}
              onScroll={handleScroll}
              className="flex-1 min-h-0 overflow-y-auto bg-black/35 px-3 py-2 font-mono text-[11.5px] leading-[1.55] text-[#d7dae0]"
            >
              {trimmed > 0 && (
                <p className="pb-2 text-[10px] text-muted/60">
                  {t('console_trimmed', { count: trimmed })}
                </p>
              )}
              {visibleEntries.length === 0 ? (
                <p className="flex h-full items-center justify-center gap-2 text-xs text-muted/60">
                  {entries.length > 0
                    ? t('console_no_matches', { count: filteredOut })
                    : activeState?.running
                      ? t('console_waiting')
                      : t('console_empty')}
                </p>
              ) : (
                <div className="whitespace-pre-wrap break-words">
                  {visibleEntries.map((entry) => (
                    <ConsoleRow
                      key={entry.line.seq}
                      line={entry.line}
                      level={entry.level}
                    />
                  ))}
                </div>
              )}
            </div>

            {activeState &&
              !activeState.running &&
              activeState.exitCode != null &&
              activeState.exitCode !== 0 && (
                <footer className="shrink-0 flex items-center gap-2 px-3 h-8 border-t border-danger/30 bg-danger/10 text-[11px] text-danger">
                  <IconChevronDown className="w-3 h-3 rotate-180 shrink-0" />
                  <span className="truncate">
                    {t('console_crash_hint', { code: activeState.exitCode })}
                  </span>
                </footer>
              )}
          </motion.section>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {open && minimized && (
          <motion.button
            ref={pillRef}
            type="button"
            initial={{ opacity: 0, scale: 0.9, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 10 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            onPointerDown={pillDragStart}
            onPointerMove={pillDragMove}
            onPointerUp={pillDragEnd}
            onPointerCancel={pillDragEnd}
            style={{ ...pillStyle, touchAction: 'none' }}
            aria-label={t('console_pill_hint')}
            className={`pointer-events-auto absolute inline-flex items-center gap-2 h-9 max-w-[calc(100%-1.5rem)] px-2.5 rounded-full border border-outline/60 bg-raised shadow-2xl shadow-black/40 cursor-grab active:cursor-grabbing select-none ${
              pillStyle ? '' : 'bottom-3 right-3'
            }`}
          >
            <IconGrip className="w-2.5 h-3.5 text-muted/40 shrink-0" />
            <span className="relative flex w-1.5 h-1.5 shrink-0">
              {activeState?.running && (
                <span className="absolute inline-flex h-full w-full rounded-full bg-mint opacity-60 animate-ping" />
              )}
              <span
                className={`relative inline-flex rounded-full w-1.5 h-1.5 ${
                  activeState?.running
                    ? 'bg-mint'
                    : activeState?.exitCode
                      ? 'bg-danger'
                      : 'bg-muted/60'
                }`}
              />
            </span>
            <span className="truncate text-xs font-medium text-ink max-w-40">
              {activeState?.name ?? t('console_title')}
            </span>
            <span className="shrink-0 text-[10px] text-muted/70">
              {activeState?.running
                ? t('console_running')
                : activeState?.exitCode == null
                  ? t('console_finished')
                  : activeState.exitCode === 0
                    ? t('console_exit_ok')
                    : t('console_exit_code', { code: activeState.exitCode })}
            </span>
            {counts.error > 0 && (
              <span className="shrink-0 min-w-[18px] h-[18px] px-1 inline-flex items-center justify-center rounded-full bg-danger/20 text-danger text-[10px] font-bold tabular-nums">
                {counts.error}
              </span>
            )}
            {counts.error === 0 && counts.warning > 0 && (
              <span className="shrink-0 min-w-[18px] h-[18px] px-1 inline-flex items-center justify-center rounded-full bg-amber/20 text-amber text-[10px] font-bold tabular-nums">
                {counts.warning}
              </span>
            )}
            <IconWindowMaximize className="w-3 h-3 text-muted/50 shrink-0" />
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  )
}
