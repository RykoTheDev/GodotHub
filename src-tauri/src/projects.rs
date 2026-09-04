use crate::models::*;
use crate::persist;
use crate::process::{self, ProcessLiveness};
use crate::settings;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Child;
use tauri::{AppHandle, Emitter, Manager};
use uuid::Uuid;

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::SystemTime;

pub enum TrackedHandle {
    Child(Child),
    Pid { pid: u32, project_path: String },
}

pub struct TrackedProcess {
    pub handle: TrackedHandle,
    pub kill_tree: bool,
    pub launched_at: std::time::SystemTime,
    pid_revalidated: bool,
}

impl TrackedProcess {
    fn is_running(&mut self) -> bool {
        match &mut self.handle {
            TrackedHandle::Child(child) => matches!(child.try_wait(), Ok(None)),
            TrackedHandle::Pid { pid, project_path } => {
                match process::process_liveness(*pid) {
                    ProcessLiveness::Alive => true,
                    ProcessLiveness::Exited => {
                        if self.pid_revalidated {
                            return false;
                        }
                        self.pid_revalidated = true;
                        match process::find_running_godot_processes() {
                            Ok(processes) => processes.iter().any(|running| {
                                running.pid == *pid
                                    && same_path(&running.project_path, project_path)
                            }),
                            Err(_) => true,
                        }
                    }
                    // A permission error is not evidence that the process exited. Keep
                    // monitoring it; the next poll may succeed after a transient error.
                    ProcessLiveness::Unknown => true,
                }
            }
        }
    }
}

pub struct ActiveProcesses(pub Mutex<HashMap<String, TrackedProcess>>);

#[derive(Debug, Clone, Serialize)]
pub struct RunningProjectInfo {
    pub id: String,
    pub name: String,
    pub version: String,
    pub launched_at_ms: u64,
}

const SESSION_START_DELAY_MS: u64 = 3000;

const DEFAULT_ICON_SVG: &[u8] = include_bytes!("../icon.svg");

struct CachedIcon {
    project_godot_mtime: Option<SystemTime>,
    icon_scan_depth: u32,
    data: Option<String>,
}

fn icon_cache() -> &'static Mutex<HashMap<String, CachedIcon>> {
    static CACHE: OnceLock<Mutex<HashMap<String, CachedIcon>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

pub(crate) fn read_projects_from(dir: &std::path::Path) -> Vec<Project> {
    let file = dir.join("projects.json");
    if !file.exists() {
        return vec![];
    }
    serde_json::from_str(&fs::read_to_string(&file).unwrap_or_default()).unwrap_or_default()
}

pub(crate) fn read_projects(app: &AppHandle) -> Vec<Project> {
    read_projects_from(&crate::workspace::active_workspace_dir(app))
}

pub(crate) fn write_projects_to(
    dir: &std::path::Path,
    projects: &Vec<Project>,
) -> Result<(), String> {
    persist::write_json(&dir.join("projects.json"), projects).map_err(|e| e.to_string())
}

pub(crate) fn write_projects(app: &AppHandle, projects: &Vec<Project>) -> Result<(), String> {
    write_projects_to(&crate::workspace::active_workspace_dir(app), projects)
}

pub(crate) fn epoch_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

fn settle_project_session(
    app: &AppHandle,
    id: &str,
    active_elapsed: Option<std::time::Duration>,
) {
    let mut projects = read_projects(app);
    let Some(project) = projects.iter_mut().find(|p| p.id == id) else {
        return;
    };
    let mut changed = false;
    let mut added_ms = 0u64;
    let mut session_start_ms: Option<u64> = None;
    match active_elapsed {
        Some(d) => {
            let marker = project.session_started_at_ms.take();
            changed = marker.is_some();
            added_ms = (d.as_millis() as u64).saturating_sub(SESSION_START_DELAY_MS);
            session_start_ms = Some(marker.unwrap_or_else(|| epoch_ms().saturating_sub(added_ms)));
        }
        None => {
            if let Some(start) = project.session_started_at_ms.take() {
                let elapsed_ms = epoch_ms().saturating_sub(start);
                added_ms = elapsed_ms.saturating_sub(SESSION_START_DELAY_MS);
                session_start_ms = Some(start);
                changed = true;
            }
        }
    }
    if added_ms > 0 {
        project.total_time_seconds += added_ms / 1000;
        changed = true;
    }
    if changed {
        let _ = write_projects(app, &projects);
    }
    if let Some(start_ms) = session_start_ms {
        crate::time_stats::record_session(app, id, start_ms, added_ms / 1000);
    }
}

pub(crate) fn settle_stale_sessions(app: &AppHandle) {
    static SETTLED: std::sync::OnceLock<()> = std::sync::OnceLock::new();
    SETTLED.get_or_init(|| {
        let running: std::collections::HashSet<String> = {
            let Some(state) = app.try_state::<ActiveProcesses>() else {
                return;
            };
            let active = state.0.lock().unwrap();
            active.keys().cloned().collect()
        };
        let projects = read_projects(app);

        let Ok(os_running) = process::find_running_godot_processes() else {
            // Process discovery is required to distinguish an exited session from a
            // temporarily unavailable process listing. Leave the session untouched and
            // let the next application start retry discovery.
            return;
        };

        for p in projects {
            if p.session_started_at_ms.is_some() && !running.contains(&p.id) {
                if let Some(running_process) = os_running
                    .iter()
                    .find(|process| same_path(&process.project_path, &p.path))
                {
                    retrack_stale_session(
                        app,
                        &p,
                        TrackedHandle::Pid {
                            pid: running_process.pid,
                            project_path: p.path.clone(),
                        },
                    );
                } else {
                    settle_project_session(app, &p.id, None);
                }
            }
        }
    });
}

fn retrack_stale_session(app: &AppHandle, project: &Project, handle: TrackedHandle) {
    let Some(state) = app.try_state::<ActiveProcesses>() else {
        return;
    };

    let id = project.id.clone();
    let app_clone = app.clone();

    let tracked = TrackedProcess {
        handle,
        kill_tree: false,
        pid_revalidated: false,
        launched_at: std::time::UNIX_EPOCH
            + std::time::Duration::from_millis(
                project
                    .session_started_at_ms
                    .unwrap_or_else(|| epoch_ms())
                    .saturating_sub(SESSION_START_DELAY_MS),
            ),
    };
    state.0.lock().unwrap().insert(id.clone(), tracked);

    std::thread::spawn(move || {
        wait_until_exited(&app_clone, &id);
    });
}

#[cfg(target_os = "linux")]
fn case_fold(path: &str) -> String {
    path.to_string()
}

#[cfg(not(target_os = "linux"))]
fn case_fold(path: &str) -> String {
    path.to_lowercase()
}

fn normalize_path(path: &str) -> String {
    let trimmed = path.trim_end_matches(['/', '\\']);
    case_fold(if trimmed.is_empty() { path } else { trimmed })
}

pub fn same_path(a: &str, b: &str) -> bool {
    normalize_path(a) == normalize_path(b)
}

pub fn contains_path(paths: &[String], path: &str) -> bool {
    let target = normalize_path(path);
    paths.iter().any(|p| normalize_path(p) == target)
}

fn undismiss(app: &AppHandle, path: &str) {
    let mut s = settings::read_settings(app);
    let before = s.dismissed_project_paths.len();
    s.dismissed_project_paths.retain(|p| !same_path(p, path));
    if s.dismissed_project_paths.len() != before {
        let _ = settings::write_settings(app, &s);
    }
    let mut archive = read_dismissed_archive(app);
    if archive.remove(&normalize_path(path)).is_some() {
        write_dismissed_archive(app, &archive);
    }
}

fn dismissed_archive_file(app: &AppHandle) -> PathBuf {
    crate::workspace::active_workspace_dir(app).join("dismissed_projects.json")
}

fn read_dismissed_archive(app: &AppHandle) -> BTreeMap<String, Project> {
    let file = dismissed_archive_file(app);
    if !file.exists() {
        return BTreeMap::new();
    }
    serde_json::from_str(&fs::read_to_string(&file).unwrap_or_default()).unwrap_or_default()
}

fn write_dismissed_archive(app: &AppHandle, archive: &BTreeMap<String, Project>) {
    let _ = persist::write_json(&dismissed_archive_file(app), archive);
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
    let start = std::time::Instant::now();
    settle_stale_sessions(&app);
    let projects = read_projects(&app);
    let (mut kept, removed): (Vec<Project>, Vec<Project>) = projects
        .into_iter()
        .partition(|p| Path::new(&p.path).join("project.godot").exists());

    let mut tags_changed = false;
    let mut names_changed = false;
    for p in kept.iter_mut() {
        if p.tags.is_empty() {
            let disk_tags = resolve_project_tags(&p.path);
            if !disk_tags.is_empty() {
                p.tags = disk_tags;
                tags_changed = true;
            }
        }
        let folder = Path::new(&p.path)
            .file_name()
            .map(|n| n.to_string_lossy().to_string());
        if let Some(folder_name) = folder {
            if p.name == folder_name {
                if let Some(resolved) = resolve_project_name(&p.path) {
                    if !resolved.trim().is_empty() && resolved != p.name {
                        p.name = resolved;
                        names_changed = true;
                    }
                }
            }
        }
    }

    if !removed.is_empty() || tags_changed || names_changed {
        let _ = write_projects(&app, &kept);
    }
    let stats = crate::time_stats::read_stats(&app);
    let now = chrono::Local::now();
    for p in kept.iter_mut() {
        let (today, week) = crate::time_stats::breakdown(&stats, &p.id, now);
        p.time_today_seconds = today;
        p.time_week_seconds = week;
    }
    eprintln!(
        "[timing] list_projects total={}ms projects={}",
        start.elapsed().as_millis(),
        kept.len()
    );
    kept
}

fn capitalize_word(word: &str) -> String {
    let mut chars = word.chars();
    match chars.next() {
        Some(first) => first.to_uppercase().collect::<String>() + &chars.as_str().to_lowercase(),
        None => String::new(),
    }
}

fn split_naming_words(name: &str) -> Vec<String> {
    let mut words: Vec<String> = Vec::new();
    let mut current = String::new();
    let chars: Vec<char> = name.chars().collect();
    let n = chars.len();
    for (i, &c) in chars.iter().enumerate() {
        if !c.is_ascii_alphanumeric() {
            if !current.is_empty() {
                words.push(std::mem::take(&mut current));
            }
            continue;
        }
        if !current.is_empty() {
            let last = current.chars().last().unwrap();
            let split = (last.is_ascii_lowercase() || last.is_ascii_digit())
                && c.is_ascii_uppercase()
                || last.is_ascii_uppercase()
                    && c.is_ascii_uppercase()
                    && i + 1 < n
                    && chars[i + 1].is_ascii_lowercase();
            if split {
                words.push(std::mem::take(&mut current));
            }
        }
        current.push(c);
    }
    if !current.is_empty() {
        words.push(current);
    }
    words
}

pub(crate) fn apply_naming_convention(name: &str, convention: &str) -> String {
    let words = split_naming_words(name);
    if words.is_empty() {
        return name.trim().to_string();
    }
    match convention {
        "kebab-case" => words
            .iter()
            .map(|w| w.to_lowercase())
            .collect::<Vec<_>>()
            .join("-"),
        "snake_case" => words
            .iter()
            .map(|w| w.to_lowercase())
            .collect::<Vec<_>>()
            .join("_"),
        "camelCase" => {
            let mut out = String::new();
            for (i, w) in words.iter().enumerate() {
                if i == 0 {
                    out.push_str(&w.to_lowercase());
                } else {
                    out.push_str(&capitalize_word(w));
                }
            }
            out
        }
        "PascalCase" => words
            .iter()
            .map(|w| capitalize_word(w))
            .collect::<String>(),
        "Title Case" => words
            .iter()
            .map(|w| capitalize_word(w))
            .collect::<Vec<_>>()
            .join(" "),
        _ => name.to_string(),
    }
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
    let settings = settings::read_settings(&app);
    let folder_name =
        apply_naming_convention(&name, &settings.directory_naming_convention);
    let project_dir = PathBuf::from(&location).join(&folder_name);
    if project_dir.exists() {
        return Err(format!(
            "A folder named '{}' already exists at this location",
            folder_name
        ));
    }

    if let Some(ref tid) = template_id {
        let template_src = crate::templates::template_dir(&app, tid);
        if !template_src.exists() {
            return Err("Template not found".into());
        }
        crate::templates::copy_dir(&template_src, &project_dir, &[])?;
        let _ = fs::remove_file(project_dir.join("template.json"));
    } else {
        fs::create_dir_all(&project_dir).map_err(|e| e.to_string())?;
    }

    let feature_tag = version_feature_tag(&godot_version);
    let mut project_godot = format!(
        "; Engine configuration file.\n\n[application]\n\nconfig/name=\"{}\"\nconfig/icon=\"res://icon.svg\"\nconfig/features=PackedStringArray(\"{}\")\n",
        name, feature_tag
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
    let project_path = project_dir.to_string_lossy().to_string();
    let tags = resolve_project_tags(&project_path);
    let project = Project {
        id: Uuid::new_v4().to_string(),
        name,
        path: project_path,
        godot_version,
        created_at: chrono::Utc::now().to_rfc3339(),
        last_opened: None,
        category: effective_category.clone(),
        pinned: false,
        sort_order: next_sort_order(&projects, &effective_category),
        launch_arguments: String::new(),
        tags,
        total_time_seconds: 0,
        session_started_at_ms: None,
        time_today_seconds: 0,
        time_week_seconds: 0,
    };

    projects.push(project.clone());
    write_projects(&app, &projects)?;
    undismiss(&app, &project.path);
    if !project.godot_version.is_empty() {
        let _ = crate::godotenv::pin_version(&project.path, &project.godot_version);
    }
    Ok(project)
}

fn version_feature_tag(tag: &str) -> String {
    let cleaned = tag.trim().trim_start_matches('v');
    let mut parts = cleaned.split(['.', '-']);
    let is_num = |s: &str| !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit());
    match (parts.next(), parts.next()) {
        (Some(m), Some(n)) if is_num(m) && is_num(n) => format!("{}.{}", m, n),
        _ => "4.3".to_string(),
    }
}

fn rebind_project_to_spec(
    p: &mut Project,
    spec: &crate::godotenv::DetectedVersion,
    installed: &[InstalledGodotVersion],
) -> bool {
    let Some(v) = crate::godotenv::best_match(spec, installed) else {
        return false;
    };
    if p.godot_version == v.tag {
        return false;
    }
    if !p.godot_version.is_empty() {
        let bound_is_mono = p.godot_version.trim_end().ends_with("-mono");
        if bound_is_mono == spec.is_dotnet {
            return false;
        }
    }
    p.godot_version = v.tag.clone();
    true
}

pub fn rebind_projects_to_version(app: &AppHandle, version: &InstalledGodotVersion) {
    let installed = crate::godot_versions::read_registry(app);
    let mut projects = read_projects(app);
    let mut changed = false;
    for p in projects.iter_mut() {
        let Some(spec) = crate::godotenv::detect_version(&p.path) else {
            continue;
        };
        if !crate::godotenv::matches_detected(&spec, &version.tag) {
            continue;
        }
        if rebind_project_to_spec(p, &spec, &installed) {
            changed = true;
        }
    }
    if changed {
        let _ = write_projects(app, &projects);
    }
}

pub fn rebind_projects_to_installed(app: &AppHandle) {
    let installed = crate::godot_versions::read_registry(app);
    let mut projects = read_projects(app);
    let mut changed = false;
    for p in projects.iter_mut() {
        let Some(spec) = crate::godotenv::detect_version(&p.path) else {
            continue;
        };
        if rebind_project_to_spec(p, &spec, &installed) {
            changed = true;
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
    let folder_name = PathBuf::from(&path)
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "Untitled".into());
    let name = resolve_project_name(&path).unwrap_or(folder_name);

    let mut projects = read_projects(&app);
    if projects.iter().any(|p| same_path(&p.path, &path)) {
        return Err("This project is already in your library".into());
    }

    let mut archive = read_dismissed_archive(&app);
    if let Some(mut archived) = archive.remove(&normalize_path(&path)) {
        archived.session_started_at_ms = None;
        archived.time_today_seconds = 0;
        archived.time_week_seconds = 0;
        let folder_name = PathBuf::from(&path)
            .file_name()
            .map(|n| n.to_string_lossy().to_string());
        if let Some(folder) = folder_name {
            if archived.name == folder {
                if let Some(resolved) = resolve_project_name(&path) {
                    if !resolved.trim().is_empty() {
                        archived.name = resolved;
                    }
                }
            }
        }
        if !godot_version.is_empty() {
            archived.godot_version = godot_version;
        }
        if let Some(cat) = &category {
            archived.category = Some(cat.clone());
        }
        if archived.godot_version.is_empty() {
            if let Some(spec) = crate::godotenv::detect_version(&path) {
                let installed = crate::godot_versions::read_registry(&app);
                if let Some(v) = crate::godotenv::best_match(&spec, &installed) {
                    archived.godot_version = v.tag.clone();
                }
            }
        }
        write_dismissed_archive(&app, &archive);
        projects.push(archived.clone());
        write_projects(&app, &projects)?;
        undismiss(&app, &path);
        return Ok(archived);
    }

    let mut godot_version = godot_version;
    if godot_version.is_empty() {
        if let Some(spec) = crate::godotenv::detect_version(&path) {
            let installed = crate::godot_versions::read_registry(&app);
            if let Some(v) = crate::godotenv::best_match(&spec, &installed) {
                godot_version = v.tag.clone();
            }
        }
    }
    let tags = resolve_project_tags(&path);
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
        tags,
        total_time_seconds: 0,
        session_started_at_ms: None,
        time_today_seconds: 0,
        time_week_seconds: 0,
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
    category: Option<String>,
) -> Result<Project, String> {
    let effective_category = category
        .as_ref()
        .and_then(|c| if c.trim().is_empty() { None } else { Some(c.clone()) });
    let project = register_project(
        app.clone(),
        path.clone(),
        godot_version,
        effective_category,
    )?;
    undismiss(&app, &path);
    Ok(project)
}

#[tauri::command]
pub async fn remove_project(app: AppHandle, id: String, delete_files: bool) -> Result<(), String> {
    let mut projects = read_projects(&app);
    let idx = projects
        .iter()
        .position(|p| p.id == id)
        .ok_or("Project not found")?;
    let project = projects.remove(idx);
    write_projects(&app, &projects)?;

    if !delete_files {
        let mut s = crate::settings::read_settings(&app);
        if !contains_path(&s.dismissed_project_paths, &project.path) {
            s.dismissed_project_paths.push(project.path.clone());
            let _ = crate::settings::write_settings(&app, &s);
        }

        let mut snapshot = project.clone();
        snapshot.session_started_at_ms = None;
        snapshot.time_today_seconds = 0;
        snapshot.time_week_seconds = 0;
        let mut archive = read_dismissed_archive(&app);
        archive.insert(normalize_path(&project.path), snapshot);
        write_dismissed_archive(&app, &archive);
    }

    if delete_files {
        let path = project.path.clone();
        tokio::task::spawn_blocking(move || {
            let _ = trash::delete_all([&path]);
        });
    }

    Ok(())
}

#[tauri::command]
pub fn reintroduce_dismissed_projects(app: AppHandle, paths: Vec<String>) -> Result<Vec<Project>, String> {
    let mut added = vec![];
    for path in &paths {
        if let Ok(p) = register_project(app.clone(), path.clone(), String::new(), None) {
            undismiss(&app, path);
            added.push(p);
        }
    }
    Ok(added)
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
        if project.godot_version != v {
            project.godot_version = v.clone();
            if !v.is_empty() {
                let _ = crate::godotenv::pin_version(&project.path, &v);
            }
        }
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
pub fn open_project(
    app: AppHandle,
    id: String,
    editor: bool,
    console: Option<bool>,
) -> Result<(), String> {
    let mut projects = read_projects(&app);
    let project = projects
        .iter_mut()
        .find(|p| p.id == id)
        .ok_or("Project not found")?;
    let project_name = resolve_project_name(&project.path)
        .unwrap_or_else(|| project.name.clone());
    let project_version = project.godot_version.clone();

    if project.godot_version.is_empty() {
        return Err("No Godot version bound to this project".into());
    }

    let versions = crate::godot_versions::list_installed_godot_versions(app.clone())?;
    let version = versions
        .iter()
        .find(|v| v.tag == project.godot_version)
        .ok_or("Bound Godot version is not installed")?;

    let mut args = vec!["--path".to_string(), project.path.clone()];
    if editor {
        args.push("-e".to_string());
    }
    args.extend(
        project
            .launch_arguments
            .split_whitespace()
            .map(str::to_string),
    );

    let settings = settings::read_settings(&app);
    let use_console = console.unwrap_or(settings.launch_with_console);

    let launched = crate::godot_versions::spawn_editor(
        &app,
        Path::new(&version.executable_path),
        &args,
        &project_name,
        use_console,
    )?;
    #[cfg(unix)]
    let pid_file = launched.pid_file.clone();
    let kill_tree = launched.kill_tree;

    project.last_opened = Some(chrono::Utc::now().to_rfc3339());
    project.session_started_at_ms = Some(epoch_ms() + SESSION_START_DELAY_MS);
    write_projects(&app, &projects)?;

    let _ = crate::tray::refresh_tray_menu(app.clone());

    if let Some(state) = app.try_state::<ActiveProcesses>() {
        state.0.lock().unwrap().insert(
            id.clone(),
            TrackedProcess {
                handle: TrackedHandle::Child(launched.child),
                kill_tree,
                pid_revalidated: false,
                launched_at: std::time::SystemTime::now(),
            },
        );
    }

    let _ = app.emit(
        "project:launched",
        serde_json::json!({
            "id": id.clone(),
            "name": project_name,
            "version": project_version,
        }),
    );

    let mut reopen_when_closed = false;

    if settings.close_on_project_open {
        #[cfg(target_os = "macos")]
        let keep_alive = true;
        #[cfg(not(target_os = "macos"))]
        let keep_alive = settings.minimize_to_tray;

        if keep_alive {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.hide();
            }
            reopen_when_closed = settings.reopen_after_godot_closes;
        } else {
            app.exit(0);
        }
    }

    let app_clone = app.clone();
    let watched = id.clone();
    std::thread::spawn(move || {
        #[cfg(unix)]
        if let Some(file) = pid_file {
            adopt_terminal_pid(&app_clone, &watched, &file);
        }

        wait_until_exited(&app_clone, &watched);

        if reopen_when_closed {
            if let Some(window) = app_clone.get_webview_window("main") {
                let _ = window.show();
                let _ = window.set_focus();
            }
        }
    });

    Ok(())
}

#[cfg(unix)]
fn adopt_terminal_pid(app: &AppHandle, id: &str, pid_file: &Path) {
    const ATTEMPTS: u32 = 200;

    for _ in 0..ATTEMPTS {
        if let Some(pid) = crate::terminal::read_pid_file(pid_file) {
            let _ = fs::remove_file(pid_file);

            let replaced = {
                let Some(state) = app.try_state::<ActiveProcesses>() else {
                    return;
                };
                let mut active = state.0.lock().unwrap();
                active
                    .get_mut(id)
                    .map(|tracked| {
                        std::mem::replace(
                            &mut tracked.handle,
                            TrackedHandle::Pid {
                                pid,
                                project_path: read_projects(app)
                                    .into_iter()
                                    .find(|project| project.id == id)
                                    .map(|project| project.path)
                                    .unwrap_or_default(),
                            },
                        )
                    })
            };

            if let Some(TrackedHandle::Child(mut launcher)) = replaced {
                let _ = launcher.wait();
            }
            return;
        }
        std::thread::sleep(std::time::Duration::from_millis(50));
    }
}

fn wait_until_exited(app: &AppHandle, id: &str) {
    const POLL: std::time::Duration = std::time::Duration::from_millis(500);
    loop {
        let Some(state) = app.try_state::<ActiveProcesses>() else {
            return;
        };

        let exited = {
            let mut active = state.0.lock().unwrap();
            let Some(tracked) = active.get_mut(id) else {
                return;
            };
            if tracked.is_running() {
                None
            } else {
                let elapsed = tracked.launched_at.elapsed().ok();
                active.remove(id);
                Some(elapsed)
            }
        };

        if let Some(elapsed) = exited {
            settle_project_session(app, id, elapsed);
            let _ = app.emit("project:exited", serde_json::json!({ "id": id }));
            return;
        }

        std::thread::sleep(POLL);
    }
}

fn kill_tracked(tracked: &mut TrackedProcess) -> Result<(), String> {
    match &mut tracked.handle {
        TrackedHandle::Child(child) => {
            if tracked.kill_tree {
                #[cfg(target_os = "windows")]
                {
                    use std::os::windows::process::CommandExt;

                    return std::process::Command::new("taskkill")
                        .args(["/PID", &child.id().to_string(), "/T", "/F"])
                        .creation_flags(crate::terminal::CREATE_NO_WINDOW)
                        .status()
                        .map(|_| ())
                        .map_err(|e| format!("Failed to kill process: {e}"));
                }
            }

            child
                .kill()
                .map_err(|e| format!("Failed to kill process: {e}"))?;
            child.wait().ok();
            Ok(())
        }
        TrackedHandle::Pid { pid, project_path } => {
            let processes = process::find_running_godot_processes()
                .map_err(|error| format!("Could not verify Godot process identity: {error}"))?;
            if !processes.iter().any(|running| {
                running.pid == *pid && same_path(&running.project_path, project_path)
            }) {
                return Err("Refusing to terminate a PID whose Godot identity no longer matches".into());
            }
            process::terminate_process(*pid)
        }
    }
}

#[tauri::command]
pub fn list_running_projects(app: AppHandle) -> Vec<RunningProjectInfo> {
    let entries: Vec<(String, std::time::SystemTime)> = {
        let Some(state) = app.try_state::<ActiveProcesses>() else {
            return vec![];
        };
        let active = state.0.lock().unwrap();
        active
            .iter()
            .map(|(id, p)| (id.clone(), p.launched_at))
            .collect()
    };
    if entries.is_empty() {
        return vec![];
    }
    let projects = read_projects(&app);
    entries
        .into_iter()
        .filter_map(|(id, launched_at)| {
            let project = projects.iter().find(|p| p.id == id)?;
            let launched_at_ms = launched_at
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_millis() as u64)
                .unwrap_or(0);
            Some(RunningProjectInfo {
                id,
                name: project.name.clone(),
                version: project.godot_version.clone(),
                launched_at_ms,
            })
        })
        .collect()
}

#[tauri::command]
pub fn stop_project(app: AppHandle, id: String) -> Result<(), String> {
    let state = app
        .try_state::<ActiveProcesses>()
        .ok_or("No running process found for this project")?;

    let mut tracked = {
        let mut active = state.0.lock().unwrap();
        active
            .remove(&id)
            .ok_or("No running process found for this project")?
    };

    let elapsed = tracked.launched_at.elapsed().ok();
    let kill_result = kill_tracked(&mut tracked);
    settle_project_session(&app, &id, elapsed);
    let _ = app.emit("project:exited", serde_json::json!({ "id": id }));
    kill_result
}

#[cfg(all(unix, not(target_os = "macos")))]
fn spawn_detached_checked(bin: &str, args: &[std::ffi::OsString]) -> Result<(), String> {
    let mut cmd = std::process::Command::new(bin);
    crate::terminal::sanitize_child_env(&mut cmd);
    cmd.args(args);
    let mut child = cmd.spawn().map_err(|e| format!("{bin}: {e}"))?;

    let deadline = std::time::Instant::now() + std::time::Duration::from_millis(1500);
    loop {
        match child.try_wait() {
            Ok(Some(status)) if status.success() => return Ok(()),
            Ok(Some(_)) => return Err(format!("{bin} exited with an error")),
            Ok(None) if std::time::Instant::now() >= deadline => return Ok(()),
            Ok(None) => std::thread::sleep(std::time::Duration::from_millis(50)),
            Err(e) => return Err(format!("{bin}: {e}")),
        }
    }
}

#[cfg(all(unix, not(target_os = "macos")))]
fn open_folder_linux(path: &str, dir: &Path) -> Result<(), String> {
    let dir_arg = dir.as_os_str().to_os_string();
    let path_arg = std::ffi::OsString::from(path);

    let mut last_err = String::from("no file manager could open the folder");

    for (bin, args) in [("xdg-open", vec![dir_arg.clone()])] {
        match spawn_detached_checked(bin, &args) {
            Ok(()) => return Ok(()),
            Err(e) => last_err = e,
        }
    }

    let file_managers: [(&str, Vec<std::ffi::OsString>); 12] = [
        ("gio", vec![std::ffi::OsString::from("open"), path_arg.clone()]),
        ("nautilus", vec![path_arg.clone()]),
        ("org.gnome.Nautilus", vec![path_arg.clone()]),
        ("dolphin", vec![path_arg.clone()]),
        ("thunar", vec![path_arg.clone()]),
        ("pcmanfm", vec![path_arg.clone()]),
        ("pcmanfm-qt", vec![path_arg.clone()]),
        ("nemo", vec![path_arg.clone()]),
        ("caja", vec![path_arg.clone()]),
        ("konqueror", vec![path_arg.clone()]),
        (
            "exo-open",
            vec![
                std::ffi::OsString::from("--launch"),
                std::ffi::OsString::from("FileManager"),
                path_arg.clone(),
            ],
        ),
        ("gnome-open", vec![path_arg.clone()]),
    ];
    for (bin, args) in file_managers {
        match spawn_detached_checked(bin, &args) {
            Ok(()) => return Ok(()),
            Err(e) => last_err = e,
        }
    }

    Err(format!(
        "{last_err}.\n\nNo file manager was found. Install one (e.g. `sudo pacman -S nautilus` \
         on Arch) or register your default folder handler:\n  xdg-mime default <file-manager>.desktop \
         inode/directory"
    ))
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
    return open_folder_linux(&path, &dir);

    #[cfg(any(target_os = "windows", target_os = "macos"))]
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
            let mut cmd = std::process::Command::new(editor_path.trim());
            crate::terminal::sanitize_child_env(&mut cmd);
            let result = cmd.arg(&dir).spawn();
            if result.is_ok() {
                return Ok(());
            }
        }
    }

    for editor in &["code", "rider", "idea", "code-insiders", "codium", "zed"] {
        let mut cmd = std::process::Command::new(editor);
        crate::terminal::sanitize_child_env(&mut cmd);
        if cmd.arg(&dir).spawn().is_ok() {
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
            if p.exists()
                && std::process::Command::new(p).arg(&dir).spawn().is_ok()
            {
                return Ok(());
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

#[tauri::command]
pub async fn read_image_file(path: String) -> Option<String> {
    tokio::task::spawn_blocking(move || {
        let bytes = std::fs::read(&path).ok()?;
        let lower = path.to_lowercase();
        let mime = if lower.ends_with(".png") {
            "image/png"
        } else if lower.ends_with(".jpg") || lower.ends_with(".jpeg") {
            "image/jpeg"
        } else if lower.ends_with(".webp") {
            "image/webp"
        } else {
            "image/svg+xml"
        };
        use base64::{engine::general_purpose, Engine as _};
        Some(format!(
            "data:{};base64,{}",
            mime,
            general_purpose::STANDARD.encode(bytes)
        ))
    })
    .await
    .ok()
    .flatten()
}

fn find_resource_by_uid(
    dir: &Path,
    target_uid: &str,
    depth: usize,
    max_depth: usize,
    budget: &mut usize,
) -> Option<PathBuf> {
    if depth > max_depth || *budget == 0 {
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
        if let Some(found) =
            find_resource_by_uid(&sub, target_uid, depth + 1, max_depth, budget)
        {
            return Some(found);
        }
    }
    None
}

fn resolve_project_icon(
    project_path: &str,
    icon_scan_depth: u32,
) -> Option<(Vec<u8>, &'static str)> {
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
        if let Some(found) = find_resource_by_uid(
            &dir,
            &uid,
            0,
            icon_scan_depth.max(1) as usize,
            &mut budget,
        ) {
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

#[tauri::command]
pub fn write_project_tags(
    app: AppHandle,
    id: String,
    path: String,
    tags: Vec<String>,
) -> Result<Project, String> {
    let godot_file = PathBuf::from(&path).join("project.godot");
    let content = fs::read_to_string(&godot_file).map_err(|e| e.to_string())?;
    let mut lines: Vec<String> = content.lines().map(|l| l.to_string()).collect();

    if tags.is_empty() {
        lines.retain(|l| !l.trim().starts_with("config/tags="));
    } else {
        let tag_line = format!(
            "config/tags=PackedStringArray({})",
            tags.iter()
                .map(|t| format!("\"{}\"", t))
                .collect::<Vec<_>>()
                .join(", ")
        );

        let mut found = false;
        for line in lines.iter_mut() {
            if line.trim().starts_with("config/tags=") {
                *line = tag_line.clone();
                found = true;
                break;
            }
        }

        if !found {
            if let Some(idx) = lines.iter().position(|l| l.trim() == "[application]") {
                lines.insert(idx + 1, tag_line.clone());
            } else {
                lines.push(String::new());
                lines.push("[application]".to_string());
                lines.push(tag_line.clone());
            }
        }
    }

    fs::write(&godot_file, lines.join("\n")).map_err(|e| e.to_string())?;

    let mut projects = read_projects(&app);
    let project = projects
        .iter_mut()
        .find(|p| p.id == id)
        .ok_or("Project not found")?;
    project.tags = tags;
    let updated = project.clone();
    write_projects(&app, &projects)?;
    Ok(updated)
}

pub(crate) fn resolve_project_tags(project_path: &str) -> Vec<String> {
    let godot_file = PathBuf::from(project_path).join("project.godot");
    let content = match fs::read_to_string(&godot_file) {
        Ok(c) => c,
        Err(_) => return vec![],
    };
    for line in content.lines() {
        let line = line.trim();
        if let Some(rest) = line.strip_prefix("config/tags=") {
            if let Some(inner) = rest
                .strip_prefix("PackedStringArray(")
                .and_then(|s| s.strip_suffix(')'))
            {
                let tags: Vec<String> = inner
                    .split(',')
                    .filter_map(|t| {
                        let t = t.trim().trim_matches('"');
                        if t.is_empty() { None } else { Some(t.to_string()) }
                    })
                    .collect();
                return tags;
            }
        }
    }
    vec![]
}

#[derive(Serialize, Deserialize)]
struct ProjectTimeStats {
    id: String,
    path: String,
    total_time_seconds: u64,
    #[serde(default)]
    sessions: Vec<crate::time_stats::SessionRecord>,
    #[serde(default)]
    daily: std::collections::BTreeMap<String, u64>,
}

#[derive(Serialize, Deserialize)]
struct TimeStatsExport {
    exported_at: String,
    projects: Vec<ProjectTimeStats>,
}

#[tauri::command]
pub fn export_project_stats(app: AppHandle, path: String) -> Result<(), String> {
    let projects = read_projects(&app);
    let store = crate::time_stats::read_stats(&app);
    let stats = TimeStatsExport {
        exported_at: chrono::Utc::now().to_rfc3339(),
        projects: projects
            .iter()
            .map(|p| ProjectTimeStats {
                id: p.id.clone(),
                path: p.path.clone(),
                total_time_seconds: p.total_time_seconds,
                sessions: store.projects.get(&p.id).cloned().unwrap_or_default(),
                daily: store.daily.get(&p.id).cloned().unwrap_or_default(),
            })
            .collect(),
    };
    persist::write_json(Path::new(&path), &stats).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn import_project_stats(app: AppHandle, path: String) -> Result<usize, String> {
    let stats: Option<TimeStatsExport> = persist::read_json_opt(Path::new(&path));
    let Some(stats) = stats else {
        return Err("Couldn't read the stats backup file".into());
    };
    let mut projects = read_projects(&app);
    let mut imported = 0usize;
    let mut restored: Vec<(
        String,
        Vec<crate::time_stats::SessionRecord>,
        std::collections::BTreeMap<String, u64>,
    )> = Vec::new();
    for s in &stats.projects {
        let idx = projects
            .iter()
            .position(|p| p.id == s.id)
            .or_else(|| projects.iter().position(|p| same_path(&p.path, &s.path)));
        if let Some(idx) = idx {
            projects[idx].total_time_seconds = s.total_time_seconds;
            restored.push((projects[idx].id.clone(), s.sessions.clone(), s.daily.clone()));
            imported += 1;
        }
    }
    if imported > 0 {
        write_projects(&app, &projects)?;
        let mut store = crate::time_stats::read_stats(&app);
        let mut changed = false;
        for (id, sessions, daily) in &restored {
            if !sessions.is_empty() {
                store.projects.insert(id.clone(), sessions.clone());
                changed = true;
            }
            if !daily.is_empty() {
                store.daily.insert(id.clone(), daily.clone());
                changed = true;
            }
        }
        if changed {
            crate::time_stats::write_stats(&app, &store);
        }
    }
    Ok(imported)
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
pub async fn validate_godot_folder(path: String, app: AppHandle) -> Option<GodotFolderPreview> {
    let godot_path = std::path::PathBuf::from(&path).join("project.godot");
    if !godot_path.exists() {
        return None;
    }
    let name = resolve_project_name(&path)?;
    let icon = get_project_icon(path, app).await;
    Some(GodotFolderPreview { name, icon })
}

#[tauri::command]
pub async fn get_project_icon(path: String, app: AppHandle) -> Option<String> {
    let icon_scan_depth = crate::settings::read_settings(&app).icon_scan_depth;
    tokio::task::spawn_blocking(move || {
        let mtime = fs::metadata(PathBuf::from(&path).join("project.godot"))
            .and_then(|m| m.modified())
            .ok();

        if let Some(cached) = icon_cache().lock().unwrap().get(&path) {
            if cached.project_godot_mtime == mtime
                && cached.icon_scan_depth == icon_scan_depth
            {
                return cached.data.clone();
            }
        }

        let (bytes, mime) = match resolve_project_icon(&path, icon_scan_depth) {
            Some(v) => v,
            None => {
                icon_cache().lock().unwrap().insert(
                    path.clone(),
                    CachedIcon {
                        project_godot_mtime: mtime,
                        icon_scan_depth,
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
                icon_scan_depth,
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

        cat_vec.sort_by_key(|a| std::cmp::Reverse(a.size));

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

#[derive(Clone, Serialize)]
pub struct ProjectFileEntry {
    pub path: String,
    pub is_dir: bool,
    pub size: u64,
}

#[tauri::command]
pub async fn get_project_file_tree(path: String) -> Result<Vec<ProjectFileEntry>, String> {
    tokio::task::spawn_blocking(move || -> Result<Vec<ProjectFileEntry>, String> {
        let dir = PathBuf::from(&path);
        if !dir.exists() {
            return Err("Project folder does not exist".into());
        }

        let mut entries = Vec::new();
        let skip = [".git", "node_modules", ".import", ".godot"];

        fn walk(
            dir: &Path,
            base: &Path,
            entries: &mut Vec<ProjectFileEntry>,
            skip: &[&str],
        ) {
            let read = match fs::read_dir(dir) {
                Ok(r) => r,
                Err(_) => return,
            };

            for entry in read.flatten() {
                let path = entry.path();
                let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");

                if skip.contains(&name) {
                    continue;
                }

                let rel = path.strip_prefix(base).unwrap_or(&path);
                let rel_str = rel.to_string_lossy().replace('\\', "/");

                if path.is_dir() {
                    entries.push(ProjectFileEntry {
                        path: format!("{}/", rel_str),
                        is_dir: true,
                        size: 0,
                    });
                    walk(&path, base, entries, skip);
                } else if path.is_file() {
                    let size = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
                    entries.push(ProjectFileEntry {
                        path: rel_str,
                        is_dir: false,
                        size,
                    });
                }
            }
        }

        walk(&dir, &dir, &mut entries, &skip);
        Ok(entries)
    })
    .await
    .map_err(|e| e.to_string())?
}
