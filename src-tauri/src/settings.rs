use crate::models::AppSettings;
use std::fs;
use std::path::PathBuf;
use tauri::AppHandle;
use tauri_plugin_dialog::DialogExt;

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
    use tauri::Manager as _;
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    if dir.exists() {
        fs::remove_dir_all(&dir).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
pub async fn export_settings(app: AppHandle) -> Result<String, String> {
    let settings = read_settings(&app);
    let json = serde_json::to_string_pretty(&settings).map_err(|e| e.to_string())?;

    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .add_filter("JSON", &["json"])
        .set_file_name("godothub-settings.json")
        .save_file(move |file| {
            let _ = tx.send(file);
        });

    match rx.recv().ok().flatten() {
        Some(path) => {
            let path_str = path.as_path().ok_or("Invalid path")?.to_string_lossy().to_string();
            fs::write(&path_str, &json).map_err(|e| e.to_string())?;
            Ok(format!("Settings exported to {}", path_str))
        }
        None => Err("Export cancelled".into()),
    }
}

#[tauri::command]
pub async fn import_settings(app: AppHandle) -> Result<AppSettings, String> {
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .add_filter("JSON", &["json"])
        .pick_file(move |file| {
            let _ = tx.send(file);
        });

    let path = rx.recv().ok().flatten().ok_or("Import cancelled")?;
    let path_str = path.as_path().ok_or("Invalid path")?.to_string_lossy().to_string();
    let content = fs::read_to_string(&path_str).map_err(|e| e.to_string())?;
    let settings: AppSettings = serde_json::from_str(&content).map_err(|e| e.to_string())?;
    write_settings(&app, &settings)?;
    Ok(settings)
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
        ..AppSettings::default()
    };
    write_settings(&app, &reset)?;
    Ok(reset)
}
