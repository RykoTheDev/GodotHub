import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { useTauriEvent } from '../../lib/useTauriEvent'
import { useSettings } from '../../hooks/useSettings'
import { pushToast } from '../../lib/toast'
import type {
  GitAheadBehind,
  GitAuthState,
  GitBranchInfo,
  GitChangedFile,
  GitLogEntry,
  GitRemoteInfo,
  GitStashEntry,
  GitStatus,
  GitWorktree,
  Project,
} from '../../types'
import { api } from '../../lib/api'
import {
  IconArrowUp,
  IconCheck,
  IconChevronDown,
  IconChevronUp,
  IconClone,
  IconCloudArrowDown,
  IconDownload,
  IconExternalLink,
  IconGitBranch,
  IconHistory,
  IconPlay,
  IconPlus,
  IconRefresh,
  IconTrash,
  IconX,
} from '../../lib/icons'

import { GitAuthModal } from '../modals/GitAuthModal'
import { DiffViewerModal } from '../modals/DiffViewerModal'
import { CommitDetailsModal } from '../modals/CommitDetailsModal'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { CommitGraph } from './CommitGraph'
import { Tooltip } from '../reusables/Tooltip'

interface Props {
  project: Project
  gitStatus: GitStatus | null
  onClose: () => void
  onRefresh: () => void
  onSwitchProject?: (project: Project) => void
  connected?: boolean
}

function TruncatedPath({ path, deleted = false }: { path: string; deleted?: boolean }) {
  const ref = useRef<HTMLSpanElement>(null)
  const [truncated, setTruncated] = useState(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const check = () => {
      setTruncated(el.scrollWidth > el.clientWidth + 1)
    }
    check()
    const observer = new ResizeObserver(check)
    observer.observe(el)
    return () => observer.disconnect()
  }, [path])

  const span = (
    <span
      ref={ref}
      className={`text-[11px] font-mono text-muted truncate block ${
        deleted ? 'line-through decoration-muted/60' : ''
      }`}
    >
      {path}
    </span>
  )

  const content = (
    <span className="flex-1 min-w-0">{span}</span>
  )

  return truncated ? (
    <Tooltip content={path} className="flex-1 min-w-0">
      {content}
    </Tooltip>
  ) : (
    content
  )
}

function Spinner() {
  return (
    <motion.svg
      width={16}
      height={16}
      viewBox="0 0 24 24"
      fill="none"
      className="block"
      animate={{ rotate: 360 }}
      transition={{ repeat: Infinity, duration: 0.8, ease: 'linear' }}
    >
      <path
        d="M21 12a9 9 0 1 1-6.219-8.56"
        stroke="currentColor"
        strokeWidth={2}
        strokeLinecap="round"
      />
    </motion.svg>
  )
}

function ProviderBadge({ webUrl }: { webUrl: string }) {
  if (webUrl.includes('gitlab.com')) {
    return (
      <span className="shrink-0 text-[9px] font-semibold px-1.5 py-0.5 rounded-tag bg-amber/15 text-amber">
        GitLab
      </span>
    )
  }
  if (webUrl.includes('github.com')) {
    return (
      <span className="shrink-0 text-[9px] font-semibold px-1.5 py-0.5 rounded-tag bg-ink/10 text-ink">
        GitHub
      </span>
    )
  }
  return <IconGitBranch className="w-3 h-3 text-muted/40 shrink-0" />
}

function ChangedFileRow({
  file,
  badgeChar,
  deleted,
  onStage,
  onUnstage,
  onDiscard,
  onOpen,
  stageLabel,
  unstageLabel,
  discardLabel,
}: {
  file: GitChangedFile
  badgeChar: string
  deleted: boolean
  onStage?: () => void
  onUnstage?: () => void
  onDiscard?: () => void
  onOpen?: () => void
  stageLabel: string
  unstageLabel: string
  discardLabel: string
}) {
  const ch = badgeChar === '?' ? 'U' : badgeChar
  const isAdded = ch === 'A'
  const isDeleted = ch === 'D'
  const isModified = ch === 'M'
  const color = isAdded
    ? 'text-mint'
    : isDeleted
      ? 'text-danger'
      : isModified
        ? 'text-amber'
        : 'text-muted/50'
  return (
    <div
      onClick={onOpen}
      className={`group relative flex items-center gap-1.5 px-2.5 py-1.5 hover:bg-raised/60 transition-colors ${
        onOpen ? 'cursor-pointer' : ''
      }`}
    >
      <span className={`w-3 shrink-0 text-[9px] font-mono font-bold ${color}`}>
        {ch}
      </span>
      <div className="flex-1 min-w-0">
        <TruncatedPath path={file.path} deleted={deleted} />
      </div>
      <div
        onClick={(e) => e.stopPropagation()}
        className="absolute right-1.5 top-1/2 -translate-y-1/2 flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity bg-base/80 rounded-md px-0.5 py-0.5"
      >
        {onStage && (
          <Tooltip content={stageLabel}>
          <button
              type="button"
              onClick={onStage}
              className="focus-ring cursor-pointer p-1 rounded text-muted/60 hover:text-mint hover:bg-raised transition-colors"
            >
              <IconPlus className="w-3 h-3" />
            </button>
          </Tooltip>
        )}
        {onUnstage && (
          <Tooltip content={unstageLabel}>
          <button
              type="button"
              onClick={onUnstage}
              className="focus-ring cursor-pointer p-1 rounded text-muted/60 hover:text-amber hover:bg-raised transition-colors"
            >
              <IconChevronUp className="w-3 h-3" />
            </button>
          </Tooltip>
        )}
        {onDiscard && (
          <Tooltip content={discardLabel}>
          <button
              type="button"
              onClick={onDiscard}
              className="focus-ring cursor-pointer p-1 rounded text-muted/60 hover:text-danger hover:bg-raised transition-colors"
            >
              <IconTrash className="w-3 h-3" />
            </button>
          </Tooltip>
        )}
      </div>
    </div>
  )
}

function Section({
  title,
  count,
  storageKey,
  defaultOpen,
  onContextMenu,
  children,
}: {
  title: string
  count?: number
  storageKey?: string
  defaultOpen?: boolean
  onContextMenu?: (e: React.MouseEvent) => void
  children: ReactNode
}) {
  const [open, setOpen] = useState(() => {
    if (!storageKey) return defaultOpen ?? true
    try {
      return localStorage.getItem(storageKey) !== '0'
    } catch {
      return defaultOpen ?? true
    }
  })
  const toggle = () => setOpen((v) => {
    if (storageKey) {
      try {
        localStorage.setItem(storageKey, v ? '0' : '1')
      } catch {}
    }
    return !v
  })
  return (
    <div className="flex flex-col gap-1.5">
      <button
        type="button"
        onClick={toggle}
        onContextMenu={onContextMenu}
        aria-expanded={open}
        className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-1 py-1 rounded-item text-left hover:bg-raised/60 transition-colors group"
      >
        <IconChevronDown
          className={`w-3 h-3 text-muted/50 shrink-0 transition-transform duration-200 ${
            open ? '' : '-rotate-90'
          }`}
        />
        <span className="flex-1 text-[10px] font-semibold uppercase tracking-wider text-muted/50 group-hover:text-muted transition-colors">
          {title}
        </span>
        {typeof count === 'number' && count > 0 && (
          <span className="text-[10px] font-mono font-medium tabular-nums text-muted/60 bg-overlay border border-outline/50 rounded-tag px-1.5 py-0.5 shrink-0">
            {count}
          </span>
        )}
      </button>

      <div
        className={`grid transition-[grid-template-rows] duration-200 ease-out ${
          open ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'
        }`}
      >
        <div className="overflow-hidden min-h-0">
          <div className="flex flex-col gap-1.5">{children}</div>
        </div>
      </div>
    </div>
  )
}

export function GitSidebar({
  project,
  gitStatus,
  onClose,
  onRefresh,
  onSwitchProject,
  connected = false,
}: Props) {
  const { t } = useTranslation('git')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const [gitAuth, setGitAuth] = useState<GitAuthState | null>(null)
  const [gitAuthFlow, setGitAuthFlow] = useState<'github' | 'gitlab' | null>(
    null,
  )
  const [commitMessage, setCommitMessage] = useState('')
  const [committing, setCommitting] = useState(false)
  const [changedFiles, setChangedFiles] = useState<GitChangedFile[]>([])
  const [changesLoading, setChangesLoading] = useState(true)
  const [changesQuery, setChangesQuery] = useState('')
  const [remotes, setRemotes] = useState<GitRemoteInfo[]>([])
  const [remotesLoading, setRemotesLoading] = useState(true)
  const [branches, setBranches] = useState<GitBranchInfo[]>([])
  const [branchesLoading, setBranchesLoading] = useState(true)
  const [switchingBranch, setSwitchingBranch] = useState<string | null>(null)
  const [branchMenuOpen, setBranchMenuOpen] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [remotePhase, setRemotePhase] = useState<{
    action: 'push' | 'pull' | 'fetch'
    phase: 'running' | 'done' | 'error'
  } | null>(null)
  const remoteTimerRef = useRef<number | null>(null)
  const [commits, setCommits] = useState<GitLogEntry[]>([])
  const [commitsLoading, setCommitsLoading] = useState(true)
  const [stashes, setStashes] = useState<GitStashEntry[]>([])
  const [stashBusy, setStashBusy] = useState<string | null>(null)
  const [ctxMenu, setCtxMenu] = useState<{ x: number; y: number } | null>(null)
  const ctxMenuRef = useRef<HTMLDivElement>(null)
  const [diffFile, setDiffFile] = useState<GitChangedFile | null>(null)
  const [stashDiff, setStashDiff] = useState<{
    index: number
    message: string
  } | null>(null)
  const [aheadBehind, setAheadBehind] = useState<GitAheadBehind | null>(null)
  const [merging, setMerging] = useState(false)
  const [conflictFiles, setConflictFiles] = useState<string[]>([])
  const [mergeBusy, setMergeBusy] = useState<string | null>(null)
  const [forcePushOpen, setForcePushOpen] = useState(false)
  const [commitHash, setCommitHash] = useState<string | null>(null)
  const [newBranchMode, setNewBranchMode] = useState(false)
  const [newBranchName, setNewBranchName] = useState('')
  const [deletingBranch, setDeletingBranch] = useState<string | null>(null)
  const [publishingBranch, setPublishingBranch] = useState(false)
  const branchMenuRef = useRef<HTMLDivElement>(null)
  const [worktrees, setWorktrees] = useState<GitWorktree[]>([])
  const [switchingWorktree, setSwitchingWorktree] = useState<string | null>(null)
  const [newWorktreeMode, setNewWorktreeMode] = useState(false)
  const [newWorktreePath, setNewWorktreePath] = useState('')
  const [newWorktreeBranch, setNewWorktreeBranch] = useState('')
  const [creatingWorktree, setCreatingWorktree] = useState(false)
  const [removingWorktree, setRemovingWorktree] = useState<string | null>(null)
  const [removeWorktreeConfirm, setRemoveWorktreeConfirm] = useState<string | null>(null)
  const [ready, setReady] = useState(false)

  const notifyGitStatusChanged = useCallback(() => {
    window.dispatchEvent(new Event('app:refresh-git-status'))
  }, [])

  const refreshGitAuth = useCallback(async () => {
    try {
      setGitAuth(await api.gitAuthGetState())
    } catch {}
  }, [])

  useEffect(() => {
    if (!ready) return
    void refreshGitAuth()
  }, [refreshGitAuth, ready])

  useEffect(() => {
    if (!ready) return
    let cancelled = false
    setChangesLoading(true)
    setRemotesLoading(true)
    setBranchesLoading(true)
    setCommitsLoading(true)
    void refreshGitAuth()
    const worktreesEnabled = settings.git_worktrees_enabled
    Promise.allSettled([
      api.gitChangedFiles(project.path),
      api.gitListRemotes(project.path),
      api.gitListBranches(project.path),
      api.gitLogEntries(project.path),
      api.gitStashList(project.path),
      api.gitAheadBehind(project.path),
      api.gitIsMerging(project.path),
      api.gitMergeConflictFiles(project.path),
      worktreesEnabled ? api.gitWorktreeList(project.path) : Promise.resolve([]),
    ]).then(([files, remotes, branches, log, stashes, aheadBehind, isMerging, conflictFiles, wts]) => {
      if (cancelled) return
      if (files.status === 'fulfilled') setChangedFiles(files.value)
      if (remotes.status === 'fulfilled') setRemotes(remotes.value)
      if (branches.status === 'fulfilled') setBranches(branches.value)
      if (log.status === 'fulfilled') setCommits(log.value)
      if (stashes.status === 'fulfilled') setStashes(stashes.value)
      if (aheadBehind.status === 'fulfilled') setAheadBehind(aheadBehind.value)
      if (isMerging.status === 'fulfilled') setMerging(isMerging.value)
      if (conflictFiles.status === 'fulfilled') setConflictFiles(conflictFiles.value)
      if (wts.status === 'fulfilled') setWorktrees(wts.value)
      setChangesLoading(false)
      setRemotesLoading(false)
      setBranchesLoading(false)
      setCommitsLoading(false)
    })
    return () => { cancelled = true }
  }, [project.path, refreshGitAuth, ready, settings.git_worktrees_enabled])

  useEffect(() => {
    const onOpened = () => setReady(true)
    window.addEventListener('app:git-sidebar-opened', onOpened)
    return () => window.removeEventListener('app:git-sidebar-opened', onOpened)
  }, [])

  useEffect(() => {
    if (!ready) return
    api.gitStartFsWatcher(project.path).catch(() => {})
    return () => {
      api.gitStopFsWatcher().catch(() => {})
    }
  }, [project.path, ready])

  useEffect(() => {
    setBranchMenuOpen(false)
    setCtxMenu(null)
    setDiffFile(null)
    setStashDiff(null)
    setCommitHash(null)
    setForcePushOpen(false)
    setNewBranchMode(false)
    setNewBranchName('')
    setCommitMessage('')
    setNewWorktreeMode(false)
    setNewWorktreePath('')
    setNewWorktreeBranch('')
    setRemoveWorktreeConfirm(null)
    setChangesQuery('')
  }, [project.path])

  useEffect(() => {
    if (!branchMenuOpen) return
    const onDown = (e: MouseEvent) => {
      if (branchMenuRef.current && !branchMenuRef.current.contains(e.target as Node)) {
        setBranchMenuOpen(false)
      }
    }
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') setBranchMenuOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    window.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDown)
      window.removeEventListener('keydown', onKey)
    }
  }, [branchMenuOpen])

  const handleSwitchBranch = async (name: string) => {
    if (switchingBranch || branches.find((b) => b.name === name)?.is_current) {
      return
    }
    setSwitchingBranch(name)
    try {
      await api.gitSwitchBranch(project.path, name)
      setBranches(await api.gitListBranches(project.path))
      await refreshChanges()
      void refreshLog()
      void refreshAheadBehind()
      onRefresh()
      notifyGitStatusChanged()
      pushToast('success', t('switched_ok', { branch: name }))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setSwitchingBranch(null)
    }
  }

  const handleCreateBranch = async () => {
    const name = newBranchName.trim()
    if (!name || deletingBranch) return
    try {
      await api.gitCreateBranch(project.path, name)
      await api.gitSwitchBranch(project.path, name)
      setBranches(await api.gitListBranches(project.path))
      await refreshChanges()
      void refreshLog()
      onRefresh()
      notifyGitStatusChanged()
      setNewBranchName('')
      setNewBranchMode(false)
      pushToast('success', t('branch_created'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleDeleteBranch = async (name: string) => {
    if (deletingBranch) return
    setDeletingBranch(name)
    try {
      await api.gitDeleteBranch(project.path, name)
      setBranches(await api.gitListBranches(project.path))
      pushToast('success', t('branch_deleted'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setDeletingBranch(null)
    }
  }

  const handlePublishBranch = async (name: string) => {
    if (publishingBranch) return
    setPublishingBranch(true)
    try {
      await api.gitBranchPublish(project.path, name)
      setBranches(await api.gitListBranches(project.path))
      void refreshAheadBehind()
      void refreshLog()
      pushToast('success', t('branch_published'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setPublishingBranch(false)
    }
  }

  const handleSync = async () => {
    if (syncing) return
    setSyncing(true)
    try {
      await api.gitPull(project.path)
      await api.gitPush(project.path)
      onRefresh()
      notifyGitStatusChanged()
      await refreshChanges()
      void refreshLog()
      void refreshAheadBehind()
      void refreshMergeState()
      pushToast('success', t('synced_ok'))
      if (settings.desktop_notifications_enabled) {
        void api.notify('GodotHub', t('synced_ok'))
      }
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setSyncing(false)
    }
  }

  useEffect(
    () => () => {
      if (remoteTimerRef.current != null) {
        window.clearTimeout(remoteTimerRef.current)
      }
    },
    [],
  )

  const handleStashPush = async () => {
    if (stashBusy) return
    setStashBusy('push')
    try {
      await api.gitStashPush(project.path)
      await refreshStashes()
      await refreshChanges()
      notifyGitStatusChanged()
      void refreshLog()
      pushToast('success', t('changes_stashed_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setStashBusy(null)
    }
  }

  const handleStashApply = async (index: number) => {
    if (stashBusy) return
    setStashBusy(`apply:${index}`)
    try {
      await api.gitStashApply(project.path, index)
      await refreshStashes()
      await refreshChanges()
      notifyGitStatusChanged()
      void refreshLog()
      pushToast('success', t('stash_applied_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setStashBusy(null)
    }
  }

  const handleStashPop = async (index: number) => {
    if (stashBusy) return
    setStashBusy(`pop:${index}`)
    try {
      await api.gitStashPop(project.path, index)
      await refreshStashes()
      await refreshChanges()
      notifyGitStatusChanged()
      void refreshLog()
      pushToast('success', t('stash_popped_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setStashBusy(null)
    }
  }

  const handleStashDrop = async (index: number) => {
    if (stashBusy) return
    setStashBusy(`drop:${index}`)
    try {
      await api.gitStashDrop(project.path, index)
      await refreshStashes()
      pushToast('success', t('stash_dropped_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setStashBusy(null)
    }
  }

  useEffect(() => {
    if (!ctxMenu) return
    const onDown = (e: MouseEvent) => {
      if (ctxMenuRef.current && !ctxMenuRef.current.contains(e.target as Node)) {
        setCtxMenu(null)
      }
    }
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') setCtxMenu(null)
    }
    document.addEventListener('mousedown', onDown)
    window.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onDown)
      window.removeEventListener('keydown', onKey)
    }
  }, [ctxMenu])

  const handleStageAll = async () => {
    setCtxMenu(null)
    try {
      await api.gitStageFile(project.path, '.')
      await refreshChanges()
      notifyGitStatusChanged()
      pushToast('success', t('stage_all_ok'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleUnstageAll = async () => {
    setCtxMenu(null)
    try {
      await api.gitUnstageFile(project.path, '.')
      await refreshChanges()
      notifyGitStatusChanged()
      pushToast('success', t('unstage_all_ok'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleDiscardAll = async () => {
    setCtxMenu(null)
    try {
      await api.gitStashPush(project.path)
      await api.gitDiscardChanges(project.path)
      await refreshStashes()
      await refreshChanges()
      notifyGitStatusChanged()
      void refreshLog()
      pushToast('success', t('discard_all_ok'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleUndoCommit = async () => {
    setCtxMenu(null)
    try {
      await api.gitUndoCommit(project.path)
      await refreshChanges()
      void refreshLog()
      onRefresh()
      notifyGitStatusChanged()
      pushToast('success', t('undo_commit_done'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleUndoPull = async () => {
    setCtxMenu(null)
    try {
      await api.gitUndoPull(project.path)
      await refreshChanges()
      void refreshLog()
      void refreshAheadBehind()
      onRefresh()
      notifyGitStatusChanged()
      pushToast('success', t('undo_pull_done'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleRemoteAction = async (action: 'push' | 'pull' | 'fetch') => {
    if (remotePhase) return
    setRemotePhase({ action, phase: 'running' })
    const hold = (phase: 'done' | 'error') => {
      setRemotePhase({ action, phase })
      remoteTimerRef.current = window.setTimeout(
        () => setRemotePhase(null),
        1200,
      )
    }
    try {
      if (action === 'push') await api.gitPush(project.path)
      else if (action === 'pull') await api.gitPull(project.path)
      else await api.gitFetch(project.path)
      onRefresh()
      notifyGitStatusChanged()
      await refreshChanges()
      void refreshLog()
      void refreshAheadBehind()
      void refreshMergeState()
      hold('done')
      const doneLabel =
        action === 'push'
          ? t('pushed_ok')
          : action === 'pull'
            ? t('pulled_ok')
            : t('fetched_ok')
      pushToast('success', doneLabel)
      if (settings.desktop_notifications_enabled) {
        void api.notify('GodotHub', doneLabel)
      }
    } catch (e) {
      hold('error')
      pushToast('error', String(e))
    }
  }

  const handleForcePush = async () => {
    setForcePushOpen(false)
    try {
      await api.gitPushForce(project.path)
      void refreshAheadBehind()
      pushToast('success', t('force_pushed'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleResolveConflict = async (
    kind: 'ours' | 'theirs' | 'manual',
    filePath: string,
  ) => {
    setMergeBusy(kind)
    try {
      if (kind === 'ours') {
        await api.gitResolveConflictOurs(project.path, filePath)
      } else if (kind === 'theirs') {
        await api.gitResolveConflictTheirs(project.path, filePath)
      } else {
        await api.gitResolveConflictManual(project.path, filePath)
      }
      await refreshMergeState()
      await refreshChanges()
      pushToast(
        'success',
        kind === 'ours'
          ? t('resolved_ours')
          : kind === 'theirs'
            ? t('resolved_theirs')
            : t('resolved_manual'),
      )
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setMergeBusy(null)
    }
  }

  const handleAbortMerge = async () => {
    setMergeBusy('abort')
    try {
      await api.gitAbortMerge(project.path)
      await refreshMergeState()
      await refreshChanges()
      void refreshLog()
      onRefresh()
      notifyGitStatusChanged()
      pushToast('success', t('merge_aborted'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setMergeBusy(null)
    }
  }

  const handleDisconnect = async (provider: 'github' | 'gitlab') => {
    try {
      await api.gitAuthDisconnect(provider)
      await refreshGitAuth()
    } catch {}
  }

  const handleCommit = async () => {
    const msg = commitMessage.trim()
    if (!msg || committing) return
    setCommitting(true)
    try {
      if (stagedFiles.length === 0) {
        await api.gitStageFile(project.path, '.')
      }
      await api.gitCommit(project.path, msg, false)
      setCommitMessage('')
      onRefresh()
      notifyGitStatusChanged()
      void refreshChanges()
      void refreshLog()
      void refreshAheadBehind()
      pushToast('success', t('committed_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setCommitting(false)
    }
  }

  const refreshChanges = useCallback(async () => {
    try {
      const files = await api.gitChangedFiles(project.path)
      setChangedFiles(files)
    } catch {}
  }, [project.path])

  const refreshLog = useCallback(async () => {
    try {
      setCommits(await api.gitLogEntries(project.path))
    } catch {}
  }, [project.path])

  const refreshStashes = useCallback(async () => {
    try {
      setStashes(await api.gitStashList(project.path))
    } catch {}
  }, [project.path])

  const refreshAheadBehind = useCallback(async () => {
    try {
      setAheadBehind(await api.gitAheadBehind(project.path))
    } catch {}
  }, [project.path])

  const refreshMergeState = useCallback(async () => {
    try {
      const [isMerging, files] = await Promise.all([
        api.gitIsMerging(project.path),
        api.gitMergeConflictFiles(project.path),
      ])
      setMerging(isMerging)
      setConflictFiles(files)
    } catch {}
  }, [project.path])

  const refreshWorktrees = useCallback(async () => {
    try {
      const wts = await api.gitWorktreeList(project.path)
      setWorktrees(wts)
    } catch {}
  }, [project.path])

  const handleSwitchWorktree = async (worktreePath: string) => {
    if (switchingWorktree) return
    setSwitchingWorktree(worktreePath)
    try {
      await api.gitWorktreeSwitch(project.path, worktreePath)
      // Update the project to point to the worktree directory
      onSwitchProject?.({ ...project, path: worktreePath })
      pushToast('success', t('switched_worktree_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setSwitchingWorktree(null)
    }
  }

  const handleCreateWorktree = async () => {
    const wtPath = newWorktreePath.trim()
    if (!wtPath || creatingWorktree) return
    setCreatingWorktree(true)
    try {
      const branch = newWorktreeBranch.trim() || undefined
      // Resolve relative paths against the project directory
      const resolvedPath = wtPath.startsWith('/') ? wtPath : `${project.path}/${wtPath}`
      await api.gitWorktreeAdd(project.path, resolvedPath, branch)
      await refreshWorktrees()
      onRefresh()
      notifyGitStatusChanged()
      setNewWorktreePath('')
      setNewWorktreeBranch('')
      setNewWorktreeMode(false)
      pushToast('success', t('worktree_created_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setCreatingWorktree(false)
    }
  }

  const handleRemoveWorktree = async (worktreePath: string) => {
    if (removingWorktree) return
    setRemovingWorktree(worktreePath)
    try {
      await api.gitWorktreeRemove(project.path, worktreePath)
      await refreshWorktrees()
      onRefresh()
      notifyGitStatusChanged()
      pushToast('success', t('worktree_removed_ok'))
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setRemovingWorktree(null)
    }
  }

  useTauriEvent(
    'git:project-changed',
    () => {
      void refreshChanges()
      void refreshLog()
      void refreshAheadBehind()
      void refreshMergeState()
      if (settings.git_worktrees_enabled) void refreshWorktrees()
    },
    [refreshChanges, refreshLog, refreshAheadBehind, refreshMergeState, refreshWorktrees, settings.git_worktrees_enabled],
  )

  const handleStageFile = async (filePath: string) => {
    try {
      await api.gitStageFile(project.path, filePath)
      await refreshChanges()
      notifyGitStatusChanged()
      pushToast('success', t('staged_ok'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleDiscardFile = async (filePath: string) => {
    try {
      await api.gitDiscardFile(project.path, filePath)
      await refreshChanges()
      notifyGitStatusChanged()
      pushToast('success', t('discarded_ok'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const handleUnstageFile = async (filePath: string) => {
    try {
      await api.gitUnstageFile(project.path, filePath)
      await refreshChanges()
      notifyGitStatusChanged()
      pushToast('success', t('unstaged_ok'))
    } catch (e) {
      pushToast('error', String(e))
    }
  }

  const changesQueryLower = changesQuery.trim().toLowerCase()
  const visibleChangedFiles = changesQueryLower
    ? changedFiles.filter((f) => f.path.toLowerCase().includes(changesQueryLower))
    : changedFiles
  const stagedFiles = visibleChangedFiles.filter((f) => {
    const s = f.status
    return s.length > 0 && s[0] !== ' ' && s[0] !== '?'
  })
  const unstagedFiles = visibleChangedFiles.filter((f) => {
    const s = f.status
    if (s === '??') return true
    return s.length > 1 && s[1] !== ' ' && s[1] !== '?'
  })

  const currentBranch =
    branches.find((b) => b.is_current)?.name ?? gitStatus?.branch ?? '…'

  const connectedCount =
    (gitAuth?.github ? 1 : 0) +
    (gitAuth?.gitlab ? 1 : 0) +
    (gitAuth?.pats ?? []).length

  return (
    <div
      className={`flex flex-col h-full w-full overflow-hidden ${
        connected ? 'rounded-none border-l border-line bg-raised' : 'rounded-card bg-raised'
      }`}
    >
      <AnimatePresence mode="wait" initial={false}>
        <motion.div
          key={project.path}
          initial={{ opacity: 0, x: 16 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -16 }}
          transition={{ duration: 0.16, ease: 'easeOut' }}
          className="flex flex-col h-full min-h-0"
        >
      <div className="shrink-0 flex items-center justify-between h-12 border-b border-line px-3">
        <span className="font-display font-medium text-ink/50 text-sm ml-1 truncate">
          {project.name} // Git
        </span>
        <Tooltip content={t('close_sidebar')} side="left">
          <button
            type="button"
            onClick={onClose}
            className="focus-ring cursor-pointer w-9 h-9 shrink-0 flex items-center justify-center rounded-item text-muted hover:text-ink hover:bg-raised/60 transition-colors"
          >
            <IconX className="w-4 h-4" />
          </button>
        </Tooltip>
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto overflow-x-hidden new-ui-scroll-viewport">
        {!ready ? (
          <div className="flex-1 flex items-center justify-center h-full">
            <motion.div key="div-938"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.2 }}
              className="flex flex-col items-center gap-3"
            >
              <Spinner />
              <span className="text-[11px] text-muted/50">
                {tc('loading')}
              </span>
            </motion.div>
          </div>
        ) : (
        <div className="px-3 py-3 flex flex-col gap-3">
          <motion.div
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2, ease: 'easeOut', delay: 0.1 }}
          >
            <Section
              title={t('auth_connected_accounts')}
              count={connectedCount}
              storageKey="git-sidebar-connected-accounts"
              defaultOpen={false}
            >
            {connectedCount === 0 ? (
              <div className="px-2.5 py-3">
                <p className="text-[11px] text-muted/60 leading-relaxed">
                  {t('auth_connect_hint')}
                </p>
              </div>
            ) : (
            <>
            {gitAuth?.github && (
            <div className="flex items-center justify-between gap-2 px-2.5 py-2 rounded-item border border-line/60 bg-base/40">
              <div className="flex items-center gap-2 min-w-0">
                <span className="w-7 h-7 rounded-item flex items-center justify-center shrink-0 border bg-mint/10 border-mint/30 text-mint">
                  <IconGitBranch className="w-3.5 h-3.5" />
                </span>
                <div className="min-w-0">
                  <p className="text-xs font-medium text-ink">GitHub</p>
                  <p className="text-[10px] font-mono text-muted truncate">
                    @{gitAuth.github.username}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => handleDisconnect('github')}
                className="focus-ring cursor-pointer inline-flex items-center gap-1 px-2 py-1 rounded-tag text-[10px] font-medium text-muted hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
              >
                {t('auth_disconnect')}
              </button>
            </div>
            )}

            {gitAuth?.gitlab && (
            <div className="flex items-center justify-between gap-2 px-2.5 py-2 rounded-item border border-line/60 bg-base/40">
              <div className="flex items-center gap-2 min-w-0">
                <span className="w-7 h-7 rounded-item flex items-center justify-center shrink-0 border bg-mint/10 border-mint/30 text-mint">
                  <IconGitBranch className="w-3.5 h-3.5" />
                </span>
                <div className="min-w-0">
                  <p className="text-xs font-medium text-ink">GitLab</p>
                  <p className="text-[10px] font-mono text-muted truncate">
                    @{gitAuth.gitlab.username}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => handleDisconnect('gitlab')}
                className="focus-ring cursor-pointer inline-flex items-center gap-1 px-2 py-1 rounded-tag text-[10px] font-medium text-muted hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
              >
                {t('auth_disconnect')}
              </button>
            </div>
            )}

            {(gitAuth?.pats ?? []).length > 0 && (
              <div className="flex flex-col gap-1 px-1 pt-1">
                {(gitAuth?.pats ?? []).map((pat) => (
                  <div
                    key={pat.host}
                    className="flex items-center gap-1.5 px-2 py-1.5 rounded-item bg-mint/5 border border-mint/20"
                  >
                    <IconCheck className="w-3 h-3 text-mint shrink-0" />
                    <span className="text-[10px] font-mono text-muted truncate flex-1">
                      {pat.host}
                    </span>
                    <span className="text-[10px] text-muted/60 truncate">
                      @{pat.username}
                    </span>
                  </div>
                ))}
              </div>
            )}
            </>
            )}
            </Section>
          </motion.div>

          {merging && (
            <motion.div
              initial={{ opacity: 0, x: 24 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.2, ease: 'easeOut', delay: 0.16 }}
            >
              <Section title={t('merge_in_progress')} count={conflictFiles.length}>
              {conflictFiles.length === 0 ? (
                <div className="px-2.5 py-2">
                  <span className="text-[11px] text-muted/50">…</span>
                </div>
              ) : (
                <div className="flex flex-col gap-1">
                  {conflictFiles.map((f) => (
                    <div
                      key={f}
                      className="flex flex-col gap-1.5 px-2.5 py-2 rounded-item border border-danger/20 bg-danger/5"
                    >
                      <p className="text-[11px] font-mono text-ink truncate">
                        {f}
                      </p>
                      <div className="flex gap-1">
                        <button
                          type="button"
                          onClick={() => void handleResolveConflict('ours', f)}
                          disabled={!!mergeBusy}
                          className="focus-ring cursor-pointer flex-1 px-1.5 py-1 rounded-tag text-[10px] font-medium text-mint bg-mint/10 hover:bg-mint/20 transition-colors disabled:opacity-40 disabled:cursor-wait"
                        >
                          {t('use_ours')}
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleResolveConflict('theirs', f)}
                          disabled={!!mergeBusy}
                          className="focus-ring cursor-pointer flex-1 px-1.5 py-1 rounded-tag text-[10px] font-medium text-amber bg-amber/10 hover:bg-amber/20 transition-colors disabled:opacity-40 disabled:cursor-wait"
                        >
                          {t('use_theirs')}
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleResolveConflict('manual', f)}
                          disabled={!!mergeBusy}
                          className="focus-ring cursor-pointer flex-1 px-1.5 py-1 rounded-tag text-[10px] font-medium text-accent-bright bg-accent/10 hover:bg-accent/20 transition-colors disabled:opacity-40 disabled:cursor-wait"
                        >
                          {t('i_resolved')}
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
              <button
                type="button"
                onClick={() => void handleAbortMerge()}
                disabled={!!mergeBusy}
                className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-item border border-danger/30 text-danger hover:bg-danger/10 transition-colors disabled:opacity-40 disabled:cursor-wait text-[11px] font-medium"
              >
                <IconTrash
                  className={`w-3.5 h-3.5 ${
                    mergeBusy === 'abort' ? 'animate-spin' : ''
                  }`}
                />
                {t('abort_merge')}
              </button>
              </Section>
            </motion.div>
          )}

          <motion.div
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2, ease: 'easeOut', delay: 0.22 }}
            className="flex gap-1.5"
          >
            {(
              [
                { key: 'push', Icon: IconArrowUp },
                { key: 'pull', Icon: IconCloudArrowDown },
                { key: 'fetch', Icon: IconDownload },
              ] as const
            ).map(({ key, Icon }) => {
              const isActive = remotePhase?.action === key
              const state = isActive ? remotePhase.phase : 'idle'
              return (
                  <Tooltip content={isActive ? t(`${key}ing`) : t(key)} className="flex-1 min-w-0">
                  <motion.button
                    type="button"
                    onClick={() => void handleRemoteAction(key)}
                    onContextMenu={(e) => {
                      if (key !== 'push') return
                      e.preventDefault()
                      setForcePushOpen(true)
                    }}
                    disabled={!!remotePhase}
                    aria-label={t(key)}
                    className={["w-full",
                      'relative w-full h-8 inline-flex items-center justify-center rounded-item border border-outline/50 shadow-md shadow-black/10 select-none focus-ring transition-colors duration-300',
                      state === 'running'
                        ? 'bg-accent text-overlay'
                        : state === 'done'
                          ? 'bg-mint text-overlay'
                          : state === 'error'
                            ? 'bg-danger text-overlay'
                            : 'bg-overlay text-muted hover:text-ink hover:bg-raised cursor-pointer',
                    ].join(' ')}
                  >
                    {key === 'push' && aheadBehind && aheadBehind.ahead > 0 && state === 'idle' && (
                      <span className="absolute -top-1.5 -right-1.5 min-w-[16px] h-4 flex items-center justify-center rounded-full bg-mint text-overlay text-[8px] font-bold px-1 z-10">
                        {aheadBehind.ahead}
                      </span>
                    )}
                    {key === 'pull' && aheadBehind && aheadBehind.behind > 0 && state === 'idle' && (
                      <span className="absolute -top-1.5 -right-1.5 min-w-[16px] h-4 flex items-center justify-center rounded-full bg-danger text-overlay text-[8px] font-bold px-1 z-10">
                        {aheadBehind.behind}
                      </span>
                    )}
                    <AnimatePresence mode="popLayout" initial={false}>
                      <motion.span
                        key={state}
                        className="inline-flex"
                        initial={{ opacity: 0, scale: 0.6, filter: 'blur(4px)' }}
                        animate={{ opacity: 1, scale: 1, filter: 'blur(0px)' }}
                        exit={{
                          opacity: 0,
                          scale: 0.6,
                          filter: 'blur(4px)',
                          transition: { duration: 0.15 },
                        }}
                        transition={{ duration: 0.2, ease: [0.34, 1.56, 0.64, 1] }}
                      >
                        {state === 'running' ? (
                          <Spinner />
                        ) : state === 'done' ? (
                          <IconCheck className="w-3.5 h-3.5" />
                        ) : state === 'error' ? (
                          <IconX className="w-3.5 h-3.5" />
                        ) : (
                          <Icon className="w-3.5 h-3.5" />
                        )}
                      </motion.span>
                    </AnimatePresence>
                  </motion.button>
                  </Tooltip>
              )
            })}
          </motion.div>

          <motion.div key="div-1187"
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2, ease: 'easeOut', delay: 0.28 }}
            className="flex flex-col gap-1.5"
          >
            {remotesLoading ? (
              <div className="px-2 py-1.5">
                <span className="text-[10px] text-muted/50">…</span>
              </div>
            ) : remotes.length === 0 ? (
              <div className="px-2 py-1.5 rounded-item border border-dashed border-outline/60">
                <span className="text-[10px] text-muted/50">
                  {t('no_remotes')}
                </span>
              </div>
            ) : null}

            <div className="flex items-stretch gap-1.5">
              <div
                ref={branchMenuRef}
                className="relative flex-1 min-w-0 rounded-item border border-outline/50 bg-raised/60"
              >
                <button
                  type="button"
                  onClick={() => setBranchMenuOpen((v) => !v)}
                  aria-expanded={branchMenuOpen}
                  className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-2.5 py-2 text-left min-w-0 transition-colors hover:bg-raised rounded-item"
                >
                  <IconGitBranch className="w-3 h-3 text-accent shrink-0" />
                  <span className="flex-1 text-[11px] font-semibold text-ink truncate">
                    {switchingBranch ?? currentBranch}
                  </span>
                  {aheadBehind &&
                    (aheadBehind.ahead > 0 || aheadBehind.behind > 0) && (
                      <span className="flex items-center gap-1 shrink-0">
                        {aheadBehind.behind > 0 && (
                          <span className="text-[9px] font-mono font-semibold text-danger bg-danger/10 rounded-tag px-1 py-0.5">
                            ↓{aheadBehind.behind}
                          </span>
                        )}
                        {aheadBehind.ahead > 0 && (
                          <span className="text-[9px] font-mono font-semibold text-mint bg-mint/10 rounded-tag px-1 py-0.5">
                            ↑{aheadBehind.ahead}
                          </span>
                        )}
                      </span>
                    )}
                  <IconChevronDown
                    className={`w-3 h-3 text-muted/60 shrink-0 transition-transform duration-200 ${
                      branchMenuOpen ? 'rotate-180' : ''
                    }`}
                  />
                </button>
                <AnimatePresence>
                  {branchMenuOpen && (
                    <motion.div
                      key="branch-menu"
                      initial={{ opacity: 0, y: -4, scale: 0.97 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: -4, scale: 0.97 }}
                      transition={{ duration: 0.12, ease: 'easeOut' }}
                      className="absolute left-0 right-0 top-full z-20 mt-1 rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-1.5 max-h-56 overflow-y-auto new-ui-scroll-viewport"
                    >
                      {branchesLoading ? (
                        <div className="px-2 py-1.5">
                          <span className="text-[11px] text-muted/50">
                            {tc('loading')}
                          </span>
                        </div>
                      ) : branches.length === 0 ? (
                        <div className="px-2 py-1.5">
                          <span className="text-[11px] text-muted/50">
                            {t('no_branches')}
                          </span>
                        </div>
                      ) : (
                        branches.map((b) => {
                          const isCurrent = b.is_current
                          const isSwitching = switchingBranch === b.name
                          return (
                            <div
                              key={b.name}
                              className="group relative flex items-center"
                            >
                              <button
                                type="button"
                                disabled={isCurrent || !!switchingBranch}
                                onClick={() => {
                                  setBranchMenuOpen(false)
                                  void handleSwitchBranch(b.name)
                                }}
                                className={`flex-1 min-w-0 flex items-center gap-1.5 pl-2 pr-1 py-1.5 rounded-item text-[11px] font-medium transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed text-left ${
                                  isCurrent
                                    ? 'text-ink bg-accent/10'
                                    : 'text-muted hover:bg-raised hover:text-ink'
                                }`}
                              >
                                <IconGitBranch
                                  className={`w-3 h-3 shrink-0 ${
                                    isCurrent ? 'text-accent' : 'text-muted/40'
                                  }`}
                                />
                                <span className="flex-1 truncate">
                                  {b.name}
                                </span>
                                {isSwitching && (
                                  <span className="text-[10px] text-muted/50 animate-pulse">
                                    {t('switching')}
                                  </span>
                                )}
                                  {isCurrent && (
                                  <IconCheck className="w-3 h-3 text-accent shrink-0" />
                                )}
                              </button>
                              {isCurrent && !b.has_upstream && (
                                  <Tooltip content={t('publish_branch')}>
                                  <button
                                    type="button"
                                    onClick={() => void handlePublishBranch(b.name)}
                                    disabled={publishingBranch}
                                    className="cursor-pointer shrink-0 p-1 mr-1 rounded text-muted/50 hover:text-accent hover:bg-raised transition-colors disabled:opacity-40"
                                  >
                                    <IconArrowUp
                                      className={`w-3 h-3 ${
                                        publishingBranch ? 'animate-spin' : ''
                                      }`}
                                    />
                                  </button>
                                  </Tooltip>
                              )}
                              {!isCurrent && (
                                  <Tooltip content={t('delete_branch')}>
                                  <button
                                    type="button"
                                    onClick={() => void handleDeleteBranch(b.name)}
                                    disabled={!!deletingBranch}
                                    className={`cursor-pointer shrink-0 p-1 mr-1 rounded transition-colors disabled:opacity-40 ${
                                      b.has_upstream
                                        ? 'text-muted/50 hover:text-danger hover:bg-raised opacity-0 group-hover:opacity-100'
                                        : 'text-muted/60 hover:text-danger hover:bg-raised'
                                    }`}
                                  >
                                    <IconTrash
                                      className={`w-3 h-3 ${
                                        deletingBranch === b.name
                                          ? 'animate-spin'
                                          : ''
                                      }`}
                                    />
                                  </button>
                                  </Tooltip>
                              )}
                            </div>
                          )
                        })
                      )}
                      <div className="border-t border-outline/40 mt-1 pt-1">
                        {newBranchMode ? (
                          <div className="flex items-center gap-1">
                            <input
                              autoFocus
                              value={newBranchName}
                              onChange={(e) => setNewBranchName(e.target.value)}
                              onKeyDown={(e) => {
                                if (e.key === 'Enter') {
                                  void handleCreateBranch()
                                } else if (e.key === 'Escape') {
                                  setNewBranchMode(false)
                                  setNewBranchName('')
                                }
                              }}
                              placeholder={t('new_branch_placeholder')}
                              className="flex-1 min-w-0 bg-base border border-outline/50 rounded-item px-2 py-1.5 text-[11px] text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
                            />
                            <Tooltip content={t('new_branch_btn')} side="top">
                              <button
                                type="button"
                                onClick={() => void handleCreateBranch()}
                                disabled={!newBranchName.trim()}
                                className="focus-ring cursor-pointer shrink-0 p-1.5 rounded text-muted hover:text-mint hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                              >
                                <IconCheck className="w-3.5 h-3.5" />
                              </button>
                            </Tooltip>
                          </div>
                        ) : (
                          <button
                            type="button"
                            onClick={() => setNewBranchMode(true)}
                            className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-2 py-1.5 rounded-item text-[11px] font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
                          >
                            <IconPlus className="w-3 h-3 text-accent shrink-0" />
                            {t('new_branch_btn')}
                          </button>
                        )}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
                <Tooltip content={syncing ? t('syncing') : t('sync')}>
                <button
                  type="button"
                  onClick={() => void handleSync()}
                  disabled={syncing}
                  className="focus-ring cursor-pointer h-full inline-flex items-center justify-center px-3.5 rounded-item border border-outline/50 bg-raised/60 text-muted transition-colors hover:text-accent hover:bg-raised disabled:opacity-50 disabled:cursor-wait"
                >
                  <IconRefresh className={`w-4 h-4 ${syncing ? 'animate-spin' : ''}`} />
                </button>
                </Tooltip>
            </div>

            <div className="flex flex-col overflow-hidden rounded-item border border-outline/50 bg-base/40">
              {!remotesLoading && remotes.length > 0 && (
                  <Tooltip content={remotes[0].web_url} className="w-full">
                  <button
                    type="button"
                    onClick={() => void openUrl(remotes[0].web_url).catch(() => {})}
                    className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-2.5 py-2 text-left min-w-0 transition-colors hover:bg-raised/60"
                  >
                    <ProviderBadge webUrl={remotes[0].web_url} />
                    <span className="text-[11px] font-medium text-ink truncate flex-1">
                      {remotes[0].repo_name}
                    </span>
                    <IconExternalLink className="w-3 h-3 text-muted/40 shrink-0" />
                  </button>
                  </Tooltip>
              )}
              <textarea
                value={commitMessage}
                onChange={(e) => setCommitMessage(e.target.value)}
                placeholder={tc('git_commit_placeholder')}
                rows={3}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
                    e.preventDefault()
                    void handleCommit()
                  }
                }}
                className={`w-full bg-transparent px-2.5 py-2 text-xs text-ink placeholder:text-muted transition-colors focus:bg-raised focus:border-accent-dim outline-none resize-none ${
                  !remotesLoading && remotes.length > 0
                    ? 'border-t border-outline/50'
                    : ''
                }`}
              />
            </div>

            {!remotesLoading && remotes.length > 1 && (
              <div className="flex flex-col gap-1">
                {remotes.slice(1).map((r) => (
                  <div key={r.name} className="flex flex-col gap-0.5">
                    <span className="text-[9px] font-semibold uppercase tracking-wider text-muted/50 px-1">
                      {r.name}
                    </span>
                      <Tooltip content={r.web_url} className="w-full">
                      <button
                        type="button"
                        onClick={() => void openUrl(r.web_url).catch(() => {})}
                        className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-2.5 py-2 rounded-item border border-line/60 bg-base/40 hover:bg-raised hover:border-accent/40 transition-colors text-left min-w-0"
                      >
                        <IconGitBranch className="w-3 h-3 text-accent shrink-0" />
                        <span className="text-[11px] font-medium text-ink truncate flex-1">
                          {r.repo_name}
                        </span>
                        <IconExternalLink className="w-3 h-3 text-muted/50 shrink-0" />
                      </button>
                      </Tooltip>
                  </div>
                ))}
              </div>
            )}

              <Tooltip content={commitMessage.trim() ? t('commit') : tc('git_commit_placeholder')} side="top">
              <button
                type="button"
                onClick={() => void handleCommit()}
                disabled={!commitMessage.trim() || committing}
                className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-40 disabled:cursor-not-allowed text-xs font-medium text-white transition-colors"
              >
                <IconCheck className="w-3.5 h-3.5" />
                {committing ? t('committing') : t('commit')}
              </button>
              </Tooltip>
          </motion.div>

          {settings.git_worktrees_enabled && (
            <motion.div
              initial={{ opacity: 0, x: 24 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.2, ease: 'easeOut', delay: 0.3 }}
            >
              <Section title={t('worktrees_title')} count={worktrees.length} storageKey="git-sidebar-worktrees" defaultOpen={false}>
                <div className="flex flex-col gap-1">
                  {worktrees.length === 0 ? (
                    <div className="px-2.5 py-2">
                      <span className="text-[11px] text-muted/50">
                        {t('no_worktrees')}
                      </span>
                    </div>
                  ) : worktrees.map((wt) => {
                      const isCurrent = wt.path === project.path
                      const isSwitching = switchingWorktree === wt.path
                      const isMainWorktree = wt.path === project.path
                      return (
                        <div
                          key={wt.path}
                          className="group relative flex items-center gap-1.5 px-2.5 py-1.5 rounded-item border border-line/60 bg-base/40 hover:bg-raised/60 transition-colors"
                        >
                          <IconClone className={`w-3 h-3 shrink-0 ${isCurrent ? 'text-accent' : 'text-muted/40'}`} />
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-1.5">
                              <p className={`text-[11px] font-medium truncate ${isCurrent ? 'text-ink' : 'text-muted'}`}>
                                {wt.branch ?? wt.path.split('/').pop()}
                              </p>
                              {wt.has_uncommitted ? (
                                <Tooltip content={t('worktree_dirty')}>
                                  <span className="shrink-0 w-1.5 h-1.5 rounded-full bg-amber" />
                                </Tooltip>
                              ) : (
                                <Tooltip content={t('worktree_clean')}>
                                  <span className="shrink-0 w-1.5 h-1.5 rounded-full bg-mint/60" />
                                </Tooltip>
                              )}
                            </div>
                            <Tooltip content={wt.path} className="block">
                              <p className="text-[9px] font-mono text-muted/50 truncate">
                                {isMainWorktree ? t('worktree_current') : wt.path}
                              </p>
                            </Tooltip>
                          </div>
                          {isSwitching && (
                            <span className="text-[10px] text-muted/50 animate-pulse">
                              {t('switching')}
                            </span>
                          )}
                          {!isCurrent && !isSwitching && (
                            <Tooltip content={t('switch_worktree')}>
                              <button
                                type="button"
                                onClick={() => void handleSwitchWorktree(wt.path)}
                                disabled={!!switchingWorktree}
                                className="focus-ring cursor-pointer shrink-0 p-1 rounded text-muted/50 hover:text-accent hover:bg-raised transition-colors disabled:opacity-40"
                              >
                                <IconExternalLink className="w-3 h-3" />
                              </button>
                            </Tooltip>
                          )}
                          {!isMainWorktree && !isSwitching && (
                            <Tooltip content={t('remove_worktree')}>
                              <button
                                type="button"
                                onClick={() => setRemoveWorktreeConfirm(wt.path)}
                                disabled={!!removingWorktree}
                                className="focus-ring cursor-pointer shrink-0 p-1 rounded text-muted/50 hover:text-danger hover:bg-raised transition-colors disabled:opacity-40 opacity-0 group-hover:opacity-100"
                              >
                                <IconTrash className="w-3 h-3" />
                              </button>
                            </Tooltip>
                          )}
                          {isCurrent && (
                            <IconCheck className="w-3 h-3 text-accent shrink-0" />
                          )}
                        </div>
                      )
                    })}
                  </div>
                <div className="border-t border-outline/40 mt-1 pt-1">
                  {newWorktreeMode ? (
                    <div className="flex flex-col gap-1.5">
                      <input
                        autoFocus
                        value={newWorktreePath}
                        onChange={(e) => setNewWorktreePath(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            void handleCreateWorktree()
                          } else if (e.key === 'Escape') {
                            setNewWorktreeMode(false)
                            setNewWorktreePath('')
                            setNewWorktreeBranch('')
                          }
                        }}
                        placeholder={t('worktree_path_placeholder')}
                        className="w-full bg-base border border-outline/50 rounded-item px-2 py-1.5 text-[11px] text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
                      />
                      <div className="flex items-center gap-1.5">
                        <input
                          value={newWorktreeBranch}
                          onChange={(e) => setNewWorktreeBranch(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') {
                              void handleCreateWorktree()
                            } else if (e.key === 'Escape') {
                              setNewWorktreeMode(false)
                              setNewWorktreePath('')
                              setNewWorktreeBranch('')
                            }
                          }}
                          placeholder={t('worktree_branch_placeholder')}
                          className="flex-1 min-w-0 bg-base border border-outline/50 rounded-item px-2 py-1.5 text-[11px] text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
                        />
                        <Tooltip content={t('add_worktree_btn')} side="top">
                          <button
                            type="button"
                            onClick={() => void handleCreateWorktree()}
                            disabled={!newWorktreePath.trim() || creatingWorktree}
                            className="focus-ring cursor-pointer shrink-0 p-1.5 rounded text-muted hover:text-mint hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                          >
                            {creatingWorktree ? (
                              <Spinner />
                            ) : (
                              <IconCheck className="w-3.5 h-3.5" />
                            )}
                          </button>
                        </Tooltip>
                      </div>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => setNewWorktreeMode(true)}
                      className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-2 py-1.5 rounded-item text-[11px] font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
                    >
                      <IconPlus className="w-3 h-3 text-accent shrink-0" />
                      {t('add_worktree')}
                    </button>
                  )}
                </div>
              </Section>
            </motion.div>
          )}

          {stashes.length > 0 && (
            <motion.div
              initial={{ opacity: 0, x: 24 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.2, ease: 'easeOut', delay: 0.34 }}
            >
              <Section title={t('stashes_title')} count={stashes.length}>
              <button
                type="button"
                onClick={() => void handleStashPush()}
                disabled={!!stashBusy}
                className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-item border border-dashed border-outline/60 bg-base/40 text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-50 disabled:cursor-wait text-[11px] font-medium"
              >
                <IconDownload
                  className={`w-3.5 h-3.5 shrink-0 ${
                    stashBusy === 'push' ? 'animate-spin' : ''
                  }`}
                />
                {stashBusy === 'push' ? t('stashing') : t('stash')}
              </button>
              <div className="flex flex-col gap-1">
                {stashes.map((s) => (
                  <div
                    key={s.index}
                    onClick={() => setStashDiff({ index: s.index, message: s.message })}
                    className="group relative flex items-center gap-1.5 px-2.5 py-1.5 rounded-item border border-line/60 bg-base/40 hover:bg-raised/60 transition-colors cursor-pointer"
                  >
                    <IconDownload className="w-3 h-3 text-muted/40 shrink-0" />
                    <div className="flex-1 min-w-0">
                      <Tooltip content={s.message || `stash@{${s.index}}`} className="block">
                        <p className="text-[11px] text-ink truncate">
                          {s.message || `stash@{${s.index}}`}
                        </p>
                      </Tooltip>
                      <Tooltip content={`stash@{${s.index}}`} className="block">
                        <p className="text-[9px] font-mono text-muted/50">
                          stash@{s.index}
                        </p>
                      </Tooltip>
                    </div>
                    <div
                      onClick={(e) => e.stopPropagation()}
                      className="absolute right-1.5 top-1/2 -translate-y-1/2 flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity bg-base/80 rounded-md px-0.5 py-0.5"
                    >
                        <Tooltip content={t('apply_stash')}>
                        <button
                          type="button"
                          onClick={() => void handleStashApply(s.index)}
                          disabled={!!stashBusy}
                          className="focus-ring cursor-pointer p-1 rounded text-muted/60 hover:text-mint hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-wait"
                        >
                          <IconPlay
                            className={`w-3 h-3 ${
                              stashBusy === `apply:${s.index}`
                                ? 'animate-spin'
                                : ''
                            }`}
                          />
                        </button>
                        </Tooltip>
                        <Tooltip content={t('pop_stash')}>
                        <button
                          type="button"
                          onClick={() => void handleStashPop(s.index)}
                          disabled={!!stashBusy}
                          className="focus-ring cursor-pointer p-1 rounded text-muted/60 hover:text-amber hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-wait"
                        >
                          <IconChevronUp
                            className={`w-3 h-3 ${
                              stashBusy === `pop:${s.index}`
                                ? 'animate-spin'
                                : ''
                            }`}
                          />
                        </button>
                        </Tooltip>
                        <Tooltip content={t('drop_stash')}>
                        <button
                          type="button"
                          onClick={() => void handleStashDrop(s.index)}
                          disabled={!!stashBusy}
                          className="focus-ring cursor-pointer p-1 rounded text-muted/60 hover:text-danger hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-wait"
                        >
                          <IconTrash
                            className={`w-3 h-3 ${
                              stashBusy === `drop:${s.index}`
                                ? 'animate-spin'
                                : ''
                            }`}
                          />
                        </button>
                        </Tooltip>
                    </div>
                  </div>
                ))}
                </div>
              </Section>
            </motion.div>
          )}

          <motion.div
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2, ease: 'easeOut', delay: 0.4 }}
          >
            <Section
              title={t('changes_title')}
            count={changedFiles.length}
            onContextMenu={(e) => {
              e.preventDefault()
              setCtxMenu({ x: e.clientX, y: e.clientY })
            }}
          >
            {changedFiles.length > 0 && (
              <input
                type="text"
                value={changesQuery}
                onChange={(e) => setChangesQuery(e.target.value)}
                placeholder={t('filter_changes')}
                className="w-full bg-base/50 border border-outline/50 rounded-item px-2.5 py-1.5 text-[11px] text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors mb-1.5"
              />
            )}
            <div className="bg-base/50 border border-outline/50 rounded-item overflow-hidden">
              <div className="h-52 overflow-y-auto new-ui-scroll-viewport">
                {changesLoading ? (
                  <div className="flex items-center gap-2 px-3 py-2.5">
                    <span className="text-[11px] text-muted/50">
                      {t('checking_changes')}
                    </span>
                  </div>
                ) : changedFiles.length === 0 ? (
                  <div className="px-3 py-2.5">
                    <span className="text-[11px] text-muted/50">
                      {t('working_tree_clean')}
                    </span>
                  </div>
                ) : changesQuery.trim() !== '' &&
                  stagedFiles.length === 0 &&
                  unstagedFiles.length === 0 ? (
                  <div className="px-3 py-2.5">
                    <span className="text-[11px] text-muted/50">
                      {t('no_matching_changes')}
                    </span>
                  </div>
                ) : (
                  <div className="flex flex-col py-0.5">
                    {stagedFiles.length > 0 && (
                      <>
                        <div className="flex items-center justify-between px-2.5 pt-1.5 pb-0.5">
                          <span className="text-[9px] font-semibold uppercase tracking-wider text-muted/50">
                            {t('staged_changes')}
                          </span>
                          <span className="text-[9px] font-mono text-muted/50">
                            {stagedFiles.length}
                          </span>
                        </div>
                        {stagedFiles.map((f) => (
                          <ChangedFileRow
                            key={f.path}
                            file={f}
                            badgeChar={f.status[0]}
                            deleted={f.status[0] === 'D'}
                            onUnstage={() => void handleUnstageFile(f.path)}
                            onDiscard={() => void handleDiscardFile(f.path)}
                            onOpen={() => setDiffFile(f)}
                            stageLabel={t('stage_file')}
                            unstageLabel={t('unstage_file')}
                            discardLabel={t('discard_file')}
                          />
                        ))}
                      </>
                    )}
                    {unstagedFiles.length > 0 && (
                      <>
                        <div className="flex items-center justify-between px-2.5 pt-1.5 pb-0.5">
                          <span className="text-[9px] font-semibold uppercase tracking-wider text-muted/50">
                            {t('changes_title')}
                          </span>
                          <span className="text-[9px] font-mono text-muted/50">
                            {unstagedFiles.length}
                          </span>
                        </div>
                        {unstagedFiles.map((f) => (
                          <ChangedFileRow
                            key={f.path}
                            file={f}
                            badgeChar={f.status[1]}
                            deleted={f.status[1] === 'D'}
                            onStage={() => void handleStageFile(f.path)}
                            onDiscard={() => void handleDiscardFile(f.path)}
                            onOpen={() => setDiffFile(f)}
                            stageLabel={t('stage_file')}
                            unstageLabel={t('unstage_file')}
                            discardLabel={t('discard_file')}
                          />
                        ))}
                      </>
                    )}
                  </div>
                )}
              </div>
            </div>
            </Section>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2, ease: 'easeOut', delay: 0.46 }}
          >
            <Section title={t('commits_title')} count={commits.length}>
            {commitsLoading ? (
              <div className="px-2.5 py-2">
                <span className="text-[11px] text-muted/50">
                  {tc('loading')}
                </span>
              </div>
            ) : (
              <div className="bg-base/50 border border-outline/50 rounded-item overflow-hidden">
                <div className="max-h-64 overflow-y-auto new-ui-scroll-viewport">
                  <CommitGraph
                    commits={commits}
                    remoteUrl={remotes[0]?.web_url}
                    onOpenDetails={(hash) => setCommitHash(hash)}
                  />
                </div>
              </div>
            )}
            </Section>
          </motion.div>

        </div>
        )}
      </div>
        </motion.div>
      </AnimatePresence>

      {gitAuthFlow && (
        <GitAuthModal
          provider={gitAuthFlow}
          onClose={() => setGitAuthFlow(null)}
          onConnected={() => {
            setGitAuthFlow(null)
            void refreshGitAuth()
          }}
        />
      )}

      {diffFile && (
        <DiffViewerModal
          title={diffFile.path}
          subtitle={project.name}
          fetchDiff={() => api.gitFileDiff(project.path, diffFile.path)}
          onClose={() => setDiffFile(null)}
        />
      )}

      {stashDiff && (
        <DiffViewerModal
          title={`stash@{${stashDiff.index}}`}
          subtitle={stashDiff.message || undefined}
          fetchDiff={() => api.gitStashShow(project.path, stashDiff.index)}
          onClose={() => setStashDiff(null)}
        />
      )}

      {commitHash && (
        <CommitDetailsModal
          project={project}
          hash={commitHash}
          onClose={() => setCommitHash(null)}
        />
      )}

      {forcePushOpen && (
        <ConfirmDialog
          title={t('force_push_confirm_title')}
          description={t('force_push_confirm_desc')}
          confirmLabel={t('force_push')}
          variant="danger"
          onConfirm={() => void handleForcePush()}
          onCancel={() => setForcePushOpen(false)}
        />
      )}

      {removeWorktreeConfirm && (
        <ConfirmDialog
          title={t('remove_worktree')}
          description={t('remove_worktree_confirm_desc', { path: removeWorktreeConfirm })}
          confirmLabel={t('remove_worktree')}
          variant="danger"
          onConfirm={() => {
            const p = removeWorktreeConfirm
            setRemoveWorktreeConfirm(null)
            void handleRemoveWorktree(p)
          }}
          onCancel={() => setRemoveWorktreeConfirm(null)}
        />
      )}

      {createPortal(
        <AnimatePresence>
          {ctxMenu && (
            <motion.div
              key="ctx-menu"
              ref={ctxMenuRef}
              role="menu"
              initial={{ opacity: 0, scale: 0.96, y: -4 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: -4 }}
              transition={{ duration: 0.12, ease: 'easeOut' }}
              style={{ left: ctxMenu.x, top: ctxMenu.y }}
              className="fixed z-50 w-48 rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-1.5"
            >
              {stagedFiles.length > 0 && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => void handleUnstageAll()}
                  className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
                >
                  <IconChevronUp className="w-3.5 h-3.5 text-amber shrink-0" />
                  {t('unstage_all_changes')}
                </button>
              )}
              <button
                type="button"
                role="menuitem"
                onClick={() => void handleStageAll()}
                className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
              >
                <IconPlus className="w-3.5 h-3.5 text-mint shrink-0" />
                {t('stage_all')}
              </button>
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  setCtxMenu(null)
                  void handleStashPush()
                }}
                className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
              >
                <IconDownload className="w-3.5 h-3.5 text-amber shrink-0" />
                {t('stash')}
              </button>
              <button
                type="button"
                role="menuitem"
                onClick={() => void handleDiscardAll()}
                className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium text-red-400 hover:bg-red-500/10 hover:text-red-300 transition-colors"
              >
                <IconTrash className="w-3.5 h-3.5 shrink-0" />
                {t('discard_all')}
              </button>
              <div className="h-px bg-white/6 my-1" />
              <button
                type="button"
                role="menuitem"
                onClick={() => void handleUndoCommit()}
                className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
              >
                <IconHistory className="w-3.5 h-3.5 shrink-0" />
                {t('undo_last_commit')}
              </button>
              <button
                type="button"
                role="menuitem"
                onClick={() => void handleUndoPull()}
                className="focus-ring cursor-pointer w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium text-muted hover:bg-raised hover:text-ink transition-colors"
              >
                <IconCloudArrowDown className="w-3.5 h-3.5 shrink-0" />
                {t('undo_pull')}
              </button>
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </div>
  )
}
