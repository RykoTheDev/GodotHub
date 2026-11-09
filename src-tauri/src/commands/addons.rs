use godothub_core::addons::{AddonUpdate, ProjectAddon};

#[tauri::command]
pub async fn list_project_addons(app: tauri::AppHandle, id: String) -> Result<Vec<ProjectAddon>, String> {
    let core = crate::core_handle(&app);
    godothub_core::addons::list_project_addons(core, id).await
}

#[tauri::command]
pub async fn check_addon_updates(app: tauri::AppHandle, id: String) -> Result<Vec<AddonUpdate>, String> {
    let core = crate::core_handle(&app);
    godothub_core::addons::check_addon_updates(core, id).await
}

#[tauri::command]
pub async fn update_project_addon(app: tauri::AppHandle, id: String, folder: String, asset_id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::addons::update_project_addon(core, id, folder, asset_id).await
}
