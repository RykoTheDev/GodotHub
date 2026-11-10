#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn remove_ui_pref(key: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::ui_prefs::remove_ui_pref(app, key)).await.map_err(CoreError::from)
}
