use godothub_core::models::{AppSettings};

#[tauri::command]
pub async fn export_workspace_backup(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::backup::export_workspace_backup(core, path).await
}

#[tauri::command]
pub async fn import_workspace_backup(app: tauri::AppHandle, path: String) -> Result<AppSettings, String> {
    let core = crate::core_handle(&app);
    godothub_core::backup::import_workspace_backup(core, path).await
}

#[tauri::command]
pub async fn export_app_backup(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::backup::export_app_backup(core, path).await
}

#[tauri::command]
pub async fn import_app_backup(app: tauri::AppHandle, path: String) -> Result<AppSettings, String> {
    let core = crate::core_handle(&app);
    godothub_core::backup::import_app_backup(core, path).await
}
