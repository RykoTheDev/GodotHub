//! Onyx (github.com/RykoTheDev/OnyxSteamworks) uploads game builds to Steamworks.
//! GodotHub finds an installed copy, checks it is current, and hands it an export
//! folder with `onyx --open <folder>`; Onyx then shows the matching project's Build page.
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

pub const RELEASES_URL: &str = "https://github.com/RykoTheDev/OnyxSteamworks/releases/latest";
const LATEST_API: &str = "https://api.github.com/repos/RykoTheDev/OnyxSteamworks/releases/latest";
const LATEST_CACHE_TTL: Duration = Duration::from_secs(60 * 60);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OnyxStatus {
    /// Onyx is built for Windows and Linux only.
    pub supported: bool,
    pub path: Option<String>,
    /// From `onyx --version`. Releases older than the GodotHub hand-off have no
    /// `--version`, so a found binary without a version is too old to use.
    pub version: Option<String>,
    /// The newest release on GitHub, or `None` when it could not be checked.
    pub latest: Option<String>,
    pub up_to_date: bool,
    pub releases_url: String,
}

fn binary_name() -> &'static str {
    if cfg!(windows) { "onyx.exe" } else { "onyx" }
}

fn candidates() -> Vec<PathBuf> {
    let mut out = Vec::new();
    if let Some(paths) = std::env::var_os("PATH") {
        out.extend(std::env::split_paths(&paths).map(|dir| dir.join(binary_name())));
    }
    if cfg!(windows) {
        // The installer puts per-user installs in %LOCALAPPDATA%\Programs and
        // machine-wide ones in Program Files.
        if let Some(local) = std::env::var_os("LOCALAPPDATA") {
            out.push(PathBuf::from(local).join("Programs").join("Onyx").join("onyx.exe"));
        }
        for var in ["ProgramFiles", "ProgramW6432"] {
            if let Some(dir) = std::env::var_os(var) {
                out.push(PathBuf::from(dir).join("Onyx").join("onyx.exe"));
            }
        }
    } else if let Some(home) = std::env::var_os("HOME") {
        let home = PathBuf::from(home);
        out.push(home.join(".local").join("bin").join("onyx"));
        out.push(home.join(".local").join("share").join("onyx").join("onyx"));
        out.push(PathBuf::from("/opt/onyx/onyx"));
    }
    out
}

pub fn onyx_binary() -> Option<PathBuf> {
    candidates().into_iter().find(|p| p.is_file())
}

fn command(bin: &Path) -> std::process::Command {
    let mut cmd = std::process::Command::new(bin);
    crate::terminal::sanitize_child_env(&mut cmd);
    cmd
}

/// Parses `onyx 1.2.0` into `1.2.0`.
fn parse_version_output(text: &str) -> Option<String> {
    let line = text.lines().map(str::trim).find(|l| !l.is_empty())?;
    let version = line.split_whitespace().last()?;
    semver::Version::parse(version.trim_start_matches('v')).ok()?;
    Some(version.trim_start_matches('v').to_string())
}

fn installed_version(bin: &Path) -> Option<String> {
    let mut cmd = command(bin);
    cmd.arg("--version");
    #[cfg(target_os = "windows")]
    cmd.creation_flags(crate::terminal::CREATE_NO_WINDOW);
    let output = cmd.output().ok()?;
    if !output.status.success() {
        return None;
    }
    parse_version_output(&String::from_utf8_lossy(&output.stdout))
}

fn latest_cache() -> &'static Mutex<Option<(Instant, String)>> {
    static CACHE: OnceLock<Mutex<Option<(Instant, String)>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(None))
}

async fn latest_version() -> Option<String> {
    if let Some((at, version)) = latest_cache().lock().unwrap_or_else(std::sync::PoisonError::into_inner).as_ref() {
        if at.elapsed() < LATEST_CACHE_TTL {
            return Some(version.clone());
        }
    }
    #[derive(Deserialize)]
    struct Release {
        tag_name: String,
    }
    let release: Release = crate::http::client()
        .ok()?
        .get(LATEST_API)
        .header("Accept", "application/vnd.github+json")
        .timeout(Duration::from_secs(15))
        .send()
        .await
        .ok()?
        .error_for_status()
        .ok()?
        .json()
        .await
        .ok()?;
    let version = release.tag_name.trim().trim_start_matches('v').to_string();
    semver::Version::parse(&version).ok()?;
    *latest_cache().lock().unwrap_or_else(std::sync::PoisonError::into_inner) = Some((Instant::now(), version.clone()));
    Some(version)
}

/// Current means the installed copy has `--version` and is not behind the latest
/// release. When GitHub can't be reached, an installed copy with `--version` counts.
fn is_up_to_date(version: Option<&str>, latest: Option<&str>) -> bool {
    let Some(installed) = version.and_then(|v| semver::Version::parse(v).ok()) else {
        return false;
    };
    match latest.and_then(|l| semver::Version::parse(l).ok()) {
        Some(latest) => installed >= latest,
        None => true,
    }
}

pub async fn onyx_status() -> OnyxStatus {
    let releases_url = RELEASES_URL.to_string();
    if !cfg!(any(target_os = "windows", target_os = "linux")) {
        return OnyxStatus { supported: false, path: None, version: None, latest: None, up_to_date: false, releases_url };
    }
    let local = crate::runtime::spawn_blocking(|| {
        let bin = onyx_binary()?;
        let version = installed_version(&bin);
        Some((bin, version))
    })
    .await
    .ok()
    .flatten();
    let latest = latest_version().await;
    let (path, version) = match local {
        Some((bin, version)) => (Some(bin.to_string_lossy().to_string()), version),
        None => (None, None),
    };
    let up_to_date = is_up_to_date(version.as_deref(), latest.as_deref());
    OnyxStatus { supported: true, path, version, latest, up_to_date, releases_url }
}

/// Starts Onyx on `folder`. Onyx opens the project whose content folder holds it, or
/// offers to create one.
pub fn open_folder(folder: &Path) -> Result<(), String> {
    if !cfg!(any(target_os = "windows", target_os = "linux")) {
        return Err("Onyx is not available for macOS.".into());
    }
    let bin = onyx_binary().ok_or("Onyx is not installed.")?;
    if installed_version(&bin).is_none() {
        return Err("This version of Onyx is too old to open GodotHub exports. Update Onyx and try again.".into());
    }
    let mut child = command(&bin)
        .arg("--open")
        .arg(folder)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
        .map_err(|e| format!("Failed to start Onyx: {e}"))?;
    std::thread::spawn(move || {
        let _ = child.wait();
    });
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_clap_version_line() {
        assert_eq!(parse_version_output("onyx 1.2.0\n").as_deref(), Some("1.2.0"));
        assert_eq!(parse_version_output("\nonyx v1.10.3").as_deref(), Some("1.10.3"));
        assert_eq!(parse_version_output("error: unexpected argument"), None);
        assert_eq!(parse_version_output(""), None);
    }

    #[test]
    fn up_to_date_needs_a_version_and_the_latest_release() {
        assert!(is_up_to_date(Some("1.2.0"), Some("1.2.0")));
        assert!(is_up_to_date(Some("1.3.0"), Some("1.2.0")));
        assert!(!is_up_to_date(Some("1.2.0"), Some("1.10.0")));
        assert!(!is_up_to_date(None, Some("1.2.0")));
        assert!(is_up_to_date(Some("1.2.0"), None));
        assert!(!is_up_to_date(None, None));
    }
}
