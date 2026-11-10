#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;

pub async fn is_portable_install() -> Result<bool, CoreError> {
    Ok(crate::lane::serial(godothub_core::install_mode::is_portable_install).await)
}
