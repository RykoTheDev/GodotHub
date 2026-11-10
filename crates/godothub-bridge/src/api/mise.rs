#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn mise_status() -> Result<MiseStatus, CoreError> {
    Ok(godothub_core::mise::mise_status().await)
}

pub async fn mise_refresh_status() -> Result<MiseStatus, CoreError> {
    Ok(godothub_core::mise::mise_refresh_status().await)
}

pub async fn mise_sync_godot_versions() -> Result<Vec<InstalledGodotVersion>, CoreError> {
    let app = app()?;
    godothub_core::mise::mise_sync_godot_versions(app).await.map_err(CoreError::from)
}

pub async fn mise_install_godot_version(tag: String) -> Result<Vec<InstalledGodotVersion>, CoreError> {
    let app = app()?;
    godothub_core::mise::mise_install_godot_version(app, tag).await.map_err(CoreError::from)
}

pub async fn mise_uninstall_godot_version(tag: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::mise::mise_uninstall_godot_version(app, tag).await.map_err(CoreError::from)
}
