use godothub_core::tool_runner::{ProjectTool};

#[tauri::command]
pub async fn list_project_tools(app: tauri::AppHandle, id: String) -> Result<Vec<ProjectTool>, String> {
    let core = crate::core_handle(&app);
    godothub_core::tool_runner::list_project_tools(core, id).await
}

#[tauri::command]
pub async fn run_project_tool(app: tauri::AppHandle, id: String, tool: String) -> Result<String, String> {
    let core = crate::core_handle(&app);
    godothub_core::tool_runner::run_project_tool(core, id, tool).await
}

#[tauri::command]
pub async fn stop_project_tool(console_id: String) -> Result<(), String> {
    crate::lane::serial(move || godothub_core::tool_runner::stop_project_tool(console_id)).await
}
