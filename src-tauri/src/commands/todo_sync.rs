use godothub_core::todo_sync::{TodoGitActivity, TodoSyncResult};

#[tauri::command]
pub async fn sync_project_todos(app: tauri::AppHandle, project_id: String, scan_comments: bool) -> Result<TodoSyncResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::todo_sync::sync_project_todos(core, project_id, scan_comments).await
}

#[tauri::command]
pub async fn todo_git_activity(app: tauri::AppHandle, project_id: String, number: u32) -> Result<TodoGitActivity, String> {
    let core = crate::core_handle(&app);
    godothub_core::todo_sync::todo_git_activity(core, project_id, number).await
}

#[tauri::command]
pub async fn list_project_resources(app: tauri::AppHandle, project_id: String) -> Result<Vec<String>, String> {
    let core = crate::core_handle(&app);
    godothub_core::todo_sync::list_project_resources(core, project_id).await
}

#[tauri::command]
pub async fn open_todo_link(app: tauri::AppHandle, project_id: String, path: String, line: Option<u32>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::todo_sync::open_todo_link(core, project_id, path, line)).await
}
