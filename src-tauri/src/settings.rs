use crate::models::AppSettings;
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

fn settings_file(app: &AppHandle) -> PathBuf {
    crate::workspace::active_workspace_dir(app).join("settings.json")
}

pub fn read_settings(app: &AppHandle) -> AppSettings {
    let file = settings_file(app);
    if !file.exists() {
        return AppSettings::default();
    }
    fs::read_to_string(&file)
        .ok()
        .and_then(|c| serde_json::from_str(&c).ok())
        .unwrap_or_default()
}

pub fn write_settings(app: &AppHandle, settings: &AppSettings) -> Result<(), String> {
    fs::write(
        settings_file(app),
        serde_json::to_string_pretty(settings).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_settings(app: AppHandle) -> AppSettings {
    read_settings(&app)
}

#[tauri::command]
pub fn update_settings(app: AppHandle, settings: AppSettings) -> Result<AppSettings, String> {
    write_settings(&app, &settings)?;
    Ok(settings)
}

#[tauri::command]
pub fn reset_app_data(app: AppHandle) -> Result<(), String> {
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    if dir.exists() {
        fs::remove_dir_all(&dir).map_err(|e| e.to_string())?;
    }
    Ok(())
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
        setup_complete: current.setup_complete,
        language: current.language,
        ..AppSettings::default()
    };
    write_settings(&app, &reset)?;
    Ok(reset)
}
