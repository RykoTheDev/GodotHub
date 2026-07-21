use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::Command;

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[cfg(target_os = "windows")]
const CREATE_NO_WINDOW: u32 = 0x08000000;

fn cmd() -> Command {
    #[allow(unused_mut)]
    let mut command = Command::new("git");
    #[cfg(target_os = "windows")]
    command.creation_flags(CREATE_NO_WINDOW);
    command
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitStatus {
    pub branch: Option<String>,
    pub has_uncommitted: bool,
    pub is_repo: bool,
}

fn check_is_repo(path: &str) -> bool {
    let dir = PathBuf::from(path);
    if dir.join(".git").exists() {
        return true;
    }
    let mut current = Some(dir.as_path());
    while let Some(p) = current {
        if p.join(".git").exists() {
            return true;
        }
        current = p.parent();
    }
    false
}

fn friendly_git_error(stderr: &str) -> String {
    let lower = stderr.to_lowercase();

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
                "  3. Add the public key to your Git hosting account\n",
                "     (e.g. GitHub Settings > SSH and GPG keys)\n\n",
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
                "Check the URL with:\n",
                "  git remote -v\n\n",
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
                "The remote server is not reachable. This could mean:\n",
                "  - The server is down\n",
                "  - You're behind a firewall\n",
                "  - The port is wrong\n",
                "  - You need a VPN or proxy\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }

    if lower.contains("could not resolve host") {
        return format!(
            concat!(
                "Could not resolve hostname.\n\n",
                "The remote server address couldn't be found. This usually means:\n",
                "  - The URL is incorrect\n",
                "  - You're offline\n",
                "  - DNS is not working\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }

    if lower.contains("timed out") || lower.contains("timeout") {
        return format!(
            concat!(
                "Connection timed out.\n\n",
                "The server took too long to respond. This could mean:\n",
                "  - You're offline or have a slow connection\n",
                "  - The server is busy or down\n",
                "  - A firewall is blocking the connection\n\n",
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
                "The remote branch has commits that you don't have locally yet.\n",
                "To fix this, use the Pull button first to get the latest changes,\n",
                "then try pushing again.\n\n",
                "If you're sure you want to overwrite the remote (force push),\n",
                "open a terminal and run:\n",
                "  git push --force-with-lease\n\n",
                "Raw error:\n{}",
            ),
            stderr.trim()
        );
    }

    format!(
        concat!(
            "Git operation failed.\n\n",
            "This is a generic git error. Open a terminal in the project folder\n",
            "and run the command manually to see the full details.\n\n",
            "Raw error:\n{}",
        ),
        stderr.trim()
    )
}

fn get_git_status_for_path(path: &str) -> GitStatus {
    if !check_is_repo(path) {
        return GitStatus {
            branch: None,
            has_uncommitted: false,
            is_repo: false,
        };
    }

    let branch = cmd()
        .args(["-C", path, "branch", "--show-current"])
        .output()
        .ok()
        .and_then(|out| {
            if out.status.success() {
                let name = String::from_utf8_lossy(&out.stdout).trim().to_string();
                if name.is_empty() {
                    None
                } else {
                    Some(name)
                }
            } else {
                None
            }
        });

    let has_uncommitted = cmd()
        .args(["-C", path, "status", "--porcelain"])
        .output()
        .ok()
        .map(|out| {
            let text = String::from_utf8_lossy(&out.stdout);
            !text.trim().is_empty()
        })
        .unwrap_or(false);

    GitStatus {
        branch,
        has_uncommitted,
        is_repo: true,
    }
}

#[tauri::command]
pub fn get_git_status(path: String) -> GitStatus {
    get_git_status_for_path(&path)
}

#[tauri::command]
pub async fn batch_git_status(paths: Vec<String>) -> HashMap<String, GitStatus> {
    tokio::task::spawn_blocking(move || {
        let results = std::sync::Mutex::new(HashMap::with_capacity(paths.len()));
        std::thread::scope(|s| {
            for p in paths {
                s.spawn(|| {
                    let status = get_git_status_for_path(&p);
                    results.lock().unwrap().insert(p, status);
                });
            }
        });
        results.into_inner().unwrap()
    })
    .await
    .unwrap_or_default()
}

#[tauri::command]
pub fn open_terminal(path: String) -> Result<(), String> {
    let dir = PathBuf::from(&path);
    if !dir.exists() {
        return Err("Path does not exist".into());
    }

    #[cfg(target_os = "windows")]
    {
        let result = Command::new("wt")
            .arg("-d")
            .arg(&path)
            .spawn();
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
        let terminals = ["x-terminal-emulator", "gnome-terminal", "konsole", "xfce4-terminal", "xterm"];
        let mut spawned = false;
        for term in &terminals {
            if Command::new(term)
                .arg("--working-directory")
                .arg(&path)
                .spawn()
                .is_ok()
            {
                spawned = true;
                break;
            }
        }
        if !spawned {
            return Err("Could not find a terminal emulator".into());
        }
    }

    Ok(())
}

#[tauri::command]
pub fn git_log(path: String) -> Result<(), String> {
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
        let terminals: [(&str, &[&str]); 5] = [
            ("gnome-terminal", &["--", "bash", "-c"]),
            ("konsole", &["--new-tab", "-e", "bash", "-c"]),
            ("xfce4-terminal", &["-e", "bash", "-c"]),
            ("xterm", &["-e", "bash", "-c"]),
            ("x-terminal-emulator", &["-e", "bash", "-c"]),
        ];
        let cmd = format!("cd '{}' && git log --oneline --graph -25 --all; exec bash", path.replace('\'', "'\\''"));
        let mut spawned = false;
        for (term, args) in &terminals {
            if Command::new(term)
                .args(*args)
                .arg(&cmd)
                .spawn()
                .is_ok()
            {
                spawned = true;
                break;
            }
        }
        if !spawned {
            return Err("Could not find a terminal emulator".into());
        }
    }

    Ok(())
}

#[tauri::command]
pub fn git_pull(path: String) -> Result<String, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "pull"])
        .output()
        .map_err(|e| format!("Failed to run git pull: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(friendly_git_error(&stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(stdout)
}

#[tauri::command]
pub fn git_push(path: String, force: Option<bool>) -> Result<String, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let mut args = vec!["-C", &path as &str, "push"];
    if force.unwrap_or(false) {
        args.push("--force-with-lease");
    }

    let output = cmd()
        .args(&args)
        .output()
        .map_err(|e| format!("Failed to run git push: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(friendly_git_error(&stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(stdout)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitLogEntry {
    pub hash: String,
    pub message: String,
    pub author: String,
    pub date: String,
}

#[tauri::command]
pub fn git_log_entries(path: String) -> Result<Vec<GitLogEntry>, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let output = cmd()
        .args([
            "-C",
            &path,
            "log",
            "--oneline",
            "--max-count=25",
            "--format=%h|||%an|||%ar|||%s",
            "--all",
        ])
        .output()
        .map_err(|e| format!("Failed to run git log: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(friendly_git_error(&stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let entries: Vec<GitLogEntry> = stdout
        .lines()
        .filter(|l| !l.trim().is_empty())
        .filter_map(|line| {
            let parts: Vec<&str> = line.splitn(4, "|||").collect();
            if parts.len() < 4 {
                return None;
            }
            Some(GitLogEntry {
                hash: parts[0].to_string(),
                author: parts[1].to_string(),
                date: parts[2].to_string(),
                message: parts[3].to_string(),
            })
        })
        .collect();

    Ok(entries)
}

#[tauri::command]
pub fn git_remote_url(path: String) -> Result<String, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let output = cmd()
        .args(["-C", &path, "remote", "get-url", "origin"])
        .output()
        .map_err(|e| format!("Failed to get remote URL: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("No remote configured: {}", stderr.trim()));
    }

    let raw = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if raw.is_empty() {
        return Err("No remote 'origin' configured".into());
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

    Ok(to_web_url(&raw))
}

#[tauri::command]
pub fn git_fetch(path: String) -> Result<String, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "fetch"])
        .output()
        .map_err(|e| format!("Failed to run git fetch: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(friendly_git_error(&stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(stdout)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitBranchInfo {
    pub name: String,
    pub is_current: bool,
}

#[tauri::command]
pub fn git_list_branches(path: String) -> Result<Vec<GitBranchInfo>, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let output = cmd()
        .args(["-C", &path, "branch", "--format=%(refname:short)|||%(HEAD)"])
        .output()
        .map_err(|e| format!("Failed to list branches: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Failed to list branches: {}", stderr.trim()));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let branches: Vec<GitBranchInfo> = stdout
        .lines()
        .filter(|l| !l.trim().is_empty())
        .filter_map(|line| {
            let parts: Vec<&str> = line.splitn(2, "|||").collect();
            if parts.len() < 2 {
                return None;
            }
            Some(GitBranchInfo {
                name: parts[0].to_string(),
                is_current: parts[1].trim() == "*",
            })
        })
        .collect();

    Ok(branches)
}

#[tauri::command]
pub fn git_switch_branch(path: String, name: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "switch", &name])
        .output()
        .map_err(|e| format!("Failed to switch branch: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Branch switch failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_create_branch(path: String, name: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "branch", &name])
        .output()
        .map_err(|e| format!("Failed to create branch: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Branch creation failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_delete_branch(path: String, name: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "branch", "-d", &name])
        .output()
        .map_err(|e| format!("Failed to delete branch: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Branch deletion failed: {}", stderr.trim()));
    }
    Ok(())
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitStashEntry {
    pub index: usize,
    pub message: String,
}

#[tauri::command]
pub fn git_stash_push(path: String) -> Result<String, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "stash", "push", "--include-untracked"])
        .output()
        .map_err(|e| format!("Failed to stash: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Stash failed: {}", stderr.trim()));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(stdout)
}

#[tauri::command]
pub fn git_stash_list(path: String) -> Result<Vec<GitStashEntry>, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let output = cmd()
        .args(["-C", &path, "stash", "list"])
        .output()
        .map_err(|e| format!("Failed to list stashes: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Failed to list stashes: {}", stderr.trim()));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
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
}

#[tauri::command]
pub fn git_stash_apply(path: String, index: usize) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "stash", "apply", &format!("stash@{{{}}}", index)])
        .output()
        .map_err(|e| format!("Failed to apply stash: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Stash apply failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_stash_drop(path: String, index: usize) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "stash", "drop", &format!("stash@{{{}}}", index)])
        .output()
        .map_err(|e| format!("Failed to drop stash: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Stash drop failed: {}", stderr.trim()));
    }
    Ok(())
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitChangedFile {
    pub path: String,
    pub status: String,
}

#[tauri::command]
pub fn git_changed_files(path: String) -> Result<Vec<GitChangedFile>, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let output = cmd()
        .args(["-C", &path, "status", "--porcelain"])
        .output()
        .map_err(|e| format!("Failed to get git status: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Git status failed: {}", stderr.trim()));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let files: Vec<GitChangedFile> = stdout
        .lines()
        .filter(|l| !l.trim().is_empty())
        .filter_map(|line| {
            let status = line.get(..2)?.trim().to_string();
            let file_path = line.get(3..)?.to_string();
            if status.is_empty() && file_path.is_empty() {
                return None;
            }
            Some(GitChangedFile {
                path: file_path,
                status,
            })
        })
        .collect();

    Ok(files)
}

#[tauri::command]
pub fn git_discard_changes(path: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "restore", "."])
        .output()
        .map_err(|e| format!("Failed to discard changes: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Discard failed: {}", stderr.trim()));
    }

    let _ = cmd()
        .args(["-C", &path, "clean", "-fd"])
        .output();

    Ok(())
}

#[tauri::command]
pub fn git_init(path: String) -> Result<String, String> {
    let dir = PathBuf::from(&path);
    if !dir.exists() {
        return Err("Path does not exist".into());
    }
    if check_is_repo(&path) {
        return Err("Already a git repository".into());
    }

    let output = cmd()
        .args(["init", &path])
        .output()
        .map_err(|e| format!("Failed to init git: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Git init failed: {}", stderr.trim()));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(stdout)
}

#[tauri::command]
pub fn git_stage_file(path: String, file_path: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "add", &file_path])
        .output()
        .map_err(|e| format!("Failed to stage file: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Stage failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_unstage_file(path: String, file_path: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "restore", "--staged", &file_path])
        .output()
        .map_err(|e| format!("Failed to unstage file: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Unstage failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_commit(path: String, message: String, amend: bool) -> Result<String, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let mut args = vec!["-C", &path as &str, "commit", "-m", &message as &str];
    if amend {
        args.push("--amend");
    }

    let output = cmd()
        .args(&args)
        .output()
        .map_err(|e| format!("Failed to commit: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stdout = String::from_utf8_lossy(&output.stdout);
        let detail = if !stderr.trim().is_empty() {
            stderr.trim().to_string()
        } else if !stdout.trim().is_empty() {
            stdout.trim().to_string()
        } else {
            "Unknown error, run 'git commit' in a terminal for more details.".to_string()
        };
        return Err(format!("Commit failed: {}", detail));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(stdout)
}

#[tauri::command]
pub fn git_set_remote(path: String, url: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let check = cmd()
        .args(["-C", &path, "remote"])
        .output()
        .map_err(|e| format!("Failed to check remotes: {}", e))?;

    let remotes = String::from_utf8_lossy(&check.stdout);
    let has_origin = remotes.lines().any(|l| l.trim() == "origin");

    let output = if has_origin {
        cmd()
            .args(["-C", &path, "remote", "set-url", "origin", &url])
            .output()
            .map_err(|e| format!("Failed to set remote URL: {}", e))?
    } else {
        cmd()
            .args(["-C", &path, "remote", "add", "origin", &url])
            .output()
            .map_err(|e| format!("Failed to add remote: {}", e))?
    };

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Remote URL change failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_remove_remote(path: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "remote", "remove", "origin"])
        .output()
        .map_err(|e| format!("Failed to remove remote: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Remote removal failed: {}", stderr.trim()));
    }
    Ok(())
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

#[tauri::command]
pub fn git_file_diff(path: String, file_path: String) -> Result<GitDiffResult, String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }

    let output = cmd()
        .args(["-C", &path, "diff", "--no-color", "--", &file_path])
        .output()
        .map_err(|e| format!("Failed to get diff: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);

    let diff_text = if stdout.trim().is_empty() {
        let cached = cmd()
            .args(["-C", &path, "diff", "--cached", "--no-color", "--", &file_path])
            .output()
            .ok();
        match cached {
            Some(c) => String::from_utf8_lossy(&c.stdout).to_string(),
            None => stdout.to_string(),
        }
    } else {
        stdout.to_string()
    };

    if diff_text.trim().is_empty() {
        return Err(format!("No diff available for '{}'", file_path));
    }

    let mut result = GitDiffResult { hunks: Vec::new() };
    let mut current_hunk: Option<GitDiffHunk> = None;

    for line in diff_text.lines() {
        if let Some(hunk_header) = line.strip_prefix("@@ ") {
            if let Some(range_part) = hunk_header.split(" @@").next() {
                if let Some(range) = range_part.split(' ').nth(1) {
                    if let Some((old, new)) = range.split_once(' ') {
                        let old_parts: Vec<&str> = old.split(',').collect();
                        let new_parts: Vec<&str> = new.split(',').collect();
                        let old_start = old_parts[0].trim_start_matches('-').parse::<u32>().unwrap_or(1);
                        let old_lines = old_parts.get(1).and_then(|s| s.parse::<u32>().ok()).unwrap_or(0);
                        let new_start = new_parts[0].trim_start_matches('+').parse::<u32>().unwrap_or(1);
                        let new_lines = new_parts.get(1).and_then(|s| s.parse::<u32>().ok()).unwrap_or(0);

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
                    }
                }
            }
        } else if let Some(hunk) = &mut current_hunk {
            if line.starts_with('+') {
                hunk.lines.push(GitDiffLine {
                    kind: "add".into(),
                    content: line[1..].to_string(),
                });
            } else if line.starts_with('-') {
                hunk.lines.push(GitDiffLine {
                    kind: "delete".into(),
                    content: line[1..].to_string(),
                });
            } else if line.starts_with(' ') {
                hunk.lines.push(GitDiffLine {
                    kind: "context".into(),
                    content: line[1..].to_string(),
                });
            }
        }
    }

    if let Some(hunk) = current_hunk.take() {
        result.hunks.push(hunk);
    }

    Ok(result)
}

#[tauri::command]
pub fn git_undo_commit(path: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "reset", "--soft", "HEAD~1"])
        .output()
        .map_err(|e| format!("Failed to undo commit: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Undo commit failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn git_undo_pull(path: String) -> Result<(), String> {
    if !check_is_repo(&path) {
        return Err("Not a git repository".into());
    }
    let output = cmd()
        .args(["-C", &path, "reset", "--keep", "ORIG_HEAD"])
        .output()
        .map_err(|e| format!("Failed to undo pull: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Undo pull failed: {}", stderr.trim()));
    }
    Ok(())
}

#[tauri::command]
pub fn clone_repo(url: String, dest: String) -> Result<String, String> {
    if !url.contains("://") && !url.contains('@') {
        return Err("Not a valid git URL".into());
    }

    let dest_path = PathBuf::from(&dest);
    let folder_name = url
        .trim_end_matches(".git")
        .split('/')
        .last()
        .unwrap_or("repo");

    let clone_target = dest_path.join(folder_name);

    if clone_target.exists() {
        return Err(format!(
            "Folder '{}' already exists at this location",
            folder_name
        ));
    }

    let output = cmd()
        .arg("clone")
        .arg(&url)
        .arg(&clone_target)
        .output()
        .map_err(|e| format!("Failed to run git: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Git clone failed: {}", stderr.trim()));
    }

    Ok(clone_target.to_string_lossy().to_string())
}
