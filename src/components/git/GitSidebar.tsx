import { useEffect, useState, useCallback, useRef } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import type {
  GitBranchInfo,
  GitChangedFile,
  GitLogEntry,
  GitStashEntry,
  GitStatus,
  Project,
} from '../../types'
import { api } from '../../lib/api'
import { DiffViewer } from './DiffViewer'
import { GitResultDialog, parseGitError } from './GitResultDialog'
import { Tooltip } from '../ui/Tooltip'
import {
  IconX,
  IconGitBranch,
  IconCloudArrowDown,
  IconRefresh,
  IconExternalLink,
  IconTerminal,
  IconTrash,
  IconArrowUpDown,
  IconHistory,
  IconCheck,
  IconFolderPlus,
  IconCheckCircle,
  IconAlertTriangle,
  IconInfo,
  IconBomb,
} from '../Icons'
import { ConfirmDialog } from '../modals/ConfirmDialog'

interface Props {
  project: Project
  gitStatus: GitStatus | null
  onClose: () => void
  onRefresh: () => void
}

interface Toast {
  id: number
  type: 'success' | 'error' | 'info'
  message: string
}

let toastId = 0

function truncateMessage(msg: string): string {
  const trimmed = msg.trim()
  if (!trimmed) return msg
  const firstLine = trimmed.split('\n')[0] ?? trimmed
  if (firstLine.length <= 120) return firstLine
  return firstLine.slice(0, 117) + '…'
}

function statusLabel(status: string): { short: string; color: string; label: string } {
  const s = status.trim()
  if (s === 'M' || s === 'M ') return { short: 'M', color: 'text-amber', label: 'Modified' }
  if (s === 'A' || s === 'A ') return { short: 'A', color: 'text-mint', label: 'Added' }
  if (s === 'D' || s === 'D ') return { short: 'D', color: 'text-danger', label: 'Deleted' }
  if (s === 'R' || s === 'R ') return { short: 'R', color: 'text-accent-bright', label: 'Renamed' }
  if (s === 'C' || s === 'C ') return { short: 'C', color: 'text-accent-bright', label: 'Copied' }
  if (s.includes('?')) return { short: '?', color: 'text-muted', label: 'Untracked' }
  if (s.includes('U')) return { short: 'U', color: 'text-danger', label: 'Unmerged' }
  return { short: s, color: 'text-muted', label: s }
}

function Checkbox({
  checked,
  onChange,
  className = '',
}: {
  checked: boolean
  onChange: () => void
  className?: string
}) {
  return (
    <label
      className={`git-checkbox relative inline-flex items-center justify-center w-4 h-4 shrink-0 cursor-pointer ${className}`}
      onClick={(e) => e.stopPropagation()}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={onChange}
        className="absolute inset-0 opacity-0 cursor-pointer"
      />
      <span
        className={`w-4 h-4 rounded border transition-all duration-150 flex items-center justify-center
          ${checked
            ? 'bg-accent border-accent-bright'
            : 'bg-base border-line hover:border-accent-dim'
          }`}
      >
        {checked && (
          <svg className="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 12 12" stroke="currentColor" strokeWidth={3}>
            <path d="M2 6l3 3 5-5" />
          </svg>
        )}
      </span>
    </label>
  )
}

export function GitSidebar({ project, gitStatus, onClose, onRefresh }: Props) {
  const [displayName, setDisplayName] = useState<string | null>(null)
  const [remoteUrl, setRemoteUrl] = useState<string | null>(null)
  const [logEntries, setLogEntries] = useState<GitLogEntry[]>([])
  const [logLoading, setLogLoading] = useState(true)

  const [branches, setBranches] = useState<GitBranchInfo[]>([])
  const [branchesLoading, setBranchesLoading] = useState(true)
  const [newBranchName, setNewBranchName] = useState('')
  const [showCreateBranch, setShowCreateBranch] = useState(false)

  const [changedFiles, setChangedFiles] = useState<GitChangedFile[]>([])
  const [changesLoading, setChangesLoading] = useState(true)

  const [stagedFiles, setStagedFiles] = useState<Set<string>>(new Set())
  const [commitMessage, setCommitMessage] = useState('')
  const [amendMode, setAmendMode] = useState(false)
  const [pushAfterCommit, setPushAfterCommit] = useState(false)

  const [stashes, setStashes] = useState<GitStashEntry[]>([])
  const [stashesLoading, setStashesLoading] = useState(true)

  const [busyAction, setBusyAction] = useState<string | null>(null)

  const [switchedTo, setSwitchedTo] = useState<string | null>(null)

  const [remoteInput, setRemoteInput] = useState('')
  const [showRemoteInput, setShowRemoteInput] = useState(false)

  const [diffFile, setDiffFile] = useState<string | null>(null)

  const [toasts, setToasts] = useState<Toast[]>([])

  const addToast = useCallback((type: Toast['type'], message: string) => {
    const id = ++toastId
    setToasts((prev) => [...prev, { id, type, message: truncateMessage(message) }])
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 5000)
  }, [])

  const [gitResult, setGitResult] = useState<{
    type: 'success' | 'error'
    title: string
    instructions: string
    rawError?: string
  } | null>(null)

  const showGitError = useCallback((message: string) => {
    const parsed = parseGitError(message)
    setGitResult({ type: 'error', ...parsed })
  }, [])

  const showGitSuccess = useCallback((title: string, instructions?: string) => {
    setGitResult({ type: 'success', title, instructions: instructions ?? '' })
  }, [])

  const [showDiscardConfirm, setShowDiscardConfirm] = useState(false)
  const [confirmBranchDelete, setConfirmBranchDelete] = useState<string | null>(null)
  const [showRemoveRemoteConfirm, setShowRemoveRemoteConfirm] = useState(false)
  const [showStashPushConfirm, setShowStashPushConfirm] = useState(false)
  const [showPushConfirm, setShowPushConfirm] = useState(false)
  const [showForcePushConfirm, setShowForcePushConfirm] = useState(false)

  interface UndoEntry {
    id: number
    label: string
    undo: () => Promise<void>
    redo?: () => Promise<void>
  }
  const [undoHistory, setUndoHistory] = useState<UndoEntry[]>([])
  const [redoHistory, setRedoHistory] = useState<UndoEntry[]>([])
  const nextUndoIdRef = useRef(0)

  const pushUndo = useCallback((label: string, undo: () => Promise<void>, redo?: () => Promise<void>) => {
    setUndoHistory((prev) => [{ id: nextUndoIdRef.current++, label, undo, redo }, ...prev])
    setRedoHistory([])
  }, [])

  const handleUndo = async (entry: UndoEntry) => {
    setBusyAction('undo')
    try {
      await entry.undo()
      setRedoHistory((prev) => [entry, ...prev])
      setUndoHistory((prev) => prev.filter((e) => e.id !== entry.id))
      await refreshAll()
      onRefresh()
      window.dispatchEvent(new CustomEvent('app:refresh-git-status'))
    } catch (e) {
      addToast('error', String(e))
    } finally {
      setBusyAction(null)
    }
  }

  const handleRedo = async (entry: UndoEntry) => {
    if (!entry.redo) return
    setBusyAction('redo')
    try {
      await entry.redo()
      setUndoHistory((prev) => [entry, ...prev])
      setRedoHistory((prev) => prev.filter((e) => e.id !== entry.id))
      await refreshAll()
      onRefresh()
      window.dispatchEvent(new CustomEvent('app:refresh-git-status'))
    } catch (e) {
      addToast('error', String(e))
    } finally {
      setBusyAction(null)
    }
  }

  const isRepo = gitStatus?.is_repo ?? false

  const refreshAll = useCallback(async () => {
    try {
      const [entries, branchList, files, stashList] = await Promise.all([
        api.gitLogEntries(project.path).catch(() => [] as GitLogEntry[]),
        api.gitListBranches(project.path).catch(() => [] as GitBranchInfo[]),
        api.gitChangedFiles(project.path).catch(() => [] as GitChangedFile[]),
        api.gitStashList(project.path).catch(() => [] as GitStashEntry[]),
      ])
      setLogEntries(entries)
      setBranches(branchList)
      setChangedFiles(files)
      setStashes(stashList)
      if (files.length === 0) setStagedFiles(new Set())
    } catch { /* fallback */ }
  }, [project.path])

  useEffect(() => {
    let cancelled = false
    api.getProjectName(project.path).then((name) => { if (!cancelled) setDisplayName(name) })
    return () => { cancelled = true }
  }, [project.path])

  useEffect(() => {
    let cancelled = false
    api.gitRemoteUrl(project.path).then((url) => { if (!cancelled) setRemoteUrl(url) })
      .catch(() => { if (!cancelled) setRemoteUrl(null) })
    return () => { cancelled = true }
  }, [project.path])

  useEffect(() => {
    if (!isRepo) {
      setLogLoading(false); setBranchesLoading(false); setChangesLoading(false); setStashesLoading(false)
      return
    }
    let cancelled = false
    setLogLoading(true); setBranchesLoading(true); setChangesLoading(true); setStashesLoading(true)
    Promise.all([
      api.gitLogEntries(project.path).then((e) => { if (!cancelled) { setLogEntries(e); setLogLoading(false) } }).catch(() => { if (!cancelled) setLogLoading(false) }),
      api.gitListBranches(project.path).then((b) => { if (!cancelled) { setBranches(b); setBranchesLoading(false) } }).catch(() => { if (!cancelled) setBranchesLoading(false) }),
      api.gitChangedFiles(project.path).then((f) => { if (!cancelled) { setChangedFiles(f); setChangesLoading(false) } }).catch(() => { if (!cancelled) setChangesLoading(false) }),
      api.gitStashList(project.path).then((s) => { if (!cancelled) { setStashes(s); setStashesLoading(false) } }).catch(() => { if (!cancelled) setStashesLoading(false) }),
    ])
    return () => { cancelled = true }
  }, [project.path, isRepo])

  const doAction = async (key: string, fn: () => Promise<unknown>): Promise<boolean> => {
    setBusyAction(key)
    try {
      await fn()
      await refreshAll()
      onRefresh()
      window.dispatchEvent(new CustomEvent('app:refresh-git-status'))
      return true
    } catch (e) {
      showGitError(String(e))
      return false
    } finally {
      setBusyAction(null)
    }
  }

  const handleSwitchBranch = async (name: string) => {
    const prevBranch = currentBranch?.name
    const ok = await doAction(`switch:${name}`, async () => {
      await api.gitSwitchBranch(project.path, name)
      setSwitchedTo(name)
      setTimeout(() => setSwitchedTo(null), 2500)
    })
    if (ok && prevBranch && prevBranch !== name) {
      pushUndo(
        `Switch to "${name}"`,
        async () => { await api.gitSwitchBranch(project.path, prevBranch) },
        async () => { await api.gitSwitchBranch(project.path, name) },
      )
    }
  }

  const handleCreateBranch = async () => {
    if (!newBranchName.trim()) return
    const branchName = newBranchName.trim()
    const ok = await doAction('create-branch', async () => {
      await api.gitCreateBranch(project.path, branchName)
      setNewBranchName(''); setShowCreateBranch(false)
    })
    if (ok) {
      pushUndo(
        `Create branch "${branchName}"`,
        async () => { await api.gitDeleteBranch(project.path, branchName) },
        async () => { await api.gitCreateBranch(project.path, branchName) },
      )
    }
  }

  const handleDeleteBranch = (name: string) => doAction(`delete:${name}`, () => api.gitDeleteBranch(project.path, name))
  const handleStashPush = () => doAction('stash-push', () => api.gitStashPush(project.path))
  const handleStashApply = (index: number) => doAction(`stash-apply:${index}`, () => api.gitStashApply(project.path, index))
  const handleStashDrop = (index: number) => doAction(`stash-drop:${index}`, () => api.gitStashDrop(project.path, index))
  const handleDiscardChanges = () =>
    doAction('discard', async () => {
      const stashResult = await api.gitStashPush(project.path)
      if (stashResult) {
        const match = stashResult.match(/stash@\{([^}]+)\}/)
        const stashLabel = match ? `stash@{${match[1]}}` : 'latest'
        addToast('info', `Changes saved to ${stashLabel}. Find and restore it from the Stashes section.`)
      }
      await api.gitDiscardChanges(project.path)
    })
  const handleInit = () => doAction('init', async () => { await api.gitInit(project.path) })

  const toggleStage = (filePath: string) => {
    setStagedFiles((prev) => {
      const next = new Set(prev)
      if (next.has(filePath)) next.delete(filePath)
      else next.add(filePath)
      return next
    })
  }

  const selectAllUnstaged = () => {
    setStagedFiles((prev) => {
      const next = new Set(prev)
      for (const f of unstagedFiles) {
        next.add(f.path)
      }
      return next
    })
  }

  const deselectAll = () => {
    setStagedFiles(new Set())
  }

  const handleStageFiles = async () => {
    if (stagedFiles.size === 0) return
    setBusyAction('stage')
    try {
      for (const f of stagedFiles) {
        await api.gitStageFile(project.path, f)
      }
      setStagedFiles(new Set())
      await refreshAll()
      addToast('success', `${stagedFiles.size} file(s) staged.`)
    } catch (e) {
      showGitError(String(e))
    } finally {
      setBusyAction(null)
    }
  }

  const handleCommit = async () => {
    if (!commitMessage.trim()) return
    const msg = commitMessage.trim()
    setBusyAction('commit')
    try {
      const filesToStage = pendingStageFiles.length > 0
        ? pendingStageFiles
        : unstagedFiles.filter((f) => !f.status.trim().includes('?'))
      if (filesToStage.length > 0) {
        for (const f of filesToStage) {
          await api.gitStageFile(project.path, f.path)
        }
      }

      const result = await api.gitCommit(project.path, msg, amendMode)
      showGitSuccess(amendMode ? 'Commit amended' : 'Committed', result || 'Changes committed successfully.')

      if (!amendMode) {
        pushUndo(
          `Commit "${msg.length > 30 ? msg.slice(0, 30) + '…' : msg}"`,
          async () => { await api.gitUndoCommit(project.path) },
          async () => {
            await api.gitStageFile(project.path, '.')
            await api.gitCommit(project.path, msg, false)
          },
        )
      }

      if (pushAfterCommit && remoteUrl) {
        try {
          const pushResult = await api.gitPush(project.path)
          if (pushResult) showGitSuccess('Pushed', pushResult)
        } catch (e) {
          showGitError(`Push failed: ${e}`)
        }
      }

      setCommitMessage('')
      setAmendMode(false)
      setPushAfterCommit(false)
      setStagedFiles(new Set())
      await refreshAll()
      onRefresh()
      window.dispatchEvent(new CustomEvent('app:refresh-git-status'))
    } catch (e) {
      showGitError(String(e))
    } finally {
      setBusyAction(null)
    }
  }

  const handleSetRemote = async () => {
    if (!remoteInput.trim()) return
    const newUrl = remoteInput.trim()
    const prevUrl = remoteUrl
    const ok = await doAction('set-remote', async () => {
      await api.gitSetRemote(project.path, newUrl)
      setRemoteUrl(newUrl)
      setRemoteInput('')
      setShowRemoteInput(false)
    })
    if (ok) {
      if (prevUrl) {
        pushUndo(
          `Set remote URL`,
          async () => { await api.gitSetRemote(project.path, prevUrl); setRemoteUrl(prevUrl) },
          async () => { await api.gitSetRemote(project.path, newUrl); setRemoteUrl(newUrl) },
        )
      } else {
        pushUndo(
          `Add remote URL`,
          async () => { await api.gitRemoveRemote(project.path); setRemoteUrl(null) },
          async () => { await api.gitSetRemote(project.path, newUrl); setRemoteUrl(newUrl) },
        )
      }
    }
  }

  const handleRemoveRemote = async () => {
    const removedUrl = remoteUrl
    const ok = await doAction('remove-remote', async () => {
      await api.gitRemoveRemote(project.path)
      setRemoteUrl(null)
    })
    if (ok && removedUrl) {
      pushUndo(
        `Remove remote`,
        async () => { await api.gitSetRemote(project.path, removedUrl); setRemoteUrl(removedUrl) },
        async () => { await api.gitRemoveRemote(project.path); setRemoteUrl(null) },
      )
    }
  }

  const handlePushAction = () => {
    if (changedFiles.length > 0) {
      setShowPushConfirm(true)
    } else {
      executePush(false)
    }
  }

  const executePush = async (force: boolean) => {
    await doAction(force ? 'force-push' : 'push', async () => {
      try {
        const r = force ? await api.gitPushForce(project.path) : await api.gitPush(project.path)
        if (r) showGitSuccess(force ? 'Force push succeeded' : 'Pushed', r)
      } catch (e: unknown) {
        const errStr = String(e)
        if (!force && (errStr.toLowerCase().includes('non-fast-forward') || errStr.toLowerCase().includes('[rejected]') || errStr.toLowerCase().includes('failed to push'))) {
          addToast('info', 'Push rejected, pulling latest changes first, then retrying…')
          try {
            await api.gitPull(project.path)
            const retry = await api.gitPush(project.path)
            showGitSuccess('Push succeeded after pull.', retry || 'Changes pushed successfully.')
            return
          } catch (pullErr) {
            showGitError(`Pull then push failed: ${pullErr}`)
            throw pullErr
          }
        }
        throw e
      }
    })
  }

  const handleForcePush = () => setShowForcePushConfirm(true)

  const currentBranch = branches.find((b) => b.is_current)

  const isStaged = (f: GitChangedFile) => {
    const s = f.status.trim()
    return s.length === 2 && s[0] !== ' ' && s[0] !== '?' && s[1] === ' '
  }
  const gitStagedFiles = changedFiles.filter((f) => isStaged(f))
  const unstagedFiles = changedFiles.filter((f) => !isStaged(f) && !stagedFiles.has(f.path))
  const pendingStageFiles = changedFiles.filter((f) => stagedFiles.has(f.path))

  return (
    <div className="w-[380px] h-full flex flex-col overflow-hidden relative">
      {/* Header */}
      <div className="flex items-center justify-between px-5 py-4 border-b border-line shrink-0">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <IconGitBranch className="w-4 h-4 text-accent-bright shrink-0" />
            <h3 className="font-display font-semibold truncate">{displayName ?? project.name}</h3>
            <Tooltip content="This feature is in beta, some operations may not work as expected. Click to see changelog." side="bottom">
              <button
                onClick={() => window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 4 }))}
                className="text-[9px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-md bg-amber/15 text-amber border border-amber/30 hover:bg-amber/25 hover:border-amber/50 cursor-pointer shrink-0 transition-colors"
              >
                Beta
              </button>
            </Tooltip>
          </div>
          {isRepo && currentBranch && (
            <p className="text-[11px] font-mono text-muted mt-0.5 truncate">
              {currentBranch.name}
              {changedFiles.length > 0 && <span className="ml-1.5 text-amber">· {changedFiles.length} uncommitted</span>}
            </p>
          )}
        </div>
        <button onClick={onClose} aria-label="Close sidebar" className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors shrink-0">
          <IconX className="w-4 h-4" />
        </button>
      </div>

      {!isRepo ? (
        <div className="flex-1 flex flex-col items-center justify-center gap-4 p-8 text-center">
          <IconGitBranch className="w-10 h-10 text-muted/40" />
          <p className="text-sm text-muted">This project is not a git repository.</p>
          <button disabled={busyAction === 'init'} onClick={handleInit}
            className="focus-ring cursor-pointer flex items-center gap-2 px-5 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-xs font-medium text-white transition-colors">
            <IconFolderPlus className="w-3.5 h-3.5" />
            {busyAction === 'init' ? 'Initializing…' : 'Initialize Git Repo'}
          </button>
        </div>
      ) : (
        <>
          {/* Action buttons */}
          <div className="flex items-center gap-2 px-5 py-3 border-b border-line shrink-0 flex-wrap">
            <button disabled={busyAction !== null}
              onClick={() => doAction('pull', async () => {
                const r = await api.gitPull(project.path)
                if (r) {
                  pushUndo(
                    `Pull`,
                    async () => { await api.gitUndoPull(project.path) },
                    async () => { const r2 = await api.gitPull(project.path); if (r2) addToast('info', r2) },
                  )
                  showGitSuccess('Pull complete', r)
                }
              })}
              className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-[11px] font-medium text-white transition-colors">
              <IconCloudArrowDown className="w-3 h-3" />{busyAction === 'pull' ? '…' : 'Pull'}
            </button>
            <button onClick={handlePushAction} disabled={busyAction !== null}
              className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-[11px] font-medium text-white transition-colors">
              <IconArrowUpDown className="w-3 h-3" />{busyAction === 'push' ? '…' : 'Push'}
            </button>
            <button disabled={busyAction !== null}
              onClick={handleForcePush}
              className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-danger/40 text-danger hover:bg-danger/10 hover:border-danger disabled:opacity-50 disabled:cursor-not-allowed text-[11px] font-medium transition-colors">
              <IconBomb className="w-3 h-3" />{busyAction === 'force-push' ? '…' : 'Force'}
            </button>
            <button disabled={busyAction !== null}
              onClick={() => doAction('fetch', () => api.gitFetch(project.path))}
              className="focus-ring cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-line text-muted hover:text-ink hover:border-accent-dim disabled:opacity-50 disabled:cursor-not-allowed text-[11px] font-medium transition-colors">
              <IconRefresh className={`w-3 h-3 ${busyAction === 'fetch' ? 'animate-spin' : ''}`} />{busyAction === 'fetch' ? '…' : 'Fetch'}
            </button>
            <button onClick={() => api.openTerminal(project.path)} title="Open in terminal"
              className="focus-ring cursor-pointer px-2 py-0.5 rounded-lg border border-line text-muted hover:text-ink hover:border-accent-dim transition-colors">
              <IconTerminal className="w-3 h-3" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto">
            {/* Remote Config */}
            <div className="px-5 pt-4 pb-2 border-b border-line">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Remote</h4>
                <button onClick={() => setShowRemoteInput((v) => !v)}
                  className="focus-ring cursor-pointer text-[10px] text-accent-bright hover:underline transition-colors">
                  {remoteUrl ? 'Change' : '+ Add'}
                </button>
              </div>
              {showRemoteInput ? (
                <div className="flex items-center gap-1.5 mb-1">
                  <input type="text" value={remoteInput} onChange={(e) => setRemoteInput(e.target.value)}
                    placeholder={remoteUrl ? 'New remote URL' : 'https://github.com/user/repo.git'}
                    onKeyDown={(e) => { if (e.key === 'Enter') handleSetRemote(); if (e.key === 'Escape') setShowRemoteInput(false) }}
                    className="flex-1 focus-ring bg-base border border-line rounded-md px-2.5 py-1.5 text-xs text-ink placeholder:text-muted transition-colors focus:border-accent-dim outline-none" autoFocus />
                  <button onClick={handleSetRemote} disabled={busyAction !== null || !remoteInput.trim()}
                    className="focus-ring cursor-pointer p-1.5 rounded-md bg-accent hover:bg-accent-bright disabled:opacity-40 disabled:cursor-not-allowed text-white transition-colors">
                    <IconCheck className="w-3 h-3" />
                  </button>
                </div>
              ) : remoteUrl ? (
                <div className="flex items-center gap-1.5">
                  <span className="flex-1 text-[11px] font-mono text-muted truncate" title={remoteUrl}>{remoteUrl}</span>
                  <button onClick={() => setShowRemoveRemoteConfirm(true)} disabled={busyAction !== null} title="Remove remote"
                    className="focus-ring cursor-pointer p-1 rounded text-muted hover:text-danger transition-colors">
                    <IconTrash className="w-3 h-3" />
                  </button>
                </div>
              ) : (
                <p className="text-[11px] text-muted/60 py-1">No remote configured.</p>
              )}
            </div>

            {/* Branches */}
            <div className="px-5 pt-4 pb-2 border-b border-line">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Branches</h4>
                <button onClick={() => setShowCreateBranch((v) => !v)}
                  className="focus-ring cursor-pointer text-[10px] text-accent-bright hover:underline transition-colors">+ New</button>
              </div>
              {showCreateBranch && (
                <div className="flex items-center gap-1.5 mb-2">
                  <input type="text" value={newBranchName} onChange={(e) => setNewBranchName(e.target.value)}
                    placeholder="Branch name"
                    onKeyDown={(e) => { if (e.key === 'Enter') handleCreateBranch(); if (e.key === 'Escape') setShowCreateBranch(false) }}
                    className="flex-1 focus-ring bg-base border border-line rounded-md px-2.5 py-1.5 text-xs text-ink placeholder:text-muted transition-colors focus:border-accent-dim outline-none" autoFocus />
                  <button onClick={handleCreateBranch} disabled={busyAction !== null || !newBranchName.trim()}
                    className="focus-ring cursor-pointer p-1.5 rounded-md bg-accent hover:bg-accent-bright disabled:opacity-40 disabled:cursor-not-allowed text-white transition-colors">
                    <IconCheck className="w-3 h-3" />
                  </button>
                </div>
              )}
              {branchesLoading ? (
                <div className="flex items-center gap-2 py-2"><IconRefresh className="w-3 h-3 animate-spin text-muted" /><span className="text-[11px] text-muted">Loading branches…</span></div>
              ) : branches.length === 0 ? (
                <p className="text-[11px] text-muted/60 py-2">No branches found.</p>
              ) : (
                <div className="flex flex-col gap-0.5 max-h-[150px] overflow-y-auto">
                  {branches.map((b) => (
                    <div key={b.name}
                      className={`group flex items-center gap-2 px-2.5 py-1.5 rounded-md transition-colors ${b.is_current ? 'bg-accent/10 text-ink' : 'hover:bg-raised text-muted'}`}>
                      <IconGitBranch className={`w-3 h-3 shrink-0 ${b.is_current ? 'text-accent-bright' : ''}`} />
                      <span className={`text-xs font-mono truncate flex-1 ${b.is_current ? 'font-medium' : ''}`}>{b.name}</span>
                      {b.is_current ? (
                        <span className="text-[9px] font-semibold uppercase transition-all duration-300"
                          style={{
                            color: switchedTo ? 'var(--color-mint, #34d399)' : 'var(--color-accent-bright)',
                          }}
                        >
                          {switchedTo === b.name ? 'Switched' : 'Active'}
                        </span>
                      ) : (
                        <div className="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button onClick={() => handleSwitchBranch(b.name)} disabled={busyAction !== null}
                            className="focus-ring cursor-pointer p-1 rounded text-muted hover:text-accent-bright hover:bg-raised disabled:opacity-40 transition-colors" title={`Switch to ${b.name}`}>
                            <IconCheck className="w-3 h-3" />
                          </button>
                          {b.name !== 'main' && b.name !== 'master' && (
                            <button onClick={() => setConfirmBranchDelete(b.name)} disabled={busyAction !== null}
                              className="focus-ring cursor-pointer p-1 rounded text-muted hover:text-danger hover:bg-raised disabled:opacity-40 transition-colors" title={`Delete ${b.name}`}>
                              <IconTrash className="w-3 h-3" />
                            </button>
                          )}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Changes + Staging + Commit */}
            <div className="px-5 pt-4 pb-2 border-b border-line">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Changes</h4>
                {unstagedFiles.length > 0 && (
                  <div className="flex items-center gap-2">
                    {/* Select / Deselect All */}
                    {stagedFiles.size < unstagedFiles.length ? (
                      <button onClick={selectAllUnstaged}
                        className="focus-ring cursor-pointer text-[10px] text-accent-bright hover:underline transition-colors">Select all</button>
                    ) : (
                      <button onClick={deselectAll}
                        className="focus-ring cursor-pointer text-[10px] text-muted hover:text-ink hover:underline transition-colors">Deselect all</button>
                    )}
                    <span className="text-muted/30">·</span>
                    <button onClick={() => setShowDiscardConfirm(true)} disabled={busyAction !== null}
                      className="focus-ring cursor-pointer text-[10px] text-danger hover:underline disabled:opacity-40 disabled:cursor-not-allowed transition-colors">Discard all</button>
                    {stagedFiles.size > 0 && (
                      <button onClick={handleStageFiles} disabled={busyAction !== null}
                        className="focus-ring cursor-pointer text-[10px] text-mint hover:underline disabled:opacity-40 disabled:cursor-not-allowed transition-colors">Stage ({stagedFiles.size})</button>
                    )}
                  </div>
                )}
              </div>

              {changesLoading ? (
                <div className="flex items-center gap-2 py-2"><IconRefresh className="w-3 h-3 animate-spin text-muted" /><span className="text-[11px] text-muted">Checking changes…</span></div>
              ) : changedFiles.length === 0 ? (
                <p className="text-[11px] text-muted/60 py-2">Working tree clean.</p>
              ) : (
                <div className="flex flex-col gap-0.5 max-h-[220px] overflow-y-auto">
                  {/* Staged section badge */}
                  {gitStagedFiles.length > 0 && (
                    <>
                      <div className="flex items-center gap-1.5 px-1 py-1 mt-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-mint shrink-0" />
                        <span className="text-[9px] font-semibold uppercase text-mint tracking-wider">Staged ({gitStagedFiles.length})</span>
                      </div>
                      {gitStagedFiles.map((f, i) => {
                        const info = statusLabel(f.status)
                        return (
                          <div key={`git-staged-${f.path}-${i}`}
                            className="flex items-center gap-2 px-2.5 py-1.5 rounded-md bg-mint/5 hover:bg-mint/10 transition-colors">
                            <span className="w-4 h-4 shrink-0" /> {/* Spacer for alignment */}
                            <span className={`font-mono text-[10px] font-bold w-4 shrink-0 ${info.color}`}>{info.short}</span>
                            <button onClick={() => setDiffFile(f.path)}
                              className="flex-1 text-left text-[11px] font-mono text-muted truncate hover:text-accent-bright transition-colors cursor-pointer">{f.path}</button>
                          </div>
                        )
                      })}
                    </>
                  )}

                  {/* Pending stage (selected via checkbox) */}
                  {pendingStageFiles.length > 0 && (
                    <>
                      <div className="flex items-center gap-1.5 px-1 py-1 mt-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-accent-bright shrink-0" />
                        <span className="text-[9px] font-semibold uppercase text-accent-bright tracking-wider">Pending stage ({pendingStageFiles.length})</span>
                      </div>
                      {pendingStageFiles.map((f, i) => {
                        const info = statusLabel(f.status)
                        return (
                          <div key={`staged-${f.path}-${i}`}
                            className="flex items-center gap-2 px-2.5 py-1.5 rounded-md bg-accent/5 hover:bg-accent/10 transition-colors">
                            <Checkbox checked={true} onChange={() => toggleStage(f.path)} />
                            <span className={`font-mono text-[10px] font-bold w-4 shrink-0 ${info.color}`}>{info.short}</span>
                            <button onClick={() => setDiffFile(f.path)}
                              className="flex-1 text-left text-[11px] font-mono text-muted truncate hover:text-accent-bright transition-colors cursor-pointer">{f.path}</button>
                          </div>
                        )
                      })}
                    </>
                  )}

                  {/* Unstaged / untracked files */}
                  {unstagedFiles.length > 0 && (
                    <>
                      <div className="flex items-center justify-between gap-1.5 px-1 py-1 mt-1">
                        <div className="flex items-center gap-1.5">
                          <span className="w-1.5 h-1.5 rounded-full bg-amber shrink-0" />
                          <span className="text-[9px] font-semibold uppercase text-amber tracking-wider">
                            {unstagedFiles.length === changedFiles.length - gitStagedFiles.length - pendingStageFiles.length ? 'Unstaged' : `Unstaged (${unstagedFiles.length})`}
                          </span>
                        </div>
                      </div>
                      {unstagedFiles.map((f, i) => {
                        const info = statusLabel(f.status)
                        const checked = stagedFiles.has(f.path)
                        return (
                          <div key={`unstaged-${f.path}-${i}`}
                            className="flex items-center gap-2 px-2.5 py-1.5 rounded-md hover:bg-raised transition-colors">
                            <Checkbox checked={checked} onChange={() => toggleStage(f.path)} />
                            <span className={`font-mono text-[10px] font-bold w-4 shrink-0 ${info.color}`}>{info.short}</span>
                            <button onClick={() => setDiffFile(f.path)}
                              className="flex-1 text-left text-[11px] font-mono text-muted truncate hover:text-accent-bright transition-colors cursor-pointer">{f.path}</button>
                          </div>
                        )
                      })}
                    </>
                  )}
                </div>
              )}

              {/* Commit composer */}
              {changedFiles.length > 0 && (
                <div className="mt-3 flex flex-col gap-2 pb-1">
                  <textarea
                    value={commitMessage}
                    onChange={(e) => setCommitMessage(e.target.value)}
                    placeholder="Commit message…"
                    rows={2}
                    onKeyDown={(e) => { if (e.key === 'Enter' && (e.ctrlKey || e.metaKey) && commitMessage.trim()) handleCommit() }}
                    className="focus-ring w-full bg-base border border-line rounded-md px-3 py-2 text-xs text-ink placeholder:text-muted transition-colors focus:border-accent-dim outline-none resize-none"
                  />
                  <div className="flex items-center gap-3">
                    <label className="flex items-center gap-1.5 cursor-pointer select-none" onClick={() => setAmendMode((v) => !v)}>
                      <Checkbox checked={amendMode} onChange={() => setAmendMode((v) => !v)} />
                      <span className="text-[10px] text-muted hover:text-ink transition-colors">Amend</span>
                    </label>
                    {remoteUrl && (
                      <label className="flex items-center gap-1.5 cursor-pointer select-none" onClick={() => setPushAfterCommit((v) => !v)}>
                        <Checkbox checked={pushAfterCommit} onChange={() => setPushAfterCommit((v) => !v)} />
                        <span className="text-[10px] text-muted hover:text-ink transition-colors">Push after</span>
                      </label>
                    )}
                    <div className="flex-1" />
                    <span className="text-[10px] text-muted/60">Ctrl+Enter</span>
                    <button
                      disabled={busyAction !== null || !commitMessage.trim() || changedFiles.length === 0}
                      onClick={handleCommit}
                      className="focus-ring cursor-pointer flex items-center gap-1.5 px-4 py-1.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-40 disabled:cursor-not-allowed text-xs font-medium text-white transition-colors"
                    >
                      <IconCheck className="w-3 h-3" />
                      {busyAction === 'commit'
                        ? (pushAfterCommit ? 'Comm+Pushing…' : 'Committing…')
                        : (amendMode ? 'Amend' : 'Commit')}
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Undo / Redo */}
            {(undoHistory.length > 0 || redoHistory.length > 0) && (
              <div className="px-5 pt-4 pb-3 border-b border-line">
                <div className="flex items-center justify-between mb-2">
                  <h4 className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Actions</h4>
                </div>
                <div className="flex flex-col gap-0.5">
                  {redoHistory.slice(0, 3).map((entry) => (
                    <button key={`redo-${entry.id}`}
                      onClick={() => handleRedo(entry)}
                      disabled={busyAction !== null}
                      className="flex items-center gap-2 px-2.5 py-1.5 rounded-md opacity-40 hover:opacity-100 hover:bg-raised transition-all disabled:opacity-20 disabled:cursor-not-allowed w-full text-left cursor-pointer">
                      <IconHistory className="w-3 h-3 text-muted shrink-0" />
                      <span className="text-[11px] text-muted truncate flex-1">Redo {entry.label}</span>
                    </button>
                  ))}
                  {undoHistory.slice(0, 5).map((entry) => (
                    <button key={`undo-${entry.id}`}
                      onClick={() => handleUndo(entry)}
                      disabled={busyAction !== null}
                      className="flex items-center gap-2 px-2.5 py-1.5 rounded-md hover:bg-raised transition-all disabled:opacity-40 disabled:cursor-not-allowed w-full text-left cursor-pointer group">
                      <IconHistory className="w-3 h-3 text-accent-bright shrink-0" />
                      <span className="text-[11px] text-muted truncate flex-1 group-hover:text-ink transition-colors">{entry.label}</span>
                      <span className="text-[9px] text-accent-bright font-semibold uppercase shrink-0">Undo</span>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Stashes */}
            <div className="px-5 pt-4 pb-2 border-b border-line">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Stashes</h4>
              </div>
              {stashesLoading ? (
                <div className="flex items-center gap-2 py-2"><IconRefresh className="w-3 h-3 animate-spin text-muted" /><span className="text-[11px] text-muted">Loading stashes…</span></div>
              ) : stashes.length === 0 ? (
                <p className="text-[11px] text-muted/60 py-2">No stashes.</p>
              ) : (
                <div className="flex flex-col gap-0.5 max-h-[120px] overflow-y-auto">
                  {stashes.map((s) => (
                    <div key={s.index} className="group flex items-center gap-2 px-2.5 py-1.5 rounded-md hover:bg-raised transition-colors">
                      <IconHistory className="w-3 h-3 text-muted shrink-0" />
                      <span className="text-[11px] font-mono text-muted truncate flex-1">{s.message}</span>
                      <div className="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => handleStashApply(s.index)} disabled={busyAction !== null}
                          className="focus-ring cursor-pointer p-1 rounded text-muted hover:text-accent-bright transition-colors" title="Apply stash"><IconCheck className="w-3 h-3" /></button>
                        <button onClick={() => handleStashDrop(s.index)} disabled={busyAction !== null}
                          className="focus-ring cursor-pointer p-1 rounded text-muted hover:text-danger transition-colors" title="Drop stash"><IconTrash className="w-3 h-3" /></button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Commits */}
            <div className="px-5 pt-4 pb-5">
              <h4 className="text-[10px] font-semibold uppercase tracking-wider text-muted/60 mb-3">Recent Commits</h4>
              {logLoading ? (
                <div className="flex items-center justify-center py-6"><IconRefresh className="w-4 h-4 animate-spin text-muted" /></div>
              ) : logEntries.length === 0 ? (
                <div className="border border-dashed border-line rounded-xl py-6 text-center"><p className="text-xs text-muted">No commits found.</p></div>
              ) : (
                <div className="flex flex-col gap-1.5">
                  {logEntries.map((entry, i) => (
                    <div key={`${entry.hash}-${i}`}
                      onClick={() => { if (remoteUrl) { const u = `${remoteUrl.replace(/\/+$/, '')}/commit/${entry.hash}`; window.open(u, '_blank') } }}
                      className={`group flex items-start gap-3 px-3 py-2 rounded-lg transition-colors ${remoteUrl ? 'cursor-pointer hover:bg-raised' : 'cursor-default'}`}>
                      <div className="flex flex-col items-center gap-1 shrink-0 pt-1">
                        <div className="w-1.5 h-1.5 rounded-full bg-accent/60 ring-2 ring-accent/10 shrink-0" />
                        {i < logEntries.length - 1 && <div className="w-px flex-1 bg-line min-h-[14px]" />}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-1.5">
                          <p className="text-[11px] font-mono text-accent-bright font-medium truncate">{entry.hash}</p>
                          {remoteUrl && <IconExternalLink className="w-2.5 h-2.5 text-muted/40 opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />}
                        </div>
                        <p className="text-xs text-ink leading-snug mt-0.5 line-clamp-2">{entry.message}</p>
                        <p className="text-[10px] text-muted mt-0.5">{entry.author} · {entry.date}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </>
      )}

      {/* Toast notifications */}
      <div className="absolute bottom-3 left-3 right-3 z-50 flex flex-col gap-2 pointer-events-none">
        <AnimatePresence>
          {toasts.map((toast) => (
            <motion.div
              key={toast.id}
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 10, scale: 0.95 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
              className={`pointer-events-auto flex items-center gap-2.5 px-3.5 py-2.5 rounded-xl shadow-lg border text-xs max-w-full ${
                toast.type === 'success'
                  ? 'bg-mint/10 border-mint/30 text-mint'
                  : toast.type === 'error'
                  ? 'bg-danger/10 border-danger/30 text-danger'
                  : 'bg-accent/10 border-accent/30 text-accent-bright'
              }`}
            >
              {toast.type === 'success' ? (
                <IconCheckCircle className="w-4 h-4 shrink-0" />
              ) : toast.type === 'error' ? (
                <IconAlertTriangle className="w-4 h-4 shrink-0" />
              ) : (
                <IconInfo className="w-4 h-4 shrink-0" />
              )}
              <span className="flex-1 min-w-0 truncate leading-snug">{toast.message}</span>
              <button
                onClick={() => setToasts((prev) => prev.filter((t) => t.id !== toast.id))}
                className="shrink-0 p-0.5 rounded opacity-60 hover:opacity-100 transition-opacity cursor-pointer"
              >
                <IconX className="w-3 h-3" />
              </button>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Diff viewer */}
      {diffFile && (
        <DiffViewer
          projectPath={project.path}
          filePath={diffFile}
          onClose={() => setDiffFile(null)}
        />
      )}

      {/* Discard confirmation */}
      <AnimatePresence>
        {showDiscardConfirm && (
          <ConfirmDialog
            title="Discard all changes?"
            description="Uncommitted changes will be stashed first so you can recover them later. Continue?"
            confirmLabel="Discard"
            variant="danger"
            onConfirm={() => { setShowDiscardConfirm(false); handleDiscardChanges() }}
            onCancel={() => setShowDiscardConfirm(false)}
          />
        )}
      </AnimatePresence>

      {/* Branch delete confirmation */}
      <AnimatePresence>
        {confirmBranchDelete && (
          <ConfirmDialog
            title={`Delete branch "${confirmBranchDelete}"?`}
            description="This will permanently delete the branch. Make sure you don't need any unmerged changes."
            confirmLabel="Delete"
            variant="danger"
            onConfirm={() => { const name = confirmBranchDelete; setConfirmBranchDelete(null); handleDeleteBranch(name) }}
            onCancel={() => setConfirmBranchDelete(null)}
          />
        )}
      </AnimatePresence>

      {/* Remote remove confirmation */}
      <AnimatePresence>
        {showRemoveRemoteConfirm && (
          <ConfirmDialog
            title="Remove remote?"
            description="This will remove the remote URL. You can add it back later."
            confirmLabel="Remove"
            variant="danger"
            onConfirm={() => { setShowRemoveRemoteConfirm(false); handleRemoveRemote() }}
            onCancel={() => setShowRemoveRemoteConfirm(false)}
          />
        )}
      </AnimatePresence>

      {/* Stash push confirmation */}
      <AnimatePresence>
        {showStashPushConfirm && (
          <ConfirmDialog
            title="Stash all changes?"
            description="Uncommitted changes will be stashed. You can restore them from the Stashes section."
            confirmLabel="Stash"
            onConfirm={() => { setShowStashPushConfirm(false); handleStashPush() }}
            onCancel={() => setShowStashPushConfirm(false)}
          />
        )}
      </AnimatePresence>

      {/* Push with uncommitted changes confirmation */}
      <AnimatePresence>
        {showPushConfirm && (
          <ConfirmDialog
            title="Push with uncommitted changes?"
            description="You have uncommitted changes. The remote will see only your last commit. Consider committing first. Continue pushing anyway?"
            confirmLabel="Push anyway"
            variant="default"
            onConfirm={() => { setShowPushConfirm(false); executePush(false) }}
            onCancel={() => setShowPushConfirm(false)}
          />
        )}
      </AnimatePresence>

      {/* Force push confirmation */}
      <AnimatePresence>
        {showForcePushConfirm && (
          <ConfirmDialog
            title="Force push, are you sure?"
            description="This will overwrite the remote branch with your local history. Other collaborators' work may be lost. This should be used with extreme caution."
            confirmLabel="Force push"
            variant="danger"
            onConfirm={() => { setShowForcePushConfirm(false); executePush(true) }}
            onCancel={() => setShowForcePushConfirm(false)}
          />
        )}
      </AnimatePresence>

      {/* Git result dialog (errors with instructions / success confirmations) */}
      <AnimatePresence>
        {gitResult && (
          <GitResultDialog
            type={gitResult.type}
            title={gitResult.title}
            instructions={gitResult.instructions}
            rawError={gitResult.rawError}
            onClose={() => setGitResult(null)}
            onOpenTerminal={() => api.openTerminal(project.path)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
