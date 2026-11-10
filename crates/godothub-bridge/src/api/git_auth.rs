#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn start_device_flow(provider: String, base_url: Option<String>, client_id: Option<String>) -> Result<DeviceFlowStart, CoreError> {
    let app = app()?;
    godothub_core::git_auth::start_device_flow(app, provider, base_url, client_id).await.map_err(CoreError::from)
}

pub async fn get_git_auth_state() -> Result<GitAuthState, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::git_auth::get_git_auth_state(app)).await)
}

pub async fn disconnect_git_auth(provider: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::git_auth::disconnect_git_auth(app, provider)).await.map_err(CoreError::from)
}

pub async fn save_git_pat(host: String, username: String, token: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::git_auth::save_git_pat(app, host, username, token)).await.map_err(CoreError::from)
}

pub async fn remove_git_pat(host: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::git_auth::remove_git_pat(app, host)).await.map_err(CoreError::from)
}

pub async fn create_remote_repo(provider: String, name: String, private_repo: bool, path: String) -> Result<CreateRepoResult, CoreError> {
    let app = app()?;
    godothub_core::git_auth::create_remote_repo(app, provider, name, private_repo, path).await.map_err(CoreError::from)
}

pub async fn list_user_repos(provider: String, page: u32) -> Result<UserRepoPage, CoreError> {
    let app = app()?;
    godothub_core::git_auth::list_user_repos(app, provider, page).await.map_err(CoreError::from)
}

pub async fn git_branch_protection(path: String) -> Result<bool, CoreError> {
    let app = app()?;
    godothub_core::git_auth::git_branch_protection(app, path).await.map_err(CoreError::from)
}

pub async fn git_open_pull_request(path: String, branch: String, base: String, title: String) -> Result<String, CoreError> {
    let app = app()?;
    godothub_core::git_auth::git_open_pull_request(app, path, branch, base, title).await.map_err(CoreError::from)
}
