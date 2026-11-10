#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_templates() -> Result<Vec<ProjectTemplate>, CoreError> {
    let app = app()?;
    godothub_core::templates::list_templates(app).await.map_err(CoreError::from)
}

pub async fn save_project_as_template(project_id: String, name: String, description: String) -> Result<ProjectTemplate, CoreError> {
    let app = app()?;
    godothub_core::templates::save_project_as_template(app, project_id, name, description).await.map_err(CoreError::from)
}

pub async fn delete_template(template_id: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::templates::delete_template(app, template_id).await.map_err(CoreError::from)
}

pub async fn sync_templates_with_scan_dir() -> Result<TemplateSyncResult, CoreError> {
    let app = app()?;
    godothub_core::templates::sync_templates_with_scan_dir(app).await.map_err(CoreError::from)
}

pub async fn get_template_preview(template_id: String) -> Result<Vec<TemplateFileEntry>, CoreError> {
    let app = app()?;
    godothub_core::templates::get_template_preview(app, template_id).await.map_err(CoreError::from)
}
