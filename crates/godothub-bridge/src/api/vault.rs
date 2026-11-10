#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_vault_items() -> Result<Vec<VaultItem>, CoreError> {
    let app = app()?;
    godothub_core::vault::list_vault_items(app).await.map_err(CoreError::from)
}

pub async fn save_to_vault(name: String, description: String, tags: Vec<String>, sources: Vec<VaultSaveSource>) -> Result<VaultItem, CoreError> {
    let app = app()?;
    godothub_core::vault::save_to_vault(app, name, description, tags, sources).await.map_err(CoreError::from)
}

pub async fn add_vault_item_to_projects(item_id: String, project_ids: Vec<String>, overwrite: bool) -> Result<Vec<VaultProjectImportResult>, CoreError> {
    let app = app()?;
    godothub_core::vault::add_vault_item_to_projects(app, item_id, project_ids, overwrite).await.map_err(CoreError::from)
}

pub async fn delete_vault_item(item_id: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::vault::delete_vault_item(app, item_id).await.map_err(CoreError::from)
}

pub async fn update_vault_item(item_id: String, name: String, description: String, tags: Vec<String>) -> Result<VaultItem, CoreError> {
    let app = app()?;
    godothub_core::vault::update_vault_item(app, item_id, name, description, tags).await.map_err(CoreError::from)
}
