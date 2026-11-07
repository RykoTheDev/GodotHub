use godothub_core::sync::{GistSyncResult, RestorePreview};

#[tauri::command]
pub async fn gist_sync_push(app: tauri::AppHandle) -> Result<GistSyncResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::sync::gist_sync_push(core).await
}

#[tauri::command]
pub async fn gist_sync_pull(app: tauri::AppHandle) -> Result<godothub_core::models::AppSettings, String> {
    let core = crate::core_handle(&app);
    godothub_core::sync::gist_sync_pull(core).await
}

#[tauri::command]
pub async fn gist_sync_get_info(app: tauri::AppHandle) -> Option<GistSyncResult> {
    let core = crate::core_handle(&app);
    godothub_core::sync::gist_sync_get_info(core).await
}

#[tauri::command]
pub async fn gist_sync_pull_by_url(app: tauri::AppHandle, gist_url: String) -> Result<godothub_core::models::AppSettings, String> {
    let core = crate::core_handle(&app);
    godothub_core::sync::gist_sync_pull_by_url(core, gist_url).await
}

#[tauri::command]
pub async fn gist_sync_fetch_backup(app: tauri::AppHandle) -> Result<RestorePreview, String> {
    let core = crate::core_handle(&app);
    godothub_core::sync::gist_sync_fetch_backup(core).await
}

#[tauri::command]
pub async fn gist_sync_save_gist_url(app: tauri::AppHandle, gist_url: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::sync::gist_sync_save_gist_url(core, gist_url)).await
}
