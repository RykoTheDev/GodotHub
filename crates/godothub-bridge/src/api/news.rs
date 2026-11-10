#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn fetch_godot_news() -> Result<NewsResponse, CoreError> {
    let app = app()?;
    godothub_core::news::fetch_godot_news(app).await.map_err(CoreError::from)
}
