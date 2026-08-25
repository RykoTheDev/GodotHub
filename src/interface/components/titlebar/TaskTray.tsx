import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { useTaskTray, type Task } from '../../../hooks/useTaskTray'
import { api } from '../../../lib/api'
import {
  IconBell,
  IconCheck,
  IconChevronDown,
  IconChevronUp,
  IconCircleCheck,
  IconCircleX,
  IconCloudArrowDown,
  IconCopy,
  IconDownload,
  IconFolderPlus,
  IconGitBranch,
  IconPause,
  IconPlay,
  IconRefresh,
  IconSearch,
  IconStore,
  IconX,
} from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'

function TaskIcon({ task }: { task: Task }) {
  const iconClass = 'w-4 h-4 shrink-0'
  switch (task.type) {
    case 'download-godot':
      return <IconDownload className={`${iconClass} text-amber`} />
    case 'download-asset':
      return <IconStore className={`${iconClass} text-accent-bright`} />
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
    case 'import-versions':
      return <IconCloudArrowDown className={`${iconClass} text-accent-bright`} />
    default:
      return <IconRefresh className={`${iconClass} text-muted`} />
  }
}

function StatusBadge({ status }: { status: Task['status'] }) {
  const { t } = useTranslation('common')
  switch (status) {
    case 'queued':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-muted/10 text-muted/70 border border-line/50">
          {t('queued')}
        </span>
      )
    case 'running':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-accent/10 text-accent-bright border border-accent-dim/30 flex items-center gap-1">
          <IconRefresh className="w-2.5 h-2.5 animate-spin" />
          {t('active')}
        </span>
      )
    case 'paused':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-amber/10 text-amber border border-amber/30 flex items-center gap-1">
          <IconPause className="w-2.5 h-2.5" />
          {t('paused')}
        </span>
      )
    case 'completed':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-mint/10 text-mint border border-mint/30 flex items-center gap-1">
          <IconCircleCheck className="w-2.5 h-2.5" />
          {t('done')}
        </span>
      )
    case 'error':
      return (
        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-danger/10 text-danger border border-danger/30 flex items-center gap-1">
          <IconCircleX className="w-2.5 h-2.5" />
          {t('task_error_status')}
        </span>
      )
  }
}

function ProgressBar({
  progress,
}: {
  progress: { current: number; total: number } | null
}) {
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
  const { t } = useTranslation('common')
  const isGodotDownload = task.type === 'download-godot'
  const isQueuedGodotDownload = isGodotDownload && task.status === 'queued'
  const downloadKey = isGodotDownload
    ? task.id.replace(/^download-/, '')
    : null

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: -8, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8, scale: 0.96 }}
      transition={{ duration: 0.2, ease: 'easeOut' }}
      className="flex items-start gap-3 px-4 py-3 rounded-item hover:bg-raised/60 transition-colors"
    >
      <div className="w-8 h-8 rounded-btn bg-raised border border-outline/50 flex items-center justify-center shrink-0 mt-0.5">
        <TaskIcon task={task} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between gap-2">
          <span className="text-sm font-medium text-ink truncate">
            {task.label}
          </span>
          <div className="flex items-center gap-1.5 shrink-0">
            {downloadKey && (
              <span className="flex items-center gap-0.5">
                {isQueuedGodotDownload && (
                  <>
                    <button
                        type="button"
                        onClick={() =>
                          api.reorderDownloadQueue(downloadKey, -1).catch(() => {})
                        }
                        aria-label={t('download_queue_move_up')}
                        className="focus-ring cursor-pointer w-5 h-5 rounded-btn flex items-center justify-center text-muted/50 hover:text-ink hover:bg-raised transition-colors"
                      >
                        <IconChevronUp className="w-3 h-3" />
                      </button>
                    <button
                        type="button"
                        onClick={() =>
                          api.reorderDownloadQueue(downloadKey, 1).catch(() => {})
                        }
                        aria-label={t('download_queue_move_down')}
                        className="focus-ring cursor-pointer w-5 h-5 rounded-btn flex items-center justify-center text-muted/50 hover:text-ink hover:bg-raised transition-colors"
                      >
                        <IconChevronDown className="w-3 h-3" />
                      </button>
                  </>
                )}
                {task.status === 'running' && (
                    <button
                      type="button"
                      onClick={() =>
                        api.pauseDownload(downloadKey).catch(() => {})
                      }
                      aria-label={t('pause_download')}
                      className="focus-ring cursor-pointer w-5 h-5 rounded-btn flex items-center justify-center text-muted/50 hover:text-ink hover:bg-raised transition-colors"
                    >
                      <IconPause className="w-3 h-3" />
                    </button>
                )}
                {(task.status === 'paused' || task.status === 'queued') && (
                  <>
                    {task.status === 'paused' && (
                        <button
                          type="button"
                          onClick={() =>
                            api.resumeDownload(downloadKey).catch(() => {})
                          }
                          aria-label={t('resume_download')}
                          className="focus-ring cursor-pointer w-5 h-5 rounded-btn flex items-center justify-center text-muted/50 hover:text-mint hover:bg-mint/10 transition-colors"
                        >
                          <IconPlay className="w-3 h-3" />
                        </button>
                    )}
                    <button
                        type="button"
                        onClick={() =>
                          api.cancelDownload(downloadKey).catch(() => {})
                        }
                        aria-label={t('cancel_download')}
                        className="focus-ring cursor-pointer w-5 h-5 rounded-btn flex items-center justify-center text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors"
                      >
                        <IconX className="w-3 h-3" />
                      </button>
                  </>
                )}
              </span>
            )}
            <StatusBadge status={task.status} />
          </div>
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
  const { t } = useTranslation('common')
  const { tasks, activeCount, clearCompleted } = useTaskTray()
  const [open, setOpen] = useState(false)
  const [openUp, setOpenUp] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  const measure = useCallback(() => {
    const el = ref.current
    if (!el) return
    const r = el.getBoundingClientRect()
    const mh = menuRef.current?.offsetHeight ?? 320
    const spaceBelow = window.innerHeight - r.bottom
    setOpenUp(spaceBelow < mh && r.top > spaceBelow)
  }, [])

  useLayoutEffect(() => {
    if (open) measure()
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    window.addEventListener('scroll', measure, true)
    window.addEventListener('resize', measure)
    return () => {
      window.removeEventListener('scroll', measure, true)
      window.removeEventListener('resize', measure)
    }
  }, [open, measure])

  useEffect(() => {
    if (!open) return
    const onDown = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    window.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDown)
      window.removeEventListener('keydown', onKey)
    }
  }, [open])

  useEffect(() => {
    if (open && tasks.length === 0) {
      const timer = setTimeout(() => setOpen(false), 2000)
      return () => clearTimeout(timer)
    }
  }, [tasks.length, open])

  const hasActivity = activeCount > 0
  const empty = tasks.length === 0

  const dismissibleCount = useMemo(
    () =>
      tasks.filter((t) => t.status !== 'queued' && t.status !== 'running')
        .length,
    [tasks],
  )

  const noDrag = (e: React.MouseEvent) => e.stopPropagation()

  return (
    <div ref={ref} className="relative mt-1 flex items-stretch shrink-0">
        <Tooltip content={t('task_tray_aria')}>
        <motion.button
          type="button"
          onMouseDown={noDrag}
          onClick={() => setOpen((o) => !o)}
          aria-label={t('task_tray_aria')}
          aria-haspopup="menu"
          aria-expanded={open}
          whileHover={{ scale: 1.08 }}
          whileTap={{ scale: 0.9 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          className="focus-ring cursor-pointer relative w-9 h-8 flex items-center justify-center rounded-item text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
        >
          <span className="relative">
            <IconBell className="w-4 h-4" />
            {hasActivity && (
              <motion.span
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                exit={{ scale: 0 }}
                transition={{ type: 'spring', stiffness: 500, damping: 25 }}
                className="absolute -top-1.5 -right-2 w-4 h-4 rounded-full bg-amber text-[9px] font-bold text-white flex items-center justify-center shadow-sm"
              >
                {activeCount > 9 ? '9+' : activeCount}
              </motion.span>
            )}
          </span>
        </motion.button>
        </Tooltip>

      <AnimatePresence>
        {open && (
          <motion.div
            ref={menuRef}
            initial={{ opacity: 0, y: openUp ? 6 : -6, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: openUp ? 6 : -6, scale: 0.96 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            onMouseDown={noDrag}
            role="menu"
            className={`absolute z-50 w-80 max-h-96 overflow-y-auto rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-2 origin-top-right ${
              openUp ? 'bottom-full mb-2 origin-bottom' : 'top-full mt-2'
            } right-0`}
          >
            <div className="px-4 py-2.5 border-b border-outline/50 mb-1">
              <h3 className="text-xs font-semibold text-muted uppercase tracking-wide">
                {t('task_tray_title')}
              </h3>
              <p className="text-[10px] text-muted/50 mt-0.5">
                {hasActivity
                  ? t('task_tray_active_count', {
                      active: activeCount,
                      recent: tasks.length - activeCount,
                    })
                  : empty
                    ? t('task_tray_empty')
                    : tasks.length === 1
                      ? t('task_tray_only_recent', { count: 1 })
                      : t('task_tray_only_recent_plural', {
                          count: tasks.length,
                        })}
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
                    <div className="w-10 h-10 rounded-btn bg-raised border border-outline/50 flex items-center justify-center">
                      <IconBell className="w-4 h-4 text-muted/50" />
                    </div>
                    <div>
                      <p className="text-xs text-muted font-medium">
                        {t('no_tasks_running')}
                      </p>
                      <p className="text-[10px] text-muted/50 mt-2 leading-relaxed max-w-[220px]">
                        {t('no_tasks_desc')}
                      </p>
                    </div>
                  </motion.div>
                ) : (
                  tasks.map((task) => <TaskItem key={task.id} task={task} />)
                )}
              </AnimatePresence>
            </div>
            {!empty && (
              <div className="border-t border-outline/50 mt-1 pt-1.5 px-1 flex items-center justify-between">
                <p className="text-[9px] text-muted/40">
                  {t('task_tray_auto_dismiss')}
                </p>
                {dismissibleCount > 0 && (
                  <motion.button
                    type="button"
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.95 }}
                    onMouseDown={noDrag}
                    onClick={clearCompleted}
                    className="focus-ring cursor-pointer flex items-center gap-1 px-2.5 py-1 rounded-item text-[10px] font-medium text-muted hover:text-ink hover:bg-raised transition-all"
                  >
                    <IconX className="w-3 h-3" />
                    {t('task_tray_dismiss', { count: dismissibleCount })}
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
