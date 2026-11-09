use godothub_core::godot_versions::{RateLimitInfo};
use godothub_core::models::{GodotRelease, InstalledGodotVersion};

#[tauri::command]
pub async fn fetch_available_godot_versions(app: tauri::AppHandle, source: Option<String>) -> Result<Vec<GodotRelease>, String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::fetch_available_godot_versions(core, source).await
}

#[tauri::command]
pub async fn open_versions_folder(app: tauri::AppHandle) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::godot_versions::open_versions_folder(core)).await
}

#[tauri::command]
pub async fn download_godot_version(app: tauri::AppHandle, tag: String, asset_name: String, download_url: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::godot_versions::download_godot_version(core, tag, asset_name, download_url)).await
}

#[tauri::command]
pub async fn download_version_for_tag(app: tauri::AppHandle, tag: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::download_version_for_tag(core, tag).await
}

#[tauri::command]
pub async fn pause_download(key: String) -> Result<(), String> {
    crate::lane::serial(move || godothub_core::godot_versions::pause_download(key)).await
}

#[tauri::command]
pub async fn resume_download(app: tauri::AppHandle, key: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::godot_versions::resume_download(core, key)).await
}

#[tauri::command]
pub async fn cancel_download(app: tauri::AppHandle, key: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::godot_versions::cancel_download(core, key)).await
}

#[tauri::command]
pub async fn reorder_download_queue(app: tauri::AppHandle, key: String, direction: i8) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::godot_versions::reorder_download_queue(core, key, direction)).await
}

#[tauri::command]
pub async fn list_installed_godot_versions(app: tauri::AppHandle) -> Result<Vec<InstalledGodotVersion>, String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::list_installed_godot_versions(core).await
}

#[tauri::command]
pub async fn rename_godot_version(app: tauri::AppHandle, tag: String, custom_name: Option<String>) -> Result<InstalledGodotVersion, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::godot_versions::rename_godot_version(core, tag, custom_name)).await
}

#[tauri::command]
pub async fn delete_godot_version(app: tauri::AppHandle, tag: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::delete_godot_version(core, tag).await
}

#[tauri::command]
pub async fn open_godot_version(app: tauri::AppHandle, tag: String, console: Option<bool>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::open_godot_version(core, tag, console).await
}

#[tauri::command]
pub async fn test_github_token(app: tauri::AppHandle) -> Result<RateLimitInfo, String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::test_github_token(core).await
}

#[tauri::command]
pub async fn get_github_rate_limit(app: tauri::AppHandle) -> Result<RateLimitInfo, String> {
    let core = crate::core_handle(&app);
    godothub_core::godot_versions::get_github_rate_limit(core).await
}
