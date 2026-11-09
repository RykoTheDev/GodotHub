use godothub_core::export_runner::{ExportCatalog, ExportRun};

#[tauri::command]
pub async fn get_project_export_presets(app: tauri::AppHandle, id: String) -> Result<ExportCatalog, String> {
    let core = crate::core_handle(&app);
    godothub_core::export_runner::get_project_export_presets(core, id).await
}

#[tauri::command]
pub async fn start_project_export(app: tauri::AppHandle, id: String, preset_id: u32, output_path: String, overwrite: bool) -> Result<ExportRun, String> {
    let core = crate::core_handle(&app);
    godothub_core::export_runner::start_project_export(core, id, preset_id, output_path, overwrite).await
}

#[tauri::command]
pub async fn get_project_export(app: tauri::AppHandle, run_id: String) -> Result<ExportRun, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::export_runner::get_project_export(core, run_id)).await
}

#[tauri::command]
pub async fn get_project_exports(app: tauri::AppHandle, id: String) -> Vec<ExportRun> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::export_runner::get_project_exports(core, id)).await
}

#[tauri::command]
pub async fn cancel_project_export(app: tauri::AppHandle, run_id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::export_runner::cancel_project_export(core, run_id)).await
}

#[tauri::command]
pub async fn open_export_artifact_folder(app: tauri::AppHandle, run_id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::export_runner::open_export_artifact_folder(core, run_id)).await
}
