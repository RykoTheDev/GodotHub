use crate::godotenv::{self, DetectedVersion};
use crate::models::{GodotRelease, GodotReleaseAsset, InstalledGodotVersion};
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter};

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

pub const MANAGED_BY: &str = "mise";

const GODOT_TOOL: &str = "godot";
const MONO_SUFFIX: &str = "-mono";

const MISE_CONFIG_FILES: [&str; 4] = [
    "mise.local.toml",
    ".mise.local.toml",
    "mise.toml",
    ".mise.toml",
];
const TOOL_VERSIONS_FILE: &str = ".tool-versions";

const STATUS_CACHE_TTL: Duration = Duration::from_secs(300);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MiseStatus {
    pub available: bool,
    pub path: Option<String>,
    pub version: Option<String>,
    pub source_url: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MiseGodotInstall {
    pub version: String,
    pub install_path: String,
}

fn binary_names() -> &'static [&'static str] {
    if cfg!(windows) {
        &["mise.exe", "mise.cmd", "mise"]
    } else {
        &["mise"]
    }
}

fn home_dir() -> Option<PathBuf> {
    std::env::var_os("HOME")
        .or_else(|| std::env::var_os("USERPROFILE"))
        .map(PathBuf::from)
        .filter(|p| !p.as_os_str().is_empty())
}

pub fn mise_binary() -> Option<PathBuf> {
    if let Some(explicit) = std::env::var_os("MISE_BIN") {
        let path = PathBuf::from(explicit);
        if path.is_file() {
            return Some(path);
        }
    }

    let mut candidates: Vec<PathBuf> = Vec::new();
    if let Some(paths) = std::env::var_os("PATH") {
        for dir in std::env::split_paths(&paths) {
            for name in binary_names() {
                candidates.push(dir.join(name));
            }
        }
    }
    if let Some(home) = home_dir() {
        for rel in [
            ".local/bin/mise",
            ".local/share/mise/bin/mise",
            "bin/mise",
            ".cargo/bin/mise",
        ] {
            let path = home.join(rel);
            candidates.push(path.clone());
            if cfg!(windows) {
                candidates.push(path.with_extension("exe"));
            }
        }
    }
    if let Some(local) = std::env::var_os("LOCALAPPDATA") {
        let base = PathBuf::from(local)
            .join("Programs")
            .join("mise")
            .join("bin");
        for name in binary_names() {
            candidates.push(base.join(name));
        }
    }

    candidates.into_iter().find(|p| p.is_file())
}

fn mise_command(bin: &Path) -> std::process::Command {
    let mut cmd = std::process::Command::new(bin);
    cmd.env("MISE_YES", "1");
    #[cfg(target_os = "windows")]
    cmd.creation_flags(crate::terminal::CREATE_NO_WINDOW);
    cmd
}

fn failure_message(args: &[&str], stdout: &str, stderr: &str) -> String {
    let detail = if stderr.trim().is_empty() {
        stdout.trim()
    } else {
        stderr.trim()
    };
    if detail.is_empty() {
        format!("`mise {}` failed.", args.join(" "))
    } else {
        detail.to_string()
    }
}

fn run_mise(args: &[&str]) -> Result<String, String> {
    let bin = mise_binary().ok_or_else(|| "mise was not found on your PATH.".to_string())?;
    let output = mise_command(&bin)
        .args(args)
        .output()
        .map_err(|e| format!("Failed to run mise: {e}"))?;
    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(failure_message(args, &stdout, &stderr));
    }
    Ok(stdout)
}

pub fn mise_version() -> Option<String> {
    let bin = mise_binary()?;
    let output = mise_command(&bin).arg("--version").output().ok()?;
    if !output.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&output.stdout);
    text.lines()
        .map(str::trim)
        .find(|line| !line.is_empty())?
        .split_whitespace()
        .next()
        .map(str::to_string)
}

fn upstream_repo(full: &str) -> Option<String> {
    let (_backend, spec) = full.split_once(':')?;
    let mut parts = spec.trim().split('/');
    let owner = parts.next()?.trim();
    let repo = parts.next()?.trim();
    if owner.is_empty() || repo.is_empty() {
        return None;
    }
    Some(format!("https://github.com/{owner}/{repo}"))
}

fn source_url() -> Option<String> {
    let output = run_mise(&["registry", GODOT_TOOL]).ok()?;
    let full = output.lines().map(str::trim).find(|l| !l.is_empty())?;
    let repo = upstream_repo(full)?;
    Some(format!("{repo}/releases"))
}

fn status_cache() -> &'static Mutex<Option<(Instant, MiseStatus)>> {
    static CACHE: OnceLock<Mutex<Option<(Instant, MiseStatus)>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(None))
}

/// Drop the cached status so the next `mise_status` call re-detects mise with
/// fresh subprocess output (used when the integration toggle changes).
pub fn clear_status_cache() {
    *status_cache().lock().unwrap() = None;
}

fn compute_status() -> MiseStatus {
    match mise_binary() {
        Some(path) => MiseStatus {
            available: true,
            path: Some(path.to_string_lossy().to_string()),
            version: mise_version(),
            source_url: source_url(),
        },
        None => MiseStatus {
            available: false,
            path: None,
            version: None,
            source_url: None,
        },
    }
}

pub fn status() -> MiseStatus {
    let cache = status_cache();
    let mut cached = cache.lock().unwrap();
    if let Some((at, status)) = cached.as_ref() {
        if at.elapsed() < STATUS_CACHE_TTL {
            return status.clone();
        }
    }
    let fresh = compute_status();
    if fresh.available {
        *cached = Some((Instant::now(), fresh.clone()));
    } else {
        *cached = None;
    }
    fresh
}

fn tool_key_is_godot(key: &str) -> bool {
    let key = key.trim().to_lowercase();
    key == GODOT_TOOL
        || key.starts_with("godot@")
        || key.ends_with(":godot")
        || key.ends_with("/godot")
}

fn expand_home(path: &str) -> String {
    let stripped = path.strip_prefix("~/").or_else(|| path.strip_prefix("~\\"));
    match stripped.and_then(|rest| home_dir().map(|home| home.join(rest))) {
        Some(path) => path.to_string_lossy().to_string(),
        None => path.to_string(),
    }
}

fn parse_ls_json(raw: &str) -> Vec<MiseGodotInstall> {
    let Ok(value) = serde_json::from_str::<serde_json::Value>(raw) else {
        return Vec::new();
    };

    let mut records: Vec<&serde_json::Value> = Vec::new();
    match &value {
        serde_json::Value::Array(items) => records.extend(items.iter()),
        serde_json::Value::Object(map) => {
            for (tool, entry) in map {
                if !tool_key_is_godot(tool) {
                    continue;
                }
                match entry {
                    serde_json::Value::Array(items) => records.extend(items.iter()),
                    single => records.push(single),
                }
            }
        }
        _ => return Vec::new(),
    }

    let mut installs = Vec::new();
    for record in records {
        if record.get("installed").and_then(|v| v.as_bool()) == Some(false) {
            continue;
        }
        let Some(version) = record.get("version").and_then(|v| v.as_str()) else {
            continue;
        };
        let version = version.trim();
        if version.is_empty() {
            continue;
        }
        let Some(path) = record
            .get("install_path")
            .or_else(|| record.get("path"))
            .and_then(|v| v.as_str())
        else {
            continue;
        };
        let install_path = expand_home(path.trim());
        if install_path.is_empty() || !Path::new(&install_path).is_dir() {
            continue;
        }
        installs.push(MiseGodotInstall {
            version: version.to_string(),
            install_path,
        });
    }
    installs
}

pub fn list_godot_installs() -> Result<Vec<MiseGodotInstall>, String> {
    match run_mise(&["ls", "--json", "--installed", GODOT_TOOL]) {
        Ok(stdout) => Ok(parse_ls_json(&stdout)),
        Err(first_error) => {
            match run_mise(&["ls", "--json"]) {
                Ok(stdout) => Ok(parse_ls_json(&stdout)),
                Err(_) => Err(first_error),
            }
        }
    }
}

fn parse_remote_versions(raw: &str) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut versions = Vec::new();
    for line in raw.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if line.eq_ignore_ascii_case("version") {
            continue;
        }
        let version = line.trim_start_matches('v').trim();
        if version.is_empty() || !version.chars().next().is_some_and(|c| c.is_ascii_digit()) {
            continue;
        }
        if !crate::godot_versions::meets_min_version(version) {
            continue;
        }
        if seen.insert(version.to_string()) {
            versions.push(version.to_string());
        }
    }
    versions
}

pub fn available_releases() -> Result<Vec<GodotRelease>, String> {
    let stdout = run_mise(&["ls-remote", GODOT_TOOL])?;
    Ok(parse_remote_versions(&stdout)
        .into_iter()
        .map(|tag| GodotRelease {
            assets: vec![GodotReleaseAsset {
                name: format!("Godot_v{tag}"),
                download_url: String::new(),
                size: 0,
                is_mono: false,
            }],
            tag,
        })
        .collect())
}

fn is_skippable_dir(lower: &str) -> bool {
    matches!(lower, "downloads" | "plugins" | ".git")
}

fn executable_name_matches(lower: &str) -> bool {
    if !lower.starts_with("godot") {
        return false;
    }
    if lower.ends_with(".dll")
        || lower.ends_with(".so")
        || lower.ends_with(".dylib")
        || lower.ends_with(".pdb")
        || lower.ends_with(".json")
        || lower.ends_with(".txt")
    {
        return false;
    }
    if cfg!(windows) {
        return lower.ends_with(".exe") && !lower.contains("console");
    }
    true
}

fn executable_rank(lower: &str) -> u8 {
    if lower.starts_with("godot_v") || lower.starts_with("godot-") {
        0
    } else if lower == GODOT_TOOL {
        1
    } else {
        2
    }
}

fn collect_executables(dir: &Path, depth: usize, out: &mut Vec<(u8, PathBuf)>) {
    if depth > 3 {
        return;
    }
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();
        let lower = name.to_lowercase();
        if path.is_dir() {
            #[cfg(target_os = "macos")]
            if lower.ends_with(".app") {
                if let Ok(bins) = fs::read_dir(path.join("Contents/MacOS")) {
                    for bin in bins.flatten() {
                        let bin_path = bin.path();
                        if bin_path.is_file() {
                            out.push((0, bin_path));
                        }
                    }
                }
                continue;
            }
            if is_skippable_dir(&lower) {
                continue;
            }
            collect_executables(&path, depth + 1, out);
            continue;
        }
        if executable_name_matches(&lower) {
            out.push((executable_rank(&lower), path));
        }
    }
}

pub fn resolve_executable(install_dir: &Path) -> Option<PathBuf> {
    if !install_dir.is_dir() {
        return None;
    }
    let mut candidates: Vec<(u8, PathBuf)> = Vec::new();
    collect_executables(install_dir, 0, &mut candidates);
    candidates.sort_by(|a, b| a.0.cmp(&b.0).then_with(|| a.1.cmp(&b.1)));
    candidates.into_iter().map(|(_, path)| path).next()
}

fn strip_mono(version: &str) -> (&str, bool) {
    let trimmed = version.trim();
    let lower = trimmed.to_lowercase();
    if lower.len() > MONO_SUFFIX.len() && lower.ends_with(MONO_SUFFIX) {
        (&trimmed[..trimmed.len() - MONO_SUFFIX.len()], true)
    } else {
        (trimmed, false)
    }
}

fn number_from_version(base: &str) -> String {
    base.split('-')
        .next()
        .unwrap_or(base)
        .trim()
        .trim_start_matches('v')
        .to_string()
}

fn strip_comment(line: &str) -> &str {
    let mut quote: Option<char> = None;
    for (idx, ch) in line.char_indices() {
        match quote {
            Some(open) => {
                if ch == open {
                    quote = None;
                }
            }
            None => {
                if ch == '"' || ch == '\'' {
                    quote = Some(ch);
                } else if ch == '#' {
                    return &line[..idx];
                }
            }
        }
    }
    line
}

fn trailing_comment(line: &str) -> Option<&str> {
    let stripped = strip_comment(line);
    (stripped.len() < line.len()).then(|| &line[stripped.len()..])
}

fn section_name(line: &str) -> Option<&str> {
    let inner = line.trim().trim_start_matches('[').trim_end_matches(']');
    if inner.is_empty() || !line.trim().starts_with('[') {
        None
    } else {
        Some(inner)
    }
}

fn split_key_value(line: &str) -> Option<(&str, &str)> {
    let mut quote: Option<char> = None;
    for (idx, ch) in line.char_indices() {
        match quote {
            Some(open) => {
                if ch == open {
                    quote = None;
                }
            }
            None => {
                if ch == '"' || ch == '\'' {
                    quote = Some(ch);
                } else if ch == '=' {
                    return Some((&line[..idx], &line[idx + 1..]));
                }
            }
        }
    }
    None
}

fn unquote(value: &str) -> &str {
    let value = value.trim();
    for quote in ['"', '\''] {
        if let Some(inner) = value
            .strip_prefix(quote)
            .and_then(|rest| rest.strip_suffix(quote))
        {
            return inner;
        }
    }
    value
}

fn quoted_strings(value: &str) -> Vec<&str> {
    let mut out = Vec::new();
    let mut rest = value;
    loop {
        let Some(start) = rest.find(['"', '\'']) else {
            break;
        };
        let quote = rest.as_bytes()[start];
        let after = &rest[start + 1..];
        let Some(end) = after.find(quote as char) else {
            break;
        };
        out.push(&after[..end]);
        rest = &after[end + 1..];
    }
    out
}

fn parse_mise_version(value: &str) -> Option<DetectedVersion> {
    let value = value.trim();
    if value.is_empty() {
        return None;
    }
    let (base, is_mono) = strip_mono(value);
    if base.is_empty() {
        return None;
    }
    let number = godotenv::parse_version(base)?;
    Some(DetectedVersion {
        number,
        is_dotnet: is_mono,
    })
}

fn version_from_value(value: &str) -> Option<DetectedVersion> {
    for candidate in quoted_strings(value) {
        if let Some(version) = parse_mise_version(candidate) {
            return Some(version);
        }
    }
    value
        .split(|c: char| c == ',' || c == '}' || c == ']' || c.is_whitespace())
        .map(str::trim)
        .filter(|token| !token.is_empty() && !token.contains('=') && *token != "{")
        .find_map(parse_mise_version)
}

fn parse_mise_toml(content: &str) -> Option<DetectedVersion> {
    let mut in_tools = false;
    let mut tool_section: Option<String> = None;

    for raw in content.lines() {
        let line = strip_comment(raw).trim();
        if line.is_empty() {
            continue;
        }

        if line.starts_with('[') {
            in_tools = false;
            tool_section = None;
            let Some(name) = section_name(line) else {
                continue;
            };
            let name = unquote(name.trim());
            if name == "tools" {
                in_tools = true;
            } else if let Some(rest) = name.strip_prefix("tools.") {
                tool_section = Some(unquote(rest.trim()).to_string());
            }
            continue;
        }

        if in_tools {
            let Some((key, value)) = split_key_value(line) else {
                continue;
            };
            if unquote(key.trim()) == GODOT_TOOL {
                if let Some(version) = version_from_value(value) {
                    return Some(version);
                }
            }
        } else if tool_section.as_deref() == Some(GODOT_TOOL) {
            let Some((key, value)) = split_key_value(line) else {
                continue;
            };
            if unquote(key.trim()) == "version" {
                if let Some(version) = version_from_value(value) {
                    return Some(version);
                }
            }
        }
    }
    None
}

fn parse_tool_versions(content: &str) -> Option<DetectedVersion> {
    for raw in content.lines() {
        let line = strip_comment(raw).trim();
        if line.is_empty() {
            continue;
        }
        let mut tokens = line.split_whitespace();
        if tokens.next() != Some(GODOT_TOOL) {
            continue;
        }
        if let Some(version) = tokens.find_map(parse_mise_version) {
            return Some(version);
        }
    }
    None
}

pub fn config_file(dir: &Path) -> Option<PathBuf> {
    for name in MISE_CONFIG_FILES {
        let path = dir.join(name);
        if path.is_file() {
            return Some(path);
        }
    }
    let tool_versions = dir.join(TOOL_VERSIONS_FILE);
    tool_versions.is_file().then_some(tool_versions)
}

pub fn config_version(dir: &Path) -> Option<DetectedVersion> {
    for name in MISE_CONFIG_FILES {
        let Ok(content) = fs::read_to_string(dir.join(name)) else {
            continue;
        };
        if let Some(version) = parse_mise_toml(&content) {
            return Some(version);
        }
    }
    let content = fs::read_to_string(dir.join(TOOL_VERSIONS_FILE)).ok()?;
    parse_tool_versions(&content)
}

fn is_section_header(line: &str) -> bool {
    strip_comment(line).trim().starts_with('[')
}

fn toml_tools_entry_line(value: &str) -> String {
    format!("{GODOT_TOOL} = \"{value}\"")
}

fn set_toml_tools_entry(content: &str, value: &str) -> String {
    let mut lines: Vec<String> = content.lines().map(str::to_string).collect();
    let header = lines
        .iter()
        .position(|line| section_name(strip_comment(line).trim()) == Some("tools"));

    match header {
        Some(idx) => {
            let end = lines
                .iter()
                .enumerate()
                .skip(idx + 1)
                .find(|(_, line)| is_section_header(line))
                .map(|(i, _)| i)
                .unwrap_or(lines.len());
            let entry = (idx + 1..end).find(|&i| {
                split_key_value(strip_comment(&lines[i]).trim())
                    .map(|(key, _)| unquote(key.trim()) == GODOT_TOOL)
                    .unwrap_or(false)
            });
            match entry {
                Some(i) => {
                    lines[i] = match trailing_comment(&lines[i]) {
                        Some(comment) => {
                            format!("{} {}", toml_tools_entry_line(value), comment.trim())
                        }
                        None => toml_tools_entry_line(value),
                    };
                }
                None => lines.insert(idx + 1, toml_tools_entry_line(value)),
            }
        }
        None => {
            let mut out = content.trim_end().to_string();
            if !out.is_empty() {
                out.push('\n');
            }
            out.push_str("[tools]\n");
            out.push_str(&toml_tools_entry_line(value));
            out.push('\n');
            return out;
        }
    }

    let trailing_newline = content.ends_with('\n');
    let mut out = lines.join("\n");
    if trailing_newline {
        out.push('\n');
    }
    out
}

fn set_tool_versions_entry(content: &str, value: &str) -> String {
    let mut lines: Vec<String> = content.lines().map(str::to_string).collect();
    let position = lines
        .iter()
        .position(|line| strip_comment(line).split_whitespace().next() == Some(GODOT_TOOL));

    match position {
        Some(i) => {
            let suffix = trailing_comment(&lines[i])
                .map(|comment| format!(" {}", comment.trim()))
                .unwrap_or_default();
            lines[i] = format!("{GODOT_TOOL} {value}{suffix}");
        }
        None => lines.push(format!("{GODOT_TOOL} {value}")),
    }

    let mut out = lines.join("\n");
    if !out.is_empty() {
        out.push('\n');
    }
    out
}

pub fn write_pin(project_dir: &Path, tag: &str) -> Result<bool, String> {
    let Some(path) = config_file(project_dir) else {
        return Ok(false);
    };
    let Some(number) = godotenv::parse_installed_tag(tag) else {
        return Ok(false);
    };
    let (_, is_mono) = strip_mono(tag);
    let value = format!(
        "{}{}",
        godotenv::release_string(&number),
        if is_mono { MONO_SUFFIX } else { "" }
    );

    let existing = fs::read_to_string(&path).unwrap_or_default();
    let is_tool_versions = path
        .file_name()
        .and_then(|name| name.to_str())
        .map(|name| name == TOOL_VERSIONS_FILE)
        .unwrap_or(false);
    let updated = if is_tool_versions {
        set_tool_versions_entry(&existing, &value)
    } else {
        set_toml_tools_entry(&existing, &value)
    };

    fs::write(&path, updated).map_err(|e| format!("Couldn't update {}: {e}", path.display()))?;
    Ok(true)
}

pub fn registry_entries(
    installs: &[MiseGodotInstall],
    existing: &[InstalledGodotVersion],
) -> Vec<InstalledGodotVersion> {
    let mut known_paths: Vec<String> = existing
        .iter()
        .map(|v| v.executable_path.clone())
        .collect();
    let mut known_tags: Vec<String> = existing.iter().map(|v| v.tag.clone()).collect();
    let mut added = Vec::new();

    for install in installs {
        let Some(executable) = resolve_executable(Path::new(&install.install_path)) else {
            continue;
        };
        let executable_path = executable.to_string_lossy().to_string();
        if known_paths.contains(&executable_path) {
            continue;
        }

        let (base, is_mono) = strip_mono(&install.version);
        let tag = if is_mono {
            format!("{base}{MONO_SUFFIX}")
        } else {
            base.to_string()
        };
        if known_tags.contains(&tag) {
            continue;
        }

        known_paths.push(executable_path.clone());
        known_tags.push(tag.clone());
        added.push(InstalledGodotVersion {
            tag,
            version: number_from_version(base),
            executable_path,
            is_mono,
            installed_at: chrono::Utc::now().to_rfc3339(),
            custom_name: None,
            install_root: Some(install.install_path.clone()),
            supports_console: false,
            managed_by: Some(MANAGED_BY.to_string()),
        });
    }

    added
}

pub fn sync_installed(app: &AppHandle) -> Result<Vec<InstalledGodotVersion>, String> {
    let installs = list_godot_installs()?;
    if installs.is_empty() {
        return Ok(Vec::new());
    }

    let registry = crate::godot_versions::read_registry(app);
    let mut added: Vec<InstalledGodotVersion> = Vec::new();

    for installed in registry_entries(&installs, &registry) {
        if !crate::godot_versions::register_version(app, installed.clone())? {
            continue;
        }
        added.push(installed);
    }

    for version in &added {
        crate::projects::rebind_projects_to_version(app, version);
        let _ = app.emit("godot-download-complete", &version.tag);
    }

    Ok(added)
}

fn forget_version(app: &AppHandle, tag: &str) {
    let mut registry = crate::godot_versions::read_registry(app);
    let before = registry.len();
    registry.retain(|v| v.tag != tag);
    if registry.len() != before {
        let _ = crate::godot_versions::write_registry(app, &registry);
    }
    crate::current_version::clear_if_current(app, tag);
    crate::current_version::remove_aliases_for_tag(app, tag);
}

#[tauri::command]
pub fn mise_status() -> MiseStatus {
    status()
}

#[tauri::command]
pub fn mise_refresh_status() -> MiseStatus {
    clear_status_cache();
    status()
}

#[tauri::command]
pub async fn mise_sync_godot_versions(
    app: AppHandle,
) -> Result<Vec<InstalledGodotVersion>, String> {
    tokio::task::spawn_blocking(move || sync_installed(&app))
        .await
        .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn mise_install_godot_version(
    app: AppHandle,
    tag: String,
) -> Result<Vec<InstalledGodotVersion>, String> {
    let (base, is_mono) = strip_mono(&tag);
    if is_mono {
        return Err(
            "mise can't install Godot Mono builds. Turn the mise integration off, or install this \
             version with GodotHub's downloader instead."
                .to_string(),
        );
    }
    if base.is_empty() {
        return Err("Invalid Godot version.".to_string());
    }

    let spec = format!("{GODOT_TOOL}@{base}");
    tokio::task::spawn_blocking(move || run_mise(&["install", &spec]).map(|_| ()))
        .await
        .map_err(|e| e.to_string())??;

    sync_installed(&app)
}

#[tauri::command]
pub async fn mise_uninstall_godot_version(app: AppHandle, tag: String) -> Result<(), String> {
    let (base, _) = strip_mono(&tag);
    if base.is_empty() {
        return Err("Invalid Godot version.".to_string());
    }

    let spec = format!("{GODOT_TOOL}@{base}");
    tokio::task::spawn_blocking(move || run_mise(&["uninstall", &spec]).map(|_| ()))
        .await
        .map_err(|e| e.to_string())??;

    forget_version(&app, &tag);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mono(version: &str) -> String {
        format!("{version}{MONO_SUFFIX}")
    }

    fn version_of(content: &str) -> Option<String> {
        parse_mise_toml(content).map(|d| godotenv::release_string(&d.number))
    }

    fn temp_project_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!(
            "godothub-mise-{name}-{}",
            std::process::id()
        ));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).expect("temp project dir");
        dir
    }

    #[test]
    fn pins_into_an_existing_mise_config_and_reads_it_back() {
        let dir = temp_project_dir("pin");
        fs::write(
            dir.join("mise.toml"),
            "[tools]\nnode = \"20\"\ngodot = \"4.3.1-stable\" # old pin\n\n[tasks.build]\nrun = \"godot --headless\"\n",
        )
        .unwrap();

        assert!(write_pin(&dir, "4.5.1-stable").unwrap());
        let updated = fs::read_to_string(dir.join("mise.toml")).unwrap();
        assert!(
            updated.contains("godot = \"4.5.1-stable\" # old pin"),
            "got: {updated}"
        );
        assert!(updated.contains("node = \"20\""), "got: {updated}");
        assert!(updated.contains("[tasks.build]"), "got: {updated}");

        let detected = config_version(&dir).expect("pinned version is readable");
        assert_eq!(godotenv::release_string(&detected.number), "4.5.1-stable");
        assert!(!detected.is_dotnet);

        assert!(write_pin(&dir, &mono("4.5.1-stable")).unwrap());
        let detected = config_version(&dir).expect("pinned mono version is readable");
        assert!(detected.is_dotnet);

        let bare = temp_project_dir("pin-bare");
        assert!(!write_pin(&bare, "4.5.1-stable").unwrap());

        let _ = fs::remove_dir_all(&dir);
        let _ = fs::remove_dir_all(&bare);
    }

    #[test]
    fn pin_version_hands_the_project_to_mise_when_enabled() {
        let dir = temp_project_dir("godotenv-pin");
        fs::write(dir.join("mise.toml"), "[tools]\nnode = \"20\"\n").unwrap();
        fs::write(dir.join(".godotrc"), "4.3.1-stable no-dotnet\n").unwrap();
        let path = dir.to_str().unwrap().to_string();

        godotenv::pin_version(&path, "4.5.1-stable", true).expect("pin into mise.toml");
        assert!(!dir.join(".godotrc").exists(), "stale .godotrc was kept");
        let detected = godotenv::detect_version(&path).expect("version detected from mise.toml");
        assert_eq!(godotenv::release_string(&detected.number), "4.5.1-stable");

        let off = temp_project_dir("godotenv-pin-off");
        fs::write(off.join("mise.toml"), "[tools]\nnode = \"20\"\n").unwrap();
        let off_path = off.to_str().unwrap().to_string();
        godotenv::pin_version(&off_path, "4.4-stable", false).expect("pin into .godotrc");
        assert!(off.join(".godotrc").exists());

        let _ = fs::remove_dir_all(&dir);
        let _ = fs::remove_dir_all(&off);
    }

    #[test]
    fn parses_tools_section() {
        let toml = "[tools]\ngodot = \"4.5.1-stable\"\nnode = \"20\"\n";
        assert_eq!(version_of(toml).as_deref(), Some("4.5.1-stable"));
    }

    #[test]
    fn parses_quoted_key_and_trailing_comment() {
        let toml = "[tools]\n\"godot\" = \"4.4-beta3\" # pinned\n";
        assert_eq!(version_of(toml).as_deref(), Some("4.4-beta3"));
    }

    #[test]
    fn parses_inline_table_and_arrays() {
        let inline = "[tools]\ngodot = { version = \"4.3.1-stable\" }\n";
        assert_eq!(version_of(inline).as_deref(), Some("4.3.1-stable"));
        let array = "[tools]\ngodot = [\"system\", \"4.2-stable\"]\n";
        assert_eq!(version_of(array).as_deref(), Some("4.2-stable"));
    }

    #[test]
    fn parses_tools_godot_section() {
        let toml = "[tools.godot]\nversion = \"4.1.4-stable\"\n";
        assert_eq!(version_of(toml).as_deref(), Some("4.1.4-stable"));
    }

    #[test]
    fn ignores_other_sections_and_unresolvable_versions() {
        let toml = "[alias]\ngodot = \"asdf:mkungla/asdf-godot\"\n[tasks.build]\ngodot = \"4.5.1-stable\"\n";
        assert_eq!(version_of(toml), None);
        let latest = "[tools]\ngodot = \"latest\"\n";
        assert_eq!(version_of(latest), None);
    }

    #[test]
    fn marks_mono_versions_as_dotnet() {
        let toml = format!("[tools]\ngodot = \"{}\"\n", mono("4.5.1-stable"));
        let detected = parse_mise_toml(&toml).expect("parsed");
        assert!(detected.is_dotnet);
        assert_eq!(godotenv::release_string(&detected.number), "4.5.1-stable");
    }

    #[test]
    fn parses_tool_versions() {
        let content = "nodejs 20.10.0\ngodot 4.5.1-stable 4.4-stable\n";
        let detected = parse_tool_versions(content).expect("parsed");
        assert_eq!(godotenv::release_string(&detected.number), "4.5.1-stable");
        assert!(!detected.is_dotnet);
    }

    #[test]
    fn writes_into_existing_tools_section() {
        let toml = "[tools]\nnode = \"20\"\n";
        let updated = set_toml_tools_entry(toml, "4.5.1-stable");
        assert!(updated.contains("godot = \"4.5.1-stable\""));
        assert!(updated.contains("node = \"20\""));
        assert!(updated.contains("[tools]"));
    }

    #[test]
    fn replaces_existing_entry_and_keeps_comments() {
        let toml = "# my tools\n[tools]\ngodot = \"4.3.1-stable\" # keep me\nnode = \"20\"\n";
        let updated = set_toml_tools_entry(toml, "4.5.1-stable");
        assert!(updated.contains("godot = \"4.5.1-stable\" # keep me"));
        assert!(!updated.contains("4.3.1-stable"));
        assert!(updated.contains("# my tools"));
        assert!(updated.contains("node = \"20\""));
    }

    #[test]
    fn appends_section_when_missing() {
        let toml = "[vars]\nfoo = \"bar\"\n";
        let updated = set_toml_tools_entry(toml, "4.5.1-stable");
        assert!(updated.contains("[tools]"));
        assert!(updated.contains("godot = \"4.5.1-stable\""));
        assert!(updated.contains("foo = \"bar\""));
    }

    #[test]
    fn updates_tool_versions_file() {
        let content = "nodejs 20.10.0\n";
        let updated = set_tool_versions_entry(content, "4.5.1-stable");
        assert_eq!(updated, "nodejs 20.10.0\ngodot 4.5.1-stable\n");

        let replaced = set_tool_versions_entry("godot 4.3.1-stable\n", "4.5.1-stable");
        assert_eq!(replaced, "godot 4.5.1-stable\n");
    }

    #[test]
    fn parses_ls_json_array_and_skips_missing_paths() {
        let existing = std::env::temp_dir().to_string_lossy().to_string();
        let missing = format!("{existing}/godothub-mise-missing");
        let raw = serde_json::json!([
            { "version": "4.5.1-stable", "install_path": existing.clone() },
            { "version": "4.4-stable", "install_path": missing },
        ])
        .to_string();
        let installs = parse_ls_json(&raw);
        assert_eq!(installs.len(), 1);
        assert_eq!(installs[0].version, "4.5.1-stable");
        assert_eq!(installs[0].install_path, existing);
    }

    #[test]
    fn parses_ls_json_object_and_skips_uninstalled() {
        let existing = std::env::temp_dir().to_string_lossy().to_string();
        let raw = serde_json::json!({
            "godot": [
                { "version": "4.5.1-stable", "install_path": existing.clone(), "installed": true },
                { "version": "4.4-stable", "install_path": existing.clone(), "installed": false },
            ],
            "node": [{ "version": "20.10.0", "install_path": existing }],
        })
        .to_string();
        let installs = parse_ls_json(&raw);
        assert_eq!(installs.len(), 1);
        assert_eq!(installs[0].version, "4.5.1-stable");
    }

    #[test]
    #[ignore = "requires a local mise install that has godot installed"]
    fn imports_a_real_mise_install() {
        let status = status();
        assert!(
            status.available,
            "mise is not on PATH; point PATH (and MISE_DATA_DIR) at a real mise install"
        );
        let version = status.version.expect("mise --version produced no output");
        assert!(
            !version.contains(' '),
            "the version token should be bare, got {version:?}"
        );

        let installs = list_godot_installs().expect("mise ls failed");
        let install = installs
            .iter()
            .find(|install| !install.version.ends_with(MONO_SUFFIX))
            .expect("no godot install in mise; run `mise install godot@<version>` first");

        let executable = resolve_executable(Path::new(&install.install_path))
            .expect("no Godot executable found inside the mise install dir");
        assert!(executable.is_file());
        let name = executable
            .file_name()
            .map(|n| n.to_string_lossy().to_lowercase())
            .unwrap_or_default();
        assert!(
            !name.contains("console"),
            "picked the console build instead of the editor: {name}"
        );

        let entries = registry_entries(&installs, &[]);
        let entry = entries
            .iter()
            .find(|entry| entry.install_root.as_deref() == Some(install.install_path.as_str()))
            .expect("the mise install was not mapped to a registry entry");
        assert_eq!(entry.managed_by.as_deref(), Some(MANAGED_BY));
        assert_eq!(entry.tag, install.version);
        assert!(!entry.is_mono);
        assert_eq!(entry.version, install.version.split('-').next().unwrap());
        assert_eq!(entry.executable_path, executable.to_string_lossy());

        assert!(registry_entries(&installs, &entries).is_empty());
    }

    #[test]
    fn parses_remote_versions_and_filters_non_releases() {
        let raw = "\n4.4-stable\nv4.3.1-stable\n3.5-stable\nnot-a-version\n4.4-stable\nversion\n";
        assert_eq!(
            parse_remote_versions(raw),
            vec!["4.4-stable", "4.3.1-stable"]
        );

        let pre = "4.5-beta1\n4.4-rc2\n4.4.1-stable\n";
        assert_eq!(parse_remote_versions(pre), vec!["4.5-beta1", "4.4-rc2", "4.4.1-stable"]);
    }

    #[test]
    fn maps_tags_to_mise_versions() {
        assert_eq!(strip_mono("4.5.1-stable"), ("4.5.1-stable", false));
        let mono_tag = mono("4.5.1-stable");
        assert_eq!(strip_mono(&mono_tag), ("4.5.1-stable", true));
        assert_eq!(number_from_version("4.5.1-stable"), "4.5.1");
        assert_eq!(number_from_version("4.5-beta3"), "4.5");
    }
}
