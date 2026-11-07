use godothub_core::project_health::{HealthReport};

#[tauri::command]
pub async fn diagnose_project(app: tauri::AppHandle, id: String) -> Result<HealthReport, String> {
    let core = crate::core_handle(&app);
    godothub_core::project_health::diagnose_project(core, id).await
}

#[tauri::command]
pub async fn fix_project_health(app: tauri::AppHandle, id: String, check_id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::project_health::fix_project_health(core, id, check_id).await
}
