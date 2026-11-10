#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

#[allow(clippy::too_many_arguments)]
pub async fn search_asset_library(filter: Option<String>, godot_version: Option<String>, page: Option<u32>, max_results: Option<u32>, asset_type: Option<String>, category_id: Option<String>, sort: Option<String>, reverse: Option<bool>) -> Result<AssetLibraryResponse, CoreError> {
    let app = app()?;
    godothub_core::asset_library::search_asset_library(app, filter, godot_version, page, max_results, asset_type, category_id, sort, reverse).await.map_err(CoreError::from)
}

pub async fn install_asset_as_template(asset_id: String) -> Result<ProjectTemplate, CoreError> {
    let app = app()?;
    godothub_core::asset_library::install_asset_as_template(app, asset_id).await.map_err(CoreError::from)
}

pub async fn install_asset(asset_id: String, project_id: Option<String>, template_id: Option<String>) -> Result<InstallAssetResult, CoreError> {
    let app = app()?;
    godothub_core::asset_library::install_asset(app, asset_id, project_id, template_id).await.map_err(CoreError::from)
}

pub async fn download_asset(asset_id: String, dest_dir: Option<String>) -> Result<String, CoreError> {
    let app = app()?;
    godothub_core::asset_library::download_asset(app, asset_id, dest_dir).await.map_err(CoreError::from)
}

pub async fn search_asset_store(filter: Option<String>, godot_version: Option<String>, page: Option<u32>, max_results: Option<u32>, sort: Option<String>) -> Result<AssetLibraryResponse, CoreError> {
    let app = app()?;
    godothub_core::asset_library::search_asset_store(app, filter, godot_version, page, max_results, sort).await.map_err(CoreError::from)
}

pub async fn download_store_asset(publisher_slug: String, asset_slug: String, title: Option<String>, dest_dir: Option<String>) -> Result<String, CoreError> {
    let app = app()?;
    godothub_core::asset_library::download_store_asset(app, publisher_slug, asset_slug, title, dest_dir).await.map_err(CoreError::from)
}

pub async fn install_store_asset(publisher_slug: String, asset_slug: String, title: Option<String>, project_id: Option<String>, template_id: Option<String>) -> Result<InstallAssetResult, CoreError> {
    let app = app()?;
    godothub_core::asset_library::install_store_asset(app, publisher_slug, asset_slug, title, project_id, template_id).await.map_err(CoreError::from)
}

pub async fn get_asset_library_categories() -> Result<Vec<AssetLibraryCategory>, CoreError> {
    godothub_core::asset_library::get_asset_library_categories().await.map_err(CoreError::from)
}
