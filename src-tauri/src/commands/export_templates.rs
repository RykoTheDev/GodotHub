use godothub_core::export_templates::{ExportTemplatesInstallResult, ExportTemplatesState};

#[tauri::command]
pub async fn get_export_templates_state(app: tauri::AppHandle) -> Result<ExportTemplatesState, String> {
    let core = crate::core_handle(&app);
    godothub_core::export_templates::get_export_templates_state(core).await
}

#[tauri::command]
pub async fn get_export_template_options(app: tauri::AppHandle, tag: String, refresh: Option<bool>) -> Result<Vec<godothub_core::export_templates::archive::TemplateOption>, String> {
    let core = crate::core_handle(&app);
    godothub_core::export_templates::get_export_template_options(core, tag, refresh).await
}

#[tauri::command]
pub async fn install_export_templates(app: tauri::AppHandle, tag: String, files: Option<Vec<String>>) -> Result<Option<ExportTemplatesInstallResult>, String> {
    let core = crate::core_handle(&app);
    godothub_core::export_templates::install_export_templates(core, tag, files).await
}

#[tauri::command]
pub async fn cancel_export_templates_download(tag: String) -> Result<(), String> {
    crate::lane::serial(move || godothub_core::export_templates::cancel_export_templates_download(tag)).await
}

#[tauri::command]
pub async fn delete_export_templates(app: tauri::AppHandle, folder: String, root: Option<String>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::export_templates::delete_export_templates(core, folder, root).await
}

#[tauri::command]
pub async fn uninstall_export_template_files(app: tauri::AppHandle, tag: String, files: Vec<String>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::export_templates::uninstall_export_template_files(core, tag, files).await
}

#[tauri::command]
pub async fn open_export_templates_folder(app: tauri::AppHandle, tag: Option<String>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::export_templates::open_export_templates_folder(core, tag)).await
}
