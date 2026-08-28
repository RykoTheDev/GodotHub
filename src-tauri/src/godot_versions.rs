use crate::models::*;
use crate::persist;
use crate::settings;
use futures_util::StreamExt;
use serde::Serialize;
use std::collections::{HashMap, VecDeque};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use tauri::{AppHandle, Emitter, Manager};

pub fn parse_godot_tag_from_filename(filename: &str) -> Option<String> {
    let lower = filename.to_lowercase();

    let stem = filename
        .strip_suffix(".exe.zip")
        .or_else(|| filename.strip_suffix(".exe"))
        .or_else(|| filename.strip_suffix(".zip"))
        .unwrap_or(filename);

    let after_prefix = stem
        .strip_prefix("Godot_v")
        .or_else(|| stem.strip_prefix("godot_v"))
        .or_else(|| stem.strip_prefix("GodotSharp_v"))?;

    let version_part = after_prefix.split('_').next()?;

    let clean = version_part.trim_start_matches('v');

    if clean.is_empty() {
        return None;
    }

    let is_mono = lower.contains("mono");

    let tag = if is_mono {
        format!("{}-mono", clean)
    } else {
        clean.to_string()
    };

    Some(tag)
}

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

pub fn migrate_registry_to_global(app: &AppHandle) {
    let global = registry_file(app);
    if global.exists() {
        return;
    }

    let base = app.path().app_data_dir().expect("no app data dir");
    let workspaces_root = base.join("workspaces");
    let Ok(entries) = fs::read_dir(&workspaces_root) else {
        return;
    };

    let mut per_workspace_files = vec![];
    let mut merged: Vec<InstalledGodotVersion> = vec![];
    let mut seen_paths = std::collections::HashSet::new();
    let mut seen_tags = std::collections::HashSet::new();

    let mut dirs: Vec<PathBuf> = entries.filter_map(|e| e.ok()).map(|e| e.path()).collect();
    dirs.sort();

    for dir in dirs {
        let file = dir.join("godot-versions.json");
        if !file.exists() {
            continue;
        }
        let list: Vec<InstalledGodotVersion> =
            serde_json::from_str(&fs::read_to_string(&file).unwrap_or_default())
                .unwrap_or_default();
        for v in list {
            if !seen_paths.insert(v.executable_path.clone()) {
                continue;
            }
            if !seen_tags.insert((v.tag.clone(), v.is_mono)) {
                continue;
            }
            merged.push(v);
        }
        per_workspace_files.push(file);
    }

    if per_workspace_files.is_empty() {
        return;
    }

    if persist::write_json(&global, &merged).is_err() {
        return;
    }

    for file in per_workspace_files {
        let _ = fs::rename(&file, file.with_extension("json.migrated"));
    }
}

pub fn read_registry(app: &AppHandle) -> Vec<InstalledGodotVersion> {
    let file = registry_file(app);
    if !file.exists() {
        return vec![];
    }
    let list: Vec<InstalledGodotVersion> =
        serde_json::from_str(&fs::read_to_string(&file).unwrap_or_default()).unwrap_or_default();
    list.into_iter()
        .map(|mut v| {
            v.supports_console = supports_console(Path::new(&v.executable_path));
            v
        })
        .collect()
}

pub fn write_registry(app: &AppHandle, list: &Vec<InstalledGodotVersion>) -> Result<(), String> {
    persist::write_json(&registry_file(app), list).map_err(|e| e.to_string())
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

fn releases_cache_file(app: &AppHandle, source: &str) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    let name = if source == "archive" {
        "godot-archive-cache.json"
    } else {
        "godot-releases-cache.json"
    };
    base.join(name)
}

#[derive(serde::Serialize, serde::Deserialize)]
struct ReleasesCache {
    fetched_at: i64,
    #[serde(default)]
    asset_target: String,
    releases: Vec<GodotRelease>,
}

const CACHE_TTL_SECS: i64 = 3600;

fn asset_target() -> String {
    format!("{}-{}", std::env::consts::OS, std::env::consts::ARCH)
}

fn read_cache_allow_stale(app: &AppHandle, source: &str) -> Option<(Vec<GodotRelease>, i64)> {
    let file = releases_cache_file(app, source);
    let raw = fs::read_to_string(&file).ok()?;
    let cache: ReleasesCache = serde_json::from_str(&raw).ok()?;
    if cache.asset_target != asset_target() {
        return None;
    }
    Some((dedupe_releases(cache.releases), cache.fetched_at))
}

fn write_releases_cache(app: &AppHandle, source: &str, releases: &[GodotRelease]) {
    let cache = ReleasesCache {
        fetched_at: chrono::Utc::now().timestamp(),
        asset_target: asset_target(),
        releases: releases.to_vec(),
    };
    if let Ok(json) = serde_json::to_string_pretty(&cache) {
        let _ = fs::write(releases_cache_file(app, source), json);
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

#[cfg(target_os = "linux")]
const LINUX_ARCH_TOKEN: Option<&str> = if cfg!(target_arch = "x86_64") {
    Some("x86_64")
} else if cfg!(target_arch = "aarch64") {
    Some("arm64")
} else if cfg!(target_arch = "arm") {
    Some("arm32")
} else if cfg!(target_arch = "x86") {
    Some("x86_32")
} else {
    None
};

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
    return LINUX_ARCH_TOKEN.is_some_and(|arch| {
        n.split_once("linux.")
            .or_else(|| n.split_once("linux_"))
            .is_some_and(|(_, rest)| rest.starts_with(arch))
    });
}

#[tauri::command]
pub async fn fetch_available_godot_versions(
    app: AppHandle,
    source: Option<String>,
) -> Result<Vec<GodotRelease>, String> {
    if source.as_deref() == Some("archive") {
        fetch_archive_versions(app).await
    } else {
        fetch_github_versions(app).await
    }
}

async fn fetch_github_versions(app: AppHandle) -> Result<Vec<GodotRelease>, String> {
    if let Some((cached, fetched_at)) = read_cache_allow_stale(&app, "github") {
        let now = chrono::Utc::now().timestamp();
        if now - fetched_at >= CACHE_TTL_SECS {
            let app_clone = app.clone();
            tauri::async_runtime::spawn(async move {
                let _ = refresh_releases_cache(app_clone).await;
            });
        }
        return Ok(cached);
    }

    refresh_releases_cache(app).await
}

async fn fetch_archive_versions(app: AppHandle) -> Result<Vec<GodotRelease>, String> {
    if let Some((cached, fetched_at)) = read_cache_allow_stale(&app, "archive") {
        let now = chrono::Utc::now().timestamp();
        if now - fetched_at >= CACHE_TTL_SECS {
            let app_clone = app.clone();
            tauri::async_runtime::spawn(async move {
                let _ = refresh_archive_releases(app_clone).await;
            });
        }
        return Ok(cached);
    }

    refresh_archive_releases(app).await
}

async fn refresh_releases_cache(app: AppHandle) -> Result<Vec<GodotRelease>, String> {
    let settings = crate::settings::read_settings(&app);
    let token = crate::git_auth::github_oauth_token(&app)
        .or_else(|| settings.github_token.filter(|t| !t.trim().is_empty()));

    let mut client_builder = reqwest::Client::builder().user_agent("godot-hub");
    if token.is_some() {
        client_builder = client_builder.user_agent("godot-hub/1.0");
    }
    let client = client_builder.build().map_err(|e| e.to_string())?;

    let mut releases: Vec<GodotRelease> = vec![];
    let mut page = 1;
    loop {
        let url = format!(
            "https://api.github.com/repos/godotengine/godot-builds/releases?per_page=100&page={}",
            page
        );
        let mut req = client.get(&url);
        if let Some(ref t) = token {
            req = req.header("Authorization", format!("Bearer {}", t));
        }
        let resp = req.send().await.map_err(|e| e.to_string())?;
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
            if let Ok(raw) = fs::read_to_string(releases_cache_file(&app, "github")) {
                if let Ok(stale) = serde_json::from_str::<ReleasesCache>(&raw) {
                    if stale.asset_target == asset_target() {
                        return Ok(stale.releases);
                    }
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

        if hit_floor || page_len < 100 || page >= 5 {
            break;
        }
        page += 1;
    }

    write_releases_cache(&app, "github", &releases);
    Ok(releases)
}

async fn refresh_archive_releases(app: AppHandle) -> Result<Vec<GodotRelease>, String> {
    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())?;

    let index_html = client
        .get("https://godotengine.org/download/archive/")
        .send()
        .await
        .map_err(|e| format!("Failed to fetch Godot archive: {e}"))?
        .text()
        .await
        .map_err(|e| e.to_string())?;

    let tags = parse_archive_tags(&index_html);
    let releases: Vec<GodotRelease> = futures_util::stream::iter(
        tags.into_iter().filter(|t| meets_min_version(t)),
    )
    .map(|tag| {
        let client = client.clone();
        async move {
            let assets = fetch_archive_assets(&client, &tag).await;
            if assets.is_empty() {
                None
            } else {
                Some(GodotRelease { tag, assets })
            }
        }
    })
    .buffered(8)
    .filter_map(|r| async move { r })
    .collect()
    .await;

    write_releases_cache(&app, "archive", &releases);
    Ok(releases)
}

fn parse_archive_tags(html: &str) -> Vec<String> {
    const MARKER: &str = "/download/archive/";
    let mut tags = Vec::new();
    let mut seen = std::collections::HashSet::new();
    let mut rest = html;
    while let Some(idx) = rest.find(MARKER) {
        let after = &rest[idx + MARKER.len()..];
        let end = after.find('"').unwrap_or(after.len());
        let tag = after[..end].trim_end_matches('/').trim().to_string();
        if !tag.is_empty()
            && tag.chars().next().is_some_and(|c| c.is_ascii_digit())
            && seen.insert(tag.clone())
        {
            tags.push(tag);
        }
        rest = after;
    }
    tags
}

fn parse_tag_parts(tag: &str) -> (String, String) {
    if let Some(idx) = tag.rfind('-') {
        let flavor = &tag[idx + 1..];
        let version = &tag[..idx];
        (version.to_string(), flavor.to_string())
    } else {
        (tag.to_string(), "stable".to_string())
    }
}

fn archive_asset_slugs() -> Vec<(&'static str, &'static str)> {
    let mut slugs = Vec::new();
    #[cfg(target_os = "windows")]
    {
        slugs.push(("win64.exe.zip", "windows.64"));
        slugs.push(("mono_win64.zip", "windows.64"));
    }
    #[cfg(target_os = "macos")]
    {
        slugs.push(("macos.universal.zip", "macos.universal"));
        slugs.push(("mono_macos.universal.zip", "macos.universal"));
    }
    #[cfg(target_os = "linux")]
    if let Some(arch) = LINUX_ARCH_TOKEN {
        match arch {
            "x86_64" => {
                slugs.push(("linux.x86_64.zip", "linux.64"));
                slugs.push(("mono_linux_x86_64.zip", "linux.64"));
            }
            "x86_32" => {
                slugs.push(("linux.x86_32.zip", "linux.32"));
                slugs.push(("mono_linux_x86_32.zip", "linux.32"));
            }
            "arm64" => {
                slugs.push(("linux.arm64.zip", "linux.arm64"));
                slugs.push(("mono_linux_arm64.zip", "linux.arm64"));
            }
            "arm32" => {
                slugs.push(("linux.arm32.zip", "linux.arm32"));
                slugs.push(("mono_linux_arm32.zip", "linux.arm32"));
            }
            _ => {}
        }
    }
    slugs
}

async fn fetch_archive_assets(client: &reqwest::Client, tag: &str) -> Vec<GodotReleaseAsset> {
    let (version, flavor) = parse_tag_parts(tag);
    let mut assets = Vec::new();
    for (slug, platform) in archive_asset_slugs() {
        let name = format!("Godot_v{tag}_{slug}");
        let url = format!(
            "https://downloads.godotengine.org/?version={version}&flavor={flavor}&slug={slug}&platform={platform}"
        );
        let Ok(resp) = client.head(&url).send().await else {
            continue;
        };
        if !resp.status().is_success() {
            continue;
        }
        let size = resp
            .headers()
            .get(reqwest::header::CONTENT_LENGTH)
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.parse::<u64>().ok())
            .unwrap_or(0);
        assets.push(GodotReleaseAsset {
            name,
            download_url: url,
            size,
            is_mono: slug.contains("mono"),
        });
    }
    assets
}

pub(crate) fn meets_min_version(tag: &str) -> bool {
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
pub fn reorder_download_queue(
    app: AppHandle,
    key: String,
    direction: i8,
) -> Result<(), String> {
    let order = {
        let mut mgr = dm().lock().unwrap();
        let idx = mgr
            .queue
            .iter()
            .position(|k| k == &key)
            .ok_or("Not queued")?;
        let max = mgr.queue.len() as isize - 1;
        let target = (idx as isize + direction as isize).clamp(0, max) as usize;
        if idx != target {
            let k = mgr.queue.remove(idx).unwrap_or_default();
            mgr.queue.insert(target, k);
        }
        mgr.queue.iter().cloned().collect::<Vec<String>>()
    };
    let _ = app.emit("godot-download-queue", order);
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
    let target2 = target_dir.clone();
    let result = tokio::task::spawn_blocking(move || -> Result<(), String> {
        install_version_archive(&app2, &job2, &zip_path, &target2)
    })
    .await;

    match result {
        Ok(Ok(())) => {
            release_slot(&app, &key, true);
            let _ = app.emit("godot-download-complete", &key);
        }
        Ok(Err(e)) => finish_with_error(&app, &key, e),
        Err(e) => finish_with_error(&app, &key, e.to_string()),
    }
}

fn install_version_archive(
    app: &AppHandle,
    job: &DownloadJob,
    zip_path: &Path,
    target_dir: &Path,
) -> Result<(), String> {
    let zip_file = fs::File::open(zip_path).map_err(|e| e.to_string())?;
    let mut archive = zip::ZipArchive::new(zip_file).map_err(|e| e.to_string())?;
    archive.extract(&target_dir).map_err(|e| e.to_string())?;
    let _ = fs::remove_file(zip_path);

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

    let version_number = job
        .tag
        .split('-')
        .next()
        .unwrap_or(&job.tag)
        .trim_start_matches('v')
        .to_string();
    let is_mono = job.asset_name.to_lowercase().contains("mono");
    let installed = InstalledGodotVersion {
        tag: if is_mono {
            format!("{}-mono", job.tag)
        } else {
            job.tag.clone()
        },
        version: version_number,
        executable_path: exe_path.to_string_lossy().to_string(),
        is_mono,
        installed_at: chrono::Utc::now().to_rfc3339(),
        custom_name: None,
        install_root: Some(target_dir.to_string_lossy().to_string()),
        supports_console: false,
    };
    register_version(app, installed.clone()).map_err(|e| e.to_string())?;
    crate::projects::rebind_projects_to_version(app, &installed);
    Ok(())
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
            if lower == "godotsharp" {
                continue;
            }
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
        if lower.starts_with("godot") && !lower.ends_with(".dll") {
            return Some(path);
        }
    }
    None
}

#[cfg(target_os = "windows")]
pub fn console_executable_for(exe: &Path) -> Option<PathBuf> {
    let stem = exe.file_stem()?.to_str()?;
    let candidate = exe.with_file_name(format!("{stem}_console.exe"));
    candidate.is_file().then_some(candidate)
}

fn migrate_mono_tags_in_place(
    list: &mut Vec<InstalledGodotVersion>,
    projects: &mut Vec<Project>,
) -> (bool, bool) {
    let mut renamed_old_tags: Vec<String> = Vec::new();
    let mut registry_changed = false;
    for v in list.iter_mut() {
        if v.is_mono && !v.tag.ends_with("-mono") {
            renamed_old_tags.push(v.tag.clone());
            v.tag = format!("{}-mono", v.tag);
            registry_changed = true;
        }
    }

    if !registry_changed {
        return (false, false);
    }

    let mut projects_changed = false;
    for old_tag in &renamed_old_tags {
        let has_standard_still = list.iter().any(|other| !other.is_mono && other.tag == *old_tag);
        if has_standard_still {
            continue;
        }
        let new_tag = format!("{}-mono", old_tag);
        for p in projects.iter_mut() {
            if p.godot_version == *old_tag {
                p.godot_version = new_tag.clone();
                projects_changed = true;
            }
        }
    }
    (registry_changed, projects_changed)
}

pub fn migrate_mono_tags(app: &AppHandle) {
    let mut list = read_registry(app);
    let mut projects = crate::projects::read_projects(app);
    let (registry_changed, projects_changed) = migrate_mono_tags_in_place(&mut list, &mut projects);
    if registry_changed {
        let _ = write_registry(app, &list);
    }
    if projects_changed {
        let _ = crate::projects::write_projects(app, &projects);
    }
}

fn installed_signature() -> &'static Mutex<Option<String>> {
    static SIG: OnceLock<Mutex<Option<String>>> = OnceLock::new();
    SIG.get_or_init(|| Mutex::new(None))
}

fn registry_signature(raw: &str) -> String {
    let Ok(value) = serde_json::from_str::<serde_json::Value>(raw) else {
        return raw.to_string();
    };
    let arr = value.as_array().map(|a| a.as_slice()).unwrap_or(&[]);
    let mut parts: Vec<String> = arr
        .iter()
        .filter_map(|e| {
            let tag = e.get("tag")?.as_str()?;
            let path = e.get("executable_path").and_then(|x| x.as_str()).unwrap_or("");
            let mono = e.get("is_mono").and_then(|x| x.as_bool()).unwrap_or(false);
            let custom = e.get("custom_name").and_then(|x| x.as_str()).unwrap_or("");
            Some(format!("{tag}|{path}|{mono}|{custom}"))
        })
        .collect();
    parts.sort();
    parts.join("\n")
}

#[tauri::command]
pub fn list_installed_godot_versions(app: AppHandle) -> Result<Vec<InstalledGodotVersion>, String> {
    let file = registry_file(&app);
    let raw = fs::read_to_string(&file).unwrap_or_default();
    let sig = registry_signature(&raw);

    let needs_reconcile = {
        let sig_lock = installed_signature().lock().unwrap();
        match sig_lock.as_ref() {
            Some(cached) => cached != &sig,
            None => true,
        }
    };

    if needs_reconcile {
        migrate_mono_tags(&app);
        crate::projects::rebind_projects_to_installed(&app);
        let raw = fs::read_to_string(&file).unwrap_or_default();
        *installed_signature().lock().unwrap() = Some(registry_signature(&raw));
    }

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

pub struct LaunchedEditor {
    pub child: std::process::Child,
    pub kill_tree: bool,
    #[cfg(unix)]
    pub pid_file: Option<PathBuf>,
}

#[cfg(target_os = "linux")]
fn verify_executable_arch(exe: &Path) -> Result<(), String> {
    use std::io::Read;

    const HOST_MACHINE: u16 = if cfg!(target_arch = "x86_64") {
        0x3E
    } else if cfg!(target_arch = "aarch64") {
        0xB7
    } else if cfg!(target_arch = "arm") {
        0x28
    } else if cfg!(target_arch = "x86") {
        0x03
    } else {
        0
    };

    if HOST_MACHINE == 0 {
        return Ok(());
    }

    let mut header = [0u8; 20];
    let Ok(mut file) = fs::File::open(exe) else {
        return Ok(());
    };
    if file.read_exact(&mut header).is_err() || &header[..4] != b"\x7fELF" {
        return Ok(());
    }

    let machine = u16::from_le_bytes([header[18], header[19]]);
    if machine == HOST_MACHINE {
        return Ok(());
    }

    let built_for = match machine {
        0x03 => "x86 (32-bit)",
        0x28 => "ARM (32-bit)",
        0x3E => "x86-64",
        0xB7 => "ARM64",
        _ => "another architecture",
    };
    Err(format!(
        "This Godot build is for {built_for}, but this system is {}. \
         Remove this version and download it again to get the matching build.",
        std::env::consts::ARCH
    ))
}

pub fn spawn_editor(
    app: &AppHandle,
    exe: &Path,
    args: &[String],
    title: &str,
    use_console: bool,
) -> Result<LaunchedEditor, String> {
    #[cfg(target_os = "linux")]
    verify_executable_arch(exe)?;

    if !use_console {
        return spawn_plain(exe, args);
    }

    spawn_with_console(app, exe, args, title)
}

fn spawn_plain(exe: &Path, args: &[String]) -> Result<LaunchedEditor, String> {
    std::process::Command::new(exe)
        .args(args)
        .spawn()
        .map(|child| LaunchedEditor {
            child,
            kill_tree: false,
            #[cfg(unix)]
            pid_file: None,
        })
        .map_err(|e| format!("Failed to launch editor: {e}"))
}

#[cfg(target_os = "windows")]
fn spawn_with_console(
    _app: &AppHandle,
    exe: &Path,
    args: &[String],
    title: &str,
) -> Result<LaunchedEditor, String> {
    match console_executable_for(exe) {
        Some(wrapper) => crate::terminal::spawn_program_in_console(&wrapper, args, title)
            .map(|child| LaunchedEditor {
                child,
                kill_tree: true,
            }),
        None => spawn_plain(exe, args),
    }
}

#[cfg(unix)]
fn spawn_with_console(
    app: &AppHandle,
    exe: &Path,
    args: &[String],
    _title: &str,
) -> Result<LaunchedEditor, String> {
    crate::terminal::spawn_program_in_terminal(app, exe, args).map(|(child, pid_file)| {
        LaunchedEditor {
            child,
            kill_tree: false,
            pid_file: Some(pid_file),
        }
    })
}

#[tauri::command]
pub fn open_godot_version(app: AppHandle, tag: String, console: Option<bool>) -> Result<(), String> {
    let list = read_registry(&app);
    let version = list
        .iter()
        .find(|v| v.tag == tag)
        .ok_or("Version not found")?;
    let path = PathBuf::from(&version.executable_path);
    if !path.exists() {
        return Err("Executable no longer exists at that path".into());
    }

    let use_console = console.unwrap_or_else(|| settings::read_settings(&app).launch_with_console);
    let title = version
        .custom_name
        .clone()
        .unwrap_or_else(|| version.tag.clone());

    spawn_editor(&app, &path, &[], &title, use_console)?;
    Ok(())
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
            if let Err(e) = trash::delete_all([&root_path]) {
                eprintln!("[delete_godot_version] trash failed for install_root {:?}: {e}, falling back to fs::remove_dir_all", root_path);
                let _ = fs::remove_dir_all(&root_path);
            } else {
                eprintln!("[delete_godot_version] trashed install_root {:?}", root_path);
            }
        } else {
            eprintln!("[delete_godot_version] install_root {:?} is not a directory, skipping", root_path);
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
            let folder = managed.join(version_folder);
            if let Err(e) = trash::delete_all([&folder]) {
                eprintln!("[delete_godot_version] trash failed for managed folder {:?}: {e}, falling back to fs::remove_dir_all", folder);
                let _ = fs::remove_dir_all(&folder);
            } else {
                eprintln!("[delete_godot_version] trashed managed folder {:?}", folder);
            }
            return Ok(());
        }
    }

    #[cfg(target_os = "macos")]
    {
        if let Some(bundle) = exe_path
            .ancestors()
            .find(|p| p.extension().map(|e| e == "app").unwrap_or(false))
        {
            if let Err(e) = trash::delete_all([bundle]) {
                eprintln!("[delete_godot_version] trash failed for macOS bundle {:?}: {e}, falling back to fs::remove_dir_all", bundle);
                let _ = fs::remove_dir_all(bundle);
            } else {
                eprintln!("[delete_godot_version] trashed macOS bundle {:?}", bundle);
            }
            return Ok(());
        }
    }

    #[cfg(target_os = "windows")]
    {
        if let Some(stem) = exe_path.file_stem().and_then(|s| s.to_str()) {
            let console_name = format!("{}_console.exe", stem);
            let console_path = exe_path.with_file_name(&console_name);
            if let Err(e) = trash::delete(&console_path) {
                eprintln!("[delete_godot_version] trash failed for console exe {:?}: {e}, falling back to fs::remove_file", console_path);
                let _ = fs::remove_file(&console_path);
            }
        }
    }

    if let Err(e) = trash::delete(&exe_path) {
        eprintln!("[delete_godot_version] trash failed for exe {:?}: {e}, falling back to fs::remove_file", exe_path);
        let _ = fs::remove_file(&exe_path);
    } else {
        eprintln!("[delete_godot_version] trashed exe {:?}", exe_path);
    }
    Ok(())
}

#[derive(Clone, Serialize)]
pub struct RateLimitInfo {
    pub remaining: u64,
    pub limit: u64,
    pub reset_at: i64,
    pub used_token: bool,
}

#[tauri::command]
pub async fn test_github_token(app: AppHandle) -> Result<RateLimitInfo, String> {
    let settings = crate::settings::read_settings(&app);
    let token = crate::git_auth::github_oauth_token(&app)
        .or_else(|| settings.github_token.filter(|t| !t.trim().is_empty()));

    let client = reqwest::Client::builder()
        .user_agent("godot-hub/1.0")
        .build()
        .map_err(|e| e.to_string())?;

    let mut req = client.get("https://api.github.com/rate_limit");
    if let Some(ref t) = token {
        req = req.header("Authorization", format!("Bearer {}", t));
    }
    let resp = req.send().await.map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        let status = resp.status();
        return Err(format!("GitHub API returned {}. Check that your token is valid.", status));
    }

    let remaining: u64 = resp
        .headers()
        .get("x-ratelimit-remaining")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse().ok())
        .unwrap_or(0);

    let limit: u64 = resp
        .headers()
        .get("x-ratelimit-limit")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse().ok())
        .unwrap_or(60);

    let reset_at: i64 = resp
        .headers()
        .get("x-ratelimit-reset")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse().ok())
        .unwrap_or(0);

    Ok(RateLimitInfo {
        remaining,
        limit,
        reset_at,
        used_token: token.is_some(),
    })
}

#[tauri::command]
pub async fn get_github_rate_limit(app: AppHandle) -> Result<RateLimitInfo, String> {
    test_github_token(app).await
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

    let zip_name = zip_path
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("")
        .to_string();

    let (tag, is_mono) = match parse_godot_tag_from_filename(&zip_name) {
        Some(clean) => {
            let detected_mono = clean.ends_with("-mono");
            (clean, detected_mono)
        }
        None => {
            let stem = zip_path
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("unknown")
                .to_string();
            let detected_mono = stem.to_lowercase().contains("mono");
            let tag = if detected_mono && !stem.ends_with("-mono") {
                format!("{}-mono", stem)
            } else {
                stem
            };
            (tag, detected_mono)
        }
    };

    let target_dir = versions_dir(&app).join(&tag);
    if target_dir.exists() {
        return Err("A version with this name already exists".into());
    }
    fs::create_dir_all(&target_dir).map_err(|e| e.to_string())?;

    let zip_file = fs::File::open(&zip_path).map_err(|e| e.to_string())?;
    let mut archive = zip::ZipArchive::new(zip_file).map_err(|e| e.to_string())?;
    archive.extract(&target_dir).map_err(|e| e.to_string())?;

    let exe_path = find_executable(&target_dir)
        .ok_or_else(|| "No Godot executable found in the archive".to_string())?;

    let version_number = tag
        .split('-')
        .next()
        .unwrap_or(&tag)
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

    let installed = InstalledGodotVersion {
        tag: tag.clone(),
        version: version_number,
        executable_path: exe_path.to_string_lossy().to_string(),
        is_mono,
        installed_at: chrono::Utc::now().to_rfc3339(),
        custom_name: None,
        install_root: Some(target_dir.to_string_lossy().to_string()),
        supports_console: false,
    };

    register_version(&app, installed.clone())?;
    crate::projects::rebind_projects_to_version(&app, &installed);

    let _ = app.emit("godot-download-complete", &tag);

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

#[cfg(target_os = "windows")]
fn supports_console(exe: &Path) -> bool {
    console_executable_for(exe).is_some()
}

#[cfg(not(target_os = "windows"))]
fn supports_console(_exe: &Path) -> bool {
    true
}

