#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn scan_for_projects(dirs: Vec<String>, depth: u32) -> Result<Vec<Project>, CoreError> {
    let app = app()?;
    godothub_core::scan::scan_for_projects(app, dirs, depth).await.map_err(CoreError::from)
}

pub async fn scan_for_projects_with_info(dirs: Vec<String>, depth: u32) -> Result<ScanProjectsResult, CoreError> {
    let app = app()?;
    godothub_core::scan::scan_for_projects_with_info(app, dirs, depth).await.map_err(CoreError::from)
}

pub async fn scan_for_versions(dirs: Vec<String>, depth: u32) -> Result<Vec<InstalledGodotVersion>, CoreError> {
    let app = app()?;
    godothub_core::scan::scan_for_versions(app, dirs, depth).await.map_err(CoreError::from)
}

pub async fn import_version(path: String) -> Result<Vec<InstalledGodotVersion>, CoreError> {
    let app = app()?;
    godothub_core::scan::import_version(app, path).await.map_err(CoreError::from)
}

pub async fn add_custom_build(path: String, name: Option<String>) -> Result<InstalledGodotVersion, CoreError> {
    let app = app()?;
    godothub_core::scan::add_custom_build(app, path, name).await.map_err(CoreError::from)
}
