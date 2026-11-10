#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_project_todos(project_id: String) -> Result<Vec<ProjectTodo>, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::project_todos::list_project_todos(app, project_id)).await.map_err(CoreError::from)
}

pub async fn save_project_todos(project_id: String, todos: Vec<ProjectTodo>) -> Result<Vec<ProjectTodo>, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::project_todos::save_project_todos(app, project_id, todos)).await.map_err(CoreError::from)
}

pub async fn list_open_todos() -> Result<Vec<OpenTodo>, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::project_todos::list_open_todos(app)).await.map_err(CoreError::from)
}
