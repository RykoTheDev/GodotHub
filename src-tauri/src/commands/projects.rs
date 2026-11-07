use godothub_core::projects::{ProjectFileEntry, ProjectSizeInfo, RunningProjectInfo};
use godothub_core::models::{Project, ProjectUpdate};

#[tauri::command]
pub async fn list_projects(app: tauri::AppHandle) -> Vec<Project> {
    let core = crate::core_handle(&app);
    godothub_core::projects::list_projects(core).await
}

#[tauri::command]
pub async fn get_projects_health(app: tauri::AppHandle) -> godothub_core::persist::LoadStatus {
    let core = crate::core_handle(&app);
    godothub_core::projects::get_projects_health(core).await
}

#[tauri::command]
pub async fn restore_projects_from_backup(app: tauri::AppHandle) -> Result<usize, String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::restore_projects_from_backup(core).await
}

#[tauri::command]
pub async fn create_project(app: tauri::AppHandle, name: String, location: String, godot_version: String, icon_path: Option<String>, template_id: Option<String>, category: Option<String>) -> Result<Project, String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::create_project(core, name, location, godot_version, icon_path, template_id, category).await
}

#[tauri::command]
pub async fn duplicate_project(app: tauri::AppHandle, id: String, name: String, dest_dir: Option<String>) -> Result<Project, String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::duplicate_project(core, id, name, dest_dir).await
}

#[tauri::command]
pub async fn import_project(app: tauri::AppHandle, path: String, godot_version: String, category: Option<String>) -> Result<Project, String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::import_project(core, path, godot_version, category).await
}

#[tauri::command]
pub async fn remove_project(app: tauri::AppHandle, id: String, delete_files: bool) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::remove_project(core, id, delete_files).await
}

#[tauri::command]
pub async fn update_project(app: tauri::AppHandle, id: String, updates: ProjectUpdate) -> Result<Project, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::projects::update_project(core, id, updates)).await
}

#[tauri::command]
pub async fn reorder_projects(app: tauri::AppHandle, ordered_ids: Vec<String>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::projects::reorder_projects(core, ordered_ids)).await
}

#[tauri::command]
pub async fn open_project(app: tauri::AppHandle, id: String, editor: bool, console: Option<bool>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::open_project(core, id, editor, console).await
}

#[tauri::command]
pub async fn open_project_folder(path: String) -> Result<(), String> {
    godothub_core::projects::open_project_folder(path).await
}

#[tauri::command]
pub async fn open_in_editor(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::projects::open_in_editor(core, path)).await
}

#[tauri::command]
pub async fn get_project_icon(app: tauri::AppHandle, path: String) -> Option<String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::get_project_icon(path, core).await
}

#[tauri::command]
pub async fn get_project_size(path: String) -> Result<ProjectSizeInfo, String> {
    godothub_core::projects::get_project_size(path).await
}

#[tauri::command]
pub async fn get_project_file_tree(path: String) -> Result<Vec<ProjectFileEntry>, String> {
    godothub_core::projects::get_project_file_tree(path).await
}

#[tauri::command]
pub async fn get_project_name(path: String) -> Option<String> {
    godothub_core::projects::get_project_name(path).await
}

#[tauri::command]
pub async fn stop_project(app: tauri::AppHandle, id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::stop_project(core, id).await
}

#[tauri::command]
pub async fn list_running_projects(app: tauri::AppHandle) -> Vec<RunningProjectInfo> {
    let core = crate::core_handle(&app);
    godothub_core::projects::list_running_projects(core).await
}

#[tauri::command]
pub async fn read_image_file(path: String) -> Option<String> {
    godothub_core::projects::read_image_file(path).await
}

#[tauri::command]
pub async fn write_project_tags(app: tauri::AppHandle, id: String, path: String, tags: Vec<String>) -> Result<Project, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::projects::write_project_tags(core, id, path, tags)).await
}

#[tauri::command]
pub async fn export_project_stats(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::export_project_stats(core, path).await
}

#[tauri::command]
pub async fn import_project_stats(app: tauri::AppHandle, path: String) -> Result<usize, String> {
    let core = crate::core_handle(&app);
    godothub_core::projects::import_project_stats(core, path).await
}

#[tauri::command]
pub async fn reintroduce_dismissed_projects(app: tauri::AppHandle, paths: Vec<String>) -> Result<Vec<Project>, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::projects::reintroduce_dismissed_projects(core, paths)).await
}
