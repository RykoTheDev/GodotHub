#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_categories() -> Result<Vec<Category>, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::categories::list_categories(app)).await)
}

pub async fn create_category(name: String, color: Option<String>) -> Result<Category, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::create_category(app, name, color)).await.map_err(CoreError::from)
}

pub async fn update_category(id: String, name: Option<String>, color: Option<String>, hidden: Option<bool>) -> Result<Category, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::update_category(app, id, name, color, hidden)).await.map_err(CoreError::from)
}

pub async fn rename_category(id: String, name: String) -> Result<Category, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::rename_category(app, id, name)).await.map_err(CoreError::from)
}

pub async fn delete_category(id: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::delete_category(app, id)).await.map_err(CoreError::from)
}

pub async fn reorder_categories(ordered_ids: Vec<String>) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::reorder_categories(app, ordered_ids)).await.map_err(CoreError::from)
}

pub async fn add_category_folder(id: String, folder: String) -> Result<Category, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::add_category_folder(app, id, folder)).await.map_err(CoreError::from)
}

pub async fn remove_category_folder(id: String, folder: String) -> Result<Category, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::categories::remove_category_folder(app, id, folder)).await.map_err(CoreError::from)
}
