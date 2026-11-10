use std::sync::Arc;

use godothub_core::{Channel, EventSink, Host, Paths};
use serde_json::value::RawValue;
use tauri::{AppHandle, Emitter, Manager};

pub const CHANNEL: Channel = Channel::Stable;

struct TauriHost(AppHandle);

impl EventSink for TauriHost {
    fn emit(&self, event: &str, payload: &RawValue) {
        let _ = self.0.emit(event, payload);
    }
}

impl Host for TauriHost {
    fn show_main_window(&self) {
        crate::tray::show_main_window(&self.0);
    }

    fn hide_main_window(&self) {
        if let Some(window) = self.0.get_webview_window("main") {
            let _ = window.hide();
        }
    }

    fn exit(&self, code: i32) {
        self.0.exit(code);
    }

    fn refresh_menus(&self) {
        let _ = crate::tray::refresh_tray_menu_now(&self.0);
    }

    fn main_window_visible(&self) -> Option<bool> {
        self.0
            .get_webview_window("main")
            .and_then(|window| window.is_visible().ok())
    }
}

pub fn create(app: &AppHandle) -> godothub_core::AppHandle {
    godothub_core::runtime::set(tauri::async_runtime::handle().inner().clone());
    let host = Arc::new(TauriHost(app.clone()));
    godothub_core::AppHandle::new(CHANNEL, Paths::for_channel(CHANNEL), host.clone(), host)
}

pub fn core_handle(app: &AppHandle) -> godothub_core::AppHandle {
    app.state::<godothub_core::AppHandle>().inner().clone()
}
