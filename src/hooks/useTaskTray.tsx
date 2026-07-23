import {
  createContext,
  createElement,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { listen } from '@tauri-apps/api/event'
import type { DownloadProgress } from '../types'

export interface Task {
  id: string
  type:
    | 'download-godot'
    | 'scan-projects'
    | 'scan-versions'
    | 'sync-templates'
    | 'clone-repo'
    | 'import-projects'
  label: string
  description?: string
  progress: { current: number; total: number } | null
  status: 'queued' | 'running' | 'paused' | 'completed' | 'error'
  errorMessage?: string
}

interface TaskTrayContextValue {
  tasks: Task[]
  activeCount: number
  registerTask: (task: Task) => void
  updateTask: (id: string, partial: Partial<Task>) => void
  unregisterTask: (id: string) => void
  clearCompleted: () => void
}

const TaskTrayContext = createContext<TaskTrayContextValue | null>(null)

export function TaskTrayProvider({ children }: { children: ReactNode }) {
  const [tasks, setTasks] = useState<Task[]>([])
  const timersRef = useRef<Map<string, ReturnType<typeof setTimeout>>>(
    new Map(),
  )

  const clearTimer = useCallback((id: string) => {
    const existing = timersRef.current.get(id)
    if (existing) {
      clearTimeout(existing)
      timersRef.current.delete(id)
    }
  }, [])

  const scheduleRemoval = useCallback(
    (id: string, delay = 4000) => {
      clearTimer(id)
      const timer = setTimeout(() => {
        setTasks((prev) => prev.filter((t) => t.id !== id))
        timersRef.current.delete(id)
      }, delay)
      timersRef.current.set(id, timer)
    },
    [clearTimer],
  )

  const registerTask = useCallback((task: Task) => {
    setTasks((prev) => {
      const exists = prev.find((t) => t.id === task.id)
      if (exists) {
        return prev.map((t) => (t.id === task.id ? task : t))
      }
      return [...prev, task]
    })
  }, [])

  const updateTask = useCallback(
    (id: string, partial: Partial<Task>) => {
      setTasks((prev) =>
        prev.map((t) => (t.id === id ? { ...t, ...partial } : t)),
      )
    },
    [],
  )

  const unregisterTask = useCallback(
    (id: string) => {
      clearTimer(id)
      setTasks((prev) => prev.filter((t) => t.id !== id))
    },
    [clearTimer],
  )

  // Listen to Tauri events for scan/download progress
  useEffect(() => {
    const unlistens: Promise<() => void>[] = []

    // Project scan progress — only show when actively scanning (current < total)
    // Watcher re-scans can fire instantly with (0,0) when nothing new found
    unlistens.push(
      listen<[number, number]>('project-scan-progress', (e) => {
        const [current, total] = e.payload
        if (current < total) {
          registerTask({
            id: 'scan-projects',
            type: 'scan-projects',
            label: 'Scanning projects',
            description: total > 0 ? `${current} / ${total}` : undefined,
            progress: { current, total },
            status: 'running',
          })
        } else if (total > 0) {
          // Only mark completed if there was actually something to scan
          updateTask('scan-projects', { status: 'completed', progress: { current, total } })
          scheduleRemoval('scan-projects')
        }
      }),
    )

    // Version scan progress — same logic
    unlistens.push(
      listen<[number, number]>('version-scan-progress', (e) => {
        const [current, total] = e.payload
        if (current < total) {
          registerTask({
            id: 'scan-versions',
            type: 'scan-versions',
            label: 'Scanning versions',
            description: total > 0 ? `${current} / ${total}` : undefined,
            progress: { current, total },
            status: 'running',
          })
        } else if (total > 0) {
          updateTask('scan-versions', { status: 'completed', progress: { current, total } })
          scheduleRemoval('scan-versions')
        }
      }),
    )

    // Godot download queued
    unlistens.push(
      listen<string>('godot-download-queued', (e) => {
        const key = e.payload
        registerTask({
          id: `download-${key}`,
          type: 'download-godot',
          label: `Downloading ${key}`,
          description: 'Queued…',
          progress: null,
          status: 'queued',
        })
      }),
    )

    // Godot download progress
    unlistens.push(
      listen<DownloadProgress>('godot-download-progress', (e) => {
        const { tag, downloaded, total } = e.payload
        const id = `download-${tag}`
        const pct =
          total > 0 ? Math.round((downloaded / total) * 100) : 0
        registerTask({
          id,
          type: 'download-godot',
          label: `Downloading ${tag}`,
          description:
            total > 0
              ? `${(downloaded / 1024 / 1024).toFixed(1)} / ${(total / 1024 / 1024).toFixed(1)} MB (${pct}%)`
              : `${(downloaded / 1024 / 1024).toFixed(1)} MB`,
          progress: total > 0 ? { current: downloaded, total } : null,
          status: 'running',
        })
      }),
    )

    // Godot download paused
    unlistens.push(
      listen<string>('godot-download-paused', (e) => {
        updateTask(`download-${e.payload}`, { status: 'paused' })
      }),
    )

    // Godot download canceled
    unlistens.push(
      listen<string>('godot-download-canceled', (e) => {
        unregisterTask(`download-${e.payload}`)
      }),
    )

    // Godot download error
    unlistens.push(
      listen<{ tag: string; message: string }>('godot-download-error', (e) => {
        updateTask(`download-${e.payload.tag}`, {
          status: 'error',
          errorMessage: e.payload.message,
        })
        scheduleRemoval(`download-${e.payload.tag}`, 6000)
      }),
    )

    // Godot download complete
    unlistens.push(
      listen<string>('godot-download-complete', (e) => {
        updateTask(`download-${e.payload}`, { status: 'completed' })
        scheduleRemoval(`download-${e.payload}`, 3000)
      }),
    )

    return () => {
      unlistens.forEach((p) => p.then((fn) => fn()))
    }
  }, [registerTask, updateTask, unregisterTask, scheduleRemoval])

  const clearCompleted = useCallback(() => {
    setTasks((prev) =>
      prev.filter(
        (t) =>
          t.status === 'queued' ||
          t.status === 'running' ||
          t.status === 'paused',
      ),
    )
    // Clear all associated timers
    timersRef.current.forEach((timer) => clearTimeout(timer))
    timersRef.current.clear()
  }, [])

  const activeCount = tasks.filter(
    (t) => t.status === 'queued' || t.status === 'running',
  ).length

  return createElement(
    TaskTrayContext.Provider,
    {
      value: {
        tasks,
        activeCount,
        registerTask,
        updateTask,
        unregisterTask,
        clearCompleted,
      },
    },
    children,
  )
}

export function useTaskTray() {
  const ctx = useContext(TaskTrayContext)
  if (!ctx)
    throw new Error('useTaskTray must be used within a <TaskTrayProvider>')
  return ctx
}
