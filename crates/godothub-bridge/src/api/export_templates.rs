#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn get_export_templates_state() -> Result<ExportTemplatesState, CoreError> {
    let app = app()?;
    godothub_core::export_templates::get_export_templates_state(app).await.map_err(CoreError::from)
}

pub async fn get_export_template_options(tag: String, refresh: Option<bool>) -> Result<Vec<TemplateOption>, CoreError> {
    let app = app()?;
    godothub_core::export_templates::get_export_template_options(app, tag, refresh).await.map_err(CoreError::from)
}

pub async fn install_export_templates(tag: String, files: Option<Vec<String>>) -> Result<Option<ExportTemplatesInstallResult>, CoreError> {
    let app = app()?;
    godothub_core::export_templates::install_export_templates(app, tag, files).await.map_err(CoreError::from)
}

pub async fn cancel_export_templates_download(tag: String) -> Result<(), CoreError> {
    crate::lane::serial(move || godothub_core::export_templates::cancel_export_templates_download(tag)).await.map_err(CoreError::from)
}

pub async fn delete_export_templates(folder: String, root: Option<String>) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::export_templates::delete_export_templates(app, folder, root).await.map_err(CoreError::from)
}

pub async fn uninstall_export_template_files(tag: String, files: Vec<String>) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::export_templates::uninstall_export_template_files(app, tag, files).await.map_err(CoreError::from)
}

pub async fn open_export_templates_folder(tag: Option<String>) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::export_templates::open_export_templates_folder(app, tag)).await.map_err(CoreError::from)
}
