use godothub_core::current_version::{AliasBatchResult, AliasRequest, CurrentVersionInfo, VersionAliases};

#[tauri::command]
pub async fn get_current_version(app: tauri::AppHandle) -> Option<CurrentVersionInfo> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::current_version::get_current_version(core)).await
}

#[tauri::command]
pub async fn set_current_version(app: tauri::AppHandle, tag: String) -> Result<CurrentVersionInfo, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::current_version::set_current_version(core, tag)).await
}

#[tauri::command]
pub async fn clear_current_version(app: tauri::AppHandle) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::current_version::clear_current_version(core)).await
}

#[tauri::command]
pub async fn list_version_aliases(app: tauri::AppHandle) -> VersionAliases {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::current_version::list_version_aliases(core)).await
}

#[tauri::command]
pub async fn create_version_aliases(app: tauri::AppHandle, entries: Vec<AliasRequest>) -> AliasBatchResult {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::current_version::create_version_aliases(core, entries)).await
}

#[tauri::command]
pub async fn delete_version_alias(app: tauri::AppHandle, name: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::current_version::delete_version_alias(core, name)).await
}
