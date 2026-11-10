#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn fix_project_health(id: String, check_id: String) -> Result<(), CoreError> {
    let app = app()?;
    godothub_core::project_health::fix_project_health(app, id, check_id).await.map_err(CoreError::from)
}
