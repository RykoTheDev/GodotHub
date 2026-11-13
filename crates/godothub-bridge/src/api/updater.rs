use flutter_rust_bridge::frb;
use godothub_core::updater::{self, Installer};

use super::error::CoreError;
use crate::frb_generated::StreamSink;

pub struct UpdateInfo {
    pub version: String,
    pub current_version: String,
    pub notes: Option<String>,
    pub pub_date: Option<String>,
    pub target: String,
    pub url: String,
    pub signature: String,
    pub installer: Option<String>,
    pub portable: bool,
    pub send_token: bool,
}

#[derive(Clone)]
pub struct UpdateProgress {
    pub downloaded: u64,
    pub total: Option<u64>,
    pub log: Option<String>,
}

fn log_line(sink: &StreamSink<UpdateProgress>, last: (u64, Option<u64>), line: String) {
    let _ = sink.add(UpdateProgress { downloaded: last.0, total: last.1, log: Some(line) });
}

fn installer_from(name: Option<&str>) -> Option<Installer> {
    name.and_then(Installer::from_name)
}

impl From<updater::UpdateInfo> for UpdateInfo {
    fn from(u: updater::UpdateInfo) -> Self {
        Self {
            version: u.version,
            current_version: u.current_version,
            notes: u.notes,
            pub_date: u.pub_date,
            target: u.target,
            url: u.url,
            signature: u.signature,
            installer: u.installer.map(|i| i.name().to_string()),
            portable: u.portable,
            send_token: u.send_token,
        }
    }
}

impl From<UpdateInfo> for updater::UpdateInfo {
    fn from(u: UpdateInfo) -> Self {
        Self {
            installer: installer_from(u.installer.as_deref()),
            version: u.version,
            current_version: u.current_version,
            notes: u.notes,
            pub_date: u.pub_date,
            target: u.target,
            url: u.url,
            signature: u.signature,
            portable: u.portable,
            send_token: u.send_token,
        }
    }
}

#[frb(sync)]
pub fn set_app_version(version: String) {
    if !version.trim().is_empty() {
        godothub_core::set_app_version(Box::leak(version.trim().to_string().into_boxed_str()));
    }
}

#[frb(sync)]
pub fn set_updater_test_overrides(endpoint: Option<String>, public_key: Option<String>) -> Result<(), CoreError> {
    updater::set_test_overrides(endpoint, public_key).map_err(CoreError::from)
}

pub async fn confirm_launch() -> Result<bool, CoreError> {
    tokio::task::spawn_blocking(updater::confirm_launch)
        .await
        .map_err(|e| CoreError::from(e.to_string()))?
        .map_err(CoreError::from)
}

pub async fn check_for_update() -> Result<Option<UpdateInfo>, CoreError> {
    let app = crate::host::app()?;
    Ok(updater::check(&app).await.map_err(CoreError::from)?.map(UpdateInfo::from))
}

static PENDING: std::sync::Mutex<Option<updater::PreparedUpdate>> = std::sync::Mutex::new(None);

fn set_pending(prepared: Option<updater::PreparedUpdate>) {
    *PENDING.lock().unwrap_or_else(|e| e.into_inner()) = prepared;
}

pub async fn download_update(update: UpdateInfo, github_token: Option<String>, sink: StreamSink<UpdateProgress>) -> Result<(), CoreError> {
    let app = crate::host::app()?;
    let update: updater::UpdateInfo = update.into();
    set_pending(None);
    let (file, host) = updater::download_source(&update.url);
    log_line(&sink, (0, None), format!("Downloading {file} from {host}"));
    let mut last = (0, None);
    let result = updater::download(&app, &update, github_token.as_deref(), |downloaded, total| {
        last = (downloaded, total);
        let _ = sink.add(UpdateProgress { downloaded, total, log: None });
    })
    .await;
    let bytes = match result {
        Ok(bytes) => bytes,
        Err(error) => {
            log_line(&sink, last, format!("Failed: {error}"));
            return Err(CoreError::from(error));
        }
    };
    log_line(&sink, last, format!("Downloaded {}", updater::format_size(bytes.len() as u64)));
    log_line(&sink, last, "Signature verified".to_string());
    let log_sink = sink.clone();
    let prepared = tokio::task::spawn_blocking(move || {
        updater::prepare(&update, bytes, &mut |line| log_line(&log_sink, last, line)).inspect_err(|error| {
            log_line(&log_sink, last, format!("Failed: {error}"));
        })
    })
    .await
        .map_err(|e| CoreError::from(e.to_string()))?
        .map_err(CoreError::from)?;
    set_pending(Some(prepared));
    Ok(())
}

pub async fn restart_to_update() -> Result<bool, CoreError> {
    let prepared = PENDING
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .take()
        .ok_or_else(|| CoreError::from("No update has been downloaded".to_string()))?;
    tokio::task::spawn_blocking(move || updater::finish(prepared, &mut |_| {}))
        .await
        .map_err(|e| CoreError::from(e.to_string()))?
        .map_err(CoreError::from)
}
