use crate::models::*;
use crate::settings;
use futures_util::StreamExt;
use std::collections::{HashMap, VecDeque};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use tauri::{AppHandle, Emitter, Manager};

pub fn versions_dir(app: &AppHandle) -> PathBuf {
    let s = settings::read_settings(app);
    let dir = match s.download_dir {
        Some(d) if !d.trim().is_empty() => PathBuf::from(d),
        _ => app
            .path()
            .app_data_dir()
            .expect("no app data dir")
            .join("godot-versions"),
    };
    if !dir.exists() {
        let _ = fs::create_dir_all(&dir);
    }
    dir
}

fn registry_file(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    base.join("godot-versions.json")
}

pub fn read_registry(app: &AppHandle) -> Vec<InstalledGodotVersion> {
    let file = registry_file(app);
    if !file.exists() {
        return vec![];
    }
    serde_json::from_str(&fs::read_to_string(&file).unwrap_or_default()).unwrap_or_default()
}

pub fn write_registry(app: &AppHandle, list: &Vec<InstalledGodotVersion>) -> Result<(), String> {
    fs::write(
        registry_file(app),
        serde_json::to_string_pretty(list).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())
}

pub fn register_version(app: &AppHandle, version: InstalledGodotVersion) -> Result<bool, String> {
    let mut list = read_registry(app);
    if list
        .iter()
        .any(|v| v.executable_path == version.executable_path)
    {
        return Ok(false);
    }
    list.push(version);
    write_registry(app, &list)?;
    Ok(true)
}

fn releases_cache_file(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    base.join("godot-releases-cache.json")
}

#[derive(serde::Serialize, serde::Deserialize)]
struct ReleasesCache {
    fetched_at: i64,
    releases: Vec<GodotRelease>,
}

const CACHE_TTL_SECS: i64 = 600;

fn read_releases_cache(app: &AppHandle) -> Option<Vec<GodotRelease>> {
    let file = releases_cache_file(app);
    let raw = fs::read_to_string(&file).ok()?;
    let cache: ReleasesCache = serde_json::from_str(&raw).ok()?;
    let now = chrono::Utc::now().timestamp();
    if now - cache.fetched_at < CACHE_TTL_SECS {
        Some(dedupe_releases(cache.releases))
    } else {
        None
    }
}

fn write_releases_cache(app: &AppHandle, releases: &[GodotRelease]) {
    let cache = ReleasesCache {
        fetched_at: chrono::Utc::now().timestamp(),
        releases: releases.to_vec(),
    };
    if let Ok(json) = serde_json::to_string_pretty(&cache) {
        let _ = fs::write(releases_cache_file(app), json);
    }
}

fn dedupe_releases(releases: Vec<GodotRelease>) -> Vec<GodotRelease> {
    let mut seen_tags = std::collections::HashSet::new();
    releases
        .into_iter()
        .filter(|r| seen_tags.insert(r.tag.clone()))
        .map(|mut r| {
            let mut seen_assets = std::collections::HashSet::new();
            r.assets.retain(|a| seen_assets.insert(a.name.clone()));
            r
        })
        .collect()
}

fn platform_asset_matcher(name: &str) -> bool {
    let n = name.to_lowercase();
    if !n.ends_with(".zip") || n.contains("console") {
        return false;
    }
    #[cfg(target_os = "windows")]
    return n.contains("win64");
    #[cfg(target_os = "macos")]
    return n.contains("macos");
    #[cfg(target_os = "linux")]
    return n.contains("linux.x86_64") || n.contains("linux_x86_64");
}

#[tauri::command]
pub async fn fetch_available_godot_versions(app: AppHandle) -> Result<Vec<GodotRelease>, String> {
    if let Some(cached) = read_releases_cache(&app) {
        return Ok(cached);
    }

    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())?;

    let mut releases: Vec<GodotRelease> = vec![];
    let mut page = 1;
    loop {
        let url = format!(
            "https://api.github.com/repos/godotengine/godot-builds/releases?per_page=100&page={}",
            page
        );
        let resp = client.get(&url).send().await.map_err(|e| e.to_string())?;
        if !resp.status().is_success() {
            let status = resp.status();
            let remaining = resp
                .headers()
                .get("x-ratelimit-remaining")
                .and_then(|v| v.to_str().ok())
                .unwrap_or("?")
                .to_string();
            let reset = resp
                .headers()
                .get("x-ratelimit-reset")
                .and_then(|v| v.to_str().ok())
                .and_then(|v| v.parse::<i64>().ok());
            let body = resp.text().await.unwrap_or_default();
            let reset_msg = match reset {
                Some(ts) => {
                    let now = chrono::Utc::now().timestamp();
                    let mins = ((ts - now).max(0)) / 60;
                    format!(" Resets in ~{} min.", mins)
                }
                None => String::new(),
            };
            let err = format!(
                "GitHub API error: {} (rate limit remaining: {}).{} {}",
                status, remaining, reset_msg, body
            );
            if let Ok(raw) = fs::read_to_string(releases_cache_file(&app)) {
                if let Ok(stale) = serde_json::from_str::<ReleasesCache>(&raw) {
                    return Ok(stale.releases);
                }
            }
            return Err(err);
        }

        let json: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
        let arr = match json.as_array() {
            Some(a) if !a.is_empty() => a.clone(),
            _ => break,
        };
        let page_len = arr.len();
        let mut hit_floor = false;

        for r in &arr {
            let tag = r["tag_name"].as_str().unwrap_or("").to_string();
            if tag.is_empty() {
                continue;
            }
            if !meets_min_version(&tag) {
                hit_floor = true;
                continue;
            }
            let mut assets = vec![];
            if let Some(asset_arr) = r["assets"].as_array() {
                for a in asset_arr {
                    let name = a["name"].as_str().unwrap_or("").to_string();
                    if !platform_asset_matcher(&name) {
                        continue;
                    }
                    let lower = name.to_lowercase();
                    assets.push(GodotReleaseAsset {
                        name,
                        download_url: a["browser_download_url"].as_str().unwrap_or("").to_string(),
                        size: a["size"].as_u64().unwrap_or(0),
                        is_mono: lower.contains("mono"),
                    });
                }
            }
            if !assets.is_empty() {
                releases.push(GodotRelease { tag, assets });
            }
        }

        if hit_floor || page_len < 100 || page >= 10 {
            break;
        }
        page += 1;
    }

    write_releases_cache(&app, &releases);
    Ok(releases)
}

fn meets_min_version(tag: &str) -> bool {
    let cleaned = tag.trim_start_matches('v');
    let mut parts = cleaned.split(['.', '-']);
    let major: u32 = parts.next().and_then(|s| s.parse().ok()).unwrap_or(0);
    let minor: u32 = parts.next().and_then(|s| s.parse().ok()).unwrap_or(0);
    (major, minor) >= (4, 1)
}

#[derive(Clone, PartialEq)]
enum SlotState {
    Active,
    Queued,
    Paused,
}

#[derive(Clone)]
struct DownloadJob {
    tag: String,
    asset_name: String,
    download_url: String,
}

struct DownloadHandle {
    job: DownloadJob,
    cancel: Arc<AtomicBool>,
    pause: Arc<AtomicBool>,
}

#[derive(Default)]
struct DownloadManager {
    handles: HashMap<String, DownloadHandle>,
    state: HashMap<String, SlotState>,
    queue: VecDeque<String>,
    active_count: usize,
}

fn dm() -> &'static Mutex<DownloadManager> {
    static DM: OnceLock<Mutex<DownloadManager>> = OnceLock::new();
    DM.get_or_init(|| Mutex::new(DownloadManager::default()))
}

fn download_key(tag: &str, asset_name: &str) -> String {
    if asset_name.to_lowercase().contains("mono") {
        format!("{}-mono", tag)
    } else {
        tag.to_string()
    }
}

fn release_slot(app: &AppHandle, key: &str, remove_handle: bool) {
    let next = {
        let mut mgr = dm().lock().unwrap();
        if remove_handle {
            mgr.handles.remove(key);
            mgr.state.remove(key);
        }
        mgr.active_count = mgr.active_count.saturating_sub(1);

        let limit = settings::read_settings(app).download_concurrency.max(1) as usize;
        let mut started = None;
        if mgr.active_count < limit {
            if let Some(next_key) = mgr.queue.pop_front() {
                if mgr.handles.contains_key(&next_key) {
                    mgr.active_count += 1;
                    mgr.state.insert(next_key.clone(), SlotState::Active);
                    started = Some(next_key);
                }
            }
        }
        started
    };
    if let Some(k) = next {
        tauri::async_runtime::spawn(run_download(app.clone(), k));
    }
}

fn finish_with_error(app: &AppHandle, key: &str, msg: String) {
    release_slot(app, key, true);
    let _ = app.emit(
        "godot-download-error",
        serde_json::json!({ "tag": key, "message": msg }),
    );
}

#[tauri::command]
pub fn download_godot_version(
    app: AppHandle,
    tag: String,
    asset_name: String,
    download_url: String,
) -> Result<(), String> {
    let key = download_key(&tag, &asset_name);
    let target_dir = versions_dir(&app).join(&key);
    if target_dir.exists() && fs::metadata(target_dir.join(&asset_name)).is_err() {
        return Err("Version already installed".into());
    }

    let mut mgr = dm().lock().unwrap();
    if mgr.handles.contains_key(&key) {
        return Err("Already downloading or queued".into());
    }
    mgr.handles.insert(
        key.clone(),
        DownloadHandle {
            job: DownloadJob {
                tag,
                asset_name,
                download_url,
            },
            cancel: Arc::new(AtomicBool::new(false)),
            pause: Arc::new(AtomicBool::new(false)),
        },
    );
    let limit = settings::read_settings(&app).download_concurrency.max(1) as usize;
    let should_start = mgr.active_count < limit;
    if should_start {
        mgr.active_count += 1;
        mgr.state.insert(key.clone(), SlotState::Active);
    } else {
        mgr.state.insert(key.clone(), SlotState::Queued);
        mgr.queue.push_back(key.clone());
    }
    drop(mgr);

    if should_start {
        tauri::async_runtime::spawn(run_download(app, key));
    } else {
        let _ = app.emit("godot-download-queued", &key);
    }
    Ok(())
}

#[tauri::command]
pub fn pause_download(key: String) -> Result<(), String> {
    let mgr = dm().lock().unwrap();
    match mgr.handles.get(&key) {
        Some(h) => {
            h.pause.store(true, Ordering::SeqCst);
            Ok(())
        }
        None => Err("Not downloading".into()),
    }
}

#[tauri::command]
pub fn cancel_download(app: AppHandle, key: String) -> Result<(), String> {
    let mut mgr = dm().lock().unwrap();
    match mgr.state.get(&key).cloned() {
        Some(SlotState::Queued) => {
            mgr.queue.retain(|k| k != &key);
            mgr.state.remove(&key);
            mgr.handles.remove(&key);
            drop(mgr);
            let _ = app.emit("godot-download-canceled", &key);
            Ok(())
        }
        Some(SlotState::Active) => {
            if let Some(h) = mgr.handles.get(&key) {
                h.cancel.store(true, Ordering::SeqCst);
            }
            Ok(())
        }
        Some(SlotState::Paused) => {
            mgr.state.remove(&key);
            mgr.handles.remove(&key);
            drop(mgr);
            let target_dir = versions_dir(&app).join(&key);
            let _ = fs::remove_dir_all(&target_dir);
            let _ = app.emit("godot-download-canceled", &key);
            Ok(())
        }
        None => Err("Not found".into()),
    }
}

#[tauri::command]
pub fn resume_download(app: AppHandle, key: String) -> Result<(), String> {
    let mut mgr = dm().lock().unwrap();
    if mgr.state.get(&key) != Some(&SlotState::Paused) {
        return Err("Not paused".into());
    }
    if let Some(h) = mgr.handles.get(&key) {
        h.pause.store(false, Ordering::SeqCst);
    }
    let limit = settings::read_settings(&app).download_concurrency.max(1) as usize;
    if mgr.active_count < limit {
        mgr.active_count += 1;
        mgr.state.insert(key.clone(), SlotState::Active);
        drop(mgr);
        tauri::async_runtime::spawn(run_download(app, key));
    } else {
        mgr.state.insert(key.clone(), SlotState::Queued);
        mgr.queue.push_back(key.clone());
        drop(mgr);
        let _ = app.emit("godot-download-queued", &key);
    }
    Ok(())
}

async fn run_download(app: AppHandle, key: String) {
    let (job, cancel, pause) = {
        let mgr = dm().lock().unwrap();
        match mgr.handles.get(&key) {
            Some(h) => (h.job.clone(), h.cancel.clone(), h.pause.clone()),
            None => return,
        }
    };

    let target_dir = versions_dir(&app).join(&key);
    if let Err(e) = fs::create_dir_all(&target_dir) {
        finish_with_error(&app, &key, e.to_string());
        return;
    }
    let zip_path = target_dir.join(&job.asset_name);
    let existing: u64 = fs::metadata(&zip_path).map(|m| m.len()).unwrap_or(0);

    let client = match reqwest::Client::builder().user_agent("godot-hub").build() {
        Ok(c) => c,
        Err(e) => return finish_with_error(&app, &key, e.to_string()),
    };
    let mut req = client.get(&job.download_url);
    if existing > 0 {
        req = req.header("Range", format!("bytes={}-", existing));
    }
    let resp = match req.send().await {
        Ok(r) => r,
        Err(e) => return finish_with_error(&app, &key, e.to_string()),
    };
    let total = resp.content_length().unwrap_or(0) + existing;

    let mut file = match fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&zip_path)
    {
        Ok(f) => f,
        Err(e) => return finish_with_error(&app, &key, e.to_string()),
    };

    let mut downloaded = existing;
    let mut stream = resp.bytes_stream();
    loop {
        if cancel.load(Ordering::SeqCst) {
            drop(file);
            let _ = fs::remove_dir_all(&target_dir);
            release_slot(&app, &key, true);
            let _ = app.emit("godot-download-canceled", &key);
            return;
        }
        if pause.load(Ordering::SeqCst) {
            drop(file);
            {
                let mut mgr = dm().lock().unwrap();
                mgr.state.insert(key.clone(), SlotState::Paused);
            }
            release_slot(&app, &key, false);
            let _ = app.emit("godot-download-paused", &key);
            return;
        }
        let chunk = match stream.next().await {
            Some(Ok(c)) => c,
            Some(Err(e)) => return finish_with_error(&app, &key, e.to_string()),
            None => break,
        };
        if let Err(e) = file.write_all(&chunk) {
            return finish_with_error(&app, &key, e.to_string());
        }
        downloaded += chunk.len() as u64;
        let _ = app.emit(
            "godot-download-progress",
            DownloadProgress {
                tag: key.clone(),
                downloaded,
                total,
            },
        );
    }
    drop(file);

    let app2 = app.clone();
    let job2 = job.clone();
    let result = tokio::task::spawn_blocking(move || -> Result<InstalledGodotVersion, String> {
        let zip_file = fs::File::open(&zip_path).map_err(|e| e.to_string())?;
        let mut archive = zip::ZipArchive::new(zip_file).map_err(|e| e.to_string())?;
        archive.extract(&target_dir).map_err(|e| e.to_string())?;
        let _ = fs::remove_file(&zip_path);

        let exe_path = find_executable(&target_dir)
            .ok_or_else(|| "Could not locate Godot executable after extraction".to_string())?;

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            if let Ok(meta) = fs::metadata(&exe_path) {
                let mut perms = meta.permissions();
                perms.set_mode(0o755);
                let _ = fs::set_permissions(&exe_path, perms);
            }
        }

        let version_number = job2
            .tag
            .split('-')
            .next()
            .unwrap_or(&job2.tag)
            .trim_start_matches('v')
            .to_string();
        let installed = InstalledGodotVersion {
            tag: job2.tag.clone(),
            version: version_number,
            executable_path: exe_path.to_string_lossy().to_string(),
            is_mono: job2.asset_name.to_lowercase().contains("mono"),
            installed_at: chrono::Utc::now().to_rfc3339(),
            custom_name: None,
            install_root: Some(target_dir.to_string_lossy().to_string()),
        };
        register_version(&app2, installed.clone()).map_err(|e| e.to_string())?;
        crate::projects::rebind_projects_to_version(&app2, &installed);
        Ok(installed)
    }).await;

    match result {
        Ok(Ok(_)) => {
            release_slot(&app, &key, true);
            let _ = app.emit("godot-download-complete", &key);
        }
        Ok(Err(e)) => finish_with_error(&app, &key, e),
        Err(e) => finish_with_error(&app, &key, e.to_string()),
    }
}

pub fn find_executable(dir: &Path) -> Option<PathBuf> {
    let entries = fs::read_dir(dir).ok()?;
    for entry in entries.flatten() {
        let path = entry.path();
        let fname = path.file_name()?.to_str()?.to_string();
        let lower = fname.to_lowercase();

        #[cfg(target_os = "macos")]
        if path.is_dir() && lower.ends_with(".app") {
            let macos_dir = path.join("Contents/MacOS");
            if let Ok(bins) = fs::read_dir(&macos_dir) {
                for b in bins.flatten() {
                    if b.path().is_file() {
                        return Some(b.path());
                    }
                }
            }
            continue;
        }

        if path.is_dir() {
            if let Some(found) = find_executable(&path) {
                return Some(found);
            }
            continue;
        }

        #[cfg(target_os = "windows")]
        if lower.ends_with(".exe") {
            return Some(path);
        }
        #[cfg(target_os = "linux")]
        if lower.starts_with("godot") {
            return Some(path);
        }
    }
    None
}

#[tauri::command]
pub fn list_installed_godot_versions(app: AppHandle) -> Result<Vec<InstalledGodotVersion>, String> {
    Ok(prune_missing(&app))
}

#[tauri::command]
pub fn rename_godot_version(
    app: AppHandle,
    tag: String,
    custom_name: Option<String>,
) -> Result<InstalledGodotVersion, String> {
    let mut list = read_registry(&app);
    let entry = list
        .iter_mut()
        .find(|v| v.tag == tag)
        .ok_or("Version not found")?;
    entry.custom_name = custom_name
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    let updated = entry.clone();
    write_registry(&app, &list)?;
    Ok(updated)
}

#[tauri::command]
pub fn delete_godot_version(app: AppHandle, tag: String) -> Result<(), String> {
    let mut list = read_registry(&app);
    let idx = list
        .iter()
        .position(|v| v.tag == tag)
        .ok_or("Version not found")?;
    let removed = list.remove(idx);
    write_registry(&app, &list)?;

    if let Some(root) = &removed.install_root {
        let root_path = PathBuf::from(root);
        if root_path.is_dir() {
            let _ = fs::remove_dir_all(&root_path);
        }
        return Ok(());
    }

    let managed = versions_dir(&app);
    let exe_path = PathBuf::from(&removed.executable_path);
    if exe_path.starts_with(&managed) {
        if let Some(version_folder) = exe_path
            .strip_prefix(&managed)
            .ok()
            .and_then(|p| p.components().next())
        {
            let _ = fs::remove_dir_all(managed.join(version_folder));
            return Ok(());
        }
    }

    #[cfg(target_os = "macos")]
    {
        if let Some(bundle) = exe_path
            .ancestors()
            .find(|p| p.extension().map(|e| e == "app").unwrap_or(false))
        {
            let _ = fs::remove_dir_all(bundle);
            return Ok(());
        }
    }

    #[cfg(target_os = "windows")]
    {
        if let Some(stem) = exe_path.file_stem().and_then(|s| s.to_str()) {
            let console_name = format!("{}_console.exe", stem);
            let _ = fs::remove_file(exe_path.with_file_name(console_name));
        }
    }

    let _ = fs::remove_file(&exe_path);
    Ok(())
}

#[tauri::command]
pub async fn import_version_zip(
    app: AppHandle,
    zip_path: String,
) -> Result<InstalledGodotVersion, String> {
    let zip_path = std::path::PathBuf::from(&zip_path);
    if !zip_path.exists() {
        return Err("File not found".into());
    }
    if zip_path
        .extension()
        .map(|e| e != "zip")
        .unwrap_or(true)
    {
        return Err("File must be a .zip archive".into());
    }

    let stem = zip_path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .to_string();
    let key = stem.clone();

    let target_dir = versions_dir(&app).join(&key);
    if target_dir.exists() {
        return Err("A version with this name already exists".into());
    }
    fs::create_dir_all(&target_dir).map_err(|e| e.to_string())?;

    let zip_file = fs::File::open(&zip_path).map_err(|e| e.to_string())?;
    let mut archive = zip::ZipArchive::new(zip_file).map_err(|e| e.to_string())?;
    archive.extract(&target_dir).map_err(|e| e.to_string())?;

    let exe_path = find_executable(&target_dir)
        .ok_or_else(|| "No Godot executable found in the archive".to_string())?;

    let version_number = stem
        .split('-')
        .next()
        .unwrap_or(&stem)
        .trim_start_matches('v')
        .to_string();

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        if let Ok(meta) = fs::metadata(&exe_path) {
            let mut perms = meta.permissions();
            perms.set_mode(0o755);
            let _ = fs::set_permissions(&exe_path, perms);
        }
    }

    let is_mono = stem.to_lowercase().contains("mono");

    let installed = InstalledGodotVersion {
        tag: key.clone(),
        version: version_number,
        executable_path: exe_path.to_string_lossy().to_string(),
        is_mono,
        installed_at: chrono::Utc::now().to_rfc3339(),
        custom_name: None,
        install_root: Some(target_dir.to_string_lossy().to_string()),
    };

    register_version(&app, installed.clone())?;
    crate::projects::rebind_projects_to_version(&app, &installed);

    let _ = app.emit("godot-download-complete", &key);

    Ok(installed)
}

pub fn prune_missing(app: &AppHandle) -> Vec<InstalledGodotVersion> {
    let list = read_registry(app);
    let (kept, removed): (Vec<InstalledGodotVersion>, Vec<InstalledGodotVersion>) = list
        .into_iter()
        .partition(|v| Path::new(&v.executable_path).exists());
    if !removed.is_empty() {
        let _ = write_registry(app, &kept);
    }
    kept
}
