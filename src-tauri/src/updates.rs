use crate::models::UpdateEntry;
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

const SANITY_PROJECT_ID: &str = "d6yq9zza";
const SANITY_DATASET: &str = "production";
const SANITY_READ_TOKEN: &str = "sk3H9kcraejNN0ZZeEgXrvnqr3PtYcxSPZnN0xC2b2jtTRhI2oeGXyAbPPDN2bcqUoaFwl0cpOrEuswn5S5Yk24A1QSAmSdKp8uIff2ygEoRJ4CNZgvFynX8nzHFAYHfkIDZk0kJExgPybC7pu6L2rmOYvviRB2Vwpy78MhE6wSapG4DZ9Vi";
const GROQ_QUERY: &str = r#"*[_type == "update"] | order(featured desc, _createdAt desc) { _id, _createdAt, kind, title, body, command, isNew, featured, link }"#;

const EMBEDDED_UPDATES: &str = include_str!("../updates.json");

fn read_embedded_entries() -> Vec<UpdateEntry> {
    serde_json::from_str(EMBEDDED_UPDATES).unwrap_or_default()
}


fn cache_file(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    base.join("updates-cache.json")
}

#[derive(serde::Serialize, serde::Deserialize)]
struct UpdatesCache {
    fetched_at: i64,
    entries: Vec<UpdateEntry>,
}

fn read_cache(app: &AppHandle) -> Option<(i64, Vec<UpdateEntry>)> {
    let raw = fs::read_to_string(cache_file(app)).ok()?;
    let cache: UpdatesCache = serde_json::from_str(&raw).ok()?;
    Some((cache.fetched_at, cache.entries))
}

fn write_cache(app: &AppHandle, entries: &[UpdateEntry]) {
    let cache = UpdatesCache {
        fetched_at: chrono::Utc::now().timestamp(),
        entries: entries.to_vec(),
    };
    if let Ok(json) = serde_json::to_string_pretty(&cache) {
        let _ = fs::write(cache_file(app), json);
    }
}


#[derive(serde::Deserialize)]
struct SanityUpdate {
    #[serde(rename = "_id")]
    id: String,
    #[serde(rename = "_createdAt", default)]
    created_at_raw: String,
    #[serde(default)]
    kind: String,
    #[serde(default)]
    title: String,
    #[serde(default)]
    body: String,
    #[serde(default)]
    command: Option<String>,
    #[serde(rename = "isNew", default)]
    is_new: bool,
    #[serde(default)]
    featured: bool,
    #[serde(default)]
    link: Option<String>,
}

#[derive(serde::Deserialize)]
struct SanityResponse {
    result: Vec<SanityUpdate>,
}

fn to_entry(raw: SanityUpdate) -> UpdateEntry {
    let created_at = chrono::DateTime::parse_from_rfc3339(&raw.created_at_raw)
        .map(|d| d.timestamp())
        .unwrap_or(0);
    UpdateEntry {
        id: raw.id,
        kind: raw.kind,
        title: raw.title,
        body: raw.body,
        command: raw.command.filter(|c| !c.trim().is_empty()),
        is_new: raw.is_new,
        featured: raw.featured,
        link: raw.link.filter(|l| !l.trim().is_empty()),
        created_at,
    }
}

#[derive(serde::Serialize)]
pub struct UpdatesResponse {
    pub entries: Vec<UpdateEntry>,
    pub from_cache: bool,
    pub fetched_at: i64,
}

async fn fetch_live() -> Result<Vec<UpdateEntry>, String> {
    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())?;
    let query = url::form_urlencoded::Serializer::new(String::new())
        .append_pair("query", GROQ_QUERY)
        .finish();
    let url = format!(
        "https://{}.apicdn.sanity.io/v2024-01-01/data/query/{}?{}",
        SANITY_PROJECT_ID, SANITY_DATASET, query
    );
    let resp = client
        .get(&url)
        .header("Authorization", format!("Bearer {}", SANITY_READ_TOKEN))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("Sanity feed returned HTTP {}", resp.status()));
    }
    let body: SanityResponse = resp.json().await.map_err(|e| e.to_string())?;
    Ok(body.result.into_iter().map(to_entry).collect())
}

#[tauri::command]
pub async fn fetch_updates(app: AppHandle) -> Result<UpdatesResponse, String> {
    match fetch_live().await {
        Ok(entries) => {
            write_cache(&app, &entries);
            Ok(UpdatesResponse {
                entries,
                from_cache: false,
                fetched_at: 0,
            })
        }
        Err(_) => match read_cache(&app) {
            Some((fetched_at, entries)) if !entries.is_empty() => Ok(UpdatesResponse {
                entries,
                from_cache: true,
                fetched_at,
            }),
            _ => Ok(UpdatesResponse {
                entries: read_embedded_entries(),
                from_cache: true,
                fetched_at: 0,
            }),
        },
    }
}
