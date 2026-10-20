use std::cell::Cell;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;

use clap::{Parser, Subcommand};

use crate::resolve::{self, EngineSource};

#[derive(Parser, Debug)]
#[command(
    name = "godothub",
    version,
    about = "GodotHub: Godot version and project management",
    disable_help_subcommand = false
)]
pub struct Cli {
    #[arg(long, global = true)]
    pub console: bool,

    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand, Debug)]
pub enum Commands {
    Open {
        name: String,
    },
    Run {
        #[arg(long)]
        path: Option<PathBuf>,
    },
    Versions,
    Install {
        version: String,
        #[arg(long)]
        mono: bool,
    },
    Export {
        preset: Option<String>,
        #[arg(long, short)]
        output: Option<PathBuf>,
        #[arg(long)]
        path: Option<PathBuf>,
        #[arg(long)]
        overwrite: bool,
    },
    Doctor {
        #[arg(long)]
        json: bool,
        #[arg(long)]
        path: Option<PathBuf>,
    },
}

const SUBCOMMANDS: [&str; 7] = [
    "open", "run", "versions", "install", "export", "doctor", "help",
];

fn looks_like_cli(args: &[String]) -> bool {
    args.iter().any(|arg| {
        SUBCOMMANDS.contains(&arg.as_str())
            || matches!(arg.as_str(), "-h" | "--help" | "-V" | "--version")
    })
}

pub fn dispatch() -> Option<i32> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if !looks_like_cli(&args) {
        return None;
    }
    attach_console();
    match Cli::try_parse() {
        Ok(cli) => Some(cli.command.map(run).unwrap_or(0)),
        Err(err) => {
            let _ = err.print();
            Some(if err.use_stderr() { 2 } else { 0 })
        }
    }
}

#[cfg(windows)]
fn attach_console() {
    use windows_sys::Win32::System::Console::{AttachConsole, ATTACH_PARENT_PROCESS};
    unsafe {
        AttachConsole(ATTACH_PARENT_PROCESS);
    }
}

#[cfg(not(windows))]
fn attach_console() {}

fn run(command: Commands) -> i32 {
    let result = match command {
        Commands::Versions => cmd_versions(),
        Commands::Open { name } => cmd_open(&name),
        Commands::Run { path } => cmd_run(path),
        Commands::Install { version, mono } => cmd_install(&version, mono),
        Commands::Export {
            preset,
            output,
            path,
            overwrite,
        } => cmd_export(preset, output, path, overwrite),
        Commands::Doctor { json, path } => cmd_doctor(json, path),
    };
    match result {
        Ok(code) => code,
        Err(message) => {
            eprintln!("error: {message}");
            1
        }
    }
}

fn base_dir() -> Result<PathBuf, String> {
    resolve::data_dir().ok_or_else(|| "Could not determine the GodotHub data directory".to_string())
}

fn project_root_from(path: Option<PathBuf>) -> Result<PathBuf, String> {
    let start = match path {
        Some(path) => path,
        None => std::env::current_dir().map_err(|e| e.to_string())?,
    };
    let start = std::fs::canonicalize(&start).unwrap_or(start);
    resolve::find_project_root(&start).ok_or_else(|| {
        "No Godot project here: project.godot was not found in this or any parent directory."
            .to_string()
    })
}

fn source_label(source: EngineSource) -> &'static str {
    match source {
        EngineSource::Pin => "project pin",
        EngineSource::Bound => "app binding",
        EngineSource::Current => "current version",
    }
}

fn cmd_versions() -> Result<i32, String> {
    let base = base_dir()?;
    let list = resolve::installed_sorted(&base);
    if list.is_empty() {
        println!("No Godot versions are installed. Use `godothub install <version>`.");
        return Ok(0);
    }
    let current = crate::current_version::read_current_tag_at(&base);
    for version in &list {
        let marker = if current.as_deref() == Some(version.tag.as_str()) {
            "*"
        } else {
            " "
        };
        let mono = if version.is_mono { " (mono)" } else { "" };
        println!("{marker} {}{}\t{}", version.tag, mono, version.executable_path);
    }
    if current.is_some() {
        println!("\n* = current version");
    }
    Ok(0)
}

fn cmd_open(name: &str) -> Result<i32, String> {
    let base = base_dir()?;
    let workspace = resolve::active_workspace_dir(&base);
    let projects = crate::projects::read_projects_from(&workspace);
    let project = projects
        .iter()
        .find(|project| project.name.eq_ignore_ascii_case(name))
        .ok_or_else(|| format!("No registered project named {name:?}."))?;
    let root = PathBuf::from(&project.path);
    let engine = resolve::resolve_engine(&base, &workspace, &root)?;

    let mut args = vec!["--path".to_string(), project.path.clone(), "-e".to_string()];
    args.extend(
        project
            .launch_arguments
            .split_whitespace()
            .map(str::to_string),
    );
    spawn_detached(&engine.executable_path, &args)?;
    println!(
        "Opening {} in Godot {} (via {}).",
        project.name,
        engine.tag,
        source_label(engine.source)
    );
    Ok(0)
}

fn cmd_run(path: Option<PathBuf>) -> Result<i32, String> {
    let base = base_dir()?;
    let workspace = resolve::active_workspace_dir(&base);
    let root = project_root_from(path)?;
    let engine = resolve::resolve_engine(&base, &workspace, &root)?;

    eprintln!(
        "Running {} with Godot {} (via {}).",
        root.display(),
        engine.tag,
        source_label(engine.source)
    );
    let status = Command::new(&engine.executable_path)
        .arg("--path")
        .arg(&root)
        .status()
        .map_err(|e| format!("Failed to launch Godot: {e}"))?;
    Ok(status.code().unwrap_or(1))
}

fn cmd_install(version: &str, mono: bool) -> Result<i32, String> {
    let base = base_dir()?;
    let workspace = resolve::active_workspace_dir(&base);
    let settings = crate::settings::read_settings_from(&workspace);
    let versions_dir = match settings.download_dir {
        Some(dir) if !dir.trim().is_empty() => PathBuf::from(dir),
        _ => base.join("godot-versions"),
    };
    let token = settings
        .github_token
        .filter(|token| !token.trim().is_empty())
        .or_else(|| std::env::var("GITHUB_TOKEN").ok())
        .or_else(|| std::env::var("GH_TOKEN").ok())
        .filter(|token| !token.trim().is_empty());

    let last_pct = Cell::new(u64::MAX);
    let progress = |downloaded: u64, total: u64| {
        if total == 0 {
            return;
        }
        let pct = downloaded.saturating_mul(100) / total;
        if pct != last_pct.get() {
            last_pct.set(pct);
            eprint!("\rDownloading {version}... {pct}%");
            let _ = std::io::stderr().flush();
            if downloaded >= total {
                eprintln!();
            }
        }
    };

    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(|e| e.to_string())?;
    let installed = runtime.block_on(crate::godot_versions::install_version_headless(
        &base,
        &versions_dir,
        token,
        version,
        mono,
        progress,
    ))?;
    println!(
        "Installed Godot {} at {}",
        installed.tag, installed.executable_path
    );
    Ok(0)
}

fn cmd_export(
    preset: Option<String>,
    output: Option<PathBuf>,
    path: Option<PathBuf>,
    overwrite: bool,
) -> Result<i32, String> {
    let base = base_dir()?;
    let workspace = resolve::active_workspace_dir(&base);
    let root = project_root_from(path)?;
    let engine = resolve::resolve_engine(&base, &workspace, &root)?;

    let presets = crate::export_runner::cli_preset_names(&root)?;
    if presets.is_empty() {
        return Err("This project has no export presets. Add one in the editor first.".to_string());
    }
    let chosen = match preset {
        Some(name) => presets
            .iter()
            .find(|preset| preset.eq_ignore_ascii_case(&name))
            .cloned()
            .ok_or_else(|| {
                format!(
                    "No export preset named {name:?}. Available presets: {}.",
                    presets.join(", ")
                )
            })?,
        None => presets[0].clone(),
    };
    let output = output.ok_or("Provide an output file with --output <file>.")?;
    if output.exists() && !overwrite {
        return Err(format!(
            "{} already exists. Pass --overwrite to replace it.",
            output.display()
        ));
    }

    let old_engine = engine.tag.trim_start_matches('v').starts_with("3.");
    let args = crate::export_runner::cli_export_args(&root, &chosen, &output, old_engine);
    eprintln!(
        "Exporting preset {chosen:?} with Godot {} (via {}).",
        engine.tag,
        source_label(engine.source)
    );
    let status = Command::new(&engine.executable_path)
        .args(&args)
        .status()
        .map_err(|e| format!("Failed to launch Godot: {e}"))?;
    let code = status.code().unwrap_or(1);
    if code == 0 {
        println!("Exported {} to {}", chosen, output.display());
    }
    Ok(code)
}

fn cmd_doctor(json: bool, path: Option<PathBuf>) -> Result<i32, String> {
    let base = base_dir()?;
    let workspace = resolve::active_workspace_dir(&base);
    let root = project_root_from(path)?;
    let registry = crate::godot_versions::read_registry_at(&base);
    let version_tag = resolve::resolve_engine(&base, &workspace, &root)
        .map(|engine| engine.tag)
        .unwrap_or_default();

    let report = crate::project_health::diagnose_cli(&root, &version_tag, &registry)?;

    if json {
        println!(
            "{}",
            serde_json::to_string_pretty(&report).map_err(|e| e.to_string())?
        );
    } else if report.checks.is_empty() {
        println!("No problems found.");
    } else {
        for check in &report.checks {
            println!("[{}] {}", check.severity, check.code);
        }
    }

    let has_error = report
        .checks
        .iter()
        .any(|check| check.severity == "error");
    Ok(if has_error { 1 } else { 0 })
}

#[cfg(windows)]
fn spawn_detached(exe: &str, args: &[String]) -> Result<(), String> {
    use std::os::windows::process::CommandExt;
    // DETACHED_PROCESS so the editor does not inherit this console.
    const DETACHED_PROCESS: u32 = 0x0000_0008;
    Command::new(exe)
        .args(args)
        .creation_flags(DETACHED_PROCESS)
        .spawn()
        .map(|_| ())
        .map_err(|e| format!("Failed to launch Godot: {e}"))
}

#[cfg(not(windows))]
fn spawn_detached(exe: &str, args: &[String]) -> Result<(), String> {
    Command::new(exe)
        .args(args)
        .spawn()
        .map(|_| ())
        .map_err(|e| format!("Failed to launch Godot: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse(args: &[&str]) -> Cli {
        Cli::try_parse_from(args).expect("args should parse")
    }

    #[test]
    fn no_arguments_means_no_subcommand() {
        let cli = parse(&["godothub"]);
        assert!(cli.command.is_none());
    }

    #[test]
    fn run_accepts_a_path() {
        let cli = parse(&["godothub", "run", "--path", "/tmp/game"]);
        match cli.command {
            Some(Commands::Run { path }) => {
                assert_eq!(path, Some(PathBuf::from("/tmp/game")));
            }
            other => panic!("expected run, got {other:?}"),
        }
    }

    #[test]
    fn open_requires_a_name() {
        assert!(Cli::try_parse_from(["godothub", "open"]).is_err());
        let cli = parse(&["godothub", "open", "My Game"]);
        assert!(matches!(cli.command, Some(Commands::Open { name }) if name == "My Game"));
    }

    #[test]
    fn install_parses_version_and_mono_flag() {
        let cli = parse(&["godothub", "install", "4.4.1-stable", "--mono"]);
        match cli.command {
            Some(Commands::Install { version, mono }) => {
                assert_eq!(version, "4.4.1-stable");
                assert!(mono);
            }
            other => panic!("expected install, got {other:?}"),
        }
    }

    #[test]
    fn doctor_json_flag_and_global_console() {
        let cli = parse(&["godothub", "--console", "doctor", "--json"]);
        assert!(cli.console);
        assert!(matches!(cli.command, Some(Commands::Doctor { json: true, .. })));
    }

    #[test]
    fn export_parses_preset_output_and_overwrite() {
        let cli = parse(&[
            "godothub", "export", "Windows", "--output", "out.exe", "--overwrite",
        ]);
        match cli.command {
            Some(Commands::Export {
                preset,
                output,
                overwrite,
                ..
            }) => {
                assert_eq!(preset.as_deref(), Some("Windows"));
                assert_eq!(output, Some(PathBuf::from("out.exe")));
                assert!(overwrite);
            }
            other => panic!("expected export, got {other:?}"),
        }
    }

    #[test]
    fn looks_like_cli_detects_subcommands_and_help() {
        assert!(looks_like_cli(&["versions".to_string()]));
        assert!(looks_like_cli(&["--help".to_string()]));
        assert!(!looks_like_cli(&["-psn_0_12345".to_string()]));
        assert!(!looks_like_cli(&[]));
    }
}
