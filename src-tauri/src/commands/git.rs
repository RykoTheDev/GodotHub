use godothub_core::git::{GitAheadBehind, GitBranchInfo, GitChangedFile, GitCommitDetails, GitDiffResult, GitInitOptions, GitInitOutcome, GitLogEntry, GitRemoteInfo, GitStashEntry, GitStatus, GitWorktree};
use std::collections::HashMap;

#[tauri::command]
pub async fn clone_repo(app: tauri::AppHandle, url: String, dest: String) -> Result<String, String> {
    let core = crate::core_handle(&app);
    godothub_core::git::clone_repo(core, url, dest).await
}

#[tauri::command]
pub async fn get_git_status(path: String) -> GitStatus {
    godothub_core::git::get_git_status(path).await
}

#[tauri::command]
pub async fn batch_git_status(paths: Vec<String>) -> HashMap<String, GitStatus> {
    godothub_core::git::batch_git_status(paths).await
}

#[tauri::command]
pub async fn open_terminal(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::git::open_terminal(core, path).await
}

#[tauri::command]
pub async fn git_pull(path: String) -> Result<String, String> {
    godothub_core::git::git_pull(path).await
}

#[tauri::command]
pub async fn git_fetch(path: String) -> Result<String, String> {
    godothub_core::git::git_fetch(path).await
}

#[tauri::command]
pub async fn git_push(path: String, force: Option<bool>) -> Result<String, String> {
    godothub_core::git::git_push(path, force).await
}

#[tauri::command]
pub async fn git_log_entries(path: String) -> Result<Vec<GitLogEntry>, String> {
    godothub_core::git::git_log_entries(path).await
}

#[tauri::command]
pub async fn git_list_remotes(path: String) -> Result<Vec<GitRemoteInfo>, String> {
    godothub_core::git::git_list_remotes(path).await
}

#[tauri::command]
pub async fn git_ahead_behind(path: String) -> Result<Option<GitAheadBehind>, String> {
    godothub_core::git::git_ahead_behind(path).await
}

#[tauri::command]
pub async fn git_show_commit(path: String, hash: String) -> Result<GitCommitDetails, String> {
    godothub_core::git::git_show_commit(path, hash).await
}

#[tauri::command]
pub async fn git_list_branches(path: String) -> Result<Vec<GitBranchInfo>, String> {
    godothub_core::git::git_list_branches(path).await
}

#[tauri::command]
pub async fn git_branch_publish(path: String, name: String) -> Result<(), String> {
    godothub_core::git::git_branch_publish(path, name).await
}

#[tauri::command]
pub async fn git_switch_branch(path: String, name: String) -> Result<(), String> {
    godothub_core::git::git_switch_branch(path, name).await
}

#[tauri::command]
pub async fn git_create_branch(path: String, name: String) -> Result<(), String> {
    godothub_core::git::git_create_branch(path, name).await
}

#[tauri::command]
pub async fn git_delete_branch(path: String, name: String) -> Result<(), String> {
    godothub_core::git::git_delete_branch(path, name).await
}

#[tauri::command]
pub async fn git_stash_push(path: String, paths: Option<Vec<String>>) -> Result<String, String> {
    godothub_core::git::git_stash_push(path, paths).await
}

#[tauri::command]
pub async fn git_stash_list(path: String) -> Result<Vec<GitStashEntry>, String> {
    godothub_core::git::git_stash_list(path).await
}

#[tauri::command]
pub async fn git_stash_apply(path: String, index: usize) -> Result<(), String> {
    godothub_core::git::git_stash_apply(path, index).await
}

#[tauri::command]
pub async fn git_stash_show(path: String, index: usize) -> Result<GitDiffResult, String> {
    godothub_core::git::git_stash_show(path, index).await
}

#[tauri::command]
pub async fn git_stash_pop(path: String, index: usize) -> Result<(), String> {
    godothub_core::git::git_stash_pop(path, index).await
}

#[tauri::command]
pub async fn git_stash_drop(path: String, index: usize) -> Result<(), String> {
    godothub_core::git::git_stash_drop(path, index).await
}

#[tauri::command]
pub async fn git_changed_files(path: String) -> Result<Vec<GitChangedFile>, String> {
    godothub_core::git::git_changed_files(path).await
}

#[tauri::command]
pub async fn git_discard_changes(path: String, remove_untracked: bool) -> Result<(), String> {
    godothub_core::git::git_discard_changes(path, remove_untracked).await
}

#[tauri::command]
pub async fn git_discard_file(path: String, file_path: String) -> Result<(), String> {
    godothub_core::git::git_discard_file(path, file_path).await
}

#[tauri::command]
pub async fn git_init_project(path: String, options: Option<GitInitOptions>) -> Result<GitInitOutcome, String> {
    godothub_core::git::git_init_project(path, options).await
}

#[tauri::command]
pub async fn git_is_available() -> bool {
    godothub_core::git::git_is_available().await
}

#[tauri::command]
pub async fn git_stage_file(path: String, file_path: String) -> Result<(), String> {
    godothub_core::git::git_stage_file(path, file_path).await
}

#[tauri::command]
pub async fn git_unstage_file(path: String, file_path: String) -> Result<(), String> {
    godothub_core::git::git_unstage_file(path, file_path).await
}

#[tauri::command]
pub async fn git_commit(path: String, message: String, amend: bool) -> Result<String, String> {
    godothub_core::git::git_commit(path, message, amend).await
}

#[tauri::command]
pub async fn git_file_diff(path: String, file_path: String) -> Result<GitDiffResult, String> {
    godothub_core::git::git_file_diff(path, file_path).await
}

#[tauri::command]
pub async fn git_undo_commit(path: String) -> Result<(), String> {
    godothub_core::git::git_undo_commit(path).await
}

#[tauri::command]
pub async fn git_undo_pull(path: String) -> Result<(), String> {
    godothub_core::git::git_undo_pull(path).await
}

#[tauri::command]
pub async fn git_merge_conflict_files(path: String) -> Result<Vec<String>, String> {
    godothub_core::git::git_merge_conflict_files(path).await
}

#[tauri::command]
pub async fn git_resolve_conflict_ours(path: String, file_path: String) -> Result<(), String> {
    godothub_core::git::git_resolve_conflict_ours(path, file_path).await
}

#[tauri::command]
pub async fn git_resolve_conflict_theirs(path: String, file_path: String) -> Result<(), String> {
    godothub_core::git::git_resolve_conflict_theirs(path, file_path).await
}

#[tauri::command]
pub async fn git_resolve_conflict_manual(path: String, file_path: String) -> Result<(), String> {
    godothub_core::git::git_resolve_conflict_manual(path, file_path).await
}

#[tauri::command]
pub async fn git_abort_merge(path: String) -> Result<(), String> {
    godothub_core::git::git_abort_merge(path).await
}

#[tauri::command]
pub async fn git_is_merging(path: String) -> Result<bool, String> {
    godothub_core::git::git_is_merging(path).await
}

#[tauri::command]
pub async fn git_worktree_list(path: String) -> Result<Vec<GitWorktree>, String> {
    godothub_core::git::git_worktree_list(path).await
}

#[tauri::command]
pub async fn git_worktree_switch(path: String, worktree_path: String) -> Result<(), String> {
    godothub_core::git::git_worktree_switch(path, worktree_path).await
}

#[tauri::command]
pub async fn git_worktree_add(path: String, worktree_path: String, branch: Option<String>) -> Result<(), String> {
    godothub_core::git::git_worktree_add(path, worktree_path, branch).await
}

#[tauri::command]
pub async fn git_worktree_remove(path: String, worktree_path: String, force: Option<bool>) -> Result<(), String> {
    godothub_core::git::git_worktree_remove(path, worktree_path, force).await
}
