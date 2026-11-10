use std::sync::{Arc, OnceLock};

use godothub_core::{AppHandle, Channel, EventSink, Host, Paths};
use serde_json::value::RawValue;

static APP: OnceLock<AppHandle> = OnceLock::new();

struct FlutterHost;

impl EventSink for FlutterHost {
    fn emit(&self, _event: &str, _payload: &RawValue) {}
}

impl Host for FlutterHost {
    fn show_main_window(&self) {}
    fn hide_main_window(&self) {}
    fn exit(&self, code: i32) {
        std::process::exit(code);
    }
    fn refresh_menus(&self) {}
}

fn parse_channel(channel: &str) -> Result<Channel, String> {
    match channel {
        "stable" => Ok(Channel::Stable),
        "beta" => Ok(Channel::Beta),
        other => Err(format!("Unknown channel {other:?}, expected \"stable\" or \"beta\"")),
    }
}

fn app() -> Result<AppHandle, String> {
    APP.get().cloned().ok_or_else(|| "The core has not been started".to_string())
}

fn to_json<T: serde::Serialize>(value: &T) -> Result<String, String> {
    serde_json::to_string_pretty(value).map_err(|e| e.to_string())
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(sync)]
pub fn start_core(channel: String) -> Result<String, String> {
    let channel = parse_channel(&channel)?;
    let app = APP.get_or_init(|| {
        let host = Arc::new(FlutterHost);
        AppHandle::new(channel, Paths::for_channel(channel), host.clone(), host)
    });
    if app.channel() != channel {
        return Err("The core is already running on another channel".into());
    }
    Ok(channel.info().display_name.to_string())
}

pub fn get_settings_json() -> Result<String, String> {
    to_json(&godothub_core::settings::get_settings(app()?))
}

pub async fn cli_tool_status_json() -> Result<String, String> {
    to_json(&godothub_core::cli_shim::cli_tool_status(app()?).await)
}

pub async fn install_cli_tool_json() -> Result<String, String> {
    to_json(&godothub_core::cli_shim::install_cli_tool(app()?).await?)
}

pub fn uninstall_cli_tool_json() -> Result<String, String> {
    to_json(&godothub_core::cli_shim::uninstall_cli_tool(app()?)?)
}
