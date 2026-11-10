#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn get_activity(range: String) -> Result<Vec<(String, u64)>, CoreError> {
    let app = app()?;
    Ok(godothub_core::time_stats::get_activity(app, range).await)
}

pub async fn get_project_activity(project_id: String) -> Result<Vec<(String, u64)>, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::time_stats::get_project_activity(app, project_id)).await)
}

pub async fn get_time_insights() -> Result<TimeInsights, CoreError> {
    let app = app()?;
    Ok(godothub_core::time_stats::get_time_insights(app).await)
}

pub async fn clear_time_stats() -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::time_stats::clear_time_stats(app)).await.map_err(CoreError::from)
}
