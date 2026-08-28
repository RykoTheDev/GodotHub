use crate::persist;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

const GIST_DESCRIPTION: &str = "GodotHub workspace backup";
const BACKUP_FILE_NAME: &str = "godothub-workspace-backup.json";

#[derive(Serialize, Deserialize)]
struct SyncState {
    gist_id: String,
    gist_url: String,
    pushed_at: String,
}

fn persistent_gist_dir(app: &AppHandle) -> PathBuf {
    if let Ok(home) = app.path().home_dir() {
        home.join(".godothub")
    } else {
        app.path().app_data_dir().expect("no app data dir")
    }
}

fn sync_state_file(app: &AppHandle) -> PathBuf {
    let base = persistent_gist_dir(app);
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    base.join("gist-sync.json")
}

fn read_sync_state(app: &AppHandle) -> Option<SyncState> {
    persist::read_json_opt(&sync_state_file(app))
}

fn write_sync_state(app: &AppHandle, state: &SyncState) {
    let _ = persist::write_json(&sync_state_file(app), state);
}

#[tauri::command]
pub fn gist_sync_get_info(app: AppHandle) -> Option<GistSyncResult> {
    read_sync_state(&app).map(|s| GistSyncResult {
        gist_url: s.gist_url,
        gist_id: s.gist_id,
        pushed_at: s.pushed_at,
    })
}

fn github_token(app: &AppHandle) -> Option<String> {
    crate::git_auth::github_oauth_token(app).or_else(|| {
        crate::settings::read_settings(app)
            .github_token
            .filter(|t| !t.trim().is_empty())
    })
}

fn client() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())
}

fn gist_error_message(status: reqwest::StatusCode, context: &str) -> String {
    match status.as_u16() {
        401 => format!(
            "{context}: GitHub token is invalid or expired. \
             Go to Settings → Integrations and re-sign in with GitHub."
        ),
        403 => format!(
            "{context}: Forbidden (HTTP 403). Your token may be rate-limited or \
             missing the required \"gist\" scope. Go to Settings → Integrations, \
             disconnect GitHub, and re-sign in."
        ),
        404 => format!(
            "{context}: Gist not found (HTTP 404). It may have been deleted on GitHub, \
             or your token lacks the \"gist\" scope. Re-authorize in Settings → \
             Integrations, then push a new backup."
        ),
        422 => format!(
            "{context}: GitHub rejected the request (HTTP 422). \
             The workspace data may be too large for a single gist."
        ),
        500..=599 => format!(
            "{context}: GitHub server error (HTTP {}). Try again later.", status
        ),
        _ => format!("{context}: GitHub API returned HTTP {status}"),
    }
}

#[derive(Serialize)]
pub struct GistSyncResult {
    pub gist_url: String,
    pub gist_id: String,
    pub pushed_at: String,
}

#[derive(Deserialize)]
struct GistResponse {
    id: String,
    html_url: String,
}

#[derive(Deserialize)]
struct GistDetail {
    files: HashMap<String, GistFile>,
}

#[derive(Deserialize)]
struct GistFile {
    content: String,
}

async fn create_gist(
    client: &reqwest::Client,
    token: &str,
    content: &str,
) -> Result<(String, String), String> {
    let body = serde_json::json!({
        "description": GIST_DESCRIPTION,
        "public": false,
        "files": { BACKUP_FILE_NAME: { "content": content } }
    });
    let resp = client
        .post("https://api.github.com/gists")
        .bearer_auth(token)
        .json(&body)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        return Err(gist_error_message(status, "Failed to create gist"));
    }
    let g: GistResponse = resp.json().await.map_err(|e| e.to_string())?;
    Ok((g.id, g.html_url))
}

async fn update_gist(
    client: &reqwest::Client,
    token: &str,
    id: &str,
    content: &str,
) -> Result<String, String> {
    let body = serde_json::json!({
        "description": GIST_DESCRIPTION,
        "files": { BACKUP_FILE_NAME: { "content": content } }
    });
    let resp = client
        .patch(format!("https://api.github.com/gists/{id}"))
        .bearer_auth(token)
        .json(&body)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        return Err(gist_error_message(status, "Failed to update gist"));
    }
    let g: GistResponse = resp.json().await.map_err(|e| e.to_string())?;
    Ok(g.html_url)
}

#[tauri::command]
pub async fn gist_sync_push(app: AppHandle) -> Result<GistSyncResult, String> {
    let token = github_token(&app)
        .ok_or("No GitHub token found. Add one in Settings → Integrations or sign in with Git auth.")?;
    let backup = crate::backup::build_app_backup(&app)?;
    let content = serde_json::to_string_pretty(&backup).map_err(|e| e.to_string())?;
    let client = client()?;

    let (id, url) = match read_sync_state(&app) {
        Some(state) => {
            match update_gist(&client, &token, &state.gist_id, &content).await {
                Ok(url) => (state.gist_id.clone(), url),
                Err(update_err) => {
                    eprintln!("Gist update failed ({update_err}), creating a new one...");
                    create_gist(&client, &token, &content).await?
                }
            }
        }
        None => create_gist(&client, &token, &content).await?,
    };
    let pushed_at = chrono::Utc::now().to_rfc3339();
    write_sync_state(
        &app,
        &SyncState {
            gist_id: id.clone(),
            gist_url: url.clone(),
            pushed_at: pushed_at.clone(),
        },
    );
    Ok(GistSyncResult {
        gist_url: url,
        gist_id: id,
        pushed_at,
    })
}

#[tauri::command]
pub fn gist_sync_save_gist_url(app: AppHandle, gist_url: String) -> Result<(), String> {
    let gist_id = gist_id_from_input(&gist_url)?;
    write_sync_state(
        &app,
        &SyncState {
            gist_id,
            gist_url: gist_url.trim().to_string(),
            pushed_at: String::new(),
        },
    );
    Ok(())
}

#[derive(Serialize)]
pub struct RestorePreview {
    pub workspace_count: usize,
    pub workspace_names: Vec<String>,
    pub project_count: usize,
    pub category_count: usize,
    pub template_count: usize,
    pub has_time_stats: bool,
    pub version_scan_dirs: Vec<String>,
    pub project_scan_dirs: Vec<String>,
}

#[tauri::command]
pub async fn gist_sync_fetch_backup(app: AppHandle) -> Result<RestorePreview, String> {
    let token = github_token(&app)
        .ok_or("No GitHub token found. Add one in Settings → Integrations or sign in with Git auth.")?;
    let state = read_sync_state(&app)
        .ok_or("No cloud backup found yet. Push one first from Settings.")?;
    let client = client()?;
    let resp = client
        .get(format!("https://api.github.com/gists/{}", state.gist_id))
        .bearer_auth(&token)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        return Err(gist_error_message(status, "Failed to fetch gist"));
    }
    let detail: GistDetail = resp.json().await.map_err(|e| e.to_string())?;
    let file = detail
        .files
        .get(BACKUP_FILE_NAME)
        .ok_or("Backup file not found in the synced gist")?;
    let backup: crate::backup::AppBackup =
        serde_json::from_str(&file.content).map_err(|e| e.to_string())?;
    let mut project_count = 0;
    let mut category_count = 0;
    let mut template_count = 0;
    let mut has_time_stats = false;
    let mut workspace_names = Vec::new();
    let mut version_scan_dirs = Vec::new();
    let mut project_scan_dirs = Vec::new();
    for wb in &backup.workspaces {
        workspace_names.push(wb.workspace_name());
        project_count += wb.project_count();
        category_count += wb.category_count();
        template_count += wb.template_count();
        if wb.has_time_stats() {
            has_time_stats = true;
        }
        if version_scan_dirs.is_empty() {
            version_scan_dirs = wb.version_scan_dirs().clone();
        }
        if project_scan_dirs.is_empty() {
            project_scan_dirs = wb.project_scan_dirs().clone();
        }
    }
    Ok(RestorePreview {
        workspace_count: backup.workspaces.len(),
        workspace_names,
        project_count,
        category_count,
        template_count,
        has_time_stats,
        version_scan_dirs,
        project_scan_dirs,
    })
}

#[tauri::command]
pub async fn gist_sync_pull(app: AppHandle) -> Result<crate::models::AppSettings, String> {
    let token = github_token(&app)
        .ok_or("No GitHub token found. Add one in Settings → Integrations or sign in with Git auth.")?;
    let state = read_sync_state(&app)
        .ok_or("No cloud backup found yet. Push one first from Settings.")?;
    let client = client()?;
    let resp = client
        .get(format!("https://api.github.com/gists/{}", state.gist_id))
        .bearer_auth(&token)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        return Err(gist_error_message(status, "Failed to pull gist"));
    }
    let detail: GistDetail = resp.json().await.map_err(|e| e.to_string())?;
    let file = detail
        .files
        .get(BACKUP_FILE_NAME)
        .ok_or("Backup file not found in the synced gist")?;
    let backup: crate::backup::AppBackup =
        serde_json::from_str(&file.content).map_err(|e| e.to_string())?;
    let settings = crate::backup::apply_app_backup(&app, backup)?;

    let scan_depth = settings.scan_depth;
    let project_dirs = settings.project_scan_dirs.clone();
    let version_dirs = settings.version_scan_dirs.clone();
    let template_dir = settings.template_scan_dir.clone();
    let app2 = app.clone();
    let _ = tokio::task::spawn_blocking(move || {
        if !project_dirs.is_empty() {
            let _ = crate::scan::scan_for_projects_blocking(
                app2.clone(), project_dirs, scan_depth, false,
            );
        }
        if !version_dirs.is_empty() {
            let _ = crate::scan::scan_for_versions_blocking(
                app2.clone(), version_dirs, scan_depth,
            );
        }
        if template_dir.is_some() {
            let _ = crate::templates::sync_templates_with_scan_dir(app2);
        }
    })
    .await;

    Ok(settings)
}

fn gist_id_from_input(input: &str) -> Result<String, String> {
    let trimmed = input.trim();
    if trimmed.is_empty() {
        return Err("Gist URL or ID cannot be empty".into());
    }
    // Full URL: https://gist.github.com/user/GIST_ID or https://gist.github.com/GIST_ID
    if let Some(id) = trimmed
        .strip_prefix("https://gist.github.com/")
        .or_else(|| trimmed.strip_prefix("http://gist.github.com/"))
    {
        let id = id.trim_end_matches('/');
        if let Some(pos) = id.rfind('/') {
            return Ok(id[pos + 1..].to_string());
        }
        if !id.is_empty() {
            return Ok(id.to_string());
        }
    }
    // Short URL: https://git.io/... or raw ID (alphanumeric + dashes)
    if trimmed
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '-')
        && trimmed.len() >= 5
    {
        return Ok(trimmed.to_string());
    }
    Err(
        "Invalid gist reference. Paste a full GitHub gist URL \
         (https://gist.github.com/...) or a gist ID."
            .into(),
    )
}

#[tauri::command]
pub async fn gist_sync_pull_by_url(
    app: AppHandle,
    gist_url: String,
) -> Result<crate::models::AppSettings, String> {
    let token = github_token(&app)
        .ok_or("No GitHub token found. Add one in Settings → Integrations or sign in with Git auth.")?;
    let gist_id = gist_id_from_input(&gist_url)?;
    let client = client()?;
    let resp = client
        .get(format!("https://api.github.com/gists/{gist_id}"))
        .bearer_auth(&token)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        return Err(gist_error_message(status, "Failed to pull gist"));
    }
    let detail: GistDetail = resp.json().await.map_err(|e| e.to_string())?;
    let file = detail
        .files
        .get(BACKUP_FILE_NAME)
        .ok_or("Backup file not found in this gist")?;
    let backup: crate::backup::AppBackup =
        serde_json::from_str(&file.content).map_err(|e| e.to_string())?;
    write_sync_state(
        &app,
        &SyncState {
            gist_id: gist_id.clone(),
            gist_url: format!("https://gist.github.com/{gist_id}"),
            pushed_at: chrono::Utc::now().to_rfc3339(),
        },
    );
    let settings = crate::backup::apply_app_backup(&app, backup)?;

    let scan_depth = settings.scan_depth;
    let project_dirs = settings.project_scan_dirs.clone();
    let version_dirs = settings.version_scan_dirs.clone();
    let template_dir = settings.template_scan_dir.clone();
    let app2 = app.clone();
    let _ = tokio::task::spawn_blocking(move || {
        if !project_dirs.is_empty() {
            let _ = crate::scan::scan_for_projects_blocking(
                app2.clone(), project_dirs, scan_depth, false,
            );
        }
        if !version_dirs.is_empty() {
            let _ = crate::scan::scan_for_versions_blocking(
                app2.clone(), version_dirs, scan_depth,
            );
        }
        if template_dir.is_some() {
            let _ = crate::templates::sync_templates_with_scan_dir(app2);
        }
    })
    .await;

    Ok(settings)
}
