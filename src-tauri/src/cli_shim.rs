use serde::Serialize;
use std::path::{Path, PathBuf};
use tauri::AppHandle;

const SHIM_STEM: &str = "godothub";

#[derive(Debug, Clone, Serialize)]
pub struct CliToolStatus {
    pub installed: bool,
    pub on_path: bool,
    pub bin_dir: String,
    pub shim_path: String,
    pub platform: String,
    /// True after an install that changed PATH, so the UI can tell the user a
    /// fresh terminal is needed.
    pub needs_new_terminal: bool,
}

fn platform_name() -> &'static str {
    #[cfg(target_os = "windows")]
    {
        "windows"
    }
    #[cfg(target_os = "macos")]
    {
        "macos"
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        "linux"
    }
}

fn shim_path(bin: &Path) -> PathBuf {
    #[cfg(windows)]
    {
        bin.join(format!("{SHIM_STEM}.cmd"))
    }
    #[cfg(not(windows))]
    {
        bin.join(SHIM_STEM)
    }
}

fn shim_exists(shim: &Path) -> bool {
    shim.exists() || std::fs::symlink_metadata(shim).is_ok()
}

fn dir_on_path(dir: &Path) -> bool {
    let Some(path) = std::env::var_os("PATH") else {
        return false;
    };
    let target = std::fs::canonicalize(dir).unwrap_or_else(|_| dir.to_path_buf());
    std::env::split_paths(&path).any(|entry| {
        entry == dir
            || std::fs::canonicalize(&entry)
                .map(|e| e == target)
                .unwrap_or(false)
    })
}

fn status_for(app: &AppHandle, needs_new_terminal: bool) -> CliToolStatus {
    let bin = crate::current_version::aliases_dir(app);
    let shim = shim_path(&bin);
    CliToolStatus {
        installed: shim_exists(&shim),
        on_path: dir_on_path(&bin),
        bin_dir: bin.to_string_lossy().to_string(),
        shim_path: shim.to_string_lossy().to_string(),
        platform: platform_name().to_string(),
        needs_new_terminal,
    }
}

#[tauri::command]
pub async fn cli_tool_status(app: AppHandle) -> CliToolStatus {
    status_for(&app, false)
}

#[tauri::command]
pub async fn install_cli_tool(app: AppHandle) -> Result<CliToolStatus, String> {
    let target = std::env::current_exe().map_err(|e| e.to_string())?;
    let bin = crate::current_version::aliases_dir(&app);
    write_shim(&shim_path(&bin), &target)?;
    let path_changed = add_bin_to_path(&bin)?;
    Ok(status_for(&app, path_changed))
}

#[tauri::command]
pub fn uninstall_cli_tool(app: AppHandle) -> Result<CliToolStatus, String> {
    let bin = crate::current_version::aliases_dir(&app);
    let shim = shim_path(&bin);
    if shim_exists(&shim) {
        std::fs::remove_file(&shim).map_err(|e| e.to_string())?;
    }
    remove_bin_from_path(&bin)?;
    Ok(status_for(&app, false))
}

#[cfg(windows)]
fn write_shim(shim: &Path, target: &Path) -> Result<(), String> {
    std::fs::write(shim, crate::current_version::shim_script(target)).map_err(|e| e.to_string())
}

#[cfg(not(windows))]
fn write_shim(shim: &Path, target: &Path) -> Result<(), String> {
    use std::os::unix::fs::symlink;
    if shim_exists(shim) {
        let _ = std::fs::remove_file(shim);
    }
    symlink(target, shim).map_err(|e| e.to_string())
}

// Windows: the user PATH lives in the registry under HKCU\Environment. We edit
// it there and broadcast the change so new shells pick it up.
#[cfg(windows)]
fn add_bin_to_path(bin: &Path) -> Result<bool, String> {
    let dir = bin.to_string_lossy().to_string();
    with_environment_key(|current| {
        if path_list_contains(current, &dir) {
            return None;
        }
        let trimmed = current.trim().trim_end_matches(';');
        let next = if trimmed.is_empty() {
            dir.clone()
        } else {
            format!("{trimmed};{dir}")
        };
        Some(next)
    })
}

#[cfg(windows)]
fn remove_bin_from_path(bin: &Path) -> Result<bool, String> {
    let dir = bin.to_string_lossy().to_string();
    with_environment_key(|current| {
        if !path_list_contains(current, &dir) {
            return None;
        }
        let kept: Vec<&str> = current
            .split(';')
            .map(str::trim)
            .filter(|entry| !entry.is_empty() && !same_dir(entry, &dir))
            .collect();
        Some(kept.join(";"))
    })
}

/// Read the user Path, let `edit` compute a replacement (None = no change),
/// write it back preserving REG_EXPAND_SZ, and broadcast. Returns whether it
/// changed.
#[cfg(windows)]
fn with_environment_key(edit: impl FnOnce(&str) -> Option<String>) -> Result<bool, String> {
    use winreg::enums::{HKEY_CURRENT_USER, KEY_READ, KEY_WRITE, REG_EXPAND_SZ};
    use winreg::{RegKey, RegValue};

    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let env = hkcu
        .open_subkey_with_flags("Environment", KEY_READ | KEY_WRITE)
        .map_err(|e| e.to_string())?;
    let current = match env.get_raw_value("Path") {
        Ok(value) => decode_utf16(&value.bytes),
        Err(_) => String::new(),
    };
    let Some(next) = edit(&current) else {
        return Ok(false);
    };
    let raw = RegValue {
        vtype: REG_EXPAND_SZ,
        bytes: encode_utf16(&next),
    };
    env.set_raw_value("Path", &raw).map_err(|e| e.to_string())?;
    broadcast_environment_change();
    Ok(true)
}

#[cfg(windows)]
fn same_dir(a: &str, b: &str) -> bool {
    a.trim_end_matches('\\')
        .eq_ignore_ascii_case(b.trim_end_matches('\\'))
}

#[cfg(windows)]
fn path_list_contains(list: &str, dir: &str) -> bool {
    list.split(';')
        .map(str::trim)
        .filter(|entry| !entry.is_empty())
        .any(|entry| same_dir(entry, dir))
}

#[cfg(windows)]
fn encode_utf16(value: &str) -> Vec<u8> {
    let mut bytes = Vec::with_capacity(value.len() * 2 + 2);
    for unit in value.encode_utf16() {
        bytes.extend_from_slice(&unit.to_le_bytes());
    }
    bytes.extend_from_slice(&[0, 0]);
    bytes
}

#[cfg(windows)]
fn decode_utf16(bytes: &[u8]) -> String {
    let mut units: Vec<u16> = bytes
        .chunks_exact(2)
        .map(|pair| u16::from_le_bytes([pair[0], pair[1]]))
        .collect();
    if units.last() == Some(&0) {
        units.pop();
    }
    String::from_utf16_lossy(&units)
}

#[cfg(windows)]
fn broadcast_environment_change() {
    use windows_sys::Win32::UI::WindowsAndMessaging::{
        SendMessageTimeoutW, HWND_BROADCAST, SMTO_ABORTIFHUNG, WM_SETTINGCHANGE,
    };
    let param: Vec<u16> = "Environment"
        .encode_utf16()
        .chain(std::iter::once(0))
        .collect();
    let mut result: usize = 0;
    unsafe {
        SendMessageTimeoutW(
            HWND_BROADCAST,
            WM_SETTINGCHANGE,
            0,
            param.as_ptr() as isize,
            SMTO_ABORTIFHUNG,
            5000,
            &mut result,
        );
    }
}

// Unix: there is no central user PATH, so we add an export line to the shell
// startup files, fenced by markers so it can be added and removed cleanly.
#[cfg(not(windows))]
const BLOCK_START: &str = "# >>> godothub >>>";
#[cfg(not(windows))]
const BLOCK_END: &str = "# <<< godothub <<<";

#[cfg(not(windows))]
fn profile_files(create_missing: bool) -> Vec<PathBuf> {
    let Some(home) = dirs::home_dir() else {
        return vec![];
    };
    let mut files = Vec::new();
    // .profile is read by login shells; always manage it.
    let profile = home.join(".profile");
    if create_missing || profile.exists() {
        files.push(profile);
    }
    for name in [".zshrc", ".bashrc"] {
        let candidate = home.join(name);
        if candidate.exists() {
            files.push(candidate);
        }
    }
    files
}

#[cfg(not(windows))]
fn add_bin_to_path(bin: &Path) -> Result<bool, String> {
    let dir = bin.to_string_lossy().to_string();
    let block = format!("\n{BLOCK_START}\nexport PATH=\"{dir}:$PATH\"\n{BLOCK_END}\n");
    let mut changed = false;
    for rc in profile_files(true) {
        let existing = std::fs::read_to_string(&rc).unwrap_or_default();
        if existing.contains(BLOCK_START) {
            continue;
        }
        let mut content = existing;
        if !content.is_empty() && !content.ends_with('\n') {
            content.push('\n');
        }
        content.push_str(&block);
        std::fs::write(&rc, content).map_err(|e| e.to_string())?;
        changed = true;
    }
    Ok(changed)
}

#[cfg(not(windows))]
fn remove_bin_from_path(_bin: &Path) -> Result<bool, String> {
    let mut changed = false;
    for rc in profile_files(false) {
        let content = std::fs::read_to_string(&rc).unwrap_or_default();
        if !content.contains(BLOCK_START) {
            continue;
        }
        std::fs::write(&rc, strip_block(&content)).map_err(|e| e.to_string())?;
        changed = true;
    }
    Ok(changed)
}

#[cfg(not(windows))]
fn strip_block(content: &str) -> String {
    let mut out: Vec<&str> = Vec::new();
    let mut skipping = false;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == BLOCK_START {
            skipping = true;
            continue;
        }
        if trimmed == BLOCK_END {
            skipping = false;
            continue;
        }
        if !skipping {
            out.push(line);
        }
    }
    let mut joined = out.join("\n");
    joined = joined.trim_end_matches('\n').to_string();
    joined.push('\n');
    joined
}

#[cfg(all(test, not(windows)))]
mod tests {
    use super::*;

    #[test]
    fn strip_block_removes_only_the_fenced_region() {
        let content =
            "a=1\n# >>> godothub >>>\nexport PATH=\"/x:$PATH\"\n# <<< godothub <<<\nb=2\n";
        assert_eq!(strip_block(content), "a=1\nb=2\n");
    }

    #[test]
    fn strip_block_is_a_noop_without_markers() {
        let content = "a=1\nb=2\n";
        assert_eq!(strip_block(content), "a=1\nb=2\n");
    }
}
