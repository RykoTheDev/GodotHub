use crate::models::InstalledGodotVersion;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use tauri::AppHandle;

#[derive(Serialize, Clone)]
pub struct StorageVersion {
    pub tag: String,
    pub name: String,
    pub path: String,
    pub size_bytes: u64,
    pub managed_by: Option<String>,
    pub external: bool,
    pub projects: Vec<String>,
    pub templates: Vec<String>,
    pub is_current: bool,
    pub aliases: Vec<String>,
    pub unused: bool,
}

#[derive(Serialize, Clone)]
pub struct StoragePartial {
    pub kind: String,
    pub name: String,
    pub path: String,
    pub size_bytes: u64,
}

#[derive(Serialize, Clone)]
pub struct StorageTemplate {
    pub id: String,
    pub name: String,
    pub workspace: String,
    pub path: String,
    pub size_bytes: u64,
}

#[derive(Serialize, Clone)]
pub struct StorageExportTemplates {
    pub tag: Option<String>,
    pub folder: String,
    pub root: String,
    pub path: String,
    pub size_bytes: u64,
    pub orphan: bool,
}

#[derive(Serialize, Clone)]
pub struct StorageReport {
    pub versions: Vec<StorageVersion>,
    pub partials: Vec<StoragePartial>,
    pub templates: Vec<StorageTemplate>,
    pub export_templates: Vec<StorageExportTemplates>,
    pub export_templates_error: Option<String>,
}

#[derive(Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum ReclaimItem {
    Version { tag: String },
    Partial { path: String },
    ExportTemplates { folder: String, root: String },
}

#[derive(Serialize)]
pub struct ReclaimFailure {
    pub label: String,
    pub error: String,
}

#[derive(Serialize)]
pub struct ReclaimResult {
    pub freed_bytes: u64,
    pub removed: usize,
    pub failed: Vec<ReclaimFailure>,
}

fn dir_size(root: &Path) -> u64 {
    let Ok(meta) = fs::symlink_metadata(root) else {
        return 0;
    };
    if meta.is_file() {
        return meta.len();
    }
    if !meta.is_dir() {
        return 0;
    }
    let mut total = 0u64;
    let mut stack = vec![root.to_path_buf()];
    while let Some(dir) = stack.pop() {
        let Ok(entries) = fs::read_dir(&dir) else {
            continue;
        };
        for entry in entries.flatten() {
            let Ok(meta) = entry.metadata() else {
                continue;
            };
            if meta.file_type().is_symlink() {
                continue;
            }
            if meta.is_dir() {
                stack.push(entry.path());
            } else if meta.is_file() {
                total += meta.len();
            }
        }
    }
    total
}

fn canonical(path: &Path) -> PathBuf {
    path.canonicalize().unwrap_or_else(|_| path.to_path_buf())
}

fn version_location(version: &InstalledGodotVersion, versions_dir: &Path) -> (PathBuf, bool) {
    if let Some(root) = &version.install_root {
        let root = PathBuf::from(root);
        let external = !canonical(&root).starts_with(canonical(versions_dir));
        return (root, external);
    }
    let exe = PathBuf::from(&version.executable_path);
    if let Ok(rest) = exe.strip_prefix(versions_dir) {
        if let Some(first) = rest.components().next() {
            return (versions_dir.join(first), false);
        }
    }
    if let Some(bundle) = exe
        .ancestors()
        .find(|p| p.extension().map(|e| e == "app").unwrap_or(false))
    {
        return (bundle.to_path_buf(), true);
    }
    (exe, true)
}

fn version_size(path: &Path) -> u64 {
    if path.is_dir() {
        return dir_size(path);
    }
    let mut total = dir_size(path);
    if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
        let ext = path
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| format!(".{e}"))
            .unwrap_or_default();
        let console = path.with_file_name(format!("{stem}_console{ext}"));
        if console != path {
            total += dir_size(&console);
        }
    }
    total
}

fn owns_folder(version: &InstalledGodotVersion, folder: &Path) -> bool {
    let folder = canonical(folder);
    if let Some(root) = &version.install_root {
        let root = canonical(Path::new(root));
        if root == folder || root.starts_with(&folder) {
            return true;
        }
    }
    canonical(Path::new(&version.executable_path)).starts_with(&folder)
}

fn has_godot_archive(folder: &Path) -> bool {
    let Ok(entries) = fs::read_dir(folder) else {
        return false;
    };
    entries.flatten().any(|entry| {
        let name = entry.file_name().to_string_lossy().to_lowercase();
        entry.path().is_file() && name.starts_with("godot_v") && name.ends_with(".zip")
    })
}

fn version_partials(app: &AppHandle, registry: &[InstalledGodotVersion]) -> Vec<StoragePartial> {
    let mut partials = Vec::new();
    let root = crate::godot_versions::versions_dir(app);
    let Ok(entries) = fs::read_dir(&root) else {
        return partials;
    };
    let active = crate::godot_versions::active_download_keys();
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        let name = entry.file_name().to_string_lossy().to_string();
        if active.contains(&name) {
            continue;
        }
        if registry.iter().any(|v| owns_folder(v, &path)) {
            continue;
        }
        if !has_godot_archive(&path) {
            continue;
        }
        partials.push(StoragePartial {
            kind: "version_download".into(),
            name,
            size_bytes: dir_size(&path),
            path: path.to_string_lossy().to_string(),
        });
    }
    partials
}

fn export_template_partials(app: &AppHandle) -> Vec<StoragePartial> {
    let mut partials = Vec::new();
    if crate::export_templates::has_active_downloads() {
        return partials;
    }
    let Some(root) = crate::export_templates::existing_downloads_dir(app) else {
        return partials;
    };
    let Ok(entries) = fs::read_dir(&root) else {
        return partials;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        partials.push(StoragePartial {
            kind: "export_templates_download".into(),
            name: entry.file_name().to_string_lossy().to_string(),
            size_bytes: dir_size(&path),
            path: path.to_string_lossy().to_string(),
        });
    }
    partials
}

struct Usage {
    projects: HashMap<String, Vec<String>>,
    templates: HashMap<String, Vec<String>>,
    template_sizes: Vec<StorageTemplate>,
}

fn collect_usage(app: &AppHandle) -> Usage {
    let state = crate::workspace::read_state(app);
    let multiple = state.workspaces.len() > 1;
    let mut usage = Usage {
        projects: HashMap::new(),
        templates: HashMap::new(),
        template_sizes: Vec::new(),
    };
    for workspace in &state.workspaces {
        let dir = crate::workspace::workspace_dir(app, &workspace.id);
        let label = |name: &str| {
            if multiple {
                format!("{name} ({})", workspace.name)
            } else {
                name.to_string()
            }
        };
        for project in crate::projects::read_projects_from(&dir) {
            usage
                .projects
                .entry(project.godot_version.clone())
                .or_default()
                .push(label(&project.name));
        }
        let Ok(entries) = fs::read_dir(dir.join("templates")) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if !path.is_dir() {
                continue;
            }
            let Some(template) = crate::templates::read_template_json(&path) else {
                continue;
            };
            if !template.godot_version.is_empty() {
                usage
                    .templates
                    .entry(template.godot_version.clone())
                    .or_default()
                    .push(label(&template.name));
            }
            usage.template_sizes.push(StorageTemplate {
                id: template.id.clone(),
                name: template.name.clone(),
                workspace: workspace.name.clone(),
                size_bytes: dir_size(&path),
                path: path.to_string_lossy().to_string(),
            });
        }
    }
    usage
}

fn build_report(app: &AppHandle) -> StorageReport {
    let registry = crate::godot_versions::read_registry(app);
    let versions_dir = crate::godot_versions::versions_dir(app);
    let mut usage = collect_usage(app);
    let current = crate::current_version::read_current_tag(app);
    let mut aliases: HashMap<String, Vec<String>> = HashMap::new();
    for alias in crate::current_version::list_named_aliases(app).aliases {
        aliases.entry(alias.tag).or_default().push(alias.name);
    }

    let mut versions: Vec<StorageVersion> = registry
        .iter()
        .map(|v| {
            let mise = matches!(
                v.managed_by.as_deref(),
                Some(crate::mise::MANAGED_BY) | Some(crate::godot_versions::CUSTOM_BUILD)
            );
            let (path, external) = version_location(v, &versions_dir);
            let size_bytes = if mise { 0 } else { version_size(&path) };
            let projects = usage.projects.remove(&v.tag).unwrap_or_default();
            let templates = usage.templates.remove(&v.tag).unwrap_or_default();
            let is_current = current.as_deref() == Some(v.tag.as_str());
            let alias_names = aliases.remove(&v.tag).unwrap_or_default();
            let unused = !mise
                && projects.is_empty()
                && templates.is_empty()
                && !is_current
                && alias_names.is_empty();
            StorageVersion {
                tag: v.tag.clone(),
                name: v.custom_name.clone().unwrap_or_else(|| v.tag.clone()),
                path: path.to_string_lossy().to_string(),
                size_bytes,
                managed_by: v.managed_by.clone(),
                external,
                projects,
                templates,
                is_current,
                aliases: alias_names,
                unused,
            }
        })
        .collect();
    versions.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));

    let mut partials = version_partials(app, &registry);
    partials.extend(export_template_partials(app));
    partials.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));

    let mut templates = usage.template_sizes;
    templates.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));

    let (export_templates, export_templates_error) =
        match crate::export_templates::build_state(app) {
            Ok(state) => {
                let mut list: Vec<StorageExportTemplates> = state
                    .versions
                    .into_iter()
                    .filter(|v| v.size_bytes > 0)
                    .map(|v| StorageExportTemplates {
                        tag: Some(v.tag),
                        folder: v.folder,
                        root: v.root,
                        path: v.templates_dir,
                        size_bytes: v.size_bytes,
                        orphan: false,
                    })
                    .collect();
                list.extend(state.orphans.into_iter().map(|o| StorageExportTemplates {
                    tag: None,
                    folder: o.folder,
                    root: o.root,
                    path: o.path,
                    size_bytes: o.size_bytes,
                    orphan: true,
                }));
                list.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
                (list, None)
            }
            Err(e) => (Vec::new(), Some(e)),
        };

    StorageReport {
        versions,
        partials,
        templates,
        export_templates,
        export_templates_error,
    }
}

#[tauri::command]
pub async fn get_storage_report(app: AppHandle) -> Result<StorageReport, String> {
    tokio::task::spawn_blocking(move || build_report(&app))
        .await
        .map_err(|e| e.to_string())
}

fn remove_path(path: &Path) -> Result<(), String> {
    if path.is_dir() {
        fs::remove_dir_all(path).map_err(|e| e.to_string())
    } else {
        fs::remove_file(path).map_err(|e| e.to_string())
    }
}

#[tauri::command]
pub async fn reclaim_storage(
    app: AppHandle,
    items: Vec<ReclaimItem>,
) -> Result<ReclaimResult, String> {
    let scan_app = app.clone();
    let report = tokio::task::spawn_blocking(move || build_report(&scan_app))
        .await
        .map_err(|e| e.to_string())?;

    let mut result = ReclaimResult {
        freed_bytes: 0,
        removed: 0,
        failed: Vec::new(),
    };
    let mut seen: HashSet<String> = HashSet::new();

    for item in items {
        match item {
            ReclaimItem::Version { tag } => {
                if !seen.insert(format!("version:{tag}")) {
                    continue;
                }
                let Some(version) = report.versions.iter().find(|v| v.tag == tag && v.unused)
                else {
                    result.failed.push(ReclaimFailure {
                        label: tag,
                        error: "This version is in use or no longer installed".into(),
                    });
                    continue;
                };
                let size = version.size_bytes;
                let delete_app = app.clone();
                let delete_tag = tag.clone();
                let outcome = tokio::task::spawn_blocking(move || {
                    crate::godot_versions::delete_godot_version(delete_app, delete_tag)
                })
                .await
                .map_err(|e| e.to_string())
                .and_then(|r| r);
                match outcome {
                    Ok(()) => {
                        result.freed_bytes += size;
                        result.removed += 1;
                    }
                    Err(error) => result.failed.push(ReclaimFailure { label: tag, error }),
                }
            }
            ReclaimItem::Partial { path } => {
                if !seen.insert(format!("partial:{path}")) {
                    continue;
                }
                let Some(partial) = report.partials.iter().find(|p| p.path == path) else {
                    result.failed.push(ReclaimFailure {
                        label: path,
                        error: "This download is no longer an orphaned partial".into(),
                    });
                    continue;
                };
                let size = partial.size_bytes;
                let target = PathBuf::from(&path);
                let outcome = tokio::task::spawn_blocking(move || remove_path(&target))
                    .await
                    .map_err(|e| e.to_string())
                    .and_then(|r| r);
                match outcome {
                    Ok(()) => {
                        result.freed_bytes += size;
                        result.removed += 1;
                    }
                    Err(error) => result.failed.push(ReclaimFailure { label: path, error }),
                }
            }
            ReclaimItem::ExportTemplates { folder, root } => {
                if !seen.insert(format!("export:{root}:{folder}")) {
                    continue;
                }
                let Some(entry) = report
                    .export_templates
                    .iter()
                    .find(|e| e.orphan && e.folder == folder && e.root == root)
                else {
                    result.failed.push(ReclaimFailure {
                        label: folder,
                        error: "These export templates are no longer orphaned".into(),
                    });
                    continue;
                };
                let size = entry.size_bytes;
                match crate::export_templates::delete_export_templates(
                    app.clone(),
                    folder.clone(),
                    Some(root),
                )
                .await
                {
                    Ok(()) => {
                        result.freed_bytes += size;
                        result.removed += 1;
                    }
                    Err(error) => result.failed.push(ReclaimFailure { label: folder, error }),
                }
            }
        }
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!(
            "godothub-storage-{name}-{}",
            std::process::id()
        ));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn version(exe: &Path, root: Option<&Path>) -> InstalledGodotVersion {
        InstalledGodotVersion {
            tag: "4.3-stable".into(),
            version: "4.3".into(),
            executable_path: exe.to_string_lossy().to_string(),
            is_mono: false,
            installed_at: String::new(),
            custom_name: None,
            install_root: root.map(|r| r.to_string_lossy().to_string()),
            supports_console: false,
            managed_by: None,
        }
    }

    #[test]
    fn dir_size_sums_nested_files() {
        let dir = temp_dir("size");
        fs::create_dir_all(dir.join("a/b")).unwrap();
        fs::write(dir.join("one.bin"), vec![0u8; 10]).unwrap();
        fs::write(dir.join("a/b/two.bin"), vec![0u8; 32]).unwrap();
        assert_eq!(dir_size(&dir), 42);
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn partial_needs_godot_archive_and_no_owner() {
        let dir = temp_dir("partial");
        let owned = dir.join("4.3-stable");
        let stray = dir.join("4.4-stable");
        let unrelated = dir.join("my-stuff");
        for d in [&owned, &stray, &unrelated] {
            fs::create_dir_all(d).unwrap();
        }
        fs::write(stray.join("Godot_v4.4-stable_win64.exe.zip"), b"zip").unwrap();
        fs::write(unrelated.join("notes.zip"), b"zip").unwrap();
        let exe = owned.join("Godot.exe");
        fs::write(&exe, b"exe").unwrap();
        let registered = version(&exe, Some(&owned));

        assert!(owns_folder(&registered, &owned));
        assert!(!owns_folder(&registered, &stray));
        assert!(has_godot_archive(&stray));
        assert!(!has_godot_archive(&unrelated));
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn version_location_uses_managed_top_folder() {
        let dir = temp_dir("location");
        let exe = dir.join("4.3-stable").join("bin").join("Godot.exe");
        let (path, external) = version_location(&version(&exe, None), &dir);
        assert_eq!(path, dir.join("4.3-stable"));
        assert!(!external);
        let _ = fs::remove_dir_all(&dir);
    }
}
