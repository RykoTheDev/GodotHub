use godothub_core::cli_shim::{CliToolStatus};

#[tauri::command]
pub async fn cli_tool_status(app: tauri::AppHandle) -> CliToolStatus {
    let core = crate::core_handle(&app);
    godothub_core::cli_shim::cli_tool_status(core).await
}

#[tauri::command]
pub async fn install_cli_tool(app: tauri::AppHandle) -> Result<CliToolStatus, String> {
    let core = crate::core_handle(&app);
    godothub_core::cli_shim::install_cli_tool(core).await
}

#[tauri::command]
pub async fn uninstall_cli_tool(app: tauri::AppHandle) -> Result<CliToolStatus, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::cli_shim::uninstall_cli_tool(core)).await
}
