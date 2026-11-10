#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn list_projects() -> Result<Vec<Project>, CoreError> {
    let app = app()?;
    Ok(godothub_core::projects::list_projects(app).await)
}

pub async fn get_projects_health() -> Result<LoadStatus, CoreError> {
    let app = app()?;
    Ok(godothub_core::projects::get_projects_health(app).await)
}

pub async fn restore_projects_from_backup() -> Result<usize, CoreError> {
    let app = app()?;
    godothub_core::projects::restore_projects_from_backup(app).await.map_err(CoreError::from)
}

pub async fn create_project(name: String, location: String, godot_version: String, icon_path: Option<String>, template_id: Option<String>, category: Option<String>) -> Result<Project, CoreError> {
    let app = app()?;
    godothub_core::projects::create_project(app, name, location, godot_version, icon_path, template_id, category).await.map_err(CoreError::from)
}

pub async fn duplicate_project(id: String, name: String, dest_dir: Option<String>) -> Result<Project, CoreError> {
    let app = app()?;
    godothub_core::projects::duplicate_project(app, id, name, dest_dir).await.map_err(CoreError::from)
}

pub async fn import_project(path: String, godot_version: String, category: Option<String>) -> Result<Project, CoreError> {
    let app = app()?;
    godothub_core::projects::import_project(app, path, godot_version, category).await.map_err(CoreError::from)
}

pub async fn remove_project(id: String, delete_files: bool) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::projects::remove_project(app, id, delete_files).await.map_err(CoreError::from)
}

pub async fn update_project(id: String, updates: ProjectUpdate) -> Result<Project, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::projects::update_project(app, id, updates)).await.map_err(CoreError::from)
}

pub async fn reorder_projects(ordered_ids: Vec<String>) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::projects::reorder_projects(app, ordered_ids)).await.map_err(CoreError::from)
}

pub async fn open_project(id: String, editor: bool, console: Option<bool>) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::projects::open_project(app, id, editor, console).await.map_err(CoreError::from)
}

pub async fn open_project_folder(path: String) -> Result<(), CoreError> {
    godothub_core::projects::open_project_folder(path).await.map_err(CoreError::from)
}

pub async fn open_in_editor(path: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::projects::open_in_editor(app, path)).await.map_err(CoreError::from)
}

pub async fn get_project_icon(path: String) -> Result<Option<String>, CoreError> {
    let app = app()?;
    Ok(godothub_core::projects::get_project_icon(path, app).await)
}

pub async fn get_project_size(path: String) -> Result<ProjectSizeInfo, CoreError> {
    godothub_core::projects::get_project_size(path).await.map_err(CoreError::from)
}

pub async fn get_project_file_tree(path: String) -> Result<Vec<ProjectFileEntry>, CoreError> {
    godothub_core::projects::get_project_file_tree(path).await.map_err(CoreError::from)
}

pub async fn get_project_name(path: String) -> Result<Option<String>, CoreError> {
    Ok(godothub_core::projects::get_project_name(path).await)
}

pub async fn stop_project(id: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::projects::stop_project(app, id).await.map_err(CoreError::from)
}

pub async fn list_running_projects() -> Result<Vec<RunningProjectInfo>, CoreError> {
    let app = app()?;
    Ok(godothub_core::projects::list_running_projects(app).await)
}

pub async fn read_image_file(path: String) -> Result<Option<String>, CoreError> {
    Ok(godothub_core::projects::read_image_file(path).await)
}

pub async fn write_project_tags(id: String, path: String, tags: Vec<String>) -> Result<Project, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::projects::write_project_tags(app, id, path, tags)).await.map_err(CoreError::from)
}

pub async fn export_project_stats(path: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::projects::export_project_stats(app, path).await.map_err(CoreError::from)
}

pub async fn import_project_stats(path: String) -> Result<usize, CoreError> {
    let app = app()?;
    godothub_core::projects::import_project_stats(app, path).await.map_err(CoreError::from)
}

pub async fn reintroduce_dismissed_projects(paths: Vec<String>) -> Result<Vec<Project>, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::projects::reintroduce_dismissed_projects(app, paths)).await.map_err(CoreError::from)
}
