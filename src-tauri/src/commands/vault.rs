use godothub_core::models::{VaultItem, VaultProjectImportResult, VaultSaveSource};

#[tauri::command]
pub async fn list_vault_items(app: tauri::AppHandle) -> Result<Vec<VaultItem>, String> {
    let core = crate::core_handle(&app);
    godothub_core::vault::list_vault_items(core).await
}

#[tauri::command]
pub async fn save_to_vault(app: tauri::AppHandle, name: String, description: String, tags: Vec<String>, sources: Vec<VaultSaveSource>) -> Result<VaultItem, String> {
    let core = crate::core_handle(&app);
    godothub_core::vault::save_to_vault(core, name, description, tags, sources).await
}

#[tauri::command]
pub async fn add_vault_item_to_projects(app: tauri::AppHandle, item_id: String, project_ids: Vec<String>, overwrite: bool) -> Result<Vec<VaultProjectImportResult>, String> {
    let core = crate::core_handle(&app);
    godothub_core::vault::add_vault_item_to_projects(core, item_id, project_ids, overwrite).await
}

#[tauri::command]
pub async fn delete_vault_item(app: tauri::AppHandle, item_id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::vault::delete_vault_item(core, item_id).await
}

#[tauri::command]
pub async fn update_vault_item(app: tauri::AppHandle, item_id: String, name: String, description: String, tags: Vec<String>) -> Result<VaultItem, String> {
    let core = crate::core_handle(&app);
    godothub_core::vault::update_vault_item(core, item_id, name, description, tags).await
}
