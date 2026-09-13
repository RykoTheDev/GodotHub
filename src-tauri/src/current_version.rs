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

/// A named command (for example `godot-mono`) bound to one installed version.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct VersionAlias {
    pub name: String,
    pub tag: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct AliasInfo {
    pub name: String,
    pub tag: String,
    pub alias_path: String,
    pub aliases_dir: String,
    /// How the alias was created: `symlink`, `hardlink` or `shim`.
    pub method: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct VersionAliases {
    pub aliases: Vec<AliasInfo>,
    pub aliases_dir: String,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct AliasesState {
    #[serde(default)]
    aliases: Vec<VersionAlias>,
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

/// The pinned alias name. Named aliases may not use it, so they can never
/// shadow the "current version" command.
const PIN_ALIAS_NAME: &str = "Godot";

const RESERVED_NAMES: [&str; 22] = [
    "con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5", "com6", "com7",
    "com8", "com9", "lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9",
];

/// The filename a named alias is primarily created under.
#[cfg(target_os = "windows")]
pub fn alias_file_name_for(name: &str) -> String {
    format!("{name}.exe")
}

#[cfg(not(target_os = "windows"))]
pub fn alias_file_name_for(name: &str) -> String {
    name.to_string()
}

/// Every filename a named alias may have been created under, so removing it
/// never leaves a stale launcher behind.
pub fn alias_candidates_for(name: &str) -> Vec<String> {
    let mut names = vec![alias_file_name_for(name)];
    for candidate in [format!("{name}.cmd"), name.to_string()] {
        if !names.contains(&candidate) {
            names.push(candidate);
        }
    }
    names
}

/// Rejects names that would break out of the aliases folder, collide with the
/// pinned alias, or be unusable as a command on Windows.
pub fn validate_alias_name(name: &str) -> Result<String, String> {
    let trimmed = name.trim();
    if trimmed.is_empty() {
        return Err("Alias name can't be empty".into());
    }
    if trimmed.len() > 64 {
        return Err("Alias name is too long (64 characters max)".into());
    }
    if trimmed.chars().any(|c| {
        c.is_control() || matches!(c, '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|')
    }) {
        return Err("Alias name can't contain path or reserved characters".into());
    }
    if trimmed == "." || trimmed == ".." {
        return Err("Alias name can't be a dot path".into());
    }
    if trimmed.ends_with('.') || trimmed.ends_with(' ') {
        return Err("Alias name can't end with a dot or space".into());
    }

    let lower = trimmed.to_lowercase();
    if lower == PIN_ALIAS_NAME.to_lowercase() {
        return Err("\"Godot\" is reserved for the current version pin".into());
    }
    if lower.ends_with(".exe") || lower.ends_with(".cmd") {
        return Err("Alias name can't end with .exe or .cmd".into());
    }
    let stem = lower.split('.').next().unwrap_or_default();
    if RESERVED_NAMES.contains(&stem) {
        return Err("Alias name is reserved by the operating system".into());
    }
    Ok(trimmed.to_string())
}

fn alias_state_file(app: &AppHandle) -> PathBuf {
    app.path()
        .app_data_dir()
        .expect("no app data dir")
        .join("aliases.json")
}

fn read_aliases(app: &AppHandle) -> AliasesState {
    crate::persist::read_json_opt_with_backup(&alias_state_file(app)).unwrap_or_default()
}

fn write_aliases(app: &AppHandle, state: &AliasesState) -> Result<(), String> {
    crate::persist::write_json_with_backup(&alias_state_file(app), state)
        .map_err(|e| e.to_string())
}

fn remove_alias_files(dir: &Path, name: &str) {
    for candidate in alias_candidates_for(name) {
        let path = dir.join(candidate);
        if fs::symlink_metadata(&path).is_ok() {
            let _ = fs::remove_file(&path);
        }
    }
}

fn existing_alias_path(dir: &Path, name: &str) -> Option<PathBuf> {
    alias_candidates_for(name)
        .into_iter()
        .map(|candidate| dir.join(candidate))
        .find(|path| fs::symlink_metadata(path).is_ok())
}

fn detect_method(path: &Path) -> String {
    if path
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("cmd"))
    {
        return "shim".to_string();
    }
    match fs::symlink_metadata(path) {
        Ok(meta) if meta.file_type().is_symlink() => "symlink".to_string(),
        Ok(_) => "hardlink".to_string(),
        Err(_) => "symlink".to_string(),
    }
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

pub fn create_named_alias(app: &AppHandle, name: &str, tag: &str) -> Result<AliasInfo, String> {
    let name = validate_alias_name(name)?;
    let list = crate::godot_versions::read_registry(app);
    let version = list
        .iter()
        .find(|v| v.tag == tag)
        .ok_or("Version not found")?;
    let target = PathBuf::from(&version.executable_path);
    if !target.is_file() {
        return Err("Executable no longer exists at that path".into());
    }

    let mut state = read_aliases(app);
    if state
        .aliases
        .iter()
        .any(|a| a.name.eq_ignore_ascii_case(&name))
    {
        return Err("An alias with this name already exists".into());
    }

    let dir = aliases_dir(app);
    remove_alias_files(&dir, &name);
    let (method, alias_path) = create_alias(&target, &dir.join(alias_file_name_for(&name)))?;
    state.aliases.push(VersionAlias {
        name: name.clone(),
        tag: tag.to_string(),
    });
    write_aliases(app, &state)?;

    Ok(AliasInfo {
        name,
        tag: tag.to_string(),
        alias_path: alias_path.to_string_lossy().to_string(),
        aliases_dir: dir.to_string_lossy().to_string(),
        method: method.to_string(),
    })
}

/// Every named alias. An alias whose version is gone, or whose launcher was
/// deleted from the aliases folder, is dropped from the saved list as well, so
/// the folder and the app always agree.
pub fn list_named_aliases(app: &AppHandle) -> VersionAliases {
    let dir = aliases_dir(app);
    let list = crate::godot_versions::read_registry(app);
    let mut state = read_aliases(app);
    let mut aliases = Vec::new();
    let mut changed = false;

    for alias in &state.aliases {
        let Some(version) = list.iter().find(|v| v.tag == alias.tag) else {
            changed = true;
            continue;
        };
        let target = PathBuf::from(&version.executable_path);
        if !target.is_file() {
            changed = true;
            continue;
        }

        // The aliases folder is the source of truth: if the launcher file was
        // deleted by hand, forget the alias rather than recreating it.
        let Some(path) = existing_alias_path(&dir, &alias.name) else {
            changed = true;
            continue;
        };
        let method = detect_method(&path);

        aliases.push(AliasInfo {
            name: alias.name.clone(),
            tag: alias.tag.clone(),
            alias_path: path.to_string_lossy().to_string(),
            aliases_dir: dir.to_string_lossy().to_string(),
            method,
        });
    }

    if changed {
        state
            .aliases
            .retain(|alias| aliases.iter().any(|a| a.name == alias.name));
        let _ = write_aliases(app, &state);
    }

    VersionAliases {
        aliases,
        aliases_dir: dir.to_string_lossy().to_string(),
    }
}

pub fn delete_named_alias(app: &AppHandle, name: &str) -> Result<(), String> {
    let trimmed = name.trim();
    let mut state = read_aliases(app);
    let before = state.aliases.len();
    state
        .aliases
        .retain(|alias| !alias.name.eq_ignore_ascii_case(trimmed));
    if state.aliases.len() == before {
        return Err("Alias not found".into());
    }
    remove_alias_files(&aliases_dir(app), trimmed);
    write_aliases(app, &state)
}

/// Drops every named alias pointing at a version that was uninstalled.
pub fn remove_aliases_for_tag(app: &AppHandle, tag: &str) {
    let mut state = read_aliases(app);
    let doomed: Vec<String> = state
        .aliases
        .iter()
        .filter(|alias| alias.tag == tag)
        .map(|alias| alias.name.clone())
        .collect();
    if doomed.is_empty() {
        return;
    }
    state.aliases.retain(|alias| alias.tag != tag);
    let dir = aliases_dir(app);
    for name in doomed {
        remove_alias_files(&dir, &name);
    }
    let _ = write_aliases(app, &state);
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

#[tauri::command]
pub fn list_version_aliases(app: AppHandle) -> VersionAliases {
    list_named_aliases(&app)
}

#[tauri::command]
pub fn create_version_alias(app: AppHandle, name: String, tag: String) -> Result<AliasInfo, String> {
    create_named_alias(&app, &name, &tag)
}

#[tauri::command]
pub fn delete_version_alias(app: AppHandle, name: String) -> Result<(), String> {
    delete_named_alias(&app, &name)
}

#[cfg(test)]
#[path = "../tests/common/current_version.rs"]
mod current_version_common_tests;
