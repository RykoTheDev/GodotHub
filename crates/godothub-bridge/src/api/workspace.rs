#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_workspaces() -> Result<WorkspacesState, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::workspace::list_workspaces(app)).await)
}

pub async fn list_workspace_scan_dirs() -> Result<Vec<WorkspaceScanDirs>, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::workspace::list_workspace_scan_dirs(app)).await)
}

pub async fn create_workspace(name: String, icon: String, color: String, copy_settings_from: Option<String>) -> Result<WorkspacesState, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::workspace::create_workspace(app, name, icon, color, copy_settings_from)).await.map_err(CoreError::from)
}

pub async fn switch_workspace(id: String) -> Result<WorkspacesState, CoreError> {
    let app = app()?;
    godothub_core::workspace::switch_workspace(app, id).await.map_err(CoreError::from)
}

pub async fn update_workspace(id: String, name: Option<String>, icon: Option<String>, color: Option<String>) -> Result<WorkspacesState, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::workspace::update_workspace(app, id, name, icon, color)).await.map_err(CoreError::from)
}

pub async fn delete_workspace(id: String) -> Result<WorkspacesState, CoreError> {
    let app = app()?;
    godothub_core::workspace::delete_workspace(app, id).await.map_err(CoreError::from)
}
