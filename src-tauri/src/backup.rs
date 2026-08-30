use crate::models::*;
use crate::persist;
use base64::{engine::general_purpose, Engine as _};
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use tauri::AppHandle;

#[derive(serde::Serialize, serde::Deserialize)]
struct WorkspaceMeta {
    name: String,
    icon: String,
    color: String,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct TemplateBackup {
    meta: ProjectTemplate,
    #[serde(default)]
    files: BTreeMap<String, String>,
}

#[derive(serde::Serialize, serde::Deserialize)]
pub(crate) struct WorkspaceBackup {
    exported_at: String,
    workspace: WorkspaceMeta,
    settings: AppSettings,
    #[serde(default)]
    projects: Vec<Project>,
    #[serde(default)]
    categories: Vec<Category>,
    #[serde(default)]
    templates: Vec<TemplateBackup>,
    #[serde(default)]
    time_stats: crate::time_stats::TimeStatsStore,
}

impl WorkspaceBackup {
    pub fn workspace_name(&self) -> String {
        self.workspace.name.clone()
    }
    pub fn project_count(&self) -> usize {
        self.projects.len()
    }
    pub fn category_count(&self) -> usize {
        self.categories.len()
    }
    pub fn template_count(&self) -> usize {
        self.templates.len()
    }
    pub fn has_time_stats(&self) -> bool {
        !self.time_stats.projects.is_empty()
    }
    pub fn version_scan_dirs(&self) -> &Vec<String> {
        &self.settings.version_scan_dirs
    }
    pub fn project_scan_dirs(&self) -> &Vec<String> {
        &self.settings.project_scan_dirs
    }
}

fn templates_root_for(dir: &Path) -> PathBuf {
    dir.join("templates")
}

fn collect_files(dir: &Path, base: &Path, out: &mut BTreeMap<String, String>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let rel = path
            .strip_prefix(base)
            .unwrap_or(&path)
            .to_string_lossy()
            .replace('\\', "/");
        if path.is_dir() {
            collect_files(&path, base, out);
        } else if let Ok(bytes) = fs::read(&path) {
            out.insert(rel, general_purpose::STANDARD.encode(bytes));
        }
    }
}

fn restore_template(dir: &Path, backup: &TemplateBackup) {
    let _ = fs::create_dir_all(dir);
    for (rel, content) in &backup.files {
        let is_safe = !rel.is_empty()
            && !Path::new(rel).is_absolute()
            && !rel
                .split(['/', '\\'])
                .any(|c| c == ".." || c == "." || c.is_empty());
        if !is_safe {
            continue;
        }
        let dest = dir.join(rel);
        if let Some(parent) = dest.parent() {
            let _ = fs::create_dir_all(parent);
        }
        if let Ok(bytes) = general_purpose::STANDARD.decode(content) {
            let _ = fs::write(&dest, bytes);
        }
    }
    let _ = crate::templates::write_template_json(dir, &backup.meta);
}

fn build_workspace_backup_in(dir: &Path, ws: &Workspace) -> WorkspaceBackup {
    let workspace = WorkspaceMeta {
        name: ws.name.clone(),
        icon: ws.icon.clone(),
        color: ws.color.clone(),
    };

    let mut templates = Vec::new();
    let root = templates_root_for(dir);
    if let Ok(entries) = fs::read_dir(&root) {
        for entry in entries.flatten() {
            let dir = entry.path();
            if !dir.is_dir() {
                continue;
            }
            let Some(meta) = crate::templates::read_template_json(&dir) else {
                continue;
            };
            let mut files = BTreeMap::new();
            collect_files(&dir, &dir, &mut files);
            templates.push(TemplateBackup { meta, files });
        }
    }

    WorkspaceBackup {
        exported_at: chrono::Utc::now().to_rfc3339(),
        workspace,
        settings: crate::settings::read_settings_from(dir),
        projects: crate::projects::read_projects_from(dir),
        categories: crate::categories::read_categories_from(dir),
        templates,
        time_stats: crate::time_stats::read_stats_from(dir),
    }
}

pub(crate) fn build_workspace_backup(app: &AppHandle) -> Result<WorkspaceBackup, String> {
    let state = crate::workspace::read_state(app);
    let ws = state
        .workspaces
        .iter()
        .find(|w| w.id == state.active_id)
        .ok_or("Active workspace not found")?;
    let dir = crate::workspace::workspace_dir(app, &ws.id);
    Ok(build_workspace_backup_in(&dir, ws))
}

fn apply_workspace_backup_in(
    dir: &Path,
    backup: WorkspaceBackup,
) -> Result<AppSettings, String> {
    let current_settings = crate::settings::read_settings_from(dir);
    let mut settings = backup.settings;
    settings.dismissed_project_paths = current_settings.dismissed_project_paths;
    settings.setup_complete = true;
    crate::settings::write_settings_to(dir, &settings).map_err(|e| e.to_string())?;

    let projects: Vec<Project> = backup
        .projects
        .into_iter()
        .map(|mut p| {
            p.session_started_at_ms = None;
            p.time_today_seconds = 0;
            p.time_week_seconds = 0;
            p
        })
        .collect();
    crate::projects::write_projects_to(dir, &projects)?;

    crate::categories::write_categories_to(dir, &backup.categories)
        .map_err(|e| e.to_string())?;

    let root = templates_root_for(dir);
    let _ = fs::remove_dir_all(&root);
    let _ = fs::create_dir_all(&root);
    for t in &backup.templates {
        restore_template(&root.join(&t.meta.id), t);
    }

    crate::time_stats::write_stats_to(dir, &backup.time_stats);

    Ok(settings)
}

#[tauri::command]
pub fn export_workspace_backup(app: AppHandle, path: String) -> Result<(), String> {
    let backup = build_workspace_backup(&app)?;
    persist::write_json(Path::new(&path), &backup).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn import_workspace_backup(app: AppHandle, path: String) -> Result<AppSettings, String> {
    let backup: Option<WorkspaceBackup> = persist::read_json_opt(Path::new(&path));
    let Some(backup) = backup else {
        return Err("Couldn't read the workspace backup file".into());
    };
    let name = backup.workspace.name.clone();
    let icon = backup.workspace.icon.clone();
    let color = backup.workspace.color.clone();
    let active_id = crate::workspace::active_workspace_id(&app);
    let dir = crate::workspace::workspace_dir(&app, &active_id);
    let settings = apply_workspace_backup_in(&dir, backup)?;
    let _ = crate::workspace::update_workspace(
        app.clone(),
        active_id,
        Some(name),
        Some(icon),
        Some(color),
    );
    let _ = crate::watcher::restart_watchers(app.clone());
    Ok(settings)
}

#[derive(serde::Serialize, serde::Deserialize)]
pub struct AppBackup {
    exported_at: String,
    #[serde(default)]
    pub(crate) workspaces: Vec<WorkspaceBackup>,
}

pub(crate) fn build_app_backup(app: &AppHandle) -> Result<AppBackup, String> {
    let state = crate::workspace::read_state(app);
    let mut workspaces = Vec::new();
    for ws in &state.workspaces {
        let dir = crate::workspace::workspace_dir(app, &ws.id);
        workspaces.push(build_workspace_backup_in(&dir, ws));
    }
    Ok(AppBackup {
        exported_at: chrono::Utc::now().to_rfc3339(),
        workspaces,
    })
}

pub(crate) fn apply_app_backup(
    app: &AppHandle,
    backup: AppBackup,
) -> Result<AppSettings, String> {
    if backup.workspaces.is_empty() {
        return Err("The backup doesn't contain any workspaces".into());
    }

    let mut last_settings: Option<AppSettings> = None;
    let mut restored_ids: std::collections::HashSet<String> = std::collections::HashSet::new();

    for wb in backup.workspaces {
        let wname = wb.workspace.name.clone();
        let wicon = wb.workspace.icon.clone();
        let wcolor = wb.workspace.color.clone();
        let state = crate::workspace::read_state(app);
        let existing = state
            .workspaces
            .iter()
            .find(|w| w.name.eq_ignore_ascii_case(&wname))
            .cloned();
        match existing {
            Some(ws) => {
                restored_ids.insert(ws.id.clone());
                let dir = crate::workspace::workspace_dir(app, &ws.id);
                last_settings = Some(apply_workspace_backup_in(&dir, wb)?);
                let _ = crate::workspace::update_workspace(
                    app.clone(),
                    ws.id,
                    Some(wname),
                    Some(wicon),
                    Some(wcolor),
                );
            }
            None => {
                let ws = crate::workspace::create_workspace_silent(
                    app, wname, wicon, wcolor,
                )?;
                restored_ids.insert(ws.id.clone());
                let dir = crate::workspace::workspace_dir(app, &ws.id);
                last_settings = Some(apply_workspace_backup_in(&dir, wb)?);
            }
        }
    }

    {
        let mut state = crate::workspace::read_state(app);
        let to_remove: Vec<String> = state
            .workspaces
            .iter()
            .filter(|w| !restored_ids.contains(&w.id))
            .map(|w| w.id.clone())
            .collect();
        if !to_remove.is_empty() {
            for id in &to_remove {
                if let Some(idx) = state.workspaces.iter().position(|w| &w.id == id) {
                    state.workspaces.remove(idx);
                    let _ = std::fs::remove_dir_all(crate::workspace::workspace_dir(app, id));
                }
            }
            if state.workspaces.is_empty() {
            } else if !state.workspaces.iter().any(|w| w.id == state.active_id) {
                state.active_id = state.workspaces[0].id.clone();
            }
            let _ = crate::workspace::write_state(app, &state);
        }
    }

    let _ = crate::watcher::restart_watchers(app.clone());
    Ok(last_settings.unwrap_or_else(|| crate::settings::read_settings(app)))
}

#[tauri::command]
pub fn export_app_backup(app: AppHandle, path: String) -> Result<(), String> {
    let backup = build_app_backup(&app)?;
    persist::write_json(Path::new(&path), &backup).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn import_app_backup(app: AppHandle, path: String) -> Result<AppSettings, String> {
    let backup: Option<AppBackup> = persist::read_json_opt(Path::new(&path));
    let Some(backup) = backup else {
        return Err("Couldn't read the app backup file".into());
    };
    apply_app_backup(&app, backup)
}
