
#[tauri::command]
pub async fn restart_watchers(app: tauri::AppHandle) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::watcher::restart_watchers(core)).await
}

#[tauri::command]
pub async fn start_git_fs_watcher(app: tauri::AppHandle, path: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::watcher::start_git_fs_watcher(core, path)).await
}

#[tauri::command]
pub async fn stop_git_fs_watcher(app: tauri::AppHandle) {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::watcher::stop_git_fs_watcher(core)).await
}
