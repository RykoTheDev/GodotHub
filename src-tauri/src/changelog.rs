use crate::models::{ChangelogEntry, ChangelogNote};

#[cfg(debug_assertions)]
use std::fs;
#[cfg(debug_assertions)]
use std::path::PathBuf;
#[cfg(debug_assertions)]
use uuid::Uuid;

const EMBEDDED_CHANGELOG: &str = include_str!("../changelog.json");

#[cfg(debug_assertions)]
fn changelog_file() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("changelog.json")
}

fn read_entries() -> Vec<ChangelogEntry> {
    #[cfg(debug_assertions)]
    {
        if let Ok(raw) = fs::read_to_string(changelog_file()) {
            return serde_json::from_str(&raw).unwrap_or_default();
        }
    }
    serde_json::from_str(EMBEDDED_CHANGELOG).unwrap_or_default()
}

#[cfg(debug_assertions)]
fn write_entries(entries: &Vec<ChangelogEntry>) -> Result<(), String> {
    fs::write(
        changelog_file(),
        serde_json::to_string_pretty(entries).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

#[cfg(debug_assertions)]
fn clean_notes(notes: Vec<ChangelogNote>) -> Vec<ChangelogNote> {
    notes
        .into_iter()
        .map(|n| ChangelogNote {
            category: match n.category.to_lowercase().as_str() {
                "fix" => "fix".to_string(),
                "improve" => "improve".to_string(),
                _ => "add".to_string(),
            },
            text: n.text.trim().to_string(),
        })
        .filter(|n| !n.text.is_empty())
        .collect()
}

#[tauri::command]
pub fn list_changelog_entries() -> Vec<ChangelogEntry> {
    let mut entries = read_entries();
    entries.sort_by_key(|b| std::cmp::Reverse(b.created_at));
    entries
}

#[tauri::command]
pub fn add_changelog_entry(
    _version: String,
    _date: String,
    _notes: Vec<ChangelogNote>,
) -> Result<ChangelogEntry, String> {
    #[cfg(not(debug_assertions))]
    {
        return Err("Changelog editing is only available in development builds.".into());
    }

    #[cfg(debug_assertions)]
    {
        let version = _version.trim().to_string();
        if version.is_empty() {
            return Err("Give the entry a version.".into());
        }
        let mut entries = read_entries();
        let entry = ChangelogEntry {
            id: Uuid::new_v4().to_string(),
            version,
            date: _date.trim().to_string(),
            notes: clean_notes(_notes),
            created_at: chrono::Utc::now().timestamp(),
        };
        entries.push(entry.clone());
        write_entries(&entries)?;
        Ok(entry)
    }
}

#[tauri::command]
pub fn update_changelog_entry(
    _id: String,
    _version: String,
    _date: String,
    _notes: Vec<ChangelogNote>,
) -> Result<ChangelogEntry, String> {
    #[cfg(not(debug_assertions))]
    {
        return Err("Changelog editing is only available in development builds.".into());
    }

    #[cfg(debug_assertions)]
    {
        let version = _version.trim().to_string();
        if version.is_empty() {
            return Err("Give the entry a version.".into());
        }
        let mut entries = read_entries();
        let entry = entries
            .iter_mut()
            .find(|e| e.id == _id)
            .ok_or("Changelog entry not found")?;
        entry.version = version;
        entry.date = _date.trim().to_string();
        entry.notes = clean_notes(_notes);
        let updated = entry.clone();
        write_entries(&entries)?;
        Ok(updated)
    }
}

#[tauri::command]
pub fn delete_changelog_entry(_id: String) -> Result<(), String> {
    #[cfg(not(debug_assertions))]
    {
        return Err("Changelog editing is only available in development builds.".into());
    }

    #[cfg(debug_assertions)]
    {
        let mut entries = read_entries();
        let idx = entries
            .iter()
            .position(|e| e.id == _id)
            .ok_or("Changelog entry not found")?;
        entries.remove(idx);
        write_entries(&entries)
    }
}
