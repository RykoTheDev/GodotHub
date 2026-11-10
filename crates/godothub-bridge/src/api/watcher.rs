#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn restart_watchers() -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::watcher::restart_watchers(app)).await.map_err(CoreError::from)
}

pub async fn start_git_fs_watcher(path: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::watcher::start_git_fs_watcher(app, path)).await.map_err(CoreError::from)
}

pub async fn stop_git_fs_watcher() -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::watcher::stop_git_fs_watcher(app)).await;
    Ok(())
}
