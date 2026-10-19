use crate::models::InstalledGodotVersion;
use futures_util::StreamExt;
use serde::Serialize;
use sha2::{Digest, Sha512};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::{Read, Write};
use std::path::{Component, Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter, Manager};

const TPZ_REPO: &str = "godotengine/godot-builds";
const MAX_EXTRACTED_BYTES: u64 = 8 * 1024 * 1024 * 1024;
const PROGRESS_INTERVAL: Duration = Duration::from_millis(250);

#[derive(Clone, Serialize)]
pub struct ExportTemplatesProgress {
    pub tag: String,
    pub downloaded: u64,
    pub total: u64,
}

#[derive(Clone, Serialize)]
pub struct ExportTemplatesStage {
    pub tag: String,
    pub stage: String,
}

#[derive(Clone, Serialize)]
pub struct ExportTemplatesError {
    pub tag: String,
    pub message: String,
}

#[derive(Serialize)]
pub struct ExportTemplatesVersionInfo {
    pub tag: String,
    pub folder: String,
    pub root: String,
    pub templates_dir: String,
    pub installed: bool,
    pub downloading: bool,
    pub size_bytes: u64,
    pub file_count: usize,
}

#[derive(Serialize)]
pub struct ExportTemplatesOrphan {
    pub folder: String,
    pub path: String,
    pub root: String,
    pub size_bytes: u64,
    pub file_count: usize,
}

#[derive(Serialize)]
pub struct ExportTemplatesState {
    pub default_dir: String,
    pub versions: Vec<ExportTemplatesVersionInfo>,
    pub orphans: Vec<ExportTemplatesOrphan>,
}

#[derive(Serialize)]
pub struct ExportTemplatesInstallResult {
    pub tag: String,
    pub folder: String,
    pub verified: bool,
    pub size_bytes: u64,
    pub file_count: usize,
}

pub fn template_folder_for(tag: &str, is_mono: bool) -> String {
    let cleaned = tag.trim().trim_start_matches('v');
    let (base, mono_from_tag) = match cleaned.strip_suffix("-mono") {
        Some(rest) => (rest, true),
        None => (cleaned, false),
    };

    let (version, status) = match base.split_once('-') {
        Some((version, status)) if !status.is_empty() => (version, status),
        _ => (base, "stable"),
    };

    let mut parts: Vec<&str> = version.split('.').filter(|p| !p.is_empty()).collect();
    // Godot only includes the patch number when it is non-zero: 4.3.0 -> 4.3.
    if parts.len() >= 3 && parts.last() == Some(&"0") {
        parts.pop();
    }
    let version = parts.join(".");

    if is_mono || mono_from_tag {
        format!("{version}.{status}.mono")
    } else {
        format!("{version}.{status}")
    }
}

fn release_base_tag(tag: &str) -> String {
    let cleaned = tag.trim().trim_start_matches('v');
    cleaned.strip_suffix("-mono").unwrap_or(cleaned).to_string()
}

fn tpz_file_name(tag: &str, is_mono: bool) -> String {
    let base = release_base_tag(tag);
    if is_mono {
        format!("Godot_v{base}_mono_export_templates.tpz")
    } else {
        format!("Godot_v{base}_export_templates.tpz")
    }
}

fn tpz_url(tag: &str, is_mono: bool) -> String {
    let base = release_base_tag(tag);
    let file = tpz_file_name(tag, is_mono);
    format!("https://github.com/{TPZ_REPO}/releases/download/{base}/{file}")
}

fn sums_url(tag: &str) -> String {
    let base = release_base_tag(tag);
    format!("https://github.com/{TPZ_REPO}/releases/download/{base}/SHA512-SUMS.txt")
}

#[cfg(target_os = "windows")]
fn default_templates_root() -> Option<PathBuf> {
    std::env::var_os("APPDATA").map(|dir| PathBuf::from(dir).join("Godot").join("export_templates"))
}

#[cfg(target_os = "macos")]
fn default_templates_root() -> Option<PathBuf> {
    std::env::var_os("HOME").map(|dir| {
        PathBuf::from(dir)
            .join("Library")
            .join("Application Support")
            .join("Godot")
            .join("export_templates")
    })
}

#[cfg(all(unix, not(target_os = "macos")))]
fn default_templates_root() -> Option<PathBuf> {
    if let Some(data_home) = std::env::var_os("XDG_DATA_HOME").filter(|v| !v.is_empty()) {
        return Some(PathBuf::from(data_home).join("godot").join("export_templates"));
    }
    std::env::var_os("HOME")
        .map(|dir| PathBuf::from(dir).join(".local").join("share").join("godot").join("export_templates"))
}

/// Godot in self-contained mode keeps everything next to the executable.
fn self_contained_root(executable_path: &str) -> Option<PathBuf> {
    let exe_dir = Path::new(executable_path).parent()?;
    if exe_dir.join("_sc_").is_file() || exe_dir.join("._sc_").is_file() {
        Some(
            exe_dir
                .join("editor_data")
                .join("export_templates"),
        )
    } else {
        None
    }
}

fn templates_root_for(version: &InstalledGodotVersion) -> Option<PathBuf> {
    self_contained_root(&version.executable_path).or_else(default_templates_root)
}

fn downloads_dir(app: &AppHandle) -> PathBuf {
    let dir = app
        .path()
        .app_data_dir()
        .map(|base| base.join("export-template-downloads"))
        .unwrap_or_else(|_| std::env::temp_dir().join("godothub-export-templates"));
    let _ = fs::create_dir_all(&dir);
    dir
}

fn active_downloads() -> &'static Mutex<HashMap<String, Arc<AtomicBool>>> {
    static ACTIVE: OnceLock<Mutex<HashMap<String, Arc<AtomicBool>>>> = OnceLock::new();
    ACTIVE.get_or_init(|| Mutex::new(HashMap::new()))
}

fn is_downloading(tag: &str) -> bool {
    active_downloads()
        .lock()
        .map(|map| map.contains_key(tag))
        .unwrap_or(false)
}

struct CancelRegistration {
    tag: String,
}

impl Drop for CancelRegistration {
    fn drop(&mut self) {
        if let Ok(mut map) = active_downloads().lock() {
            map.remove(&self.tag);
        }
    }
}

fn is_valid_folder_name(name: &str) -> bool {
    !name.is_empty()
        && name.len() <= 128
        && !name.starts_with('.')
        && name != ".."
        && name
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '_' | '-'))
}

fn dir_stats(path: &Path) -> (u64, usize) {
    fn walk(dir: &Path, depth: u8) -> (u64, usize) {
        if depth > 4 {
            return (0, 0);
        }
        let Ok(entries) = fs::read_dir(dir) else {
            return (0, 0);
        };
        let mut total = 0u64;
        let mut count = 0usize;
        for entry in entries.flatten() {
            let path = entry.path();
            let Ok(meta) = entry.metadata() else {
                continue;
            };
            if meta.file_type().is_symlink() {
                continue;
            }
            if meta.is_dir() {
                let (size, files) = walk(&path, depth + 1);
                total += size;
                count += files;
            } else if meta.is_file() {
                total += meta.len();
                count += 1;
            }
        }
        (total, count)
    }

    if path.is_dir() {
        walk(path, 0)
    } else {
        (0, 0)
    }
}

fn known_roots(app: &AppHandle) -> Vec<PathBuf> {
    let mut roots: Vec<PathBuf> = Vec::new();
    if let Some(default) = default_templates_root() {
        roots.push(default);
    }
    for version in crate::godot_versions::read_registry(app) {
        if let Some(root) = self_contained_root(&version.executable_path) {
            roots.push(root);
        }
    }
    roots.dedup();
    roots
}

fn canonical(path: &Path) -> PathBuf {
    path.canonicalize().unwrap_or_else(|_| path.to_path_buf())
}

fn build_state(app: &AppHandle) -> Result<ExportTemplatesState, String> {
    let default_root = default_templates_root()
        .ok_or_else(|| "Could not locate Godot's data folder on this system".to_string())?;
    let registry = crate::godot_versions::read_registry(app);

    let mut versions = Vec::with_capacity(registry.len());
    let mut expected: HashSet<PathBuf> = HashSet::new();

    for version in &registry {
        let folder = template_folder_for(&version.tag, version.is_mono);
        if !is_valid_folder_name(&folder) {
            continue;
        }
        let root = templates_root_for(version).unwrap_or_else(|| default_root.clone());
        let dir = root.join(&folder);
        let (size_bytes, file_count) = dir_stats(&dir);
        expected.insert(canonical(&dir));
        versions.push(ExportTemplatesVersionInfo {
            tag: version.tag.clone(),
            folder,
            root: root.to_string_lossy().to_string(),
            templates_dir: dir.to_string_lossy().to_string(),
            installed: dir.is_dir(),
            downloading: is_downloading(&version.tag),
            size_bytes,
            file_count,
        });
    }

    let mut orphans = Vec::new();
    let mut seen_roots: HashSet<PathBuf> = HashSet::new();
    for root in known_roots(app) {
        if !root.is_dir() || !seen_roots.insert(canonical(&root)) {
            continue;
        }
        let Ok(entries) = fs::read_dir(&root) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if !path.is_dir() {
                continue;
            }
            let Some(folder) = path.file_name().and_then(|name| name.to_str()) else {
                continue;
            };
            if folder.starts_with('.') || expected.contains(&canonical(&path)) {
                continue;
            }
            let (size_bytes, file_count) = dir_stats(&path);
            orphans.push(ExportTemplatesOrphan {
                folder: folder.to_string(),
                path: path.to_string_lossy().to_string(),
                root: root.to_string_lossy().to_string(),
                size_bytes,
                file_count,
            });
        }
    }
    orphans.sort_by(|a, b| a.folder.cmp(&b.folder));

    Ok(ExportTemplatesState {
        default_dir: default_root.to_string_lossy().to_string(),
        versions,
        orphans,
    })
}

#[tauri::command]
pub async fn get_export_templates_state(app: AppHandle) -> Result<ExportTemplatesState, String> {
    tokio::task::spawn_blocking(move || build_state(&app))
        .await
        .map_err(|e| e.to_string())?
}

fn parse_content_range_start(value: &str) -> Option<u64> {
    let rest = value.trim().strip_prefix("bytes")?.trim_start();
    let (range, _) = rest.split_once('/')?;
    let (start, _) = range.split_once('-')?;
    start.trim().parse().ok()
}

fn parse_content_range_total(value: &str) -> Option<u64> {
    let rest = value.trim().strip_prefix("bytes")?.trim_start();
    let (_, total) = rest.split_once('/')?;
    let total = total.trim();
    if total == "*" {
        return None;
    }
    total.parse().ok()
}

fn hash_file(path: &Path) -> Result<String, String> {
    let mut file = fs::File::open(path).map_err(|e| e.to_string())?;
    let mut hasher = Sha512::new();
    let mut buffer = vec![0u8; 1024 * 1024];
    loop {
        let read = file.read(&mut buffer).map_err(|e| e.to_string())?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(hasher
        .finalize()
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect())
}

async fn expected_checksum(tag: &str, file_name: &str) -> Option<String> {
    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .timeout(Duration::from_secs(20))
        .build()
        .ok()?;
    let response = client.get(sums_url(tag)).send().await.ok()?;
    if !response.status().is_success() {
        return None;
    }
    let text = response.text().await.ok()?;
    for line in text.lines() {
        let mut parts = line.split_whitespace();
        let (Some(hash), Some(name)) = (parts.next(), parts.next()) else {
            continue;
        };
        if name.trim_start_matches('*') == file_name {
            return Some(hash.to_ascii_lowercase());
        }
    }
    None
}

async fn download_tpz(
    app: &AppHandle,
    tag: &str,
    url: &str,
    destination: &Path,
    cancel: Arc<AtomicBool>,
) -> Result<(), String> {
    if let Some(parent) = destination.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }

    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .connect_timeout(Duration::from_secs(30))
        .build()
        .map_err(|e| e.to_string())?;

    let mut existing = fs::metadata(destination).map(|m| m.len()).unwrap_or(0);
    let mut restarts = 0u8;

    loop {
        let mut request = client.get(url);
        if existing > 0 {
            request = request.header(reqwest::header::RANGE, format!("bytes={existing}-"));
        }
        let response = request
            .send()
            .await
            .map_err(|e| format!("Download failed: {e}"))?;
        let status = response.status();

        if status == reqwest::StatusCode::RANGE_NOT_SATISFIABLE && existing > 0 {
            restarts += 1;
            if restarts > 2 {
                return Err("Download could not be resumed and restarting failed".into());
            }
            let _ = fs::remove_file(destination);
            existing = 0;
            continue;
        }
        if !status.is_success() {
            return Err(format!("Download failed: HTTP {status}"));
        }

        let resuming = existing > 0 && status == reqwest::StatusCode::PARTIAL_CONTENT;
        if existing > 0 && !resuming {
            // The server ignored our Range header. Appending would corrupt the
            // archive, so start over instead.
            let _ = fs::remove_file(destination);
            existing = 0;
        }
        if resuming {
            let start = response
                .headers()
                .get(reqwest::header::CONTENT_RANGE)
                .and_then(|value| value.to_str().ok())
                .and_then(parse_content_range_start);
            if start != Some(existing) {
                restarts += 1;
                if restarts > 2 {
                    return Err("Download could not be resumed cleanly".into());
                }
                let _ = fs::remove_file(destination);
                existing = 0;
                continue;
            }
        }

        let total = if resuming {
            response
                .headers()
                .get(reqwest::header::CONTENT_RANGE)
                .and_then(|value| value.to_str().ok())
                .and_then(parse_content_range_total)
                .or_else(|| response.content_length().map(|len| len + existing))
                .unwrap_or(0)
        } else {
            response.content_length().unwrap_or(0)
        };

        let mut file = if resuming {
            fs::OpenOptions::new()
                .append(true)
                .open(destination)
                .map_err(|e| e.to_string())?
        } else {
            fs::OpenOptions::new()
                .create(true)
                .write(true)
                .truncate(true)
                .open(destination)
                .map_err(|e| e.to_string())?
        };

        let mut downloaded = existing;
        let mut last_emit = Instant::now() - PROGRESS_INTERVAL;
        let mut stream = response.bytes_stream();
        loop {
            if cancel.load(Ordering::SeqCst) {
                drop(file);
                let _ = fs::remove_file(destination);
                return Err("__canceled__".into());
            }
            // Without a per-chunk timeout a dead connection would keep the task
            // (and the cancel flag) waiting forever.
            let next = tokio::time::timeout(Duration::from_secs(30), stream.next()).await;
            let chunk = match next {
                Err(_) => {
                    drop(file);
                    return Err("The download stalled. Try again to resume it.".into());
                }
                Ok(None) => break,
                Ok(Some(Ok(chunk))) => chunk,
                Ok(Some(Err(error))) => {
                    drop(file);
                    return Err(format!("Download failed: {error}"));
                }
            };
            file.write_all(&chunk).map_err(|e| e.to_string())?;
            downloaded += chunk.len() as u64;
            if last_emit.elapsed() >= PROGRESS_INTERVAL {
                last_emit = Instant::now();
                let _ = app.emit(
                    "export-templates-progress",
                    ExportTemplatesProgress {
                        tag: tag.to_string(),
                        downloaded,
                        total,
                    },
                );
            }
        }
        drop(file);
        let _ = app.emit(
            "export-templates-progress",
            ExportTemplatesProgress {
                tag: tag.to_string(),
                downloaded,
                total,
            },
        );
        return Ok(());
    }
}

fn strip_templates_prefix(path: &Path) -> PathBuf {
    let mut components = path.components();
    if let Some(Component::Normal(first)) = components.next() {
        if first.eq_ignore_ascii_case("templates") {
            return components.as_path().to_path_buf();
        }
    }
    path.to_path_buf()
}

fn extract_tpz(archive_path: &Path, destination: &Path) -> Result<(u64, usize), String> {
    let file = fs::File::open(archive_path).map_err(|e| e.to_string())?;
    let mut archive = zip::ZipArchive::new(file).map_err(|e| format!("Invalid template archive: {e}"))?;

    fs::create_dir_all(destination).map_err(|e| e.to_string())?;

    let mut total = 0u64;
    let mut count = 0usize;
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index).map_err(|e| e.to_string())?;
        if entry.is_symlink() {
            continue;
        }
        // `enclosed_name` rejects absolute paths and `..` traversal.
        let Some(path) = entry.enclosed_name() else {
            continue;
        };
        let relative = strip_templates_prefix(&path);
        if relative.as_os_str().is_empty() {
            continue;
        }
        let out_path = destination.join(&relative);
        if entry.is_dir() {
            fs::create_dir_all(&out_path).map_err(|e| e.to_string())?;
            continue;
        }
        if let Some(parent) = out_path.parent() {
            fs::create_dir_all(parent).map_err(|e| e.to_string())?;
        }
        if total.saturating_add(entry.size()) > MAX_EXTRACTED_BYTES {
            return Err("Template archive exceeds the expected size".into());
        }
        let mut out = fs::File::create(&out_path).map_err(|e| e.to_string())?;
        total += std::io::copy(&mut entry, &mut out).map_err(|e| e.to_string())?;
        count += 1;
    }

    if count == 0 {
        return Err("Template archive did not contain any files".into());
    }
    Ok((total, count))
}

/// Extract into a staging directory, then swap it into place so a failed or
/// canceled install never leaves a half-written template folder behind.
fn install_archive(archive_path: &Path, root: &Path, folder: &str) -> Result<(u64, usize), String> {
    if !is_valid_folder_name(folder) {
        return Err("Invalid export template folder name".into());
    }
    fs::create_dir_all(root).map_err(|e| e.to_string())?;

    let target = root.join(folder);
    let staging = root.join(format!(".{folder}.installing"));
    let previous = root.join(format!(".{folder}.previous"));

    let _ = fs::remove_dir_all(&staging);
    // A previous crashed swap can leave the backup behind; restore it rather
    // than treating the templates as lost.
    if !target.exists() && previous.exists() {
        let _ = fs::rename(&previous, &target);
    }
    let _ = fs::remove_dir_all(&previous);

    let extracted = match extract_tpz(archive_path, &staging) {
        Ok(stats) => stats,
        Err(error) => {
            let _ = fs::remove_dir_all(&staging);
            return Err(error);
        }
    };

    if target.exists() {
        fs::rename(&target, &previous).map_err(|e| {
            let _ = fs::remove_dir_all(&staging);
            format!("Could not replace the existing template folder: {e}")
        })?;
    }

    if let Err(e) = fs::rename(&staging, &target) {
        if previous.exists() {
            let _ = fs::rename(&previous, &target);
        }
        let _ = fs::remove_dir_all(&staging);
        return Err(format!("Could not finish installing templates: {e}"));
    }

    if previous.exists() {
        let _ = fs::remove_dir_all(&previous);
    }
    Ok(extracted)
}

#[tauri::command]
pub async fn install_export_templates(
    app: AppHandle,
    tag: String,
) -> Result<Option<ExportTemplatesInstallResult>, String> {
    let registry = crate::godot_versions::read_registry(&app);
    let version = registry
        .iter()
        .find(|version| version.tag == tag)
        .ok_or_else(|| "This Godot version is not installed".to_string())?
        .clone();

    let root = templates_root_for(&version)
        .ok_or_else(|| "Could not locate Godot's data folder on this system".to_string())?;
    let folder = template_folder_for(&version.tag, version.is_mono);
    if !is_valid_folder_name(&folder) {
        return Err("Could not derive the export template folder for this version".into());
    }

    let cancel = Arc::new(AtomicBool::new(false));
    {
        let mut active = active_downloads().lock().map_err(|e| e.to_string())?;
        if active.contains_key(&tag) {
            return Err("Export templates are already downloading for this version".into());
        }
        active.insert(tag.clone(), cancel.clone());
    }
    let _registration = CancelRegistration { tag: tag.clone() };

    let url = tpz_url(&version.tag, version.is_mono);
    let file_name = tpz_file_name(&version.tag, version.is_mono);
    let archive_path = downloads_dir(&app).join(format!("{folder}.tpz"));

    let _ = app.emit("export-templates-queued", &tag);

    let fail = |app: &AppHandle, message: String| -> Result<Option<ExportTemplatesInstallResult>, String> {
        let _ = app.emit(
            "export-templates-error",
            ExportTemplatesError {
                tag: tag.clone(),
                message: message.clone(),
            },
        );
        Err(message)
    };

    if let Err(message) = download_tpz(&app, &tag, &url, &archive_path, cancel.clone()).await {
        if message == "__canceled__" {
            let _ = app.emit("export-templates-canceled", &tag);
            return Ok(None);
        }
        return fail(&app, message);
    }

    let mut verified = false;
    if let Some(expected) = expected_checksum(&version.tag, &file_name).await {
        let _ = app.emit(
            "export-templates-stage",
            ExportTemplatesStage {
                tag: tag.clone(),
                stage: "verifying".into(),
            },
        );
        let archive_for_hash = archive_path.clone();
        let actual = tokio::task::spawn_blocking(move || hash_file(&archive_for_hash))
            .await
            .map_err(|e| e.to_string())?;
        match actual {
            Ok(actual) if actual.eq_ignore_ascii_case(&expected) => verified = true,
            Ok(_) => {
                let _ = fs::remove_file(&archive_path);
                return fail(
                    &app,
                    "The downloaded export templates failed checksum verification".into(),
                );
            }
            Err(error) => return fail(&app, error),
        }
    }

    let _ = app.emit(
        "export-templates-stage",
        ExportTemplatesStage {
            tag: tag.clone(),
            stage: "extracting".into(),
        },
    );

    let archive_for_extract = archive_path.clone();
    let root_for_extract = root.clone();
    let folder_for_extract = folder.clone();
    let extracted = tokio::task::spawn_blocking(move || {
        install_archive(&archive_for_extract, &root_for_extract, &folder_for_extract)
    })
    .await
    .map_err(|e| e.to_string())?;

    let (size_bytes, file_count) = match extracted {
        Ok(stats) => stats,
        Err(error) => {
            return fail(&app, error);
        }
    };

    let _ = fs::remove_file(&archive_path);
    let _ = app.emit("export-templates-complete", &tag);

    Ok(Some(ExportTemplatesInstallResult {
        tag,
        folder,
        verified,
        size_bytes,
        file_count,
    }))
}

#[tauri::command]
pub fn cancel_export_templates_download(tag: String) -> Result<(), String> {
    let active = active_downloads().lock().map_err(|e| e.to_string())?;
    if let Some(flag) = active.get(&tag) {
        flag.store(true, Ordering::SeqCst);
    }
    Ok(())
}

#[tauri::command]
pub async fn delete_export_templates(
    app: AppHandle,
    folder: String,
    root: Option<String>,
) -> Result<(), String> {
    if !is_valid_folder_name(&folder) {
        return Err("Invalid export template folder name".into());
    }

    let roots = known_roots(&app);
    let target_root = match root {
        Some(root) => {
            let candidate = PathBuf::from(root);
            if !roots
                .iter()
                .any(|known| canonical(known) == canonical(&candidate))
            {
                return Err("Refusing to delete outside Godot's template folders".into());
            }
            candidate
        }
        None => roots
            .into_iter()
            .next()
            .ok_or_else(|| "Could not locate Godot's data folder on this system".to_string())?,
    };

    let target = target_root.join(&folder);
    if !target.is_dir() {
        return Err("This template folder is not installed".into());
    }
    if canonical(target.parent().unwrap_or(&target_root)) != canonical(&target_root) {
        return Err("Refusing to delete outside Godot's template folders".into());
    }

    tokio::task::spawn_blocking(move || {
        if let Err(error) = trash::delete_all([&target]) {
            eprintln!("[delete_export_templates] trash failed for {target:?}: {error}");
            fs::remove_dir_all(&target).map_err(|e| e.to_string())?;
        }
        Ok::<(), String>(())
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub fn open_export_templates_folder(app: AppHandle, tag: Option<String>) -> Result<(), String> {
    let dir = match tag {
        Some(tag) => {
            let registry = crate::godot_versions::read_registry(&app);
            let version = registry
                .iter()
                .find(|version| version.tag == tag)
                .ok_or_else(|| "This Godot version is not installed".to_string())?;
            let folder = template_folder_for(&version.tag, version.is_mono);
            if !is_valid_folder_name(&folder) {
                return Err("Could not derive the export template folder for this version".into());
            }
            let root = templates_root_for(version)
                .ok_or_else(|| "Could not locate Godot's data folder on this system".to_string())?;
            root.join(folder)
        }
        None => default_templates_root()
            .ok_or_else(|| "Could not locate Godot's data folder on this system".to_string())?,
    };
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    crate::projects::open_project_folder(dir.to_string_lossy().to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stable_tag_maps_to_godot_version_folder() {
        assert_eq!(template_folder_for("4.3-stable", false), "4.3.stable");
        assert_eq!(template_folder_for("4.3.1-stable", false), "4.3.1.stable");
        assert_eq!(template_folder_for("v4.2-stable", false), "4.2.stable");
    }

    #[test]
    fn mono_suffix_is_preserved() {
        assert_eq!(template_folder_for("4.3-stable-mono", true), "4.3.stable.mono");
        assert_eq!(template_folder_for("4.3-stable-mono", false), "4.3.stable.mono");
        assert_eq!(template_folder_for("4.3.1-stable", true), "4.3.1.stable.mono");
    }

    #[test]
    fn prerelease_status_becomes_folder_suffix() {
        assert_eq!(template_folder_for("4.4-beta1", false), "4.4.beta1");
        assert_eq!(template_folder_for("4.4-rc1", false), "4.4.rc1");
        assert_eq!(template_folder_for("4.4-dev", false), "4.4.dev");
    }

    #[test]
    fn missing_patch_and_status_are_normalized() {
        assert_eq!(template_folder_for("4.3.0", false), "4.3.stable");
        assert_eq!(template_folder_for("4.3", false), "4.3.stable");
    }

    #[test]
    fn tpz_names_match_the_official_release_assets() {
        assert_eq!(
            tpz_file_name("4.3-stable", false),
            "Godot_v4.3-stable_export_templates.tpz"
        );
        assert_eq!(
            tpz_file_name("4.3-stable-mono", true),
            "Godot_v4.3-stable_mono_export_templates.tpz"
        );
        assert!(tpz_url("4.3.1-stable", false)
            .ends_with("/4.3.1-stable/Godot_v4.3.1-stable_export_templates.tpz"));
    }

    #[test]
    fn folder_names_are_validated() {
        assert!(is_valid_folder_name("4.3.stable.mono"));
        assert!(!is_valid_folder_name(""));
        assert!(!is_valid_folder_name(".."));
        assert!(!is_valid_folder_name("../escape"));
        assert!(!is_valid_folder_name("/absolute"));
        assert!(!is_valid_folder_name(".hidden"));
        assert!(!is_valid_folder_name("a/b"));
    }

    #[test]
    fn template_archive_prefix_is_stripped() {
        assert_eq!(
            strip_templates_prefix(Path::new("templates/linux_debug.x86_64")),
            PathBuf::from("linux_debug.x86_64")
        );
        assert_eq!(
            strip_templates_prefix(Path::new("templates/nested/version.txt")),
            PathBuf::from("nested/version.txt")
        );
        assert_eq!(
            strip_templates_prefix(Path::new("Templates/windows_release_x86_64.exe")),
            PathBuf::from("windows_release_x86_64.exe")
        );
        assert_eq!(
            strip_templates_prefix(Path::new("version.txt")),
            PathBuf::from("version.txt")
        );
        assert!(strip_templates_prefix(Path::new("templates")).as_os_str().is_empty());
    }

    #[test]
    fn content_range_parsing() {
        assert_eq!(parse_content_range_start("bytes 100-199/200"), Some(100));
        assert_eq!(parse_content_range_total("bytes 100-199/200"), Some(200));
        assert_eq!(parse_content_range_total("bytes 100-199/*"), None);
        assert_eq!(parse_content_range_start("nonsense"), None);
    }
}
