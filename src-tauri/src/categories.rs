use crate::error::AppResult;
use crate::models::*;
use crate::persist;
use crate::projects;
use std::sync::MutexGuard;
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

fn categories_lock(app: &AppHandle) -> MutexGuard<'_, ()> {
    crate::file_locks(app)
        .categories
        .lock()
        .unwrap_or_else(|e| e.into_inner())
}

fn mutate_categories<T>(
    app: &AppHandle,
    mutate: impl FnOnce(&mut Vec<Category>) -> Result<(T, bool), String>,
) -> Result<T, String> {
    let _guard = categories_lock(app);
    let mut categories = read_categories(app);
    let (value, changed) = mutate(&mut categories)?;
    if changed {
        write_categories(app, &categories).map_err(|e| e.to_string())?;
    }
    Ok(value)
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
    mutate_categories(&app, |cats| {
        if cats.iter().any(|c| c.name.eq_ignore_ascii_case(&trimmed)) {
            return Err("A category with this name already exists".into());
        }
        let next_order = cats
            .iter()
            .map(|c| c.sort_order)
            .max()
            .map(|m| m + 1)
            .unwrap_or(0);
        let category = Category {
            id: Uuid::new_v4().to_string(),
            name: trimmed.clone(),
            sort_order: next_order,
            color: color.unwrap_or_else(default_accent),
            hidden: false,
        };
        cats.push(category.clone());
        Ok((category, true))
    })
}

#[tauri::command]
pub fn update_category(
    app: AppHandle,
    id: String,
    name: Option<String>,
    color: Option<String>,
    hidden: Option<bool>,
) -> Result<Category, String> {
    let (updated, rename) = mutate_categories(&app, |cats| {
        let idx = cats
            .iter()
            .position(|c| c.id == id)
            .ok_or("Category not found")?;

        let mut rename: Option<(String, String)> = None;
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
                rename = Some((old_name, cats[idx].name.clone()));
            }
        }

        if let Some(ref new_color) = color {
            cats[idx].color = new_color.clone();
        }

        if let Some(hidden) = hidden {
            cats[idx].hidden = hidden;
        }

        let updated = cats[idx].clone();
        Ok(((updated, rename), true))
    })?;

    if let Some((old_name, new_name)) = rename {
        projects::mutate_projects(&app, |all_projects| {
            let mut changed = false;
            for p in all_projects.iter_mut() {
                if p.category.as_deref() == Some(old_name.as_str()) {
                    p.category = Some(new_name.clone());
                    changed = true;
                }
            }
            Ok(((), changed))
        })?;
    }

    Ok(updated)
}

#[tauri::command]
pub fn rename_category(app: AppHandle, id: String, name: String) -> Result<Category, String> {
    update_category(app, id, Some(name), None, None)
}

#[tauri::command]
pub fn delete_category(app: AppHandle, id: String) -> Result<(), String> {
    let removed = mutate_categories(&app, |cats| {
        let idx = cats
            .iter()
            .position(|c| c.id == id)
            .ok_or("Category not found")?;
        Ok((cats.remove(idx), true))
    })?;

    projects::mutate_projects(&app, |all_projects| {
        let mut changed = false;
        for p in all_projects.iter_mut() {
            if p.category.as_deref() == Some(removed.name.as_str()) {
                p.category = None;
                changed = true;
            }
        }
        Ok(((), changed))
    })
}

#[tauri::command]
pub fn reorder_categories(app: AppHandle, ordered_ids: Vec<String>) -> Result<(), String> {
    mutate_categories(&app, |cats| {
        for (i, id) in ordered_ids.iter().enumerate() {
            if let Some(c) = cats.iter_mut().find(|c| &c.id == id) {
                c.sort_order = i as i64;
            }
        }
        Ok(((), true))
    })
}
