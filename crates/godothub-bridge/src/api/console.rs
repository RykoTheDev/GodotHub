#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn get_project_console(id: String, since: Option<u64>) -> Result<ConsoleSnapshot, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::console::get_project_console(app, id, since)).await)
}

pub async fn clear_project_console(id: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::console::clear_project_console(app, id)).await;
    Ok(())
}
