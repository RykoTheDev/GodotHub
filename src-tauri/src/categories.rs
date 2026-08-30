use crate::error::AppResult;
use crate::persist;
use crate::models::*;
use crate::projects;
use tauri::AppHandle;
use uuid::Uuid;

pub(crate) fn read_categories_from(dir: &std::path::Path) -> Vec<Category> {
    persist::read_json(&dir.join("categories.json"))
}

pub(crate) fn read_categories(app: &AppHandle) -> Vec<Category> {
    read_categories_from(&crate::workspace::active_workspace_dir(app))
}

pub(crate) fn write_categories_to(
    dir: &std::path::Path,
    categories: &Vec<Category>,
) -> AppResult<()> {
    persist::write_json(&dir.join("categories.json"), categories)
}

pub(crate) fn write_categories(app: &AppHandle, categories: &Vec<Category>) -> AppResult<()> {
    write_categories_to(&crate::workspace::active_workspace_dir(app), categories)
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
            let mut changed = false;
            for p in all_projects.iter_mut() {
                if p.category.as_deref() == Some(old_name.as_str()) {
                    p.category = Some(cats[idx].name.clone());
                    changed = true;
                }
            }
            if changed {
                projects::write_projects(&app, &all_projects).map_err(|e| e.to_string())?;
            }
        }
    }

    if let Some(ref new_color) = color {
        cats[idx].color = new_color.clone();
    }

    let updated = cats[idx].clone();
    write_categories(&app, &cats).map_err(|e| e.to_string())?;
    Ok(updated)
}

#[tauri::command]
pub fn rename_category(app: AppHandle, id: String, name: String) -> Result<Category, String> {
    update_category(app, id, Some(name), None)
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
    let mut changed = false;
    for p in all_projects.iter_mut() {
        if p.category.as_deref() == Some(removed.name.as_str()) {
            p.category = None;
            changed = true;
        }
    }
    if changed {
        projects::write_projects(&app, &all_projects).map_err(|e| e.to_string())?;
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
