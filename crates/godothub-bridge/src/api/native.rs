use super::error::CoreError;

pub struct RecentProject {
    pub id: String,
    pub label: String,
    pub path: String,
}

pub struct DiscordActivity {
    pub name: Option<String>,
    pub details: Option<String>,
    pub state: Option<String>,
    pub start_timestamp: Option<i64>,
}

fn dialog() -> rfd::AsyncFileDialog {
    rfd::AsyncFileDialog::new()
}

fn path_of(handle: Option<rfd::FileHandle>) -> Option<String> {
    handle.map(|h| h.path().to_string_lossy().to_string())
}

pub async fn pick_folder() -> Option<String> {
    path_of(dialog().pick_folder().await)
}

pub async fn pick_save_path(default_name: String) -> Option<String> {
    path_of(dialog().set_file_name(default_name).save_file().await)
}

pub async fn pick_data_file() -> Option<String> {
    path_of(dialog().add_filter("JSON", &["json"]).pick_file().await)
}

pub async fn pick_image_file() -> Option<String> {
    path_of(dialog().add_filter("Images", &["png", "svg", "jpg", "jpeg", "webp"]).pick_file().await)
}

pub async fn pick_executable() -> Option<String> {
    #[cfg(target_os = "macos")]
    let handle = dialog().pick_folder().await;
    #[cfg(not(target_os = "macos"))]
    let handle = dialog().pick_file().await;
    path_of(handle)
}

pub async fn notify(title: String, body: String) -> Result<(), CoreError> {
    let identifier = crate::host::app()?.channel().info().identifier;
    let mut notification = notify_rust::Notification::new();
    notification.summary(&title).body(&body).auto_icon();
    #[cfg(windows)]
    notification.app_id(identifier);
    #[cfg(target_os = "macos")]
    let _ = notify_rust::set_application(identifier);
    #[cfg(not(any(windows, target_os = "macos")))]
    let _ = identifier;
    notification.show().map(|_| ()).map_err(|e| CoreError::from(e.to_string()))
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_main_window_visible(visible: bool) {
    crate::host::set_main_window_visible(visible);
}

pub async fn relaunch(args: Vec<String>) -> Result<(), CoreError> {
    godothub_core::single_instance::relaunch(&args).map_err(CoreError::from)
}

pub async fn refresh_recent_projects() -> Result<Vec<RecentProject>, CoreError> {
    let app = crate::host::app()?;
    let recent = crate::lane::serial(move || godothub_core::recent::recent_projects(&app)).await;
    crate::jump_list::refresh(recent.clone());
    Ok(recent
        .into_iter()
        .map(|p| RecentProject { id: p.id, label: p.label, path: p.path })
        .collect())
}

pub async fn open_recent_project(id: String) -> Result<(), CoreError> {
    let app = crate::host::app()?;
    godothub_core::projects::open_project(app, id, true, None).await.map_err(CoreError::from)
}

pub async fn discord_connect(app_id: String) -> Result<(), CoreError> {
    let app = crate::host::app()?;
    tokio::task::spawn_blocking(move || godothub_core::discord::connect(&app, app_id))
        .await
        .map_err(|e| CoreError::from(e.to_string()))?
        .map_err(CoreError::from)
}

pub async fn discord_disconnect() -> Result<(), CoreError> {
    godothub_core::discord::disconnect(&crate::host::app()?);
    Ok(())
}

pub async fn discord_set_activity(activity: Option<DiscordActivity>) -> Result<(), CoreError> {
    let activity = activity.map(|a| godothub_core::discord::DiscordActivity {
        name: a.name,
        details: a.details,
        state: a.state,
        start_timestamp: a.start_timestamp,
    });
    godothub_core::discord::set_activity(&crate::host::app()?, activity);
    Ok(())
}
