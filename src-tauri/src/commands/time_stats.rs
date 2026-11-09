use godothub_core::time_stats::{TimeInsights};

#[tauri::command]
pub async fn get_activity(app: tauri::AppHandle, range: String) -> Vec<(String, u64)> {
    let core = crate::core_handle(&app);
    godothub_core::time_stats::get_activity(core, range).await
}

#[tauri::command]
pub async fn get_project_activity(app: tauri::AppHandle, project_id: String) -> Vec<(String, u64)> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::time_stats::get_project_activity(core, project_id)).await
}

#[tauri::command]
pub async fn get_time_insights(app: tauri::AppHandle) -> TimeInsights {
    let core = crate::core_handle(&app);
    godothub_core::time_stats::get_time_insights(core).await
}

#[tauri::command]
pub async fn clear_time_stats(app: tauri::AppHandle) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::time_stats::clear_time_stats(core)).await
}
