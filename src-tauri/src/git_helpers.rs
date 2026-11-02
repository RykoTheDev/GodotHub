use std::ffi::OsStr;
use std::path::PathBuf;
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
    crate::terminal::sanitize_child_env(&mut cmd);
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
    let output = git_command().args(args).current_dir(working_dir).output()?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(AppError::Message(stderr));
    }

    Ok(String::from_utf8_lossy(&output.stdout)
        .trim_end()
        .to_string())
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
