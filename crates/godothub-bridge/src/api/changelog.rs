#[allow(unused_imports)]
use std::collections::HashMap;
#[allow(unused_imports)]
use super::types::*;
use super::error::CoreError;

pub async fn list_changelog_entries() -> Result<Vec<ChangelogEntry>, CoreError> {
    Ok(crate::lane::serial(godothub_core::changelog::list_changelog_entries).await)
}

pub async fn add_changelog_entry(version: String, date: String, notes: Vec<ChangelogNote>, known_issues: Vec<String>) -> Result<ChangelogEntry, CoreError> {
    crate::lane::serial(move || godothub_core::changelog::add_changelog_entry(version, date, notes, known_issues)).await.map_err(CoreError::from)
}

pub async fn update_changelog_entry(id: String, version: String, date: String, notes: Vec<ChangelogNote>, known_issues: Vec<String>) -> Result<ChangelogEntry, CoreError> {
    crate::lane::serial(move || godothub_core::changelog::update_changelog_entry(id, version, date, notes, known_issues)).await.map_err(CoreError::from)
}

pub async fn delete_changelog_entry(id: String) -> Result<(), CoreError> {
    crate::lane::serial(move || godothub_core::changelog::delete_changelog_entry(id)).await.map_err(CoreError::from)
}

pub async fn list_git_tags() -> Result<Vec<String>, CoreError> {
    godothub_core::changelog::list_git_tags().await.map_err(CoreError::from)
}

pub async fn generate_changelog_draft(from: String, to: String) -> Result<ChangelogDraft, CoreError> {
    godothub_core::changelog::generate_changelog_draft(from, to).await.map_err(CoreError::from)
}
