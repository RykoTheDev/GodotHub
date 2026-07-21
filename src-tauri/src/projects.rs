use crate::models::*;
use crate::settings;
use serde::Serialize;
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Child, Command};
use tauri::{AppHandle, Emitter, Manager};
use uuid::Uuid;

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::SystemTime;

pub struct ActiveProcesses(pub Mutex<HashMap<String, Child>>);

const DEFAULT_ICON_SVG: &[u8] = include_bytes!("../icon.svg");

struct CachedIcon {
    project_godot_mtime: Option<SystemTime>,
    data: Option<String>,
}

fn icon_cache() -> &'static Mutex<HashMap<String, CachedIcon>> {
    static CACHE: OnceLock<Mutex<HashMap<String, CachedIcon>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

fn projects_file(app: &AppHandle) -> PathBuf {
    crate::workspace::active_workspace_dir(app).join("projects.json")
}

pub(crate) fn read_projects(app: &AppHandle) -> Vec<Project> {
    let file = projects_file(app);
    if !file.exists() {
        return vec![];
    }
    serde_json::from_str(&fs::read_to_string(&file).unwrap_or_default()).unwrap_or_default()
}

pub(crate) fn write_projects(app: &AppHandle, projects: &Vec<Project>) -> Result<(), String> {
    fs::write(
        projects_file(app),
        serde_json::to_string_pretty(projects).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

fn next_sort_order(projects: &[Project], category: &Option<String>) -> i64 {
    projects
        .iter()
        .filter(|p| !p.pinned && &p.category == category)
        .map(|p| p.sort_order)
        .max()
        .map(|m| m + 1)
        .unwrap_or(0)
}

#[tauri::command]
pub fn list_projects(app: AppHandle) -> Vec<Project> {
    let projects = read_projects(&app);
    let (kept, removed): (Vec<Project>, Vec<Project>) = projects
        .into_iter()
        .partition(|p| Path::new(&p.path).join("project.godot").exists());
    if !removed.is_empty() {
        let _ = write_projects(&app, &kept);
    }
    kept
}

#[tauri::command]
pub fn create_project(
    app: AppHandle,
    name: String,
    location: String,
    godot_version: String,
    icon_path: Option<String>,
    template_id: Option<String>,
    category: Option<String>,
) -> Result<Project, String> {
    let project_dir = PathBuf::from(&location).join(&name);
    if project_dir.exists() {
        return Err("A folder with this name already exists at this location".into());
    }

    if let Some(ref tid) = template_id {
        let templates_root = app
            .path()
            .app_data_dir()
            .expect("no app data dir")
            .join("templates")
            .join(tid);
        if !templates_root.exists() {
            return Err("Template not found".into());
        }
        crate::templates::copy_dir(&templates_root, &project_dir, &[])?;
        let _ = fs::remove_file(project_dir.join("template.json"));
    } else {
        fs::create_dir_all(&project_dir).map_err(|e| e.to_string())?;
    }

    let mut project_godot = format!(
        "; Engine configuration file.\n\n[application]\n\nconfig/name=\"{}\"\nconfig/icon=\"res://icon.svg\"\nconfig/features=PackedStringArray(\"4.3\")\n",
        name
    );

    if let Some(icon) = &icon_path {
        let src = PathBuf::from(icon);
        if src.is_file() {
            let ext = src.extension().and_then(|e| e.to_str()).unwrap_or("svg");
            let icon_name = format!("icon.{ext}");
            let dest = project_dir.join(&icon_name);
            fs::copy(&src, dest).map_err(|e| e.to_string())?;
            if ext != "svg" {
                project_godot = project_godot.replace("res://icon.svg", &format!("res://icon.{ext}"));
            }
        }
    } else if template_id.is_none() {
        fs::write(project_dir.join("icon.svg"), DEFAULT_ICON_SVG).map_err(|e| e.to_string())?;
    }

    if project_dir.join("project.godot").exists() {
        let existing = fs::read_to_string(project_dir.join("project.godot")).unwrap_or_default();
        let mut lines: Vec<String> = existing.lines()
            .map(|l| {
                let trimmed = l.trim();
                if trimmed.starts_with("config/name=") {
                    format!("config/name=\"{}\"", name)
                } else {
                    l.to_string()
                }
            })
            .collect();

        if !lines.iter().any(|l| l.trim().starts_with("config/name=")) {
            if let Some(idx) = lines.iter().position(|l| l.trim() == "[application]") {
                lines.insert(idx + 1, format!("config/name=\"{}\"", name));
            } else {
                lines.push(String::new());
                lines.push("[application]".to_string());
                lines.push(format!("config/name=\"{}\"", name));
            }
        }

        fs::write(project_dir.join("project.godot"), lines.join("\n")).map_err(|e| e.to_string())?;
    } else {
        fs::write(project_dir.join("project.godot"), &project_godot).map_err(|e| e.to_string())?;
        let _ = fs::create_dir(project_dir.join(".godot"));
    }

    let mut projects = read_projects(&app);
    let effective_category = category.as_ref().and_then(|c| if c.trim().is_empty() { None } else { Some(c.clone()) });
    let project = Project {
        id: Uuid::new_v4().to_string(),
        name,
        path: project_dir.to_string_lossy().to_string(),
        godot_version,
        created_at: chrono::Utc::now().to_rfc3339(),
        last_opened: None,
        category: effective_category.clone(),
        pinned: false,
        sort_order: next_sort_order(&projects, &effective_category),
        launch_arguments: String::new(),
    };

    projects.push(project.clone());
    write_projects(&app, &projects)?;
    Ok(project)
}

fn detect_required_version(path: &str) -> Option<String> {
    let content = fs::read_to_string(PathBuf::from(path).join("project.godot")).ok()?;
    for line in content.lines() {
        if let Some(rest) = line.trim().strip_prefix("config/features=") {
            let start = rest.find('"')? + 1;
            let end = start + rest[start..].find('"')?;
            return Some(rest[start..end].to_string());
        }
    }
    None
}

fn version_matches(required: &str, v: &InstalledGodotVersion) -> bool {
    let req = required.trim_start_matches('v');
    v.tag.trim_start_matches('v').starts_with(req)
        || v.version.trim_start_matches('v').starts_with(req)
}

pub fn rebind_projects_to_version(app: &AppHandle, version: &InstalledGodotVersion) {
    let mut projects = read_projects(app);
    let mut changed = false;
    for p in projects.iter_mut() {
        if !p.godot_version.is_empty() {
            continue;
        }
        if let Some(required) = detect_required_version(&p.path) {
            if version_matches(&required, version) {
                p.godot_version = version.tag.clone();
                changed = true;
            }
        }
    }
    if changed {
        let _ = write_projects(app, &projects);
    }
}

pub fn register_project(
    app: AppHandle,
    path: String,
    godot_version: String,
    category: Option<String>,
) -> Result<Project, String> {
    if !PathBuf::from(&path).join("project.godot").exists() {
        return Err("No project.godot found in the selected folder".into());
    }
    let name = PathBuf::from(&path)
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "Untitled".into());

    let mut projects = read_projects(&app);
    if projects.iter().any(|p| p.path == path) {
        return Err("This project is already in your library".into());
    }
    let mut godot_version = godot_version;
    if godot_version.is_empty() {
        if let Some(required) = detect_required_version(&path) {
            let installed = crate::godot_versions::read_registry(&app);
            if let Some(v) = installed.iter().find(|v| version_matches(&required, v)) {
                godot_version = v.tag.clone();
            }
        }
    }
    let project = Project {
        id: Uuid::new_v4().to_string(),
        name,
        path,
        godot_version,
        created_at: chrono::Utc::now().to_rfc3339(),
        last_opened: None,
        sort_order: next_sort_order(&projects, &category),
        category,
        pinned: false,
        launch_arguments: String::new(),
    };
    projects.push(project.clone());
    write_projects(&app, &projects)?;
    Ok(project)
}

#[tauri::command]
pub fn import_project(
    app: AppHandle,
    path: String,
    godot_version: String,
) -> Result<Project, String> {
    register_project(app, path, godot_version, None)
}

#[tauri::command]
pub fn remove_project(app: AppHandle, id: String, delete_files: bool) -> Result<(), String> {
    let mut projects = read_projects(&app);
    let idx = projects
        .iter()
        .position(|p| p.id == id)
        .ok_or("Project not found")?;
    let project = projects.remove(idx);
    if delete_files {
        let _ = fs::remove_dir_all(&project.path);
    }
    write_projects(&app, &projects)
}

#[tauri::command]
pub fn update_project(
    app: AppHandle,
    id: String,
    updates: ProjectUpdate,
) -> Result<Project, String> {
    let mut projects = read_projects(&app);
    let project = projects
        .iter_mut()
        .find(|p| p.id == id)
        .ok_or("Project not found")?;
    if let Some(name) = updates.name {
        project.name = name;
    }
    if let Some(v) = updates.godot_version {
        project.godot_version = v;
    }
    if let Some(category) = updates.category {
        project.category = if category.trim().is_empty() {
            None
        } else {
            Some(category)
        };
    }
    if let Some(pinned) = updates.pinned {
        project.pinned = pinned;
    }
    if let Some(launch_arguments) = updates.launch_arguments {
        project.launch_arguments = launch_arguments;
    }
    let updated = project.clone();
    write_projects(&app, &projects)?;
    Ok(updated)
}

#[tauri::command]
pub fn reorder_projects(app: AppHandle, ordered_ids: Vec<String>) -> Result<(), String> {
    let mut projects = read_projects(&app);
    for (i, id) in ordered_ids.iter().enumerate() {
        if let Some(p) = projects.iter_mut().find(|p| &p.id == id) {
            p.sort_order = i as i64;
        }
    }
    write_projects(&app, &projects)
}

#[tauri::command]
pub fn open_project(app: AppHandle, id: String, editor: bool) -> Result<(), String> {
    let mut projects = read_projects(&app);
    let project = projects
        .iter_mut()
        .find(|p| p.id == id)
        .ok_or("Project not found")?;
    let project_name = project.name.clone();
    let project_version = project.godot_version.clone();

    if project.godot_version.is_empty() {
        return Err("No Godot version bound to this project".into());
    }

    let versions = crate::godot_versions::list_installed_godot_versions(app.clone())?;
    let version = versions
        .iter()
        .find(|v| v.tag == project.godot_version)
        .ok_or("Bound Godot version is not installed")?;

    let mut cmd = Command::new(&version.executable_path);
    cmd.arg("--path").arg(&project.path);
    if editor {
        cmd.arg("-e");
    }
    if !project.launch_arguments.is_empty() {
        for arg in project.launch_arguments.split_whitespace() {
            cmd.arg(arg);
        }
    }

    let child = cmd.spawn().map_err(|e| e.to_string())?;

    project.last_opened = Some(chrono::Utc::now().to_rfc3339());
    write_projects(&app, &projects)?;

    if let Some(state) = app.try_state::<ActiveProcesses>() {
        state.0.lock().unwrap().insert(id.clone(), child);
    }

    let _ = app.emit(
        "project:launched",
        serde_json::json!({
            "id": id.clone(),
            "name": project_name,
            "version": project_version,
        }),
    );

    let settings = crate::settings::read_settings(&app);
    if settings.close_on_project_open {
        if settings.minimize_to_tray {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.hide();
            }

            if settings.reopen_after_godot_closes {
                let app_handle = app.clone();
                let pid = id.clone();
                std::thread::spawn(move || {
                    if let Some(state) = app_handle.try_state::<ActiveProcesses>() {
                        if let Some(mut child) = state.0.lock().unwrap().remove(&pid) {
                            let _ = child.wait();
                        }
                    }
                    if let Some(window) = app_handle.get_webview_window("main") {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                });
            }
        } else {
            app.exit(0);
        }
    }

    let app_clone = app.clone();
    let pid = id.clone();
    std::thread::spawn(move || {
        std::thread::sleep(std::time::Duration::from_secs(2));
        if let Some(state) = app_clone.try_state::<ActiveProcesses>() {
            if let Some(mut child) = state.0.lock().unwrap().remove(&pid) {
                let _ = child.wait();
                let _ = app_clone.emit(
                    "project:exited",
                    serde_json::json!({
                        "id": pid,
                    }),
                );
            }
        }
    });

    Ok(())
}

#[tauri::command]
pub fn stop_project(app: AppHandle, id: String) -> Result<(), String> {
    if let Some(state) = app.try_state::<ActiveProcesses>() {
        if let Some(mut child) = state.0.lock().unwrap().remove(&id) {
            child.kill().map_err(|e| format!("Failed to kill process: {e}"))?;
            child.wait().ok();
            let _ = app.emit(
                "project:exited",
                serde_json::json!({
                    "id": id,
                }),
            );
            return Ok(());
        }
    }
    Err("No running process found for this project".into())
}

#[tauri::command]
pub fn open_project_folder(path: String) -> Result<(), String> {
    let dir = PathBuf::from(&path);
    if !dir.exists() {
        return Err("This folder no longer exists".into());
    }

    #[cfg(target_os = "windows")]
    let result = std::process::Command::new("explorer").arg(&dir).spawn();

    #[cfg(target_os = "macos")]
    let result = std::process::Command::new("open").arg(&dir).spawn();

    #[cfg(all(unix, not(target_os = "macos")))]
    let result = std::process::Command::new("xdg-open").arg(&dir).spawn();

    result.map(|_| ()).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn open_in_editor(app: AppHandle, path: String) -> Result<(), String> {
    let dir = PathBuf::from(&path);
    if !dir.exists() {
        return Err("This folder no longer exists".into());
    }

    let settings = settings::read_settings(&app);
    if let Some(editor_path) = &settings.external_editor_path {
        if !editor_path.trim().is_empty() {
            let result = std::process::Command::new(editor_path.trim())
                .arg(&dir)
                .spawn();
            if let Ok(_) = result {
                return Ok(());
            }
        }
    }

    for editor in &["code", "rider", "idea", "code-insiders", "codium", "zed"] {
        if let Ok(_) = std::process::Command::new(editor).arg(&dir).spawn() {
            return Ok(());
        }
    }

    #[cfg(target_os = "windows")]
    {
        let username = std::env::var("USERNAME").unwrap_or_else(|_| "default".into());
        let common_paths = [
            format!("C:\\Users\\{username}\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe"),
            "C:\\Program Files\\Microsoft VS Code\\Code.exe".into(),
            "C:\\Program Files (x86)\\Microsoft VS Code\\Code.exe".into(),
        ];
        for exe_path in &common_paths {
            let p = std::path::Path::new(exe_path);
            if p.exists() {
                if let Ok(_) = std::process::Command::new(p).arg(&dir).spawn() {
                    return Ok(());
                }
            }
        }
    }

    Err("No supported IDE found. Install VS Code, Rider, or configure your editor path in Settings.".into())
}

#[tauri::command]
pub async fn pick_file(app: tauri::AppHandle) -> Option<String> {
    use tauri_plugin_dialog::DialogExt;
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .add_filter("Images", &["png", "svg", "jpg", "jpeg", "webp"])
        .pick_file(move |file| {
            let _ = tx.send(file);
        });
    rx.recv().ok().flatten().map(|p| p.to_string())
}

fn find_resource_by_uid(
    dir: &Path,
    target_uid: &str,
    depth: usize,
    budget: &mut usize,
) -> Option<PathBuf> {
    if depth > 14 || *budget == 0 {
        return None;
    }
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return None,
    };

    let mut subdirs: Vec<PathBuf> = Vec::new();
    for entry in entries.flatten() {
        if *budget == 0 {
            break;
        }
        *budget -= 1;
        let path = entry.path();
        if path.is_dir() {
            let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if name == ".git" || name == ".godot" || name == "node_modules" {
                continue;
            }
            subdirs.push(path);
        } else if path.extension().and_then(|e| e.to_str()) == Some("import") {
            if let Ok(content) = fs::read_to_string(&path) {
                let target_line = format!("uid=\"{}\"", target_uid);
                if content.lines().any(|l| l.trim() == target_line) {
                    let mut src = path.clone();
                    src.set_extension("");
                    return Some(src);
                }
            }
        }
    }

    for sub in subdirs {
        if let Some(found) = find_resource_by_uid(&sub, target_uid, depth + 1, budget) {
            return Some(found);
        }
    }
    None
}

fn resolve_project_icon(project_path: &str) -> Option<(Vec<u8>, &'static str)> {
    let dir = PathBuf::from(project_path);
    let godot_file = dir.join("project.godot");
    let mut icon_rel: Option<String> = None;
    let mut icon_uid: Option<String> = None;

    if let Ok(content) = fs::read_to_string(&godot_file) {
        for line in content.lines() {
            let line = line.trim();
            if let Some(rest) = line.strip_prefix("config/icon=") {
                let cleaned = rest.trim().trim_matches('"');
                if let Some(uid) = cleaned.strip_prefix("uid://") {
                    icon_uid = Some(format!("uid://{uid}"));
                } else {
                    icon_rel = Some(cleaned.trim_start_matches("res://").to_string());
                }
                break;
            }
        }
    }

    let mut candidates: Vec<String> = Vec::new();
    if let Some(p) = icon_rel {
        candidates.push(p);
    }
    if let Some(uid) = icon_uid {
        let mut budget = 8000usize;
        if let Some(found) = find_resource_by_uid(&dir, &uid, 0, &mut budget) {
            if let Ok(rel) = found.strip_prefix(&dir) {
                if let Some(rel_str) = rel.to_str() {
                    candidates.push(rel_str.to_string());
                }
            }
        }
    }

    for fallback in ["icon.svg", "icon.png"] {
        if !candidates.iter().any(|c| c == fallback) {
            candidates.push(fallback.to_string());
        }
    }

    for rel in candidates {
        let full = dir.join(&rel);
        if full.is_file() {
            if let Ok(bytes) = fs::read(&full) {
                let lower = rel.to_lowercase();
                let mime = if lower.ends_with(".svg") {
                    "image/svg+xml"
                } else if lower.ends_with(".png") {
                    "image/png"
                } else if lower.ends_with(".jpg") || lower.ends_with(".jpeg") {
                    "image/jpeg"
                } else {
                    continue;
                };
                return Some((bytes, mime));
            }
        }
    }
    None
}

pub(crate) fn resolve_project_name(project_path: &str) -> Option<String> {
    let godot_file = PathBuf::from(project_path).join("project.godot");
    let content = fs::read_to_string(&godot_file).ok()?;
    for line in content.lines() {
        let line = line.trim();
        if let Some(rest) = line.strip_prefix("config/name=") {
            let cleaned = rest.trim().trim_matches('"');
            if !cleaned.is_empty() {
                return Some(cleaned.to_string());
            }
            break;
        }
    }
    None
}

#[tauri::command]
pub fn get_project_name(path: String) -> Option<String> {
    resolve_project_name(&path)
}

#[tauri::command]
pub async fn validate_godot_folder(path: String) -> Option<GodotFolderPreview> {
    let godot_path = std::path::PathBuf::from(&path).join("project.godot");
    if !godot_path.exists() {
        return None;
    }
    let name = resolve_project_name(&path)?;
    let icon = get_project_icon(path).await;
    Some(GodotFolderPreview { name, icon })
}

#[tauri::command]
pub async fn get_project_icon(path: String) -> Option<String> {
    tokio::task::spawn_blocking(move || {
        let mtime = fs::metadata(PathBuf::from(&path).join("project.godot"))
            .and_then(|m| m.modified())
            .ok();

        if let Some(cached) = icon_cache().lock().unwrap().get(&path) {
            if cached.project_godot_mtime == mtime {
                return cached.data.clone();
            }
        }

        let (bytes, mime) = match resolve_project_icon(&path) {
            Some(v) => v,
            None => {
                icon_cache().lock().unwrap().insert(
                    path.clone(),
                    CachedIcon {
                        project_godot_mtime: mtime,
                        data: None,
                    },
                );
                return None;
            }
        };
        use base64::{engine::general_purpose, Engine as _};
        let encoded = general_purpose::STANDARD.encode(bytes);
        let data_url = format!("data:{};base64,{}", mime, encoded);

        icon_cache().lock().unwrap().insert(
            path.clone(),
            CachedIcon {
                project_godot_mtime: mtime,
                data: Some(data_url.clone()),
            },
        );
        Some(data_url)
    })
    .await
    .ok()
    .flatten()
}

#[derive(Clone, Serialize)]
pub struct FileSizeCategory {
    pub label: String,
    pub size: u64,
    pub count: usize,
}

#[derive(Clone, Serialize)]
pub struct ProjectSizeInfo {
    pub total_size: u64,
    pub categories: Vec<FileSizeCategory>,
    pub file_count: usize,
}

struct CachedSize {
    dir_mtime: Option<SystemTime>,
    data: Result<ProjectSizeInfo, String>,
}

fn size_cache() -> &'static Mutex<HashMap<String, CachedSize>> {
    static CACHE: OnceLock<Mutex<HashMap<String, CachedSize>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

fn classify_extension(ext: &str) -> Option<&'static str> {
    match ext.to_lowercase().as_str() {
        "gd" => Some("Scripts"),
        "cs" => Some("C# Scripts"),
        "tscn" => Some("Scenes"),
        "scn" => Some("Scenes"),
        "escn" => Some("Scenes"),
        "tres" => Some("Resources"),
        "res" => Some("Resources"),
        "theme" => Some("Themes"),
        "png" => Some("Images"),
        "svg" => Some("Images"),
        "jpg" | "jpeg" => Some("Images"),
        "webp" => Some("Images"),
        "bmp" => Some("Images"),
        "tga" => Some("Images"),
        "ktx" => Some("Images"),
        "ogg" | "oga" => Some("Audio"),
        "wav" => Some("Audio"),
        "mp3" => Some("Audio"),
        "flac" => Some("Audio"),
        "glb" | "gltf" => Some("3D Models"),
        "obj" => Some("3D Models"),
        "fbx" => Some("3D Models"),
        "dae" => Some("3D Models"),
        "gdshader" | "gdshaderinc" => Some("Shaders"),
        "godot" => Some("Engine Files"),
        "import" => Some("Imports"),
        _ => None,
    }
}

#[tauri::command]
pub async fn get_project_size(path: String) -> Result<ProjectSizeInfo, String> {
    tokio::task::spawn_blocking(move || -> Result<ProjectSizeInfo, String> {
        let dir = PathBuf::from(&path);
        if !dir.exists() {
            return Err("Project folder does not exist".into());
        }

        let dir_mtime = fs::metadata(&dir).and_then(|m| m.modified()).ok();

        if let Some(cached) = size_cache().lock().unwrap().get(&path) {
            if cached.dir_mtime == dir_mtime {
                return match &cached.data {
                    Ok(data) => Ok(data.clone()),
                    Err(e) => Err(e.clone()),
                };
            }
        }

        let mut total_size: u64 = 0;
        let mut total_count: usize = 0;
        let mut categories: BTreeMap<&'static str, (u64, usize)> = BTreeMap::new();
        let mut other_size: u64 = 0;
        let mut other_count: usize = 0;

        fn walk(
            dir: &Path,
            total_size: &mut u64,
            total_count: &mut usize,
            categories: &mut BTreeMap<&'static str, (u64, usize)>,
            other_size: &mut u64,
            other_count: &mut usize,
        ) {
            let entries = match fs::read_dir(dir) {
                Ok(e) => e,
                Err(_) => return,
            };

            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
                    if name == ".git" || name == "node_modules" || name == ".import" {
                        continue;
                    }
                    walk(
                        &path,
                        total_size,
                        total_count,
                        categories,
                        other_size,
                        other_count,
                    );
                } else if path.is_file() {
                    if let Ok(meta) = fs::metadata(&path) {
                        let size = meta.len();
                        *total_size += size;
                        *total_count += 1;

                        let ext = path
                            .extension()
                            .and_then(|e| e.to_str())
                            .unwrap_or("");

                        if let Some(cat) = classify_extension(ext) {
                            let entry = categories.entry(cat).or_insert((0, 0));
                            entry.0 += size;
                            entry.1 += 1;
                        } else {
                            *other_size += size;
                            *other_count += 1;
                        }
                    }
                }
            }
        }

        walk(
            &dir,
            &mut total_size,
            &mut total_count,
            &mut categories,
            &mut other_size,
            &mut other_count,
        );

        let mut cat_vec: Vec<FileSizeCategory> = categories
            .into_iter()
            .map(|(label, (size, count))| FileSizeCategory {
                label: label.to_string(),
                size,
                count,
            })
            .collect();

        if other_count > 0 || other_size > 0 {
            cat_vec.push(FileSizeCategory {
                label: "Other".to_string(),
                size: other_size,
                count: other_count,
            });
        }

        cat_vec.sort_by(|a, b| b.size.cmp(&a.size));

        let result = Ok(ProjectSizeInfo {
            total_size,
            file_count: total_count,
            categories: cat_vec,
        });

        size_cache().lock().unwrap().insert(
            path.clone(),
            CachedSize {
                dir_mtime,
                data: result.clone(),
            },
        );

        result
    })
    .await
    .map_err(|e| e.to_string())?
}
