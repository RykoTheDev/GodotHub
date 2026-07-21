use crate::models::*;
use std::fs;
use std::path::{Path, PathBuf};
use tauri::{AppHandle, Manager};
use uuid::Uuid;

fn templates_root(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    let dir = base.join("templates");
    if !dir.exists() {
        let _ = fs::create_dir_all(&dir);
    }
    dir
}

fn template_dir(app: &AppHandle, id: &str) -> PathBuf {
    templates_root(app).join(id)
}

fn read_template_json(dir: &Path) -> Option<ProjectTemplate> {
    let file = dir.join("template.json");
    if !file.exists() {
        return None;
    }
    serde_json::from_str(&fs::read_to_string(&file).ok()?).ok()
}

fn write_template_json(dir: &Path, template: &ProjectTemplate) -> Result<(), String> {
    fs::write(
        dir.join("template.json"),
        serde_json::to_string_pretty(template).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

pub(crate) fn copy_dir(src: &Path, dst: &Path, skip_dirs: &[&str]) -> Result<(), String> {
    if !dst.exists() {
        fs::create_dir_all(dst).map_err(|e| e.to_string())?;
    }
    for entry in fs::read_dir(src).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let name = entry.file_name();
        let name_str = name.to_string_lossy().to_string();
        if skip_dirs.iter().any(|d| name_str == *d) {
            continue;
        }
        let src_path = entry.path();
        let dst_path = dst.join(&name);
        if src_path.is_dir() {
            copy_dir(&src_path, &dst_path, skip_dirs)?;
        } else {
            fs::copy(&src_path, &dst_path).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

#[tauri::command]
pub fn list_templates(app: AppHandle) -> Vec<ProjectTemplate> {
    let mut templates: Vec<ProjectTemplate> = Vec::new();

    let root = templates_root(&app);
    if !root.exists() {
        return templates;
    }
    let mut entries: Vec<_> = match fs::read_dir(&root) {
        Ok(e) => e.filter_map(|e| e.ok()).collect(),
        Err(_) => return templates,
    };
    entries.sort_by_key(|e| e.file_name());
    for entry in entries {
        let path = entry.path();
        if path.is_dir() {
            if let Some(t) = read_template_json(&path) {
                templates.push(t);
            }
        }
    }
    templates
}

#[tauri::command]
pub fn save_project_as_template(
    app: AppHandle,
    project_id: String,
    name: String,
    description: String,
) -> Result<ProjectTemplate, String> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err("Template name can't be empty".into());
    }

    let projects = crate::projects::read_projects(&app);
    let project = projects
        .iter()
        .find(|p| p.id == project_id)
        .ok_or("Project not found")?;

    let src = PathBuf::from(&project.path);
    if !src.exists() {
        return Err("Project folder no longer exists on disk".into());
    }

    let id = Uuid::new_v4().to_string();
    let dst = template_dir(&app, &id);

    copy_dir(&src, &dst, &[".godot", ".git", "node_modules"])?;

    let template = ProjectTemplate {
        id: id.clone(),
        name: trimmed,
        description,
        godot_version: project.godot_version.clone(),
        created_at: chrono::Utc::now().to_rfc3339(),
        source_project_id: Some(project_id),
        source_path: None,
        path: dst.to_string_lossy().to_string(),
    };

    write_template_json(&dst, &template)?;
    Ok(template)
}

#[tauri::command]
pub fn delete_template(app: AppHandle, template_id: String) -> Result<(), String> {
    let dir = template_dir(&app, &template_id);
    if !dir.exists() {
        return Err("Template not found".into());
    }
    fs::remove_dir_all(&dir).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_template_preview(app: AppHandle, template_id: String) -> Result<Vec<TemplateFileEntry>, String> {
    let dir = template_dir(&app, &template_id);
    if !dir.exists() {
        return Err("Template not found".into());
    }

    let mut entries = Vec::new();
    list_files_recursive(&dir, &dir, &mut entries)?;
    Ok(entries)
}

fn list_files_recursive(base: &Path, dir: &Path, entries: &mut Vec<TemplateFileEntry>) -> Result<(), String> {
    for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        let rel = path
            .strip_prefix(base)
            .map_err(|_| "Path error".to_string())?;
        let rel_str = rel.to_string_lossy().replace("\\", "/");

        if path.is_dir() {
            entries.push(TemplateFileEntry {
                path: rel_str.clone() + "/",
                is_dir: true,
                size: 0,
            });
            list_files_recursive(base, &path, entries)?;
        } else {
            let size = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
            entries.push(TemplateFileEntry {
                path: rel_str,
                is_dir: false,
                size,
            });
        }
    }
    Ok(())
}

fn read_all_templates(app: &AppHandle) -> Vec<ProjectTemplate> {
    let root = templates_root(app);
    let mut result = Vec::new();
    if !root.exists() {
        return result;
    }
    if let Ok(entries) = fs::read_dir(&root) {
        for entry in entries.flatten() {
            if entry.path().is_dir() {
                if let Some(t) = read_template_json(&entry.path()) {
                    result.push(t);
                }
            }
        }
    }
    result
}

fn delete_template_dir(app: &AppHandle, id: &str) {
    let dir = template_dir(app, id);
    let _ = fs::remove_dir_all(&dir);
}

#[tauri::command]
pub fn sync_templates_with_scan_dir(app: AppHandle) -> Result<TemplateSyncResult, String> {
    let settings = crate::settings::read_settings(&app);
    let scan_dir = match &settings.template_scan_dir {
        Some(d) if !d.trim().is_empty() => PathBuf::from(d.trim()),
        _ => return Err("No template scan directory configured. Set one in Settings → Storage.".into()),
    };

    if !scan_dir.exists() {
        return Err(format!(
            "Template scan directory does not exist: {}",
            scan_dir.display()
        ));
    }

    let scan_dir_canon = scan_dir.canonicalize().unwrap_or(scan_dir.clone());
    let mut source_to_folder: std::collections::HashMap<String, String> = std::collections::HashMap::new();
    if let Ok(entries) = fs::read_dir(&scan_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if !path.is_dir() {
                continue;
            }
            let name = match entry.file_name().to_str() {
                Some(n) if !n.starts_with('.') => n.to_string(),
                _ => continue,
            };
            let full = scan_dir_canon.join(&name).to_string_lossy().to_string();
            source_to_folder.insert(full, name);
        }
    }

    let name_to_path: std::collections::HashMap<String, String> = source_to_folder
        .iter()
        .map(|(path, name)| (name.clone(), path.clone()))
        .collect();

    let existing = read_all_templates(&app);
    let mut updated_names: Vec<String> = Vec::new();
    let mut removed_names: Vec<String> = Vec::new();
    let mut imported: Vec<ProjectTemplate> = Vec::new();

    for mut t in existing {
        if t.source_path.is_none() {
            continue;
        }

        let src_path = t.source_path.as_ref().unwrap();

        if source_to_folder.contains_key(src_path) {
            let src = PathBuf::from(src_path);
            let dst = template_dir(&app, &t.id);
            if let Err(e) = copy_dir(&src, &dst, &[".godot", ".git", "node_modules"]) {
                eprintln!("Failed to update template '{}': {}", t.name, e);
                continue;
            }

            if let Some(proj_name) = crate::projects::resolve_project_name(&src.to_string_lossy()) {
                if proj_name != t.name {
                    t.name = proj_name;
                    let _ = write_template_json(&dst, &t);
                }
            }

            updated_names.push(t.name.clone());
        } else if !Path::new(src_path).exists() {
            let folder_name = Path::new(src_path)
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_default();

            if let Some(new_path) = name_to_path.get(&folder_name) {
                t.source_path = Some(new_path.clone());
                let src = PathBuf::from(new_path);
                let dst = template_dir(&app, &t.id);

                if let Err(e) = copy_dir(&src, &dst, &[".godot", ".git", "node_modules"]) {
                    eprintln!("Failed to update template '{}' after rename: {}", t.name, e);
                    delete_template_dir(&app, &t.id);
                    removed_names.push(t.name.clone());
                    continue;
                }

                if let Some(proj_name) = crate::projects::resolve_project_name(&src.to_string_lossy()) {
                    t.name = proj_name;
                }

                let _ = write_template_json(&dst, &t);
                updated_names.push(format!("{} (moved)", t.name));
            } else {
                delete_template_dir(&app, &t.id);
                removed_names.push(t.name.clone());
            }
        } else {
            delete_template_dir(&app, &t.id);
            removed_names.push(t.name.clone());
        }
    }

    let remaining = read_all_templates(&app);
    let existing_sources: std::collections::HashSet<String> = remaining
        .iter()
        .filter_map(|t| t.source_path.clone())
        .collect();

    for (full_path, folder_name) in &source_to_folder {
        if existing_sources.contains(full_path) {
            continue;
        }

        let src = PathBuf::from(full_path);
        let id = Uuid::new_v4().to_string();
        let dst = template_dir(&app, &id);

        if let Err(e) = copy_dir(&src, &dst, &[".godot", ".git", "node_modules"]) {
            eprintln!("Failed to import template '{}': {}", folder_name, e);
            continue;
        }

        let project_name = crate::projects::resolve_project_name(&src.to_string_lossy());

        let template = ProjectTemplate {
            id: id.clone(),
            name: project_name.unwrap_or_else(|| folder_name.clone()),
            description: format!("Imported from {}", folder_name),
            godot_version: String::new(),
            created_at: chrono::Utc::now().to_rfc3339(),
            source_project_id: None,
            source_path: Some(full_path.clone()),
            path: dst.to_string_lossy().to_string(),
        };

        if write_template_json(&dst, &template).is_ok() {
            imported.push(template);
        }
    }

    Ok(TemplateSyncResult {
        imported,
        updated: updated_names,
        removed: removed_names,
    })
}
