import { invoke } from '@tauri-apps/api/core'
import type { GitAheadBehind, GitBranchInfo, GitChangedFile, GitCommitDetails, GitDiffResult, GitInitOptions, GitInitOutcome, GitLogEntry, GitRemoteInfo, GitStashEntry, GitStatus } from '../types'

export const gitApi = {
  status: (path: string) =>
    invoke<GitStatus>('get_git_status', { path }),
  batchStatus: (paths: string[]) =>
    invoke<Record<string, GitStatus>>('batch_git_status', { paths }),
  clone: (url: string, dest: string) =>
    invoke<string>('clone_repo', { url, dest }),
  pull: (path: string) =>
    invoke<string>('git_pull', { path }),
  fetch: (path: string) =>
    invoke<string>('git_fetch', { path }),
  push: (path: string, force?: boolean) =>
    invoke<string>('git_push', { path, force: force ?? false }),
  pushForce: (path: string) =>
    invoke<string>('git_push', { path, force: true }),
  log: (path: string) =>
    invoke<void>('git_log', { path }),
  logEntries: (path: string) =>
    invoke<GitLogEntry[]>('git_log_entries', { path }),
  listRemotes: (path: string) =>
    invoke<GitRemoteInfo[]>('git_list_remotes', { path }),
  aheadBehind: (path: string) =>
    invoke<GitAheadBehind | null>('git_ahead_behind', { path }),
  showCommit: (path: string, hash: string) =>
    invoke<GitCommitDetails>('git_show_commit', { path, hash }),
  startFsWatcher: (path: string) =>
    invoke<void>('start_git_fs_watcher', { path }),
  stopFsWatcher: () =>
    invoke<void>('stop_git_fs_watcher'),
  remoteUrl: (path: string) =>
    invoke<string>('git_remote_url', { path }),
  listBranches: (path: string) =>
    invoke<GitBranchInfo[]>('git_list_branches', { path }),
  switchBranch: (path: string, name: string) =>
    invoke<void>('git_switch_branch', { path, name }),
  branchPublish: (path: string, name: string) =>
    invoke<void>('git_branch_publish', { path, name }),
  createBranch: (path: string, name: string) =>
    invoke<void>('git_create_branch', { path, name }),
  deleteBranch: (path: string, name: string) =>
    invoke<void>('git_delete_branch', { path, name }),
  stashPush: (path: string, paths?: string[]) =>
    invoke<string>('git_stash_push', { path, paths }),
  stashList: (path: string) =>
    invoke<GitStashEntry[]>('git_stash_list', { path }),
  stashApply: (path: string, index: number) =>
    invoke<void>('git_stash_apply', { path, index }),
  stashShow: (path: string, index: number) =>
    invoke<GitDiffResult>('git_stash_show', { path, index }),
  stashPop: (path: string, index: number) =>
    invoke<void>('git_stash_pop', { path, index }),
  stashDrop: (path: string, index: number) =>
    invoke<void>('git_stash_drop', { path, index }),
  changedFiles: (path: string) =>
    invoke<GitChangedFile[]>('git_changed_files', { path }),
  discardChanges: (path: string) =>
    invoke<void>('git_discard_changes', { path }),
  discardFile: (path: string, filePath: string) =>
    invoke<void>('git_discard_file', { path, filePath }),
  init: (path: string) =>
    invoke<string>('git_init', { path }),
  initProject: (path: string, options?: GitInitOptions) =>
    invoke<GitInitOutcome>('git_init_project', {
      path,
      options: options ?? null,
    }),
  isAvailable: () =>
    invoke<boolean>('git_is_available'),
  stageFile: (path: string, filePath: string) =>
    invoke<void>('git_stage_file', { path, filePath }),
  unstageFile: (path: string, filePath: string) =>
    invoke<void>('git_unstage_file', { path, filePath }),
  commit: (path: string, message: string, amend?: boolean) =>
    invoke<string>('git_commit', { path, message, amend: amend ?? false }),
  setRemote: (path: string, url: string) =>
    invoke<void>('git_set_remote', { path, url }),
  removeRemote: (path: string) =>
    invoke<void>('git_remove_remote', { path }),
  fileDiff: (path: string, filePath: string) =>
    invoke<GitDiffResult>('git_file_diff', { path, filePath }),
  undoCommit: (path: string) =>
    invoke<void>('git_undo_commit', { path }),
  undoPull: (path: string) =>
    invoke<void>('git_undo_pull', { path }),
  mergeConflictFiles: (path: string) =>
    invoke<string[]>('git_merge_conflict_files', { path }),
  resolveConflictOurs: (path: string, filePath: string) =>
    invoke<void>('git_resolve_conflict_ours', { path, filePath }),
  resolveConflictTheirs: (path: string, filePath: string) =>
    invoke<void>('git_resolve_conflict_theirs', { path, filePath }),
  resolveConflictManual: (path: string, filePath: string) =>
    invoke<void>('git_resolve_conflict_manual', { path, filePath }),
  abortMerge: (path: string) =>
    invoke<void>('git_abort_merge', { path }),
  isMerging: (path: string) =>
    invoke<boolean>('git_is_merging', { path }),
  openTerminal: (path: string) =>
    invoke<void>('open_terminal', { path }),
}
