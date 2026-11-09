use crate::asset_library::{fetch_detail, AssetDetail, ASSET_LIB_API};
use crate::persist::Versioned;
use crate::project_health::{setting, settings, strings};
use futures_util::{stream, StreamExt};
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use crate::AppHandle;

#[derive(Serialize, Deserialize, Default, Clone)]
struct AddonSource {
    asset_id: String,
    title: String,
    #[serde(default)]
    revision: Option<u64>,
    #[serde(default)]
    version: String,
}

#[derive(Serialize, Deserialize, Default)]
struct AddonSources {
    #[serde(default)]
    schema_version: u32,
    #[serde(default)]
    projects: HashMap<String, HashMap<String, AddonSource>>,
}

impl Versioned for AddonSources {
    const VERSION: u32 = 1;
}

#[derive(Serialize)]
pub struct ProjectAddon {
    pub folder: String,
    pub name: String,
    pub description: String,
    pub author: String,
    pub version: String,
    pub has_plugin: bool,
    pub enabled: bool,
    pub asset_id: Option<String>,
}

#[derive(Serialize)]
pub struct AddonUpdate {
    pub folder: String,
    pub asset_id: String,
    pub title: String,
    pub latest_version: String,
    pub update_available: bool,
    pub matched_by: String,
    pub browse_url: Option<String>,
}

fn sources_path(app: &AppHandle) -> Option<PathBuf> {
    app.path().app_data_dir().ok().map(|dir| dir.join("addon_sources.json"))
}

fn project_key(dir: &Path) -> String {
    fs::canonicalize(dir)
        .unwrap_or_else(|_| dir.to_path_buf())
        .to_string_lossy()
        .to_lowercase()
}

fn sources_for(app: &AppHandle, dir: &Path) -> HashMap<String, AddonSource> {
    let Some(path) = sources_path(app) else {
        return HashMap::new();
    };
    crate::persist::load_json::<AddonSources>(&path)
        .value
        .projects
        .remove(&project_key(dir))
        .unwrap_or_default()
}

pub(crate) fn record_install(
    app: &AppHandle,
    project_dir: &Path,
    asset_id: &str,
    detail: &AssetDetail,
    folders: &[String],
) {
    if folders.is_empty() {
        return;
    }
    let Some(path) = sources_path(app) else {
        return;
    };
    let key = project_key(project_dir);
    let _ = crate::persist::update_json::<AddonSources, _>(&path, |sources| {
        let entry = sources.projects.entry(key).or_default();
        for folder in folders {
            entry.insert(
                folder.clone(),
                AddonSource {
                    asset_id: asset_id.to_string(),
                    title: detail.title().to_string(),
                    revision: detail.revision(),
                    version: detail.version_string().to_string(),
                },
            );
        }
    });
}

fn project_dir(app: &AppHandle, id: &str) -> Result<(crate::models::Project, PathBuf), String> {
    let project = crate::projects::read_projects(app)
        .into_iter()
        .find(|p| p.id == id)
        .ok_or("Project is no longer registered")?;
    let dir = PathBuf::from(&project.path);
    if !dir.is_dir() {
        return Err("The project folder no longer exists".into());
    }
    Ok((project, dir))
}

fn first(fields: &[crate::project_health::Setting], key: &str) -> String {
    setting(fields, "plugin", key)
        .and_then(|v| strings(v).into_iter().next())
        .unwrap_or_default()
}

fn inventory(root: &Path, sources: &HashMap<String, AddonSource>) -> Vec<ProjectAddon> {
    let project_text = fs::read_to_string(root.join("project.godot")).unwrap_or_default();
    let enabled: HashSet<String> = setting(&settings(&project_text), "editor_plugins", "enabled")
        .map(strings)
        .unwrap_or_default()
        .into_iter()
        .collect();
    let Ok(entries) = fs::read_dir(root.join("addons")) else {
        return vec![];
    };
    let mut addons: Vec<ProjectAddon> = entries
        .flatten()
        .filter(|e| e.file_type().is_ok_and(|t| t.is_dir() && !t.is_symlink()))
        .filter(|e| !e.file_name().to_string_lossy().starts_with('.'))
        .take(500)
        .map(|entry| {
            let folder = entry.file_name().to_string_lossy().to_string();
            let cfg = entry.path().join("plugin.cfg");
            let fields = fs::read_to_string(&cfg).map(|t| settings(&t)).unwrap_or_default();
            let name = first(&fields, "name");
            ProjectAddon {
                name: if name.is_empty() { folder.clone() } else { name },
                description: first(&fields, "description"),
                author: first(&fields, "author"),
                version: first(&fields, "version"),
                has_plugin: cfg.is_file(),
                enabled: enabled.contains(&format!("res://addons/{folder}/plugin.cfg")),
                asset_id: sources.get(&folder).map(|s| s.asset_id.clone()),
                folder,
            }
        })
        .collect();
    addons.sort_by_key(|a| a.name.to_lowercase());
    addons
}

pub async fn list_project_addons(app: AppHandle, id: String) -> Result<Vec<ProjectAddon>, String> {
    tokio::task::spawn_blocking(move || {
        let (_, dir) = project_dir(&app, &id)?;
        Ok(inventory(&dir, &sources_for(&app, &dir)))
    })
    .await
    .map_err(|e| e.to_string())?
}

fn version_parts(value: &str) -> Option<Vec<u64>> {
    let digits: Vec<u64> = value
        .trim()
        .trim_start_matches(['v', 'V'])
        .split(|c: char| !c.is_ascii_digit())
        .take_while(|part| !part.is_empty())
        .map(|part| part.parse().ok())
        .collect::<Option<_>>()?;
    (!digits.is_empty()).then_some(digits)
}

fn is_newer(latest: &str, current: &str) -> Option<bool> {
    let (mut a, mut b) = (version_parts(latest)?, version_parts(current)?);
    let len = a.len().max(b.len());
    a.resize(len, 0);
    b.resize(len, 0);
    Some(a > b)
}

fn normalize(name: &str) -> String {
    name.chars()
        .filter(|c| c.is_alphanumeric())
        .flat_map(char::to_lowercase)
        .collect()
}

#[derive(Deserialize)]
struct SearchItem {
    #[serde(rename = "asset_id")]
    asset_id: String,
    #[serde(default)]
    title: String,
}

#[derive(Deserialize)]
struct SearchResponse {
    #[serde(default)]
    result: Vec<SearchItem>,
}

async fn find_by_name(http: &reqwest::Client, name: &str, godot: Option<&str>) -> Option<String> {
    let mut params = vec![("filter", name), ("type", "addon"), ("max_results", "10")];
    if let Some(version) = godot {
        params.push(("godot_version", version));
    }
    let url = url::Url::parse_with_params(&format!("{ASSET_LIB_API}/asset"), &params).ok()?;
    let response: SearchResponse = http.get(url).send().await.ok()?.json().await.ok()?;
    let wanted = normalize(name);
    response
        .result
        .into_iter()
        .find(|item| normalize(&item.title) == wanted)
        .map(|item| item.asset_id)
}

pub async fn check_addon_updates(app: AppHandle, id: String) -> Result<Vec<AddonUpdate>, String> {
    let lookup = app.clone();
    let (project, dir) = tokio::task::spawn_blocking(move || project_dir(&lookup, &id))
        .await
        .map_err(|e| e.to_string())??;
    let sources = sources_for(&app, &dir);
    let addons = inventory(&dir, &sources);
    let godot = crate::project_health::version(&project.godot_version).map(|(a, b)| format!("{a}.{b}"));
    let http = crate::http::client()?;
    let updates = stream::iter(addons)
        .map(|addon| {
            let http = http.clone();
            let source = sources.get(&addon.folder).cloned();
            let godot = godot.clone();
            async move {
                let (asset_id, matched_by) = match &source {
                    Some(s) => (s.asset_id.clone(), "install"),
                    None => (find_by_name(&http, &addon.name, godot.as_deref()).await?, "name"),
                };
                let detail = fetch_detail(&http, &asset_id).await?;
                let latest = detail.version_string().to_string();
                let update_available = match &source {
                    Some(s) => match (detail.revision(), s.revision) {
                        (Some(remote), Some(local)) => remote > local,
                        _ => !latest.is_empty() && latest != s.version,
                    },
                    None => is_newer(&latest, &addon.version).unwrap_or(false),
                };
                Some(AddonUpdate {
                    folder: addon.folder,
                    asset_id,
                    title: detail.title().to_string(),
                    latest_version: latest,
                    update_available,
                    matched_by: matched_by.into(),
                    browse_url: detail.browse_url().map(str::to_string),
                })
            }
        })
        .buffer_unordered(4)
        .filter_map(|update| async move { update })
        .collect::<Vec<_>>()
        .await;
    Ok(updates)
}

fn restore(backup: &Path, target: &Path) {
    if target.exists() {
        let _ = crate::templates::remove_dir_force(target);
    }
    let _ = fs::rename(backup, target);
}

pub async fn update_project_addon(
    app: AppHandle,
    id: String,
    folder: String,
    asset_id: String,
) -> Result<(), String> {
    if folder.is_empty() || folder.contains(['/', '\\']) || folder.starts_with('.') {
        return Err("Invalid addon folder".into());
    }
    let (project, dir) = project_dir(&app, &id)?;
    if crate::projects::tracked_pid(&app, &project.id).is_some() {
        return Err("Close the project in Godot before updating its addons".into());
    }
    let target = dir.join("addons").join(&folder);
    if !target.is_dir() {
        return Err("This addon folder no longer exists".into());
    }
    let backup = dir.join("addons").join(format!(".{folder}.godothub-update"));
    if backup.exists() {
        crate::templates::remove_dir_force(&backup).map_err(|e| e.to_string())?;
    }
    fs::rename(&target, &backup).map_err(|e| format!("Could not move the old addon aside: {e}"))?;
    let installed = crate::asset_library::install_asset(app.clone(), asset_id, Some(id), None).await;
    match installed {
        Ok(result) if result.addon_folders.contains(&folder) && target.is_dir() => {
            if trash::delete(&backup).is_err() {
                let _ = crate::templates::remove_dir_force(&backup);
            }
            Ok(())
        }
        Ok(_) => {
            restore(&backup, &target);
            Err(format!("The new download does not contain addons/{folder}, so the old version was kept"))
        }
        Err(error) => {
            restore(&backup, &target);
            Err(error)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compares_semantic_versions() {
        assert_eq!(is_newer("1.10.0", "1.9.2"), Some(true));
        assert_eq!(is_newer("v2.0", "2.0.0"), Some(false));
        assert_eq!(is_newer("1.0.0", "1.0.1"), Some(false));
        assert_eq!(is_newer("beta", "1.0"), None);
    }

    #[test]
    fn names_match_ignoring_case_and_punctuation() {
        assert_eq!(normalize("Dialogue Manager"), normalize("dialogue_manager"));
        assert_ne!(normalize("Dialogue Manager 3"), normalize("Dialogue Manager"));
    }

    #[test]
    fn inventory_reads_plugin_cfg_and_enabled_state() {
        let root = std::env::temp_dir().join(format!("godothub-addons-{}", std::process::id()));
        let _ = fs::remove_dir_all(&root);
        fs::create_dir_all(root.join("addons/cool_tool")).unwrap();
        fs::create_dir_all(root.join("addons/library")).unwrap();
        fs::write(
            root.join("addons/cool_tool/plugin.cfg"),
            "[plugin]\n\nname=\"Cool Tool\"\nauthor=\"Ann\"\nversion=\"1.2.0\"\nscript=\"plugin.gd\"\n",
        )
        .unwrap();
        fs::write(
            root.join("project.godot"),
            "[editor_plugins]\n\nenabled=PackedStringArray(\"res://addons/cool_tool/plugin.cfg\")\n",
        )
        .unwrap();
        let addons = inventory(&root, &HashMap::new());
        assert_eq!(addons.len(), 2);
        let cool = addons.iter().find(|a| a.folder == "cool_tool").unwrap();
        assert_eq!(cool.name, "Cool Tool");
        assert_eq!(cool.version, "1.2.0");
        assert!(cool.enabled && cool.has_plugin);
        let library = addons.iter().find(|a| a.folder == "library").unwrap();
        assert!(!library.has_plugin && !library.enabled);
        let _ = fs::remove_dir_all(&root);
    }
}
