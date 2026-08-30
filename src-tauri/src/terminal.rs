use std::path::Path;
use std::process::{Child, Command};

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[cfg(target_os = "windows")]
pub const CREATE_NO_WINDOW: u32 = 0x0800_0000;

#[cfg(unix)]
use std::path::PathBuf;

#[cfg(unix)]
use tauri::{AppHandle, Manager};

#[cfg(all(unix, not(target_os = "macos")))]
const TERMINALS: [(&str, &[&str]); 23] = [
    ("xdg-terminal-exec", &[]),
    ("x-terminal-emulator", &["-e"]),
    ("gnome-terminal", &["--"]),
    ("konsole", &["-e"]),
    ("kgx", &["--"]),
    ("ptyxis", &["-x"]),
    ("xfce4-terminal", &["-x"]),
    ("tilix", &["-e"]),
    ("mate-terminal", &["-x"]),
    ("deepin-terminal", &["-e"]),
    ("cosmic-term", &["-e"]),
    ("qterminal", &["-e"]),
    ("lxterminal", &["-e"]),
    ("kitty", &[]),
    ("alacritty", &["-e"]),
    ("wezterm", &["start", "--"]),
    ("foot", &[]),
    ("ghostty", &["-e"]),
    ("terminator", &["-x"]),
    ("urxvt", &["-e"]),
    ("rxvt", &["-e"]),
    ("st", &["-e"]),
    ("xterm", &["-e"]),
];

#[cfg(unix)]
fn sh_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}

#[cfg(unix)]
fn prune_stale_scripts(dir: &Path) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    let cutoff = std::time::Duration::from_secs(60 * 60 * 24);
    for entry in entries.flatten() {
        let stale = entry
            .metadata()
            .and_then(|m| m.modified())
            .map(|m| m.elapsed().map(|age| age > cutoff).unwrap_or(false))
            .unwrap_or(false);
        if stale {
            let _ = std::fs::remove_file(entry.path());
        }
    }
}

#[cfg(unix)]
fn launch_dir(app: &AppHandle) -> Result<PathBuf, String> {
    use std::os::unix::fs::{DirBuilderExt, PermissionsExt};

    let dir = app
        .path()
        .app_cache_dir()
        .map_err(|e| e.to_string())?
        .join("launch");

    if !dir.exists() {
        if let Some(parent) = dir.parent() {
            std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
        }
        std::fs::DirBuilder::new()
            .mode(0o700)
            .create(&dir)
            .map_err(|e| e.to_string())?;
    } else {
        std::fs::set_permissions(&dir, std::fs::Permissions::from_mode(0o700))
            .map_err(|e| e.to_string())?;
    }

    Ok(dir)
}

#[cfg(unix)]
fn launch_stamp() -> u128 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0)
}

#[cfg(unix)]
fn write_launch_script(
    app: &AppHandle,
    body: &str,
    extension: &str,
    stamp: u128,
) -> Result<PathBuf, String> {
    use std::os::unix::fs::PermissionsExt;

    let dir = launch_dir(app)?;
    prune_stale_scripts(&dir);

    let script = dir.join(format!("launch-{stamp}.{extension}"));

    std::fs::write(&script, body).map_err(|e| e.to_string())?;
    std::fs::set_permissions(&script, std::fs::Permissions::from_mode(0o700))
        .map_err(|e| e.to_string())?;

    Ok(script)
}

#[cfg(unix)]
fn program_script_body(program: &Path, args: &[String], pid_file: &Path) -> String {
    let quoted_pid_file = sh_quote(&pid_file.to_string_lossy());
    let mut body = format!(
        "#!/bin/sh\necho $$ > {quoted_pid_file}.tmp && mv {quoted_pid_file}.tmp {quoted_pid_file}\nexec "
    );
    body.push_str(&sh_quote(&program.to_string_lossy()));
    for arg in args {
        body.push(' ');
        body.push_str(&sh_quote(arg));
    }
    body.push('\n');
    body
}

#[cfg(all(unix, not(target_os = "macos")))]
fn find_on_path(binary: &str) -> Option<PathBuf> {
    if binary.contains('/') {
        let direct = PathBuf::from(binary);
        return direct.is_file().then_some(direct);
    }
    std::env::split_paths(&std::env::var_os("PATH")?)
        .map(|dir| dir.join(binary))
        .find(|candidate| candidate.is_file())
}

#[cfg(all(unix, not(target_os = "macos")))]
fn flags_for(binary: &str) -> &'static [&'static str] {
    let name = Path::new(binary)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or(binary);
    TERMINALS
        .iter()
        .find(|(known, _)| *known == name)
        .map(|(_, flags)| *flags)
        .unwrap_or(&["-e"])
}

#[cfg(all(unix, not(target_os = "macos")))]
pub fn sanitize_child_env(cmd: &mut Command) {
    if std::env::var_os("APPIMAGE").is_some() {
        cmd.env_remove("LD_LIBRARY_PATH");
    }
}

#[cfg(not(all(unix, not(target_os = "macos"))))]
pub fn sanitize_child_env(_cmd: &mut Command) {}

#[cfg(all(unix, not(target_os = "macos")))]
fn spawn_script(script: &Path) -> Result<Child, String> {
    if let Some(preferred) = std::env::var("TERMINAL").ok().filter(|t| !t.is_empty()) {
        if let Some(binary) = find_on_path(&preferred) {
            let mut cmd = Command::new(binary);
            sanitize_child_env(&mut cmd);
            if let Ok(child) = cmd.args(flags_for(&preferred)).arg(script).spawn() {
                return Ok(child);
            }
        }
    }

    for (binary, flags) in TERMINALS {
        let Some(resolved) = find_on_path(binary) else {
            continue;
        };
        let mut cmd = Command::new(resolved);
        sanitize_child_env(&mut cmd);
        if let Ok(child) = cmd.args(flags).arg(script).spawn() {
            return Ok(child);
        }
    }

    Err("Could not find a terminal emulator".into())
}

#[cfg(all(unix, not(target_os = "macos")))]
pub fn spawn_shell_script_in_terminal(app: &AppHandle, body: &str) -> Result<Child, String> {
    let script = write_launch_script(app, body, "sh", launch_stamp())?;
    spawn_script(&script)
}

#[cfg(target_os = "macos")]
fn spawn_script(script: &Path) -> Result<Child, String> {
    Command::new("open")
        .arg(script)
        .spawn()
        .or_else(|_| Command::new("open").args(["-a", "Terminal"]).arg(script).spawn())
        .map_err(|e| format!("Failed to open a terminal: {e}"))
}

#[cfg(unix)]
pub fn spawn_program_in_terminal(
    app: &AppHandle,
    program: &Path,
    args: &[String],
) -> Result<(Child, PathBuf), String> {
    let extension = if cfg!(target_os = "macos") { "command" } else { "sh" };
    let stamp = launch_stamp();
    let pid_file = launch_dir(app)?.join(format!("launch-{stamp}.pid"));
    let script = write_launch_script(
        app,
        &program_script_body(program, args, &pid_file),
        extension,
        stamp,
    )?;
    spawn_script(&script).map(|child| (child, pid_file))
}

#[cfg(unix)]
pub fn read_pid_file(path: &Path) -> Option<u32> {
    std::fs::read_to_string(path)
        .ok()?
        .trim()
        .parse::<u32>()
        .ok()
        .filter(|pid| *pid > 1)
}

#[cfg(unix)]
pub fn process_is_alive(pid: u32) -> bool {
    unsafe { libc::kill(pid as libc::pid_t, 0) == 0 }
}

#[cfg(unix)]
pub fn terminate_process(pid: u32) -> Result<(), String> {
    if unsafe { libc::kill(pid as libc::pid_t, libc::SIGKILL) } == 0 {
        return Ok(());
    }
    Err(std::io::Error::last_os_error().to_string())
}

#[cfg(target_os = "windows")]
fn console_title(raw: &str) -> String {
    let cleaned: String = raw
        .lines()
        .next()
        .unwrap_or_default()
        .chars()
        .filter(|c| !c.is_control() && *c != '"' && *c != '%')
        .take(60)
        .collect();

    match cleaned.trim() {
        "" => "Godot".to_string(),
        trimmed => trimmed.to_string(),
    }
}

#[cfg(target_os = "windows")]
fn quote_arg(arg: &str) -> String {
    let sanitized = arg.replace('"', "'");
    let trailing = sanitized.len() - sanitized.trim_end_matches('\\').len();
    format!("\"{}{}\"", sanitized, "\\".repeat(trailing))
}

#[cfg(target_os = "windows")]
pub fn spawn_program_in_console(
    program: &Path,
    args: &[String],
    title: &str,
) -> Result<Child, String> {
    let mut line = format!(
        "/C start \"{}\" /WAIT {}",
        console_title(title),
        quote_arg(&program.display().to_string())
    );
    for arg in args {
        line.push(' ');
        line.push_str(&quote_arg(arg));
    }

    Command::new("cmd")
        .raw_arg(line)
        .creation_flags(CREATE_NO_WINDOW)
        .spawn()
        .map_err(|e| format!("Failed to open a console window: {e}"))
}
