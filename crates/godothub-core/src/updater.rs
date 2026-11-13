use std::collections::HashMap;
use std::path::{Path, PathBuf};

use base64::Engine;
use futures_util::StreamExt;
use serde::Deserialize;

use crate::{AppHandle, Channel};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Installer {
    AppImage,
    Deb,
    Rpm,
    App,
    Msi,
    Nsis,
}

impl Installer {
    pub fn name(self) -> &'static str {
        match self {
            Self::AppImage => "appimage",
            Self::Deb => "deb",
            Self::Rpm => "rpm",
            Self::App => "app",
            Self::Msi => "msi",
            Self::Nsis => "nsis",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InstallKind {
    Installed(Installer),
    Portable,
    Unknown,
}

#[derive(Debug, Clone, Deserialize, PartialEq, Eq)]
pub struct PlatformEntry {
    pub url: String,
    pub signature: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(untagged)]
enum ReleaseData {
    Dynamic(PlatformEntry),
    Static { platforms: HashMap<String, PlatformEntry> },
}

#[derive(Debug, Clone, Deserialize)]
struct RawManifest {
    version: String,
    notes: Option<String>,
    pub_date: Option<String>,
    #[serde(flatten)]
    data: ReleaseData,
}

#[derive(Debug, Clone)]
pub struct Manifest {
    pub version: semver::Version,
    pub version_text: String,
    pub notes: Option<String>,
    pub pub_date: Option<String>,
    data: ReleaseData,
}

impl Manifest {
    pub fn parse(json: &str) -> Result<Self, String> {
        let raw: RawManifest = serde_json::from_str(json).map_err(|e| format!("Invalid update manifest: {e}"))?;
        let version = parse_version(&raw.version)?;
        Ok(Self { version, version_text: raw.version, notes: raw.notes, pub_date: raw.pub_date, data: raw.data })
    }

    pub fn entry(&self, key: &str) -> Option<&PlatformEntry> {
        match &self.data {
            ReleaseData::Dynamic(entry) => Some(entry),
            ReleaseData::Static { platforms } => platforms.get(key),
        }
    }

    pub fn select(&self, keys: &[String]) -> Option<(String, PlatformEntry)> {
        keys.iter().find_map(|key| self.entry(key).map(|entry| (key.clone(), entry.clone())))
    }

    fn urls(&self) -> Vec<&str> {
        match &self.data {
            ReleaseData::Dynamic(entry) => vec![entry.url.as_str()],
            ReleaseData::Static { platforms } => platforms.values().map(|p| p.url.as_str()).collect(),
        }
    }

    pub fn downloads_from_github_api(&self) -> bool {
        let urls = self.urls();
        !urls.is_empty()
            && urls.iter().all(|u| url::Url::parse(u).ok().and_then(|u| u.host_str().map(str::to_string)).as_deref() == Some("api.github.com"))
    }
}

fn parse_version(text: &str) -> Result<semver::Version, String> {
    semver::Version::parse(text.trim().trim_start_matches('v')).map_err(|e| format!("Invalid version {text:?}: {e}"))
}

pub fn updater_os() -> Option<&'static str> {
    if cfg!(target_os = "linux") {
        Some("linux")
    } else if cfg!(target_os = "macos") {
        Some("darwin")
    } else if cfg!(target_os = "windows") {
        Some("windows")
    } else {
        None
    }
}

pub fn updater_arch() -> Option<&'static str> {
    if cfg!(target_arch = "x86") {
        Some("i686")
    } else if cfg!(target_arch = "x86_64") {
        Some("x86_64")
    } else if cfg!(target_arch = "arm") {
        Some("armv7")
    } else if cfg!(target_arch = "aarch64") {
        Some("aarch64")
    } else if cfg!(target_arch = "riscv64") {
        Some("riscv64")
    } else {
        None
    }
}

pub fn target_keys(os: &str, arch: &str, installer: Option<Installer>) -> Vec<String> {
    let mut keys = Vec::new();
    if let Some(installer) = installer {
        keys.push(format!("{os}-{arch}-{}", installer.name()));
    }
    keys.push(format!("{os}-{arch}"));
    keys
}

pub fn endpoint(channel: Channel) -> &'static str {
    channel.info().update_endpoint
}

pub fn detect_install_kind() -> InstallKind {
    let Ok(exe) = std::env::current_exe() else {
        return InstallKind::Unknown;
    };
    detect_for(&exe)
}

#[cfg(target_os = "windows")]
fn detect_for(exe: &Path) -> InstallKind {
    if crate::install_mode::is_portable_install() {
        return InstallKind::Portable;
    }
    let has_uninstaller = exe
        .parent()
        .and_then(|dir| dir.read_dir().ok())
        .is_some_and(|entries| {
            entries.flatten().any(|e| {
                let name = e.file_name().to_string_lossy().to_lowercase();
                name.starts_with("uninstall") && name.ends_with(".exe")
            })
        });
    InstallKind::Installed(if has_uninstaller { Installer::Nsis } else { Installer::Msi })
}

#[cfg(target_os = "macos")]
fn detect_for(exe: &Path) -> InstallKind {
    match app_bundle_of(exe) {
        Some(_) => InstallKind::Installed(Installer::App),
        None => InstallKind::Unknown,
    }
}

#[cfg(target_os = "linux")]
fn detect_for(exe: &Path) -> InstallKind {
    if std::env::var_os("APPIMAGE").is_some() {
        return InstallKind::Installed(Installer::AppImage);
    }
    let owned_by = |cmd: &str, arg: &str| {
        std::process::Command::new(cmd)
            .arg(arg)
            .arg(exe)
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status()
            .is_ok_and(|s| s.success())
    };
    if owned_by("dpkg", "-S") {
        InstallKind::Installed(Installer::Deb)
    } else if owned_by("rpm", "-qf") {
        InstallKind::Installed(Installer::Rpm)
    } else {
        InstallKind::Unknown
    }
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn detect_for(_exe: &Path) -> InstallKind {
    InstallKind::Unknown
}

pub fn app_bundle_of(exe: &Path) -> Option<PathBuf> {
    let macos = exe.parent()?;
    let contents = macos.parent()?;
    let bundle = contents.parent()?;
    let is_bundle = macos.file_name()? == "MacOS"
        && contents.file_name()? == "Contents"
        && bundle.extension().is_some_and(|e| e == "app");
    is_bundle.then(|| bundle.to_path_buf())
}

fn decode_base64_text(value: &str) -> Result<String, String> {
    let bytes = base64::engine::general_purpose::STANDARD
        .decode(value.trim())
        .map_err(|e| format!("Invalid base64: {e}"))?;
    String::from_utf8(bytes).map_err(|_| "The signature is not valid UTF-8".to_string())
}

fn signed_version(trusted_comment: &str) -> Option<&str> {
    trusted_comment.split('\t').find_map(|field| field.strip_prefix("version:"))
}

fn check_signed_version(trusted_comment: &str, announced: &str) -> Result<(), String> {
    let Some(signed) = signed_version(trusted_comment) else {
        return Ok(());
    };
    let matches = match (parse_version(signed), parse_version(announced)) {
        (Ok(a), Ok(b)) => a == b,
        _ => signed == announced,
    };
    if matches {
        Ok(())
    } else {
        Err(format!("The update was signed for version {signed}, not {announced}"))
    }
}

pub fn verify_signature(data: &[u8], signature: &str, public_keys: &[&str], announced_version: &str) -> Result<(), String> {
    let signature_text = decode_base64_text(signature)?;
    let signature = minisign_verify::Signature::decode(&signature_text).map_err(|e| format!("Invalid signature: {e}"))?;
    let mut last_error = "No trusted update keys are configured".to_string();
    for key in public_keys {
        let key = match decode_base64_text(key).and_then(|text| {
            minisign_verify::PublicKey::decode(&text).map_err(|e| format!("Invalid public key: {e}"))
        }) {
            Ok(key) => key,
            Err(error) => {
                last_error = error;
                continue;
            }
        };
        match key.verify(data, &signature, true) {
            Ok(()) => return check_signed_version(signature.trusted_comment(), announced_version),
            Err(error) => last_error = format!("The update signature is not valid: {error}"),
        }
    }
    Err(last_error)
}

#[derive(Debug, Clone)]
pub struct UpdateInfo {
    pub version: String,
    pub current_version: String,
    pub notes: Option<String>,
    pub pub_date: Option<String>,
    pub target: String,
    pub url: String,
    pub signature: String,
    pub installer: Option<Installer>,
    pub portable: bool,
    pub send_token: bool,
}

pub fn update_from_manifest(manifest: &Manifest, current: &str, kind: InstallKind) -> Result<Option<UpdateInfo>, String> {
    let current_version = parse_version(current)?;
    if manifest.version <= current_version {
        return Ok(None);
    }
    let os = updater_os().ok_or("Updates are not supported on this operating system")?;
    let arch = updater_arch().ok_or("Updates are not supported on this architecture")?;
    let installer = match kind {
        InstallKind::Installed(installer) => Some(installer),
        _ => None,
    };
    let keys = target_keys(os, arch, installer);
    let (target, entry) = manifest
        .select(&keys)
        .ok_or_else(|| format!("The update has no download for {}", keys.join(" or ")))?;
    Ok(Some(UpdateInfo {
        version: manifest.version_text.trim_start_matches('v').to_string(),
        current_version: current.to_string(),
        notes: manifest.notes.clone(),
        pub_date: manifest.pub_date.clone(),
        target,
        url: entry.url,
        signature: entry.signature,
        installer,
        portable: kind == InstallKind::Portable,
        send_token: manifest.downloads_from_github_api(),
    }))
}

fn with_token(request: reqwest::RequestBuilder, token: Option<&str>, send: bool) -> reqwest::RequestBuilder {
    match token.filter(|t| send && !t.trim().is_empty()) {
        Some(token) => request.header(reqwest::header::AUTHORIZATION, format!("Bearer {}", token.trim())),
        None => request,
    }
}

pub async fn check(app: &AppHandle) -> Result<Option<UpdateInfo>, String> {
    let url = endpoint(app.channel());
    let response = crate::http::client()?
        .get(url)
        .header(reqwest::header::ACCEPT, "application/json")
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if response.status() == reqwest::StatusCode::NO_CONTENT {
        return Ok(None);
    }
    if !response.status().is_success() {
        return Err(format!("Update check failed with status {}", response.status()));
    }
    let body = response.text().await.map_err(|e| e.to_string())?;
    let manifest = Manifest::parse(&body)?;
    update_from_manifest(&manifest, crate::app_version(), detect_install_kind())
}

pub async fn download<F: FnMut(u64, Option<u64>)>(
    app: &AppHandle,
    update: &UpdateInfo,
    github_token: Option<&str>,
    mut on_progress: F,
) -> Result<Vec<u8>, String> {
    let request = crate::http::client()?
        .get(&update.url)
        .header(reqwest::header::ACCEPT, "application/octet-stream");
    let response = with_token(request, github_token, update.send_token).send().await.map_err(|e| e.to_string())?;
    if !response.status().is_success() {
        return Err(format!("Download request failed with status: {}", response.status()));
    }
    let total = response.content_length();
    let mut buffer = Vec::with_capacity(total.unwrap_or(0) as usize);
    let mut stream = response.bytes_stream();
    on_progress(0, total);
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| e.to_string())?;
        buffer.extend_from_slice(&chunk);
        on_progress(buffer.len() as u64, total);
    }
    verify_signature(&buffer, &update.signature, app.channel().info().updater_public_keys, &update.version)?;
    Ok(buffer)
}

pub(crate) fn is_zip(bytes: &[u8]) -> bool {
    bytes.starts_with(b"PK\x03\x04")
}

pub(crate) fn is_exe(bytes: &[u8]) -> bool {
    bytes.starts_with(b"MZ")
}

pub(crate) fn is_msi(bytes: &[u8]) -> bool {
    bytes.starts_with(&[0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1])
}

pub(crate) fn is_elf(bytes: &[u8]) -> bool {
    bytes.starts_with(&[0x7F, b'E', b'L', b'F'])
}

pub(crate) fn is_gzip(bytes: &[u8]) -> bool {
    bytes.starts_with(&[0x1F, 0x8B])
}

pub(crate) fn is_deb(bytes: &[u8]) -> bool {
    bytes.starts_with(b"!<arch>\ndebian-binary")
}

pub(crate) fn is_rpm(bytes: &[u8]) -> bool {
    bytes.starts_with(&[0xED, 0xAB, 0xEE, 0xDB])
}

pub fn extract_from_zip(bytes: &[u8], wanted: impl Fn(&str) -> bool) -> Result<(String, Vec<u8>), String> {
    use std::io::Read;
    let mut archive = zip::ZipArchive::new(std::io::Cursor::new(bytes)).map_err(|e| e.to_string())?;
    for i in 0..archive.len() {
        let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
        if file.is_dir() {
            continue;
        }
        let name = file.name().map_err(|e| e.to_string())?.to_string();
        let leaf = Path::new(&name).file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
        if wanted(&leaf) {
            let mut out = Vec::with_capacity(file.size() as usize);
            file.read_to_end(&mut out).map_err(|e| e.to_string())?;
            return Ok((leaf, out));
        }
    }
    Err("The update archive does not contain an installer".into())
}

fn temp_dir_for(version: &str) -> Result<PathBuf, String> {
    let dir = std::env::temp_dir().join(format!("godothub-{version}-updater-{}", std::process::id()));
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    Ok(dir)
}

pub fn install(update: &UpdateInfo, bytes: &[u8]) -> Result<(), String> {
    platform::install(update, bytes)
}

#[cfg(target_os = "windows")]
pub(crate) fn nsis_arguments() -> String {
    ["/P", "/UPDATE", "/R", "/ARGS"].join(" ")
}

#[cfg(target_os = "windows")]
pub(crate) fn msi_arguments(path: &Path) -> String {
    format!("/i \"{}\" /passive /promptrestart AUTOLAUNCHAPP=True LAUNCHAPPARGS=\"\"", path.display())
}

#[cfg(target_os = "windows")]
mod platform {
    use super::*;

    enum Package {
        Nsis(PathBuf),
        Msi(PathBuf),
    }

    fn write(dir: &Path, name: &str, bytes: &[u8]) -> Result<PathBuf, String> {
        let path = dir.join(name);
        std::fs::write(&path, bytes).map_err(|e| e.to_string())?;
        Ok(path)
    }

    fn unpack(update: &UpdateInfo, bytes: &[u8]) -> Result<Package, String> {
        let dir = temp_dir_for(&update.version)?;
        if is_zip(bytes) {
            let (name, inner) = extract_from_zip(bytes, |n| {
                let n = n.to_lowercase();
                n.ends_with(".exe") || n.ends_with(".msi")
            })?;
            let path = write(&dir, &name, &inner)?;
            return Ok(if name.to_lowercase().ends_with(".msi") { Package::Msi(path) } else { Package::Nsis(path) });
        }
        if is_exe(bytes) {
            return write(&dir, &format!("GodotHub-{}-installer.exe", update.version), bytes).map(Package::Nsis);
        }
        if is_msi(bytes) {
            return write(&dir, &format!("GodotHub-{}-installer.msi", update.version), bytes).map(Package::Msi);
        }
        Err("The update is not a Windows installer".into())
    }

    fn wide(value: &std::ffi::OsStr) -> Vec<u16> {
        use std::os::windows::ffi::OsStrExt;
        value.encode_wide().chain(std::iter::once(0)).collect()
    }

    pub fn install(update: &UpdateInfo, bytes: &[u8]) -> Result<(), String> {
        use windows_sys::Win32::UI::Shell::ShellExecuteW;
        use windows_sys::Win32::UI::WindowsAndMessaging::SW_SHOW;
        if update.portable {
            return Err("Portable copies are updated by downloading the new release".into());
        }
        let (file, parameters) = match unpack(update, bytes)? {
            Package::Nsis(path) => (path.into_os_string(), nsis_arguments()),
            Package::Msi(path) => {
                let msiexec = std::env::var("SYSTEMROOT")
                    .map(|root| format!("{root}\\System32\\msiexec.exe"))
                    .unwrap_or_else(|_| "msiexec.exe".into());
                (msiexec.into(), msi_arguments(&path))
            }
        };
        let file = wide(&file);
        let parameters = wide(std::ffi::OsStr::new(&parameters));
        let verb = wide(std::ffi::OsStr::new("open"));
        let result = unsafe {
            ShellExecuteW(std::ptr::null_mut(), verb.as_ptr(), file.as_ptr(), parameters.as_ptr(), std::ptr::null(), SW_SHOW)
        };
        if result as isize <= 32 {
            return Err(format!("Could not start the installer (error {})", result as isize));
        }
        Ok(())
    }
}

#[cfg(target_os = "macos")]
mod platform {
    use super::*;
    use std::os::unix::fs::MetadataExt;

    fn swap_bundle(target: &Path, staged: &Path) -> std::io::Result<()> {
        use std::ffi::CString;
        use std::os::unix::ffi::OsStrExt;
        let from = CString::new(staged.as_os_str().as_bytes())?;
        let to = CString::new(target.as_os_str().as_bytes())?;
        if unsafe { libc::renamex_np(from.as_ptr(), to.as_ptr(), libc::RENAME_SWAP) } == 0 {
            Ok(())
        } else {
            Err(std::io::Error::last_os_error())
        }
    }

    fn replace_bundle(target: &Path, staged: &Path, backup: &Path) -> std::io::Result<()> {
        std::fs::rename(target, backup)?;
        if let Err(err) = std::fs::rename(staged, target) {
            let _ = std::fs::rename(backup, target);
            return Err(err);
        }
        Ok(())
    }

    fn sh_quote(path: &Path) -> String {
        format!("'{}'", path.to_string_lossy().replace('\'', r"'\''"))
    }

    fn privileged_replace(target: &Path, staged: &Path, backup: &Path) -> Result<(), String> {
        let command = format!(
            "mv -f {target} {backup} && {{ mv -f {staged} {target} || {{ mv -f {backup} {target}; exit 1; }}; }} && rm -rf {backup}",
            target = sh_quote(target),
            staged = sh_quote(staged),
            backup = sh_quote(backup),
        );
        let script = format!("do shell script \"{}\" with administrator privileges", command.replace('\\', "\\\\").replace('"', "\\\""));
        let status = std::process::Command::new("osascript").arg("-e").arg(script).status().map_err(|e| e.to_string())?;
        if status.success() {
            Ok(())
        } else {
            Err("Failed to move the new app into place".into())
        }
    }

    pub fn install(update: &UpdateInfo, bytes: &[u8]) -> Result<(), String> {
        let exe = std::env::current_exe().map_err(|e| e.to_string())?;
        let target = app_bundle_of(&exe).ok_or("GodotHub is not running from an .app bundle")?;
        if !is_gzip(bytes) {
            return Err("The update is not an .app.tar.gz archive".into());
        }
        let app_dev = std::fs::symlink_metadata(&target).map_err(|e| e.to_string())?.dev();
        let root = [Some(std::env::temp_dir()), target.parent().map(Path::to_path_buf)]
            .into_iter()
            .flatten()
            .find(|dir| dir.metadata().is_ok_and(|m| m.dev() == app_dev))
            .ok_or("No temporary folder on the same volume as GodotHub")?;
        let work = root.join(format!("godothub-update-{}-{}", update.version, std::process::id()));
        let staged = work.join("staged");
        let backup = work.join("backup");
        std::fs::create_dir_all(&staged).map_err(|e| e.to_string())?;
        let mut archive = tar::Archive::new(flate2::read::GzDecoder::new(std::io::Cursor::new(bytes)));
        for entry in archive.entries().map_err(|e| e.to_string())? {
            let mut entry = entry.map_err(|e| e.to_string())?;
            let inner: PathBuf = entry.path().map_err(|e| e.to_string())?.iter().skip(1).collect();
            if inner.as_os_str().is_empty() {
                continue;
            }
            let path = staged.join(&inner);
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
            }
            entry.unpack(&path).map_err(|e| e.to_string())?;
        }
        let result = match swap_bundle(&target, &staged) {
            Ok(()) => Ok(()),
            Err(err) if err.kind() == std::io::ErrorKind::PermissionDenied => privileged_replace(&target, &staged, &backup),
            Err(_) => replace_bundle(&target, &staged, &backup).or_else(|err| {
                if err.kind() == std::io::ErrorKind::PermissionDenied {
                    privileged_replace(&target, &staged, &backup)
                } else {
                    Err(err.to_string())
                }
            }),
        };
        if result.is_ok() {
            let _ = std::fs::remove_dir_all(&work);
            let _ = std::process::Command::new("touch").arg(&target).status();
        }
        result
    }
}

#[cfg(target_os = "linux")]
mod platform {
    use super::*;
    use std::os::unix::fs::{MetadataExt, PermissionsExt};

    fn temp_locations(near: &Path) -> Vec<PathBuf> {
        [Some(std::env::temp_dir()), dirs::cache_dir(), near.parent().map(Path::to_path_buf)]
            .into_iter()
            .flatten()
            .collect()
    }

    fn appimage_bytes(bytes: &[u8]) -> Result<Vec<u8>, String> {
        if is_zip(bytes) {
            let (_, inner) = extract_from_zip(bytes, |n| n.ends_with(".AppImage"))?;
            if !is_elf(&inner) {
                return Err("The update archive does not contain an AppImage".into());
            }
            return Ok(inner);
        }
        if is_elf(bytes) {
            return Ok(bytes.to_vec());
        }
        Err("The update is neither an AppImage nor a zipped AppImage".into())
    }

    fn install_appimage(bytes: &[u8]) -> Result<(), String> {
        let target = PathBuf::from(std::env::var_os("APPIMAGE").ok_or("GodotHub is not running as an AppImage")?);
        let image = appimage_bytes(bytes)?;
        let target_dev = target.metadata().map_err(|e| e.to_string())?.dev();
        let permissions = target.metadata().map_err(|e| e.to_string())?.permissions();
        for location in temp_locations(&target) {
            let backup_dir = location.join(format!("godothub-current-app-{}", std::process::id()));
            if std::fs::create_dir_all(&backup_dir).is_err() {
                continue;
            }
            if backup_dir.metadata().map(|m| m.dev()).ok() != Some(target_dev) {
                let _ = std::fs::remove_dir_all(&backup_dir);
                continue;
            }
            let _ = std::fs::set_permissions(&backup_dir, std::fs::Permissions::from_mode(0o700));
            let backup = backup_dir.join("current_app.AppImage");
            match std::fs::rename(&target, &backup) {
                Ok(()) => {}
                Err(err) if err.kind() == std::io::ErrorKind::CrossesDevices => continue,
                Err(err) => return Err(err.to_string()),
            }
            return match std::fs::write(&target, &image).and_then(|()| std::fs::set_permissions(&target, permissions)) {
                Ok(()) => {
                    let _ = std::fs::remove_dir_all(&backup_dir);
                    Ok(())
                }
                Err(err) => {
                    let _ = std::fs::rename(&backup, &target);
                    Err(err.to_string())
                }
            };
        }
        Err("No temporary folder on the same filesystem as the AppImage".into())
    }

    fn password_graphically() -> Option<String> {
        let ask = |cmd: &str, args: &[&str]| {
            std::process::Command::new(cmd)
                .args(args)
                .output()
                .ok()
                .filter(|o| o.status.success())
                .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        };
        ask("zenity", &["--password", "--title=Authentication Required", "--text=Enter your password to install the update:"])
            .or_else(|| ask("kdialog", &["--password", "Enter your password to install the update:"]))
    }

    fn install_package(bytes: &[u8], command: &str, arg: &str, extension: &str) -> Result<(), String> {
        use std::io::Write;
        let exe = std::env::current_exe().map_err(|e| e.to_string())?;
        for location in temp_locations(&exe) {
            let dir = location.join(format!("godothub_{extension}_update_{}", std::process::id()));
            if std::fs::create_dir_all(&dir).is_err() {
                continue;
            }
            let package = dir.join(format!("package.{extension}"));
            if std::fs::write(&package, bytes).is_err() {
                continue;
            }
            if std::process::Command::new("pkexec").arg(command).arg(arg).arg(&package).status().is_ok_and(|s| s.success()) {
                return Ok(());
            }
            if let Some(password) = password_graphically() {
                let child = std::process::Command::new("sudo")
                    .arg("-S")
                    .arg(command)
                    .arg(arg)
                    .arg(&package)
                    .stdin(std::process::Stdio::piped())
                    .stdout(std::process::Stdio::piped())
                    .stderr(std::process::Stdio::piped())
                    .spawn();
                if let Ok(mut child) = child {
                    if let Some(mut stdin) = child.stdin.take() {
                        let _ = writeln!(stdin, "{password}");
                    }
                    if child.wait().is_ok_and(|s| s.success()) {
                        return Ok(());
                    }
                }
            }
            let status = std::process::Command::new("sudo").arg(command).arg(arg).arg(&package).status().map_err(|e| e.to_string())?;
            return if status.success() { Ok(()) } else { Err("Failed to install the update package".into()) };
        }
        Err("No temporary folder is available".into())
    }

    pub fn install(update: &UpdateInfo, bytes: &[u8]) -> Result<(), String> {
        match update.installer {
            Some(Installer::Deb) if is_deb(bytes) => install_package(bytes, "dpkg", "-i", "deb"),
            Some(Installer::Deb) => Err("The update is not a valid deb package".into()),
            Some(Installer::Rpm) if is_rpm(bytes) => install_package(bytes, "rpm", "-U", "rpm"),
            Some(Installer::Rpm) => Err("The update is not a valid rpm package".into()),
            _ => install_appimage(bytes),
        }
    }
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
mod platform {
    use super::*;

    pub fn install(_update: &UpdateInfo, _bytes: &[u8]) -> Result<(), String> {
        Err("Updates are not supported on this operating system".into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn manifest(platforms: &[&str]) -> Manifest {
        let entries: Vec<String> = platforms
            .iter()
            .map(|k| format!(r#""{k}": {{"signature": "sig-{k}", "url": "https://github.com/x/{k}.bin"}}"#))
            .collect();
        Manifest::parse(&format!(
            r#"{{"version": "1.6.0", "notes": "n", "pub_date": "2026-01-01T00:00:00Z", "platforms": {{{}}}}}"#,
            entries.join(",")
        ))
        .unwrap()
    }

    #[test]
    fn manifests_parse_static_and_dynamic_shapes() {
        let m = manifest(&["windows-x86_64", "windows-x86_64-nsis"]);
        assert_eq!(m.version, semver::Version::new(1, 6, 0));
        assert_eq!(m.notes.as_deref(), Some("n"));
        assert_eq!(m.entry("windows-x86_64-nsis").unwrap().signature, "sig-windows-x86_64-nsis");
        let dynamic = Manifest::parse(r#"{"version": "v2.0.0", "url": "https://x/y", "signature": "s"}"#).unwrap();
        assert_eq!(dynamic.version, semver::Version::new(2, 0, 0));
        assert_eq!(dynamic.entry("anything").unwrap().url, "https://x/y");
        assert!(Manifest::parse(r#"{"version": "nope", "platforms": {}}"#).is_err());
    }

    #[test]
    fn platform_keys_try_the_installer_first_then_the_plain_target() {
        assert_eq!(target_keys("windows", "x86_64", Some(Installer::Nsis)), ["windows-x86_64-nsis", "windows-x86_64"]);
        assert_eq!(target_keys("linux", "x86_64", None), ["linux-x86_64"]);
        let m = manifest(&["windows-x86_64", "windows-x86_64-msi", "darwin-aarch64-app", "linux-x86_64-appimage"]);
        assert_eq!(m.select(&target_keys("windows", "x86_64", Some(Installer::Msi))).unwrap().0, "windows-x86_64-msi");
        assert_eq!(m.select(&target_keys("windows", "x86_64", Some(Installer::Nsis))).unwrap().0, "windows-x86_64");
        assert_eq!(m.select(&target_keys("darwin", "aarch64", Some(Installer::App))).unwrap().0, "darwin-aarch64-app");
        assert!(m.select(&target_keys("linux", "x86_64", Some(Installer::Deb))).is_none());
        assert_eq!(m.select(&target_keys("linux", "x86_64", Some(Installer::AppImage))).unwrap().0, "linux-x86_64-appimage");
    }

    #[test]
    fn current_platform_update_is_found_only_for_newer_versions() {
        let os = updater_os().unwrap();
        let arch = updater_arch().unwrap();
        let m = manifest(&[&format!("{os}-{arch}")]);
        let update = update_from_manifest(&m, "1.5.9", InstallKind::Unknown).unwrap().unwrap();
        assert_eq!(update.version, "1.6.0");
        assert_eq!(update.target, format!("{os}-{arch}"));
        assert!(!update.send_token);
        assert!(update_from_manifest(&m, "1.6.0", InstallKind::Unknown).unwrap().is_none());
        assert!(update_from_manifest(&m, "2.0.0", InstallKind::Unknown).unwrap().is_none());
        let portable = update_from_manifest(&m, "1.0.0", InstallKind::Portable).unwrap().unwrap();
        assert!(portable.portable);
        let none = manifest(&["plan9-x86_64"]);
        assert!(update_from_manifest(&none, "1.0.0", InstallKind::Unknown).is_err());
    }

    #[test]
    fn channels_read_their_own_endpoint() {
        assert_eq!(endpoint(Channel::Beta), "https://github.com/RykoTheDev/godothub/releases/download/flutter-beta/latest.json");
        assert_eq!(endpoint(Channel::Stable), "https://github.com/RykoTheDev/godothub/releases/latest/download/latest-v2.json");
        assert_eq!(Channel::Stable.info().updater_public_keys, Channel::Beta.info().updater_public_keys);
        assert!(!Channel::Stable.info().updater_public_keys.is_empty());
    }

    #[test]
    fn token_is_only_sent_to_github_api_downloads() {
        let api = Manifest::parse(r#"{"version": "1.0.0", "platforms": {"a": {"url": "https://api.github.com/x", "signature": "s"}}}"#).unwrap();
        assert!(api.downloads_from_github_api());
        let mixed = Manifest::parse(
            r#"{"version": "1.0.0", "platforms": {"a": {"url": "https://api.github.com/x", "signature": "s"}, "b": {"url": "https://github.com/x", "signature": "s"}}}"#,
        )
        .unwrap();
        assert!(!mixed.downloads_from_github_api());
    }

    #[test]
    fn app_bundles_are_found_from_the_executable() {
        let exe = Path::new("/Applications/GodotHub Beta.app/Contents/MacOS/godothub-beta");
        assert_eq!(app_bundle_of(exe).unwrap(), Path::new("/Applications/GodotHub Beta.app"));
        assert!(app_bundle_of(Path::new("/usr/bin/godothub")).is_none());
    }

    #[test]
    fn formats_are_recognised_by_their_magic_bytes() {
        assert!(is_exe(b"MZ\x90\x00"));
        assert!(is_msi(&[0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, 0]));
        assert!(is_zip(b"PK\x03\x04rest"));
        assert!(is_elf(b"\x7fELF\x02"));
        assert!(is_gzip(&[0x1F, 0x8B, 8]));
        assert!(is_deb(b"!<arch>\ndebian-binary   "));
        assert!(is_rpm(&[0xED, 0xAB, 0xEE, 0xDB, 3]));
        assert!(!is_exe(b"PK\x03\x04"));
    }

    #[test]
    fn zipped_appimages_are_extracted() {
        use std::io::Write;
        let mut buffer = std::io::Cursor::new(Vec::new());
        {
            let mut zip = zip::ZipWriter::new(&mut buffer);
            let options = zip::write::SimpleFileOptions::default();
            zip.start_file("GodotHub-Beta-1.6.0-linux-amd64.AppImage", options).unwrap();
            zip.write_all(b"\x7fELFpayload").unwrap();
            zip.finish().unwrap();
        }
        let bytes = buffer.into_inner();
        assert!(is_zip(&bytes));
        let (name, inner) = extract_from_zip(&bytes, |n| n.ends_with(".AppImage")).unwrap();
        assert_eq!(name, "GodotHub-Beta-1.6.0-linux-amd64.AppImage");
        assert_eq!(inner, b"\x7fELFpayload");
        assert!(extract_from_zip(&bytes, |n| n.ends_with(".exe")).is_err());
    }

    fn keypair() -> (String, minisign::SecretKey) {
        let pair = minisign::KeyPair::generate_unencrypted_keypair().unwrap();
        let public = base64::engine::general_purpose::STANDARD.encode(pair.pk.to_box().unwrap().to_string());
        (public, pair.sk)
    }

    fn sign(secret: &minisign::SecretKey, data: &[u8], trusted: &str) -> String {
        let signature = minisign::sign(None, secret, std::io::Cursor::new(data), Some(trusted), Some("signature")).unwrap();
        base64::engine::general_purpose::STANDARD.encode(signature.to_string())
    }

    #[test]
    fn signatures_verify_against_any_trusted_key() {
        let (old_public, old_secret) = keypair();
        let (new_public, new_secret) = keypair();
        let data = b"installer bytes";
        let signed_old = sign(&old_secret, data, "timestamp:1\tfile:x");
        let signed_new = sign(&new_secret, data, "timestamp:1\tfile:x\tversion:1.6.0");
        assert!(verify_signature(data, &signed_old, &[&old_public], "1.6.0").is_ok());
        assert!(verify_signature(data, &signed_new, &[&old_public, &new_public], "1.6.0").is_ok());
        assert!(verify_signature(data, &signed_new, &[&old_public], "1.6.0").is_err());
        assert!(verify_signature(b"tampered bytes", &signed_old, &[&old_public], "1.6.0").is_err());
        assert!(verify_signature(data, &signed_new, &[&new_public], "1.7.0").is_err());
        assert!(verify_signature(data, &signed_new, &[&new_public], "v1.6.0").is_ok());
        assert!(verify_signature(data, &signed_old, &[], "1.6.0").is_err());
    }

    #[test]
    fn the_frozen_legacy_manifest_still_resolves_every_installer() {
        let legacy = Manifest::parse(include_str!("../../../.github/updater/legacy-latest.json")).unwrap();
        assert_eq!(legacy.version, semver::Version::new(1, 5, 6));
        assert!(legacy.notes.as_deref().unwrap().contains("## "));
        for (os, arch, installer, key) in [
            ("windows", "x86_64", Some(Installer::Nsis), "windows-x86_64-nsis"),
            ("windows", "x86_64", Some(Installer::Msi), "windows-x86_64-msi"),
            ("darwin", "aarch64", Some(Installer::App), "darwin-aarch64-app"),
            ("darwin", "x86_64", None, "darwin-x86_64"),
            ("linux", "x86_64", Some(Installer::AppImage), "linux-x86_64-appimage"),
            ("linux", "x86_64", Some(Installer::Deb), "linux-x86_64-deb"),
            ("linux", "x86_64", Some(Installer::Rpm), "linux-x86_64-rpm"),
        ] {
            assert_eq!(legacy.select(&target_keys(os, arch, installer)).unwrap().0, key);
        }
    }

    #[test]
    fn the_shipped_key_decodes() {
        let text = decode_base64_text(Channel::Beta.info().updater_public_keys[0]).unwrap();
        assert!(minisign_verify::PublicKey::decode(&text).is_ok());
        assert!(text.contains("465E29F5EA1A2214"));
    }

    #[cfg(target_os = "windows")]
    #[test]
    fn windows_installer_arguments_match_the_tauri_updater() {
        assert_eq!(nsis_arguments(), "/P /UPDATE /R /ARGS");
        assert_eq!(
            msi_arguments(Path::new(r"C:\t\GodotHub.msi")),
            r#"/i "C:\t\GodotHub.msi" /passive /promptrestart AUTOLAUNCHAPP=True LAUNCHAPPARGS="""#
        );
    }
}
