#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn sync_project_todos(project_id: String, scan_comments: bool) -> Result<TodoSyncResult, CoreError> {
    let app = app()?;
    godothub_core::todo_sync::sync_project_todos(app, project_id, scan_comments).await.map_err(CoreError::from)
}

pub async fn todo_git_activity(project_id: String, number: u32) -> Result<TodoGitActivity, CoreError> {
    let app = app()?;
    godothub_core::todo_sync::todo_git_activity(app, project_id, number).await.map_err(CoreError::from)
}

pub async fn list_project_resources(project_id: String) -> Result<Vec<String>, CoreError> {
    let app = app()?;
    godothub_core::todo_sync::list_project_resources(app, project_id).await.map_err(CoreError::from)
}

pub async fn open_todo_link(project_id: String, path: String, line: Option<u32>) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::todo_sync::open_todo_link(app, project_id, path, line)).await.map_err(CoreError::from)
}
