use crate::git_helpers;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};

#[cfg(any(target_os = "windows", target_os = "macos"))]
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitStatus {
    pub branch: Option<String>,
    pub has_uncommitted: bool,
    pub is_repo: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitLogEntry {
    pub hash: String,
    pub parents: Vec<String>,
    pub message: String,
    pub author: String,
    pub date: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitBranchInfo {
    pub name: String,
    pub is_current: bool,
    pub has_upstream: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitStashEntry {
    pub index: usize,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitChangedFile {
    pub path: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitRemoteInfo {
    pub name: String,
    pub web_url: String,
    pub repo_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitAheadBehind {
    pub ahead: usize,
    pub behind: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitCommitFile {
    pub path: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitCommitDetails {
    pub hash: String,
    pub message: String,
    pub author: String,
    pub date: String,
    pub files: Vec<GitCommitFile>,
    pub diff: GitDiffResult,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitInitOutcome {
    pub initialized: bool,
    pub committed: bool,
    pub branch: Option<String>,
    pub warning: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GitInitOptions {
    #[serde(default = "default_true")]
    pub gitignore: bool,
    #[serde(default = "default_true")]
    pub gitattributes: bool,
    #[serde(default)]
    pub readme: bool,
    #[serde(default)]
    pub license: Option<String>,
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitDiffResult {
    pub hunks: Vec<GitDiffHunk>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitDiffHunk {
    pub old_start: u32,
    pub old_lines: u32,
    pub new_start: u32,
    pub new_lines: u32,
    pub lines: Vec<GitDiffLine>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitDiffLine {
    pub kind: String,
    pub content: String,
}

fn check_is_repo(path: &str) -> bool {
    let dir = PathBuf::from(path);
    let mut current = Some(dir.as_path());
    while let Some(p) = current {
        if p.join(".git").exists() {
            return true;
        }
        current = p.parent();
    }
    false
}

fn parent_repo(path: &str) -> Option<PathBuf> {
    let dir = PathBuf::from(path);
    let parent = dir.parent()?;
    if parent.as_os_str().is_empty() {
        return None;
    }
    if parent.join(".git").exists() {
        Some(parent.to_path_buf())
    } else {
        None
    }
}

fn friendly_git_error(stderr: &str, path: &str) -> String {
    let lower = stderr.to_lowercase();

    if lower.contains("xcode-select")
        || lower.contains("no developer tools")
        || lower.contains("command line developer tools")
    {
        return format!(
            concat!(
                "macOS needs the Xcode Command Line Tools before Git will run.\n\n",
                "Install them, then initialize the repository from the Git panel:\n",
                "  xcode-select --install\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("please tell me who you are")
        || (lower.contains("user.email") && lower.contains("user.name"))
    {
        return format!(
            concat!(
                "Git doesn't know who you are yet, so it couldn't commit.\n\n",
                "Set your identity, then commit from the Git panel:\n",
                "  git config --global user.name \"Your Name\"\n",
                "  git config --global user.email \"you@example.com\"\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }

    if lower.contains("host key verification failed") {
        return format!(
            concat!(
                "SSH host key not verified.\n\n",
                "This happens when connecting to a server for the first time.\n",
                "To fix it, open a terminal and run:\n",
                "  ssh -T git@github.com\n",
                "(or your hosting provider). Type 'yes' to accept the key.\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("permission denied")
        || (lower.contains("publickey") && lower.contains("authentication"))
    {
        return format!(
            concat!(
                "SSH authentication failed.\n\n",
                "Your SSH key isn't set up correctly. To fix it:\n",
                "  1. Generate a key: ssh-keygen -t ed25519\n",
                "  2. Add it to your SSH agent: ssh-add ~/.ssh/id_ed25519\n",
                "  3. Add the public key to your Git hosting account\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("could not read from remote")
        || lower.contains("repository not found")
    {
        return format!(
            concat!(
                "Remote repository not found.\n\n",
                "The remote URL may be wrong or you don't have access.\n",
                "Check the URL with: git remote -v\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("authentication failed") {
        return format!(
            concat!(
                "Authentication failed.\n\n",
                "If you're using HTTPS, your credentials may be wrong or expired.\n",
                "To switch to SSH, run:\n",
                "  git remote set-url origin git@github.com:user/repo.git\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("connection refused") {
        return format!(
            concat!(
                "Connection refused.\n\n",
                "The remote server is not reachable.\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("could not resolve host") {
        return format!(
            concat!(
                "Could not resolve hostname.\n\n",
                "The remote server address couldn't be found.\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("timed out") || lower.contains("timeout") {
        return format!(
            concat!(
                "Connection timed out.\n\n",
                "The server took too long to respond.\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("merge conflict")
        || (lower.contains("conflict") && lower.contains("merge"))
        || lower.contains("automatic merge failed")
    {
        let conflicted = get_merge_conflict_files_for_path_internal(path).unwrap_or_default();
        if !conflicted.is_empty() {
            let files_list = conflicted.join("\n  · ");
            return format!(
                concat!(
                    "Merge conflicts detected.\n\n",
                    "The following files have conflicts:\n",
                    "  · {}\n\n",
                    "You can resolve them using the conflict resolver below,\n",
                    "or by opening a terminal and editing each file manually.\n",
                    "After resolving, stage and commit the changes.\n\n",
                    "Raw error:\n{}",
                ),
                files_list,
                stderr.trim()
            );
        }
        return format!(
            concat!(
                "Merge conflicts detected.\n\n",
                "There are conflicts that need to be resolved before the merge can complete.\n",
                "Open a terminal in the project folder and use 'git status' to see them.\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    if lower.contains("non-fast-forward") || lower.contains("[rejected]")
        || (lower.contains("failed to push") && lower.contains("fetch first"))
    {
        return format!(
            concat!(
                "Push rejected, your local branch is behind the remote.\n\n",
                "Use the Pull button first to get the latest changes, then try pushing again.\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }
    format!(
        concat!(
            "Git operation failed.\n\n",
            "Raw error:\n{}",
        ),
        stderr.trim()
    )
}

fn friendly_cmd(path: &str, args: &[&str]) -> Result<String, String> {
    let output = git_helpers::git_raw(path, args).map_err(|e| e.to_string())?;
    if !output.status.success() {
        let stderr = git_helpers::output_stderr(&output);
        return Err(friendly_git_error(&stderr, path));
    }
    Ok(git_helpers::output_stdout(&output).trim().to_string())
}

fn get_merge_conflict_files_for_path_internal(path: &str) -> Result<Vec<String>, String> {
    if !check_is_repo(path) {
        return Err("Not a git repository".into());
    }
    let stdout = git_helpers::git_cmd(path, ["diff", "--name-only", "--diff-filter=U"])
        .map_err(|e| e.to_string())?;
    Ok(stdout.lines().filter(|l| !l.trim().is_empty()).map(|l| l.trim().to_string()).collect())
}

fn repo_base_name(url: &str) -> String {
    let trimmed = url.trim().trim_end_matches('/').trim_end_matches(".git");
    trimmed
        .split('/')
        .next_back()
        .filter(|s| !s.is_empty())
        .unwrap_or("repo")
        .to_string()
}

fn get_git_status_for_path(path: &str) -> GitStatus {
    if !check_is_repo(path) {
        return GitStatus { branch: None, has_uncommitted: false, is_repo: false };
    }

    let output = git_helpers::git_raw(path, ["status", "--porcelain", "--branch"]).ok();

    match output {
        Some(out) => {
            let stdout = git_helpers::output_stdout(&out);
            let mut branch: Option<String> = None;
            let mut has_uncommitted = false;

            for (i, line) in stdout.lines().enumerate() {
                let trimmed = line.trim();
                if trimmed.is_empty() { continue; }
                if i == 0 && trimmed.starts_with("## ") {
                    let branch_info = &trimmed[3..];
                    if !branch_info.starts_with("HEAD (no branch)") && !branch_info.is_empty() {
                        let name = branch_info
                            .split("...").next()
                            .unwrap_or(branch_info)
                            .split('[').next()
                            .unwrap_or(branch_info)
                            .trim();
                        if !name.is_empty() {
                            branch = Some(name.to_string());
                        }
                    }
                } else {
                    has_uncommitted = true;
                }
            }
            GitStatus { branch, has_uncommitted, is_repo: true }
        }
        None => GitStatus { branch: None, has_uncommitted: false, is_repo: true },
    }
}

#[tauri::command]
pub async fn get_git_status(path: String) -> GitStatus {
    tokio::task::spawn_blocking(move || get_git_status_for_path(&path))
        .await
        .unwrap_or_else(|_| GitStatus {
            branch: None,
            has_uncommitted: false,
            is_repo: false,
        })
}

#[tauri::command]
pub async fn batch_git_status(paths: Vec<String>) -> HashMap<String, GitStatus> {
    const MAX_CONCURRENT: usize = 10;
    tokio::task::spawn_blocking(move || {
        let results = std::sync::Mutex::new(HashMap::with_capacity(paths.len()));
        for chunk in paths.chunks(MAX_CONCURRENT) {
            std::thread::scope(|s| {
                for p in chunk {
                    s.spawn(|| {
                        results.lock().unwrap().insert(p.clone(), get_git_status_for_path(p));
                    });
                }
            });
        }
        results.into_inner().unwrap()
    })
    .await
    .unwrap_or_default()
}

#[tauri::command]
pub async fn git_pull(path: String) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        friendly_cmd(&path, &["pull"])
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_push(path: String, force: Option<bool>) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let mut args = vec!["push"];
        if force.unwrap_or(false) {
            args.push("--force-with-lease");
        }
        friendly_cmd(&path, &args)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_log_entries(path: String) -> Result<Vec<GitLogEntry>, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let stdout = git_helpers::git_cmd(
            &path,
            [
                "log",
                "--max-count=100",
                "--topo-order",
                "--format=%H|||%P|||%an|||%ar|||%s",
                "--all",
            ],
        )
        .map_err(|e| e.to_string())?;

        let entries: Vec<GitLogEntry> = stdout
            .lines()
            .filter(|l| !l.trim().is_empty())
            .filter_map(|line| {
                let parts: Vec<&str> = line.splitn(5, "|||").collect();
                if parts.len() < 5 { return None; }
                Some(GitLogEntry {
                    hash: parts[0].to_string(),
                    parents: parts[1]
                        .split_whitespace()
                        .map(|p| p.to_string())
                        .collect(),
                    author: parts[2].to_string(),
                    date: parts[3].to_string(),
                    message: parts[4].to_string(),
                })
            })
            .collect();

        Ok(entries)
    })
    .await
    .map_err(|e| e.to_string())?
}

fn to_web_url(url: &str) -> String {
    let url = url.trim_end_matches(".git").trim_end_matches('/');
    if let Some(rest) = url.strip_prefix("git@") {
        if let Some((host, path)) = rest.split_once(':') {
            return format!("https://{}/{}", host, path.trim_start_matches('/'));
        }
    }
    if url.starts_with("https://") || url.starts_with("http://") {
        return url.to_string();
    }
    if let Some(rest) = url.strip_prefix("git://") {
        return format!("https://{}", rest);
    }
    url.to_string()
}

fn repo_label(url: &str) -> String {
    let web = to_web_url(url);
    let path = web.split("://").nth(1).unwrap_or(&web);
    let segments: Vec<&str> = path
        .split('/')
        .skip(1)
        .filter(|s| !s.is_empty())
        .collect();
    match segments.last() {
        Some(last) => last.to_string(),
        None => repo_base_name(url),
    }
}

#[tauri::command]
pub async fn git_ahead_behind(path: String) -> Result<Option<GitAheadBehind>, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let upstream = git_helpers::git_cmd(
            &path,
            ["rev-parse", "--abbrev-ref", "@{upstream}"],
        )
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty() && s != "@{upstream}");
        let Some(upstream) = upstream else {
            return Ok(None);
        };
        let out = git_helpers::git_cmd(
            &path,
            ["rev-list", "--left-right", "--count", &upstream, "...", "HEAD"],
        )
        .map_err(|e| e.to_string())?;
        let parts: Vec<&str> = out.split_whitespace().collect();
        if parts.len() < 2 {
            return Ok(None);
        }
        Ok(Some(GitAheadBehind {
            behind: parts[0].parse().unwrap_or(0),
            ahead: parts[1].parse().unwrap_or(0),
        }))
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_show_commit(path: String, hash: String) -> Result<GitCommitDetails, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let meta = git_helpers::git_cmd(
            &path,
            ["show", "-s", "--format=%H|||%an|||%ar|||%s", &hash],
        )
        .map_err(|e| e.to_string())?;
        let mut parts = meta.splitn(4, "|||");
        let hash = parts.next().unwrap_or(&hash).to_string();
        let author = parts.next().unwrap_or("").to_string();
        let date = parts.next().unwrap_or("").to_string();
        let message = parts.next().unwrap_or("").to_string();

        let files_out = git_helpers::git_cmd(
            &path,
            ["show", "--name-status", "--format=", &hash],
        )
        .map_err(|e| e.to_string())?;
        let files: Vec<GitCommitFile> = files_out
            .lines()
            .filter(|l| !l.trim().is_empty())
            .filter_map(|l| {
                let mut it = l.split('\t');
                let status = it.next()?.to_string();
                let path = it.next_back()?.to_string();
                Some(GitCommitFile { path, status })
            })
            .collect();

        let out = git_helpers::git_raw(&path, ["show", "--no-color", &hash])
            .map_err(|e| e.to_string())?;
        let stdout = git_helpers::output_stdout(&out);

        Ok(GitCommitDetails {
            hash,
            message,
            author,
            date,
            files,
            diff: parse_diff_text(&stdout),
        })
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_list_remotes(path: String) -> Result<Vec<GitRemoteInfo>, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let stdout = git_helpers::git_cmd(&path, ["remote", "-v"]).map_err(|e| e.to_string())?;
        let mut seen = HashSet::new();
        let mut remotes = Vec::new();
        for line in stdout.lines() {
            let mut parts = line.split_whitespace();
            let (Some(name), Some(url)) = (parts.next(), parts.next()) else {
                continue;
            };
            if !seen.insert(name.to_string()) {
                continue;
            }
            let url = url.to_string();
            remotes.push(GitRemoteInfo {
                web_url: to_web_url(&url),
                repo_name: repo_label(&url),
                name: name.to_string(),
            });
        }
        Ok(remotes)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_remote_url(path: String) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }

        let raw = git_helpers::git_cmd(&path, ["remote", "get-url", "origin"])
            .map_err(|_| "No remote 'origin' configured".to_string())?;

        if raw.is_empty() {
            return Err("No remote 'origin' configured".into());
        }

        Ok(to_web_url(&raw))
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_fetch(path: String) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["fetch"]).map_err(|e| e.to_string())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_list_branches(path: String) -> Result<Vec<GitBranchInfo>, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let stdout = git_helpers::git_cmd(
            &path,
            ["branch", "--format=%(refname:short)|||%(HEAD)|||%(upstream:short)"],
        )
        .map_err(|e| e.to_string())?;

        let branches: Vec<GitBranchInfo> = stdout
            .lines()
            .filter(|l| !l.trim().is_empty())
            .filter_map(|line| {
                let parts: Vec<&str> = line.splitn(3, "|||").collect();
                if parts.len() < 3 { return None; }
                Some(GitBranchInfo {
                    name: parts[0].to_string(),
                    is_current: parts[1].trim() == "*",
                    has_upstream: !parts[2].trim().is_empty(),
                })
            })
            .collect();

        Ok(branches)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_branch_publish(path: String, name: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["push", "-u", "origin", &name])
            .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_switch_branch(path: String, name: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["switch", &name]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_create_branch(path: String, name: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["branch", &name]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_delete_branch(path: String, name: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["branch", "-d", &name]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stash_push(path: String, paths: Option<Vec<String>>) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let mut args: Vec<&str> = vec!["stash", "push", "--include-untracked"];
        if let Some(files) = &paths {
            args.push("--");
            for file in files {
                args.push(file.as_str());
            }
        }
        git_helpers::git_cmd(&path, &args).map_err(|e| e.to_string())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stash_list(path: String) -> Result<Vec<GitStashEntry>, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let stdout = git_helpers::git_cmd(&path, ["stash", "list"])
            .map_err(|e| e.to_string())?;

        let stashes: Vec<GitStashEntry> = stdout
            .lines()
            .filter(|l| !l.trim().is_empty())
            .filter_map(|line| {
                if let Some(rest) = line.strip_prefix("stash@{") {
                    let parts: Vec<&str> = rest.splitn(2, '}').collect();
                    if parts.len() == 2 {
                        let index = parts[0].parse::<usize>().ok()?;
                        let message = parts[1].trim_start_matches(": ").to_string();
                        return Some(GitStashEntry { index, message });
                    }
                }
                None
            })
            .collect();

        Ok(stashes)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stash_apply(path: String, index: usize) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["stash", "apply", &format!("stash@{{{}}}", index)])
            .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stash_show(path: String, index: usize) -> Result<GitDiffResult, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let output = git_helpers::git_raw(
            &path,
            ["stash", "show", "-p", &format!("stash@{{{}}}", index)],
        )
        .map_err(|e| e.to_string())?;
        let stdout = git_helpers::output_stdout(&output);
        if stdout.trim().is_empty() {
            return Err(format!("No diff available for stash@{{{}}}", index));
        }
        Ok(parse_diff_text(&stdout))
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stash_pop(path: String, index: usize) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["stash", "pop", &format!("stash@{{{}}}", index)])
            .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stash_drop(path: String, index: usize) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["stash", "drop", &format!("stash@{{{}}}", index)])
            .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

fn parse_changed_files(stdout: &str) -> Vec<GitChangedFile> {
    stdout
        .lines()
        .filter(|l| !l.trim().is_empty())
        .filter_map(|line| {
            let status = line.get(..2)?.to_string();
            let raw_path = line.get(2..)?.trim_start().to_string();
            if status.trim().is_empty() && raw_path.is_empty() {
                return None;
            }
            let file_path = if raw_path.starts_with('"') && raw_path.ends_with('"') && raw_path.len() >= 2 {
                raw_path[1..raw_path.len() - 1].to_string()
            } else {
                raw_path
            };
            Some(GitChangedFile { path: file_path, status })
        })
        .collect()
}

fn reroot_to_project(
    files: Vec<GitChangedFile>,
    project: &Path,
    top: &Path,
) -> Vec<GitChangedFile> {
    let Ok(prefix) = project.strip_prefix(top) else {
        return files;
    };
    if prefix.as_os_str().is_empty() {
        return files;
    }
    files
        .into_iter()
        .filter_map(|f| {
            let rel = Path::new(&f.path).strip_prefix(prefix).ok()?;
            let path = if rel.as_os_str().is_empty() {
                project.file_name()?.to_string_lossy().to_string()
            } else {
                rel.to_string_lossy().to_string()
            };
            Some(GitChangedFile { path, status: f.status })
        })
        .collect()
}

fn check_ignored_files(path: &str, files: &[GitChangedFile]) -> HashSet<String> {
    let mut args: Vec<&str> = vec!["check-ignore", "--no-index", "--"];
    for f in files {
        args.push(f.path.as_str());
    }
    let output = git_helpers::git_raw(path, &args).ok();
    match output {
        Some(out) if out.status.success() => git_helpers::output_stdout(&out)
            .lines()
            .map(|l| l.trim().to_string())
            .collect(),
        _ => HashSet::new(),
    }
}

#[tauri::command]
pub async fn git_changed_files(path: String) -> Result<Vec<GitChangedFile>, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        let project = fs::canonicalize(&path).unwrap_or_else(|_| PathBuf::from(&path));
        let top = if project.join(".git").exists() {
            Some(project.clone())
        } else {
            git_helpers::git_cmd(&path, ["rev-parse", "--show-toplevel"])
                .ok()
                .map(|s| {
                    let top = PathBuf::from(s.trim());
                    fs::canonicalize(&top).unwrap_or(top)
                })
        };
        let nested = matches!(&top, Some(t) if *t != project);

        let args: &[&str] = if nested {
            &["status", "--porcelain", "-uall", "--", "."]
        } else {
            &["status", "--porcelain"]
        };
        let stdout = git_helpers::git_cmd(&path, args).map_err(|e| e.to_string())?;

        let mut files = parse_changed_files(&stdout);
        if nested {
            if let Some(top) = top {
                files = reroot_to_project(files, &project, &top);
            }
        }
        if !files.is_empty() {
            let ignored = check_ignored_files(&path, &files);
            files.retain(|f| !ignored.contains(&f.path));
        }

        Ok(files)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_discard_changes(path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["restore", "."]).map_err(|e| e.to_string())?;
        let _ = git_helpers::git_cmd(&path, ["clean", "-fd"]);
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_discard_file(path: String, file_path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["restore", "--staged", "--worktree", &file_path])
            .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_init(path: String) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        let dir = PathBuf::from(&path);
        if !dir.exists() {
            return Err("Path does not exist".into());
        }
        if check_is_repo(&path) {
            return Err("Already a git repository".into());
        }

        let stdout = git_helpers::git_command()
            .args(["init", &path])
            .output()
            .map_err(|e| format!("Failed to init git: {e}"))
            .and_then(|out| {
                if !out.status.success() {
                    let stderr = String::from_utf8_lossy(&out.stderr).trim().to_string();
                    return Err(format!("Git init failed: {stderr}"));
                }
                Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
            })?;
        Ok(stdout)
    })
    .await
    .map_err(|e| e.to_string())?
}

const GODOT_GITIGNORE: &str = "\
# Godot 4+ specific ignores
.godot/
/android/

# Godot-specific ignores
.import/
export.cfg
export_presets.cfg

# Imported translations (automatically generated from CSV files)
*.translation

# Mono-specific ignores
.mono/
data_*/
mono_crash.*.json

# Editor and export output
.vscode/
/build/
/builds/

# OS-generated files
.DS_Store
Thumbs.db
";

const GODOT_GITATTRIBUTES: &str = "\
# Normalize line endings for every file Git considers text.
* text=auto eol=lf
";

#[cfg(unix)]
fn is_executable(path: &Path) -> bool {
    use std::os::unix::fs::PermissionsExt;
    fs::metadata(path)
        .map(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

#[cfg(not(unix))]
fn is_executable(path: &Path) -> bool {
    path.is_file()
}

#[cfg(target_os = "windows")]
fn executable_names(name: &str) -> Vec<String> {
    std::env::var("PATHEXT")
        .unwrap_or_else(|_| ".EXE;.CMD;.BAT;.COM".to_string())
        .split(';')
        .map(|ext| ext.trim())
        .filter(|ext| !ext.is_empty())
        .map(|ext| format!("{name}{}", ext.to_lowercase()))
        .collect()
}

#[cfg(not(target_os = "windows"))]
fn executable_names(name: &str) -> Vec<String> {
    vec![name.to_string()]
}

fn git_is_available_sync() -> bool {
    let Some(path_var) = std::env::var_os("PATH") else {
        return false;
    };
    let names = executable_names("git");
    std::env::split_paths(&path_var)
        .any(|dir| names.iter().any(|name| is_executable(&dir.join(name))))
}

#[tauri::command]
pub async fn git_is_available() -> bool {
    tokio::task::spawn_blocking(git_is_available_sync)
        .await
        .unwrap_or(false)
}

#[tauri::command]
pub async fn git_init_project(
    path: String,
    options: Option<GitInitOptions>,
) -> Result<GitInitOutcome, String> {
    tokio::task::spawn_blocking(move || {
        let dir = PathBuf::from(&path);
        if !dir.is_dir() {
            return Err("Path does not exist".into());
        }

        if dir.join(".git").exists() {
            return Ok(GitInitOutcome {
                initialized: false,
                committed: false,
                branch: None,
                warning: None,
            });
        }

        if let Some(parent) = parent_repo(&path) {
            return Ok(GitInitOutcome {
                initialized: false,
                committed: false,
                branch: None,
                warning: Some(format!(
                    "No repository was created: the folder above this one is already a Git repository ({}). Commit the project from there instead.",
                    parent.display()
                )),
            });
        }

        if !git_is_available_sync() {
            return Err("Git isn't installed, or it isn't on your PATH.".into());
        }

        if let Err(e) = git_helpers::git_cmd(&path, ["init"]) {
            return Err(friendly_git_error(&e.to_string(), &path));
        }

        let opts = options.unwrap_or_default();

        if opts.gitignore {
            let file = dir.join(".gitignore");
            if !file.exists() {
                fs::write(&file, GODOT_GITIGNORE)
                    .map_err(|e| format!("Failed to write .gitignore: {e}"))?;
            }
        }
        if opts.gitattributes {
            let file = dir.join(".gitattributes");
            if !file.exists() {
                fs::write(&file, GODOT_GITATTRIBUTES)
                    .map_err(|e| format!("Failed to write .gitattributes: {e}"))?;
            }
        }
        if opts.readme {
            let file = dir.join("README.md");
            if !file.exists() {
                let project_name = dir
                    .file_name()
                    .map(|n| n.to_string_lossy().to_string())
                    .unwrap_or_else(|| "My Project".to_string());
                let readme = format!("# {}\n\nA Godot project\n", project_name);
                fs::write(&file, readme).map_err(|e| format!("Failed to write README.md: {e}"))?;
            }
        }
        if let Some(license_id) = &opts.license {
            let project_name = dir
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_default();
            if let Some(text) = crate::licenses::license_text(license_id, &project_name) {
                let file = dir.join("LICENSE");
                if !file.exists() {
                    fs::write(&file, text)
                        .map_err(|e| format!("Failed to write LICENSE: {e}"))?;
                }
            }
        }

        if let Err(e) = git_helpers::git_cmd(&path, ["add", "."]) {
            return Ok(GitInitOutcome {
                initialized: true,
                committed: false,
                branch: None,
                warning: Some(friendly_git_error(&e.to_string(), &path)),
            });
        }

        let commit = git_helpers::git_raw(&path, ["commit", "-m", "Initial commit"])
            .map_err(|e| e.to_string())?;
        if !commit.status.success() {
            let stderr = git_helpers::output_stderr(&commit);
            let detail = if stderr.trim().is_empty() {
                git_helpers::output_stdout(&commit)
            } else {
                stderr
            };
            return Ok(GitInitOutcome {
                initialized: true,
                committed: false,
                branch: None,
                warning: Some(friendly_git_error(&detail, &path)),
            });
        }

        let mut branch = git_helpers::git_cmd(&path, ["rev-parse", "--abbrev-ref", "HEAD"]).ok();
        if branch.as_deref() == Some("master")
            && git_helpers::git_cmd(&path, ["branch", "-M", "main"]).is_ok()
        {
            branch = Some("main".to_string());
        }

        Ok(GitInitOutcome {
            initialized: true,
            committed: true,
            branch,
            warning: None,
        })
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_stage_file(path: String, file_path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["add", &file_path]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_unstage_file(path: String, file_path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["restore", "--staged", &file_path]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_commit(path: String, message: String, amend: bool) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }

        let mut args = vec!["commit", "-m", &message];
        if amend {
            args.push("--amend");
        }

        let output = git_helpers::git_raw(&path, &args).map_err(|e| e.to_string())?;

        if !output.status.success() {
            let stderr = git_helpers::output_stderr(&output).trim().to_string();
            let stdout = git_helpers::output_stdout(&output).trim().to_string();
            let detail = if !stderr.is_empty() { stderr }
                        else if !stdout.is_empty() { stdout }
                        else { "Unknown error, run 'git commit' in a terminal for more details.".to_string() };
            return Err(format!("Commit failed: {detail}"));
        }

        Ok(git_helpers::output_stdout(&output).trim().to_string())
    })
    .await
    .map_err(|e| e.to_string())?
}#[tauri::command]
pub async fn git_set_remote(path: String, url: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }

        let remotes = git_helpers::git_cmd(&path, ["remote"]).unwrap_or_default();
        let has_origin = remotes.lines().any(|l| l.trim() == "origin");

        let verb = if has_origin { "set-url" } else { "add" };
        git_helpers::git_cmd(&path, ["remote", verb, "origin", &url]).map_err(|e| e.to_string())?;

        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_remove_remote(path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["remote", "remove", "origin"]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_undo_commit(path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["reset", "--soft", "HEAD~1"]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_undo_pull(path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["reset", "--keep", "ORIG_HEAD"]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_abort_merge(path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["merge", "--abort"]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_is_merging(path: String) -> Result<bool, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }

        let git_dir = git_helpers::git_cmd(&path, ["rev-parse", "--git-dir"])
            .map_err(|e| e.to_string())?;
        let base = std::path::PathBuf::from(&path).join(&git_dir);

        Ok(base.join("MERGE_HEAD").exists()
            || base.join("rebase-merge").exists()
            || base.join("rebase-apply").exists())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_merge_conflict_files(path: String) -> Result<Vec<String>, String> {
    tokio::task::spawn_blocking(move || get_merge_conflict_files_for_path_internal(&path))
        .await
        .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_resolve_conflict_ours(path: String, file_path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["checkout", "--ours", &file_path]).map_err(|e| e.to_string())?;
        git_helpers::git_cmd(&path, ["add", &file_path]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_resolve_conflict_theirs(path: String, file_path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["checkout", "--theirs", &file_path]).map_err(|e| e.to_string())?;
        git_helpers::git_cmd(&path, ["add", &file_path]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_resolve_conflict_manual(path: String, file_path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }
        git_helpers::git_cmd(&path, ["add", &file_path]).map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn clone_repo(app: tauri::AppHandle, url: String, dest: String) -> Result<String, String> {
    tokio::task::spawn_blocking(move || {
        if !url.contains("://") && !url.contains('@') {
            return Err("Not a valid git URL".into());
        }

        let dest_path = PathBuf::from(&dest);
        let settings = crate::settings::read_settings(&app);
        let folder_name = crate::projects::apply_naming_convention(
            &repo_base_name(&url),
            &settings.directory_naming_convention,
        );

        let clone_target = dest_path.join(&folder_name);
        if clone_target.exists() {
            return Err(format!("Folder '{folder_name}' already exists at this location"));
        }

        let output = git_helpers::git_command()
            .arg("clone")
            .arg(&url)
            .arg(&clone_target)
            .output()
            .map_err(|e| format!("Failed to run git: {e}"))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
            return Err(format!("Git clone failed: {stderr}"));
        }

        Ok(clone_target.to_string_lossy().to_string())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn open_terminal(_app: tauri::AppHandle, path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        let dir = PathBuf::from(&path);
        if !dir.exists() {
            return Err("Path does not exist".into());
        }

        #[cfg(target_os = "windows")]
        {
            let result = Command::new("wt").arg("-d").arg(&path).spawn();
            if result.is_err() {
                Command::new("cmd")
                    .args(["/C", "start", "", "cmd"])
                    .current_dir(&dir)
                    .spawn()
                    .map_err(|e| e.to_string())?;
            }
        }

        #[cfg(target_os = "macos")]
        {
            Command::new("open")
                .args(["-a", "Terminal", &path])
                .spawn()
                .map_err(|e| e.to_string())?;
        }

        #[cfg(all(unix, not(target_os = "macos")))]
        {
            let script = format!(
                "#!/bin/sh\ncd '{}' && exec ${{SHELL:-bash}}\n",
                path.replace('\'', "'\\''")
            );
            crate::terminal::spawn_shell_script_in_terminal(&_app, &script)?;
        }

        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_log(_app: tauri::AppHandle, path: String) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        let dir = PathBuf::from(&path);
        if !dir.exists() {
            return Err("Path does not exist".into());
        }
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }

        #[cfg(target_os = "windows")]
        {
            Command::new("cmd")
                .args(["/C", "start", "Git Log", "cmd", "/K", "git log --oneline --graph -25 --all"])
                .current_dir(&dir)
                .spawn()
                .map_err(|e| e.to_string())?;
        }

        #[cfg(target_os = "macos")]
        {
            let script = format!(
                r#"tell application "Terminal"
                    activate
                    do script "cd \"{}\" && git log --oneline --graph -25 --all"
                end tell"#,
                path.replace('"', "\\\"")
            );
            Command::new("osascript")
                .arg("-e")
                .arg(&script)
                .spawn()
                .map_err(|e| e.to_string())?;
        }

        #[cfg(all(unix, not(target_os = "macos")))]
        {
            let script = format!(
                "#!/bin/sh\ncd '{}' && git log --oneline --graph -25 --all\nexec sh\n",
                path.replace('\'', "'\\''")
            );
            crate::terminal::spawn_shell_script_in_terminal(&_app, &script)?;
        }

        Ok(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn git_file_diff(path: String, file_path: String) -> Result<GitDiffResult, String> {
    tokio::task::spawn_blocking(move || {
        if !check_is_repo(&path) {
            return Err("Not a git repository".into());
        }

        let output = git_helpers::git_raw(&path, ["diff", "--no-color", "--", &file_path])
            .map_err(|e| e.to_string())?;
        let stdout = git_helpers::output_stdout(&output);

        let diff_text = if stdout.trim().is_empty() {
            let cached = git_helpers::git_raw(&path, ["diff", "--cached", "--no-color", "--", &file_path])
                .ok();
            match cached {
                Some(c) => git_helpers::output_stdout(&c),
                None => stdout,
            }
        } else {
            stdout
        };

        if diff_text.trim().is_empty() {
            return Err(format!("No diff available for '{}'", file_path));
        }

        Ok(parse_diff_text(&diff_text))
    })
    .await
    .map_err(|e| e.to_string())?
}

fn parse_diff_text(diff_text: &str) -> GitDiffResult {
    let mut result = GitDiffResult { hunks: Vec::new() };
    let mut current_hunk: Option<GitDiffHunk> = None;

    for line in diff_text.lines() {
        if let Some(header) = line.strip_prefix("@@ ") {
            let Some((old_range, new_range)) = header
                .split(" @@")
                .next()
                .and_then(|r| r.split_once(' '))
            else {
                continue;
            };

            let old_parts: Vec<&str> = old_range.split(',').collect();
            let new_parts: Vec<&str> = new_range.split(',').collect();
            let old_start = old_parts[0].trim_start_matches('-').parse::<u32>().unwrap_or(1);
            let old_lines = old_parts.get(1).and_then(|s| s.parse::<u32>().ok()).unwrap_or(1);
            let new_start = new_parts[0].trim_start_matches('+').parse::<u32>().unwrap_or(1);
            let new_lines = new_parts.get(1).and_then(|s| s.parse::<u32>().ok()).unwrap_or(1);

            if let Some(hunk) = current_hunk.take() {
                result.hunks.push(hunk);
            }
            current_hunk = Some(GitDiffHunk {
                old_start,
                old_lines,
                new_start,
                new_lines,
                lines: Vec::new(),
            });
        } else if let Some(hunk) = &mut current_hunk {
            if line.starts_with('+') {
                hunk.lines.push(GitDiffLine { kind: "add".into(), content: line.strip_prefix('+').unwrap().to_string() });
            } else if line.starts_with('-') {
                hunk.lines.push(GitDiffLine { kind: "delete".into(), content: line.strip_prefix('-').unwrap().to_string() });
            } else if line.starts_with(' ') {
                hunk.lines.push(GitDiffLine { kind: "context".into(), content: line.strip_prefix(' ').unwrap().to_string() });
            }
        }
    }

    if let Some(hunk) = current_hunk.take() {
        result.hunks.push(hunk);
    }
    result
}
