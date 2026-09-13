use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use tauri::{AppHandle, Manager};

pub const ALIAS_CANDIDATES: [&str; 3] = ["Godot.exe", "Godot.cmd", "Godot"];

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct CurrentVersionInfo {
    pub tag: String,
    pub alias_path: String,
    pub aliases_dir: String,
    pub method: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CurrentVersionState {
    #[serde(default)]
    tag: Option<String>,
    #[serde(default = "default_method")]
    method: String,
}

fn default_method() -> String {
    "symlink".to_string()
}

#[cfg(target_os = "windows")]
pub fn alias_file_name() -> &'static str {
    "Godot.exe"
}

#[cfg(not(target_os = "windows"))]
pub fn alias_file_name() -> &'static str {
    "Godot"
}

pub fn aliases_dir(app: &AppHandle) -> PathBuf {
    let dir = app
        .path()
        .app_data_dir()
        .expect("no app data dir")
        .join("bin");
    if !dir.exists() {
        let _ = fs::create_dir_all(&dir);
    }
    dir
}

fn state_file(app: &AppHandle) -> PathBuf {
    app.path()
        .app_data_dir()
        .expect("no app data dir")
        .join("current-version.json")
}

fn read_state(app: &AppHandle) -> Option<CurrentVersionState> {
    crate::persist::read_json_opt_with_backup(&state_file(app))
}

pub fn read_current_tag(app: &AppHandle) -> Option<String> {
    read_state(app)?.tag
}

#[cfg(any(target_os = "windows", test))]
pub fn shim_script(target: &Path) -> String {
    format!("@echo off\r\n\"{}\" %*\r\n", target.display())
}

fn remove_existing_aliases(dir: &Path) {
    for name in ALIAS_CANDIDATES {
        let path = dir.join(name);
        if fs::symlink_metadata(&path).is_ok() {
            let _ = fs::remove_file(&path);
        }
    }
}

#[cfg(unix)]
fn create_alias(target: &Path, alias: &Path) -> Result<(&'static str, PathBuf), String> {
    std::os::unix::fs::symlink(target, alias).map_err(|e| e.to_string())?;
    Ok(("symlink", alias.to_path_buf()))
}

#[cfg(target_os = "windows")]
fn create_alias(target: &Path, alias: &Path) -> Result<(&'static str, PathBuf), String> {
    if std::os::windows::fs::symlink_file(target, alias).is_ok() {
        return Ok(("symlink", alias.to_path_buf()));
    }
    if fs::hard_link(target, alias).is_ok() {
        return Ok(("hardlink", alias.to_path_buf()));
    }
    let shim = alias.with_extension("cmd");
    fs::write(&shim, shim_script(target)).map_err(|e| e.to_string())?;
    Ok(("shim", shim))
}

fn activate(app: &AppHandle, tag: &str) -> Result<CurrentVersionInfo, String> {
    let list = crate::godot_versions::read_registry(app);
    let version = list
        .iter()
        .find(|v| v.tag == tag)
        .ok_or("Version not found")?;
    let target = PathBuf::from(&version.executable_path);
    if !target.is_file() {
        return Err("Executable no longer exists at that path".into());
    }

    let dir = aliases_dir(app);
    remove_existing_aliases(&dir);
    let (method, alias_path) = create_alias(&target, &dir.join(alias_file_name()))?;

    let state = CurrentVersionState {
        tag: Some(tag.to_string()),
        method: method.to_string(),
    };
    crate::persist::write_json_with_backup(&state_file(app), &state).map_err(|e| e.to_string())?;

    Ok(CurrentVersionInfo {
        tag: tag.to_string(),
        alias_path: alias_path.to_string_lossy().to_string(),
        aliases_dir: dir.to_string_lossy().to_string(),
        method: method.to_string(),
    })
}

pub fn clear(app: &AppHandle) -> Result<(), String> {
    remove_existing_aliases(&aliases_dir(app));
    let file = state_file(app);
    if file.exists() {
        fs::remove_file(&file).map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn clear_if_current(app: &AppHandle, tag: &str) {
    if read_current_tag(app).as_deref() == Some(tag) {
        let _ = clear(app);
    }
}

#[tauri::command]
pub fn get_current_version(app: AppHandle) -> Option<CurrentVersionInfo> {
    let state = read_state(&app)?;
    let tag = state.tag?;

    let list = crate::godot_versions::read_registry(&app);
    let Some(version) = list.iter().find(|v| v.tag == tag) else {
        let _ = clear(&app);
        return None;
    };
    let target = PathBuf::from(&version.executable_path);
    if !target.is_file() {
        let _ = clear(&app);
        return None;
    }

    let dir = aliases_dir(&app);
    let alias = dir.join(alias_file_name());

    if fs::symlink_metadata(&alias).is_err() {
        remove_existing_aliases(&dir);
        let Ok((method, alias_path)) = create_alias(&target, &alias) else {
            let _ = clear(&app);
            return None;
        };
        let state = CurrentVersionState {
            tag: Some(tag.clone()),
            method: method.to_string(),
        };
        let _ = crate::persist::write_json_with_backup(&state_file(&app), &state);
        return Some(CurrentVersionInfo {
            tag,
            alias_path: alias_path.to_string_lossy().to_string(),
            aliases_dir: dir.to_string_lossy().to_string(),
            method: method.to_string(),
        });
    }

    Some(CurrentVersionInfo {
        tag,
        alias_path: alias.to_string_lossy().to_string(),
        aliases_dir: dir.to_string_lossy().to_string(),
        method: state.method,
    })
}

#[tauri::command]
pub fn set_current_version(app: AppHandle, tag: String) -> Result<CurrentVersionInfo, String> {
    activate(&app, &tag)
}

#[tauri::command]
pub fn clear_current_version(app: AppHandle) -> Result<(), String> {
    clear(&app)
}

#[cfg(test)]
#[path = "../tests/common/current_version.rs"]
mod current_version_common_tests;
