use crate::error::AppResult;
use crate::persist;
use crate::models::AppSettings;
use std::path::Path;
use tauri::{AppHandle, Manager};

pub fn read_settings_from(dir: &Path) -> AppSettings {
    persist::read_json(&dir.join("settings.json"))
}

pub fn read_settings(app: &AppHandle) -> AppSettings {
    read_settings_from(&crate::workspace::active_workspace_dir(app))
}

pub fn write_settings_to(dir: &Path, settings: &AppSettings) -> AppResult<()> {
    persist::write_json(&dir.join("settings.json"), settings)
}

pub fn write_settings(app: &AppHandle, settings: &AppSettings) -> AppResult<()> {
    write_settings_to(&crate::workspace::active_workspace_dir(app), settings)
}

#[tauri::command]
pub fn get_settings(app: AppHandle) -> AppSettings {
    read_settings(&app)
}

#[tauri::command]
pub fn update_settings(app: AppHandle, mut settings: AppSettings) -> Result<AppSettings, String> {
    settings.dismissed_project_paths = read_settings(&app).dismissed_project_paths;
    write_settings(&app, &settings).map_err(|e| e.to_string())?;
    Ok(settings)
}

#[tauri::command]
pub fn reset_app_data(app: AppHandle) -> Result<(), String> {
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    if dir.exists() {
        std::fs::remove_dir_all(&dir).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[derive(serde::Serialize, serde::Deserialize)]
struct ProjectTotalTime {
    path: String,
    total_time_seconds: u64,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct SettingsExport {
    exported_at: String,
    settings: AppSettings,
    #[serde(default)]
    time_stats: Option<crate::time_stats::TimeStatsStore>,
    #[serde(default)]
    project_totals: Option<Vec<ProjectTotalTime>>,
}

#[tauri::command]
pub fn export_settings(app: AppHandle, path: String) -> Result<(), String> {
    let projects = crate::projects::read_projects(&app);
    let data = SettingsExport {
        exported_at: chrono::Utc::now().to_rfc3339(),
        settings: read_settings(&app),
        time_stats: Some(crate::time_stats::read_stats(&app)),
        project_totals: Some(
            projects
                .iter()
                .map(|p| ProjectTotalTime {
                    path: p.path.clone(),
                    total_time_seconds: p.total_time_seconds,
                })
                .collect(),
        ),
    };
    persist::write_json(Path::new(&path), &data).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn import_settings(app: AppHandle, path: String) -> Result<AppSettings, String> {
    let data: Option<SettingsExport> = persist::read_json_opt(Path::new(&path));
    let Some(data) = data else {
        return Err("Couldn't read the settings backup file".into());
    };
    let current = read_settings(&app);
    let mut merged = data.settings;
    merged.dismissed_project_paths = current.dismissed_project_paths;
    merged.setup_complete = true;
    write_settings(&app, &merged).map_err(|e| e.to_string())?;

    if let Some(store) = data.time_stats {
        crate::time_stats::write_stats(&app, &store);
    }
    if let Some(totals) = data.project_totals {
        let mut projects = crate::projects::read_projects(&app);
        let mut changed = false;
        for t in &totals {
            if let Some(p) = projects
                .iter_mut()
                .find(|p| crate::projects::same_path(&p.path, &t.path))
            {
                if p.total_time_seconds != t.total_time_seconds {
                    p.total_time_seconds = t.total_time_seconds;
                    changed = true;
                }
            }
        }
        if changed {
            let _ = crate::projects::write_projects(&app, &projects);
        }
    }
    Ok(merged)
}

#[tauri::command]
pub fn reset_settings(app: AppHandle) -> Result<AppSettings, String> {
    let current = read_settings(&app);
    let reset = AppSettings {
        download_dir: current.download_dir,
        default_project_location: current.default_project_location,
        project_scan_dirs: current.project_scan_dirs,
        version_scan_dirs: current.version_scan_dirs,
        scan_depth: current.scan_depth,
        icon_scan_depth: current.icon_scan_depth,
        setup_complete: current.setup_complete,
        language: current.language,
        dismissed_project_paths: current.dismissed_project_paths,
        ..AppSettings::default()
    };
    write_settings(&app, &reset).map_err(|e| e.to_string())?;
    Ok(reset)
}
