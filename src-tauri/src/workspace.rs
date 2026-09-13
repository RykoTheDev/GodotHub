use crate::models::*;
use crate::persist;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};
use tauri::{AppHandle, Manager};
use uuid::Uuid;

const META_FILE: &str = "workspace.json";
const LEGACY_FILES: [&str; 4] = ["settings.json", "projects.json", "categories.json", "templates"];

fn state_lock() -> &'static Mutex<()> {
    static LOCK: OnceLock<Mutex<()>> = OnceLock::new();
    LOCK.get_or_init(|| Mutex::new(()))
}

fn app_data_dir(app: &AppHandle) -> PathBuf {
    app.path().app_data_dir().expect("no app data dir")
}

fn workspaces_file_in(base: &Path) -> PathBuf {
    base.join("workspaces.json")
}

fn workspaces_root_in(base: &Path) -> PathBuf {
    base.join("workspaces")
}

fn workspaces_root(app: &AppHandle) -> PathBuf {
    workspaces_root_in(&app_data_dir(app))
}

fn ensure_dir(dir: &Path) {
    if !dir.exists() {
        let _ = fs::create_dir_all(dir);
    }
}

pub fn workspace_dir_in(base: &Path, id: &str) -> PathBuf {
    let dir = workspaces_root_in(base).join(id);
    ensure_dir(&dir);
    dir
}

pub fn workspace_dir(app: &AppHandle, id: &str) -> PathBuf {
    workspace_dir_in(&app_data_dir(app), id)
}

pub(crate) fn write_state(app: &AppHandle, state: &WorkspacesState) -> Result<(), String> {
    write_state_in(&app_data_dir(app), state)
}

fn write_state_in(base: &Path, state: &WorkspacesState) -> Result<(), String> {
    for ws in &state.workspaces {
        let dir = workspace_dir_in(base, &ws.id);
        let _ = persist::write_json(&dir.join(META_FILE), ws);
    }
    persist::write_json_with_backup(&workspaces_file_in(base), state).map_err(|e| e.to_string())
}

fn read_state_file(file: &Path) -> Option<WorkspacesState> {
    for candidate in [file.to_path_buf(), persist::backup_path(file)] {
        if let Some(state) = persist::read_json_opt::<WorkspacesState>(&candidate) {
            if !state.workspaces.is_empty() {
                return Some(state);
            }
        }
    }
    None
}

fn has_workspace_data(dir: &Path) -> bool {
    dir.join(META_FILE).is_file()
        || dir.join("settings.json").is_file()
        || dir.join("projects.json").is_file()
        || dir.join("categories.json").is_file()
        || dir.join("templates").is_dir()
}

fn dir_timestamp(dir: &Path) -> String {
    fs::metadata(dir)
        .and_then(|m| m.modified())
        .ok()
        .map(chrono::DateTime::<chrono::Utc>::from)
        .unwrap_or_else(chrono::Utc::now)
        .to_rfc3339()
}

fn pick_active(workspaces: &[Workspace], root: &Path) -> String {
    let mut best: Option<(bool, std::time::SystemTime, String)> = None;
    for ws in workspaces {
        let settings = root.join(&ws.id).join("settings.json");
        let Ok(modified) = fs::metadata(&settings).and_then(|m| m.modified()) else {
            continue;
        };
        let configured = persist::read_json_opt::<serde_json::Value>(&settings)
            .and_then(|v| v.get("setup_complete").and_then(|b| b.as_bool()))
            .unwrap_or(false);
        let candidate = (configured, modified, ws.id.clone());
        if best.as_ref().is_none_or(|current| candidate > *current) {
            best = Some(candidate);
        }
    }
    best.map(|(_, _, id)| id)
        .unwrap_or_else(|| workspaces[0].id.clone())
}

fn recover_state(base: &Path) -> Option<WorkspacesState> {
    let root = workspaces_root_in(base);
    let mut dirs: Vec<(String, PathBuf)> = fs::read_dir(&root)
        .ok()?
        .flatten()
        .filter_map(|entry| {
            let dir = entry.path();
            let id = dir.file_name()?.to_str()?.to_string();
            (dir.is_dir() && has_workspace_data(&dir)).then_some((id, dir))
        })
        .collect();

    if dirs.is_empty() {
        return None;
    }
    dirs.sort_by(|a, b| a.0.cmp(&b.0));

    let single = dirs.len() == 1;
    let workspaces: Vec<Workspace> = dirs
        .into_iter()
        .enumerate()
        .map(|(index, (id, dir))| {
            let mut workspace = persist::read_json_opt::<Workspace>(&dir.join(META_FILE))
                .unwrap_or_else(|| Workspace {
                    id: id.clone(),
                    name: if single {
                        "Default".to_string()
                    } else {
                        format!("Recovered {}", index + 1)
                    },
                    icon: "briefcase".to_string(),
                    color: crate::models::default_accent(),
                    created_at: dir_timestamp(&dir),
                });
            workspace.id = id;
            workspace
        })
        .collect();

    let active_id = pick_active(&workspaces, &root);
    Some(WorkspacesState {
        workspaces,
        active_id,
    })
}

fn note(base: &Path, message: &str) {
    use std::io::Write;
    let Ok(mut file) = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(base.join("diagnostics.log"))
    else {
        return;
    };
    let _ = writeln!(file, "{} [workspace] {}", chrono::Utc::now().to_rfc3339(), message);
}

fn migrate_legacy_files(base: &Path, id: &str) {
    let dir = workspace_dir_in(base, id);
    for name in LEGACY_FILES {
        let src = base.join(name);
        let dst = dir.join(name);
        if src.exists() && !dst.exists() {
            let _ = fs::rename(&src, &dst);
        }
    }
}

fn create_default_state(base: &Path) -> WorkspacesState {
    let id = Uuid::new_v4().to_string();
    migrate_legacy_files(base, &id);

    let workspace = Workspace {
        id: id.clone(),
        name: "Default".to_string(),
        icon: "briefcase".to_string(),
        color: crate::models::default_accent(),
        created_at: chrono::Utc::now().to_rfc3339(),
    };
    let state = WorkspacesState {
        workspaces: vec![workspace],
        active_id: id,
    };
    let _ = write_state_in(base, &state);
    state
}

pub fn read_state(app: &AppHandle) -> WorkspacesState {
    let _guard = state_lock().lock().unwrap_or_else(|e| e.into_inner());
    read_state_in(&app_data_dir(app))
}

pub fn read_state_in(base: &Path) -> WorkspacesState {
    ensure_dir(base);
    let file = workspaces_file_in(base);

    if let Some(mut state) = read_state_file(&file) {
        if !state.workspaces.iter().any(|w| w.id == state.active_id) {
            state.active_id = state.workspaces[0].id.clone();
            let _ = write_state_in(base, &state);
        }
        return state;
    }

    let damaged = file.exists();
    if damaged {
        let backup = file.with_extension(format!(
            "json.corrupt-{}",
            chrono::Utc::now().timestamp()
        ));
        let _ = fs::rename(&file, &backup);
    }

    if let Some(state) = recover_state(base) {
        note(
            base,
            &format!(
                "rebuilt workspaces index from disk: {} workspace(s), damaged index: {}",
                state.workspaces.len(),
                damaged
            ),
        );
        let _ = write_state_in(base, &state);
        return state;
    }

    if damaged {
        note(base, "workspaces index was unusable and nothing could be recovered");
    }
    create_default_state(base)
}

pub fn active_workspace_dir(app: &AppHandle) -> PathBuf {
    let state = read_state(app);
    workspace_dir(app, &state.active_id)
}

pub fn active_workspace_id(app: &AppHandle) -> String {
    read_state(app).active_id
}

#[tauri::command]
pub fn list_workspaces(app: AppHandle) -> WorkspacesState {
    read_state(&app)
}

#[tauri::command]
pub fn list_workspace_scan_dirs(app: AppHandle) -> Vec<WorkspaceScanDirs> {
    let state = read_state(&app);
    state
        .workspaces
        .iter()
        .map(|w| {
            let dir = workspace_dir(&app, &w.id);
            let settings: crate::models::AppSettings =
                persist::read_json_with_backup(&dir.join("settings.json"));
            WorkspaceScanDirs {
                workspace_id: w.id.clone(),
                workspace_name: w.name.clone(),
                project_scan_dirs: settings.project_scan_dirs,
                version_scan_dirs: settings.version_scan_dirs,
                template_scan_dir: settings.template_scan_dir,
            }
        })
        .collect()
}

#[tauri::command]
pub fn create_workspace_silent(
    app: &AppHandle,
    name: String,
    icon: String,
    color: String,
) -> Result<Workspace, String> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err("Workspace name can't be empty".into());
    }
    let mut state = read_state(app);
    if state
        .workspaces
        .iter()
        .any(|w| w.name.eq_ignore_ascii_case(&trimmed))
    {
        return Err("A workspace with this name already exists".into());
    }
    let id = Uuid::new_v4().to_string();
    workspace_dir(app, &id);
    let workspace = Workspace {
        id: id.clone(),
        name: trimmed,
        icon,
        color,
        created_at: chrono::Utc::now().to_rfc3339(),
    };
    state.workspaces.push(workspace.clone());
    write_state(app, &state)?;
    Ok(workspace)
}

#[tauri::command]
pub fn create_workspace(
    app: AppHandle,
    name: String,
    icon: String,
    color: String,
) -> Result<WorkspacesState, String> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err("Workspace name can't be empty".into());
    }
    let mut state = read_state(&app);
    if state
        .workspaces
        .iter()
        .any(|w| w.name.eq_ignore_ascii_case(&trimmed))
    {
        return Err("A workspace with this name already exists".into());
    }
    let id = Uuid::new_v4().to_string();
    workspace_dir(&app, &id);
    let workspace = Workspace {
        id: id.clone(),
        name: trimmed,
        icon,
        color,
        created_at: chrono::Utc::now().to_rfc3339(),
    };
    state.workspaces.push(workspace);
    state.active_id = id;
    write_state(&app, &state)?;
    let _ = crate::watcher::restart_watchers(app);
    Ok(state)
}

#[tauri::command]
pub fn switch_workspace(app: AppHandle, id: String) -> Result<WorkspacesState, String> {
    let mut state = read_state(&app);
    if !state.workspaces.iter().any(|w| w.id == id) {
        return Err("Workspace not found".into());
    }
    state.active_id = id;
    write_state(&app, &state)?;
    let _ = crate::watcher::restart_watchers(app);
    Ok(state)
}

#[tauri::command]
pub fn update_workspace(
    app: AppHandle,
    id: String,
    name: Option<String>,
    icon: Option<String>,
    color: Option<String>,
) -> Result<WorkspacesState, String> {
    let mut state = read_state(&app);
    if let Some(ref n) = name {
        let trimmed = n.trim();
        if trimmed.is_empty() {
            return Err("Workspace name can't be empty".into());
        }
        if state.workspaces.iter().any(|w| w.id != id && w.name.eq_ignore_ascii_case(trimmed)) {
            return Err("A workspace with this name already exists".into());
        }
    }
    if let Some(ws) = state.workspaces.iter_mut().find(|w| w.id == id) {
        if let Some(ref n) = name { ws.name = n.trim().to_string(); }
        if let Some(icon) = icon { ws.icon = icon; }
        if let Some(color) = color { ws.color = color; }
    } else {
        return Err("Workspace not found".into());
    }
    write_state(&app, &state)?;
    Ok(state)
}

#[tauri::command]
pub fn delete_workspace(app: AppHandle, id: String) -> Result<WorkspacesState, String> {
    let mut state = read_state(&app);
    if state.workspaces.len() <= 1 {
        return Err("Can't delete your only workspace".into());
    }
    let idx = state.workspaces.iter().position(|w| w.id == id).ok_or("Workspace not found")?;
    state.workspaces.remove(idx);
    let switched = state.active_id == id;
    if switched {
        state.active_id = state.workspaces[0].id.clone();
    }
    write_state(&app, &state)?;
    let _ = fs::remove_dir_all(workspaces_root(&app).join(&id));
    if switched {
        let _ = crate::watcher::restart_watchers(app);
    }
    Ok(state)
}

#[cfg(test)]
#[path = "../tests/common/workspace.rs"]
mod workspace_common_tests;
