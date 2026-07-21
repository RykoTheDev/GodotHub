use crate::godot_versions;
use crate::models::*;
use crate::projects;
use std::fs;
use std::path::{Path, PathBuf};
use tauri::AppHandle;
use tauri::Emitter;

const SKIP_DIRS: [&str; 5] = [".git", ".import", ".godot", "Addons", "addons"];

fn walk<F: FnMut(&Path)>(dir: &Path, depth: usize, max_depth: usize, visit: &mut F) {
    if depth > max_depth {
        return;
    }
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();
        if path.is_dir() {
            if SKIP_DIRS.contains(&name.as_str()) {
                continue;
            }
            visit(&path);
            walk(&path, depth + 1, max_depth, visit);
        } else {
            visit(&path);
        }
    }
}

#[tauri::command]
pub async fn scan_for_projects(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
) -> Result<Vec<Project>, String> {
    tokio::task::spawn_blocking(move || scan_for_projects_blocking(app, dirs, depth))
        .await
        .map_err(|e| e.to_string())?
}

pub fn scan_for_projects_blocking(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
) -> Result<Vec<Project>, String> {
    let existing = projects::list_projects(app.clone());
    let existing_paths: Vec<String> = existing.iter().map(|p| p.path.clone()).collect();
    let mut found_dirs: Vec<PathBuf> = vec![];
    let max_depth = depth as usize;

    for dir in &dirs {
        let root = PathBuf::from(dir);
        if !root.exists() {
            continue;
        }
        walk(&root, 0, max_depth, &mut |path| {
            if path.is_file()
                && path
                    .file_name()
                    .map(|n| n == "project.godot")
                    .unwrap_or(false)
            {
                if let Some(parent) = path.parent() {
                    found_dirs.push(parent.to_path_buf());
                }
            }
        });
    }

    let new_dirs: Vec<PathBuf> = found_dirs
        .into_iter()
        .filter(|d| !existing_paths.contains(&d.to_string_lossy().to_string()))
        .collect();
    let total = new_dirs.len();

    let _ = app.emit("project-scan-progress", (0usize, total));

    let mut added = vec![];
    for dir in new_dirs {
        let path_str = dir.to_string_lossy().to_string();
        if let Ok(p) = projects::register_project(app.clone(), path_str, String::new(), None) {
            added.push(p);
        }
        let _ = app.emit("project-scan-progress", (added.len(), total));
    }
    Ok(added)
}

fn looks_like_executable(path: &Path) -> bool {
    let name = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_lowercase();

    #[cfg(target_os = "macos")]
    {
        return path.is_dir() && name.ends_with(".app") && name.contains("godot");
    }

    #[cfg(target_os = "windows")]
    {
        path.is_file()
            && name.ends_with(".exe")
            && name.contains("godot")
            && !name.contains("console")
    }

    #[cfg(target_os = "linux")]
    {
        if !path.is_file() || !name.starts_with("godot") {
            return false;
        }
        use std::os::unix::fs::PermissionsExt;
        fs::metadata(path)
            .map(|m| m.permissions().mode() & 0o111 != 0)
            .unwrap_or(false)
    }
}

fn resolve_macos_bundle_exe(app_bundle: &Path) -> Option<PathBuf> {
    let macos_dir = app_bundle.join("Contents/MacOS");
    let entries = fs::read_dir(&macos_dir).ok()?;
    entries.flatten().map(|e| e.path()).find(|p| p.is_file())
}

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[cfg(target_os = "windows")]
const CREATE_NO_WINDOW: u32 = 0x08000000;

fn probe_version(exe: &Path) -> String {
    let mut cmd = std::process::Command::new(exe);
    cmd.arg("--version");
    #[cfg(target_os = "windows")]
    cmd.creation_flags(CREATE_NO_WINDOW);
    match cmd.output() {
        Ok(o) => {
            let out = String::from_utf8_lossy(&o.stdout).trim().to_string();
            if out.is_empty() {
                String::from_utf8_lossy(&o.stderr).trim().to_string()
            } else {
                out
            }
        }
        Err(_) => String::new(),
    }
}

fn normalize_tag(raw: &str) -> String {
    let parts: Vec<&str> = raw.trim().split('.').filter(|p| !p.is_empty()).collect();
    let mut numeric = vec![];
    let mut i = 0;
    while i < parts.len() && !parts[i].is_empty() && parts[i].chars().all(|c| c.is_ascii_digit()) {
        numeric.push(parts[i]);
        i += 1;
    }
    if numeric.is_empty() {
        return raw.trim().to_string();
    }
    let channel = parts.get(i).copied().unwrap_or("stable");
    format!("{}-{}", numeric.join("."), channel)
}

#[tauri::command]
pub async fn scan_for_versions(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
) -> Result<Vec<InstalledGodotVersion>, String> {
    tokio::task::spawn_blocking(move || scan_for_versions_blocking(app, dirs, depth))
        .await
        .map_err(|e| e.to_string())?
}

pub fn scan_for_versions_blocking(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
) -> Result<Vec<InstalledGodotVersion>, String> {
    let existing = godot_versions::read_registry(&app);
    let existing_paths: Vec<String> = existing.iter().map(|v| v.executable_path.clone()).collect();
    let mut candidates: Vec<PathBuf> = vec![];
    let max_depth = depth as usize;

    for dir in &dirs {
        let root = PathBuf::from(dir);
        if !root.exists() {
            continue;
        }
        walk(&root, 0, max_depth, &mut |path| {
            if looks_like_executable(path) {
                candidates.push(path.to_path_buf());
            }
        });
    }

    let total = candidates.len();
    let _ = app.emit("version-scan-progress", (0usize, total));

    let mut added = vec![];
    for (i, candidate) in candidates.into_iter().enumerate() {
        let exe_path = if candidate.is_dir() {
            match resolve_macos_bundle_exe(&candidate) {
                Some(p) => p,
                None => {
                    let _ = app.emit("version-scan-progress", (i + 1, total));
                    continue;
                }
            }
        } else {
            candidate
        };
        let exe_str = exe_path.to_string_lossy().to_string();
        if existing_paths.contains(&exe_str) {
            let _ = app.emit("version-scan-progress", (i + 1, total));
            continue;
        }

        let raw_version = probe_version(&exe_path);
        let tag = if raw_version.is_empty() {
            exe_path
                .file_stem()
                .map(|s| s.to_string_lossy().to_string())
                .unwrap_or_else(|| "unknown".into())
        } else {
            normalize_tag(&raw_version)
        };
        let is_mono = exe_str.to_lowercase().contains("mono");

        if existing
            .iter()
            .any(|v| v.tag == tag && v.is_mono == is_mono)
        {
            let _ = app.emit("version-scan-progress", (i + 1, total));
            continue;
        }

        let installed = InstalledGodotVersion {
            tag,
            version: raw_version,
            executable_path: exe_str,
            is_mono,
            installed_at: chrono::Utc::now().to_rfc3339(),
            custom_name: None,
            install_root: None,
        };

        if godot_versions::register_version(&app, installed.clone())? {
            projects::rebind_projects_to_version(&app, &installed);
            added.push(installed);
        }
        let _ = app.emit("version-scan-progress", (i + 1, total));
    }
    Ok(added)
}

#[tauri::command]
pub async fn import_version(
    app: AppHandle,
    path: String,
) -> Result<Vec<InstalledGodotVersion>, String> {
    tokio::task::spawn_blocking(move || import_version_blocking(app, path))
        .await
        .map_err(|e| e.to_string())?
}

fn import_version_blocking(
    app: AppHandle,
    path: String,
) -> Result<Vec<InstalledGodotVersion>, String> {
    let root = PathBuf::from(&path);
    if !root.exists() {
        return Err("That folder doesn't exist.".into());
    }

    let mut existing = godot_versions::read_registry(&app);

    let mut candidates: Vec<PathBuf> = vec![];
    if looks_like_executable(&root) {
        candidates.push(root.clone());
    } else {
        walk(&root, 0, 4, &mut |p| {
            if looks_like_executable(p) {
                candidates.push(p.to_path_buf());
            }
        });
    }

    if candidates.is_empty() {
        return Err("Couldn't find a Godot executable in that folder.".into());
    }

    let total = candidates.len();
    let _ = app.emit("version-scan-progress", (0usize, total));

    let mut imported = vec![];
    let mut last_err: Option<String> = None;

    for (i, found) in candidates.into_iter().enumerate() {
        let exe_path = if found.is_dir() {
            match resolve_macos_bundle_exe(&found) {
                Some(p) => p,
                None => {
                    let _ = app.emit("version-scan-progress", (i + 1, total));
                    continue;
                }
            }
        } else {
            found
        };
        let exe_str = exe_path.to_string_lossy().to_string();
        if existing.iter().any(|v| v.executable_path == exe_str) {
            let _ = app.emit("version-scan-progress", (i + 1, total));
            continue;
        }

        let raw_version = probe_version(&exe_path);
        let tag = if raw_version.is_empty() {
            exe_path
                .file_stem()
                .map(|s| s.to_string_lossy().to_string())
                .unwrap_or_else(|| "unknown".into())
        } else {
            normalize_tag(&raw_version)
        };
        let is_mono = exe_str.to_lowercase().contains("mono");

        if existing
            .iter()
            .any(|v| v.tag == tag && v.is_mono == is_mono)
        {
            let _ = app.emit("version-scan-progress", (i + 1, total));
            continue;
        }

        let installed = InstalledGodotVersion {
            tag,
            version: raw_version,
            executable_path: exe_str,
            is_mono,
            installed_at: chrono::Utc::now().to_rfc3339(),
            custom_name: None,
            install_root: None,
        };

        match godot_versions::register_version(&app, installed.clone()) {
            Ok(_) => {
                existing.push(installed.clone());
                projects::rebind_projects_to_version(&app, &installed);
                imported.push(installed);
            }
            Err(e) => last_err = Some(e),
        }
        let _ = app.emit("version-scan-progress", (i + 1, total));
    }

    if imported.is_empty() {
        return Err(last_err.unwrap_or_else(|| "This version is already imported.".into()));
    }
    Ok(imported)
}
