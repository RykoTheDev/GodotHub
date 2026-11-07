use godothub_core::git_auth::{CreateRepoResult, DeviceFlowPoll, DeviceFlowStart, GitAuthState, UserRepoPage};

#[tauri::command]
pub async fn start_device_flow(app: tauri::AppHandle, provider: String, base_url: Option<String>, client_id: Option<String>) -> Result<DeviceFlowStart, String> {
    let core = crate::core_handle(&app);
    godothub_core::git_auth::start_device_flow(core, provider, base_url, client_id).await
}

#[tauri::command]
pub async fn poll_device_flow(app: tauri::AppHandle, provider: String, device_code: String, base_url: Option<String>, client_id: Option<String>) -> Result<DeviceFlowPoll, String> {
    let core = crate::core_handle(&app);
    godothub_core::git_auth::poll_device_flow(core, provider, device_code, base_url, client_id).await
}

#[tauri::command]
pub async fn get_git_auth_state(app: tauri::AppHandle) -> GitAuthState {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::git_auth::get_git_auth_state(core)).await
}

#[tauri::command]
pub async fn disconnect_git_auth(app: tauri::AppHandle, provider: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::git_auth::disconnect_git_auth(core, provider)).await
}

#[tauri::command]
pub async fn save_git_pat(app: tauri::AppHandle, host: String, username: String, token: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::git_auth::save_git_pat(core, host, username, token)).await
}

#[tauri::command]
pub async fn remove_git_pat(app: tauri::AppHandle, host: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::git_auth::remove_git_pat(core, host)).await
}

#[tauri::command]
pub async fn create_remote_repo(app: tauri::AppHandle, provider: String, name: String, private_repo: bool, path: String) -> Result<CreateRepoResult, String> {
    let core = crate::core_handle(&app);
    godothub_core::git_auth::create_remote_repo(core, provider, name, private_repo, path).await
}

#[tauri::command]
pub async fn list_user_repos(app: tauri::AppHandle, provider: String, page: u32) -> Result<UserRepoPage, String> {
    let core = crate::core_handle(&app);
    godothub_core::git_auth::list_user_repos(core, provider, page).await
}

#[tauri::command]
pub async fn git_branch_protection(app: tauri::AppHandle, path: String) -> Result<bool, String> {
    let core = crate::core_handle(&app);
    godothub_core::git_auth::git_branch_protection(core, path).await
}

#[tauri::command]
pub async fn git_open_pull_request(app: tauri::AppHandle, path: String, branch: String, base: String, title: String) -> Result<String, String> {
    let core = crate::core_handle(&app);
    godothub_core::git_auth::git_open_pull_request(core, path, branch, base, title).await
}
