//! Asset Store and Asset Library extras on top of search and install: a
//! normalized detail view for both sources, a file listing of an asset's
//! archive (downloaded once into a capped cache that installs reuse), the
//! user's favorite and hidden assets, and update checks for templates that
//! came from the Asset Library.

use crate::asset_library::{
    client, fetch_detail, normalize_store_asset, resolve_store_download_url, AssetDetail,
    AssetLibraryAsset, StoreAsset, ASSET_LIB_API, ASSET_STORE_API, MAX_ASSET_DOWNLOAD_BYTES,
};
use crate::persist::{self, Versioned};
use crate::AppHandle;
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize)]
pub struct AssetMedia {
    pub url: String,
    pub thumbnail: Option<String>,
    /// A video link (YouTube and the like) rather than an image.
    pub video: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct AssetRelease {
    pub version: String,
    pub date: String,
    pub notes: String,
    pub min_godot: Option<String>,
    pub max_godot: Option<String>,
    pub stable: bool,
    pub size_bytes: Option<u64>,
}

/// Everything the asset detail dialog shows, the same shape for both sources.
#[derive(Debug, Clone, Serialize)]
pub struct AssetInfo {
    pub asset: AssetLibraryAsset,
    /// Plain text; the Store's BBCode is flattened.
    pub description: String,
    pub version: String,
    pub revision: Option<u64>,
    pub license: String,
    pub license_url: Option<String>,
    pub source_url: Option<String>,
    pub issues_url: Option<String>,
    pub updated: Option<String>,
    pub media: Vec<AssetMedia>,
    pub releases: Vec<AssetRelease>,
    pub download_size_bytes: Option<u64>,
    /// Paid Store assets can't be downloaded or previewed from GodotHub.
    pub paid: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct AssetFileEntry {
    pub path: String,
    pub is_dir: bool,
    pub size: u64,
}

#[derive(Debug, Clone, Serialize)]
pub struct AssetFileListing {
    pub entries: Vec<AssetFileEntry>,
    /// The archive held more entries than are listed.
    pub truncated: bool,
    pub archive_bytes: u64,
}

fn store_slugs(asset_id: &str) -> Option<(String, String)> {
    let rest = asset_id.strip_prefix("store:")?;
    let (publisher, slug) = rest.split_once('/')?;
    (!publisher.is_empty() && !slug.is_empty()).then(|| (publisher.to_string(), slug.to_string()))
}

/// Flattens BBCode to readable plain text: tags are dropped, list items get a
/// bullet, `[url=..]label[/url]` keeps the label, and images disappear.
pub(crate) fn bbcode_to_text(input: &str) -> String {
    let img = regex::Regex::new(r"(?is)\[img[^\]]*\].*?\[/img\]").unwrap();
    let item = regex::Regex::new(r"(?i)\[\*\]|\[li\]").unwrap();
    let tag = regex::Regex::new(r"(?i)\[/?[a-z][a-z0-9]*(=[^\]]*)?\]").unwrap();
    let text = img.replace_all(input, "");
    let text = item.replace_all(&text, "\n• ");
    let text = tag.replace_all(&text, "");
    let blank_lines = regex::Regex::new(r"\n{3,}").unwrap();
    blank_lines
        .replace_all(text.trim(), "\n\n")
        .replace("\r\n", "\n")
}

fn value_str(v: &serde_json::Value, key: &str) -> Option<String> {
    match v.get(key)? {
        serde_json::Value::String(s) if !s.trim().is_empty() => Some(s.trim().to_string()),
        serde_json::Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}

fn library_asset(d: &AssetDetail) -> AssetLibraryAsset {
    AssetLibraryAsset {
        asset_id: d.asset_id.clone(),
        title: d.title.clone(),
        author: d.author.clone(),
        category: d.category.clone(),
        godot_version: d.godot_version.clone(),
        cost: d.cost.clone(),
        support_level: d.support_level.clone(),
        asset_type: d.asset_type.clone(),
        description: d.description.clone(),
        icon_url: d.icon_url.clone(),
        download_url: d.download_url.clone(),
        browse_url: d.browse_url.clone(),
        modify_date: d.modify_date.clone(),
        rating: d.rating.clone(),
        source: "library".to_string(),
        version: d.version_string.clone(),
    }
}

pub(crate) fn library_info(raw: &serde_json::Value) -> Result<AssetInfo, String> {
    let detail: AssetDetail = serde_json::from_value(raw.clone()).map_err(|e| e.to_string())?;
    let media = raw
        .get("previews")
        .and_then(|p| p.as_array())
        .map(|items| {
            items
                .iter()
                .filter_map(|p| {
                    let url = value_str(p, "link")?;
                    Some(AssetMedia {
                        thumbnail: value_str(p, "thumbnail"),
                        video: value_str(p, "type").is_some_and(|t| t == "video"),
                        url,
                    })
                })
                .collect()
        })
        .unwrap_or_default();
    Ok(AssetInfo {
        description: detail
            .description
            .clone()
            .unwrap_or_default()
            .replace("\r\n", "\n")
            .trim()
            .to_string(),
        version: detail.version_string.clone(),
        revision: detail.revision(),
        license: detail.cost.clone(),
        license_url: None,
        source_url: detail.browse_url.clone(),
        issues_url: value_str(raw, "issues_url"),
        updated: detail.modify_date.clone(),
        media,
        releases: vec![],
        download_size_bytes: None,
        paid: false,
        asset: library_asset(&detail),
    })
}

pub(crate) fn store_info(
    raw: &serde_json::Value,
    releases: &serde_json::Value,
) -> Result<AssetInfo, String> {
    let store: StoreAsset = serde_json::from_value(raw.clone()).map_err(|e| e.to_string())?;
    let mut asset = normalize_store_asset(store);
    let updated = value_str(raw, "last_updated");
    asset.modify_date = updated.clone();
    let mut media: Vec<AssetMedia> = raw
        .get("media")
        .and_then(|m| m.as_array())
        .map(|items| {
            items
                .iter()
                .filter_map(|m| m.as_str().filter(|s| !s.is_empty()))
                .map(|url| AssetMedia {
                    url: url.to_string(),
                    thumbnail: None,
                    video: false,
                })
                .collect()
        })
        .unwrap_or_default();
    if let Some(video) =
        value_str(raw, "video_playback_url").or_else(|| value_str(raw, "video_embed_url"))
    {
        media.insert(
            0,
            AssetMedia {
                url: video,
                thumbnail: value_str(raw, "video_thumbnail_url"),
                video: true,
            },
        );
    }
    let releases: Vec<AssetRelease> = releases
        .as_array()
        .map(|items| {
            items
                .iter()
                .map(|r| AssetRelease {
                    version: value_str(r, "version").unwrap_or_default(),
                    date: value_str(r, "created").unwrap_or_default(),
                    notes: value_str(r, "changes_bbcode")
                        .map(|t| bbcode_to_text(&t))
                        .unwrap_or_default(),
                    min_godot: value_str(r, "min_godot_version"),
                    max_godot: value_str(r, "max_godot_version"),
                    stable: r.get("stable").and_then(|s| s.as_bool()).unwrap_or(true),
                    // The Store reports sizes in megabytes.
                    size_bytes: r
                        .get("size")
                        .and_then(|s| s.as_f64())
                        .map(|mb| (mb * 1_048_576.0) as u64),
                })
                .collect()
        })
        .unwrap_or_default();
    let latest = releases
        .iter()
        .find(|r| r.stable)
        .or_else(|| releases.first());
    if let Some(min) = latest.and_then(|r| r.min_godot.clone()) {
        asset.godot_version = min;
    }
    if let Some(release) = latest {
        asset.version = release.version.clone();
    }
    let price = value_str(raw, "price_cent")
        .and_then(|p| p.parse::<f64>().ok())
        .unwrap_or(0.0);
    Ok(AssetInfo {
        description: value_str(raw, "body_bbcode")
            .map(|b| bbcode_to_text(&b))
            .or_else(|| asset.description.clone())
            .unwrap_or_default(),
        version: latest.map(|r| r.version.clone()).unwrap_or_default(),
        revision: None,
        license: asset.cost.clone(),
        license_url: value_str(raw, "license_url"),
        source_url: value_str(raw, "source"),
        issues_url: None,
        updated,
        media,
        download_size_bytes: latest.and_then(|r| r.size_bytes),
        paid: price > 0.0,
        releases,
        asset,
    })
}

async fn get_json(http: &reqwest::Client, url: &str) -> Result<serde_json::Value, String> {
    let resp = http.get(url).send().await.map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("The server returned HTTP {}", resp.status()));
    }
    resp.json().await.map_err(|e| e.to_string())
}

pub async fn get_asset_info(asset_id: String) -> Result<AssetInfo, String> {
    let http = client()?;
    if let Some((publisher, slug)) = store_slugs(&asset_id) {
        let raw = get_json(
            &http,
            &format!("{ASSET_STORE_API}/assets/{publisher}/{slug}/"),
        )
        .await?;
        let releases = get_json(
            &http,
            &format!("{ASSET_STORE_API}/releases/{publisher}/{slug}/"),
        )
        .await
        .unwrap_or(serde_json::Value::Array(vec![]));
        return store_info(&raw, &releases);
    }
    let raw = get_json(&http, &format!("{ASSET_LIB_API}/asset/{asset_id}")).await?;
    let mut info = library_info(&raw)?;
    if let Some(url) = info.asset.download_url.clone() {
        info.download_size_bytes = http
            .head(&url)
            .timeout(std::time::Duration::from_secs(8))
            .send()
            .await
            .ok()
            .filter(|r| r.status().is_success())
            .and_then(|r| r.content_length())
            .filter(|n| *n > 0);
    }
    Ok(info)
}

// ---------------------------------------------------------------------------
// Archive cache shared by the file preview and installs.

const ARCHIVE_CACHE_MAX_FILES: usize = 12;
const ARCHIVE_CACHE_MAX_BYTES: u64 = 1024 * 1024 * 1024;
const LISTING_MAX_ENTRIES: usize = 5_000;

fn archive_cache_dir(app: &AppHandle) -> Option<PathBuf> {
    app.path()
        .app_cache_dir()
        .ok()
        .map(|d| d.join("asset-archives"))
}

fn archive_cache_file(app: &AppHandle, url: &str) -> Option<PathBuf> {
    let mut hasher = DefaultHasher::new();
    url.hash(&mut hasher);
    archive_cache_dir(app).map(|d| d.join(format!("{:016x}.zip", hasher.finish())))
}

/// How long a previewed archive is trusted. Some assets publish every upload
/// at the same URL, so an older copy must not be installed as the new one.
const ARCHIVE_CACHE_MAX_AGE: std::time::Duration = std::time::Duration::from_secs(24 * 60 * 60);

/// A recently downloaded archive for [url], if the preview fetched it.
pub(crate) fn cached_archive(app: &AppHandle, url: &str) -> Option<PathBuf> {
    archive_cache_file(app, url).filter(|p| is_fresh(p, ARCHIVE_CACHE_MAX_AGE))
}

fn is_fresh(path: &Path, max_age: std::time::Duration) -> bool {
    fs::metadata(path)
        .ok()
        .filter(|m| m.is_file())
        .and_then(|m| m.modified().ok())
        .and_then(|t| t.elapsed().ok())
        .is_some_and(|age| age <= max_age)
}

/// Keeps the cache to the newest few archives and a total size cap.
pub(crate) fn prune_archive_cache(dir: &Path, max_files: usize, max_bytes: u64) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    let mut files: Vec<(PathBuf, std::time::SystemTime, u64)> = entries
        .flatten()
        .filter_map(|e| {
            let meta = e.metadata().ok()?;
            meta.is_file().then(|| {
                (
                    e.path(),
                    meta.modified().unwrap_or(std::time::UNIX_EPOCH),
                    meta.len(),
                )
            })
        })
        .collect();
    files.sort_by(|a, b| b.1.cmp(&a.1));
    let mut total = 0u64;
    for (i, (path, _, len)) in files.iter().enumerate() {
        total += len;
        if i >= max_files || total > max_bytes {
            let _ = fs::remove_file(path);
        }
    }
}

async fn download_archive(
    app: &AppHandle,
    http: &reqwest::Client,
    url: &str,
) -> Result<PathBuf, String> {
    if let Some(path) = cached_archive(app, url) {
        return Ok(path);
    }
    let dest = archive_cache_file(app, url).ok_or("No cache folder is available")?;
    let dir = dest.parent().ok_or("No cache folder is available")?;
    fs::create_dir_all(dir).map_err(|e| e.to_string())?;
    let partial = dest.with_extension("part");
    let resp = http
        .get(url)
        .header(reqwest::header::ACCEPT_ENCODING, "identity")
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("The download returned HTTP {}", resp.status()));
    }
    let mut file = fs::File::create(&partial).map_err(|e| e.to_string())?;
    let mut stream = resp.bytes_stream();
    let mut written = 0u64;
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| e.to_string())?;
        written += chunk.len() as u64;
        if written > MAX_ASSET_DOWNLOAD_BYTES {
            drop(file);
            let _ = fs::remove_file(&partial);
            return Err("This asset is too large to preview".into());
        }
        file.write_all(&chunk).map_err(|e| e.to_string())?;
    }
    drop(file);
    fs::rename(&partial, &dest).map_err(|e| e.to_string())?;
    prune_archive_cache(dir, ARCHIVE_CACHE_MAX_FILES, ARCHIVE_CACHE_MAX_BYTES);
    Ok(dest)
}

/// Lists the files of a zip archive, adding folder entries for folders that
/// are only implied by file paths, sorted folders-first per level.
pub(crate) fn list_zip(path: &Path, max_entries: usize) -> Result<AssetFileListing, String> {
    let file = fs::File::open(path).map_err(|e| e.to_string())?;
    let archive_bytes = file.metadata().map(|m| m.len()).unwrap_or(0);
    let mut zip = zip::ZipArchive::new(file)
        .map_err(|_| "The download is not a valid zip archive".to_string())?;
    let mut entries: std::collections::BTreeMap<String, AssetFileEntry> =
        std::collections::BTreeMap::new();
    let mut truncated = false;
    for i in 0..zip.len() {
        let Ok(entry) = zip.by_index_raw(i) else {
            continue;
        };
        let Some(name) = entry.enclosed_name() else {
            continue;
        };
        let path = name.to_string_lossy().replace('\\', "/");
        let path = path.trim_end_matches('/').to_string();
        if path.is_empty() {
            continue;
        }
        if entries.len() >= max_entries {
            truncated = true;
            break;
        }
        let parts: Vec<&str> = path.split('/').collect();
        for depth in 1..parts.len() {
            let dir = parts[..depth].join("/");
            entries.entry(dir.clone()).or_insert(AssetFileEntry {
                path: dir,
                is_dir: true,
                size: 0,
            });
        }
        let is_dir = entry.is_dir();
        entries.insert(
            path.clone(),
            AssetFileEntry {
                path,
                is_dir,
                size: if is_dir { 0 } else { entry.size() },
            },
        );
    }
    Ok(AssetFileListing {
        entries: entries.into_values().collect(),
        truncated,
        archive_bytes,
    })
}

pub async fn list_asset_files(
    app: AppHandle,
    asset_id: String,
) -> Result<AssetFileListing, String> {
    let http = client()?;
    let url = if let Some((publisher, slug)) = store_slugs(&asset_id) {
        resolve_store_download_url(&http, &publisher, &slug).await?
    } else {
        fetch_detail(&http, &asset_id)
            .await
            .and_then(|d| d.download_url)
            .ok_or("This asset has no download available")?
    };
    let path = download_archive(&app, &http, &url).await?;
    tokio::task::spawn_blocking(move || list_zip(&path, LISTING_MAX_ENTRIES))
        .await
        .map_err(|e| e.to_string())?
}

// ---------------------------------------------------------------------------
// Favorites and hidden assets. Global, not per workspace: an asset you like or
// dismissed is the same asset whichever workspace you browse it from.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HiddenAsset {
    pub asset_id: String,
    pub title: String,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct AssetPrefs {
    #[serde(default)]
    pub schema_version: u32,
    /// Card snapshots, so the Saved list renders without a network request.
    #[serde(default)]
    pub favorites: Vec<AssetLibraryAsset>,
    #[serde(default)]
    pub hidden: Vec<HiddenAsset>,
}

impl Versioned for AssetPrefs {
    const VERSION: u32 = 1;
}

fn prefs_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_data_dir()
        .map(|d| d.join("asset_prefs.json"))
        .map_err(|_| "No data folder is available".to_string())
}

pub fn get_asset_prefs(app: &AppHandle) -> AssetPrefs {
    prefs_path(app)
        .map(|p| persist::load_json::<AssetPrefs>(&p).value)
        .unwrap_or_default()
}

pub fn set_asset_favorite(
    app: &AppHandle,
    asset: AssetLibraryAsset,
    favorite: bool,
) -> Result<AssetPrefs, String> {
    persist::update_json::<AssetPrefs, _>(&prefs_path(app)?, |prefs| {
        prefs.favorites.retain(|a| a.asset_id != asset.asset_id);
        if favorite {
            prefs.favorites.insert(0, asset);
        }
    })
    .map_err(|e| e.to_string())
}

pub fn set_asset_hidden(
    app: &AppHandle,
    asset_id: String,
    title: String,
    hidden: bool,
) -> Result<AssetPrefs, String> {
    persist::update_json::<AssetPrefs, _>(&prefs_path(app)?, |prefs| {
        prefs.hidden.retain(|a| a.asset_id != asset_id);
        if hidden {
            prefs.hidden.insert(0, HiddenAsset { asset_id, title });
        }
    })
    .map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Template updates.

#[derive(Debug, Clone, Serialize)]
pub struct TemplateUpdate {
    pub template_id: String,
    pub asset_id: String,
    pub installed_version: String,
    pub latest_version: String,
}

/// Whether the library copy is newer than what a template was installed from.
/// Revisions are compared when both are known; otherwise the version strings.
pub(crate) fn is_newer(
    installed_version: &str,
    installed_revision: Option<u64>,
    latest: &AssetDetail,
) -> bool {
    match (installed_revision, latest.revision()) {
        (Some(have), Some(now)) => now > have,
        _ => !latest.version_string.is_empty() && latest.version_string != installed_version,
    }
}

pub async fn check_template_updates(app: AppHandle) -> Result<Vec<TemplateUpdate>, String> {
    let http = client()?;
    let templates: Vec<_> = crate::templates::read_templates(&app)
        .into_iter()
        .filter(|t| t.source_asset_id.is_some())
        .collect();
    let checks = futures_util::stream::iter(templates)
        .map(|t| {
            let http = http.clone();
            async move {
                let asset_id = t.source_asset_id.clone()?;
                let latest = fetch_detail(&http, &asset_id).await?;
                let installed = t.source_asset_version.clone().unwrap_or_default();
                is_newer(&installed, t.source_asset_revision, &latest).then(|| TemplateUpdate {
                    template_id: t.id.clone(),
                    asset_id,
                    installed_version: installed,
                    latest_version: latest.version_string.clone(),
                })
            }
        })
        .buffer_unordered(4)
        .collect::<Vec<_>>()
        .await;
    Ok(checks.into_iter().flatten().collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bbcode_flattens_to_text() {
        let text = bbcode_to_text(
            "[b]What is it?[/b]\nA [code]Camera2D[/code] helper.\n[url=https://x.dev/]Docs[/url]\n[img]a.png[/img][ul][*]One[*]Two[/ul]",
        );
        assert_eq!(
            text,
            "What is it?\nA Camera2D helper.\nDocs\n\n• One\n• Two"
        );
    }

    #[test]
    fn library_detail_maps_previews_and_license() {
        let raw = serde_json::json!({
            "asset_id": "1918", "type": "addon", "title": "Godot Jolt", "author": "mihe",
            "category": "Misc", "godot_version": "4.3", "rating": "0", "cost": "MIT",
            "description": "Line one\r\nLine two", "support_level": "community",
            "download_url": "https://example.com/a.zip", "browse_url": "https://github.com/x/y",
            "issues_url": "https://github.com/x/y/issues", "version": "19", "version_string": "0.15.0",
            "modify_date": "2025-03-10 13:11:50",
            "previews": [
                {"preview_id": "1", "type": "image", "link": "https://i/a.png", "thumbnail": "https://i/a_t.png"},
                {"preview_id": "2", "type": "video", "link": "https://youtu.be/x", "thumbnail": "https://i/v.png"}
            ]
        });
        let info = library_info(&raw).unwrap();
        assert_eq!(info.asset.asset_id, "1918");
        assert_eq!(info.version, "0.15.0");
        assert_eq!(info.revision, Some(19));
        assert_eq!(info.license, "MIT");
        assert_eq!(info.description, "Line one\nLine two");
        assert_eq!(
            info.issues_url.as_deref(),
            Some("https://github.com/x/y/issues")
        );
        assert_eq!(info.media.len(), 2);
        assert!(!info.media[0].video && info.media[1].video);
        assert!(!info.paid);
    }

    #[test]
    fn store_detail_maps_media_releases_and_price() {
        let raw = serde_json::json!({
            "name": "Phantom Camera", "slug": "phantom-camera",
            "publisher": {"name": "Ramokz", "slug": "ramokz"},
            "description": "A Camera addon.", "body_bbcode": "[b]Hello[/b] world",
            "license_type": "MIT", "license_url": "https://choosealicense.com/licenses/mit/",
            "media": ["https://m/1.webp", "https://m/2.webp"], "price_cent": "0",
            "source": "https://github.com/ramokz/phantom-camera", "last_updated": "2026-10-28T20:01:49",
            "store_url": "https://store.godotengine.org/asset/ramokz/phantom-camera/",
            "tags": [{"display_name": "3D", "featured": true, "slug": "3d"}], "type": 0,
            "video_playback_url": ""
        });
        let releases = serde_json::json!([
            {"version": "v0.11.0.4", "created": "2026-10-27", "changes_bbcode": "[ul][*]Fix[/ul]",
             "min_godot_version": "4.4.1", "max_godot_version": null, "stable": true, "size": 0.5,
             "download_url": "https://d/a.zip"}
        ]);
        let info = store_info(&raw, &releases).unwrap();
        assert_eq!(info.asset.asset_id, "store:ramokz/phantom-camera");
        assert_eq!(info.description, "Hello world");
        assert_eq!(info.version, "v0.11.0.4");
        assert_eq!(info.asset.godot_version, "4.4.1");
        assert_eq!(info.media.len(), 2);
        assert_eq!(info.releases[0].notes, "• Fix");
        assert_eq!(info.download_size_bytes, Some(524_288));
        assert!(!info.paid);

        let mut paid = raw.clone();
        paid["price_cent"] = serde_json::json!("999");
        assert!(store_info(&paid, &serde_json::json!([])).unwrap().paid);
    }

    #[test]
    fn zip_listing_adds_implied_folders() {
        let dir = std::env::temp_dir().join(format!("godothub-zip-list-{}", uuid::Uuid::new_v4()));
        fs::create_dir_all(&dir).unwrap();
        let path = dir.join("a.zip");
        {
            let mut zip = zip::ZipWriter::new(fs::File::create(&path).unwrap());
            let opts = zip::write::SimpleFileOptions::default();
            zip.start_file("addons/cam/plugin.cfg", opts).unwrap();
            zip.write_all(b"[plugin]").unwrap();
            zip.start_file("README.md", opts).unwrap();
            zip.write_all(b"hi").unwrap();
            zip.finish().unwrap();
        }
        let listing = list_zip(&path, 100).unwrap();
        let paths: Vec<_> = listing
            .entries
            .iter()
            .map(|e| (e.path.as_str(), e.is_dir))
            .collect();
        assert_eq!(
            paths,
            vec![
                ("README.md", false),
                ("addons", true),
                ("addons/cam", true),
                ("addons/cam/plugin.cfg", false)
            ]
        );
        assert!(!listing.truncated);
        assert!(list_zip(&path, 2).unwrap().truncated);
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn archive_cache_keeps_newest_files_within_caps() {
        let dir =
            std::env::temp_dir().join(format!("godothub-archive-cache-{}", uuid::Uuid::new_v4()));
        fs::create_dir_all(&dir).unwrap();
        for i in 0..5 {
            fs::write(dir.join(format!("{i}.zip")), vec![0u8; 10]).unwrap();
            std::thread::sleep(std::time::Duration::from_millis(20));
        }
        prune_archive_cache(&dir, 3, 1_000);
        assert_eq!(fs::read_dir(&dir).unwrap().count(), 3);
        assert!(dir.join("4.zip").exists() && !dir.join("0.zip").exists());
        prune_archive_cache(&dir, 10, 15);
        assert_eq!(fs::read_dir(&dir).unwrap().count(), 1);
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn cached_archives_expire() {
        let path = std::env::temp_dir().join(format!("godothub-fresh-{}.zip", uuid::Uuid::new_v4()));
        fs::write(&path, b"zip").unwrap();
        assert!(is_fresh(&path, std::time::Duration::from_secs(60)));
        std::thread::sleep(std::time::Duration::from_millis(20));
        assert!(!is_fresh(&path, std::time::Duration::from_millis(1)));
        assert!(!is_fresh(&path.with_extension("missing"), std::time::Duration::from_secs(60)));
        fs::remove_file(&path).unwrap();
    }

    #[test]
    fn template_update_compares_revisions_then_versions() {
        let latest: AssetDetail = serde_json::from_value(
            serde_json::json!({"asset_id": "1", "version": "5", "version_string": "1.2"}),
        )
        .unwrap();
        assert!(is_newer("1.1", Some(4), &latest));
        assert!(!is_newer("1.2", Some(5), &latest));
        assert!(is_newer("1.1", None, &latest));
        assert!(!is_newer("1.2", None, &latest));
    }
}
