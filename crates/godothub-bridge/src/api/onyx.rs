#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;

pub async fn onyx_status() -> Result<OnyxStatus, CoreError> {
    Ok(godothub_core::onyx::onyx_status().await)
}
