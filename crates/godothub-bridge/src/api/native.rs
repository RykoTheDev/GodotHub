use super::error::CoreError;

pub struct RecentProject {
    pub id: String,
    pub label: String,
    pub path: String,
}

fn dialog() -> rfd::AsyncFileDialog {
    rfd::AsyncFileDialog::new()
}

/// Shows a dialog modally. On Windows the dialog is deliberately not given the
/// Flutter window as owner (see `dialog_modal`); the window is disabled instead.
async fn show<F>(open: impl FnOnce(rfd::AsyncFileDialog) -> F) -> Option<String>
where
    F: std::future::Future<Output = Option<rfd::FileHandle>>,
{
    #[cfg(windows)]
    let _modal = crate::dialog_modal::disable_main_window();
    open(dialog()).await.map(|h| h.path().to_string_lossy().to_string())
}

pub async fn pick_folder() -> Option<String> {
    show(|d| d.pick_folder()).await
}

pub async fn pick_save_path(default_name: String) -> Option<String> {
    show(|d| d.set_file_name(default_name).save_file()).await
}

pub async fn pick_data_file() -> Option<String> {
    show(|d| d.add_filter("JSON", &["json"]).pick_file()).await
}

pub async fn pick_image_file() -> Option<String> {
    show(|d| d.add_filter("Images", &["png", "svg", "jpg", "jpeg", "webp"]).pick_file()).await
}

pub async fn pick_executable() -> Option<String> {
    #[cfg(target_os = "macos")]
    return show(|d| d.pick_folder()).await;
    #[cfg(not(target_os = "macos"))]
    show(|d| d.pick_file()).await
}

pub async fn notify(title: String, body: String) -> Result<(), CoreError> {
    let identifier = godothub_core::APP.identifier;
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
