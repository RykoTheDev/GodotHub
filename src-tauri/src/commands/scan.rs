use godothub_core::models::{InstalledGodotVersion, Project, ScanProjectsResult};

#[tauri::command]
pub async fn scan_for_projects(app: tauri::AppHandle, dirs: Vec<String>, depth: u32) -> Result<Vec<Project>, String> {
    let core = crate::core_handle(&app);
    godothub_core::scan::scan_for_projects(core, dirs, depth).await
}

#[tauri::command]
pub async fn scan_for_projects_with_info(app: tauri::AppHandle, dirs: Vec<String>, depth: u32) -> Result<ScanProjectsResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::scan::scan_for_projects_with_info(core, dirs, depth).await
}

#[tauri::command]
pub async fn scan_for_versions(app: tauri::AppHandle, dirs: Vec<String>, depth: u32) -> Result<Vec<InstalledGodotVersion>, String> {
    let core = crate::core_handle(&app);
    godothub_core::scan::scan_for_versions(core, dirs, depth).await
}

#[tauri::command]
pub async fn import_version(app: tauri::AppHandle, path: String) -> Result<Vec<InstalledGodotVersion>, String> {
    let core = crate::core_handle(&app);
    godothub_core::scan::import_version(core, path).await
}

#[tauri::command]
pub async fn add_custom_build(app: tauri::AppHandle, path: String, name: Option<String>) -> Result<InstalledGodotVersion, String> {
    let core = crate::core_handle(&app);
    godothub_core::scan::add_custom_build(core, path, name).await
}
