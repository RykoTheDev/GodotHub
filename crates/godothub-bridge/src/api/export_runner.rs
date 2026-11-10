#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn start_project_export(id: String, preset_id: u32, output_path: String, overwrite: bool) -> Result<ExportRun, CoreError> {
    let app = app()?;
    godothub_core::export_runner::start_project_export(app, id, preset_id, output_path, overwrite).await.map_err(CoreError::from)
}

pub async fn get_project_export(run_id: String) -> Result<ExportRun, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::export_runner::get_project_export(app, run_id)).await.map_err(CoreError::from)
}

pub async fn get_project_exports(id: String) -> Result<Vec<ExportRun>, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::export_runner::get_project_exports(app, id)).await)
}

pub async fn cancel_project_export(run_id: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::export_runner::cancel_project_export(app, run_id)).await.map_err(CoreError::from)
}

pub async fn open_export_artifact_folder(run_id: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::export_runner::open_export_artifact_folder(app, run_id)).await.map_err(CoreError::from)
}
