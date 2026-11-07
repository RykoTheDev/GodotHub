use crate::models::*;
use crate::template_files::{copy_dir, remove_dir_force};
use std::fs;
use std::path::{Component, Path, PathBuf};
use crate::AppHandle;
use uuid::Uuid;

const SKIP_DIRS: &[&str] = &[".godot", ".git", "node_modules"];

fn vault_root(app: &AppHandle) -> PathBuf {
    let dir = crate::workspace::active_workspace_dir(app).join("vault");
    if !dir.exists() {
        let _ = fs::create_dir_all(&dir);
    }
    dir
}

fn vault_item_dir(app: &AppHandle, id: &str) -> PathBuf {
    vault_root(app).join(id)
}

fn item_files_dir(dir: &Path) -> PathBuf {
    dir.join("files")
}

fn is_safe_relative(rel: &Path) -> bool {
    if rel.as_os_str().is_empty() {
        return false;
    }
    for comp in rel.components() {
        match comp {
            Component::Normal(_) | Component::CurDir => {}
            _ => return false,
        }
    }
    true
}

fn read_vault_json(dir: &Path) -> Option<VaultItem> {
    let file = dir.join("vault.json");
    if !file.exists() {
        return None;
    }
    serde_json::from_str(&fs::read_to_string(&file).ok()?).ok()
}

fn write_vault_json(dir: &Path, item: &VaultItem) -> Result<(), String> {
    fs::write(
        dir.join("vault.json"),
        serde_json::to_string_pretty(item).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

fn list_files_recursive(
    base: &Path,
    dir: &Path,
    entries: &mut Vec<VaultFileEntry>,
) -> Result<(), String> {
    for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        let rel = path
            .strip_prefix(base)
            .map_err(|_| "Path error".to_string())?;
        let rel_str = rel.to_string_lossy().replace("\\", "/");
        if path.is_dir() {
            entries.push(VaultFileEntry {
                path: rel_str.clone() + "/",
                is_dir: true,
                size: 0,
            });
            list_files_recursive(base, &path, entries)?;
        } else {
            let size = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
            entries.push(VaultFileEntry {
                path: rel_str,
                is_dir: false,
                size,
            });
        }
    }
    Ok(())
}

fn collect_files(files_dir: &Path) -> Vec<VaultFileEntry> {
    let mut entries = Vec::new();
    if files_dir.exists() {
        let _ = list_files_recursive(files_dir, files_dir, &mut entries);
    }
    entries.sort_by(|a, b| a.path.cmp(&b.path));
    entries
}

fn resolve_item_dir(app: &AppHandle, id: &str) -> Option<PathBuf> {
    let dir = vault_item_dir(app, id);
    if dir.exists() {
        Some(dir)
    } else {
        None
    }
}

fn delete_dir_best_effort(dir: &Path) -> bool {
    trash::delete_all(dir)
        .map_err(|e| e.to_string())
        .or_else(|_| remove_dir_force(dir))
        .is_ok()
}

pub async fn list_vault_items(app: AppHandle) -> Result<Vec<VaultItem>, String> {
    tokio::task::spawn_blocking(move || read_vault_items(&app))
        .await
        .map_err(|e| e.to_string())
}

fn read_vault_items(app: &AppHandle) -> Vec<VaultItem> {
    let mut items: Vec<VaultItem> = Vec::new();
    let root = vault_root(app);
    if !root.exists() {
        return items;
    }
    let mut entries: Vec<_> = match fs::read_dir(&root) {
        Ok(e) => e.filter_map(|e| e.ok()).collect(),
        Err(_) => return items,
    };
    entries.sort_by_key(|e| e.file_name());
    for entry in entries {
        let path = entry.path();
        if path.is_dir() {
            if let Some(mut item) = read_vault_json(&path) {
                let folder_name = path
                    .file_name()
                    .map(|n| n.to_string_lossy().to_string())
                    .unwrap_or_default();
                item.id = folder_name;
                item.path = path.to_string_lossy().to_string();
                item.files = collect_files(&item_files_dir(&path));
                items.push(item);
            }
        }
    }
    items
}

pub async fn save_to_vault(
    app: AppHandle,
    name: String,
    description: String,
    tags: Vec<String>,
    sources: Vec<VaultSaveSource>,
) -> Result<VaultItem, String> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err("Vault item name can't be empty".into());
    }
    if sources.is_empty() {
        return Err("Select at least one project to save from".into());
    }
    if sources.iter().all(|s| s.paths.is_empty()) {
        return Err("Select at least one file or folder to save".into());
    }

    let projects = crate::projects::read_projects(&app);

    let id = Uuid::new_v4().to_string();
    let dir = vault_item_dir(&app, &id);
    let files_dir = item_files_dir(&dir);
    fs::create_dir_all(&files_dir).map_err(|e| e.to_string())?;

    let mut godot_version = String::new();
    let mut source_project_ids: Vec<String> = Vec::new();

    let result = (|| -> Result<(), String> {
        for source in &sources {
            let project = projects
                .iter()
                .find(|p| p.id == source.project_id)
                .ok_or("Project not found")?;
            let project_root = PathBuf::from(&project.path);
            if !project_root.exists() {
                return Err("Project folder no longer exists on disk".into());
            }
            if godot_version.is_empty() {
                godot_version = project.godot_version.clone();
            }
            if !source_project_ids.contains(&source.project_id) {
                source_project_ids.push(source.project_id.clone());
            }

            for raw in &source.paths {
                let normalized = raw
                    .replace("\\", "/")
                    .trim_start_matches("res://")
                    .trim_start_matches('/')
                    .to_string();
                let rel = Path::new(&normalized);
                if normalized.is_empty() || !is_safe_relative(rel) {
                    return Err(format!("Unsafe path: {raw}"));
                }
                let src = project_root.join(rel);
                if !src.exists() {
                    return Err(format!("Path does not exist in project: {raw}"));
                }
                let dst = files_dir.join(rel);
                if let Some(parent) = dst.parent() {
                    fs::create_dir_all(parent).map_err(|e| e.to_string())?;
                }
                if src.is_dir() {
                    copy_dir(&src, &dst, SKIP_DIRS)?;
                } else {
                    fs::copy(&src, &dst).map_err(|e| e.to_string())?;
                }
            }
        }
        Ok(())
    })();

    if let Err(e) = result {
        let _ = delete_dir_best_effort(&dir);
        return Err(e);
    }

    let item = VaultItem {
        id: id.clone(),
        name: trimmed,
        description,
        godot_version,
        created_at: chrono::Utc::now().to_rfc3339(),
        source_project_id: source_project_ids.first().cloned(),
        source_project_ids,
        tags,
        files: collect_files(&files_dir),
        path: dir.to_string_lossy().to_string(),
    };

    if let Err(e) = write_vault_json(&dir, &item) {
        let _ = delete_dir_best_effort(&dir);
        return Err(e);
    }

    Ok(item)
}

pub async fn add_vault_item_to_projects(
    app: AppHandle,
    item_id: String,
    project_ids: Vec<String>,
    overwrite: bool,
) -> Result<Vec<VaultProjectImportResult>, String> {
    let dir = resolve_item_dir(&app, &item_id).ok_or("Vault item not found")?;
    let files_dir = item_files_dir(&dir);

    let file_paths: Vec<String> = collect_files(&files_dir)
        .into_iter()
        .filter(|e| !e.is_dir)
        .map(|e| e.path)
        .collect();

    let projects = crate::projects::read_projects(&app);
    let mut results = Vec::new();

    for project_id in &project_ids {
        let project = projects
            .iter()
            .find(|p| &p.id == project_id)
            .ok_or("Project not found")?;
        let project_root = PathBuf::from(&project.path);
        if !project_root.exists() {
            return Err("Project folder no longer exists on disk".into());
        }

        let conflicts: Vec<String> = file_paths
            .iter()
            .filter(|rel| project_root.join(rel).exists())
            .cloned()
            .collect();

        if !overwrite {
            results.push(VaultProjectImportResult {
                project_id: project_id.clone(),
                installed: Vec::new(),
                conflicts,
                skipped: true,
            });
            continue;
        }

        let mut installed = Vec::new();
        for rel in &file_paths {
            let src = files_dir.join(rel);
            let dst = project_root.join(rel);
            if let Some(parent) = dst.parent() {
                fs::create_dir_all(parent).map_err(|e| e.to_string())?;
            }
            fs::copy(&src, &dst).map_err(|e| e.to_string())?;
            installed.push(rel.clone());
        }

        results.push(VaultProjectImportResult {
            project_id: project_id.clone(),
            installed,
            conflicts,
            skipped: false,
        });
    }

    Ok(results)
}

pub async fn delete_vault_item(app: AppHandle, item_id: String) -> Result<(), String> {
    let dir = resolve_item_dir(&app, &item_id).ok_or("Vault item not found")?;
    if delete_dir_best_effort(&dir) {
        Ok(())
    } else {
        Err(format!(
            "Could not delete vault item folder: {}",
            dir.display()
        ))
    }
}

pub async fn update_vault_item(
    app: AppHandle,
    item_id: String,
    name: String,
    description: String,
    tags: Vec<String>,
) -> Result<VaultItem, String> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err("Vault item name can't be empty".into());
    }
    let dir = resolve_item_dir(&app, &item_id).ok_or("Vault item not found")?;
    let mut item = read_vault_json(&dir).ok_or("Vault manifest not found")?;
    item.id = item_id;
    item.name = trimmed;
    item.description = description;
    item.tags = tags;
    item.path = dir.to_string_lossy().to_string();
    item.files = collect_files(&item_files_dir(&dir));
    write_vault_json(&dir, &item)?;
    Ok(item)
}
