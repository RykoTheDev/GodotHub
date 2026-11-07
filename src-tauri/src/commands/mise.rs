use godothub_core::mise::{MiseStatus};
use godothub_core::models::InstalledGodotVersion;

#[tauri::command]
pub async fn mise_status() -> MiseStatus {
    godothub_core::mise::mise_status().await
}

#[tauri::command]
pub async fn mise_refresh_status() -> MiseStatus {
    godothub_core::mise::mise_refresh_status().await
}

#[tauri::command]
pub async fn mise_sync_godot_versions(app: tauri::AppHandle) -> Result<Vec<InstalledGodotVersion>, String> {
    let core = crate::core_handle(&app);
    godothub_core::mise::mise_sync_godot_versions(core).await
}

#[tauri::command]
pub async fn mise_install_godot_version(app: tauri::AppHandle, tag: String) -> Result<Vec<InstalledGodotVersion>, String> {
    let core = crate::core_handle(&app);
    godothub_core::mise::mise_install_godot_version(core, tag).await
}

#[tauri::command]
pub async fn mise_uninstall_godot_version(app: tauri::AppHandle, tag: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::mise::mise_uninstall_godot_version(core, tag).await
}
