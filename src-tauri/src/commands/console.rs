use godothub_core::console::{ConsoleSnapshot};

#[tauri::command]
pub async fn get_project_console(app: tauri::AppHandle, id: String, since: Option<u64>) -> ConsoleSnapshot {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::console::get_project_console(core, id, since)).await
}

#[tauri::command]
pub async fn clear_project_console(app: tauri::AppHandle, id: String) {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::console::clear_project_console(core, id)).await
}
