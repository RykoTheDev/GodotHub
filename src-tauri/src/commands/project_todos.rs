use godothub_core::project_todos::{OpenTodo};
use godothub_core::models::ProjectTodo;

#[tauri::command]
pub async fn list_project_todos(app: tauri::AppHandle, project_id: String) -> Result<Vec<ProjectTodo>, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::project_todos::list_project_todos(core, project_id)).await
}

#[tauri::command]
pub async fn save_project_todos(app: tauri::AppHandle, project_id: String, todos: Vec<ProjectTodo>) -> Result<Vec<ProjectTodo>, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::project_todos::save_project_todos(core, project_id, todos)).await
}

#[tauri::command]
pub async fn list_open_todos(app: tauri::AppHandle) -> Result<Vec<OpenTodo>, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::project_todos::list_open_todos(core)).await
}
