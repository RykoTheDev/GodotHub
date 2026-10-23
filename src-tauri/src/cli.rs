use std::cell::Cell;
use std::io::{IsTerminal, Write};
use std::path::PathBuf;
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};

use clap::{Parser, Subcommand};

use crate::resolve::{self, EngineSource};

const LOGO: &str = r#"  ___         _     _   _  _      _
 / __|___  __| |___| |_| || |_  _| |__
| (_ / _ \/ _` / _ \  _| __ | || | '_ \
 \___\___/\__,_\___/\__|_||_|\_,_|_.__/"#;

static COLOR: AtomicBool = AtomicBool::new(false);

fn color_enabled() -> bool {
    COLOR.load(Ordering::Relaxed)
}

/// Decide whether to emit ANSI styling: never when --no-color or NO_COLOR is
/// set, never for a dumb terminal, and otherwise only when stdout is a tty, so
/// piped and redirected output stays clean.
fn detect_color(no_color_flag: bool) -> bool {
    if no_color_flag || std::env::var_os("NO_COLOR").is_some() {
        return false;
    }
    if std::env::var("TERM").is_ok_and(|term| term == "dumb") {
        return false;
    }
    std::io::stdout().is_terminal()
}

fn sgr(code: &str, text: &str) -> String {
    if color_enabled() {
        format!("\x1b[{code}m{text}\x1b[0m")
    } else {
        text.to_string()
    }
}

fn bold(text: &str) -> String {
    sgr("1", text)
}
fn dim(text: &str) -> String {
    sgr("2", text)
}
fn red(text: &str) -> String {
    sgr("31", text)
}
fn green(text: &str) -> String {
    sgr("32", text)
}
fn yellow(text: &str) -> String {
    sgr("33", text)
}
fn accent(text: &str) -> String {
    sgr("1;36", text)
}

/// Print the logo to stderr, only in an interactive terminal, so it decorates
/// the view without polluting stdout that a script may be parsing.
fn print_banner() {
    if !color_enabled() {
        return;
    }
    for line in LOGO.lines() {
        eprintln!("{}", accent(line));
    }
    eprintln!(
        "{}\n",
        dim(&format!(
            "Godot version and project management  v{}",
            env!("CARGO_PKG_VERSION")
        ))
    );
}

fn severity_label(severity: &str) -> String {
    let tag = format!("[{severity}]");
    match severity {
        "error" => red(&tag),
        "warning" => yellow(&tag),
        "ok" => green(&tag),
        _ => dim(&tag),
    }
}

#[derive(Parser, Debug)]
#[command(
    name = "godothub",
    version,
    about = "GodotHub: Godot version and project management",
    before_help = LOGO,
    disable_help_subcommand = false
)]
pub struct Cli {
    /// Windows only: attach to the parent console so output is visible.
    #[arg(long, global = true)]
    pub console: bool,

    /// Disable colored output.
    #[arg(long, global = true)]
    pub no_color: bool,

    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand, Debug)]
pub enum Commands {
    /// Open a registered project by name in the editor.
    Open {
        /// Project name as shown in the app.
        name: String,
    },
    /// Run the project in the current directory (play, not the editor).
    Run {
        /// Project directory; defaults to the current directory, walking up to project.godot.
        #[arg(long)]
        path: Option<PathBuf>,
    },
    /// List installed Godot versions.
    Versions,
    /// Download and install a Godot version.
    Install {
        /// Version tag, e.g. 4.4.1-stable or 4.4.1.
        version: String,
        /// Install the .NET/Mono build.
        #[arg(long)]
        mono: bool,
    },
    /// Export the current project using a preset.
    Export {
        /// Preset name; defaults to the first preset in export_presets.cfg.
        preset: Option<String>,
        /// Output file path.
        #[arg(long, short)]
        output: Option<PathBuf>,
        /// Project directory; defaults to the current directory.
        #[arg(long)]
        path: Option<PathBuf>,
        /// Overwrite an existing output file.
        #[arg(long)]
        overwrite: bool,
    },
    /// Report project health problems for the current project.
    Doctor {
        /// Emit the report as JSON.
        #[arg(long)]
        json: bool,
        /// Project directory; defaults to the current directory.
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

/// Parse argv and, when a subcommand is present, run it and return an exit code.
/// Returns `None` when no subcommand is given, meaning the GUI should launch.
/// Stray OS arguments on a GUI launch (for example macOS `-psn_...`) are ignored
/// rather than treated as a parse error.
pub fn dispatch() -> Option<i32> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if !looks_like_cli(&args) {
        return None;
    }
    attach_console();
    match Cli::try_parse() {
        Ok(cli) => {
            COLOR.store(detect_color(cli.no_color), Ordering::Relaxed);
            Some(cli.command.map(run).unwrap_or(0))
        }
        Err(err) => {
            let _ = err.print();
            Some(if err.use_stderr() { 2 } else { 0 })
        }
    }
}

/// The Windows GUI subsystem build has no console, so a subcommand's output
/// would be lost. Attaching to the parent process's console restores it.
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
            eprintln!("{} {message}", red("error:"));
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
    print_banner();
    if list.is_empty() {
        println!("No Godot versions are installed. Use `godothub install <version>`.");
        return Ok(0);
    }
    let current = crate::current_version::read_current_tag_at(&base);
    for version in &list {
        let is_current = current.as_deref() == Some(version.tag.as_str());
        let marker = if is_current {
            green("*")
        } else {
            " ".to_string()
        };
        let tag = if is_current {
            accent(&version.tag)
        } else {
            bold(&version.tag)
        };
        let mono = if version.is_mono {
            dim(" (mono)")
        } else {
            String::new()
        };
        println!("{marker} {tag}{mono}\t{}", dim(&version.executable_path));
    }
    if current.is_some() {
        println!("\n{} = current version", green("*"));
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
        "{} {} in Godot {} ({}).",
        green("Opening"),
        bold(&project.name),
        accent(&engine.tag),
        dim(source_label(engine.source))
    );
    Ok(0)
}

fn cmd_run(path: Option<PathBuf>) -> Result<i32, String> {
    let base = base_dir()?;
    let workspace = resolve::active_workspace_dir(&base);
    let root = project_root_from(path)?;
    let engine = resolve::resolve_engine(&base, &workspace, &root)?;

    eprintln!(
        "{} {} with Godot {} ({}).",
        green("Running"),
        dim(&root.display().to_string()),
        accent(&engine.tag),
        dim(source_label(engine.source))
    );
    let mut cmd = Command::new(&engine.executable_path);
    crate::terminal::sanitize_child_env(&mut cmd);
    let status = cmd
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
        "{} Godot {} at {}",
        green("Installed"),
        accent(&installed.tag),
        dim(&installed.executable_path)
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
        "{} preset {chosen:?} with Godot {} ({}).",
        green("Exporting"),
        accent(&engine.tag),
        dim(source_label(engine.source))
    );
    let mut cmd = Command::new(&engine.executable_path);
    crate::terminal::sanitize_child_env(&mut cmd);
    let status = cmd
        .args(&args)
        .status()
        .map_err(|e| format!("Failed to launch Godot: {e}"))?;
    let code = status.code().unwrap_or(1);
    if code == 0 {
        println!(
            "{} {} to {}",
            green("Exported"),
            bold(&chosen),
            dim(&output.display().to_string())
        );
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
    } else {
        print_banner();
        if report.checks.is_empty() {
            println!("{}", green("No problems found."));
        } else {
            for check in &report.checks {
                println!("{} {}", severity_label(&check.severity), check.code);
            }
        }
    }

    let has_error = report.checks.iter().any(|check| check.severity == "error");
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
    let mut cmd = Command::new(exe);
    crate::terminal::sanitize_child_env(&mut cmd);
    cmd.args(args)
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
        assert!(matches!(
            cli.command,
            Some(Commands::Doctor { json: true, .. })
        ));
    }

    #[test]
    fn export_parses_preset_output_and_overwrite() {
        let cli = parse(&[
            "godothub",
            "export",
            "Windows",
            "--output",
            "out.exe",
            "--overwrite",
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
