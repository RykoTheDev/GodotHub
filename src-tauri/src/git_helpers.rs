use std::ffi::OsStr;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::OnceLock;

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[cfg(target_os = "windows")]
use crate::terminal::CREATE_NO_WINDOW;

use crate::error::{AppError, AppResult};

static CREDENTIAL_STORE: OnceLock<Option<PathBuf>> = OnceLock::new();

pub fn set_credential_store(path: PathBuf) {
    let _ = CREDENTIAL_STORE.set(Some(path));
}

fn credential_store_arg() -> Option<String> {
    let path = CREDENTIAL_STORE.get().and_then(|o| o.as_ref())?;
    if !path.exists() {
        return None;
    }
    let escaped = path
        .display()
        .to_string()
        .replace('\\', "\\\\")
        .replace('\"', "\\\"");
    Some(format!("store --file=\"{}\"", escaped))
}

pub fn git_command() -> Command {
    #[allow(unused_mut)]
    let mut cmd = Command::new("git");
    #[cfg(target_os = "windows")]
    cmd.creation_flags(CREATE_NO_WINDOW);
    if let Some(helper) = credential_store_arg() {
        cmd.arg("-c");
        cmd.arg(format!("credential.helper={}", helper));
    }
    cmd
}

pub fn git_cmd<I, S>(working_dir: &str, args: I) -> AppResult<String>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    let output = git_command()
        .args(args)
        .current_dir(working_dir)
        .output()?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(AppError::Message(stderr));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim_end().to_string())
}

pub fn git_raw<I, S>(working_dir: &str, args: I) -> AppResult<std::process::Output>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    git_command()
        .args(args)
        .current_dir(working_dir)
        .output()
        .map_err(AppError::from)
}

pub fn output_stdout(output: &std::process::Output) -> String {
    String::from_utf8_lossy(&output.stdout).to_string()
}

pub fn output_stderr(output: &std::process::Output) -> String {
    String::from_utf8_lossy(&output.stderr).to_string()
}

#[allow(dead_code)]
pub fn git_lines(working_dir: &str, args: &[&str]) -> AppResult<Vec<String>> {
    let out = git_cmd(working_dir, args)?;
    Ok(out.lines().filter(|l| !l.is_empty()).map(String::from).collect())
}

#[allow(dead_code)]
pub fn open_in_os(path: &Path) -> AppResult<()> {
    let path_str = path.to_string_lossy();
    let _path_s: &str = &path_str;

    #[cfg(target_os = "windows")]
    let result = Command::new("explorer").arg(path).spawn();

    #[cfg(target_os = "macos")]
    let result = Command::new("open").arg(path).spawn();

    #[cfg(all(unix, not(target_os = "macos")))]
    let result = Command::new("xdg-open")
        .arg(path)
        .spawn()
        .or_else(|_| Command::new("gio").args(["open", _path_s]).spawn())
        .or_else(|_| Command::new("nautilus").arg(_path_s).spawn())
        .or_else(|_| Command::new("dolphin").arg(_path_s).spawn())
        .or_else(|_| Command::new("thunar").arg(_path_s).spawn());

    result.map(|_| ()).map_err(|e| format!("Failed to open: {e}").into())
}
