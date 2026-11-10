#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn get_storage_report() -> Result<StorageReport, CoreError> {
    let app = app()?;
    godothub_core::storage::get_storage_report(app).await.map_err(CoreError::from)
}
