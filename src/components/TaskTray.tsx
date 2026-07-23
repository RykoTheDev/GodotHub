import { useState, useRef, useEffect, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useTaskTray, type Task } from '../hooks/useTaskTray'
import { Tooltip } from './ui/Tooltip'
import {
  IconBell,
  IconDownload,
  IconSearch,
  IconCopy,
  IconGitBranch,
  IconFolderPlus,
  IconRefresh,
  IconPause,
  IconCheck,
  IconCircleX,
  IconCircleCheck,
  IconX,
} from './Icons'

function TaskIcon({ task }: { task: Task }) {
  const iconClass = 'w-4 h-4 shrink-0'
  switch (task.type) {
    case 'download-godot':
      return <IconDownload className={`${iconClass} text-amber`} />
    case 'scan-projects':
    case 'scan-versions':
      return task.status === 'running' ? (
        <IconSearch className={`${iconClass} text-accent-bright`} />
      ) : (
        <IconCheck className={`${iconClass} text-mint`} />
      )
    case 'sync-templates':
      return <IconCopy className={`${iconClass} text-accent-bright`} />
    case 'clone-repo':
      return <IconGitBranch className={`${iconClass} text-mint`} />
    case 'import-projects':
      return <IconFolderPlus className={`${iconClass} text-accent-bright`} />
    default:
      return <IconRefresh className={`${iconClass} text-muted`} />
  }
}

function StatusBadge({ status }: { status: Task['status'] }) {
  switch (status) {
    case 'queued':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-muted/10 text-muted/70 border border-line/50">
          Queued
        </span>
      )
    case 'running':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-accent/10 text-accent-bright border border-accent-dim/30 flex items-center gap-1">
          <IconRefresh className="w-2.5 h-2.5 animate-spin" />
          Active
        </span>
      )
    case 'paused':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-amber/10 text-amber border border-amber/30 flex items-center gap-1">
          <IconPause className="w-2.5 h-2.5" />
          Paused
        </span>
      )
    case 'completed':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-mint/10 text-mint border border-mint/30 flex items-center gap-1">
          <IconCircleCheck className="w-2.5 h-2.5" />
          Done
        </span>
      )
    case 'error':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-danger/10 text-danger border border-danger/30 flex items-center gap-1">
          <IconCircleX className="w-2.5 h-2.5" />
          Error
        </span>
      )
  }
}

function ProgressBar({ progress }: { progress: { current: number; total: number } | null }) {
  if (!progress || progress.total <= 0) return null
  const pct = Math.min((progress.current / progress.total) * 100, 100)
  return (
    <div className="h-1.5 w-full rounded-full bg-line/60 overflow-hidden mt-2">
      <motion.div
        className="h-full rounded-full bg-accent"
        initial={{ width: 0 }}
        animate={{ width: `${pct}%` }}
        transition={{ duration: 0.3, ease: 'easeOut' }}
      />
    </div>
  )
}

function TaskItem({ task }: { task: Task }) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: -8, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8, scale: 0.96 }}
      transition={{ duration: 0.2, ease: 'easeOut' }}
      className="flex items-start gap-3 px-4 py-3 rounded-xl hover:bg-raised/60 transition-colors"
    >
      <div className="w-8 h-8 rounded-lg bg-raised border border-line flex items-center justify-center shrink-0 mt-0.5">
        <TaskIcon task={task} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between gap-2">
          <span className="text-sm font-medium text-ink truncate">
            {task.label}
          </span>
          <StatusBadge status={task.status} />
        </div>
        {task.description && (
          <p className="text-[11px] text-muted mt-0.5 truncate">
            {task.description}
          </p>
        )}
        {task.errorMessage && (
          <p className="text-[11px] text-danger mt-0.5 truncate">
            {task.errorMessage}
          </p>
        )}
        <ProgressBar progress={task.progress} />
      </div>
    </motion.div>
  )
}

export function TaskTray() {
  const { tasks, activeCount, clearCompleted } = useTaskTray()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  // Auto-close when all tasks are gone
  useEffect(() => {
    if (open && tasks.length === 0) {
      const t = setTimeout(() => setOpen(false), 2000)
      return () => clearTimeout(t)
    }
  }, [tasks.length, open])

  const hasActivity = activeCount > 0
  const empty = tasks.length === 0

  const dismissibleCount = useMemo(
    () => tasks.filter((t) => t.status !== 'queued' && t.status !== 'running').length,
    [tasks],
  )

  // Build tooltip text: preview of active tasks
  const tooltipContent = useMemo(() => {
    if (activeCount === 0) return 'No active tasks'
    const labels = tasks
      .filter((t) => t.status === 'queued' || t.status === 'running')
      .slice(0, 3)
      .map((t) => t.label)
    if (labels.length === 0) return `${activeCount} active task${activeCount !== 1 ? 's' : ''}`
    const preview = labels.join(', ')
    const remaining = activeCount - labels.length
    if (remaining > 0) return `${preview} +${remaining} more`
    return preview
  }, [tasks, activeCount])

  const bellButton = (
    <motion.button
      onClick={() => setOpen((o) => !o)}
      aria-label="Task Tray"
      className="relative w-9 cursor-pointer flex items-center justify-center text-muted hover:text-ink transition-colors shrink-0"
      whileHover={{
        y: -2,
        scale: 1.1,
      }}
      transition={{
        type: 'spring',
        stiffness: 500,
        damping: 30,
      }}
    >
      <span className="relative">
        <IconBell className="w-4 h-4" />
        {hasActivity && (
          <motion.span
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            transition={{
              type: 'spring',
              stiffness: 500,
              damping: 25,
            }}
            className="absolute -top-1.5 -right-2 w-4 h-4 rounded-full bg-amber text-[9px] font-bold text-white flex items-center justify-center shadow-sm"
          >
            {activeCount > 9 ? '9+' : activeCount}
          </motion.span>
        )}
      </span>
    </motion.button>
  )

  return (
    <div ref={ref} className="relative flex items-stretch">
      <Tooltip content={tooltipContent} delay={200} className="flex items-stretch">
        {bellButton}
      </Tooltip>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -6, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -6, scale: 0.96 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            className="absolute top-full right-0 mt-2 w-80 max-h-96 overflow-y-auto rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-2 z-50 origin-top-right"
          >
            <div className="px-4 py-2.5 border-b border-line/50 mb-1">
              <h3 className="text-xs font-semibold text-muted uppercase tracking-wide">
                Tasks
              </h3>
              <p className="text-[10px] text-muted/50 mt-0.5">
                {hasActivity
                  ? `${activeCount} active, ${tasks.length - activeCount} recent`
                  : empty
                    ? 'No active tasks'
                    : `${tasks.length} recent task${tasks.length !== 1 ? 's' : ''}`}
              </p>
            </div>
            <div className="flex flex-col">
              <AnimatePresence mode="popLayout">
                {empty ? (
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="flex flex-col items-center gap-3 py-8 px-4 text-center"
                  >
                    <div className="w-10 h-10 rounded-xl bg-raised border border-line flex items-center justify-center">
                      <IconBell className="w-4 h-4 text-muted/50" />
                    </div>
                    <div>
                      <p className="text-xs text-muted font-medium">No tasks running</p>
                      <p className="text-[10px] text-muted/50 mt-2 leading-relaxed max-w-[220px]">
                        Background operations like downloading Godot versions, scanning
                        for projects &amp; versions, syncing templates, and cloning
                        repositories will appear here with live progress.
                      </p>
                    </div>
                  </motion.div>
                ) : (
                  tasks.map((task) => (
                    <TaskItem key={task.id} task={task} />
                  ))
                )}
              </AnimatePresence>
            </div>
            {!empty && (
              <div className="border-t border-line/50 mt-1 pt-1.5 px-1 flex items-center justify-between">
                <p className="text-[9px] text-muted/40">
                  Completed auto-dismiss
                </p>
                {dismissibleCount > 0 && (
                  <motion.button
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={clearCompleted}
                    className="focus-ring cursor-pointer flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-medium text-muted hover:text-ink hover:bg-raised transition-all"
                  >
                    <IconX className="w-3 h-3" />
                    Dismiss {dismissibleCount}
                  </motion.button>
                )}
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
