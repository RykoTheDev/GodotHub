use crate::models::NewsItem;
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

const FEED_URL: &str = "https://godotengine.org/rss.xml";

fn cache_file(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    if !base.exists() {
        let _ = fs::create_dir_all(&base);
    }
    base.join("news-cache.json")
}

#[derive(serde::Serialize, serde::Deserialize)]
struct NewsCache {
    fetched_at: i64,
    items: Vec<NewsItem>,
}

fn read_cache(app: &AppHandle) -> Option<Vec<NewsItem>> {
    let raw = fs::read_to_string(cache_file(app)).ok()?;
    let cache: NewsCache = serde_json::from_str(&raw).ok()?;
    Some(cache.items)
}

fn write_cache(app: &AppHandle, items: &[NewsItem]) {
    let cache = NewsCache {
        fetched_at: chrono::Utc::now().timestamp(),
        items: items.to_vec(),
    };
    if let Ok(json) = serde_json::to_string_pretty(&cache) {
        let _ = fs::write(cache_file(app), json);
    }
}

fn strip_html(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let mut in_tag = false;
    for c in input.chars() {
        match c {
            '<' => in_tag = true,
            '>' => in_tag = false,
            _ if !in_tag => out.push(c),
            _ => {}
        }
    }
    let decoded = out
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&nbsp;", " ");
    decoded.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn extract_item_images(xml: &[u8]) -> Result<Vec<Option<String>>, String> {
    use quick_xml::events::Event;
    use quick_xml::Reader;

    let mut reader = Reader::from_reader(xml);
    reader.config_mut().trim_text(true);
    let mut images = Vec::new();
    let mut in_item = false;
    let mut in_image = false;
    let mut current: Option<String> = None;
    let mut buf = Vec::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let name = e.name();
                if name.as_ref() == b"item" {
                    in_item = true;
                    current = None;
                } else if in_item && name.as_ref() == b"image" {
                    in_image = true;
                }
            }
            Ok(Event::Text(t)) if in_image => {
                if let Ok(text) = t.xml10_content() {
                    let text = text.trim().to_string();
                    if !text.is_empty() && current.is_none() {
                        current = Some(text);
                    }
                }
            }
            Ok(Event::End(e)) => {
                let name = e.name();
                if name.as_ref() == b"item" {
                    images.push(current.take());
                    in_item = false;
                } else if in_item && name.as_ref() == b"image" {
                    in_image = false;
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("Failed to parse feed XML: {e}")),
            _ => {}
        }
        buf.clear();
    }
    Ok(images)
}

#[derive(serde::Serialize)]
pub struct NewsResponse {
    pub items: Vec<NewsItem>,
    pub from_cache: bool,
}

#[tauri::command]
pub async fn fetch_godot_news(app: AppHandle) -> Result<NewsResponse, String> {
    match fetch_live().await {
        Ok(items) => {
            write_cache(&app, &items);
            Ok(NewsResponse {
                items,
                from_cache: false,
            })
        }
        Err(err) => match read_cache(&app) {
            Some(items) if !items.is_empty() => Ok(NewsResponse {
                items,
                from_cache: true,
            }),
            _ => Err(err),
        },
    }
}

async fn fetch_live() -> Result<Vec<NewsItem>, String> {
    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())?;
    let resp = client
        .get(FEED_URL)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("Godot news feed returned HTTP {}", resp.status()));
    }
    let bytes = resp.bytes().await.map_err(|e| e.to_string())?;
    let feed = feed_rs::parser::parse(&bytes[..]).map_err(|e| e.to_string())?;
    let images = extract_item_images(&bytes)?;

    let items = feed
        .entries
        .into_iter()
        .zip(images)
        .filter_map(|(entry, image)| {
            let title = entry.title.map(|t| t.content)?;
            let link = entry.links.first().map(|l| l.href.clone())?;
            let published = entry.published.or(entry.updated).map(|dt| dt.to_rfc3339());
            let summary = entry.summary.map(|s| strip_html(&s.content));
            let author = entry.authors.first().map(|a| a.name.clone());
            let category = entry.categories.first().map(|c| c.term.clone());
            let id = if entry.id.trim().is_empty() {
                link.clone()
            } else {
                entry.id.clone()
            };
            Some(NewsItem {
                id,
                title,
                link,
                published,
                summary,
                author,
                category,
                image,
            })
        })
        .collect();

    Ok(items)
}
