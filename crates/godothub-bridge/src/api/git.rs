#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn clone_repo(url: String, dest: String) -> Result<String, CoreError> {
    let app = app()?;
    godothub_core::git::clone_repo(app, url, dest).await.map_err(CoreError::from)
}

pub async fn get_git_status(path: String) -> Result<GitStatus, CoreError> {
    Ok(godothub_core::git::get_git_status(path).await)
}

pub async fn batch_git_status(paths: Vec<String>) -> Result<HashMap<String, GitStatus>, CoreError> {
    Ok(godothub_core::git::batch_git_status(paths).await)
}

pub async fn open_terminal(path: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::git::open_terminal(app, path).await.map_err(CoreError::from)
}

pub async fn git_pull(path: String) -> Result<String, CoreError> {
    godothub_core::git::git_pull(path).await.map_err(CoreError::from)
}

pub async fn git_fetch(path: String) -> Result<String, CoreError> {
    godothub_core::git::git_fetch(path).await.map_err(CoreError::from)
}

pub async fn git_push(path: String, force: Option<bool>) -> Result<String, CoreError> {
    godothub_core::git::git_push(path, force).await.map_err(CoreError::from)
}

pub async fn git_log_entries(path: String) -> Result<Vec<GitLogEntry>, CoreError> {
    godothub_core::git::git_log_entries(path).await.map_err(CoreError::from)
}

pub async fn git_list_remotes(path: String) -> Result<Vec<GitRemoteInfo>, CoreError> {
    godothub_core::git::git_list_remotes(path).await.map_err(CoreError::from)
}

pub async fn git_ahead_behind(path: String) -> Result<Option<GitAheadBehind>, CoreError> {
    godothub_core::git::git_ahead_behind(path).await.map_err(CoreError::from)
}

pub async fn git_show_commit(path: String, hash: String) -> Result<GitCommitDetails, CoreError> {
    godothub_core::git::git_show_commit(path, hash).await.map_err(CoreError::from)
}

pub async fn git_list_branches(path: String) -> Result<Vec<GitBranchInfo>, CoreError> {
    godothub_core::git::git_list_branches(path).await.map_err(CoreError::from)
}

pub async fn git_branch_publish(path: String, name: String) -> Result<(), CoreError> {
    godothub_core::git::git_branch_publish(path, name).await.map_err(CoreError::from)
}

pub async fn git_switch_branch(path: String, name: String) -> Result<(), CoreError> {
    godothub_core::git::git_switch_branch(path, name).await.map_err(CoreError::from)
}

pub async fn git_create_branch(path: String, name: String) -> Result<(), CoreError> {
    godothub_core::git::git_create_branch(path, name).await.map_err(CoreError::from)
}

pub async fn git_delete_branch(path: String, name: String) -> Result<(), CoreError> {
    godothub_core::git::git_delete_branch(path, name).await.map_err(CoreError::from)
}

pub async fn git_stash_push(path: String, paths: Option<Vec<String>>) -> Result<String, CoreError> {
    godothub_core::git::git_stash_push(path, paths).await.map_err(CoreError::from)
}

pub async fn git_stash_list(path: String) -> Result<Vec<GitStashEntry>, CoreError> {
    godothub_core::git::git_stash_list(path).await.map_err(CoreError::from)
}

pub async fn git_stash_apply(path: String, index: usize) -> Result<(), CoreError> {
    godothub_core::git::git_stash_apply(path, index).await.map_err(CoreError::from)
}

pub async fn git_stash_show(path: String, index: usize) -> Result<GitDiffResult, CoreError> {
    godothub_core::git::git_stash_show(path, index).await.map_err(CoreError::from)
}

pub async fn git_stash_pop(path: String, index: usize) -> Result<(), CoreError> {
    godothub_core::git::git_stash_pop(path, index).await.map_err(CoreError::from)
}

pub async fn git_stash_drop(path: String, index: usize) -> Result<(), CoreError> {
    godothub_core::git::git_stash_drop(path, index).await.map_err(CoreError::from)
}

pub async fn git_changed_files(path: String) -> Result<Vec<GitChangedFile>, CoreError> {
    godothub_core::git::git_changed_files(path).await.map_err(CoreError::from)
}

pub async fn git_discard_changes(path: String, remove_untracked: bool) -> Result<(), CoreError> {
    godothub_core::git::git_discard_changes(path, remove_untracked).await.map_err(CoreError::from)
}

pub async fn git_discard_file(path: String, file_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_discard_file(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_init_project(path: String, options: Option<GitInitOptions>) -> Result<GitInitOutcome, CoreError> {
    godothub_core::git::git_init_project(path, options).await.map_err(CoreError::from)
}

pub async fn git_is_available() -> Result<bool, CoreError> {
    Ok(godothub_core::git::git_is_available().await)
}

pub async fn git_stage_file(path: String, file_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_stage_file(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_unstage_file(path: String, file_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_unstage_file(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_commit(path: String, message: String, amend: bool) -> Result<String, CoreError> {
    godothub_core::git::git_commit(path, message, amend).await.map_err(CoreError::from)
}

pub async fn git_file_diff(path: String, file_path: String) -> Result<GitDiffResult, CoreError> {
    godothub_core::git::git_file_diff(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_undo_commit(path: String) -> Result<(), CoreError> {
    godothub_core::git::git_undo_commit(path).await.map_err(CoreError::from)
}

pub async fn git_undo_pull(path: String) -> Result<(), CoreError> {
    godothub_core::git::git_undo_pull(path).await.map_err(CoreError::from)
}

pub async fn git_merge_conflict_files(path: String) -> Result<Vec<String>, CoreError> {
    godothub_core::git::git_merge_conflict_files(path).await.map_err(CoreError::from)
}

pub async fn git_resolve_conflict_ours(path: String, file_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_resolve_conflict_ours(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_resolve_conflict_theirs(path: String, file_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_resolve_conflict_theirs(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_resolve_conflict_manual(path: String, file_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_resolve_conflict_manual(path, file_path).await.map_err(CoreError::from)
}

pub async fn git_abort_merge(path: String) -> Result<(), CoreError> {
    godothub_core::git::git_abort_merge(path).await.map_err(CoreError::from)
}

pub async fn git_is_merging(path: String) -> Result<bool, CoreError> {
    godothub_core::git::git_is_merging(path).await.map_err(CoreError::from)
}

pub async fn git_worktree_list(path: String) -> Result<Vec<GitWorktree>, CoreError> {
    godothub_core::git::git_worktree_list(path).await.map_err(CoreError::from)
}

pub async fn git_worktree_switch(path: String, worktree_path: String) -> Result<(), CoreError> {
    godothub_core::git::git_worktree_switch(path, worktree_path).await.map_err(CoreError::from)
}

pub async fn git_worktree_add(path: String, worktree_path: String, branch: Option<String>) -> Result<(), CoreError> {
    godothub_core::git::git_worktree_add(path, worktree_path, branch).await.map_err(CoreError::from)
}

pub async fn git_worktree_remove(path: String, worktree_path: String, force: Option<bool>) -> Result<(), CoreError> {
    godothub_core::git::git_worktree_remove(path, worktree_path, force).await.map_err(CoreError::from)
}
