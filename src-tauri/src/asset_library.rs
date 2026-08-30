use crate::godot_versions::meets_min_version;
use crate::models::ProjectTemplate;
use futures_util::StreamExt;
use serde::Deserialize;
use std::collections::HashMap;
use std::fs;
use std::io::Cursor;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter, Manager};

const ASSET_LIB_API: &str = "https://godotengine.org/asset-library/api";
const ASSET_STORE_API: &str = "https://store.godotengine.org/api/v1";
const ALLOWED_TYPES: &[&str] = &["project"];
const MAX_PAGE_SKIP: u32 = 8;

#[derive(Debug, Clone, Deserialize)]
struct AssetSearchResult {
    #[serde(rename = "asset_id")]
    asset_id: String,
}

#[derive(Debug, Clone, Deserialize)]
struct AssetSearchResponse {
    result: Vec<AssetSearchResult>,
    pages: u32,
    #[serde(rename = "total_items")]
    total_items: u32,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct AssetDetail {
    #[serde(rename = "asset_id")]
    asset_id: String,
    #[serde(default, rename = "type")]
    asset_type: String,
    #[serde(default)]
    title: String,
    #[serde(default)]
    author: String,
    #[serde(default)]
    category: String,
    #[serde(default, rename = "godot_version")]
    godot_version: String,
    #[serde(default)]
    cost: String,
    #[serde(default)]
    description: Option<String>,
    #[serde(default, rename = "support_level")]
    support_level: String,
    #[serde(default, rename = "download_url")]
    download_url: Option<String>,
    #[serde(default, rename = "browse_url")]
    browse_url: Option<String>,
    #[serde(default, rename = "icon_url")]
    icon_url: Option<String>,
    #[serde(default, rename = "modify_date")]
    modify_date: Option<String>,
    #[serde(default)]
    rating: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct AssetLibraryAsset {
    pub asset_id: String,
    pub title: String,
    pub author: String,
    pub category: String,
    pub godot_version: String,
    pub cost: String,
    pub support_level: String,
    pub asset_type: String,
    pub description: Option<String>,
    pub icon_url: Option<String>,
    pub download_url: Option<String>,
    pub browse_url: Option<String>,
    pub modify_date: Option<String>,
    pub rating: String,
    pub source: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct AssetLibraryResponse {
    pub assets: Vec<AssetLibraryAsset>,
    pub page: u32,
    pub pages: u32,
    pub total: u32,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AssetLibraryCategory {
    pub id: String,
    pub name: String,
    #[serde(rename(deserialize = "type", serialize = "category_type"))]
    pub category_type: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct InstallAssetResult {
    pub asset_id: String,
    pub title: String,
    pub target_type: String,
    pub target_name: String,
    pub path: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub(crate) struct AssetDownloadProgress {
    pub asset_id: String,
    pub title: String,
    pub downloaded: u64,
    pub total: u64,
}

#[derive(Debug, Clone, serde::Serialize)]
pub(crate) struct AssetDownloadError {
    pub asset_id: String,
    pub title: String,
    pub message: String,
}

fn client() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())
}

async fn fetch_detail(http: &reqwest::Client, asset_id: &str) -> Option<AssetDetail> {
    http.get(format!("{ASSET_LIB_API}/asset/{asset_id}"))
        .send()
        .await
        .ok()?
        .json::<AssetDetail>()
        .await
        .ok()
}

const DETAIL_CACHE_TTL: Duration = Duration::from_secs(10 * 60);
const SEARCH_CACHE_TTL: Duration = Duration::from_secs(60);
const CACHE_MAX_ENTRIES: usize = 256;

#[derive(Default)]
pub struct AssetResponseCache {
    details: Mutex<HashMap<String, (Instant, AssetDetail)>>,
    searches: Mutex<HashMap<String, (Instant, AssetLibraryResponse)>>,
}

fn evict_if_full<T>(map: &mut HashMap<String, (Instant, T)>, ttl: Duration) {
    if map.len() >= CACHE_MAX_ENTRIES {
        map.retain(|_, (ts, _)| ts.elapsed() < ttl);
        if map.len() >= CACHE_MAX_ENTRIES {
            map.clear();
        }
    }
}

impl AssetResponseCache {
    fn cached_detail(&self, asset_id: &str) -> Option<AssetDetail> {
        let map = self.details.lock().ok()?;
        match map.get(asset_id) {
            Some((ts, d)) if ts.elapsed() < DETAIL_CACHE_TTL => Some(d.clone()),
            _ => None,
        }
    }

    fn store_detail(&self, asset_id: String, detail: AssetDetail) {
        if let Ok(mut map) = self.details.lock() {
            evict_if_full(&mut map, DETAIL_CACHE_TTL);
            map.insert(asset_id, (Instant::now(), detail));
        }
    }

    fn cached_search(&self, key: &str) -> Option<AssetLibraryResponse> {
        let map = self.searches.lock().ok()?;
        match map.get(key) {
            Some((ts, r)) if ts.elapsed() < SEARCH_CACHE_TTL => Some(r.clone()),
            _ => None,
        }
    }

    fn store_search(&self, key: String, resp: AssetLibraryResponse) {
        if let Ok(mut map) = self.searches.lock() {
            evict_if_full(&mut map, SEARCH_CACHE_TTL);
            map.insert(key, (Instant::now(), resp));
        }
    }
}

async fn cached_detail(
    cache: &AssetResponseCache,
    http: &reqwest::Client,
    asset_id: &str,
) -> Option<AssetDetail> {
    if let Some(detail) = cache.cached_detail(asset_id) {
        return Some(detail);
    }
    let detail = fetch_detail(http, asset_id).await?;
    cache.store_detail(asset_id.to_string(), detail.clone());
    Some(detail)
}

fn emit_asset_error(app: &AppHandle, asset_id: &str, title: &str, message: &str) {
    let _ = app.emit(
        "asset-download-error",
        AssetDownloadError {
            asset_id: asset_id.to_string(),
            title: title.to_string(),
            message: message.to_string(),
        },
    );
}

fn emit_asset_queued(app: &AppHandle, detail: &AssetDetail) {
    let _ = app.emit(
        "asset-download-queued",
        AssetDownloadProgress {
            asset_id: detail.asset_id.clone(),
            title: detail.title.clone(),
            downloaded: 0,
            total: 0,
        },
    );
}

fn emit_asset_complete(app: &AppHandle, detail: &AssetDetail) {
    let _ = app.emit(
        "asset-download-complete",
        AssetDownloadProgress {
            asset_id: detail.asset_id.clone(),
            title: detail.title.clone(),
            downloaded: 0,
            total: 0,
        },
    );
}

async fn stream_download_bytes(
    app: &AppHandle,
    http: &reqwest::Client,
    detail: &AssetDetail,
    download_url: &str,
) -> Result<Vec<u8>, String> {
    let resp = http
        .get(download_url)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("Asset download returned HTTP {}", resp.status()));
    }
    let total = resp.content_length().unwrap_or(0);
    let mut bytes: Vec<u8> = Vec::new();
    let mut downloaded: u64 = 0;
    let mut stream = resp.bytes_stream();
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| e.to_string())?;
        downloaded += chunk.len() as u64;
        let _ = app.emit(
            "asset-download-progress",
            AssetDownloadProgress {
                asset_id: detail.asset_id.clone(),
                title: detail.title.clone(),
                downloaded,
                total,
            },
        );
        bytes.extend_from_slice(&chunk);
    }
    Ok(bytes)
}

#[tauri::command]
pub async fn search_asset_library(
    state: tauri::State<'_, Arc<AssetResponseCache>>,
    filter: Option<String>,
    godot_version: Option<String>,
    page: Option<u32>,
    max_results: Option<u32>,
    asset_type: Option<String>,
    category_id: Option<String>,
    sort: Option<String>,
    reverse: Option<bool>,
) -> Result<AssetLibraryResponse, String> {
    let cache = state.inner().clone();
    let cache_key = format!(
        "lib|{filter:?}|{godot_version:?}|{page:?}|{max_results:?}|{asset_type:?}|{category_id:?}|{sort:?}|{reverse:?}"
    );
    if let Some(resp) = cache.cached_search(&cache_key) {
        return Ok(resp);
    }

    let http = client()?;
    let max_results = max_results.unwrap_or(20);
    let start_page = page.unwrap_or(0);

    let (type_param, apply_default_filters) = match asset_type.as_deref() {
        None | Some("") => ("project".to_string(), true),
        Some("any") => ("any".to_string(), false),
        Some(t) => (t.to_string(), false),
    };

    let mut current_page = start_page;
    let mut pages = start_page + 1;
    let mut total = 0u32;
    let mut assets: Vec<AssetLibraryAsset> = Vec::new();

    let mut skipped = 0u32;
    while assets.is_empty() && skipped <= MAX_PAGE_SKIP {
        let mut params = vec![
            ("max_results".to_string(), max_results.to_string()),
            ("page".to_string(), current_page.to_string()),
        ];
        if !type_param.is_empty() {
            params.push(("type".to_string(), type_param.clone()));
        }
        if let Some(c) = category_id
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
        {
            params.push(("category".to_string(), c.to_string()));
        }
        if let Some(f) = filter
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
        {
            params.push(("filter".to_string(), f.to_string()));
        }
        if let Some(v) = godot_version
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
        {
            params.push(("godot_version".to_string(), v.to_string()));
        }
        if let Some(s) = sort.as_deref().map(str::trim).filter(|s| !s.is_empty()) {
            params.push(("sort".to_string(), s.to_string()));
        }
        if reverse.unwrap_or(false) {
            params.push(("reverse".to_string(), "1".to_string()));
        }

        let url = reqwest::Url::parse_with_params(&format!("{ASSET_LIB_API}/asset"), &params)
            .map_err(|e| e.to_string())?;
        let resp = http
            .get(url)
            .send()
            .await
            .map_err(|e| e.to_string())?;
        if !resp.status().is_success() {
            return Err(format!(
                "Godot Asset Library returned HTTP {}",
                resp.status()
            ));
        }
        let search: AssetSearchResponse = resp.json().await.map_err(|e| e.to_string())?;
        pages = search.pages;
        total = search.total_items;

        let ids: Vec<String> = search.result.iter().map(|r| r.asset_id.clone()).collect();
        let futures = ids.into_iter().map(|id| {
            let http = http.clone();
            let cache = cache.clone();
            async move { cached_detail(&cache, &http, &id).await }
        });
        let details: Vec<Option<AssetDetail>> = futures_util::stream::iter(futures)
            .buffer_unordered(8)
            .collect()
            .await;
        let failures = details.iter().filter(|d| d.is_none()).count();
        if failures > 0 {
            eprintln!("Asset Library: {failures} detail fetch(es) failed");
        }

        assets = details
            .into_iter()
            .flatten()
            .filter(|d| !apply_default_filters || ALLOWED_TYPES.contains(&d.asset_type.as_str()))
            .map(|d| AssetLibraryAsset {
                asset_id: d.asset_id,
                title: d.title,
                author: d.author,
                category: d.category,
                godot_version: d.godot_version,
                cost: d.cost,
                support_level: d.support_level,
                asset_type: d.asset_type,
                description: d.description,
                icon_url: d.icon_url,
                download_url: d.download_url,
                browse_url: d.browse_url,
                modify_date: d.modify_date,
                rating: d.rating.clone(),
                source: "library".to_string(),
            })
            .collect();

        if assets.is_empty() {
            skipped += 1;
            current_page += 1;
            if current_page >= pages {
                break;
            }
        }
    }

    let response = AssetLibraryResponse {
        assets,
        page: current_page.min(pages.saturating_sub(1)),
        pages,
        total,
    };
    cache.store_search(cache_key, response.clone());
    Ok(response)
}

#[tauri::command]
pub async fn get_asset_library_categories() -> Result<Vec<AssetLibraryCategory>, String> {
    let http = client()?;
    let resp = http
        .get(format!("{ASSET_LIB_API}/configure?type=any"))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!(
            "Godot Asset Library returned HTTP {}",
            resp.status()
        ));
    }
    #[derive(Deserialize)]
    struct ConfigureResponse {
        categories: Vec<AssetLibraryCategory>,
    }
    let cfg: ConfigureResponse = resp.json().await.map_err(|e| e.to_string())?;
    Ok(cfg.categories)
}

#[derive(Debug, Clone, Deserialize)]
struct StoreSearchResponse {
    #[serde(default)]
    count: Option<String>,
    #[serde(default)]
    hits: Vec<StoreSearchHit>,
}

#[derive(Debug, Clone, Deserialize)]
struct StoreSearchHit {
    #[serde(default)]
    asset: StoreAsset,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct StorePublisher {
    #[serde(default)]
    name: String,
    #[serde(default)]
    slug: String,
}

#[derive(Debug, Clone, Deserialize)]
struct StoreTag {
    #[serde(default)]
    display_name: String,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct StoreAsset {
    #[serde(default)]
    slug: String,
    #[serde(default)]
    publisher: StorePublisher,
    #[serde(default)]
    name: String,
    #[serde(default, rename = "type")]
    asset_type: i64,
    #[serde(default)]
    description: Option<String>,
    #[serde(default, rename = "license_type")]
    license_type: String,
    #[serde(default)]
    thumbnail: Option<String>,
    #[serde(default, rename = "reviews_score")]
    reviews_score: i64,
    #[serde(default)]
    tags: Vec<StoreTag>,
    #[serde(default, rename = "store_url")]
    store_url: String,
}

fn normalize_store_asset(a: StoreAsset) -> AssetLibraryAsset {
    let publisher_slug = a.publisher.slug.clone();
    let asset_slug = a.slug.clone();
    AssetLibraryAsset {
        asset_id: format!("store:{publisher_slug}/{asset_slug}"),
        title: a.name,
        author: a.publisher.name,
        category: a
            .tags
            .first()
            .map(|t| t.display_name.clone())
            .unwrap_or_default(),
        godot_version: String::new(),
        cost: a.license_type,
        support_level: String::new(),
        asset_type: if a.asset_type == 1 {
            "project"
        } else {
            "addon"
        }
        .to_string(),
        description: a.description,
        icon_url: a.thumbnail,
        download_url: None,
        browse_url: if a.store_url.is_empty() {
            Some(format!("https://store.godotengine.org/asset/{publisher_slug}/{asset_slug}/"))
        } else {
            Some(a.store_url)
        },
        modify_date: None,
        rating: a.reviews_score.to_string(),
        source: "store".to_string(),
    }
}

#[tauri::command]
pub async fn search_asset_store(
    state: tauri::State<'_, Arc<AssetResponseCache>>,
    filter: Option<String>,
    godot_version: Option<String>,
    page: Option<u32>,
    max_results: Option<u32>,
    sort: Option<String>,
) -> Result<AssetLibraryResponse, String> {
    let cache = state.inner().clone();
    let cache_key = format!(
        "store|{filter:?}|{godot_version:?}|{page:?}|{max_results:?}|{sort:?}"
    );
    if let Some(resp) = cache.cached_search(&cache_key) {
        return Ok(resp);
    }

    let http = client()?;
    let max_results = max_results.unwrap_or(12).clamp(1, 100);
    let app_page = page.unwrap_or(0);
    let store_page = (app_page + 1).max(1);
    let query = filter.as_deref().map(str::trim).unwrap_or("");

    let mut params = vec![
        ("type".to_string(), "0".to_string()),
        ("page".to_string(), store_page.to_string()),
        ("query".to_string(), query.to_string()),
        ("batch_size".to_string(), max_results.to_string()),
    ];
    if let Some(s) = sort
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        params.push(("sort".to_string(), s.to_string()));
    }
    if let Some(v) = godot_version
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        params.push(("compatibility".to_string(), v.to_string()));
    }

    let url = reqwest::Url::parse_with_params(
        &format!("{ASSET_STORE_API}/search/query/"),
        &params,
    )
    .map_err(|e| e.to_string())?;
    let resp = http.get(url).send().await.map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("Godot Asset Store returned HTTP {}", resp.status()));
    }
    let search: StoreSearchResponse = resp.json().await.map_err(|e| e.to_string())?;
    let count = search
        .count
        .as_deref()
        .and_then(|c| c.parse::<u32>().ok())
        .unwrap_or(search.hits.len() as u32);
    let pages = if count > 0 {
        (count + max_results - 1) / max_results
    } else {
        1
    };

    let response = AssetLibraryResponse {
        assets: search
            .hits
            .into_iter()
            .map(|h| normalize_store_asset(h.asset))
            .collect(),
        page: app_page,
        pages,
        total: count,
    };
    cache.store_search(cache_key, response.clone());
    Ok(response)
}

#[tauri::command]
pub async fn install_asset_as_template(
    app: AppHandle,
    asset_id: String,
) -> Result<ProjectTemplate, String> {
    let http = client()?;

    let detail = match fetch_detail(&http, &asset_id).await {
        Some(d) => d,
        None => {
            let message = format!("Could not fetch asset {asset_id} from the Asset Library");
            emit_asset_error(&app, &asset_id, "", &message);
            return Err(message);
        }
    };

    if !ALLOWED_TYPES.contains(&detail.asset_type.as_str()) {
        let message = format!(
            "This asset ({}) can't be installed as a project template",
            detail.asset_type
        );
        emit_asset_error(&app, &asset_id, &detail.title, &message);
        return Err(message);
    }
    if !meets_min_version(&detail.godot_version) {
        let message = format!(
            "This asset targets Godot {} which is older than the supported minimum (4.1)",
            detail.godot_version
        );
        emit_asset_error(&app, &asset_id, &detail.title, &message);
        return Err(message);
    }
    let download_url = match detail.download_url.clone() {
        Some(url) => url,
        None => {
            let message = "This asset has no download URL".to_string();
            emit_asset_error(&app, &asset_id, &detail.title, &message);
            return Err(message);
        }
    };

    emit_asset_queued(&app, &detail);

    let result = download_and_install(&app, &http, &detail, &asset_id, &download_url).await;

    match &result {
        Ok(_) => emit_asset_complete(&app, &detail),
        Err(message) => {
            emit_asset_error(&app, &asset_id, &detail.title, message);
        }
    }

    result
}

enum InstallTarget {
    Project { name: String, dir: PathBuf },
    Template { name: String, dir: PathBuf },
}

impl InstallTarget {
    fn name(&self) -> &str {
        match self {
            InstallTarget::Project { name, .. } | InstallTarget::Template { name, .. } => name,
        }
    }

    fn dir(&self) -> &Path {
        match self {
            InstallTarget::Project { dir, .. } | InstallTarget::Template { dir, .. } => dir,
        }
    }

    fn type_str(&self) -> &str {
        match self {
            InstallTarget::Project { .. } => "project",
            InstallTarget::Template { .. } => "template",
        }
    }
}

fn resolve_install_target(
    app: &AppHandle,
    project_id: &Option<String>,
    template_id: &Option<String>,
) -> Result<InstallTarget, String> {
    match (project_id, template_id) {
        (Some(pid), None) => {
            let projects = crate::projects::read_projects(app);
            let project = projects
                .iter()
                .find(|p| p.id == *pid)
                .ok_or("Project not found")?;
            let dir = PathBuf::from(&project.path);
            if !dir.is_dir() {
                return Err(format!(
                    "Project folder no longer exists on disk: {}",
                    project.path
                ));
            }
            Ok(InstallTarget::Project {
                name: project.name.clone(),
                dir,
            })
        }
        (None, Some(tid)) => {
            let dir = crate::templates::resolve_template_dir(app, tid)
                .ok_or("Template not found")?;
            let name = crate::templates::list_templates(app.clone())
                .into_iter()
                .find(|t| t.id == *tid)
                .map(|t| t.name)
                .unwrap_or_else(|| tid.clone());
            Ok(InstallTarget::Template { name, dir })
        }
        _ => Err("Specify exactly one install target (project or template)".into()),
    }
}

#[tauri::command]
pub async fn install_asset(
    app: AppHandle,
    asset_id: String,
    project_id: Option<String>,
    template_id: Option<String>,
) -> Result<InstallAssetResult, String> {
    let target = resolve_install_target(&app, &project_id, &template_id)?;

    let http = client()?;
    let detail = match fetch_detail(&http, &asset_id).await {
        Some(d) => d,
        None => {
            let message = format!("Could not fetch asset {asset_id} from the Asset Library");
            emit_asset_error(&app, &asset_id, "", &message);
            return Err(message);
        }
    };
    let download_url = match detail.download_url.clone() {
        Some(url) => url,
        None => {
            let message = "This asset has no download URL".to_string();
            emit_asset_error(&app, &asset_id, &detail.title, &message);
            return Err(message);
        }
    };

    emit_asset_queued(&app, &detail);

    let result = download_and_merge(&app, &http, &detail, &asset_id, &download_url, &target).await;

    match &result {
        Ok(_) => emit_asset_complete(&app, &detail),
        Err(message) => {
            emit_asset_error(&app, &asset_id, &detail.title, message);
        }
    }

    result
}

async fn download_and_merge(
    app: &AppHandle,
    http: &reqwest::Client,
    detail: &AssetDetail,
    asset_id: &str,
    download_url: &str,
    target: &InstallTarget,
) -> Result<InstallAssetResult, String> {
    let bytes = stream_download_bytes(app, http, detail, download_url).await?;

    let temp_key = asset_id.replace([':', '/', '\\'], "_");
    let temp_dir = std::env::temp_dir().join(format!("godothub-asset-{temp_key}"));
    let _ = crate::templates::remove_dir_force(&temp_dir);
    fs::create_dir_all(&temp_dir).map_err(|e| e.to_string())?;

    let merge_result = extract_zip(&bytes, &temp_dir)
        .and_then(|_| {
            let root = find_content_root(&temp_dir);
            merge_asset_into(&root, target.dir())
        })
        .map(|_| InstallAssetResult {
            asset_id: asset_id.to_string(),
            title: detail.title.clone(),
            target_type: target.type_str().to_string(),
            target_name: target.name().to_string(),
            path: target.dir().to_string_lossy().to_string(),
        });

    let _ = crate::templates::remove_dir_force(&temp_dir);
    merge_result
}

#[tauri::command]
pub async fn download_asset(
    app: AppHandle,
    asset_id: String,
    dest_dir: Option<String>,
) -> Result<String, String> {
    let http = client()?;
    let detail = match fetch_detail(&http, &asset_id).await {
        Some(d) => d,
        None => {
            let message = format!("Could not fetch asset {asset_id} from the Asset Library");
            emit_asset_error(&app, &asset_id, "", &message);
            return Err(message);
        }
    };
    let download_url = match detail.download_url.clone() {
        Some(url) => url,
        None => {
            let message = "This asset has no download URL".to_string();
            emit_asset_error(&app, &asset_id, &detail.title, &message);
            return Err(message);
        }
    };

    let dir = resolve_download_dir(&app, dest_dir.as_deref())?;
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;

    let base = crate::templates::sanitize_folder_name(&detail.title);
    let mut file_name = format!("{base}.zip");
    let mut n = 2;
    while dir.join(&file_name).exists() {
        file_name = format!("{base} ({n}).zip");
        n += 1;
    }
    let dest = dir.join(&file_name);

    emit_asset_queued(&app, &detail);

    let result = download_to_file(&app, &http, &download_url, &dest, &asset_id, &detail.title).await;

    match &result {
        Ok(_) => emit_asset_complete(&app, &detail),
        Err(message) => {
            let _ = fs::remove_file(&dest);
            emit_asset_error(&app, &asset_id, &detail.title, message);
        }
    }

    result.map(|_| dest.to_string_lossy().to_string())
}

async fn download_to_file(
    app: &AppHandle,
    http: &reqwest::Client,
    url: &str,
    dest: &Path,
    asset_id: &str,
    title: &str,
) -> Result<(), String> {
    let resp = http.get(url).send().await.map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("Asset download returned HTTP {}", resp.status()));
    }
    let total = resp.content_length().unwrap_or(0);
    let mut file = fs::File::create(dest).map_err(|e| e.to_string())?;
    let mut downloaded: u64 = 0;
    let mut stream = resp.bytes_stream();
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| e.to_string())?;
        downloaded += chunk.len() as u64;
        file.write_all(&chunk).map_err(|e| e.to_string())?;
        let _ = app.emit(
            "asset-download-progress",
            AssetDownloadProgress {
                asset_id: asset_id.to_string(),
                title: title.to_string(),
                downloaded,
                total,
            },
        );
    }
    Ok(())
}

#[derive(Debug, Clone, Deserialize)]
struct StoreRelease {
    #[serde(default, rename = "download_url")]
    download_url: Option<String>,
    #[serde(default)]
    stable: bool,
}

async fn resolve_store_download_url(
    http: &reqwest::Client,
    publisher_slug: &str,
    asset_slug: &str,
) -> Result<String, String> {
    let releases: Vec<StoreRelease> = http
        .get(format!(
            "{ASSET_STORE_API}/releases/{publisher_slug}/{asset_slug}/"
        ))
        .send()
        .await
        .map_err(|e| e.to_string())?
        .json()
        .await
        .map_err(|e| e.to_string())?;
    releases
        .iter()
        .find(|r| r.stable && r.download_url.is_some())
        .or_else(|| releases.iter().find(|r| r.download_url.is_some()))
        .and_then(|r| r.download_url.clone())
        .ok_or_else(|| "No downloadable release available for this asset".to_string())
}

#[tauri::command]
pub async fn install_store_asset(
    app: AppHandle,
    publisher_slug: String,
    asset_slug: String,
    title: Option<String>,
    project_id: Option<String>,
    template_id: Option<String>,
) -> Result<InstallAssetResult, String> {
    let target = resolve_install_target(&app, &project_id, &template_id)?;

    let http = client()?;
    let download_url = resolve_store_download_url(&http, &publisher_slug, &asset_slug).await?;

    let base = crate::templates::sanitize_folder_name(
        title
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .unwrap_or(&asset_slug),
    );
    let asset_id = format!("store:{publisher_slug}/{asset_slug}");
    let detail = AssetDetail {
        asset_id: asset_id.clone(),
        title: base,
        ..Default::default()
    };

    emit_asset_queued(&app, &detail);

    let result = download_and_merge(&app, &http, &detail, &asset_id, &download_url, &target).await;

    match &result {
        Ok(_) => emit_asset_complete(&app, &detail),
        Err(message) => {
            emit_asset_error(&app, &asset_id, &detail.title, message);
        }
    }

    result
}

#[tauri::command]
pub async fn download_store_asset(
    app: AppHandle,
    publisher_slug: String,
    asset_slug: String,
    title: Option<String>,
    dest_dir: Option<String>,
) -> Result<String, String> {
    let http = client()?;
    let download_url = resolve_store_download_url(&http, &publisher_slug, &asset_slug).await?;

    let dir = resolve_download_dir(&app, dest_dir.as_deref())?;
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;

    let base = crate::templates::sanitize_folder_name(
        title
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .unwrap_or(&asset_slug),
    );
    let mut file_name = format!("{base}.zip");
    let mut n = 2;
    while dir.join(&file_name).exists() {
        file_name = format!("{base} ({n}).zip");
        n += 1;
    }
    let dest = dir.join(&file_name);

    let asset_id = format!("store:{publisher_slug}/{asset_slug}");
    let detail = AssetDetail {
        asset_id: asset_id.clone(),
        title: base.clone(),
        ..Default::default()
    };
    emit_asset_queued(&app, &detail);

    let result = download_to_file(&app, &http, &download_url, &dest, &asset_id, &base).await;

    match &result {
        Ok(_) => emit_asset_complete(&app, &detail),
        Err(message) => {
            let _ = fs::remove_file(&dest);
            emit_asset_error(&app, &asset_id, &base, message);
        }
    }

    result.map(|_| dest.to_string_lossy().to_string())
}

fn resolve_download_dir(app: &AppHandle, dest_dir: Option<&str>) -> Result<PathBuf, String> {
    if let Some(d) = dest_dir.map(str::trim).filter(|s| !s.is_empty()) {
        return Ok(PathBuf::from(d));
    }
    if let Ok(d) = app.path().download_dir() {
        return Ok(d);
    }
    let settings = crate::settings::read_settings(app);
    if let Some(d) = settings
        .download_dir
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        return Ok(PathBuf::from(d));
    }
    if let Ok(d) = app.path().home_dir() {
        return Ok(d);
    }
    Ok(std::env::temp_dir())
}

async fn download_and_install(
    app: &AppHandle,
    http: &reqwest::Client,
    detail: &AssetDetail,
    asset_id: &str,
    download_url: &str,
) -> Result<ProjectTemplate, String> {
    let bytes = stream_download_bytes(app, http, detail, download_url).await?;

    let temp_key = asset_id.replace([':', '/', '\\'], "_");
    let temp_dir = std::env::temp_dir().join(format!("godothub-asset-{temp_key}"));
    let _ = crate::templates::remove_dir_force(&temp_dir);
    fs::create_dir_all(&temp_dir).map_err(|e| e.to_string())?;

    let extract_result = extract_zip(&bytes, &temp_dir)
        .and_then(|_| find_project_root(&temp_dir))
        .and_then(|src| {
            crate::templates::install_downloaded_asset(
                app,
                detail.title.clone(),
                detail.description.clone().unwrap_or_default(),
                detail.godot_version.clone(),
                &src,
            )
        });

    let _ = crate::templates::remove_dir_force(&temp_dir);
    extract_result
}

fn extract_zip(bytes: &[u8], dest: &Path) -> Result<(), String> {
    let mut archive = zip::ZipArchive::new(Cursor::new(bytes)).map_err(|e| e.to_string())?;
    for i in 0..archive.len() {
        let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
        let name = file.name().to_string();
        if name.contains("..")
            || name.starts_with('/')
            || name.starts_with('\\')
            || name.contains(":/")
            || name.contains(":\\")
        {
            continue;
        }
        let out_path = dest.join(&name);
        if file.is_dir() {
            fs::create_dir_all(&out_path).map_err(|e| e.to_string())?;
        } else {
            if let Some(parent) = out_path.parent() {
                fs::create_dir_all(parent).map_err(|e| e.to_string())?;
            }
            let mut out = fs::File::create(&out_path).map_err(|e| e.to_string())?;
            std::io::copy(&mut file, &mut out).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

fn find_project_root(dir: &Path) -> Result<PathBuf, String> {
    if dir.join("project.godot").is_file() {
        return Ok(dir.to_path_buf());
    }
    let mut subdirs: Vec<PathBuf> = Vec::new();
    for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        if entry.path().is_dir() {
            subdirs.push(entry.path());
        }
    }
    if subdirs.len() == 1 {
        let sub = subdirs.remove(0);
        if sub.join("project.godot").is_file() {
            return Ok(sub);
        }
        return find_project_root(&sub);
    }
    for sub in &subdirs {
        if sub.join("project.godot").is_file() {
            return Ok(sub.clone());
        }
    }
    Ok(dir.to_path_buf())
}

fn find_content_root(dir: &Path) -> PathBuf {
    if dir.join("addons").is_dir() || dir.join("project.godot").is_file() {
        return dir.to_path_buf();
    }
    let mut subdirs: Vec<PathBuf> = Vec::new();
    let mut has_files = false;
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                subdirs.push(path);
            } else {
                has_files = true;
            }
        }
    }
    if subdirs.len() == 1 && !has_files {
        return find_content_root(&subdirs[0]);
    }
    dir.to_path_buf()
}

fn merge_asset_into(src: &Path, dst: &Path) -> Result<(), String> {
    let skip_dirs: &[&str] = &[".godot", ".git", "node_modules"];
    let protect_project_file = dst.join("project.godot").is_file();
    if !dst.exists() {
        fs::create_dir_all(dst).map_err(|e| e.to_string())?;
    }
    for entry in fs::read_dir(src).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let name = entry.file_name();
        let name_str = name.to_string_lossy().to_string();
        if skip_dirs.contains(&name_str.as_str()) {
            continue;
        }
        if protect_project_file && name_str == "project.godot" {
            continue;
        }
        let src_path = entry.path();
        let dst_path = dst.join(&name);
        if src_path.is_dir() {
            crate::templates::copy_dir(&src_path, &dst_path, skip_dirs)?;
        } else {
            if let Some(parent) = dst_path.parent() {
                fs::create_dir_all(parent).map_err(|e| e.to_string())?;
            }
            fs::copy(&src_path, &dst_path).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}
