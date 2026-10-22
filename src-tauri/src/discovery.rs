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
}

#[derive(Serialize)]
pub struct DiscoveredInstall {
    pub path: String,
    pub name: String,
    pub source: String,
}

fn projects_cfg_candidates() -> Vec<PathBuf> {
    let mut bases: Vec<PathBuf> = Vec::new();
    for base in [dirs::data_dir(), dirs::config_dir()].into_iter().flatten() {
        bases.push(base.join("Godot"));
        bases.push(base.join("godot"));
    }
    bases
        .into_iter()
        .map(|b| b.join("projects.cfg"))
        .filter(|p| p.is_file())
        .collect()
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

        for cfg in projects_cfg_candidates() {
            let Ok(text) = std::fs::read_to_string(&cfg) else {
                continue;
            };
            for (raw_path, favorite) in parse_projects_cfg(&text) {
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
    let names = ["godot.exe", "godot4.exe", "Godot.exe", "godot_console.exe"];
    #[cfg(not(target_os = "windows"))]
    let names = ["godot", "godot4", "Godot"];

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
            out.push(DiscoveredInstall {
                path: path.to_string_lossy().to_string(),
                name,
                source: source.to_string(),
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
