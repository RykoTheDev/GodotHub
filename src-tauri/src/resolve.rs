use std::path::{Path, PathBuf};

use crate::models::InstalledGodotVersion;

pub const APP_IDENTIFIER: &str = "Ryko.GodotHub";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EngineSource {
    Pin,
    Bound,
    Current,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ResolveError {
    PinnedMissing(String),
    None,
}

#[derive(Debug, Clone)]
pub struct Engine {
    pub tag: String,
    pub executable_path: String,
    pub source: EngineSource,
}

pub fn data_dir() -> Option<PathBuf> {
    dirs::data_dir().map(|dir| dir.join(APP_IDENTIFIER))
}

pub fn active_workspace_dir(base: &Path) -> PathBuf {
    let state = crate::workspace::read_state_in(base);
    crate::workspace::workspace_dir_in(base, &state.active_id)
}

pub fn find_project_root(start: &Path) -> Option<PathBuf> {
    let mut dir = Some(start);
    while let Some(current) = dir {
        if current.join("project.godot").is_file() {
            return Some(current.to_path_buf());
        }
        dir = current.parent();
    }
    None
}

pub fn choose_version(
    pin: Option<&str>,
    bound: Option<&str>,
    current: Option<&str>,
    is_installed: impl Fn(&str) -> bool,
) -> Result<(String, EngineSource), ResolveError> {
    let candidates = [
        (pin, EngineSource::Pin),
        (bound, EngineSource::Bound),
        (current, EngineSource::Current),
    ];
    for (value, source) in candidates {
        let Some(tag) = value.map(str::trim).filter(|tag| !tag.is_empty()) else {
            continue;
        };
        if is_installed(tag) {
            return Ok((tag.to_string(), source));
        }
        if source == EngineSource::Pin {
            return Err(ResolveError::PinnedMissing(tag.to_string()));
        }
    }
    Err(ResolveError::None)
}

pub fn resolve_engine(
    base: &Path,
    workspace_dir: &Path,
    project_root: &Path,
) -> Result<Engine, String> {
    let registry = crate::godot_versions::read_registry_at(base);
    let project_path = project_root.to_string_lossy().to_string();

    let pin = crate::project_identity::read_project_version(&project_path);
    let bound = crate::projects::read_projects_from(workspace_dir)
        .into_iter()
        .find(|project| crate::projects::same_path(&project.path, &project_path))
        .map(|project| project.godot_version)
        .filter(|tag| !tag.trim().is_empty());
    let current = crate::current_version::read_current_tag_at(base);

    match choose_version(pin.as_deref(), bound.as_deref(), current.as_deref(), |tag| {
        registry.iter().any(|version| version.tag == tag)
    }) {
        Ok((tag, source)) => {
            let version = registry
                .iter()
                .find(|version| version.tag == tag)
                .ok_or_else(|| format!("Version {tag} is registered without an executable"))?;
            let exe = version.executable_path.clone();
            if !Path::new(&exe).is_file() {
                return Err(format!(
                    "The Godot executable for {tag} is missing at {exe}. Reinstall it or update the pin."
                ));
            }
            Ok(Engine {
                tag,
                executable_path: exe,
                source,
            })
        }
        Err(ResolveError::PinnedMissing(tag)) => Err(format!(
            "This project pins Godot {tag}, which is not installed. Run `godothub install {tag}` or change the pin."
        )),
        Err(ResolveError::None) => Err(
            "No Godot version resolves for this project. Pin one from the app, set a current version, or bind one in the project card."
                .into(),
        ),
    }
}

pub fn installed_sorted(base: &Path) -> Vec<InstalledGodotVersion> {
    let mut list = crate::godot_versions::read_registry_at(base);
    list.sort_by(|a, b| b.tag.cmp(&a.tag));
    list
}

#[cfg(test)]
mod tests {
    use super::*;

    fn installed<'a>(tags: &'a [&'a str]) -> impl Fn(&str) -> bool + 'a {
        move |tag: &str| tags.contains(&tag)
    }

    #[test]
    fn pin_wins_when_installed() {
        let got = choose_version(
            Some("4.4-stable"),
            Some("4.3-stable"),
            Some("4.2-stable"),
            installed(&["4.4-stable", "4.3-stable", "4.2-stable"]),
        );
        assert_eq!(got, Ok(("4.4-stable".to_string(), EngineSource::Pin)));
    }

    #[test]
    fn a_pinned_but_missing_version_never_falls_through() {
        let got = choose_version(
            Some("4.4-stable"),
            Some("4.3-stable"),
            Some("4.2-stable"),
            installed(&["4.3-stable", "4.2-stable"]),
        );
        assert_eq!(got, Err(ResolveError::PinnedMissing("4.4-stable".to_string())));
    }

    #[test]
    fn bound_is_used_when_there_is_no_pin() {
        let got = choose_version(
            None,
            Some("4.3-stable"),
            Some("4.2-stable"),
            installed(&["4.3-stable", "4.2-stable"]),
        );
        assert_eq!(got, Ok(("4.3-stable".to_string(), EngineSource::Bound)));
    }

    #[test]
    fn current_is_used_when_bound_is_absent_or_uninstalled() {
        let no_bound = choose_version(
            None,
            None,
            Some("4.2-stable"),
            installed(&["4.2-stable"]),
        );
        assert_eq!(no_bound, Ok(("4.2-stable".to_string(), EngineSource::Current)));

        let bound_gone = choose_version(
            None,
            Some("4.3-stable"),
            Some("4.2-stable"),
            installed(&["4.2-stable"]),
        );
        assert_eq!(bound_gone, Ok(("4.2-stable".to_string(), EngineSource::Current)));
    }

    #[test]
    fn blank_candidates_are_ignored() {
        let got = choose_version(
            Some("   "),
            Some(""),
            Some("4.2-stable"),
            installed(&["4.2-stable"]),
        );
        assert_eq!(got, Ok(("4.2-stable".to_string(), EngineSource::Current)));
    }

    #[test]
    fn nothing_resolves_to_none() {
        let got = choose_version(None, None, None, installed(&["4.2-stable"]));
        assert_eq!(got, Err(ResolveError::None));
    }

    #[test]
    fn find_project_root_walks_up() {
        let tmp = std::env::temp_dir().join(format!("ghcli-root-{}", std::process::id()));
        let nested = tmp.join("a").join("b");
        std::fs::create_dir_all(&nested).unwrap();
        std::fs::write(tmp.join("project.godot"), b"[application]\n").unwrap();
        assert_eq!(find_project_root(&nested).as_deref(), Some(tmp.as_path()));
        assert!(find_project_root(std::env::temp_dir().as_path()).is_none()
            || !std::env::temp_dir().join("project.godot").exists());
        let _ = std::fs::remove_dir_all(&tmp);
    }
}
