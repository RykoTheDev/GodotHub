use crate::models::InstalledGodotVersion;
use serde::Serialize;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use crate::AppHandle;

const CONSOLE_PREFIX: &str = "tool:";
const SKIPPED_DIRS: &[&str] = &["addons", ".godot", ".import", ".git"];

#[derive(Serialize)]
pub struct ProjectTool {
    pub id: String,
    pub kind: String,
    pub available: bool,
    pub reason: Option<String>,
    pub detail: Option<String>,
}

fn running() -> &'static Mutex<HashMap<String, Arc<AtomicBool>>> {
    static RUNNING: OnceLock<Mutex<HashMap<String, Arc<AtomicBool>>>> = OnceLock::new();
    RUNNING.get_or_init(|| Mutex::new(HashMap::new()))
}

fn find_on_path(name: &str) -> Option<PathBuf> {
    let binary = if cfg!(windows) {
        format!("{name}.exe")
    } else {
        name.to_string()
    };
    std::env::split_paths(&std::env::var_os("PATH")?)
        .map(|dir| dir.join(&binary))
        .find(|candidate| candidate.is_file())
}

fn gdunit_test_dir(root: &Path) -> Option<&'static str> {
    ["test", "tests"].into_iter().find(|dir| root.join(dir).is_dir())
}

fn lint_targets(root: &Path, config_names: &[&str]) -> Vec<String> {
    if config_names.iter().any(|name| root.join(name).is_file()) {
        return vec![".".into()];
    }
    let Ok(entries) = fs::read_dir(root) else {
        return vec![];
    };
    let mut targets: Vec<String> = entries
        .flatten()
        .filter_map(|entry| {
            let name = entry.file_name().to_string_lossy().to_string();
            if name.starts_with('.') || SKIPPED_DIRS.contains(&name.as_str()) {
                return None;
            }
            let kind = entry.file_type().ok()?;
            if kind.is_dir() || (kind.is_file() && name.ends_with(".gd")) {
                Some(name)
            } else {
                None
            }
        })
        .collect();
    targets.sort();
    targets
}

fn tool(id: &str, kind: &str, reason: Option<&str>, detail: Option<String>) -> ProjectTool {
    ProjectTool {
        id: id.into(),
        kind: kind.into(),
        available: reason.is_none(),
        reason: reason.map(str::to_string),
        detail,
    }
}

fn detect(root: &Path, engine: Option<&InstalledGodotVersion>) -> Vec<ProjectTool> {
    let engine_reason = match engine {
        None => Some("engine_missing"),
        Some(v) if !Path::new(&v.executable_path).is_file() => Some("engine_missing"),
        Some(_) => None,
    };
    let mut tools = vec![];
    if root.join("addons/gut/gut_cmdln.gd").is_file() {
        tools.push(tool("gut", "test", engine_reason, None));
    }
    if root.join("addons/gdUnit4/bin/GdUnitCmdTool.gd").is_file() {
        let dir = gdunit_test_dir(root);
        let reason = engine_reason.or(if dir.is_none() { Some("no_test_folder") } else { None });
        tools.push(tool("gdunit", "test", reason, dir.map(|d| format!("res://{d}"))));
    }
    for (id, configs) in [
        ("gdlint", &["gdlintrc", ".gdlintrc"][..]),
        ("gdformat", &["gdformatrc", ".gdformatrc"][..]),
    ] {
        let found = find_on_path(id);
        tools.push(tool(
            id,
            "lint",
            if found.is_none() { Some("not_installed") } else { None },
            found.map(|_| lint_targets(root, configs).join(" ")),
        ));
    }
    tools
}

fn project_and_engine(
    app: &AppHandle,
    id: &str,
) -> Result<(crate::models::Project, Option<InstalledGodotVersion>), String> {
    let project = crate::projects::read_projects(app)
        .into_iter()
        .find(|p| p.id == id)
        .ok_or("Project is no longer registered")?;
    let engine = crate::godot_versions::read_registry(app)
        .into_iter()
        .find(|v| v.tag == project.godot_version);
    Ok((project, engine))
}

pub async fn list_project_tools(app: AppHandle, id: String) -> Result<Vec<ProjectTool>, String> {
    tokio::task::spawn_blocking(move || {
        let (project, engine) = project_and_engine(&app, &id)?;
        Ok(detect(Path::new(&project.path), engine.as_ref()))
    })
    .await
    .map_err(|e| e.to_string())?
}

fn godot_args(root: &Path, engine: &InstalledGodotVersion, script: &str, extra: &[&str]) -> Vec<String> {
    let mut args = vec![];
    if !crate::export_runner::legacy(engine) {
        args.push("--headless".into());
    }
    args.push("--path".into());
    args.push(root.display().to_string());
    args.push("-s".into());
    args.push(script.into());
    args.extend(extra.iter().map(|a| a.to_string()));
    args
}

fn start(app: AppHandle, id: String, tool_id: String) -> Result<String, String> {
    let (project, engine) = project_and_engine(&app, &id)?;
    let root = PathBuf::from(&project.path);
    let detected = detect(&root, engine.as_ref());
    let found = detected
        .iter()
        .find(|t| t.id == tool_id)
        .ok_or("This tool is not set up for the project")?;
    if let Some(reason) = &found.reason {
        return Err(match reason.as_str() {
            "engine_missing" => "Install the project's Godot version before running tests".into(),
            "no_test_folder" => "gdUnit4 needs a test or tests folder in the project".into(),
            _ => format!("{tool_id} is not installed or not on PATH"),
        });
    }
    let console_id = format!("{CONSOLE_PREFIX}{}:{tool_id}", project.id);
    let cancel = Arc::new(AtomicBool::new(false));
    {
        let mut active = running().lock().unwrap_or_else(std::sync::PoisonError::into_inner);
        if active.contains_key(&console_id) {
            return Err("This tool is already running".into());
        }
        active.insert(console_id.clone(), cancel.clone());
    }
    let workspace = crate::workspace::active_workspace_dir(&app);
    let spawned = match tool_id.as_str() {
        "gut" | "gdunit" => {
            let engine = engine.as_ref().ok_or("Install the project's Godot version first")?;
            let args = if tool_id == "gut" {
                godot_args(&root, engine, "res://addons/gut/gut_cmdln.gd", &["-gexit"])
            } else {
                let dir = found.detail.clone().unwrap_or_else(|| "res://test".into());
                godot_args(
                    &root,
                    engine,
                    "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
                    &["-a", &dir, "--ignoreHeadlessMode"],
                )
            };
            crate::console::spawn_job_console(
                &app,
                Path::new(&engine.executable_path),
                &args,
                &root,
                &workspace,
                &console_id,
            )
        }
        _ => {
            let program = find_on_path(&tool_id).ok_or("The tool is no longer on PATH")?;
            let configs: &[&str] = if tool_id == "gdlint" {
                &["gdlintrc", ".gdlintrc"]
            } else {
                &["gdformatrc", ".gdformatrc"]
            };
            let mut args: Vec<String> = if tool_id == "gdformat" {
                vec!["--check".into()]
            } else {
                vec![]
            };
            let targets = lint_targets(&root, configs);
            if targets.is_empty() {
                Err("No GDScript folders were found outside addons".to_string())
            } else {
                args.extend(targets);
                crate::console::spawn_job_program(&app, &program, &args, &root, &workspace, &console_id)
            }
        }
    };
    let (mut child, mut console) = match spawned {
        Ok(result) => result,
        Err(error) => {
            running().lock().unwrap_or_else(std::sync::PoisonError::into_inner).remove(&console_id);
            return Err(error);
        }
    };
    let label = match tool_id.as_str() {
        "gut" => "GUT tests",
        "gdunit" => "gdUnit4 tests",
        "gdlint" => "gdlint",
        _ => "gdformat check",
    };
    let finished_id = console_id.clone();
    std::thread::spawn(move || {
        let outcome = crate::export_runner::wait_for_export(&mut child, &cancel, || console.drain());
        let message = if outcome.cancelled {
            format!("[GodotHub] {label} stopped.")
        } else if let Some(error) = outcome.error {
            format!("[GodotHub] {label} could not finish: {error}")
        } else if outcome.code == Some(0) {
            format!("[GodotHub] {label} passed.")
        } else {
            format!(
                "[GodotHub] {label} failed (exit code {}).",
                outcome.code.map_or_else(|| "unknown".into(), |c| c.to_string())
            )
        };
        console.finish(&app, outcome.code, &message);
        running().lock().unwrap_or_else(std::sync::PoisonError::into_inner).remove(&finished_id);
    });
    Ok(console_id)
}

pub async fn run_project_tool(app: AppHandle, id: String, tool: String) -> Result<String, String> {
    tokio::task::spawn_blocking(move || start(app, id, tool))
        .await
        .map_err(|e| e.to_string())?
}

pub fn stop_project_tool(console_id: String) -> Result<(), String> {
    let active = running().lock().unwrap_or_else(std::sync::PoisonError::into_inner);
    let cancel = active.get(&console_id).ok_or("This tool is not running")?;
    cancel.store(true, Ordering::Relaxed);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fixture(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("godothub-tools-{name}-{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn lint_targets_skip_addons_and_engine_folders() {
        let root = fixture("targets");
        for dir in ["addons", ".godot", "scripts", "scenes"] {
            fs::create_dir_all(root.join(dir)).unwrap();
        }
        fs::write(root.join("main.gd"), "").unwrap();
        fs::write(root.join("project.godot"), "").unwrap();
        assert_eq!(lint_targets(&root, &["gdlintrc"]), vec!["main.gd", "scenes", "scripts"]);
        fs::write(root.join("gdlintrc"), "").unwrap();
        assert_eq!(lint_targets(&root, &["gdlintrc"]), vec!["."]);
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn detects_test_addons_and_missing_engine() {
        let root = fixture("detect");
        fs::create_dir_all(root.join("addons/gut")).unwrap();
        fs::write(root.join("addons/gut/gut_cmdln.gd"), "").unwrap();
        fs::create_dir_all(root.join("addons/gdUnit4/bin")).unwrap();
        fs::write(root.join("addons/gdUnit4/bin/GdUnitCmdTool.gd"), "").unwrap();
        let tools = detect(&root, None);
        let gut = tools.iter().find(|t| t.id == "gut").unwrap();
        assert_eq!(gut.reason.as_deref(), Some("engine_missing"));
        let gdunit = tools.iter().find(|t| t.id == "gdunit").unwrap();
        assert!(!gdunit.available);
        let _ = fs::remove_dir_all(&root);
    }
}
