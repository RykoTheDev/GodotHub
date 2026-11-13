use std::sync::{Arc, OnceLock};

use flutter_rust_bridge::frb;
use godothub_core::{AppHandle, Channel, EventSink, Host, Paths};
use serde_json::value::RawValue;

use crate::api::error::CoreError;

static APP: OnceLock<AppHandle> = OnceLock::new();

#[frb(opaque)]
pub struct FlutterHost;

impl EventSink for FlutterHost {
    fn emit(&self, event: &str, payload: &RawValue) {
        crate::api::events::dispatch(event, payload.get());
    }
}

pub const SHOW_MAIN_WINDOW_EVENT: &str = "host:show-main-window";
pub const HIDE_MAIN_WINDOW_EVENT: &str = "host:hide-main-window";
pub const REFRESH_MENUS_EVENT: &str = "host:refresh-menus";

impl Host for FlutterHost {
    fn show_main_window(&self) {
        crate::api::events::dispatch(SHOW_MAIN_WINDOW_EVENT, "null");
    }
    fn hide_main_window(&self) {
        crate::api::events::dispatch(HIDE_MAIN_WINDOW_EVENT, "null");
    }
    fn exit(&self, code: i32) {
        std::process::exit(code);
    }
    fn refresh_menus(&self) {
        crate::api::events::dispatch(REFRESH_MENUS_EVENT, "null");
    }
    fn main_window_visible(&self) -> Option<bool> {
        Some(true)
    }
}

pub fn start(channel: Channel, paths: Paths, single_instance: bool) -> Result<(), CoreError> {
    if let Some(app) = APP.get() {
        return if app.channel() == channel {
            Ok(())
        } else {
            Err("The core is already running on another channel".into())
        };
    }
    if let Ok(handle) = tokio::runtime::Handle::try_current() {
        godothub_core::runtime::set(handle);
    }
    let host = Arc::new(FlutterHost);
    let app = APP.get_or_init(|| AppHandle::new(channel, paths, host.clone(), host));
    godothub_core::startup::initialize(app);
    if single_instance {
        let events = app.clone();
        if let Err(error) = godothub_core::single_instance::listen_for_other_instances(channel, move |args| {
            let _ = events.emit("app:second-instance", args);
        }) {
            eprintln!("single instance listener unavailable: {error}");
        }
    }
    godothub_core::runtime::spawn(godothub_core::startup::background_tasks(app.clone()));
    Ok(())
}

pub fn app() -> Result<AppHandle, CoreError> {
    APP.get()
        .cloned()
        .ok_or_else(|| CoreError::from("The core has not been started"))
}
