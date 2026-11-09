use godothub_core::models::{WorkspaceScanDirs, WorkspacesState};

#[tauri::command]
pub async fn list_workspaces(app: tauri::AppHandle) -> WorkspacesState {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::workspace::list_workspaces(core)).await
}

#[tauri::command]
pub async fn list_workspace_scan_dirs(app: tauri::AppHandle) -> Vec<WorkspaceScanDirs> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::workspace::list_workspace_scan_dirs(core)).await
}

#[tauri::command]
pub async fn create_workspace(app: tauri::AppHandle, name: String, icon: String, color: String, copy_settings_from: Option<String>) -> Result<WorkspacesState, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::workspace::create_workspace(core, name, icon, color, copy_settings_from)).await
}

#[tauri::command]
pub async fn switch_workspace(app: tauri::AppHandle, id: String) -> Result<WorkspacesState, String> {
    let core = crate::core_handle(&app);
    godothub_core::workspace::switch_workspace(core, id).await
}

#[tauri::command]
pub async fn update_workspace(app: tauri::AppHandle, id: String, name: Option<String>, icon: Option<String>, color: Option<String>) -> Result<WorkspacesState, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::workspace::update_workspace(core, id, name, icon, color)).await
}

#[tauri::command]
pub async fn delete_workspace(app: tauri::AppHandle, id: String) -> Result<WorkspacesState, String> {
    let core = crate::core_handle(&app);
    godothub_core::workspace::delete_workspace(core, id).await
}
