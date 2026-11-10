use flutter_rust_bridge::frb;
pub use godothub_core::window_state::WindowState;

use super::error::CoreError;
use crate::host::app;

#[frb(mirror(WindowState))]
pub struct _WindowState {
    pub width: u32,
    pub height: u32,
    pub x: i32,
    pub y: i32,
    pub maximized: bool,
}

pub async fn load_window_state() -> Result<Option<WindowState>, CoreError> {
    let app = app()?;
    Ok(godothub_core::window_state::load_window_state(&app)?)
}

pub async fn save_window_state(state: WindowState) -> Result<(), CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::window_state::save_window_state(&app, state)).await?)
}

pub async fn open_from_args(args: Vec<String>) -> Result<bool, CoreError> {
    let app = app()?;
    Ok(godothub_core::recent::open_from_args(&app, &args))
}

pub async fn open_launch_args() -> Result<bool, CoreError> {
    let args: Vec<String> = std::env::args().collect();
    open_from_args(args).await
}
