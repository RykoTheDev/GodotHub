//! Release exports run separately from game/editor sessions and use the built-in console.
use crate::models::{InstalledGodotVersion, Project};
use crate::project_health::{setting, settings, strings, Setting};
use serde::Serialize;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fs;
use std::io::Read;
use std::path::{Component, Path, PathBuf};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc, Mutex,
};
use std::time::Duration;
use tauri::{AppHandle, Emitter, Manager};

#[derive(Clone, Debug, Serialize)]
pub struct ExportPreset {
    pub id: u32,
    pub name: String,
    pub platform: String,
    pub output_path: String,
    pub missing_templates: Vec<String>,
    pub template_error: Option<String>,
    #[serde(skip)]
    options: BTreeMap<String, String>,
}

#[derive(Serialize)]
pub struct ExportCatalog {
    pub version_tag: String,
    pub engine_error: Option<String>,
    pub presets: Vec<ExportPreset>,
}

#[derive(Clone, Debug, Serialize)]
pub struct ExportRun {
    pub id: String,
    pub project_id: String,
    pub project_name: String,
    pub preset_name: String,
    pub output_path: String,
    pub status: String,
    pub size_bytes: Option<u64>,
    pub exit_code: Option<i32>,
    pub error: Option<String>,
    pub started_at_ms: u64,
}

struct Job {
    run: ExportRun,
    workspace: PathBuf,
    root: PathBuf,
    cancel: Arc<AtomicBool>,
}

#[derive(Default)]
pub struct ExportRuns(Arc<Mutex<HashMap<String, Job>>>);

fn string_field(fields: &[Setting], section: &str, key: &str) -> String {
    setting(fields, section, key)
        .and_then(|v| strings(v).into_iter().next())
        .unwrap_or_default()
}

fn parse_presets(text: &str, project_name: &str) -> Result<Vec<ExportPreset>, String> {
    let fields = settings(text);
    let mut seen = HashSet::new();
    for field in &fields {
        if !seen.insert((&field.section, &field.key)) {
            return Err(format!(
                "Duplicate setting {} in [{}]. Resolve it in Godot first.",
                field.key, field.section
            ));
        }
    }
    let mut indices: Vec<u32> = fields
        .iter()
        .filter_map(|f| f.section.strip_prefix("preset.")?.parse().ok())
        .collect();
    indices.sort_unstable();
    indices.dedup();
    if indices.len() > 1024 {
        return Err("Too many export presets".into());
    }
    let mut names = HashSet::new();
    indices.into_iter().map(|id| {
        let section = format!("preset.{id}");
        let name = string_field(&fields, &section, "name");
        if name.is_empty() || !names.insert(name.clone()) { return Err("Export preset names must be nonempty and unique. Edit export_presets.cfg in Godot.".into()); }
        let platform = string_field(&fields, &section, "platform");
        let options = fields.iter().filter(|f| f.section == format!("{section}.options")).map(|f| (f.key.clone(), f.value.trim().to_string())).collect();
        let configured = string_field(&fields, &section, "export_path");
        let output_path = if configured.is_empty() { suggested_output(project_name, &name, &platform) } else { configured };
        Ok(ExportPreset {id,name,platform,output_path,options,missing_templates:vec![],template_error:None})
    }).collect()
}

fn slug(text: &str) -> String {
    let slug: String = text
        .chars()
        .map(|c| {
            if c.is_alphanumeric() || c == '-' || c == '_' {
                c
            } else {
                '_'
            }
        })
        .take(80)
        .collect();
    if slug.is_empty() {
        "game".into()
    } else {
        slug
    }
}

fn suggested_output(project: &str, preset: &str, platform: &str) -> String {
    let ext = match platform.to_lowercase().as_str() {
        "windows desktop" | "windows" => "exe",
        "linux" | "linux/x11" | "linux/bsd" => "x86_64",
        "android" => "apk",
        "web" | "html5" => "html",
        "macos" | "mac osx" | "ios" | "visionos" => "zip",
        _ => "bin",
    };
    format!("builds/{}/{}.{}", slug(preset), slug(project), ext)
}

fn legacy(version: &InstalledGodotVersion) -> bool {
    version.version.trim_start_matches('v').starts_with("3.")
        || version.tag.trim_start_matches('v').starts_with("3.")
}

fn option(preset: &ExportPreset, key: &str) -> String {
    preset
        .options
        .get(key)
        .map(|v| strings(v).into_iter().next().unwrap_or_else(|| v.clone()))
        .unwrap_or_default()
}

fn release_templates(preset: &ExportPreset, old: bool) -> Result<Vec<Vec<String>>, String> {
    let mut architecture = option(preset, "binary_format/architecture");
    if architecture.is_empty() {
        architecture = if old && option(preset, "binary_format/64_bits") == "false" {
            "x86_32"
        } else {
            "x86_64"
        }
        .into();
    }
    if !architecture
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_')
    {
        return Err("Invalid preset architecture".into());
    }
    let platform = preset.platform.to_lowercase();
    let file = match platform.as_str() {
        "windows desktop" | "windows" if old => format!("windows_{}_release.exe", if architecture == "x86_32" { "32" } else { "64" }),
        "windows desktop" | "windows" => format!("windows_release_{architecture}.exe"),
        "linux/x11" if old => format!("linux_x11_{}_release", if architecture == "x86_32" { "32" } else { "64" }),
        "linux" | "linux/x11" | "linux/bsd" => format!("linux_release.{architecture}"),
        "mac osx" if old => "osx.zip".into(),
        "macos" | "mac osx" => "macos.zip".into(),
        "android" if option(preset,"gradle_build/use_gradle_build") == "true" || option(preset,"custom_template/use_custom_build") == "true" => "android_source.zip".into(),
        "android" => "android_release.apk".into(),
        "ios" => if old { "iphone.zip" } else { "ios.zip" }.into(),
        "visionos" => "visionos.zip".into(),
        "web" => format!("web{}{}_release.zip", if option(preset,"variant/extensions_support") == "true" { "_dlink" } else { "" }, if option(preset,"variant/thread_support") == "false" { "_nothreads" } else { "" }),
        "html5" => "webassembly_release.zip".into(),
        _ => return Err(format!("Template checks for {} are not available. Configure a custom release template in this preset.", preset.platform)),
    };
    let mut required = vec![vec![file]];
    if !old
        && matches!(platform.as_str(), "windows" | "windows desktop")
        && option(preset, "debug/export_console_wrapper") == "2"
    {
        required.push(vec![format!("windows_release_{architecture}_console.exe")]);
    }
    Ok(required)
}

fn resolve_path(root: &Path, value: &str) -> PathBuf {
    let path = PathBuf::from(value.strip_prefix("res://").unwrap_or(value));
    let path = if path.is_absolute() {
        path
    } else {
        root.join(path)
    };
    let mut normalized = PathBuf::new();
    for part in path.components() {
        match part {
            Component::ParentDir => {
                normalized.pop();
            }
            Component::CurDir => {}
            _ => normalized.push(part.as_os_str()),
        }
    }
    normalized
}

fn check_templates(
    preset: &mut ExportPreset,
    root: &Path,
    version: &InstalledGodotVersion,
    templates: Option<&Path>,
) {
    preset.missing_templates.clear();
    preset.template_error = None;
    let gradle = option(preset, "gradle_build/use_gradle_build") == "true"
        || option(preset, "custom_template/use_custom_build") == "true";
    let groups = release_templates(preset, legacy(version));
    // Godot's platform validation checks BOTH template variants, even for a
    // --export-release invocation. A release executable alone is insufficient.
    for variant in ["debug", "release"] {
        let custom = if gradle {
            String::new()
        } else {
            option(preset, &format!("custom_template/{variant}"))
        };
        if !custom.is_empty() {
            if !resolve_path(root, &custom)
                .metadata()
                .is_ok_and(|m| m.is_file() && m.len() > 0)
            {
                preset.template_error =
                    Some(format!("Custom {variant} template is missing: {custom}"));
            }
            continue;
        }
        match &groups {
            Err(error) => preset.template_error = Some(error.clone()),
            Ok(groups) => {
                for alternatives in groups {
                    let names: Vec<_> = alternatives
                        .iter()
                        .map(|name| {
                            if variant == "debug" {
                                name.replace("release", "debug")
                            } else {
                                name.clone()
                            }
                        })
                        .collect();
                    if !names.iter().any(|name| {
                        templates.is_some_and(|dir| {
                            dir.join(name)
                                .metadata()
                                .is_ok_and(|m| m.is_file() && m.len() > 0)
                        })
                    }) {
                        let missing = names.join(" or ");
                        if !preset.missing_templates.contains(&missing) {
                            preset.missing_templates.push(missing);
                        }
                    }
                }
            }
        }
    }
}

fn read_presets(root: &Path, name: &str) -> Result<Vec<ExportPreset>, String> {
    let path = root.join("export_presets.cfg");
    if !path.exists() {
        return Ok(vec![]);
    }
    let mut text = String::new();
    fs::File::open(path)
        .map_err(|e| e.to_string())?
        .take(8 * 1024 * 1024 + 1)
        .read_to_string(&mut text)
        .map_err(|e| e.to_string())?;
    if text.len() > 8 * 1024 * 1024 {
        return Err("export_presets.cfg is too large".into());
    }
    parse_presets(&text, name)
}

fn project_version(
    app: &AppHandle,
    id: &str,
) -> Result<(Project, Option<InstalledGodotVersion>), String> {
    let project = crate::projects::read_projects(app)
        .into_iter()
        .find(|p| p.id == id)
        .ok_or("Project not found")?;
    let version = crate::godot_versions::list_installed_godot_versions(app.clone())?
        .into_iter()
        .find(|v| v.tag == project.godot_version);
    Ok((project, version))
}

fn catalog_for(
    project: &Project,
    version: Option<&InstalledGodotVersion>,
) -> Result<ExportCatalog, String> {
    let root = Path::new(&project.path);
    if !root.join("project.godot").is_file() {
        return Err("project.godot is missing".into());
    }
    let mut presets = read_presets(root, &project.name)?;
    let engine_error = match version {
        None => Some("The bound Godot version is not installed. Bind an installed engine in the project card.".into()),
        Some(v) if !Path::new(&v.executable_path).is_file() => Some("The bound Godot executable is missing. Locate it in Versions.".into()),
        Some(v) => {
            let templates = crate::export_templates::installed_template_directory(v);
            for preset in &mut presets { check_templates(preset,root,v,templates.as_deref()); }
            None
        }
    };
    Ok(ExportCatalog {
        version_tag: project.godot_version.clone(),
        engine_error,
        presets,
    })
}

fn catalog(app: &AppHandle, id: &str) -> Result<ExportCatalog, String> {
    let (project, version) = project_version(app, id)?;
    catalog_for(&project, version.as_ref())
}

#[tauri::command]
pub async fn get_project_export_presets(
    app: AppHandle,
    id: String,
) -> Result<ExportCatalog, String> {
    tauri::async_runtime::spawn_blocking(move || catalog(&app, &id))
        .await
        .map_err(|e| e.to_string())?
}

fn validate_output(root: &Path, value: &str, overwrite: bool) -> Result<PathBuf, String> {
    if value.trim().is_empty() || value.contains('\0') {
        return Err("Choose an output file".into());
    }
    let requested = resolve_path(root, value.trim());
    if fs::symlink_metadata(&requested).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err("Choose an output file that is not a symbolic link".into());
    }
    // Resolve existing parent links before checking protected folders. Keep
    // missing parents for creation only after every preflight check succeeds.
    let mut ancestor = requested.parent().ok_or("Invalid output path")?;
    while !ancestor.exists() {
        ancestor = ancestor.parent().ok_or("Invalid output folder")?;
    }
    if !ancestor.is_dir() {
        return Err("The output parent is not a folder".into());
    }
    let physical = fs::canonicalize(ancestor).map_err(|e| e.to_string())?;
    let output = physical.join(
        requested
            .strip_prefix(ancestor)
            .map_err(|e| e.to_string())?,
    );
    if output.file_name().is_none()
        || (output.is_dir() && output.extension().is_none_or(|ext| ext != "app"))
    {
        return Err("Choose an output filename, not a folder".into());
    }
    let name = output.file_name().unwrap().to_string_lossy().to_lowercase();
    if ["project.godot","export_presets.cfg","export_credentials.cfg",".godothub.json"].contains(&name.as_str()) || output.components().any(|c| matches!(c,Component::Normal(n) if n.to_string_lossy().eq_ignore_ascii_case(".git") || n.to_string_lossy().eq_ignore_ascii_case(".godot"))) {
        return Err("The export output cannot replace project configuration or editor/Git data".into());
    }
    if output.exists() && !overwrite {
        return Err("OUTPUT_EXISTS: Confirm replacing the existing export file.".into());
    }
    Ok(output)
}

pub(crate) fn cli_preset_names(root: &Path) -> Result<Vec<String>, String> {
    let name = root
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("project");
    Ok(read_presets(root, name)?
        .into_iter()
        .map(|preset| preset.name)
        .collect())
}

pub(crate) fn cli_export_args(root: &Path, preset: &str, output: &Path, old: bool) -> Vec<String> {
    export_args(root, preset, output, old)
}

fn export_args(project: &Path, preset: &str, output: &Path, old: bool) -> Vec<String> {
    vec![
        if old { "--no-window" } else { "--headless" }.into(),
        "--path".into(),
        project.to_string_lossy().into(),
        if old { "--export" } else { "--export-release" }.into(),
        preset.into(),
        output.to_string_lossy().into(),
    ]
}

fn artifact_size(path: &Path) -> Result<Option<u64>, String> {
    let metadata = fs::metadata(path)
        .map_err(|_| "Godot exited successfully but did not create the output file".to_string())?;
    if metadata.is_file() && metadata.len() == 0 {
        return Err("Godot created an empty output file".into());
    }
    if metadata.is_file() {
        return Ok(Some(metadata.len()));
    }
    if !metadata.is_dir() {
        return Err("Godot did not create an output artifact".into());
    }
    let started = std::time::Instant::now();
    let mut pending = vec![path.to_path_buf()];
    let mut count = 0;
    let mut bytes = 0u64;
    while let Some(dir) = pending.pop() {
        let Ok(entries) = fs::read_dir(dir) else {
            return Ok(None);
        };
        for entry in entries {
            count += 1;
            if count > 50_000 || started.elapsed() > Duration::from_secs(3) {
                return Ok(None);
            }
            let Ok(entry) = entry else {
                return Ok(None);
            };
            let Ok(metadata) = entry.path().symlink_metadata() else {
                return Ok(None);
            };
            if metadata.file_type().is_symlink() {
                continue;
            }
            if metadata.is_dir() {
                pending.push(entry.path());
            } else if metadata.is_file() {
                bytes = bytes.saturating_add(metadata.len());
            }
        }
    }
    if bytes == 0 {
        return Err("Godot created an empty output bundle".into());
    }
    Ok(Some(bytes))
}

struct ProcessOutcome {
    code: Option<i32>,
    cancelled: bool,
    error: Option<String>,
}

fn file_stamp(path: &Path) -> Option<(u64, std::time::SystemTime)> {
    let metadata = path.metadata().ok()?;
    if !metadata.is_file() {
        return None;
    }
    Some((metadata.len(), metadata.modified().ok()?))
}

fn completed_artifact(
    path: &Path,
    previous: Option<(u64, std::time::SystemTime)>,
) -> Result<Option<u64>, String> {
    if previous.is_some() && previous == file_stamp(path) {
        return Err(
            "Godot exited without updating the existing output file. See the export log.".into(),
        );
    }
    artifact_size(path)
}

fn wait_for_export(
    child: &mut std::process::Child,
    cancel: &AtomicBool,
    mut drain: impl FnMut(),
) -> ProcessOutcome {
    loop {
        drain();
        match child.try_wait() {
            Ok(Some(status)) => {
                return ProcessOutcome {
                    code: status.code(),
                    cancelled: false,
                    error: None,
                }
            }
            Err(error) => {
                let _ = child.kill();
                let _ = child.wait();
                return ProcessOutcome {
                    code: None,
                    cancelled: false,
                    error: Some(error.to_string()),
                };
            }
            Ok(None) => {}
        }
        if cancel.load(Ordering::Relaxed) {
            #[cfg(windows)]
            {
                use std::os::windows::process::CommandExt;
                let _ = std::process::Command::new("taskkill")
                    .args(["/F", "/T", "/PID", &child.id().to_string()])
                    .creation_flags(crate::terminal::CREATE_NO_WINDOW)
                    .stdout(std::process::Stdio::null())
                    .stderr(std::process::Stdio::null())
                    .status();
            }
            #[cfg(unix)]
            {
                let _ = std::process::Command::new("kill")
                    .args(["-KILL", "--", &format!("-{}", child.id())])
                    .stdout(std::process::Stdio::null())
                    .stderr(std::process::Stdio::null())
                    .status();
            }
            let _ = child.kill();
            let result = child.wait();
            return ProcessOutcome {
                code: result.as_ref().ok().and_then(|status| status.code()),
                cancelled: true,
                error: result.err().map(|e| e.to_string()),
            };
        }
        std::thread::sleep(Duration::from_millis(100));
    }
}

fn start(
    app: AppHandle,
    id: String,
    preset_id: u32,
    output_path: String,
    overwrite: bool,
) -> Result<ExportRun, String> {
    let workspace = crate::workspace::active_workspace_dir(&app);
    let (project, version) = project_version(&app, &id)?;
    let version = version.ok_or("The bound Godot version is not installed")?;
    let root = fs::canonicalize(&project.path).map_err(|e| e.to_string())?;
    let catalog = catalog_for(&project, Some(&version))?;
    if let Some(error) = catalog.engine_error {
        return Err(error);
    }
    let preset = catalog
        .presets
        .into_iter()
        .find(|p| p.id == preset_id)
        .ok_or("Export preset no longer exists. Refresh the preset list.")?;
    if let Some(error) = &preset.template_error {
        return Err(error.clone());
    }
    if !preset.missing_templates.is_empty() {
        return Err(format!(
            "INSTALL_EXPORT_TEMPLATES: Missing export templates for {}: {}",
            version.tag,
            preset.missing_templates.join(", ")
        ));
    }
    let output = validate_output(&root, &output_path, overwrite)?;
    let previous_artifact = file_stamp(&output);
    if crate::workspace::active_workspace_dir(&app) != workspace {
        return Err("Workspace changed. Open the export dialog again.".into());
    }
    let store = app.state::<ExportRuns>().0.clone();
    let cancel = Arc::new(AtomicBool::new(false));
    let run = ExportRun {
        id: format!("export-{}", uuid::Uuid::new_v4()),
        project_id: id,
        project_name: project.name,
        preset_name: preset.name.clone(),
        output_path: output.to_string_lossy().into(),
        status: "running".into(),
        size_bytes: None,
        exit_code: None,
        error: None,
        started_at_ms: crate::projects::epoch_ms(),
    };
    {
        let mut jobs = store.lock().unwrap();
        if jobs
            .values()
            .any(|j| j.root == root && j.run.status == "running")
        {
            return Err(
                "This project already has an export running. Open its console to follow it.".into(),
            );
        }
        if jobs.len() >= 40 {
            if let Some(oldest) = jobs
                .iter()
                .filter(|(_, j)| j.run.status != "running")
                .min_by_key(|(_, j)| j.run.started_at_ms)
                .map(|(k, _)| k.clone())
            {
                jobs.remove(&oldest);
                crate::console::forget_console(&app, &oldest);
            }
        }
        jobs.insert(
            run.id.clone(),
            Job {
                run: run.clone(),
                workspace: workspace.clone(),
                root: root.clone(),
                cancel: cancel.clone(),
            },
        );
    }
    let spawned = (|| {
        fs::create_dir_all(output.parent().ok_or("Invalid output folder")?)
            .map_err(|e| e.to_string())?;
        let args = export_args(&root, &preset.name, &output, legacy(&version));
        crate::console::spawn_job_console(
            &app,
            Path::new(&version.executable_path),
            &args,
            &root,
            &workspace,
            &run.id,
        )
    })();
    let (mut child, mut console) = match spawned {
        Ok(result) => result,
        Err(error) => {
            store.lock().unwrap().remove(&run.id);
            return Err(error);
        }
    };
    let _ = app.emit("export:started", &run);
    let returned = run.clone();
    std::thread::spawn(move || {
        let mut completed = run;
        let outcome = wait_for_export(&mut child, &cancel, || console.drain());
        completed.exit_code = outcome.code;
        completed.error = outcome.error;
        // Include final stdout/stderr before marking the console complete.
        console.drain();
        completed.status = if outcome.cancelled {
            "cancelled"
        } else if completed.exit_code == Some(0) && completed.error.is_none() {
            match completed_artifact(&output, previous_artifact) {
                Ok(size) => {
                    completed.size_bytes = size;
                    "succeeded"
                }
                Err(error) => {
                    completed.error = Some(error);
                    "failed"
                }
            }
        } else {
            "failed"
        }
        .into();
        let message = match completed.status.as_str() {
            "succeeded" => match completed.size_bytes {
                Some(size) => format!(
                    "Export complete: {} ({} bytes)",
                    completed.output_path, size
                ),
                None => format!(
                    "Export complete: {} (size unavailable)",
                    completed.output_path
                ),
            },
            "cancelled" => {
                "Export cancelled. Partial output may remain in the output folder.".into()
            }
            _ => completed.error.clone().unwrap_or_else(|| {
                format!(
                    "Export failed (exit code {}). See Godot output above.",
                    completed
                        .exit_code
                        .map(|n| n.to_string())
                        .unwrap_or_else(|| "unknown".into())
                )
            }),
        };
        if completed.status == "failed" && completed.error.is_none() {
            completed.error = Some(message.clone());
        }
        console.finish(&app, completed.exit_code, &message);
        if let Some(job) = store.lock().unwrap().get_mut(&completed.id) {
            job.run = completed.clone();
        }
        let _ = app.emit("export:finished", completed);
    });
    Ok(returned)
}

#[tauri::command]
pub async fn start_project_export(
    app: AppHandle,
    id: String,
    preset_id: u32,
    output_path: String,
    overwrite: bool,
) -> Result<ExportRun, String> {
    tauri::async_runtime::spawn_blocking(move || start(app, id, preset_id, output_path, overwrite))
        .await
        .map_err(|e| e.to_string())?
}

#[tauri::command]
pub fn get_project_export(app: AppHandle, run_id: String) -> Result<ExportRun, String> {
    let state = app.state::<ExportRuns>();
    let jobs = state.0.lock().unwrap();
    jobs.get(&run_id)
        .map(|j| j.run.clone())
        .ok_or_else(|| "Export run not found".into())
}

#[tauri::command]
pub fn get_project_exports(app: AppHandle, id: String) -> Vec<ExportRun> {
    let workspace = crate::workspace::active_workspace_dir(&app);
    let mut runs: Vec<_> = app
        .state::<ExportRuns>()
        .0
        .lock()
        .unwrap()
        .values()
        .filter(|j| j.workspace == workspace && j.run.project_id == id)
        .map(|j| j.run.clone())
        .collect();
    runs.sort_by_key(|run| std::cmp::Reverse(run.started_at_ms));
    runs
}

#[tauri::command]
pub fn cancel_project_export(app: AppHandle, run_id: String) -> Result<(), String> {
    get_project_export(app.clone(), run_id.clone())?;
    if let Some(job) = app.state::<ExportRuns>().0.lock().unwrap().get(&run_id) {
        job.cancel.store(true, Ordering::Relaxed);
    }
    Ok(())
}

#[tauri::command]
pub fn open_export_artifact_folder(app: AppHandle, run_id: String) -> Result<(), String> {
    let run = get_project_export(app, run_id)?;
    if run.status != "succeeded" {
        return Err("No successful export artifact is available".into());
    }
    let path = Path::new(&run.output_path);
    if !path.exists() {
        return Err("The export artifact has been moved or deleted".into());
    }
    crate::projects::open_project_folder(
        path.parent()
            .ok_or("Invalid artifact path")?
            .to_string_lossy()
            .into(),
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    struct Fixture(PathBuf);
    impl Fixture {
        fn new() -> Self {
            let p =
                std::env::temp_dir().join(format!("godothub-export-test-{}", uuid::Uuid::new_v4()));
            fs::create_dir_all(&p).unwrap();
            Self(p)
        }
        fn write(&self, name: &str, bytes: &[u8]) {
            let p = self.0.join(name);
            fs::create_dir_all(p.parent().unwrap()).unwrap();
            fs::write(p, bytes).unwrap();
        }
    }
    impl Drop for Fixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }
    fn version() -> InstalledGodotVersion {
        InstalledGodotVersion {
            tag: "4.5-stable".into(),
            version: "4.5".into(),
            executable_path: "godot".into(),
            is_mono: false,
            installed_at: String::new(),
            custom_name: None,
            install_root: None,
            supports_console: true,
            managed_by: None,
        }
    }
    fn preset(platform: &str) -> ExportPreset {
        parse_presets(&format!("[preset.0]\nname=\"Release\"\nplatform={platform:?}\n[preset.0.options]\nbinary_format/architecture=\"arm64\"\n"),"Game").unwrap().remove(0)
    }

    #[test]
    fn parses_names_paths_comments_and_noncontiguous_presets_without_options_as_presets() {
        let text="\u{feff}[preset.2]\nname=\"Windows \\\"Shipping\\\"; #1\" ; comment\nplatform=\"Windows Desktop\"\nexport_path=\"../build/My Game.exe\"\n[preset.2.options]\ncustom_features=PackedStringArray(\n\"a\", \"b\"\n)\n[preset.9]\nname=\"Web\"\nplatform=\"Web\"\n";
        let presets = parse_presets(text, "My Game").unwrap();
        assert_eq!(presets.len(), 2);
        assert_eq!(presets[0].id, 2);
        assert_eq!(presets[0].name, "Windows \"Shipping\"; #1");
        assert_eq!(presets[0].output_path, "../build/My Game.exe");
        assert_eq!(presets[1].output_path, "builds/Web/My_Game.html");
    }
    #[test]
    fn rejects_ambiguous_preset_names_and_duplicate_settings() {
        assert!(parse_presets(
            "[preset.0]\nname=\"Same\"\n[preset.1]\nname=\"Same\"\n",
            "Game"
        )
        .is_err());
        assert!(parse_presets("[preset.0]\nname=\"First\"\nname=\"Other\"\n", "Game").is_err());
    }
    #[test]
    fn unrelated_debug_or_architecture_templates_do_not_pass_release_preflight() {
        let f = Fixture::new();
        f.write("windows_debug_arm64.exe", b"debug");
        f.write("windows_release_x86_64.exe", b"release");
        let mut p = preset("Windows Desktop");
        check_templates(&mut p, &f.0, &version(), Some(&f.0));
        assert_eq!(p.missing_templates, vec!["windows_release_arm64.exe"]);
        f.write("windows_release_arm64.exe", b"release");
        let mut p = preset("Windows Desktop");
        check_templates(&mut p, &f.0, &version(), Some(&f.0));
        assert!(p.missing_templates.is_empty());
    }
    #[test]
    fn custom_release_template_is_checked_on_disk_and_bypasses_official_template() {
        let f = Fixture::new();
        let mut p = preset("Windows Desktop");
        p.options.insert(
            "custom_template/release".into(),
            "\"res://custom.exe\"".into(),
        );
        p.options.insert(
            "custom_template/debug".into(),
            "\"res://custom.exe\"".into(),
        );
        check_templates(&mut p, &f.0, &version(), None);
        assert!(p.template_error.is_some());
        f.write("custom.exe", b"custom engine");
        p.template_error = None;
        check_templates(&mut p, &f.0, &version(), None);
        assert!(p.template_error.is_none());
        assert!(p.missing_templates.is_empty());
    }
    #[test]
    fn selects_web_extension_thread_variant_and_android_gradle_sources() {
        let mut p = preset("Web");
        p.options
            .insert("variant/extensions_support".into(), "true".into());
        p.options
            .insert("variant/thread_support".into(), "false".into());
        assert_eq!(
            release_templates(&p, false).unwrap()[0],
            vec!["web_dlink_nothreads_release.zip"]
        );
        let mut p = preset("Android");
        p.options
            .insert("gradle_build/use_gradle_build".into(), "true".into());
        assert_eq!(
            release_templates(&p, false).unwrap()[0],
            vec!["android_source.zip"]
        );
    }
    #[test]
    fn command_arguments_preserve_spaces_and_shell_characters_and_support_legacy_flags() {
        let args = export_args(
            Path::new("project with spaces"),
            "Windows \"Release\"; $HOME",
            Path::new("out/game.exe"),
            false,
        );
        assert_eq!(
            args,
            vec![
                "--headless",
                "--path",
                "project with spaces",
                "--export-release",
                "Windows \"Release\"; $HOME",
                "out/game.exe"
            ]
        );
        let args = export_args(Path::new("proj"), "Legacy", Path::new("game.exe"), true);
        assert_eq!(args[0], "--no-window");
        assert_eq!(args[3], "--export");
    }
    #[test]
    fn output_requires_confirmation_and_cannot_replace_configuration_or_git_data() {
        let f = Fixture::new();
        f.write("project.godot", b"config");
        f.write("builds/game.exe", b"old build");
        assert!(validate_output(&f.0, "project.godot", true).is_err());
        assert!(validate_output(&f.0, "builds/../.git/config", true).is_err());
        assert!(validate_output(&f.0, ".godot/export.bin", true).is_err());
        assert!(validate_output(&f.0, "builds/game.exe", false)
            .unwrap_err()
            .starts_with("OUTPUT_EXISTS:"));
        assert!(validate_output(&f.0, "builds/game.exe", true)
            .unwrap()
            .ends_with("builds/game.exe"));
        assert!(validate_output(&f.0, "builds/new/deep/game.exe", false).is_ok());
        assert!(!f.0.join("builds/new").exists());
        assert_eq!(fs::read(f.0.join("project.godot")).unwrap(), b"config");
    }
    #[test]
    fn artifact_size_requires_a_real_output_file() {
        let f = Fixture::new();
        assert!(artifact_size(&f.0.join("missing.exe")).is_err());
        assert!(artifact_size(&f.0).is_err());
        f.write("build/game.exe", b"artifact bytes");
        assert_eq!(
            artifact_size(&f.0.join("build/game.exe")).unwrap(),
            Some(14)
        );
    }

    // Child fixture used by the same production wait/drain/cancel loop. It is
    // explicitly ignored in the parent test run and writes only into a fixture.
    #[test]
    #[ignore]
    fn fake_engine_child() {
        println!("Export started");
        std::io::stdout().flush().unwrap();
        eprintln!("SDK output on stderr");
        std::thread::sleep(Duration::from_millis(
            std::env::var("EXPORT_TEST_DELAY").unwrap().parse().unwrap(),
        ));
        let code: i32 = std::env::var("EXPORT_TEST_EXIT").unwrap().parse().unwrap();
        if code == 0 {
            fs::write(
                std::env::var("EXPORT_TEST_OUTPUT").unwrap(),
                b"export artifact",
            )
            .unwrap();
        }
        std::process::exit(code);
    }
    fn child(f: &Fixture, delay: u64, code: i32) -> std::process::Child {
        let log = fs::File::create(f.0.join("console.log")).unwrap();
        let mut command = std::process::Command::new(std::env::current_exe().unwrap());
        command
            .args([
                "--exact",
                "export_runner::tests::fake_engine_child",
                "--ignored",
                "--nocapture",
            ])
            .env("EXPORT_TEST_DELAY", delay.to_string())
            .env("EXPORT_TEST_EXIT", code.to_string())
            .env("EXPORT_TEST_OUTPUT", f.0.join("game.exe"))
            .stdout(std::process::Stdio::from(log.try_clone().unwrap()))
            .stderr(std::process::Stdio::from(log));
        #[cfg(unix)]
        {
            use std::os::unix::process::CommandExt;
            command.process_group(0);
        }
        command.spawn().unwrap()
    }
    #[test]
    fn process_output_is_available_before_completion_and_artifact_size_is_reported() {
        let f = Fixture::new();
        let mut process = child(&f, 700, 0);
        let cancel = AtomicBool::new(false);
        let mut streaming = false;
        let outcome = wait_for_export(&mut process, &cancel, || {
            let log = fs::read_to_string(f.0.join("console.log")).unwrap_or_default();
            if log.contains("Export started") && !f.0.join("game.exe").exists() {
                streaming = true;
            }
        });
        assert!(streaming);
        assert_eq!(outcome.code, Some(0));
        assert!(!outcome.cancelled);
        assert!(fs::read_to_string(f.0.join("console.log"))
            .unwrap()
            .contains("SDK output on stderr"));
        assert_eq!(artifact_size(&f.0.join("game.exe")).unwrap(), Some(15));
    }
    #[test]
    fn failed_process_preserves_exit_code_and_has_no_artifact() {
        let f = Fixture::new();
        let mut process = child(&f, 50, 7);
        let outcome = wait_for_export(&mut process, &AtomicBool::new(false), || {});
        assert_eq!(outcome.code, Some(7));
        assert!(!f.0.join("game.exe").exists());
    }
    #[test]
    fn cancellation_stops_only_the_owned_child_and_reaps_it() {
        let f = Fixture::new();
        let mut process = child(&f, 30000, 0);
        let unrelated = Fixture::new();
        let mut other = child(&unrelated, 5000, 0);
        let cancel = AtomicBool::new(false);
        let mut polls = 0;
        let outcome = wait_for_export(&mut process, &cancel, || {
            polls += 1;
            if polls >= 2 {
                cancel.store(true, Ordering::Relaxed);
            }
        });
        let other_alive = other.try_wait().unwrap().is_none();
        let _ = other.kill();
        let _ = other.wait();
        assert!(other_alive);
        assert!(outcome.cancelled);
        assert!(process.try_wait().unwrap().is_some());
        assert!(!f.0.join("game.exe").exists());
    }

    #[test]
    fn release_only_install_is_not_enough_for_godot_platform_validation() {
        let f = Fixture::new();
        f.write("windows_release_arm64.exe", b"release");
        let mut p = preset("Windows Desktop");
        check_templates(&mut p, &f.0, &version(), Some(&f.0));
        assert_eq!(p.missing_templates, vec!["windows_debug_arm64.exe"]);
    }
    #[test]
    fn old_or_empty_artifacts_are_not_reported_as_successful() {
        let f = Fixture::new();
        f.write("game.exe", b"old");
        let file = f.0.join("game.exe");
        let before = file_stamp(&file);
        assert!(completed_artifact(&file, before).is_err());
        f.write("game.exe", b"new artifact");
        assert_eq!(completed_artifact(&file, before).unwrap(), Some(12));
        f.write("empty.exe", b"");
        assert!(artifact_size(&f.0.join("empty.exe")).is_err());
    }
    #[test]
    fn application_bundle_size_includes_nested_files() {
        let f = Fixture::new();
        f.write("Game.app/Contents/MacOS/Game", b"game");
        f.write("Game.app/Contents/Resources/game.pck", b"pack");
        assert_eq!(artifact_size(&f.0.join("Game.app")).unwrap(), Some(8));
    }
}
