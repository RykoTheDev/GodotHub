#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_project_tools(id: String) -> Result<Vec<ProjectTool>, CoreError> {
    let app = app()?;
    godothub_core::tool_runner::list_project_tools(app, id).await.map_err(CoreError::from)
}

pub async fn run_project_tool(id: String, tool: String) -> Result<String, CoreError> {
    let app = app()?;
    godothub_core::tool_runner::run_project_tool(app, id, tool).await.map_err(CoreError::from)
}

pub async fn stop_project_tool(console_id: String) -> Result<(), CoreError> {
    crate::lane::serial(move || godothub_core::tool_runner::stop_project_tool(console_id)).await.map_err(CoreError::from)
}
