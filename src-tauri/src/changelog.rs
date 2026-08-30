use serde::Serialize;

use crate::error::AppResult;
use crate::persist;
use crate::models::{ChangelogEntry, ChangelogNote};

#[cfg(debug_assertions)]
use std::path::{Path, PathBuf};
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
        if let Some(entries) = persist::read_json_opt::<Vec<ChangelogEntry>>(&changelog_file()) {
            return entries;
        }
    }
    serde_json::from_str(EMBEDDED_CHANGELOG).unwrap_or_default()
}

#[cfg(debug_assertions)]
fn write_entries(entries: &Vec<ChangelogEntry>) -> AppResult<()> {
    persist::write_json(&changelog_file(), entries)
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

#[cfg(debug_assertions)]
fn clean_known_issues(issues: Vec<String>) -> Vec<String> {
    issues
        .into_iter()
        .map(|i| i.trim().to_string())
        .filter(|i| !i.is_empty())
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
    _known_issues: Vec<String>,
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
            known_issues: clean_known_issues(_known_issues),
            created_at: chrono::Utc::now().timestamp(),
        };
        entries.push(entry.clone());
        write_entries(&entries).map_err(|e| e.to_string())?;
        Ok(entry)
    }
}

#[tauri::command]
pub fn update_changelog_entry(
    _id: String,
    _version: String,
    _date: String,
    _notes: Vec<ChangelogNote>,
    _known_issues: Vec<String>,
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
        entry.known_issues = clean_known_issues(_known_issues);
        let updated = entry.clone();
        write_entries(&entries).map_err(|e| e.to_string())?;
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
        write_entries(&entries).map_err(|e| e.to_string())
    }
}

#[derive(Serialize, Clone)]
pub struct ChangelogDraftNote {
    pub category: String,
    pub text: String,
    pub hash: String,
    pub author: String,
}

#[derive(Serialize, Clone)]
pub struct ChangelogDraftSkipped {
    pub hash: String,
    pub subject: String,
    pub reason: String,
}

#[derive(Serialize)]
pub struct ChangelogDraft {
    pub from: String,
    pub to: String,
    pub count: usize,
    pub next_version: String,
    pub notes: Vec<ChangelogDraftNote>,
    pub skipped: Vec<ChangelogDraftSkipped>,
}

#[cfg(debug_assertions)]
fn git_repo_root() -> Result<PathBuf, String> {
    let out = std::process::Command::new("git")
        .args([
            "-C",
            env!("CARGO_MANIFEST_DIR"),
            "rev-parse",
            "--show-toplevel",
        ])
        .output()
        .map_err(|e| format!("Failed to run git: {e}"))?;
    if !out.status.success() {
        return Err(
            "Not inside the GodotHub git repository. The generator reads the repo's commit history."
                .into(),
        );
    }
    let root = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if root.is_empty() {
        return Err("Could not locate the git repository root.".into());
    }
    Ok(PathBuf::from(root))
}

#[cfg(debug_assertions)]
fn git_tags(root: &Path) -> Result<Vec<String>, String> {
    let out = std::process::Command::new("git")
        .current_dir(root)
        .args(["tag", "--sort=-v:refname"])
        .output()
        .map_err(|e| format!("Failed to list git tags: {e}"))?;
    if !out.status.success() {
        return Err(String::from_utf8_lossy(&out.stderr).trim().to_string());
    }
    Ok(String::from_utf8_lossy(&out.stdout)
        .lines()
        .map(|l| l.trim().to_string())
        .filter(|l| !l.is_empty())
        .collect())
}

#[cfg(debug_assertions)]
fn bump_patch(version: &str) -> String {
    let trimmed = version.trim().trim_start_matches('v');
    let parts: Vec<&str> = trimmed.split('.').collect();
    let last = parts
        .last()
        .and_then(|p| p.parse::<u32>().ok());
    match last {
        Some(n) if parts.len() >= 2 => {
            let mut out: Vec<String> =
                parts[..parts.len() - 1].iter().map(|s| s.to_string()).collect();
            out.push((n + 1).to_string());
            format!("v{}", out.join("."))
        }
        _ => format!("v{}.1", trimmed),
    }
}

#[cfg(debug_assertions)]
fn classify_subject(subject: &str) -> (Option<&'static str>, &str) {
    let trimmed = subject.trim();
    let lower = trimmed.to_lowercase();
    if lower.starts_with("merge")
        || lower.starts_with("revert")
        || lower.starts_with("bump version")
    {
        return (None, trimmed);
    }

    if let Some(colon) = trimmed.find(':') {
        let prefix = &trimmed[..colon];
        let desc = trimmed[colon + 1..].trim();
        let type_part = match prefix.find('(') {
            Some(p) if prefix.ends_with(')') => &prefix[..p],
            _ => prefix,
        };
        let t = type_part.trim().to_lowercase();
        if !t.is_empty() && t.chars().all(|c| c.is_ascii_alphabetic()) {
            let category = match t.as_str() {
                "feat" | "feature" | "add" | "new" => Some("add"),
                "fix" | "bugfix" | "bug" | "hotfix" | "patch" => Some("fix"),
                "improve"
                | "improvement"
                | "perf"
                | "performance"
                | "refactor"
                | "ref"
                | "chore"
                | "docs"
                | "doc"
                | "style"
                | "test"
                | "ci"
                | "build"
                | "ui"
                | "ux"
                | "tweak"
                | "polish"
                | "cleanup" => Some("improve"),
                _ => None,
            };
            if category.is_some() && !desc.is_empty() {
                return (category, desc);
            }
        }
    }

    if lower.starts_with("fix")
        || lower.starts_with("bugfix")
        || lower.starts_with("hotfix")
        || lower.starts_with("correct")
    {
        return (Some("fix"), trimmed);
    }
    if lower.starts_with("add")
        || lower.starts_with("new")
        || lower.starts_with("feature")
        || lower.starts_with("introduce")
    {
        return (Some("add"), trimmed);
    }
    if lower.starts_with("improve")
        || lower.starts_with("perf")
        || lower.starts_with("refactor")
        || lower.starts_with("cleanup")
        || lower.starts_with("update")
        || lower.starts_with("upgrade")
        || lower.starts_with("redesign")
        || lower.starts_with("rework")
        || lower.starts_with("tweak")
        || lower.starts_with("polish")
        || lower.starts_with("remove")
        || lower.starts_with("unify")
        || lower.starts_with("move")
        || lower.starts_with("moved")
    {
        return (Some("improve"), trimmed);
    }

    (None, trimmed)
}

#[cfg(debug_assertions)]
fn clean_text(text: &str) -> String {
    let t = text.trim().trim_end_matches('.').trim();
    let mut chars = t.chars();
    match chars.next() {
        Some(c) => c.to_uppercase().collect::<String>() + chars.as_str(),
        None => String::new(),
    }
}

#[tauri::command]
pub fn list_git_tags() -> Result<Vec<String>, String> {
    #[cfg(not(debug_assertions))]
    {
        return Err(
            "Changelog tooling is only available in development builds.".into(),
        );
    }

    #[cfg(debug_assertions)]
    {
        let root = git_repo_root()?;
        git_tags(&root)
    }
}

#[tauri::command]
pub fn generate_changelog_draft(
    _from: String,
    _to: String,
) -> Result<ChangelogDraft, String> {
    #[cfg(not(debug_assertions))]
    {
        return Err(
            "Changelog tooling is only available in development builds.".into(),
        );
    }

    #[cfg(debug_assertions)]
    {
        let from = _from.trim().to_string();
        let to = _to.trim().to_string();
        if from.is_empty() || to.is_empty() {
            return Err("Both refs are required.".into());
        }
        let root = git_repo_root()?;
        let range = if from == to {
            from.clone()
        } else {
            format!("{from}..{to}")
        };
        let out = std::process::Command::new("git")
            .current_dir(&root)
            .args(["log", "--pretty=%h%x1f%an%x1f%s"])
            .arg(&range)
            .output()
            .map_err(|e| format!("Failed to run git log: {e}"))?;
        if !out.status.success() {
            return Err(format!(
                "git log failed: {}",
                String::from_utf8_lossy(&out.stderr).trim()
            ));
        }

        let mut notes: Vec<ChangelogDraftNote> = Vec::new();
        let mut skipped: Vec<ChangelogDraftSkipped> = Vec::new();
        for line in String::from_utf8_lossy(&out.stdout).lines() {
            let mut parts = line.splitn(3, '\x1f');
            let hash = parts.next().unwrap_or("").trim().to_string();
            let author = parts.next().unwrap_or("").trim().to_string();
            let subject = parts.next().unwrap_or("").trim().to_string();
            if subject.is_empty() {
                continue;
            }
            match classify_subject(&subject) {
                (Some(cat), desc) => {
                    let text = clean_text(desc);
                    if !text.is_empty() {
                        notes.push(ChangelogDraftNote {
                            category: cat.to_string(),
                            text,
                            hash,
                            author,
                        });
                    }
                }
                (None, _) => {
                    let reason = if subject.to_lowercase().starts_with("merge") {
                        "merge"
                    } else if subject.to_lowercase().starts_with("revert") {
                        "revert"
                    } else if subject.to_lowercase().starts_with("bump version") {
                        "bump"
                    } else {
                        "unrecognized"
                    };
                    skipped.push(ChangelogDraftSkipped {
                        hash,
                        subject,
                        reason: reason.to_string(),
                    });
                }
            }
        }

        let next_version = git_tags(&root)?
            .first()
            .map(|t| bump_patch(t))
            .unwrap_or_default();

        Ok(ChangelogDraft {
            from,
            to,
            count: notes.len() + skipped.len(),
            next_version,
            notes,
            skipped,
        })
    }
}
