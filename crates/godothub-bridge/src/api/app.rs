use flutter_rust_bridge::frb;
pub use godothub_core::beta_import::BetaImport;
use godothub_core::{Channel, Paths};

use super::error::CoreError;

#[frb(mirror(BetaImport))]
pub struct _BetaImport {
    pub imported: bool,
    pub copied_files: u64,
    pub shared_versions_dir: Option<String>,
}

fn parse_channel(channel: &str) -> Result<Channel, CoreError> {
    match channel {
        "stable" => Ok(Channel::Stable),
        "beta" => Ok(Channel::Beta),
        other => Err(format!("Unknown channel {other:?}, expected \"stable\" or \"beta\"").into()),
    }
}

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub async fn start_core(channel: String) -> Result<String, CoreError> {
    let channel = parse_channel(&channel)?;
    if channel == Channel::Beta {
        godothub_core::beta_import::import_on_first_launch(
            &Paths::for_channel(Channel::Stable),
            &Paths::for_channel(Channel::Beta),
        )?;
    }
    crate::host::start(channel, Paths::for_channel(channel))?;
    Ok(channel.info().display_name.to_string())
}

pub async fn start_core_in(
    channel: String,
    data_dir: String,
    config_dir: String,
    cache_dir: String,
) -> Result<String, CoreError> {
    let channel = parse_channel(&channel)?;
    crate::host::start(channel, Paths::at(data_dir.into(), config_dir.into(), cache_dir.into()))?;
    Ok(channel.info().display_name.to_string())
}

pub async fn reimport_from_stable() -> Result<BetaImport, CoreError> {
    let app = crate::host::app()?;
    if app.channel() != Channel::Beta {
        return Err("Only the beta can re-import data from GodotHub".into());
    }
    let result = crate::lane::serial(|| {
        godothub_core::beta_import::reimport(&Paths::for_channel(Channel::Stable), &Paths::for_channel(Channel::Beta))
    })
    .await?;
    Ok(result)
}

pub async fn emit_event_for_test(name: String, payload_json: String) -> Result<(), CoreError> {
    let app = crate::host::app()?;
    let payload: serde_json::Value =
        serde_json::from_str(&payload_json).map_err(|e| CoreError::from(format!("Invalid JSON payload: {e}")))?;
    app.emit(&name, payload).map_err(|e| CoreError::from(e.to_string()))
}

pub async fn get_os_username() -> Result<Option<String>, CoreError> {
    Ok(godothub_core::system::get_os_username())
}
