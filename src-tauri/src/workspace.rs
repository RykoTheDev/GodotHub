use crate::models::*;
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};
use uuid::Uuid;

fn workspaces_file(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    base.join("workspaces.json")
}

fn workspaces_root(app: &AppHandle) -> PathBuf {
    app.path()
        .app_data_dir()
        .expect("no app data dir")
        .join("workspaces")
}

pub fn workspace_dir(app: &AppHandle, id: &str) -> PathBuf {
    let dir = workspaces_root(app).join(id);
    if !dir.exists() {
        let _ = fs::create_dir_all(&dir);
    }
    dir
}

fn write_state(app: &AppHandle, state: &WorkspacesState) -> Result<(), String> {
    fs::write(
        workspaces_file(app),
        serde_json::to_string_pretty(state).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

pub fn read_state(app: &AppHandle) -> WorkspacesState {
    let file = workspaces_file(app);
    if file.exists() {
        if let Ok(state) =
            serde_json::from_str::<WorkspacesState>(&fs::read_to_string(&file).unwrap_or_default())
        {
            if !state.workspaces.is_empty()
                && state.workspaces.iter().any(|w| w.id == state.active_id)
            {
                return state;
            }
        }
    }

    let base = app.path().app_data_dir().expect("no app data dir");
    let id = Uuid::new_v4().to_string();
    let dir = workspace_dir(app, &id);
    for name in ["settings.json", "projects.json", "categories.json"] {
        let src = base.join(name);
        let dst = dir.join(name);
        if src.exists() && !dst.exists() {
            let _ = fs::rename(&src, &dst);
        }
    }
    let workspace = Workspace {
        id: id.clone(),
        name: "Default".to_string(),
        icon: "briefcase".to_string(),
        color: "#457ff2".to_string(),
        created_at: chrono::Utc::now().to_rfc3339(),
    };
    let state = WorkspacesState {
        workspaces: vec![workspace],
        active_id: id,
    };
    let _ = write_state(app, &state);
    state
}

pub fn active_workspace_dir(app: &AppHandle) -> PathBuf {
    let state = read_state(app);
    workspace_dir(app, &state.active_id)
}

#[tauri::command]
pub fn list_workspaces(app: AppHandle) -> WorkspacesState {
    read_state(&app)
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

    if let Some(name) = &name {
        let trimmed = name.trim();
        if trimmed.is_empty() {
            return Err("Workspace name can't be empty".into());
        }
        if state
            .workspaces
            .iter()
            .any(|w| w.id != id && w.name.eq_ignore_ascii_case(trimmed))
        {
            return Err("A workspace with this name already exists".into());
        }
    }

    {
        let ws = state
            .workspaces
            .iter_mut()
            .find(|w| w.id == id)
            .ok_or("Workspace not found")?;
        if let Some(name) = name {
            ws.name = name.trim().to_string();
        }
        if let Some(icon) = icon {
            ws.icon = icon;
        }
        if let Some(color) = color {
            ws.color = color;
        }
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
    let idx = state
        .workspaces
        .iter()
        .position(|w| w.id == id)
        .ok_or("Workspace not found")?;
    state.workspaces.remove(idx);
    if state.active_id == id {
        state.active_id = state.workspaces[0].id.clone();
    }
    write_state(&app, &state)?;
    let _ = fs::remove_dir_all(workspaces_root(&app).join(&id));
    Ok(state)
}
