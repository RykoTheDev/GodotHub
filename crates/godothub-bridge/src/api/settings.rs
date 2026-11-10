#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn get_settings() -> Result<AppSettings, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::settings::get_settings(app)).await)
}

pub async fn update_settings(settings: AppSettings) -> Result<AppSettings, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::settings::update_settings(app, settings)).await.map_err(CoreError::from)
}

pub async fn reset_settings() -> Result<AppSettings, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::settings::reset_settings(app)).await.map_err(CoreError::from)
}

pub async fn export_settings(path: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::settings::export_settings(app, path)).await.map_err(CoreError::from)
}

pub async fn import_settings(path: String) -> Result<AppSettings, CoreError> {
    let app = app()?;
    godothub_core::settings::import_settings(app, path).await.map_err(CoreError::from)
}

pub async fn reset_app_data() -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::settings::reset_app_data(app).await.map_err(CoreError::from)
}
