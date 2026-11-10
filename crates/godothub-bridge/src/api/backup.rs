#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn export_workspace_backup(path: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::backup::export_workspace_backup(app, path).await.map_err(CoreError::from)
}

pub async fn import_workspace_backup(path: String) -> Result<AppSettings, CoreError> {
    let app = app()?;
    godothub_core::backup::import_workspace_backup(app, path).await.map_err(CoreError::from)
}

pub async fn export_app_backup(path: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::backup::export_app_backup(app, path).await.map_err(CoreError::from)
}

pub async fn import_app_backup(path: String) -> Result<AppSettings, CoreError> {
    let app = app()?;
    godothub_core::backup::import_app_backup(app, path).await.map_err(CoreError::from)
}
