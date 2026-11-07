use godothub_core::models::AppSettings;

#[tauri::command]
pub async fn get_settings(app: tauri::AppHandle) -> AppSettings {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::settings::get_settings(core)).await
}

#[tauri::command]
pub async fn update_settings(app: tauri::AppHandle, settings: AppSettings) -> Result<AppSettings, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::settings::update_settings(core, settings)).await
}

#[tauri::command]
pub async fn reset_settings(app: tauri::AppHandle) -> Result<AppSettings, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::settings::reset_settings(core)).await
}

#[tauri::command]
pub async fn export_settings(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::settings::export_settings(core, path)).await
}

#[tauri::command]
pub async fn import_settings(app: tauri::AppHandle, path: String) -> Result<AppSettings, String> {
    let core = crate::core_handle(&app);
    godothub_core::settings::import_settings(core, path).await
}

#[tauri::command]
pub async fn reset_app_data(app: tauri::AppHandle) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::settings::reset_app_data(core).await
}
