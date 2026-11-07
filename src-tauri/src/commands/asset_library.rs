use godothub_core::asset_library::{AssetLibraryCategory, AssetLibraryResponse, InstallAssetResult};
use godothub_core::models::ProjectTemplate;

#[allow(clippy::too_many_arguments)]
#[tauri::command]
pub async fn search_asset_library(app: tauri::AppHandle, filter: Option<String>, godot_version: Option<String>, page: Option<u32>, max_results: Option<u32>, asset_type: Option<String>, category_id: Option<String>, sort: Option<String>, reverse: Option<bool>) -> Result<AssetLibraryResponse, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::search_asset_library(core, filter, godot_version, page, max_results, asset_type, category_id, sort, reverse).await
}

#[tauri::command]
pub async fn install_asset_as_template(app: tauri::AppHandle, asset_id: String) -> Result<ProjectTemplate, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::install_asset_as_template(core, asset_id).await
}

#[tauri::command]
pub async fn install_asset(app: tauri::AppHandle, asset_id: String, project_id: Option<String>, template_id: Option<String>) -> Result<InstallAssetResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::install_asset(core, asset_id, project_id, template_id).await
}

#[tauri::command]
pub async fn download_asset(app: tauri::AppHandle, asset_id: String, dest_dir: Option<String>) -> Result<String, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::download_asset(core, asset_id, dest_dir).await
}

#[tauri::command]
pub async fn search_asset_store(app: tauri::AppHandle, filter: Option<String>, godot_version: Option<String>, page: Option<u32>, max_results: Option<u32>, sort: Option<String>) -> Result<AssetLibraryResponse, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::search_asset_store(core, filter, godot_version, page, max_results, sort).await
}

#[tauri::command]
pub async fn download_store_asset(app: tauri::AppHandle, publisher_slug: String, asset_slug: String, title: Option<String>, dest_dir: Option<String>) -> Result<String, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::download_store_asset(core, publisher_slug, asset_slug, title, dest_dir).await
}

#[tauri::command]
pub async fn install_store_asset(app: tauri::AppHandle, publisher_slug: String, asset_slug: String, title: Option<String>, project_id: Option<String>, template_id: Option<String>) -> Result<InstallAssetResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::asset_library::install_store_asset(core, publisher_slug, asset_slug, title, project_id, template_id).await
}

#[tauri::command]
pub async fn get_asset_library_categories() -> Result<Vec<AssetLibraryCategory>, String> {
    godothub_core::asset_library::get_asset_library_categories().await
}
