#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn fetch_available_godot_versions(source: Option<String>) -> Result<Vec<GodotRelease>, CoreError> {
    let app = app()?;
    godothub_core::godot_versions::fetch_available_godot_versions(app, source).await.map_err(CoreError::from)
}

pub async fn open_versions_folder() -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::godot_versions::open_versions_folder(app)).await.map_err(CoreError::from)
}

pub async fn download_godot_version(tag: String, asset_name: String, download_url: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::godot_versions::download_godot_version(app, tag, asset_name, download_url)).await.map_err(CoreError::from)
}

pub async fn download_version_for_tag(tag: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::godot_versions::download_version_for_tag(app, tag).await.map_err(CoreError::from)
}

pub async fn pause_download(key: String) -> Result<(), CoreError> {
    crate::lane::serial(move || godothub_core::godot_versions::pause_download(key)).await.map_err(CoreError::from)
}

pub async fn resume_download(key: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::godot_versions::resume_download(app, key)).await.map_err(CoreError::from)
}

pub async fn cancel_download(key: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::godot_versions::cancel_download(app, key)).await.map_err(CoreError::from)
}

pub async fn reorder_download_queue(key: String, direction: i8) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::godot_versions::reorder_download_queue(app, key, direction)).await.map_err(CoreError::from)
}

pub async fn list_installed_godot_versions() -> Result<Vec<InstalledGodotVersion>, CoreError> {
    let app = app()?;
    godothub_core::godot_versions::list_installed_godot_versions(app).await.map_err(CoreError::from)
}

pub async fn rename_godot_version(tag: String, custom_name: Option<String>) -> Result<InstalledGodotVersion, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::godot_versions::rename_godot_version(app, tag, custom_name)).await.map_err(CoreError::from)
}

pub async fn delete_godot_version(tag: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::godot_versions::delete_godot_version(app, tag).await.map_err(CoreError::from)
}

pub async fn open_godot_version(tag: String, console: Option<bool>) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::godot_versions::open_godot_version(app, tag, console).await.map_err(CoreError::from)
}

pub async fn test_github_token() -> Result<RateLimitInfo, CoreError> {
    let app = app()?;
    godothub_core::godot_versions::test_github_token(app).await.map_err(CoreError::from)
}

pub async fn get_github_rate_limit() -> Result<RateLimitInfo, CoreError> {
    let app = app()?;
    godothub_core::godot_versions::get_github_rate_limit(app).await.map_err(CoreError::from)
}
