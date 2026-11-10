#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;
use crate::host::app;

pub async fn get_current_version() -> Result<Option<CurrentVersionInfo>, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::current_version::get_current_version(app)).await)
}

pub async fn set_current_version(tag: String) -> Result<CurrentVersionInfo, CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::current_version::set_current_version(app, tag)).await.map_err(CoreError::from)
}

pub async fn clear_current_version() -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::current_version::clear_current_version(app)).await.map_err(CoreError::from)
}

pub async fn list_version_aliases() -> Result<VersionAliases, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::current_version::list_version_aliases(app)).await)
}

pub async fn create_version_aliases(entries: Vec<AliasRequest>) -> Result<AliasBatchResult, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::current_version::create_version_aliases(app, entries)).await)
}

pub async fn delete_version_alias(name: String) -> Result<(), CoreError> {
    let app = app()?;
    crate::lane::serial(move || godothub_core::current_version::delete_version_alias(app, name)).await.map_err(CoreError::from)
}
