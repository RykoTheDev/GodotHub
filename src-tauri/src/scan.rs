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

fn collect_matching_paths<F>(dirs: &[String], max_depth: usize, mut matcher: F) -> Vec<PathBuf>
where
    F: FnMut(&Path) -> bool,
{
    let mut results = Vec::new();
    for dir in dirs {
        let root = PathBuf::from(dir);
        if !root.exists() {
            continue;
        }
        walk(&root, 0, max_depth, &mut |path| {
            if matcher(path) {
                results.push(path.to_path_buf());
            }
        });
    }
    results
}
fn register_version_candidate(
    app: &AppHandle,
    candidate: PathBuf,
    existing: &mut Vec<InstalledGodotVersion>,
    existing_paths: &[String],
) -> Result<Option<InstalledGodotVersion>, String> {
    let exe_path = if candidate.is_dir() {
        match resolve_macos_bundle_exe(&candidate) {
            Some(p) => p,
            None => return Ok(None),
        }
    } else {
        candidate
    };

    let exe_str = exe_path.to_string_lossy().to_string();

    if existing_paths.contains(&exe_str) {
        return Ok(None);
    }

    let raw_version = probe_version(&exe_path);

    let base_tag = if raw_version.is_empty() {
        let fname = exe_path
            .file_name()
            .and_then(|s| s.to_str())
            .unwrap_or("");
        godot_versions::parse_godot_tag_from_filename(fname)
            .or_else(|| {
                exe_path
                    .file_stem()
                    .map(|s| s.to_string_lossy().to_string())
            })
            .unwrap_or_else(|| "unknown".into())
    } else {
        normalize_tag(&raw_version)
    };

    let is_mono = exe_str.to_lowercase().contains("mono");
    let tag = if is_mono && !base_tag.ends_with("-mono") {
        format!("{}-mono", base_tag)
    } else {
        base_tag
    };

    if existing.iter().any(|v| v.tag == tag && v.is_mono == is_mono) {
        return Ok(None);
    }

    let version = if raw_version.is_empty() {
        let v = tag.trim_end_matches("-mono");
        v.split('-').next().unwrap_or(v).trim_start_matches('v').to_string()
    } else {
        raw_version
    };

    let installed = InstalledGodotVersion {
        tag,
        version,
        executable_path: exe_str,
        is_mono,
        installed_at: chrono::Utc::now().to_rfc3339(),
        custom_name: None,
        install_root: None,
        supports_console: false,
    };

    match godot_versions::register_version(app, installed.clone()) {
        Ok(true) => {
            existing.push(installed.clone());
            projects::rebind_projects_to_version(app, &installed);
            Ok(Some(installed))
        }
        Ok(false) => Ok(None),
        Err(e) => Err(e),
    }
}

#[tauri::command]
pub async fn scan_for_projects(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
) -> Result<Vec<Project>, String> {
    tokio::task::spawn_blocking(move || {
        let result = scan_for_projects_blocking(app.clone(), dirs, depth, false)?;
        Ok(result.added)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn scan_for_projects_with_info(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
) -> Result<ScanProjectsResult, String> {
    tokio::task::spawn_blocking(move || scan_for_projects_blocking(app, dirs, depth, true))
        .await
        .map_err(|e| e.to_string())?
}

pub fn scan_for_projects_blocking(
    app: AppHandle,
    dirs: Vec<String>,
    depth: u32,
    include_dismissed: bool,
) -> Result<ScanProjectsResult, String> {
    let existing = projects::list_projects(app.clone());
    let existing_paths: Vec<String> = existing.iter().map(|p| p.path.clone()).collect();
    let max_depth = depth as usize;

    let dismissed = crate::settings::read_settings(&app).dismissed_project_paths;

    let found_dirs = collect_matching_paths(&dirs, max_depth, |path| {
        path.is_file()
            && path.file_name().map(|n| n == "project.godot").unwrap_or(false)
    });

    let mut found_dismissed: Vec<String> = vec![];

    let new_dirs: Vec<PathBuf> = found_dirs
        .into_iter()
        .filter(|d| {
            let parent_path = d.parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_default();
            if projects::contains_path(&existing_paths, &parent_path) {
                return false;
            }
            if projects::contains_path(&dismissed, &parent_path) {
                if include_dismissed {
                    found_dismissed.push(parent_path);
                }
                return false;
            }
            true
        })
        .collect();

    let project_dirs: Vec<PathBuf> = new_dirs
        .into_iter()
        .filter_map(|p| p.parent().map(|pp| pp.to_path_buf()))
        .collect();

    let total = project_dirs.len();
    let _ = app.emit("project-scan-progress", (0usize, total));

    let mut added = vec![];
    for dir in project_dirs {
        let path_str = dir.to_string_lossy().to_string();
        if let Ok(p) = projects::register_project(app.clone(), path_str, String::new(), None) {
            added.push(p);
        }
        let _ = app.emit("project-scan-progress", (added.len(), total));
    }
    let _ = app.emit("watcher:project-scan-done", ());
    Ok(ScanProjectsResult { added, found_dismissed })
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
use crate::terminal::CREATE_NO_WINDOW;

fn extract_version_line(raw: &str) -> Option<&str> {
    fn numeric(part: Option<&str>) -> bool {
        part.is_some_and(|p| !p.is_empty() && p.chars().all(|c| c.is_ascii_digit()))
    }
    raw.lines().map(str::trim).find(|line| {
        let mut parts = line.split('.');
        numeric(parts.next()) && numeric(parts.next())
    })
}

fn probe_version(exe: &Path) -> String {
    let mut cmd = std::process::Command::new(exe);
    cmd.arg("--version");
    #[cfg(target_os = "windows")]
    cmd.creation_flags(CREATE_NO_WINDOW);
    match cmd.output() {
        Ok(o) => {
            let stdout = String::from_utf8_lossy(&o.stdout);
            let stderr = String::from_utf8_lossy(&o.stderr);
            extract_version_line(&stdout)
                .or_else(|| extract_version_line(&stderr))
                .unwrap_or_default()
                .to_string()
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
    let mut existing = godot_versions::read_registry(&app);
    let existing_paths: Vec<String> = existing.iter().map(|v| v.executable_path.clone()).collect();
    let max_depth = depth as usize;

    let candidates = collect_matching_paths(&dirs, max_depth, looks_like_executable);

    let total = candidates.len();
    let _ = app.emit("version-scan-progress", (0usize, total));

    let mut added = vec![];
    for (i, candidate) in candidates.into_iter().enumerate() {
        match register_version_candidate(&app, candidate, &mut existing, &existing_paths) {
            Ok(Some(v)) => added.push(v),
            Ok(None) => {}
            Err(e) => eprintln!("Error registering version: {e}"),
        }
        let _ = app.emit("version-scan-progress", (i + 1, total));
    }
    let _ = app.emit("watcher:version-scan-done", ());
    if !added.is_empty() {
        let _ = app.emit("watcher:project-scan-done", ());
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
    let existing_paths: Vec<String> = existing.iter().map(|v| v.executable_path.clone()).collect();

    let mut candidates: Vec<PathBuf> = vec![];
    if looks_like_executable(&root) {
        candidates.push(root.clone());
    } else {
        candidates = collect_matching_paths(
            &[path],
            4,
            looks_like_executable,
        );
    }

    if candidates.is_empty() {
        return Err("Couldn't find a Godot executable in that folder.".into());
    }

    let total = candidates.len();
    let _ = app.emit("version-scan-progress", (0usize, total));

    let mut imported = vec![];
    let mut last_err: Option<String> = None;

    for (i, candidate) in candidates.into_iter().enumerate() {
        match register_version_candidate(&app, candidate, &mut existing, &existing_paths) {
            Ok(Some(v)) => imported.push(v),
            Ok(None) => {}
            Err(e) => last_err = Some(e),
        }
        let _ = app.emit("version-scan-progress", (i + 1, total));
    }

    if imported.is_empty() {
        return Err(last_err.unwrap_or_else(|| "This version is already imported.".into()));
    }
    let _ = app.emit("watcher:version-scan-done", ());
    let _ = app.emit("watcher:project-scan-done", ());
    Ok(imported)
}
