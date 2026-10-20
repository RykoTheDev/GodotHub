use crate::models::{InstalledGodotVersion, Project};
use serde::Serialize;
use std::collections::{BTreeMap, HashSet};
use std::fs;
use std::io::{Read, Write};
use std::path::{Component, Path, PathBuf};
use std::process::{Output, Stdio};
use std::time::{Duration, Instant, SystemTime};
use tauri::AppHandle;

const LARGE_BINARY: u64 = 50 * 1024 * 1024;
const LARGE_CACHE: u64 = 1024 * 1024 * 1024;
const SCAN_LIMIT: usize = 50_000;
const CONFIG_LIMIT: u64 = 8 * 1024 * 1024;

#[derive(Clone, Serialize)]
pub struct HealthAction {
    pub kind: String,
    pub target: Option<String>,
    pub confirm: bool,
}

#[derive(Serialize)]
pub struct HealthCheck {
    pub id: String,
    pub category: String,
    pub severity: String,
    pub code: String,
    pub details: Vec<String>,
    pub values: BTreeMap<String, String>,
    pub action: Option<HealthAction>,
}

#[derive(Serialize)]
pub struct HealthReport {
    pub project_id: String,
    pub scanned_at_ms: u64,
    pub checks: Vec<HealthCheck>,
}

fn check(category: &str, severity: &str, code: &str) -> HealthCheck {
    HealthCheck {
        id: code.into(),
        category: category.into(),
        severity: severity.into(),
        code: code.into(),
        details: vec![],
        values: BTreeMap::new(),
        action: None,
    }
}
impl HealthCheck {
    fn detail(mut self, value: impl Into<String>) -> Self {
        self.details.push(value.into());
        self
    }
    fn value(mut self, key: &str, value: impl ToString) -> Self {
        self.values.insert(key.into(), value.to_string());
        self
    }
    fn action(mut self, kind: &str, target: Option<String>, confirm: bool) -> Self {
        self.action = Some(HealthAction {
            kind: kind.into(),
            target,
            confirm,
        });
        self
    }
    fn named(mut self, id: &str) -> Self {
        self.id = format!("{}:{id}", self.code);
        self
    }
}

#[derive(Debug)]
pub(crate) struct Setting {
    pub(crate) section: String,
    pub(crate) key: String,
    pub(crate) value: String,
    start: usize,
    end: usize,
}

pub(crate) fn settings(text: &str) -> Vec<Setting> {
    let mut result = vec![];
    let mut section = String::new();
    let mut offset = 0;
    let mut pending: Option<Setting> = None;
    let mut depth = 0i32;
    let mut quoted = false;
    let mut escaped = false;
    for line in text.split_inclusive('\n') {
        let trimmed = line.trim().trim_start_matches('\u{feff}');
        if pending.is_none() {
            if trimmed.starts_with('[') && trimmed.contains(']') {
                section = trimmed[1..trimmed.find(']').unwrap()].to_string();
                offset += line.len();
                continue;
            }
            if trimmed.starts_with(';') || trimmed.starts_with('#') || !trimmed.contains('=') {
                offset += line.len();
                continue;
            }
            let (key, _) = trimmed.split_once('=').unwrap();
            pending = Some(Setting {
                section: section.clone(),
                key: key.trim().into(),
                value: String::new(),
                start: offset,
                end: offset,
            });
            depth = 0;
            quoted = false;
            escaped = false;
        }
        let segment = if pending.as_ref().unwrap().start == offset {
            line.split_once('=').unwrap().1
        } else {
            line
        };
        let field = pending.as_mut().unwrap();
        for c in segment.chars() {
            if !quoted && (c == ';' || c == '#') {
                break;
            }
            field.value.push(c);
            if escaped {
                escaped = false;
                continue;
            }
            if quoted && c == '\\' {
                escaped = true;
                continue;
            }
            if c == '"' {
                quoted = !quoted;
            }
            if !quoted {
                match c {
                    '(' | '[' | '{' => depth += 1,
                    ')' | ']' | '}' => depth -= 1,
                    _ => {}
                }
            }
        }
        offset += line.len();
        field.end = offset;
        if depth <= 0 && !quoted {
            result.push(pending.take().unwrap());
        }
    }
    result
}

pub(crate) fn strings(value: &str) -> Vec<String> {
    let mut result = vec![];
    let mut start = None;
    let mut escaped = false;
    for (i, c) in value.char_indices() {
        if escaped {
            escaped = false;
            continue;
        }
        if start.is_some() && c == '\\' {
            escaped = true;
            continue;
        }
        if c == '"' {
            if let Some(from) = start.take() {
                if let Ok(s) = serde_json::from_str::<String>(&value[from..=i]) {
                    result.push(s);
                }
            } else {
                start = Some(i);
            }
        }
    }
    result
}

pub(crate) fn setting<'a>(fields: &'a [Setting], section: &str, key: &str) -> Option<&'a str> {
    fields
        .iter()
        .find(|f| f.section == section && f.key == key)
        .map(|f| f.value.trim())
}

fn replace_setting(text: &str, section: &str, key: &str, value: &str) -> Result<String, String> {
    let fields = settings(text);
    let matches: Vec<_> = fields
        .iter()
        .filter(|f| f.section == section && f.key == key)
        .collect();
    if matches.len() > 1 {
        return Err("This setting appears more than once. Resolve it in the editor first.".into());
    }
    let newline = if text.contains("\r\n") { "\r\n" } else { "\n" };
    let assignment = format!("{key}={value}{newline}");
    if let Some(field) = matches.first() {
        let mut next = text.to_string();
        next.replace_range(field.start..field.end, &assignment);
        return Ok(next);
    }
    let marker = format!("[{section}]");
    let mut offset = 0;
    for line in text.split_inclusive('\n') {
        offset += line.len();
        if line.trim() == marker {
            let mut next = text.to_string();
            next.insert_str(offset, &format!("{newline}{assignment}"));
            return Ok(next);
        }
    }
    Ok(format!(
        "{}{newline}{marker}{newline}{assignment}",
        text.trim_end()
    ))
}

fn read_config(path: &Path) -> Result<String, String> {
    let metadata = fs::metadata(path).map_err(|e| e.to_string())?;
    if metadata.len() > CONFIG_LIMIT {
        return Err("Configuration exceeds the 8 MB inspection limit".into());
    }
    fs::read_to_string(path).map_err(|e| e.to_string())
}

fn version(tag: &str) -> Option<(u32, u32)> {
    let mut parts = tag.trim().trim_start_matches('v').split(['.', '-']);
    Some((parts.next()?.parse().ok()?, parts.next()?.parse().ok()?))
}

fn same_project_path(a: &Path, b: &Path) -> bool {
    match (fs::canonicalize(a), fs::canonicalize(b)) {
        (Ok(a), Ok(b)) => crate::projects::same_path(&a.to_string_lossy(), &b.to_string_lossy()),
        _ => crate::projects::same_path(
            &a.to_string_lossy().replace('\\', "/"),
            &b.to_string_lossy().replace('\\', "/"),
        ),
    }
}

fn identity_at(root: &Path) -> Option<String> {
    [
        root.join(".godothub/project.json"),
        root.join(".godothub.json"),
    ]
    .into_iter()
    .find_map(|path| {
        let text = read_config(&path).ok()?;
        serde_json::from_str::<serde_json::Value>(&text)
            .ok()?
            .get("id")?
            .as_str()
            .filter(|id| !id.trim().is_empty())
            .map(str::to_string)
    })
}

fn local_resource(root: &Path, resource: &str) -> Option<PathBuf> {
    let relative = resource.strip_prefix("res://")?;
    if relative.contains('\\') || relative.contains(':') {
        return None;
    }
    let path = Path::new(relative);
    if path
        .components()
        .any(|c| !matches!(c, Component::Normal(_) | Component::CurDir))
    {
        return None;
    }
    let candidate = root.join(path);
    if let Ok(real) = fs::canonicalize(&candidate) {
        if !real.starts_with(fs::canonicalize(root).ok()?) {
            return None;
        }
    }
    Some(candidate)
}

#[derive(Default)]
struct TreeStats {
    bytes: u64,
    files: usize,
    newest: Option<SystemTime>,
    complete: bool,
    large: Vec<PathBuf>,
}
fn walk(root: &Path, cache: bool) -> TreeStats {
    let start = Instant::now();
    let mut stats = TreeStats {
        complete: true,
        ..Default::default()
    };
    let mut pending = vec![root.to_path_buf()];
    let mut visited = 0;
    while let Some(dir) = pending.pop() {
        let entries = match fs::read_dir(&dir) {
            Ok(entries) => entries,
            Err(_) => {
                stats.complete = false;
                continue;
            }
        };
        for entry in entries {
            visited += 1;
            if visited > SCAN_LIMIT || start.elapsed() > Duration::from_secs(5) {
                stats.complete = false;
                return stats;
            }
            let entry = match entry {
                Ok(entry) => entry,
                Err(_) => {
                    stats.complete = false;
                    continue;
                }
            };
            let path = entry.path();
            let metadata = match fs::symlink_metadata(&path) {
                Ok(m) => m,
                Err(_) => {
                    stats.complete = false;
                    continue;
                }
            };
            if metadata.file_type().is_symlink() {
                continue;
            }
            if metadata.is_dir() {
                let name = entry.file_name();
                if cache
                    || ![".git", ".godot", ".import", "node_modules", ".godothub"]
                        .iter()
                        .any(|n| name == *n)
                {
                    pending.push(path);
                }
            } else if metadata.is_file() {
                stats.files += 1;
                stats.bytes = stats.bytes.saturating_add(metadata.len());
                if let Ok(time) = metadata.modified() {
                    stats.newest = Some(stats.newest.map_or(time, |previous| previous.max(time)));
                }
                if !cache && metadata.len() >= LARGE_BINARY {
                    if stats.large.len() < 100 {
                        stats.large.push(path);
                    } else {
                        stats.complete = false;
                    }
                }
            }
        }
    }
    stats
}

fn git(root: &Path, args: &[&str]) -> Result<Output, String> {
    crate::git_helpers::git_command()
        .current_dir(root)
        .args(args)
        .output()
        .map_err(|e| e.to_string())
}
fn git_text(root: &Path, args: &[&str]) -> Result<String, String> {
    let output = git(root, args)?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(String::from_utf8_lossy(&output.stdout).trim().into())
}
fn git_success(root: &Path, args: &[&str]) -> bool {
    git(root, args).is_ok_and(|o| o.status.success())
}

fn engine_checks(
    project: &Project,
    fields: &[Setting],
    versions: &[InstalledGodotVersion],
) -> Vec<HealthCheck> {
    let mut checks = vec![];
    let bound = versions.iter().find(|v| v.tag == project.godot_version);
    checks.push(if project.godot_version.is_empty() {
        check("engine", "error", "version_unbound").action("choose_version", None, false)
    } else if let Some(bound) = bound {
        if Path::new(&bound.executable_path).is_file() {
            check("engine", "ok", "version_ready").value("version", &bound.tag)
        } else {
            check("engine", "error", "version_executable_missing")
                .value("version", &bound.tag)
                .detail(&bound.executable_path)
                .action("manage_versions", None, false)
        }
    } else {
        check("engine", "error", "version_missing")
            .value("version", &project.godot_version)
            .action("install_version", None, false)
    });

    let format = setting(fields, "", "config_version").and_then(|n| n.parse::<u32>().ok());
    let feature = setting(fields, "application", "config/features")
        .into_iter()
        .flat_map(strings)
        .find_map(|s| version(&s));
    let recorded = feature.or_else(|| {
        format.and_then(|f| match f {
            4 => Some((3, 0)),
            5 => Some((4, 0)),
            _ => None,
        })
    });
    let target = version(&project.godot_version);
    let compatibility = match (format, recorded, target) {
        (Some(f), _, Some((major, _))) if f > 5 || (major == 3 && f > 4) => {
            check("engine", "error", "format_incompatible")
                .value("format", f)
                .value("version", &project.godot_version)
                .action("choose_version", None, false)
        }
        (_, Some((major, _)), Some((target_major, _))) if major != target_major => {
            check("engine", "error", "major_mismatch")
                .value("major", major)
                .value("version", &project.godot_version)
                .action("choose_version", None, false)
        }
        (_, Some(recorded), Some(target)) if feature.is_some() && recorded != target => check(
            "engine",
            if recorded > target {
                "error"
            } else {
                "warning"
            },
            "feature_mismatch",
        )
        .value("recorded", format!("{}.{}", recorded.0, recorded.1))
        .value("version", &project.godot_version)
        .action("choose_version", None, false),
        (None, _, _) | (_, None, _) | (_, _, None) => check("engine", "info", "format_unknown"),
        _ => check("engine", "ok", "format_ready"),
    };
    checks.push(compatibility);
    checks
}

fn addon_checks(root: &Path, fields: &[Setting]) -> Vec<HealthCheck> {
    let enabled: HashSet<String> = setting(fields, "editor_plugins", "enabled")
        .map(strings)
        .unwrap_or_default()
        .into_iter()
        .collect();
    let mut checks = vec![];
    for plugin in &enabled {
        if !local_resource(root, plugin).is_some_and(|p| p.is_file()) {
            checks.push(
                check("addons", "warning", "addon_missing")
                    .named(plugin)
                    .detail(plugin)
                    .action("disable_addon", Some(plugin.clone()), false),
            );
        }
    }
    if let Ok(entries) = fs::read_dir(root.join("addons")) {
        for entry in entries.flatten().take(500) {
            let cfg = entry.path().join("plugin.cfg");
            if entry
                .file_type()
                .is_ok_and(|t| t.is_dir() && !t.is_symlink())
            {
                let name = entry.file_name().to_string_lossy().to_string();
                let resource = format!("res://addons/{name}/plugin.cfg");
                if !cfg.is_file() {
                    checks.push(
                        check("addons", "info", "addon_orphan")
                            .named(&name)
                            .detail(format!("res://addons/{name}"))
                            .action("open_addons", None, false),
                    );
                    continue;
                }
                if !enabled.contains(&resource) {
                    let valid = read_config(&cfg).ok().is_some_and(|text| {
                        let fields = settings(&text);
                        setting(&fields, "plugin", "script")
                            .and_then(|v| strings(v).into_iter().next())
                            .is_some_and(|s| {
                                let res = if s.starts_with("res://") {
                                    s
                                } else {
                                    format!("res://addons/{name}/{s}")
                                };
                                local_resource(root, &res).is_some_and(|p| p.is_file())
                            })
                    });
                    let mut c = check("addons", "info", "addon_disabled")
                        .named(&resource)
                        .detail(&resource);
                    if valid {
                        c = c.action("enable_addon", Some(resource), true);
                    }
                    checks.push(c);
                }
            }
        }
    }
    if checks.is_empty() {
        checks.push(check("addons", "ok", "addons_ready"));
    }
    checks
}

fn export_checks(root: &Path) -> Vec<HealthCheck> {
    let path = root.join("export_presets.cfg");
    if !path.exists() {
        return vec![check("exports", "info", "no_presets")];
    }
    let text = match read_config(&path) {
        Ok(t) => t,
        Err(e) => return vec![check("exports", "warning", "presets_unreadable").detail(e)],
    };
    let mut missing = std::collections::BTreeSet::new();
    let fields = settings(&text);
    for field in &fields {
        if [
            "exclude_filter",
            "include_filter",
            "export_path",
            "encryption_include_filters",
            "encryption_exclude_filters",
        ]
        .contains(&field.key.as_str())
        {
            continue;
        }
        if field.key == "export_files"
            && setting(&fields, &field.section, "export_filter")
                .is_some_and(|v| v.contains("exclude"))
        {
            continue;
        }
        for resource in strings(&field.value)
            .into_iter()
            .filter(|s| s.starts_with("res://") && !s.contains(['*', '?']))
        {
            if !local_resource(root, &resource).is_some_and(|p| p.exists()) {
                missing.insert((format!("{}: {}", field.section, field.key), resource));
            }
        }
    }
    if missing.is_empty() {
        vec![check("exports", "ok", "exports_ready")]
    } else {
        let mut c = check("exports", "warning", "export_resources_missing").action(
            "open_presets",
            None,
            false,
        );
        c.details = missing
            .into_iter()
            .map(|(key, resource)| format!("{key} → {resource}"))
            .collect();
        vec![c]
    }
}

fn required_template_platforms(root: &Path) -> HashSet<String> {
    let text = read_config(&root.join("export_presets.cfg")).unwrap_or_default();
    settings(&text)
        .into_iter()
        .filter(|field| field.key == "platform")
        .filter_map(|field| {
            let platform = strings(&field.value).into_iter().next()?;
            Some(
                match platform.as_str() {
                    "Windows Desktop" => "Windows",
                    "Linux" | "Linux/X11" => "Linux",
                    "macOS" | "Mac OSX" => "macOS",
                    "HTML5" | "Web" => "Web",
                    "Android" => "Android",
                    "iOS" | "iPhone" => "iOS",
                    "visionOS" => "visionOS",
                    "UWP" => "UWP",
                    _ => return None,
                }
                .to_string(),
            )
        })
        .collect()
}

fn binary(path: &Path) -> bool {
    let mut bytes = [0; 8192];
    fs::File::open(path)
        .and_then(|mut f| f.read(&mut bytes))
        .is_ok_and(|len| bytes[..len].contains(&0) || std::str::from_utf8(&bytes[..len]).is_err())
}

fn git_checks(root: &Path, large: &[PathBuf]) -> Vec<HealthCheck> {
    let repo = match git_text(root, &["rev-parse", "--show-toplevel"]) {
        Ok(repo) => PathBuf::from(repo),
        Err(error) => return vec![check("git", "info", "git_unavailable").detail(error)],
    };
    let mut checks = vec![];
    let ignored = |path: &str| git_success(root, &["check-ignore", "--no-index", "-q", "--", path]);
    if !ignored(".godot/__doctor_probe__")
        || !ignored(".godothub.json")
        || !ignored(".godothub/__doctor_probe__")
    {
        checks.push(check("git", "warning", "ignore_missing").action("add_ignores", None, false));
    } else {
        checks.push(check("git", "ok", "ignores_ready"));
    }
    if git_success(
        root,
        &["ls-files", "--error-unmatch", "--", ".godothub.json"],
    ) {
        checks.push(check("git", "warning", "metadata_tracked").action(
            "untrack_metadata",
            None,
            true,
        ));
    } else {
        checks.push(check("git", "ok", "metadata_private"));
    }

    let candidates: Vec<_> = large
        .iter()
        .filter(|p| binary(p))
        .filter_map(|p| {
            let relative = p.strip_prefix(&repo).ok()?.to_str()?.replace('\\', "/");
            if git_success(&repo, &["check-ignore", "-q", "--", &relative]) {
                return None;
            }
            Some(relative)
        })
        .collect();
    if candidates.is_empty() {
        checks.push(check("git", "ok", "lfs_ready"));
        return checks;
    }
    let attributes = (|| -> Result<HashSet<String>, String> {
        let mut child = crate::git_helpers::git_command()
            .current_dir(&repo)
            .args(["check-attr", "-z", "--stdin", "filter"])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| e.to_string())?;
        let mut input = child
            .stdin
            .take()
            .ok_or("Could not inspect Git attributes")?;
        for file in &candidates {
            input
                .write_all(file.as_bytes())
                .and_then(|_| input.write_all(&[0]))
                .map_err(|e| e.to_string())?;
        }
        drop(input);
        let output = child.wait_with_output().map_err(|e| e.to_string())?;
        if !output.status.success() {
            return Err(String::from_utf8_lossy(&output.stderr).into());
        }
        let parts: Vec<_> = output.stdout.split(|c| *c == 0).collect();
        Ok(parts
            .chunks(3)
            .filter_map(|row| {
                if row.len() == 3 && row[2] == b"lfs" {
                    Some(String::from_utf8_lossy(row[0]).into())
                } else {
                    None
                }
            })
            .collect())
    })();
    let attributes = match attributes {
        Ok(a) => a,
        Err(e) => {
            checks.push(check("git", "warning", "lfs_unknown").detail(e));
            return checks;
        }
    };
    for file in candidates {
        if !attributes.contains(&file) {
            checks.push(
                check("git", "warning", "binary_without_lfs")
                    .named(&file)
                    .detail(&file)
                    .action("track_lfs", Some(file), true),
            );
        }
    }
    if !checks.iter().any(|c| c.code == "binary_without_lfs") {
        checks.push(check("git", "ok", "lfs_ready"));
    }
    checks
}

fn diagnose(app: &AppHandle, id: &str) -> Result<HealthReport, String> {
    let projects = crate::projects::read_projects(app);
    let project = projects
        .iter()
        .find(|p| p.id == id)
        .ok_or("Project is no longer registered")?;
    let versions = crate::godot_versions::read_registry(app);
    diagnose_local(project, &projects, &versions)
}

pub(crate) fn diagnose_cli(
    root: &Path,
    version_tag: &str,
    versions: &[InstalledGodotVersion],
) -> Result<HealthReport, String> {
    let project = Project {
        id: String::new(),
        name: root
            .file_name()
            .and_then(|name| name.to_str())
            .unwrap_or("project")
            .to_string(),
        path: root.to_string_lossy().to_string(),
        godot_version: version_tag.to_string(),
        created_at: String::new(),
        last_opened: None,
        category: None,
        pinned: false,
        sort_order: 0,
        launch_arguments: String::new(),
        tags: Vec::new(),
        total_time_seconds: 0,
        session_started_at_ms: None,
        time_today_seconds: 0,
        time_week_seconds: 0,
    };
    let projects = [project.clone()];
    diagnose_local(&project, &projects, versions)
}

pub(crate) fn diagnose_local(
    project: &Project,
    projects: &[Project],
    versions: &[InstalledGodotVersion],
) -> Result<HealthReport, String> {
    let id = project.id.as_str();
    let root = Path::new(&project.path);
    let mut checks = vec![];
    let project_file = root.join("project.godot");
    if let Err(error) = fs::metadata(&project_file) {
        if error.kind() != std::io::ErrorKind::NotFound {
            return Err(format!("Could not inspect project.godot: {error}"));
        }
    }
    if !project_file.is_file() {
        checks.push(
            check("registrations", "error", "registration_stale")
                .detail(&project.path)
                .action("remove_registration", Some(project.id.clone()), true),
        );
        return Ok(HealthReport {
            project_id: id.into(),
            scanned_at_ms: crate::projects::epoch_ms(),
            checks,
        });
    }
    let text = read_config(&root.join("project.godot"))?;
    let fields = settings(&text);
    checks.extend(engine_checks(project, &fields, versions));
    if let Some(bound) = versions.iter().find(|v| v.tag == project.godot_version) {
        let installed = crate::export_templates::installed_template_platforms(bound);
        let required = required_template_platforms(root);
        let missing: Vec<_> = required
            .into_iter()
            .filter(|platform| !installed.contains(platform))
            .collect();
        checks.push(if installed.is_empty() {
            check("templates", "warning", "templates_missing")
                .value("version", &bound.tag)
                .action("templates", None, false)
        } else if !missing.is_empty() {
            let mut c = check("templates", "warning", "templates_platforms_missing").action(
                "templates",
                None,
                false,
            );
            c.details = missing;
            c
        } else {
            let mut c = check("templates", "ok", "templates_ready");
            c.details = installed;
            c.action("templates", None, false)
        });
    } else {
        checks.push(check("templates", "info", "templates_unknown"));
    }
    checks.push(if crate::projects::project_has_main_scene(&project.path) {
        check("scenes", "ok", "main_scene_ready")
    } else {
        check("scenes", "warning", "main_scene_missing").action("open_editor", None, false)
    });
    if let Some(main) = setting(&fields, "application", "run/main_scene")
        .and_then(|v| strings(v).into_iter().next())
    {
        if main.starts_with("res://") && !local_resource(root, &main).is_some_and(|p| p.is_file()) {
            checks.push(
                check("scenes", "error", "main_scene_missing_file")
                    .detail(main)
                    .action("open_editor", None, false),
            );
        }
    }
    let cache = root.join(".godot");
    if cache.is_dir() && !fs::symlink_metadata(&cache).is_ok_and(|m| m.file_type().is_symlink()) {
        let stats = walk(&cache, true);
        let age = stats
            .newest
            .and_then(|time| SystemTime::now().duration_since(time).ok())
            .map(|d| d.as_secs() / 86400);
        let outdated = read_config(&cache.join("editor/project_metadata.cfg"))
            .ok()
            .and_then(|t| {
                setting(&settings(&t), "editor_metadata", "executable_path").map(str::to_string)
            })
            .and_then(|v| strings(&v).into_iter().next())
            .is_some_and(|exe| {
                versions
                    .iter()
                    .find(|v| v.tag == project.godot_version)
                    .is_some_and(|bound| {
                        !same_project_path(Path::new(&exe), Path::new(&bound.executable_path))
                    })
            });
        let code = if !stats.complete {
            "cache_partial"
        } else if outdated {
            "cache_version"
        } else if age.is_some_and(|d| d >= 30) {
            "cache_stale"
        } else if stats.bytes >= LARGE_CACHE {
            "cache_large"
        } else {
            "cache_ready"
        };
        checks.push(
            check(
                "cache",
                if code == "cache_ready" { "ok" } else { "info" },
                code,
            )
            .value("bytes", stats.bytes)
            .value("files", stats.files)
            .value("days", age.map_or_else(|| "-".into(), |v| v.to_string()))
            .action("clear_cache", None, true),
        );
    } else {
        checks.push(check("cache", "info", "cache_absent"));
    }
    checks.extend(addon_checks(root, &fields));
    checks.extend(export_checks(root));
    let tree = walk(root, false);
    checks.extend(git_checks(root, &tree.large));
    if !tree.complete {
        checks.push(check("git", "info", "scan_partial"));
    }
    let identity = identity_at(root);
    for other in projects.iter().filter(|p| p.id != id) {
        let same_path = same_project_path(root, Path::new(&other.path));
        let stale_copy = !Path::new(&other.path).join("project.godot").is_file()
            && identity.as_ref().is_some_and(|current| {
                identity_at(Path::new(&other.path)).as_ref() == Some(current)
            });
        if same_path || stale_copy {
            checks.push(
                check("registrations", "warning", "registration_duplicate")
                    .named(&other.id)
                    .detail(format!("{} · {}", other.name, other.path))
                    .action("remove_registration", Some(other.id.clone()), true),
            );
        }
    }
    if !checks.iter().any(|c| c.category == "registrations") {
        checks.push(check("registrations", "ok", "registration_ready"));
    }
    Ok(HealthReport {
        project_id: id.into(),
        scanned_at_ms: crate::projects::epoch_ms(),
        checks,
    })
}

fn require_closed(app: &AppHandle, project: &Project) -> Result<(), String> {
    if crate::projects::tracked_pid(app, &project.id).is_some()
        || project.session_started_at_ms.is_some()
    {
        return Err("Close this project in Godot before applying this fix.".into());
    }
    let running = crate::process::find_running_godot_processes().map_err(|_| {
        "Could not verify that Godot is closed. Try again after closing the editor."
    })?;
    if running
        .iter()
        .any(|p| same_project_path(Path::new(&p.project_path), Path::new(&project.path)))
    {
        return Err("Close this project in Godot before applying this fix.".into());
    }
    Ok(())
}

fn write_backup(app: &AppHandle, project: &Project, path: &Path, next: &str) -> Result<(), String> {
    if fs::symlink_metadata(path).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err("Edit this linked file directly instead.".into());
    }
    if path.exists() {
        let backup = crate::workspace::active_workspace_dir(app)
            .join("doctor-backups")
            .join(
                project
                    .id
                    .chars()
                    .map(|c| {
                        if c.is_ascii_alphanumeric() || c == '-' || c == '_' {
                            c
                        } else {
                            '_'
                        }
                    })
                    .collect::<String>(),
            )
            .join(uuid::Uuid::new_v4().to_string());
        fs::create_dir_all(&backup).map_err(|e| e.to_string())?;
        fs::copy(
            path,
            backup.join(path.file_name().ok_or("Invalid file path")?),
        )
        .map_err(|e| e.to_string())?;
    }
    fs::write(path, next).map_err(|e| e.to_string())
}

fn apply_fix(app: &AppHandle, id: &str, check_id: &str) -> Result<(), String> {
    static FIX_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());
    let _guard = FIX_LOCK
        .lock()
        .map_err(|_| "Another Doctor fix did not complete. Restart GodotHub and try again.")?;
    let report = diagnose(app, id)?;
    let action = report
        .checks
        .into_iter()
        .find(|c| c.id == check_id)
        .and_then(|c| c.action)
        .ok_or("This finding has changed. Run the checks again.")?;
    let mut projects = crate::projects::read_projects(app);
    let project = projects
        .iter()
        .find(|p| p.id == id)
        .cloned()
        .ok_or("Project not found")?;
    let root = Path::new(&project.path);
    match action.kind.as_str() {
        "clear_cache" => {
            require_closed(app, &project)?;
            let cache = root.join(".godot");
            let metadata = fs::symlink_metadata(&cache).map_err(|e| e.to_string())?;
            if !metadata.is_dir() || metadata.file_type().is_symlink() {
                return Err("The import cache is not a regular directory.".into());
            }
            let real = fs::canonicalize(&cache).map_err(|e| e.to_string())?;
            if real.parent() != fs::canonicalize(root).ok().as_deref() {
                return Err("The import cache is outside this project.".into());
            }
            trash::delete(&cache).map_err(|e| e.to_string())?;
        }
        "disable_addon" | "enable_addon" => {
            require_closed(app, &project)?;
            let path = root.join("project.godot");
            let text = read_config(&path)?;
            let fields = settings(&text);
            let value =
                setting(&fields, "editor_plugins", "enabled").unwrap_or("PackedStringArray()");
            let mut enabled = strings(value);
            let target = action.target.ok_or("Missing addon")?;
            enabled.retain(|entry| entry != &target);
            if action.kind == "enable_addon" {
                enabled.push(target);
            }
            let array = if value.starts_with("PoolStringArray")
                || setting(&fields, "", "config_version") == Some("4")
            {
                "PoolStringArray"
            } else {
                "PackedStringArray"
            };
            let quoted: Vec<_> = enabled
                .iter()
                .map(|s| serde_json::to_string(s).unwrap())
                .collect();
            let next = replace_setting(
                &text,
                "editor_plugins",
                "enabled",
                &format!("{array}({})", quoted.join(", ")),
            )?;
            write_backup(app, &project, &path, &next)?;
        }
        "add_ignores" => {
            let path = root.join(".gitignore");
            let original = if path.exists() {
                read_config(&path)?
            } else {
                String::new()
            };
            let newline = if original.contains("\r\n") {
                "\r\n"
            } else {
                "\n"
            };
            let mut next = original.trim_end().to_string();
            next.push_str(&format!("{newline}{newline}# Godot import cache and local GodotHub metadata{newline}/.godot/{newline}/.godothub/{newline}/.godothub.json{newline}"));
            write_backup(app, &project, &path, &next)?;
        }
        "untrack_metadata" => {
            if !git_success(
                root,
                &["diff", "--cached", "--quiet", "--", ".godothub.json"],
            ) {
                return Err("This file has staged changes. Review them in Git before removing it from tracking.".into());
            }
            git_text(root, &["rm", "--cached", "--", ".godothub.json"])?;
        }
        "track_lfs" => {
            let repo = PathBuf::from(git_text(root, &["rev-parse", "--show-toplevel"])?);
            let file = action.target.ok_or("Missing file")?;
            git_text(&repo, &["lfs", "version"])
                .map_err(|_| "Install Git LFS first, then run this fix again.")?;
            let attributes = repo.join(".gitattributes");
            if fs::symlink_metadata(&attributes).is_ok_and(|m| m.file_type().is_symlink()) {
                return Err("Edit this linked .gitattributes file directly instead.".into());
            }
            if attributes.exists() {
                let text = read_config(&attributes)?;
                write_backup(app, &project, &attributes, &text)?;
            }
            git_text(&repo, &["lfs", "track", "--filename", "--", &file])?;
        }
        "remove_registration" => {
            let target = action.target.ok_or("Missing registration")?;
            if projects
                .iter()
                .any(|p| p.id == target && p.session_started_at_ms.is_some())
            {
                return Err("Stop this project before removing its registration.".into());
            }
            let registry = crate::workspace::active_workspace_dir(app).join("projects.json");
            let text = read_config(&registry)?;
            write_backup(app, &project, &registry, &text)?;
            projects.retain(|p| p.id != target);
            crate::projects::write_projects(app, &projects)?;
        }
        _ => return Err("This action must be completed from the Doctor panel.".into()),
    }
    Ok(())
}

#[tauri::command]
pub async fn diagnose_project(app: AppHandle, id: String) -> Result<HealthReport, String> {
    tokio::task::spawn_blocking(move || diagnose(&app, &id))
        .await
        .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn fix_project_health(
    app: AppHandle,
    id: String,
    check_id: String,
) -> Result<(), String> {
    tokio::task::spawn_blocking(move || apply_fix(&app, &id, &check_id))
        .await
        .map_err(|e| e.to_string())?
}

#[cfg(test)]
mod tests {
    use super::*;

    struct Fixture(PathBuf);
    impl Fixture {
        fn new() -> Self {
            let root = std::env::temp_dir()
                .join(format!("godothub-doctor-fixture-{}", uuid::Uuid::new_v4()));
            fs::create_dir_all(&root).unwrap();
            Self(root)
        }
        fn write(&self, name: &str, text: &str) {
            let file = self.0.join(name);
            fs::create_dir_all(file.parent().unwrap()).unwrap();
            fs::write(file, text).unwrap();
        }
        fn project(&self, id: &str) -> Project {
            serde_json::from_value(serde_json::json!({"id":id,"name":"Doctor fixture","path":self.0.to_string_lossy(),"godot_version":"4.4-stable","last_opened":null})).unwrap()
        }
    }
    impl Drop for Fixture {
        fn drop(&mut self) {
            let real = fs::canonicalize(&self.0).unwrap();
            let parent = fs::canonicalize(std::env::temp_dir()).unwrap();
            assert!(
                real.parent() == Some(parent.as_path())
                    && real
                        .file_name()
                        .unwrap()
                        .to_string_lossy()
                        .starts_with("godothub-doctor-fixture-")
            );
            fs::remove_dir_all(real).unwrap();
        }
    }

    #[test]
    fn fixture_finds_missing_addons_resources_and_duplicate_registrations_without_writing() {
        let fixture = Fixture::new();
        fixture.write("project.godot", "config_version=5\n[application]\nconfig/features=PackedStringArray(\"4.4\")\n[editor_plugins]\nenabled=PackedStringArray(\"res://addons/missing/plugin.cfg\")\n");
        fixture.write(
            "addons/disabled/plugin.cfg",
            "[plugin]\nscript=\"plugin.gd\"\n",
        );
        fixture.write("addons/disabled/plugin.gd", "@tool\nextends EditorPlugin\n");
        fixture.write("addons/runtime/helper.gd", "extends Node\n");
        fixture.write("export_presets.cfg", "[preset.0]\nplatform=\"Android\"\nexport_files=PackedStringArray(\"res://absent_a.tscn\", \"res://absent_b.tscn\")\n");
        fixture.write(".godothub.json", "{\"id\":\"legacy-id\"}");
        let project = fixture.project("current");
        let duplicate = fixture.project("duplicate");
        let report = diagnose_local(&project, &[project.clone(), duplicate], &[]).unwrap();
        for code in [
            "version_missing",
            "main_scene_missing",
            "addon_missing",
            "addon_disabled",
            "addon_orphan",
            "export_resources_missing",
            "registration_duplicate",
        ] {
            assert!(
                report.checks.iter().any(|c| c.code == code),
                "Missing {code}"
            );
        }
        assert_eq!(
            report
                .checks
                .iter()
                .find(|c| c.code == "export_resources_missing")
                .unwrap()
                .details
                .len(),
            2
        );
        assert!(fixture.0.join(".godothub.json").is_file());
        assert!(!fixture.0.join(".godothub").exists());
        assert_eq!(
            required_template_platforms(&fixture.0),
            HashSet::from(["Android".into()])
        );
    }

    #[test]
    fn stale_registration_has_only_a_library_removal_action() {
        let fixture = Fixture::new();
        let project = fixture.project("current");
        let report = diagnose_local(&project, &[project.clone()], &[]).unwrap();
        assert_eq!(report.checks.len(), 1);
        assert_eq!(report.checks[0].code, "registration_stale");
        assert_eq!(
            report.checks[0].action.as_ref().unwrap().kind,
            "remove_registration"
        );
    }

    #[test]
    fn git_checks_use_effective_ignores_and_nested_lfs_attributes() {
        let fixture = Fixture::new();
        git_text(&fixture.0, &["init", "-q"]).unwrap();
        fixture.write("game/project.godot", "config_version=5\n");
        fixture.write("game/.godothub.json", "{\"id\":\"test\"}");
        fixture.write(
            ".gitignore",
            "/game/.godot/\n/game/.godothub/\n/game/.godothub.json\n",
        );
        git_text(&fixture.0, &["add", "--force", "--", "game/.godothub.json"]).unwrap();
        let large = fixture.0.join("game/asset with spaces.bin");
        fs::File::create(&large)
            .unwrap()
            .set_len(LARGE_BINARY)
            .unwrap();
        let checks = git_checks(&fixture.0.join("game"), &[large.clone()]);
        assert!(checks.iter().any(|c| c.code == "ignores_ready"));
        assert!(checks.iter().any(|c| c.code == "metadata_tracked"));
        assert!(checks.iter().any(|c| c.code == "binary_without_lfs"));
        fixture.write(
            "game/.gitattributes",
            "*.bin filter=lfs diff=lfs merge=lfs -text\n",
        );
        let checks = git_checks(&fixture.0.join("game"), &[large]);
        assert!(checks.iter().any(|c| c.code == "lfs_ready"));
        assert!(!checks.iter().any(|c| c.code == "binary_without_lfs"));
    }

    #[test]
    fn duplicate_settings_cannot_be_silently_rewritten() {
        assert!(replace_setting(
            "[editor_plugins]\nenabled=PackedStringArray()\nenabled=PackedStringArray()\n",
            "editor_plugins",
            "enabled",
            "PackedStringArray()"
        )
        .is_err());
    }

    #[test]
    fn cache_age_and_size_are_reported_without_deleting_it() {
        let fixture = Fixture::new();
        fixture.write("project.godot", "config_version=5\n");
        fixture.write(".godot/imported/cache.bin", "cache");
        let file = fs::OpenOptions::new()
            .write(true)
            .open(fixture.0.join(".godot/imported/cache.bin"))
            .unwrap();
        let old = SystemTime::now() - Duration::from_secs(40 * 86400);
        file.set_times(fs::FileTimes::new().set_modified(old))
            .unwrap();
        drop(file);
        let project = fixture.project("current");
        let report = diagnose_local(&project, &[project.clone()], &[]).unwrap();
        let cache = report
            .checks
            .iter()
            .find(|c| c.code == "cache_stale")
            .unwrap();
        assert_eq!(cache.values["bytes"], "5");
        assert_eq!(cache.values["days"], "40");
        assert!(fixture.0.join(".godot/imported/cache.bin").is_file());
    }

    #[test]
    fn lfs_filename_fix_treats_special_characters_literally() {
        let fixture = Fixture::new();
        git_text(&fixture.0, &["init", "-q"]).unwrap();
        if !git_success(&fixture.0, &["lfs", "version"]) {
            return;
        }
        fixture.write("asset [draft].bin", "binary fixture");
        git_text(
            &fixture.0,
            &["lfs", "track", "--filename", "--", "asset [draft].bin"],
        )
        .unwrap();
        assert!(git_text(
            &fixture.0,
            &["check-attr", "filter", "--", "asset [draft].bin"]
        )
        .unwrap()
        .ends_with("filter: lfs"));
        assert!(
            !git_text(&fixture.0, &["check-attr", "filter", "--", "asset d.bin"])
                .unwrap()
                .ends_with("filter: lfs")
        );
        assert!(fixture.0.join("asset [draft].bin").is_file());
    }
    #[test]
    fn variants_and_comments_are_preserved() {
        let text = "; keep me\r\nconfig_version=5\r\n[application]\r\nconfig/features=PackedStringArray(\"4.4\", \"GL Compatibility\")\r\n[editor_plugins]\r\nenabled=PackedStringArray(\r\n\"res://addons/a/plugin.cfg\",\r\n\"res://addons/b/plugin.cfg\") ; old\r\n[rendering]\r\nrenderer/rendering_method=\"gl_compatibility\"\r\n";
        let fields = settings(text);
        assert_eq!(
            strings(setting(&fields, "editor_plugins", "enabled").unwrap()).len(),
            2
        );
        let next =
            replace_setting(text, "editor_plugins", "enabled", "PackedStringArray()").unwrap();
        assert!(next.starts_with("; keep me\r\nconfig_version=5"));
        assert!(next.contains("[rendering]\r\nrenderer/rendering_method=\"gl_compatibility\""));
        assert!(!next.contains("addons/b"));
    }
    #[test]
    fn resource_paths_cannot_escape() {
        let root = std::env::temp_dir();
        assert!(local_resource(&root, "res://../secret").is_none());
        assert!(local_resource(&root, "res://C:/secret").is_none());
        assert!(local_resource(&root, "res://..\\secret").is_none());
        assert!(local_resource(&root, "uid://abc").is_none());
        assert!(local_resource(&root, "res://assets/file.tscn").is_some());
    }
    #[test]
    fn compatibility_uses_feature_version_for_minor_releases() {
        assert_eq!(version("v4.4.1-stable-mono"), Some((4, 4)));
        let fields = settings("config_version=5\n[application]\nconfig/features=PackedStringArray(\"4.4\", \"GL Compatibility\")\n");
        let project: Project = serde_json::from_value(serde_json::json!({"id":"test","name":"test","path":"","godot_version":"4.2-stable","last_opened":null})).unwrap();
        let checks = engine_checks(&project, &fields, &[]);
        assert!(checks
            .iter()
            .any(|c| c.code == "feature_mismatch" && c.severity == "error"));
        let fields = settings("config_version=4\n");
        assert!(engine_checks(&project, &fields, &[])
            .iter()
            .any(|c| c.code == "major_mismatch"));
    }
    #[test]
    fn export_outputs_and_filters_are_not_resource_dependencies() {
        let root = std::env::temp_dir().join(format!("godothub-doctor-{}", uuid::Uuid::new_v4()));
        fs::create_dir_all(&root).unwrap();
        fs::write(root.join("export_presets.cfg"), "[preset.0]\nexport_path=\"res://build/missing.exe\"\ninclude_filter=\"res://optional/*\"\n[preset.0.options]\napplication/icon=\"res://missing.ico\"\n").unwrap();
        let checks = export_checks(&root);
        assert_eq!(checks[0].code, "export_resources_missing");
        assert_eq!(checks[0].details.len(), 1);
        assert!(checks[0].details[0].contains("missing.ico"));
        fs::remove_file(root.join("export_presets.cfg")).unwrap();
        fs::remove_dir(root).unwrap();
    }
}
