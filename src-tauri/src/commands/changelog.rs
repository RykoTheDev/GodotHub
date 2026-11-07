use godothub_core::changelog::{ChangelogDraft};
use godothub_core::models::ChangelogEntry;
use godothub_core::models::ChangelogNote;

#[tauri::command]
pub async fn list_changelog_entries() -> Vec<ChangelogEntry> {
    crate::lane::serial(godothub_core::changelog::list_changelog_entries).await
}

#[tauri::command]
pub async fn add_changelog_entry(_version: String, _date: String, _notes: Vec<ChangelogNote>, _known_issues: Vec<String>) -> Result<ChangelogEntry, String> {
    crate::lane::serial(move || godothub_core::changelog::add_changelog_entry(_version, _date, _notes, _known_issues)).await
}

#[tauri::command]
pub async fn update_changelog_entry(_id: String, _version: String, _date: String, _notes: Vec<ChangelogNote>, _known_issues: Vec<String>) -> Result<ChangelogEntry, String> {
    crate::lane::serial(move || godothub_core::changelog::update_changelog_entry(_id, _version, _date, _notes, _known_issues)).await
}

#[tauri::command]
pub async fn delete_changelog_entry(_id: String) -> Result<(), String> {
    crate::lane::serial(move || godothub_core::changelog::delete_changelog_entry(_id)).await
}

#[tauri::command]
pub async fn list_git_tags() -> Result<Vec<String>, String> {
    godothub_core::changelog::list_git_tags().await
}

#[tauri::command]
pub async fn generate_changelog_draft(_from: String, _to: String) -> Result<ChangelogDraft, String> {
    godothub_core::changelog::generate_changelog_draft(_from, _to).await
}
