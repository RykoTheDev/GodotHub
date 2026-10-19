use crate::error::AppResult;
use crate::persist;
use crate::models::*;
use crate::projects;
use tauri::AppHandle;
use uuid::Uuid;

pub(crate) fn read_categories_from(dir: &std::path::Path) -> Vec<Category> {
    persist::read_json_with_backup(&dir.join("categories.json"))
}

pub(crate) fn read_categories(app: &AppHandle) -> Vec<Category> {
    read_categories_from(&crate::workspace::active_workspace_dir(app))
}

pub(crate) fn write_categories_to(
    dir: &std::path::Path,
    categories: &Vec<Category>,
) -> AppResult<()> {
    persist::write_json_with_backup(&dir.join("categories.json"), categories)
}

pub(crate) fn write_categories(app: &AppHandle, categories: &Vec<Category>) -> AppResult<()> {
    write_categories_to(&crate::workspace::active_workspace_dir(app), categories)
}

fn normalize_folder(folder: &str) -> Option<String> {
    let trimmed = folder.trim();
    if trimmed.is_empty() {
        return None;
    }
    let without_trailing = trimmed.trim_end_matches(['/', '\\']);
    let value = if without_trailing.is_empty() {
        trimmed
    } else {
        without_trailing
    };
    Some(value.to_string())
}

fn folder_assignments(categories: &[Category]) -> Vec<(String, String)> {
    categories
        .iter()
        .flat_map(|c| {
            c.folders
                .iter()
                .map(|f| (c.name.clone(), f.clone()))
                .collect::<Vec<_>>()
        })
        .filter(|(_, folder)| !folder.trim().is_empty())
        .collect()
}

pub(crate) fn best_folder_match(
    assignments: &[(String, String)],
    project_path: &str,
) -> Option<String> {
    let mut best: Option<(usize, &str)> = None;
    for (name, folder) in assignments {
        if !projects::path_is_within(project_path, folder) {
            continue;
        }
        let specificity = folder.trim_end_matches(['/', '\\']).len();
        if best.is_none_or(|(best_len, _)| specificity > best_len) {
            best = Some((specificity, name.as_str()));
        }
    }
    best.map(|(_, name)| name.to_string())
}

pub(crate) fn category_for_path(app: &AppHandle, project_path: &str) -> Option<String> {
    let assignments = folder_assignments(&read_categories(app));
    best_folder_match(&assignments, project_path)
}

fn apply_folder_rules_within(app: &AppHandle, folder: &str) {
    let assignments = folder_assignments(&read_categories(app));
    let mut projects = projects::read_projects(app);
    let mut changed: Vec<(String, String, Option<String>)> = Vec::new();
    for p in projects.iter_mut() {
        if !projects::path_is_within(&p.path, folder) {
            continue;
        }
        let next = best_folder_match(&assignments, &p.path);
        if p.category != next {
            p.category = next.clone();
            changed.push((p.path.clone(), p.id.clone(), next));
        }
    }
    if changed.is_empty() {
        return;
    }
    if projects::write_projects(app, &projects).is_err() {
        return;
    }
    for (path, pid, category) in &changed {
        let _ = crate::project_identity::ensure_project_identity(path, pid, category.as_deref());
    }
}

#[tauri::command]
pub fn list_categories(app: AppHandle) -> Vec<Category> {
    let mut cats = read_categories(&app);
    cats.sort_by_key(|c| c.sort_order);
    cats
}

#[tauri::command]
pub fn create_category(app: AppHandle, name: String, color: Option<String>) -> Result<Category, String> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err("Category name can't be empty".into());
    }
    let mut cats = read_categories(&app);
    if cats.iter().any(|c| c.name.eq_ignore_ascii_case(&trimmed)) {
        return Err("A category with this name already exists".into());
    }
    let next_order = cats
        .iter()
        .map(|c| c.sort_order)
        .max()
        .map(|m| m + 1)
        .unwrap_or(0);
    let effective_color = color.unwrap_or_else(default_accent);
    let category = Category {
        id: Uuid::new_v4().to_string(),
        name: trimmed,
        sort_order: next_order,
        color: effective_color,
        hidden: false,
        folders: vec![],
    };
    cats.push(category.clone());
    write_categories(&app, &cats).map_err(|e| e.to_string())?;
    Ok(category)
}

#[tauri::command]
pub fn update_category(
    app: AppHandle,
    id: String,
    name: Option<String>,
    color: Option<String>,
    hidden: Option<bool>,
) -> Result<Category, String> {
    let mut cats = read_categories(&app);
    let idx = cats
        .iter()
        .position(|c| c.id == id)
        .ok_or("Category not found")?;

    if let Some(ref new_name) = name {
        let trimmed = new_name.trim().to_string();
        if trimmed.is_empty() {
            return Err("Category name can't be empty".into());
        }
        if cats
            .iter()
            .any(|c| c.id != id && c.name.eq_ignore_ascii_case(&trimmed))
        {
            return Err("A category with this name already exists".into());
        }
        let old_name = cats[idx].name.clone();
        cats[idx].name = trimmed;

        if old_name != cats[idx].name {
            let mut all_projects = projects::read_projects(&app);
            let mut changed_paths: Vec<(String, String)> = Vec::new();
            for p in all_projects.iter_mut() {
                if p.category.as_deref() == Some(old_name.as_str()) {
                    p.category = Some(cats[idx].name.clone());
                    changed_paths.push((p.path.clone(), p.id.clone()));
                }
            }
            if !changed_paths.is_empty() {
                projects::write_projects(&app, &all_projects).map_err(|e| e.to_string())?;
                for (path, pid) in &changed_paths {
                    crate::project_identity::ensure_project_identity(
                        path,
                        pid,
                        Some(cats[idx].name.as_str()),
                    );
                }
            }
        }
    }

    if let Some(ref new_color) = color {
        cats[idx].color = new_color.clone();
    }

    if let Some(hidden) = hidden {
        cats[idx].hidden = hidden;
    }

    let updated = cats[idx].clone();
    write_categories(&app, &cats).map_err(|e| e.to_string())?;
    Ok(updated)
}

#[tauri::command]
pub fn rename_category(app: AppHandle, id: String, name: String) -> Result<Category, String> {
    update_category(app, id, Some(name), None, None)
}

#[tauri::command]
pub fn delete_category(app: AppHandle, id: String) -> Result<(), String> {
    let mut cats = read_categories(&app);
    let idx = cats
        .iter()
        .position(|c| c.id == id)
        .ok_or("Category not found")?;
    let removed = cats.remove(idx);
    write_categories(&app, &cats).map_err(|e| e.to_string())?;

    let mut all_projects = projects::read_projects(&app);
    let mut changed_paths: Vec<(String, String)> = Vec::new();
    for p in all_projects.iter_mut() {
        if p.category.as_deref() == Some(removed.name.as_str()) {
            p.category = None;
            changed_paths.push((p.path.clone(), p.id.clone()));
        }
    }
    if !changed_paths.is_empty() {
        projects::write_projects(&app, &all_projects).map_err(|e| e.to_string())?;
        for (path, pid) in &changed_paths {
            crate::project_identity::ensure_project_identity(path, pid, None);
        }
    }
    Ok(())
}

#[tauri::command]
pub fn reorder_categories(app: AppHandle, ordered_ids: Vec<String>) -> Result<(), String> {
    let mut cats = read_categories(&app);
    for (i, id) in ordered_ids.iter().enumerate() {
        if let Some(c) = cats.iter_mut().find(|c| &c.id == id) {
            c.sort_order = i as i64;
        }
    }
    write_categories(&app, &cats).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn add_category_folder(app: AppHandle, id: String, folder: String) -> Result<Category, String> {
    let Some(folder) = normalize_folder(&folder) else {
        return Err("Folder path can't be empty".into());
    };
    let mut cats = read_categories(&app);
    let idx = cats
        .iter()
        .position(|c| c.id == id)
        .ok_or("Category not found")?;

    if cats[idx].folders.iter().any(|f| projects::same_path(f, &folder)) {
        return Ok(cats[idx].clone());
    }

    if let Some(other) = cats.iter().find(|c| {
        c.id != id && c.folders.iter().any(|f| projects::same_path(f, &folder))
    }) {
        return Err(format!(
            "This folder is already assigned to \"{}\"",
            other.name
        ));
    }

    cats[idx].folders.push(folder.clone());
    write_categories(&app, &cats).map_err(|e| e.to_string())?;
    apply_folder_rules_within(&app, &folder);
    Ok(cats[idx].clone())
}

#[tauri::command]
pub fn remove_category_folder(app: AppHandle, id: String, folder: String) -> Result<Category, String> {
    let mut cats = read_categories(&app);
    let idx = cats
        .iter()
        .position(|c| c.id == id)
        .ok_or("Category not found")?;
    let before = cats[idx].folders.len();
    cats[idx]
        .folders
        .retain(|f| !projects::same_path(f, &folder));
    if cats[idx].folders.len() == before {
        return Err("This folder is not assigned to the category".into());
    }
    write_categories(&app, &cats).map_err(|e| e.to_string())?;
    Ok(cats[idx].clone())
}