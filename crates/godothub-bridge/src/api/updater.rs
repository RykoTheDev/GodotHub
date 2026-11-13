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

pub struct UpdateProgress {
    pub downloaded: u64,
    pub total: Option<u64>,
}

fn installer_from(name: Option<&str>) -> Option<Installer> {
    [Installer::AppImage, Installer::Deb, Installer::Rpm, Installer::App, Installer::Msi, Installer::Nsis]
        .into_iter()
        .find(|i| Some(i.name()) == name)
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

pub async fn check_for_update() -> Result<Option<UpdateInfo>, CoreError> {
    let app = crate::host::app()?;
    Ok(updater::check(&app).await.map_err(CoreError::from)?.map(UpdateInfo::from))
}

pub async fn download_and_install_update(
    update: UpdateInfo,
    github_token: Option<String>,
    sink: StreamSink<UpdateProgress>,
) -> Result<(), CoreError> {
    let app = crate::host::app()?;
    let update: updater::UpdateInfo = update.into();
    let bytes = updater::download(&app, &update, github_token.as_deref(), |downloaded, total| {
        let _ = sink.add(UpdateProgress { downloaded, total });
    })
    .await
    .map_err(CoreError::from)?;
    tokio::task::spawn_blocking(move || updater::install(&update, &bytes))
        .await
        .map_err(|e| CoreError::from(e.to_string()))?
        .map_err(CoreError::from)
}
