#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn gist_sync_push() -> Result<GistSyncResult, CoreError> {
    let app = app()?;
    godothub_core::sync::gist_sync_push(app).await.map_err(CoreError::from)
}

pub async fn gist_sync_pull() -> Result<AppSettings, CoreError> {
    let app = app()?;
    godothub_core::sync::gist_sync_pull(app).await.map_err(CoreError::from)
}

pub async fn gist_sync_get_info() -> Result<Option<GistSyncResult>, CoreError> {
    let app = app()?;
    Ok(godothub_core::sync::gist_sync_get_info(app).await)
}

pub async fn gist_sync_pull_by_url(gist_url: String) -> Result<AppSettings, CoreError> {
    let app = app()?;
    godothub_core::sync::gist_sync_pull_by_url(app, gist_url).await.map_err(CoreError::from)
}

pub async fn gist_sync_fetch_backup() -> Result<RestorePreview, CoreError> {
    let app = app()?;
    godothub_core::sync::gist_sync_fetch_backup(app).await.map_err(CoreError::from)
}

pub async fn gist_sync_save_gist_url(gist_url: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::sync::gist_sync_save_gist_url(app, gist_url)).await.map_err(CoreError::from)
}
