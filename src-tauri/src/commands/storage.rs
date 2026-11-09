use godothub_core::storage::{ReclaimItem, ReclaimResult, StorageReport};

#[tauri::command]
pub async fn get_storage_report(app: tauri::AppHandle) -> Result<StorageReport, String> {
    let core = crate::core_handle(&app);
    godothub_core::storage::get_storage_report(core).await
}

#[tauri::command]
pub async fn reclaim_storage(app: tauri::AppHandle, items: Vec<ReclaimItem>) -> Result<ReclaimResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::storage::reclaim_storage(core, items).await
}
