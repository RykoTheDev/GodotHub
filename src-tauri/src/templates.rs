use crate::models::*;
use std::fs;
use std::path::{Path, PathBuf};
use tauri::{AppHandle, Manager};
use uuid::Uuid;

fn templates_root(app: &AppHandle) -> PathBuf {
    let dir = crate::workspace::active_workspace_dir(app).join("templates");
    if !dir.exists() {
        let _ = fs::create_dir_all(&dir);
    }
    dir
}

pub(crate) fn template_dir(app: &AppHandle, id: &str) -> PathBuf {
    templates_root(app).join(id)
}

pub(crate) fn sanitize_folder_name(name: &str) -> String {
    let cleaned: String = name
        .chars()
        .map(|c| match c {
            '<' | '>' | ':' | '"' | '/' | '\\' | '|' | '?' | '*' => '_',
            c if (c as u32) < 32 => '_',
            c => c,
        })
        .collect();
    let trimmed = cleaned
        .trim()
        .trim_end_matches(['.', ' '])
        .to_string();
    let result = if trimmed.is_empty() {
        "Template".to_string()
    } else {
        trimmed
    };
    if result.starts_with('.') || is_reserved_windows_name(&result) {
        format!("_{result}")
    } else {
        result
    }
}

fn is_reserved_windows_name(name: &str) -> bool {
    let upper = name.to_ascii_uppercase();
    if matches!(upper.as_str(), "CON" | "PRN" | "AUX" | "NUL" | "CLOCK$") {
        return true;
    }
    for prefix in ["COM", "LPT"] {
        if let Some(rest) = upper.strip_prefix(prefix) {
            if rest.len() == 1
                && rest
                    .chars()
                    .next()
                    .map(|c| c.is_ascii_digit())
                    .unwrap_or(false)
            {
                return true;
            }
        }
    }
    false
}

fn configured_scan_dir(app: &AppHandle) -> Option<PathBuf> {
    let settings = crate::settings::read_settings(app);
    settings
        .template_scan_dir
        .as_deref()
        .map(str::trim)
        .filter(|d| !d.is_empty())
        .map(PathBuf::from)
        .and_then(|p| p.canonicalize().ok())
}

fn unique_folder_name(scan_dir: &Path, base: &str) -> String {
    let mut name = base.to_string();
    let mut n = 2;
    while scan_dir.join(&name).exists() {
        name = format!("{base} ({n})");
        n += 1;
    }
    name
}

pub(crate) fn read_template_json(dir: &Path) -> Option<ProjectTemplate> {
    let file = dir.join("template.json");
    if !file.exists() {
        return None;
    }
    serde_json::from_str(&fs::read_to_string(&file).ok()?).ok()
}

pub(crate) fn write_template_json(dir: &Path, template: &ProjectTemplate) -> Result<(), String> {
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

pub(crate) fn mirror_dir(src: &Path, dst: &Path, skip_dirs: &[&str]) -> Result<(), String> {
    if !dst.exists() {
        fs::create_dir_all(dst).map_err(|e| e.to_string())?;
    }

    fn prune(src: &Path, dst: &Path, skip_dirs: &[&str]) -> Result<(), String> {
        let mut src_entries: std::collections::HashMap<String, bool> = std::collections::HashMap::new();
        for entry in fs::read_dir(src).map_err(|e| e.to_string())? {
            let entry = entry.map_err(|e| e.to_string())?;
            let name = entry.file_name().to_string_lossy().to_string();
            if skip_dirs.iter().any(|d| name == *d) {
                continue;
            }
            let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
            src_entries.insert(name, is_dir);
        }

        for entry in fs::read_dir(dst).map_err(|e| e.to_string())? {
            let entry = entry.map_err(|e| e.to_string())?;
            let name = entry.file_name().to_string_lossy().to_string();
            if name == "template.json" || skip_dirs.iter().any(|d| name == *d) {
                continue;
            }
            let dst_is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
            match src_entries.get(&name) {
                None => {
                    remove_dir_force(&entry.path())?;
                }
                Some(src_is_dir) if *src_is_dir != dst_is_dir => {
                    remove_dir_force(&entry.path())?;
                }
                Some(true) => {
                    prune(&src.join(&name), &entry.path(), skip_dirs)?;
                }
                _ => {}
            }
        }
        Ok(())
    }

    prune(src, dst, skip_dirs)?;
    copy_dir(src, dst, skip_dirs)
}

pub(crate) fn install_downloaded_asset(
    app: &AppHandle,
    name: String,
    description: String,
    godot_version: String,
    src: &Path,
) -> Result<ProjectTemplate, String> {
    if !src.join("project.godot").is_file() {
        return Err("Downloaded asset does not contain a project.godot file".into());
    }
    let id = Uuid::new_v4().to_string();
    let dst = template_dir(app, &id);

    copy_dir(src, &dst, &[".godot", ".git", "node_modules"])?;

    let mut template = ProjectTemplate {
        id: id.clone(),
        name,
        description,
        godot_version,
        created_at: chrono::Utc::now().to_rfc3339(),
        source_project_id: None,
        source_path: None,
        path: dst.to_string_lossy().to_string(),
        keep_name: true,
    };

    write_template_json(&dst, &template)?;

    if let Some(scan_dir) = configured_scan_dir(app) {
        let folder_name = unique_folder_name(&scan_dir, &sanitize_folder_name(&template.name));
        let scan_copy = scan_dir.join(&folder_name);
        if fs::create_dir_all(&scan_copy).is_ok()
            && copy_dir(src, &scan_copy, &[".godot", ".git", "node_modules"]).is_ok()
        {
            let source_path = scan_dir.join(&folder_name).to_string_lossy().to_string();
            template.source_path = Some(source_path);
            if write_template_json(&scan_copy, &template).is_ok() {
                let _ = write_template_json(&dst, &template);
            } else {
                let _ = fs::remove_dir_all(&scan_copy);
                template.source_path = None;
                let _ = write_template_json(&dst, &template);
            }
        } else {
            let _ = fs::remove_dir_all(&scan_copy);
        }
    }

    Ok(template)
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
            if let Some(mut t) = read_template_json(&path) {
                let folder_name = path
                    .file_name()
                    .map(|n| n.to_string_lossy().to_string())
                    .unwrap_or_default();
                if t.id != folder_name {
                    t.id = folder_name.clone();
                    t.path = path.to_string_lossy().to_string();
                    let _ = write_template_json(&path, &t);
                }
                t.path = path.to_string_lossy().to_string();
                templates.push(t);
            }
        }
    }
    templates
}

pub(crate) fn consolidate_legacy_templates(app: &AppHandle) {
    let base = app.path().app_data_dir().expect("no app data dir");
    let legacy = base.join("templates");

    if legacy.is_dir() {
        let workspace_root = templates_root(app);
        if let Ok(entries) = fs::read_dir(&legacy) {
            for entry in entries.flatten() {
                let src = entry.path();
                if !src.is_dir() || !src.join("template.json").is_file() {
                    continue;
                }
                let id = read_template_json(&src)
                    .map(|t| t.id)
                    .unwrap_or_else(|| {
                        src.file_name()
                            .map(|n| n.to_string_lossy().to_string())
                            .unwrap_or_default()
                    });
                let dst = workspace_root.join(&id);
                if dst.exists() {
                    continue;
                }
                if copy_dir(&src, &dst, &[]).is_ok() {
                    if let Some(mut t) = read_template_json(&dst) {
                        t.path = dst.to_string_lossy().to_string();
                        let _ = write_template_json(&dst, &t);
                    }
                }
            }
        }
        let _ = delete_dir_best_effort(&legacy);
    }

    for t in read_all_templates(app) {
        let dir = template_dir(app, &t.id);
        let actual = dir.to_string_lossy().to_string();
        if t.path != actual {
            let mut fixed = t;
            fixed.path = actual;
            let _ = write_template_json(&dir, &fixed);
        }
    }
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

    let mut template = ProjectTemplate {
        id: id.clone(),
        name: trimmed,
        description,
        godot_version: project.godot_version.clone(),
        created_at: chrono::Utc::now().to_rfc3339(),
        source_project_id: Some(project_id),
        source_path: None,
        path: dst.to_string_lossy().to_string(),
        keep_name: false,
    };

    write_template_json(&dst, &template)?;

    if let Some(scan_dir) = configured_scan_dir(&app) {
        let folder_name = unique_folder_name(&scan_dir, &sanitize_folder_name(&template.name));
        let scan_copy = scan_dir.join(&folder_name);
        if fs::create_dir_all(&scan_copy).is_ok()
            && copy_dir(&src, &scan_copy, &[".godot", ".git", "node_modules"]).is_ok()
        {
            let source_path = scan_dir.join(&folder_name).to_string_lossy().to_string();
            template.source_path = Some(source_path);
            if write_template_json(&scan_copy, &template).is_ok() {
                let _ = write_template_json(&dst, &template);
            } else {
                let _ = fs::remove_dir_all(&scan_copy);
                template.source_path = None;
                let _ = write_template_json(&dst, &template);
            }
        } else {
            let _ = fs::remove_dir_all(&scan_copy);
        }
    }

    Ok(template)
}

pub(crate) fn remove_dir_force(dir: &Path) -> Result<(), String> {
    #[allow(clippy::permissions_set_readonly_false)]
    fn clear_readonly(path: &Path) {
        if let Ok(meta) = fs::metadata(path) {
            let mut perms = meta.permissions();
            perms.set_readonly(false);
            let _ = fs::set_permissions(path, perms);
        }
    }

    fn walk(dir: &Path) -> Result<(), String> {
        if dir.is_dir() {
            for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
                let entry = entry.map_err(|e| e.to_string())?;
                let path = entry.path();
                clear_readonly(&path);
                if path.is_dir() {
                    walk(&path)?;
                } else {
                    fs::remove_file(&path).map_err(|e| e.to_string())?;
                }
            }
            fs::remove_dir(dir).map_err(|e| e.to_string())
        } else {
            clear_readonly(dir);
            fs::remove_file(dir).map_err(|e| e.to_string())
        }
    }

    walk(dir)
}

fn delete_dir_best_effort(dir: &Path) -> bool {
    trash::delete_all(dir)
        .map_err(|e| e.to_string())
        .or_else(|_| remove_dir_force(dir))
        .is_ok()
}

fn find_template_dir_by_id(app: &AppHandle, id: &str) -> Option<PathBuf> {
    let root = templates_root(app);
    if !root.exists() {
        return None;
    }
    if let Ok(entries) = fs::read_dir(&root) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                if let Some(t) = read_template_json(&path) {
                    if t.id == id {
                        return Some(path);
                    }
                }
            }
        }
    }
    None
}

pub(crate) fn resolve_template_dir(app: &AppHandle, id: &str) -> Option<PathBuf> {
    let dir = template_dir(app, id);
    if dir.exists() {
        Some(dir)
    } else {
        find_template_dir_by_id(app, id)
    }
}

#[tauri::command]
pub fn delete_template(app: AppHandle, template_id: String) -> Result<(), String> {
    let dir = resolve_template_dir(&app, &template_id).ok_or("Template not found")?;

    if let Some(t) = read_template_json(&dir) {
        if let Some(src) = &t.source_path {
            if let Some(scan_dir) = configured_scan_dir(&app) {
                if let Ok(src_canon) = PathBuf::from(src).canonicalize() {
                    if src_canon.starts_with(&scan_dir) && src_canon.join("template.json").is_file() {
                        let _ = delete_dir_best_effort(&src_canon);
                    }
                }
            }
        }
    }

    if delete_dir_best_effort(&dir) {
        Ok(())
    } else {
        Err(format!("Could not delete template folder: {}", dir.display()))
    }
}

#[tauri::command]
pub fn get_template_preview(app: AppHandle, template_id: String) -> Result<Vec<TemplateFileEntry>, String> {
    let dir = resolve_template_dir(&app, &template_id).ok_or("Template not found")?;

    let mut entries = Vec::new();
    list_files_recursive(&dir, &dir, &mut entries)?;
    Ok(entries)
}

fn list_files_recursive(base: &Path, dir: &Path, entries: &mut Vec<TemplateFileEntry>) -> Result<(), String> {
    for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        let name = entry.file_name();
        if name == "template.json" {
            continue;
        }
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
    let _ = delete_dir_best_effort(&dir);
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
            if let Some(scan_dir) = configured_scan_dir(&app) {
                let src_dir = template_dir(&app, &t.id);
                let folder_name = unique_folder_name(&scan_dir, &sanitize_folder_name(&t.name));
                let scan_copy = scan_dir.join(&folder_name);
                if fs::create_dir_all(&scan_copy).is_ok()
                    && copy_dir(&src_dir, &scan_copy, &[".godot", ".git", "node_modules"]).is_ok()
                {
                    if t.source_project_id.is_none() {
                        t.keep_name = true;
                    }
                    let source_path = scan_dir.join(&folder_name).to_string_lossy().to_string();
                    t.source_path = Some(source_path);
                    if write_template_json(&scan_copy, &t).is_ok() {
                        let _ = write_template_json(&src_dir, &t);
                        updated_names.push(format!("{} (moved to folder)", t.name));
                    } else {
                        let _ = fs::remove_dir_all(&scan_copy);
                        t.source_path = None;
                    }
                } else {
                    let _ = fs::remove_dir_all(&scan_copy);
                }
            }
            continue;
        }

        let src_path = t.source_path.as_ref().unwrap();

        if source_to_folder.contains_key(src_path) {
            let src = PathBuf::from(src_path);
            let dst = template_dir(&app, &t.id);
            if let Err(e) = mirror_dir(&src, &dst, &[".godot", ".git", "node_modules"]) {
                eprintln!("Failed to update template '{}': {}", t.name, e);
                continue;
            }

            let _ = write_template_json(&dst, &t);

            if t.source_project_id.is_none() && !t.keep_name {
                if let Some(proj_name) = crate::projects::resolve_project_name(&src.to_string_lossy()) {
                    if proj_name != t.name {
                        t.name = proj_name;
                        let _ = write_template_json(&dst, &t);
                    }
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

                if let Err(e) = mirror_dir(&src, &dst, &[".godot", ".git", "node_modules"]) {
                    eprintln!("Failed to update template '{}' after rename: {}", t.name, e);
                    delete_template_dir(&app, &t.id);
                    removed_names.push(t.name.clone());
                    continue;
                }

                if t.source_project_id.is_none() && !t.keep_name {
                    if let Some(proj_name) = crate::projects::resolve_project_name(&src.to_string_lossy()) {
                        t.name = proj_name;
                    }
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
            keep_name: false,
        };

        if write_template_json(&dst, &template).is_ok() {
            let _ = write_template_json(&src, &template);
            imported.push(template);
        }
    }

    Ok(TemplateSyncResult {
        imported,
        updated: updated_names,
        removed: removed_names,
    })
}
