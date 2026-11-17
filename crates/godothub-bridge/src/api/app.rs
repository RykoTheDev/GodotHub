use flutter_rust_bridge::frb;
use godothub_core::{Paths, APP};

use super::error::CoreError;

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    godothub_core::diagnostics::install_panic_hook();
}

#[frb(sync)]
pub fn app_identifier() -> String {
    APP.identifier.to_string()
}

#[frb(sync)]
pub fn app_version() -> String {
    godothub_core::app_version().to_string()
}

pub async fn start_core() -> Result<String, CoreError> {
    crate::host::start(Paths::default_dirs(), true)?;
    Ok(APP.display_name.to_string())
}

pub async fn start_core_in(data_dir: String, config_dir: String, cache_dir: String) -> Result<String, CoreError> {
    crate::host::start(Paths::at(data_dir.into(), config_dir.into(), cache_dir.into()), false)?;
    Ok(APP.display_name.to_string())
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
