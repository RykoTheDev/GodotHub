#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn cli_tool_status() -> Result<CliToolStatus, CoreError> {
    let app = app()?;
    Ok(godothub_core::cli_shim::cli_tool_status(app).await)
}

pub async fn install_cli_tool() -> Result<CliToolStatus, CoreError> {
    let app = app()?;
    godothub_core::cli_shim::install_cli_tool(app).await.map_err(CoreError::from)
}

pub async fn uninstall_cli_tool() -> Result<CliToolStatus, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::cli_shim::uninstall_cli_tool(app)).await.map_err(CoreError::from)
}
