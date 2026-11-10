use std::cell::Cell;
use std::ffi::OsString;
use std::io::{IsTerminal, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};

use clap::{CommandFactory, FromArgMatches, Parser, Subcommand};

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
fn print_banner(io: &mut Io) {
    if !color_enabled() {
        return;
    }
    for line in LOGO.lines() {
        let _ = writeln!(io.err, "{}", accent(line));
    }
    let _ = writeln!(
        io.err,
        "{}\n",
        dim(&format!(
            "Godot version and project management  v{}",
            crate::app_version()
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
    /// Open a project in the editor, by its registered name or a folder path.
    Open {
        /// Project name as shown in the app, or a path to a project folder.
        target: String,
        /// Godot version to use when the folder isn't registered yet
        /// (for example 4.4.1-stable). Defaults to the pin or current version.
        #[arg(long)]
        godot: Option<String>,
        /// When opening an unregistered folder, add it to GodotHub without asking.
        #[arg(long)]
        add: bool,
        /// When opening an unregistered folder, don't add it and don't ask.
        #[arg(long, conflicts_with = "add")]
        no_add: bool,
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

pub struct Io<'a> {
    pub out: &'a mut dyn Write,
    pub err: &'a mut dyn Write,
}

/// Parse argv and, when a subcommand is present, run it and return an exit code.
/// Returns `None` when no subcommand is given, meaning the GUI should launch.
/// Stray OS arguments on a GUI launch (for example macOS `-psn_...`) are ignored
/// rather than treated as a parse error.
pub fn dispatch(channel: crate::Channel) -> Option<i32> {
    dispatch_from(channel, std::env::args_os().collect())
}

pub fn dispatch_from(channel: crate::Channel, argv: Vec<OsString>) -> Option<i32> {
    let args: Vec<String> = argv
        .iter()
        .skip(1)
        .map(|arg| arg.to_string_lossy().into_owned())
        .collect();
    if !looks_like_cli(&args) {
        return None;
    }
    attach_console();
    match parse_from(channel, argv) {
        Ok(cli) => {
            COLOR.store(detect_color(cli.no_color), Ordering::Relaxed);
            let mut stdout = std::io::stdout();
            let mut stderr = std::io::stderr();
            let mut io = Io {
                out: &mut stdout,
                err: &mut stderr,
            };
            Some(
                cli.command
                    .map(|command| run(channel, command, &mut io))
                    .unwrap_or(0),
            )
        }
        Err(err) => {
            let _ = err.print();
            Some(if err.use_stderr() { 2 } else { 0 })
        }
    }
}

pub fn command(channel: crate::Channel) -> clap::Command {
    Cli::command()
        .name(channel.info().cli_shim_name)
        .version(crate::app_version())
}

pub fn parse_from(channel: crate::Channel, argv: Vec<OsString>) -> Result<Cli, clap::Error> {
    let matches = command(channel).try_get_matches_from(argv)?;
    Cli::from_arg_matches(&matches)
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

fn run(channel: crate::Channel, command: Commands, io: &mut Io) -> i32 {
    let result = base_dir(channel).and_then(|base| run_in(&base, command, io));
    report(result, io)
}

fn report(result: Result<i32, String>, io: &mut Io) -> i32 {
    match result {
        Ok(code) => code,
        Err(message) => {
            let _ = writeln!(io.err, "{} {message}", red("error:"));
            1
        }
    }
}

fn run_in(base: &Path, command: Commands, io: &mut Io) -> Result<i32, String> {
    match command {
        Commands::Versions => cmd_versions(base, io),
        Commands::Open {
            target,
            godot,
            add,
            no_add,
        } => cmd_open(base, &target, godot, add, no_add, io),
        Commands::Run { path } => cmd_run(base, path, io),
        Commands::Install { version, mono } => cmd_install(base, &version, mono, io),
        Commands::Export {
            preset,
            output,
            path,
            overwrite,
        } => cmd_export(base, preset, output, path, overwrite, io),
        Commands::Doctor { json, path } => cmd_doctor(base, json, path, io),
    }
}

fn base_dir(channel: crate::Channel) -> Result<PathBuf, String> {
    resolve::data_dir(channel)
        .ok_or_else(|| "Could not determine the GodotHub data directory".to_string())
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

fn cmd_versions(base: &Path, io: &mut Io) -> Result<i32, String> {
    let list = resolve::installed_sorted(base);
    print_banner(io);
    if list.is_empty() {
        let _ = writeln!(
            io.out,
            "No Godot versions are installed. Use `godothub install <version>`."
        );
        return Ok(0);
    }
    let current = crate::current_version::read_current_tag_at(base);
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
        let _ = writeln!(
            io.out,
            "{marker} {tag}{mono}\t{}",
            dim(&version.executable_path)
        );
    }
    if current.is_some() {
        let _ = writeln!(io.out, "\n{} = current version", green("*"));
    }
    Ok(0)
}

/// Decide whether an `open` argument is a folder path rather than a project
/// name. Anything with a path separator, a leading `.`/`~`, or that already
/// exists as a directory is treated as a path; bare words are names.
fn looks_like_path(target: &str) -> bool {
    target.contains('/')
        || target.contains('\\')
        || target == "."
        || target == ".."
        || target.starts_with('~')
        || Path::new(target).is_dir()
}

fn cmd_open(
    base: &Path,
    target: &str,
    godot: Option<String>,
    add: bool,
    no_add: bool,
    io: &mut Io,
) -> Result<i32, String> {
    let workspace = resolve::active_workspace_dir(base);
    let projects = crate::projects::read_projects_from(&workspace);

    if looks_like_path(target) {
        let root = project_root_from(Some(PathBuf::from(target)))?;
        let root_str = root.to_string_lossy().to_string();
        if let Some(project) = projects
            .iter()
            .find(|project| crate::projects::same_path(&project.path, &root_str))
        {
            return open_registered(base, &workspace, project, io);
        }
        return open_unregistered(base, &workspace, &root, godot, add, no_add, io);
    }

    let project = projects
        .iter()
        .find(|project| project.name.eq_ignore_ascii_case(target))
        .ok_or_else(|| {
            format!(
                "No registered project named {target:?}. Pass a folder path to open a project by location."
            )
        })?;
    open_registered(base, &workspace, project, io)
}

fn open_registered(
    base: &Path,
    workspace: &Path,
    project: &crate::models::Project,
    io: &mut Io,
) -> Result<i32, String> {
    let root = PathBuf::from(&project.path);
    let engine = resolve::resolve_engine(base, workspace, &root)?;

    let mut args = vec!["--path".to_string(), project.path.clone(), "-e".to_string()];
    args.extend(
        project
            .launch_arguments
            .split_whitespace()
            .map(str::to_string),
    );
    spawn_detached(&engine.executable_path, &args)?;
    let _ = writeln!(
        io.out,
        "{} {} in Godot {} ({}).",
        green("Opening"),
        bold(&project.name),
        accent(&engine.tag),
        dim(source_label(engine.source))
    );
    Ok(0)
}

fn open_unregistered(
    base: &Path,
    workspace: &Path,
    root: &Path,
    godot: Option<String>,
    add: bool,
    no_add: bool,
    io: &mut Io,
) -> Result<i32, String> {
    let root_str = root.to_string_lossy().to_string();
    let interactive = std::io::stdin().is_terminal() && std::io::stdout().is_terminal();

    let engine = match godot {
        Some(tag) => find_installed_version(base, &tag)?,
        None => match resolve::resolve_engine(base, workspace, root) {
            Ok(engine) => engine,
            Err(_) if interactive => prompt_select_version(base, io)?,
            Err(err) => {
                return Err(format!(
                    "{err} Pass --godot <version> to choose one (see `godothub versions`)."
                ));
            }
        },
    };

    let args = vec!["--path".to_string(), root_str.clone(), "-e".to_string()];
    spawn_detached(&engine.executable_path, &args)?;
    let _ = writeln!(
        io.out,
        "{} {} in Godot {}.",
        green("Opening"),
        dim(&root_str),
        accent(&engine.tag)
    );

    let should_add = if add {
        true
    } else if no_add {
        false
    } else if interactive {
        prompt_yes_no("Add this project to GodotHub?", io)?
    } else {
        false
    };
    if should_add {
        let project = crate::projects::register_project_in_workspace(
            workspace,
            &root_str,
            engine.tag.clone(),
        )?;
        let _ = writeln!(
            io.out,
            "{} {} to GodotHub.",
            green("Added"),
            bold(&project.name)
        );
    }
    Ok(0)
}

/// Look up an installed version by tag, tolerating a bare `4.4.1` for
/// `4.4.1-stable`, for the `--godot` flag.
fn find_installed_version(base: &Path, tag: &str) -> Result<resolve::Engine, String> {
    let registry = crate::godot_versions::read_registry_at(base);
    let wanted = tag.trim();
    let version = registry
        .iter()
        .find(|version| version.tag.eq_ignore_ascii_case(wanted))
        .or_else(|| {
            registry
                .iter()
                .find(|version| version.tag.eq_ignore_ascii_case(&format!("{wanted}-stable")))
        })
        .ok_or_else(|| {
            format!(
                "Godot {wanted:?} is not installed. Run `godothub versions` to list installed versions, or `godothub install {wanted}`."
            )
        })?;
    engine_from(version)
}

fn prompt_select_version(base: &Path, io: &mut Io) -> Result<resolve::Engine, String> {
    let list = resolve::installed_sorted(base);
    if list.is_empty() {
        return Err(
            "No Godot versions are installed. Run `godothub install <version>` first.".into(),
        );
    }
    let _ = writeln!(io.err, "{}", bold("Select a Godot version:"));
    for (index, version) in list.iter().enumerate() {
        let mono = if version.is_mono {
            dim(" (mono)")
        } else {
            String::new()
        };
        let _ = writeln!(io.err, "  {}. {}{}", index + 1, bold(&version.tag), mono);
    }
    let _ = write!(io.err, "Version [1-{}]: ", list.len());
    io.err.flush().map_err(|e| e.to_string())?;
    let mut line = String::new();
    std::io::stdin()
        .read_line(&mut line)
        .map_err(|e| e.to_string())?;
    let choice: usize = line
        .trim()
        .parse()
        .map_err(|_| "That isn't a valid selection.".to_string())?;
    let version = list
        .get(choice.wrapping_sub(1))
        .ok_or_else(|| "That selection is out of range.".to_string())?;
    engine_from(version)
}

fn engine_from(version: &crate::models::InstalledGodotVersion) -> Result<resolve::Engine, String> {
    if !Path::new(&version.executable_path).is_file() {
        return Err(format!(
            "The Godot executable for {} is missing at {}.",
            version.tag, version.executable_path
        ));
    }
    Ok(resolve::Engine {
        tag: version.tag.clone(),
        executable_path: version.executable_path.clone(),
        source: EngineSource::Current,
    })
}

fn prompt_yes_no(question: &str, io: &mut Io) -> Result<bool, String> {
    let _ = write!(io.err, "{question} [y/N]: ");
    io.err.flush().map_err(|e| e.to_string())?;
    let mut line = String::new();
    std::io::stdin()
        .read_line(&mut line)
        .map_err(|e| e.to_string())?;
    Ok(matches!(line.trim().to_lowercase().as_str(), "y" | "yes"))
}

fn cmd_run(base: &Path, path: Option<PathBuf>, io: &mut Io) -> Result<i32, String> {
    let workspace = resolve::active_workspace_dir(base);
    let root = project_root_from(path)?;
    let engine = resolve::resolve_engine(base, &workspace, &root)?;

    let _ = writeln!(
        io.err,
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

fn cmd_install(base: &Path, version: &str, mono: bool, io: &mut Io) -> Result<i32, String> {
    let workspace = resolve::active_workspace_dir(base);
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
    let progress_err = std::cell::RefCell::new(&mut *io.err);
    let progress = |downloaded: u64, total: u64| {
        if total == 0 {
            return;
        }
        let pct = downloaded.saturating_mul(100) / total;
        if pct != last_pct.get() {
            last_pct.set(pct);
            let mut err = progress_err.borrow_mut();
            let _ = write!(err, "\rDownloading {version}... {pct}%");
            let _ = err.flush();
            if downloaded >= total {
                let _ = writeln!(err);
            }
        }
    };

    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(|e| e.to_string())?;
    let installed = runtime.block_on(crate::godot_versions::install_version_headless(
        base,
        &versions_dir,
        token,
        version,
        mono,
        progress,
    ))?;
    let _ = writeln!(
        io.out,
        "{} Godot {} at {}",
        green("Installed"),
        accent(&installed.tag),
        dim(&installed.executable_path)
    );
    Ok(0)
}

fn cmd_export(
    base: &Path,
    preset: Option<String>,
    output: Option<PathBuf>,
    path: Option<PathBuf>,
    overwrite: bool,
    io: &mut Io,
) -> Result<i32, String> {
    let workspace = resolve::active_workspace_dir(base);
    let root = project_root_from(path)?;
    let engine = resolve::resolve_engine(base, &workspace, &root)?;

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
    let _ = writeln!(
        io.err,
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
        let _ = writeln!(
            io.out,
            "{} {} to {}",
            green("Exported"),
            bold(&chosen),
            dim(&output.display().to_string())
        );
    }
    Ok(code)
}

fn cmd_doctor(base: &Path, json: bool, path: Option<PathBuf>, io: &mut Io) -> Result<i32, String> {
    let workspace = resolve::active_workspace_dir(base);
    let root = project_root_from(path)?;
    let registry = crate::godot_versions::read_registry_at(base);
    let version_tag = resolve::resolve_engine(base, &workspace, &root)
        .map(|engine| engine.tag)
        .unwrap_or_default();

    let report = crate::project_health::diagnose_cli(&root, &version_tag, &registry)?;

    if json {
        let _ = writeln!(
            io.out,
            "{}",
            serde_json::to_string_pretty(&report).map_err(|e| e.to_string())?
        );
    } else {
        print_banner(io);
        if report.checks.is_empty() {
            let _ = writeln!(io.out, "{}", green("No problems found."));
        } else {
            for check in &report.checks {
                let _ = writeln!(io.out, "{} {}", severity_label(&check.severity), check.code);
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

#[allow(clippy::missing_safety_doc)]
#[no_mangle]
pub unsafe extern "C" fn godothub_cli_dispatch(
    channel: u32,
    version: *const std::ffi::c_char,
    exit_code: *mut i32,
) -> bool {
    if !version.is_null() {
        if let Ok(version) = std::ffi::CStr::from_ptr(version).to_str() {
            crate::set_app_version(Box::leak(version.to_owned().into_boxed_str()));
        }
    }
    match ffi_dispatch(channel, std::env::args_os().collect()) {
        Some(code) => {
            if !exit_code.is_null() {
                *exit_code = code;
            }
            true
        }
        None => false,
    }
}

fn ffi_dispatch(channel: u32, argv: Vec<OsString>) -> Option<i32> {
    let channel = if channel == 0 {
        crate::Channel::Stable
    } else {
        crate::Channel::Beta
    };
    std::panic::catch_unwind(|| dispatch_from(channel, argv)).unwrap_or(Some(101))
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
    fn open_requires_a_target() {
        assert!(Cli::try_parse_from(["godothub", "open"]).is_err());
        let cli = parse(&["godothub", "open", "My Game"]);
        assert!(matches!(cli.command, Some(Commands::Open { target, .. }) if target == "My Game"));
    }

    #[test]
    fn open_parses_path_with_version_and_add() {
        let cli = parse(&[
            "godothub",
            "open",
            "/tmp/game",
            "--godot",
            "4.4.1-stable",
            "--add",
        ]);
        match cli.command {
            Some(Commands::Open {
                target,
                godot,
                add,
                no_add,
            }) => {
                assert_eq!(target, "/tmp/game");
                assert_eq!(godot.as_deref(), Some("4.4.1-stable"));
                assert!(add);
                assert!(!no_add);
            }
            other => panic!("expected open, got {other:?}"),
        }
    }

    #[test]
    fn open_add_and_no_add_conflict() {
        assert!(
            Cli::try_parse_from(["godothub", "open", "/tmp/game", "--add", "--no-add"]).is_err()
        );
    }

    #[test]
    fn looks_like_path_detects_paths_but_not_names() {
        assert!(looks_like_path("/home/me/game"));
        assert!(looks_like_path("./game"));
        assert!(looks_like_path("."));
        assert!(!looks_like_path("My Game"));
        assert!(!looks_like_path("MyGame"));
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

    fn os(args: &[&str]) -> Vec<OsString> {
        args.iter().map(OsString::from).collect()
    }

    struct Fixture {
        root: PathBuf,
        base: PathBuf,
        project: PathBuf,
    }

    impl Fixture {
        fn new(name: &str) -> Self {
            let root =
                std::env::temp_dir().join(format!("godothub-cli-{name}-{}", uuid::Uuid::new_v4()));
            let base = root.join("data");
            let project = root.join("game");
            std::fs::create_dir_all(&base).unwrap();
            std::fs::create_dir_all(&project).unwrap();
            std::fs::write(
                project.join("project.godot"),
                "config_version=5\n\n[application]\n\nconfig/name=\"Space Game\"\n",
            )
            .unwrap();
            Self {
                root,
                base,
                project,
            }
        }

        fn engine(&self, exit_code: i32) -> String {
            #[cfg(windows)]
            let path = {
                let path = self.root.join(format!("godot-{exit_code}.cmd"));
                std::fs::write(&path, format!("@exit /b {exit_code}\r\n")).unwrap();
                path
            };
            #[cfg(not(windows))]
            let path = {
                use std::os::unix::fs::PermissionsExt;
                let path = self.root.join(format!("godot-{exit_code}"));
                std::fs::write(&path, format!("#!/bin/sh\nexit {exit_code}\n")).unwrap();
                std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o755)).unwrap();
                path
            };
            path.to_string_lossy().into_owned()
        }

        fn install(&self, tag: &str, executable_path: &str, is_mono: bool) {
            let mut registry = crate::godot_versions::read_registry_at(&self.base);
            registry.push(crate::models::InstalledGodotVersion {
                tag: tag.into(),
                version: tag.into(),
                executable_path: executable_path.into(),
                is_mono,
                installed_at: "2026-01-01T00:00:00Z".into(),
                custom_name: None,
                install_root: None,
                supports_console: false,
                managed_by: None,
            });
            std::fs::write(
                self.base.join("godot-versions.json"),
                serde_json::to_string(&registry).unwrap(),
            )
            .unwrap();
        }

        fn set_current(&self, tag: &str) {
            std::fs::write(
                self.base.join("current-version.json"),
                serde_json::json!({ "tag": tag }).to_string(),
            )
            .unwrap();
        }

        fn register(&self, tag: &str) -> crate::models::Project {
            let workspace = resolve::active_workspace_dir(&self.base);
            crate::projects::register_project_in_workspace(
                &workspace,
                &self.project.to_string_lossy(),
                tag.into(),
            )
            .unwrap()
        }

        fn project_root(&self) -> String {
            std::fs::canonicalize(&self.project)
                .unwrap()
                .display()
                .to_string()
        }

        fn run(&self, args: &[&str]) -> (i32, String, String) {
            let cli = parse_from(crate::Channel::Stable, os(args)).expect("args should parse");
            let (mut out, mut err) = (Vec::new(), Vec::new());
            let code = {
                let mut io = Io {
                    out: &mut out,
                    err: &mut err,
                };
                let result = run_in(&self.base, cli.command.expect("a subcommand"), &mut io);
                report(result, &mut io)
            };
            (
                code,
                String::from_utf8(out).unwrap(),
                String::from_utf8(err).unwrap(),
            )
        }
    }

    impl Drop for Fixture {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.root);
        }
    }

    #[test]
    fn versions_parses_without_arguments() {
        assert!(matches!(
            parse(&["godothub", "versions"]).command,
            Some(Commands::Versions)
        ));
        assert!(Cli::try_parse_from(["godothub", "versions", "extra"]).is_err());
    }

    #[test]
    fn version_flag_prints_the_app_version_for_each_channel() {
        let stable = parse_from(crate::Channel::Stable, os(&["godothub", "--version"])).unwrap_err();
        assert_eq!(stable.kind(), clap::error::ErrorKind::DisplayVersion);
        assert_eq!(
            stable.to_string(),
            format!("godothub {}\n", crate::app_version())
        );
        let beta = parse_from(crate::Channel::Beta, os(&["godothub-beta", "-V"])).unwrap_err();
        assert_eq!(
            beta.to_string(),
            format!("godothub-beta {}\n", crate::app_version())
        );
    }

    #[test]
    fn help_shows_the_logo_usage_and_every_subcommand() {
        let help = parse_from(crate::Channel::Stable, os(&["godothub", "--help"])).unwrap_err();
        assert_eq!(help.kind(), clap::error::ErrorKind::DisplayHelp);
        let text = help.to_string();
        assert!(text.starts_with(LOGO));
        assert!(text.contains("GodotHub: Godot version and project management"));
        assert!(text.contains("Usage: godothub [OPTIONS] [COMMAND]"));
        for name in ["open", "run", "versions", "install", "export", "doctor", "help"] {
            assert!(text.contains(&format!("\n  {name} ")), "missing {name}");
        }
        assert!(text.contains("--no-color"));
        assert!(text.contains("--console"));
    }

    #[test]
    fn versions_prints_installed_versions_with_the_current_marker() {
        let fx = Fixture::new("versions");
        let engine = fx.engine(0);
        fx.install("4.3-stable", &engine, true);
        fx.install("4.4.1-stable", &engine, false);
        fx.set_current("4.4.1-stable");
        let (code, out, err) = fx.run(&["godothub", "versions"]);
        assert_eq!(code, 0);
        assert_eq!(
            out,
            format!("* 4.4.1-stable\t{engine}\n  4.3-stable (mono)\t{engine}\n\n* = current version\n")
        );
        assert_eq!(err, "");
    }

    #[test]
    fn versions_without_installs_explains_how_to_install() {
        let fx = Fixture::new("versions-empty");
        let (code, out, err) = fx.run(&["godothub", "versions"]);
        assert_eq!(code, 0);
        assert_eq!(
            out,
            "No Godot versions are installed. Use `godothub install <version>`.\n"
        );
        assert_eq!(err, "");
    }

    #[test]
    fn open_by_name_launches_the_bound_version() {
        let fx = Fixture::new("open-name");
        fx.install("4.4.1-stable", &fx.engine(0), false);
        let project = fx.register("4.4.1-stable");
        let (code, out, err) = fx.run(&["godothub", "open", &project.name.to_uppercase()]);
        assert_eq!(code, 0, "{err}");
        assert_eq!(
            out,
            format!("Opening {} in Godot 4.4.1-stable (app binding).\n", project.name)
        );
        assert_eq!(err, "");
    }

    #[test]
    fn open_with_an_unknown_name_fails() {
        let fx = Fixture::new("open-unknown");
        let (code, out, err) = fx.run(&["godothub", "open", "Nope"]);
        assert_eq!(code, 1);
        assert_eq!(out, "");
        assert_eq!(
            err,
            "error: No registered project named \"Nope\". Pass a folder path to open a project by location.\n"
        );
    }

    #[test]
    fn open_by_path_with_a_bare_version_and_no_add() {
        let fx = Fixture::new("open-path");
        fx.install("4.4.1-stable", &fx.engine(0), false);
        let path = fx.project.to_string_lossy().into_owned();
        let (code, out, err) = fx.run(&["godothub", "open", &path, "--godot", "4.4.1", "--no-add"]);
        assert_eq!(code, 0, "{err}");
        assert_eq!(
            out,
            format!("Opening {} in Godot 4.4.1-stable.\n", fx.project_root())
        );
        assert_eq!(err, "");
        let workspace = resolve::active_workspace_dir(&fx.base);
        assert!(crate::projects::read_projects_from(&workspace).is_empty());
    }

    #[test]
    fn open_by_path_with_add_registers_the_project() {
        let fx = Fixture::new("open-add");
        fx.install("4.4.1-stable", &fx.engine(0), false);
        let path = fx.project.to_string_lossy().into_owned();
        let (code, out, _) = fx.run(&["godothub", "open", &path, "--godot", "4.4.1-stable", "--add"]);
        assert_eq!(code, 0);
        let workspace = resolve::active_workspace_dir(&fx.base);
        let projects = crate::projects::read_projects_from(&workspace);
        assert_eq!(projects.len(), 1);
        assert_eq!(
            out,
            format!(
                "Opening {} in Godot 4.4.1-stable.\nAdded {} to GodotHub.\n",
                fx.project_root(),
                projects[0].name
            )
        );
    }

    #[test]
    fn run_returns_the_engine_exit_code() {
        let fx = Fixture::new("run");
        fx.install("4.4.1-stable", &fx.engine(3), false);
        fx.set_current("4.4.1-stable");
        let path = fx.project.to_string_lossy().into_owned();
        let (code, out, err) = fx.run(&["godothub", "run", "--path", &path]);
        assert_eq!(code, 3);
        assert_eq!(out, "");
        assert_eq!(
            err,
            format!(
                "Running {} with Godot 4.4.1-stable (current version).\n",
                fx.project_root()
            )
        );
    }

    #[test]
    fn run_outside_a_project_fails() {
        let fx = Fixture::new("run-none");
        let empty = fx.root.join("empty");
        std::fs::create_dir_all(&empty).unwrap();
        let path = empty.to_string_lossy().into_owned();
        let (code, out, err) = fx.run(&["godothub", "run", "--path", &path]);
        assert_eq!(code, 1);
        assert_eq!(out, "");
        assert_eq!(
            err,
            "error: No Godot project here: project.godot was not found in this or any parent directory.\n"
        );
    }

    #[test]
    fn install_requires_a_version() {
        assert!(Cli::try_parse_from(["godothub", "install"]).is_err());
        let cli = parse(&["godothub", "install", "4.4"]);
        assert!(matches!(
            cli.command,
            Some(Commands::Install { version, mono: false }) if version == "4.4"
        ));
    }

    #[test]
    fn export_runs_the_first_preset_and_reports_the_output() {
        let fx = Fixture::new("export");
        fx.install("4.4.1-stable", &fx.engine(0), false);
        fx.set_current("4.4.1-stable");
        std::fs::write(
            fx.project.join("export_presets.cfg"),
            "[preset.0]\nname=\"Windows Desktop\"\nplatform=\"Windows Desktop\"\n[preset.1]\nname=\"Web\"\nplatform=\"Web\"\n",
        )
        .unwrap();
        let output = fx.root.join("out.exe");
        let path = fx.project.to_string_lossy().into_owned();
        let output_arg = output.to_string_lossy().into_owned();
        let (code, out, err) =
            fx.run(&["godothub", "export", "--path", &path, "--output", &output_arg]);
        assert_eq!(code, 0, "{err}");
        assert_eq!(
            err,
            "Exporting preset \"Windows Desktop\" with Godot 4.4.1-stable (current version).\n"
        );
        assert_eq!(out, format!("Exported Windows Desktop to {output_arg}\n"));
    }

    #[test]
    fn export_rejects_unknown_presets_and_existing_outputs() {
        let fx = Fixture::new("export-errors");
        fx.install("4.4.1-stable", &fx.engine(0), false);
        fx.set_current("4.4.1-stable");
        let path = fx.project.to_string_lossy().into_owned();
        let (code, _, err) = fx.run(&["godothub", "export", "--path", &path]);
        assert_eq!(code, 1);
        assert_eq!(
            err,
            "error: This project has no export presets. Add one in the editor first.\n"
        );

        std::fs::write(
            fx.project.join("export_presets.cfg"),
            "[preset.0]\nname=\"Web\"\nplatform=\"Web\"\n",
        )
        .unwrap();
        let (_, _, err) = fx.run(&["godothub", "export", "Linux", "--path", &path]);
        assert_eq!(
            err,
            "error: No export preset named \"Linux\". Available presets: Web.\n"
        );
        let (_, _, err) = fx.run(&["godothub", "export", "--path", &path]);
        assert_eq!(err, "error: Provide an output file with --output <file>.\n");

        let output = fx.root.join("index.html");
        std::fs::write(&output, "old").unwrap();
        let output_arg = output.to_string_lossy().into_owned();
        let (code, _, err) =
            fx.run(&["godothub", "export", "--path", &path, "--output", &output_arg]);
        assert_eq!(code, 1);
        assert_eq!(
            err,
            format!(
                "error: {} already exists. Pass --overwrite to replace it.\n",
                output.display()
            )
        );
    }

    #[test]
    fn doctor_prints_the_same_checks_as_text_and_json() {
        let fx = Fixture::new("doctor");
        fx.install("4.4.1-stable", &fx.engine(0), false);
        fx.set_current("4.4.1-stable");
        let path = fx.project.to_string_lossy().into_owned();

        let (json_code, json_out, json_err) =
            fx.run(&["godothub", "doctor", "--json", "--path", &path]);
        assert_eq!(json_err, "");
        let report: serde_json::Value = serde_json::from_str(&json_out).unwrap();
        assert!(json_out.ends_with("}\n"));
        let checks = report["checks"].as_array().unwrap();

        let (text_code, text_out, _) = fx.run(&["godothub", "doctor", "--path", &path]);
        let expected = if checks.is_empty() {
            "No problems found.\n".to_string()
        } else {
            checks
                .iter()
                .map(|check| {
                    format!(
                        "[{}] {}\n",
                        check["severity"].as_str().unwrap(),
                        check["code"].as_str().unwrap()
                    )
                })
                .collect()
        };
        assert_eq!(text_out, expected);
        let has_error = checks.iter().any(|check| check["severity"] == "error");
        assert_eq!(json_code, i32::from(has_error));
        assert_eq!(text_code, json_code);
    }

    #[test]
    fn c_entry_point_only_handles_cli_arguments() {
        assert_eq!(ffi_dispatch(0, os(&["godothub"])), None);
        assert_eq!(ffi_dispatch(1, os(&["godothub-beta", "-psn_0_1"])), None);
        assert_eq!(ffi_dispatch(0, os(&["godothub", "--version"])), Some(0));
        assert_eq!(ffi_dispatch(0, os(&["godothub", "versions", "--bogus"])), Some(2));
    }
}
