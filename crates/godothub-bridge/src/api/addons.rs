#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_project_addons(id: String) -> Result<Vec<ProjectAddon>, CoreError> {
    let app = app()?;
    godothub_core::addons::list_project_addons(app, id).await.map_err(CoreError::from)
}

pub async fn check_addon_updates(id: String) -> Result<Vec<AddonUpdate>, CoreError> {
    let app = app()?;
    godothub_core::addons::check_addon_updates(app, id).await.map_err(CoreError::from)
}

pub async fn update_project_addon(id: String, folder: String, asset_id: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::addons::update_project_addon(app, id, folder, asset_id).await.map_err(CoreError::from)
}
