#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn scan_godot_recent_projects() -> Result<Vec<DiscoveredProject>, CoreError> {
    let app = app()?;
    godothub_core::discovery::scan_godot_recent_projects(app).await.map_err(CoreError::from)
}

pub async fn detect_godot_installs() -> Result<Vec<DiscoveredInstall>, CoreError> {
    let app = app()?;
    godothub_core::discovery::detect_godot_installs(app).await.map_err(CoreError::from)
}

pub async fn import_detected_install(path: String) -> Result<InstalledGodotVersion, CoreError> {
    let app = app()?;
    godothub_core::discovery::import_detected_install(app, path).await.map_err(CoreError::from)
}
