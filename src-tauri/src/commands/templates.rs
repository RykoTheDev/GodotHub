use godothub_core::models::{ProjectTemplate, TemplateFileEntry, TemplateSyncResult};

#[tauri::command]
pub async fn list_templates(app: tauri::AppHandle) -> Result<Vec<ProjectTemplate>, String> {
    let core = crate::core_handle(&app);
    godothub_core::templates::list_templates(core).await
}

#[tauri::command]
pub async fn save_project_as_template(app: tauri::AppHandle, project_id: String, name: String, description: String) -> Result<ProjectTemplate, String> {
    let core = crate::core_handle(&app);
    godothub_core::templates::save_project_as_template(core, project_id, name, description).await
}

#[tauri::command]
pub async fn delete_template(app: tauri::AppHandle, template_id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::templates::delete_template(core, template_id).await
}

#[tauri::command]
pub async fn sync_templates_with_scan_dir(app: tauri::AppHandle) -> Result<TemplateSyncResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::templates::sync_templates_with_scan_dir(core).await
}

#[tauri::command]
pub async fn get_template_preview(app: tauri::AppHandle, template_id: String) -> Result<Vec<TemplateFileEntry>, String> {
    let core = crate::core_handle(&app);
    godothub_core::templates::get_template_preview(core, template_id).await
}
