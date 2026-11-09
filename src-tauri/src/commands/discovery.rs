use godothub_core::discovery::{DiscoveredInstall, DiscoveredProject};
use godothub_core::models::InstalledGodotVersion;

#[tauri::command]
pub async fn scan_godot_recent_projects(app: tauri::AppHandle) -> Result<Vec<DiscoveredProject>, String> {
    let core = crate::core_handle(&app);
    godothub_core::discovery::scan_godot_recent_projects(core).await
}

#[tauri::command]
pub async fn detect_godot_installs(app: tauri::AppHandle) -> Result<Vec<DiscoveredInstall>, String> {
    let core = crate::core_handle(&app);
    godothub_core::discovery::detect_godot_installs(core).await
}

#[tauri::command]
pub async fn import_detected_install(app: tauri::AppHandle, path: String) -> Result<InstalledGodotVersion, String> {
    let core = crate::core_handle(&app);
    godothub_core::discovery::import_detected_install(core, path).await
}
