use crate::models::InstalledGodotVersion;
use serde::Serialize;
use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::process::Command;
use tauri::AppHandle;

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[derive(Serialize)]
pub struct DiscoveredProject {
    pub path: String,
    pub name: String,
    pub favorite: bool,
    pub engine: Option<String>,
}

#[derive(Serialize)]
pub struct DiscoveredInstall {
    pub path: String,
    pub name: String,
    pub source: String,
    pub version: Option<String>,
}

fn godot_data_dirs() -> Vec<PathBuf> {
    let mut bases: Vec<PathBuf> = Vec::new();
    for base in [dirs::data_dir(), dirs::config_dir()].into_iter().flatten() {
        bases.push(base.join("Godot"));
        bases.push(base.join("godot"));
    }
    bases
}

fn projects_cfg_candidates() -> Vec<PathBuf> {
    godot_data_dirs()
        .into_iter()
        .map(|b| b.join("projects.cfg"))
        .filter(|p| p.is_file())
        .collect()
}

fn godot3_settings_candidates() -> Vec<PathBuf> {
    godot_data_dirs()
        .into_iter()
        .map(|b| b.join("editor_settings-3.tres"))
        .filter(|p| p.is_file())
        .collect()
}

fn parse_godot3_projects(text: &str) -> Vec<(String, bool)> {
    let mut out: Vec<(String, bool)> = Vec::new();
    for line in text.lines() {
        let t = line.trim();
        let (favorite, rest) = if let Some(rest) = t.strip_prefix("favorite_projects/") {
            (true, rest)
        } else if let Some(rest) = t.strip_prefix("projects/") {
            (false, rest)
        } else {
            continue;
        };
        let Some((_, value)) = rest.split_once('=') else {
            continue;
        };
        let path = value.trim().trim_matches('"').to_string();
        if path.is_empty() {
            continue;
        }
        if let Some(existing) = out.iter_mut().find(|(p, _)| *p == path) {
            existing.1 |= favorite;
        } else {
            out.push((path, favorite));
        }
    }
    out
}

pub(crate) struct ProjectEngine {
    pub major: u32,
    pub minor: Option<u32>,
    pub is_dotnet: bool,
}

impl ProjectEngine {
    fn label(&self) -> String {
        match self.minor {
            Some(minor) => format!("{}.{}", self.major, minor),
            None => format!("{}.x", self.major),
        }
    }
}

fn has_csproj(dir: &Path) -> bool {
    std::fs::read_dir(dir)
        .map(|entries| {
            entries.flatten().any(|e| {
                e.path()
                    .extension()
                    .map(|ext| ext.eq_ignore_ascii_case("csproj"))
                    .unwrap_or(false)
            })
        })
        .unwrap_or(false)
}

pub(crate) fn project_engine(project_dir: &Path) -> Option<ProjectEngine> {
    let text = std::fs::read_to_string(project_dir.join("project.godot")).ok()?;
    let fields = crate::project_health::settings(&text);
    let is_dotnet = has_csproj(project_dir)
        || crate::project_health::setting(&fields, "dotnet", "project/assembly_name").is_some();
    let feature = crate::project_health::setting(&fields, "application", "config/features")
        .into_iter()
        .flat_map(crate::project_health::strings)
        .find_map(|s| crate::project_health::version(&s));
    if let Some((major, minor)) = feature {
        return Some(ProjectEngine {
            major,
            minor: Some(minor),
            is_dotnet,
        });
    }
    let format = crate::project_health::setting(&fields, "", "config_version")?
        .trim()
        .parse::<u32>()
        .ok()?;
    let major = match format {
        4 => 3,
        5 => 4,
        _ => return None,
    };
    Some(ProjectEngine {
        major,
        minor: None,
        is_dotnet,
    })
}

pub(crate) fn pick_engine_version<'a>(
    engine: &ProjectEngine,
    installed: &'a [InstalledGodotVersion],
) -> Option<&'a InstalledGodotVersion> {
    installed
        .iter()
        .filter_map(|v| crate::godotenv::parse_installed_tag(&v.tag).map(|n| (v, n)))
        .filter(|(_, n)| n.major == engine.major && engine.minor.map_or(true, |m| n.minor == m))
        .max_by_key(|(v, n)| {
            (
                v.is_mono == engine.is_dotnet,
                n.label == "stable",
                n.minor,
                n.patch,
                n.label_num,
            )
        })
        .map(|(v, _)| v)
}

pub(crate) fn engine_match_tag(app: &AppHandle, project_path: &str) -> Option<String> {
    let engine = project_engine(Path::new(project_path))?;
    let installed = crate::godot_versions::read_registry(app);
    pick_engine_version(&engine, &installed).map(|v| v.tag.clone())
}

pub(crate) fn bind_unbound_projects(app: &AppHandle) -> usize {
    let installed = crate::godot_versions::read_registry(app);
    if installed.is_empty() {
        return 0;
    }
    let bindings: Vec<(String, String)> = crate::projects::read_projects(app)
        .into_iter()
        .filter(|p| p.godot_version.is_empty())
        .filter_map(|p| {
            let engine = project_engine(Path::new(&p.path))?;
            let v = pick_engine_version(&engine, &installed)?;
            Some((p.id, v.tag.clone()))
        })
        .collect();
    if bindings.is_empty() {
        return 0;
    }
    let mut changed = 0;
    let result = crate::projects::update_projects(app, |projects| {
        for p in projects.iter_mut().filter(|p| p.godot_version.is_empty()) {
            if let Some((_, tag)) = bindings.iter().find(|(id, _)| *id == p.id) {
                p.godot_version = tag.clone();
                changed += 1;
            }
        }
    });
    if result.is_err() {
        return 0;
    }
    changed
}

fn parse_projects_cfg(text: &str) -> Vec<(String, bool)> {
    let mut out: Vec<(String, bool)> = Vec::new();
    let mut current: Option<(String, bool)> = None;
    for line in text.lines() {
        let t = line.trim();
        if t.starts_with('[') && t.ends_with(']') && t.len() >= 2 {
            if let Some(c) = current.take() {
                out.push(c);
            }
            current = Some((t[1..t.len() - 1].trim().to_string(), false));
        } else if let Some((_, fav)) = current.as_mut() {
            if let Some(rest) = t.strip_prefix("favorite") {
                let v = rest.trim_start_matches([' ', '=']).trim();
                *fav = v.eq_ignore_ascii_case("true");
            }
        }
    }
    if let Some(c) = current.take() {
        out.push(c);
    }
    out
}

fn read_project_name(project_file: &Path) -> Option<String> {
    let text = std::fs::read_to_string(project_file).ok()?;
    for line in text.lines() {
        if let Some(value) = line.trim().strip_prefix("config/name=") {
            let name = value.trim().trim_matches('"').to_string();
            if !name.is_empty() {
                return Some(name);
            }
        }
    }
    None
}

fn folder_name(path: &Path) -> String {
    path.file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| path.to_string_lossy().to_string())
}

#[tauri::command]
pub async fn scan_godot_recent_projects(app: AppHandle) -> Result<Vec<DiscoveredProject>, String> {
    tokio::task::spawn_blocking(move || {
        let known: BTreeSet<PathBuf> = crate::projects::read_projects(&app)
            .into_iter()
            .filter_map(|p| std::fs::canonicalize(&p.path).ok())
            .collect();

        let mut seen: BTreeSet<PathBuf> = BTreeSet::new();
        let mut out: Vec<DiscoveredProject> = Vec::new();

        let mut entries: Vec<(String, bool)> = Vec::new();
        for cfg in projects_cfg_candidates() {
            if let Ok(text) = std::fs::read_to_string(&cfg) {
                entries.extend(parse_projects_cfg(&text));
            }
        }
        for settings in godot3_settings_candidates() {
            if let Ok(text) = std::fs::read_to_string(&settings) {
                entries.extend(parse_godot3_projects(&text));
            }
        }

        {
            for (raw_path, favorite) in entries {
                let dir = PathBuf::from(&raw_path);
                if !dir.join("project.godot").is_file() {
                    continue;
                }
                let canon = std::fs::canonicalize(&dir).unwrap_or_else(|_| dir.clone());
                if known.contains(&canon) || !seen.insert(canon) {
                    continue;
                }
                let name = read_project_name(&dir.join("project.godot"))
                    .unwrap_or_else(|| folder_name(&dir));
                out.push(DiscoveredProject {
                    path: dir.to_string_lossy().to_string(),
                    name,
                    favorite,
                    engine: project_engine(&dir).map(|e| e.label()),
                });
            }
        }

        out.sort_by(|a, b| {
            b.favorite
                .cmp(&a.favorite)
                .then_with(|| a.name.to_lowercase().cmp(&b.name.to_lowercase()))
        });
        Ok(out)
    })
    .await
    .map_err(|e| e.to_string())?
}

fn is_godot_executable_name(name: &str) -> bool {
    let lower = name.to_lowercase();
    if !lower.contains("godot") {
        return false;
    }
    #[cfg(target_os = "windows")]
    {
        lower.ends_with(".exe")
    }
    #[cfg(not(target_os = "windows"))]
    {
        !lower.ends_with(".txt")
            && !lower.ends_with(".md")
            && !lower.ends_with(".cfg")
            && !lower.ends_with(".json")
    }
}

#[cfg(unix)]
fn is_executable(path: &Path) -> bool {
    use std::os::unix::fs::PermissionsExt;
    std::fs::metadata(path)
        .map(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

#[cfg(not(unix))]
fn is_executable(path: &Path) -> bool {
    path.is_file()
}

fn path_godot_binaries() -> Vec<PathBuf> {
    let mut found = Vec::new();
    let Some(path_var) = std::env::var_os("PATH") else {
        return found;
    };
    #[cfg(target_os = "windows")]
    let names = ["godot.exe", "godot4.exe", "godot3.exe", "Godot.exe"];
    #[cfg(not(target_os = "windows"))]
    let names = ["godot", "godot4", "godot3", "godot-mono", "Godot"];

    for dir in std::env::split_paths(&path_var) {
        for name in names {
            let candidate = dir.join(name);
            if is_executable(&candidate) {
                found.push(candidate);
            }
        }
    }
    found
}

fn steam_roots() -> Vec<PathBuf> {
    let mut roots: Vec<PathBuf> = Vec::new();

    #[cfg(target_os = "windows")]
    {
        use winreg::enums::HKEY_CURRENT_USER;
        use winreg::RegKey;
        if let Ok(key) = RegKey::predef(HKEY_CURRENT_USER).open_subkey("Software\\Valve\\Steam") {
            if let Ok(p) = key.get_value::<String, _>("SteamPath") {
                if !p.is_empty() {
                    roots.push(PathBuf::from(p));
                }
            }
        }
        for p in [r"C:\Program Files (x86)\Steam", r"C:\Program Files\Steam"] {
            roots.push(PathBuf::from(p));
        }
    }
    #[cfg(target_os = "macos")]
    {
        if let Some(home) = dirs::home_dir() {
            roots.push(home.join("Library/Application Support/Steam"));
        }
    }
    #[cfg(all(unix, not(target_os = "macos")))]
    {
        if let Some(home) = dirs::home_dir() {
            roots.push(home.join(".steam/steam"));
            roots.push(home.join(".local/share/Steam"));
            roots.push(home.join(".var/app/com.valvesoftware.Steam/.local/share/Steam"));
        }
    }

    roots.retain(|r| r.is_dir());
    roots
}

/// Parse `libraryfolders.vdf` for the `"path"` of each Steam library.
fn steam_library_paths(steam_root: &Path) -> Vec<PathBuf> {
    let mut libs = vec![steam_root.to_path_buf()];
    let vdf = steam_root.join("steamapps").join("libraryfolders.vdf");
    if let Ok(text) = std::fs::read_to_string(&vdf) {
        for line in text.lines() {
            let t = line.trim();
            // lines look like:  "path"   "D:\\SteamLibrary"
            if let Some(rest) = t.strip_prefix("\"path\"") {
                let val = rest.trim().trim_matches('"').replace("\\\\", "\\");
                if !val.is_empty() {
                    libs.push(PathBuf::from(val));
                }
            }
        }
    }
    libs
}

fn steam_godot_binaries() -> Vec<PathBuf> {
    let mut found = Vec::new();
    let mut seen_dirs: BTreeSet<PathBuf> = BTreeSet::new();
    for root in steam_roots() {
        for lib in steam_library_paths(&root) {
            let godot_dir = lib.join("steamapps").join("common").join("Godot Engine");
            if !godot_dir.is_dir() || !seen_dirs.insert(godot_dir.clone()) {
                continue;
            }
            if let Ok(entries) = std::fs::read_dir(&godot_dir) {
                for entry in entries.flatten() {
                    let p = entry.path();
                    let name = entry.file_name().to_string_lossy().to_string();
                    #[cfg(target_os = "macos")]
                    {
                        // Steam ships Godot.app on macOS.
                        if name.eq_ignore_ascii_case("Godot.app") {
                            let bin = p.join("Contents/MacOS/Godot");
                            if bin.is_file() {
                                found.push(bin);
                            }
                            continue;
                        }
                    }
                    if is_godot_executable_name(&name) && is_executable(&p) {
                        found.push(p);
                    }
                }
            }
        }
    }
    found
}

#[tauri::command]
pub async fn detect_godot_installs(app: AppHandle) -> Result<Vec<DiscoveredInstall>, String> {
    tokio::task::spawn_blocking(move || {
        let registered: BTreeSet<PathBuf> =
            crate::godot_versions::list_installed_godot_versions(app.clone())
                .unwrap_or_default()
                .into_iter()
                .filter_map(|v| std::fs::canonicalize(&v.executable_path).ok())
                .collect();

        let mut seen: BTreeSet<PathBuf> = BTreeSet::new();
        let mut out: Vec<DiscoveredInstall> = Vec::new();

        let mut add = |path: PathBuf, source: &str| {
            if is_console_build(&path) {
                return;
            }
            let canon = std::fs::canonicalize(&path).unwrap_or_else(|_| path.clone());
            if registered.contains(&canon) || !seen.insert(canon) {
                return;
            }
            let name = path
                .parent()
                .and_then(|d| d.file_name())
                .map(|n| n.to_string_lossy().to_string())
                .filter(|n| !n.is_empty())
                .unwrap_or_else(|| folder_name(&path));
            let version = probe_version(&path).map(|(tag, _, _)| tag);
            out.push(DiscoveredInstall {
                path: path.to_string_lossy().to_string(),
                name,
                source: source.to_string(),
                version,
            });
        };

        for p in path_godot_binaries() {
            add(p, "PATH");
        }
        for p in steam_godot_binaries() {
            add(p, "Steam");
        }
        Ok(out)
    })
    .await
    .map_err(|e| e.to_string())?
}

fn is_console_build(path: &Path) -> bool {
    path.file_stem()
        .map(|s| s.to_string_lossy().to_lowercase().ends_with("_console"))
        .unwrap_or(false)
}

fn parse_version_line(line: &str) -> Option<(String, String, bool)> {
    let lower = line.trim().to_lowercase();
    if lower.is_empty() {
        return None;
    }
    let is_mono = lower.contains("mono");
    let mut nums: Vec<&str> = Vec::new();
    let mut status: Option<&str> = None;
    for part in lower.split('.') {
        if !part.is_empty() && part.chars().all(|c| c.is_ascii_digit()) {
            nums.push(part);
        } else {
            status = Some(part);
            break;
        }
    }
    if nums.is_empty() {
        return None;
    }
    let version = nums.join(".");
    let status = status.filter(|s| !s.is_empty()).unwrap_or("stable");
    let tag = if is_mono {
        format!("{version}-{status}-mono")
    } else {
        format!("{version}-{status}")
    };
    Some((tag, version, is_mono))
}

fn probe_version(exe: &Path) -> Option<(String, String, bool)> {
    if let Some(name) = exe.file_name().and_then(|n| n.to_str()) {
        if let Some(tag) = crate::godot_versions::parse_godot_tag_from_filename(name) {
            let is_mono = tag.ends_with("-mono");
            let version = tag
                .trim_end_matches("-mono")
                .split('-')
                .next()
                .unwrap_or("")
                .to_string();
            if !version.is_empty() {
                return Some((tag, version, is_mono));
            }
        }
    }

    let mut cmd = Command::new(exe);
    cmd.arg("--version");
    #[cfg(target_os = "windows")]
    cmd.creation_flags(crate::terminal::CREATE_NO_WINDOW);
    let output = cmd.output().ok()?;
    let text = String::from_utf8_lossy(&output.stdout);
    let line = text.lines().map(str::trim).rfind(|l| !l.is_empty())?;
    parse_version_line(line)
}

#[tauri::command]
pub async fn import_detected_install(
    app: AppHandle,
    path: String,
) -> Result<InstalledGodotVersion, String> {
    tokio::task::spawn_blocking(move || {
        let exe = PathBuf::from(&path);
        if !exe.is_file() {
            return Err("That Godot executable no longer exists.".to_string());
        }
        let (tag, version, is_mono) =
            probe_version(&exe).ok_or("Couldn't read the Godot version from that executable.")?;

        let installed = InstalledGodotVersion {
            tag,
            version,
            executable_path: exe.to_string_lossy().to_string(),
            is_mono,
            installed_at: chrono::Utc::now().to_rfc3339(),
            custom_name: None,
            install_root: None,
            supports_console: false,
            managed_by: Some("external".to_string()),
        };
        let added = crate::godot_versions::register_version(&app, installed.clone())?;
        if !added {
            return Err("That Godot version is already in your list.".into());
        }
        crate::projects::rebind_projects_to_version(&app, &installed);
        bind_unbound_projects(&app);
        Ok(installed)
    })
    .await
    .map_err(|e| e.to_string())?
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_project_sections_and_favorites() {
        let cfg = "[/home/me/Game A]\nfavorite=true\n\n[/home/me/Game B]\nfavorite=false\n";
        let parsed = parse_projects_cfg(cfg);
        assert_eq!(parsed.len(), 2);
        assert_eq!(parsed[0], ("/home/me/Game A".to_string(), true));
        assert_eq!(parsed[1], ("/home/me/Game B".to_string(), false));
    }

    #[test]
    fn reads_project_name_from_godot_file() {
        let dir = std::env::temp_dir().join("gh_discovery_test");
        let _ = std::fs::create_dir_all(&dir);
        let file = dir.join("project.godot");
        std::fs::write(&file, "[application]\nconfig/name=\"Space Game\"\n").unwrap();
        assert_eq!(read_project_name(&file).as_deref(), Some("Space Game"));
    }

    #[test]
    fn parses_version_lines() {
        assert_eq!(
            parse_version_line("4.3.stable.official.77dcf97d8"),
            Some(("4.3-stable".to_string(), "4.3".to_string(), false))
        );
        assert_eq!(
            parse_version_line("4.2.2.stable.mono.official.abc"),
            Some(("4.2.2-stable-mono".to_string(), "4.2.2".to_string(), true))
        );
        assert_eq!(parse_version_line(""), None);
    }

    #[test]
    fn godot_executable_name_matching() {
        #[cfg(target_os = "windows")]
        {
            assert!(is_godot_executable_name("Godot_v4.3-stable_win64.exe"));
            assert!(!is_godot_executable_name("godot.txt"));
        }
        #[cfg(not(target_os = "windows"))]
        {
            assert!(is_godot_executable_name("godot"));
            assert!(!is_godot_executable_name("godot.txt"));
        }
    }

    #[test]
    fn parses_godot3_project_list() {
        let tres = "[resource]\nprojects/C____games_old = \"C:/games/old\"\nfavorite_projects/C____games_old = \"C:/games/old\"\nprojects/D____jam = \"D:/jam\"\ntext_editor/theme = \"Default\"\n";
        let parsed = parse_godot3_projects(tres);
        assert_eq!(parsed.len(), 2);
        assert_eq!(parsed[0], ("C:/games/old".to_string(), true));
        assert_eq!(parsed[1], ("D:/jam".to_string(), false));
    }

    #[test]
    fn console_builds_are_skipped() {
        assert!(is_console_build(Path::new("Godot_v4.3-stable_win64_console.exe")));
        assert!(!is_console_build(Path::new("Godot_v4.3-stable_win64.exe")));
    }

    fn installed(tag: &str, is_mono: bool) -> InstalledGodotVersion {
        InstalledGodotVersion {
            tag: tag.into(),
            version: String::new(),
            executable_path: String::new(),
            is_mono,
            installed_at: String::new(),
            custom_name: None,
            install_root: None,
            supports_console: false,
            managed_by: None,
        }
    }

    #[test]
    fn engine_reads_features_and_picks_best_install() {
        let dir = std::env::temp_dir().join(format!("gh_engine_test_{}", std::process::id()));
        let _ = std::fs::create_dir_all(&dir);
        std::fs::write(
            dir.join("project.godot"),
            "config_version=5\n[application]\nconfig/features=PackedStringArray(\"4.3\", \"Forward Plus\")\n",
        )
        .unwrap();
        let engine = project_engine(&dir).expect("engine detected");
        assert_eq!(engine.label(), "4.3");
        assert!(!engine.is_dotnet);

        let list = vec![
            installed("4.2-stable", false),
            installed("4.3-beta2", false),
            installed("4.3.1-stable-mono", true),
            installed("4.3-stable", false),
            installed("4.3.1-stable", false),
        ];
        assert_eq!(pick_engine_version(&engine, &list).map(|v| v.tag.as_str()), Some("4.3.1-stable"));

        std::fs::write(dir.join("Game.csproj"), "<Project />").unwrap();
        let dotnet = project_engine(&dir).unwrap();
        assert_eq!(pick_engine_version(&dotnet, &list).map(|v| v.tag.as_str()), Some("4.3.1-stable-mono"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn godot3_format_without_features_matches_major() {
        let dir = std::env::temp_dir().join(format!("gh_engine3_test_{}", std::process::id()));
        let _ = std::fs::create_dir_all(&dir);
        std::fs::write(dir.join("project.godot"), "config_version=4\n[application]\nconfig/name=\"Old\"\n").unwrap();
        let engine = project_engine(&dir).unwrap();
        assert_eq!(engine.label(), "3.x");
        let list = vec![installed("3.5.2-stable", false), installed("3.6-stable", false), installed("4.3-stable", false)];
        assert_eq!(pick_engine_version(&engine, &list).map(|v| v.tag.as_str()), Some("3.6-stable"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn steam_library_parse() {
        let dir = std::env::temp_dir().join("gh_steam_test");
        let apps = dir.join("steamapps");
        let _ = std::fs::create_dir_all(&apps);
        std::fs::write(
            apps.join("libraryfolders.vdf"),
            "\"libraryfolders\"\n{\n\t\"0\"\n\t{\n\t\t\"path\"\t\t\"/games/lib\"\n\t}\n}\n",
        )
        .unwrap();
        let libs = steam_library_paths(&dir);
        assert!(libs.iter().any(|p| p.ends_with("lib")));
    }
}
