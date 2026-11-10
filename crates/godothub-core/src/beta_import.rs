use std::fs;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::Paths;

const SKIPPED_DATA_ENTRIES: [&str; 2] = ["godot-versions", "bin"];

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct BetaImport {
    pub imported: bool,
    pub copied_files: u64,
    pub shared_versions_dir: Option<String>,
}

struct Dirs {
    stable_data: PathBuf,
    stable_config: PathBuf,
    beta_data: PathBuf,
    beta_config: PathBuf,
}

fn dirs(stable: &Paths, beta: &Paths) -> Result<Dirs, String> {
    let dirs = Dirs {
        stable_data: stable.app_data_dir().map_err(|e| e.to_string())?,
        stable_config: stable.app_config_dir().map_err(|e| e.to_string())?,
        beta_data: beta.app_data_dir().map_err(|e| e.to_string())?,
        beta_config: beta.app_config_dir().map_err(|e| e.to_string())?,
    };
    let stable_dirs = [&dirs.stable_data, &dirs.stable_config];
    if stable_dirs.contains(&&dirs.beta_data) || stable_dirs.contains(&&dirs.beta_config) {
        return Err("The beta data folders must differ from the stable ones".into());
    }
    Ok(dirs)
}

pub fn import_on_first_launch(stable: &Paths, beta: &Paths) -> Result<BetaImport, String> {
    let dirs = dirs(stable, beta)?;
    if dirs.beta_data.exists() || (!dirs.stable_data.exists() && !dirs.stable_config.exists()) {
        return Ok(BetaImport::default());
    }
    copy_all(&dirs)
}

pub fn reimport(stable: &Paths, beta: &Paths) -> Result<BetaImport, String> {
    let dirs = dirs(stable, beta)?;
    for dir in [&dirs.beta_data, &dirs.beta_config] {
        if dir.exists() {
            fs::remove_dir_all(dir).map_err(|e| format!("Could not clear {}: {e}", dir.display()))?;
        }
    }
    if !dirs.stable_data.exists() && !dirs.stable_config.exists() {
        return Ok(BetaImport::default());
    }
    copy_all(&dirs)
}

fn copy_all(dirs: &Dirs) -> Result<BetaImport, String> {
    let mut copied = 0;
    let staged_data = staging(&dirs.beta_data);
    let _ = fs::remove_dir_all(&staged_data);
    if dirs.stable_data.exists() {
        copied += copy_tree(&dirs.stable_data, &staged_data, &SKIPPED_DATA_ENTRIES)?;
    } else {
        fs::create_dir_all(&staged_data).map_err(|e| e.to_string())?;
    }

    let separate_config = dirs.stable_config != dirs.stable_data && dirs.beta_config != dirs.beta_data;
    if separate_config && dirs.stable_config.exists() {
        let staged_config = staging(&dirs.beta_config);
        let _ = fs::remove_dir_all(&staged_config);
        copied += copy_tree(&dirs.stable_config, &staged_config, &[])?;
        promote(&staged_config, &dirs.beta_config)?;
    }

    let versions_dir = dirs.stable_data.join("godot-versions");
    let shared = share_versions_dir(&staged_data, &versions_dir)?;
    promote(&staged_data, &dirs.beta_data)?;

    Ok(BetaImport {
        imported: true,
        copied_files: copied,
        shared_versions_dir: shared.then(|| versions_dir.to_string_lossy().into_owned()),
    })
}

fn staging(target: &Path) -> PathBuf {
    let name = target
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_default();
    target.with_file_name(format!("{name}.importing"))
}

fn promote(staged: &Path, target: &Path) -> Result<(), String> {
    if let Some(parent) = target.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    fs::rename(staged, target).map_err(|e| format!("Could not finish the import into {}: {e}", target.display()))
}

fn copy_tree(from: &Path, to: &Path, skip: &[&str]) -> Result<u64, String> {
    fs::create_dir_all(to).map_err(|e| format!("Could not create {}: {e}", to.display()))?;
    let mut copied = 0;
    let entries = fs::read_dir(from).map_err(|e| format!("Could not read {}: {e}", from.display()))?;
    for entry in entries {
        let entry = entry.map_err(|e| e.to_string())?;
        let name = entry.file_name();
        if skip.iter().any(|s| name == *s) {
            continue;
        }
        let source = entry.path();
        let target = to.join(&name);
        let kind = entry.file_type().map_err(|e| e.to_string())?;
        if kind.is_dir() {
            copied += copy_tree(&source, &target, &[])?;
        } else if kind.is_file() {
            fs::copy(&source, &target).map_err(|e| format!("Could not copy {}: {e}", source.display()))?;
            copied += 1;
        }
    }
    Ok(copied)
}

fn share_versions_dir(beta_data: &Path, versions_dir: &Path) -> Result<bool, String> {
    let state = crate::workspace::read_state_in(beta_data);
    let shared = versions_dir.to_string_lossy().into_owned();
    let mut changed = false;
    for workspace in &state.workspaces {
        let dir = crate::workspace::workspace_dir_in(beta_data, &workspace.id);
        if !dir.join("settings.json").exists() {
            continue;
        }
        let mut settings = crate::settings::read_settings_from(&dir);
        if settings.download_dir.as_deref().is_some_and(|d| !d.trim().is_empty()) {
            continue;
        }
        settings.download_dir = Some(shared.clone());
        crate::settings::write_settings_to(&dir, &settings).map_err(|e| e.to_string())?;
        changed = true;
    }
    Ok(changed)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::BTreeMap;

    struct Layout {
        root: PathBuf,
        stable: Paths,
        beta: Paths,
    }

    impl Layout {
        fn new(name: &str, separate_config: bool) -> Self {
            let root = std::env::temp_dir().join(format!("godothub-beta-import-{name}-{}", uuid::Uuid::new_v4()));
            let (stable_config, beta_config) = if separate_config {
                (root.join("config").join("Ryko.GodotHub"), root.join("config").join("Ryko.GodotHub.Beta"))
            } else {
                (root.join("data").join("Ryko.GodotHub"), root.join("data").join("Ryko.GodotHub.Beta"))
            };
            Self {
                stable: Paths::at(root.join("data").join("Ryko.GodotHub"), stable_config, root.join("cache").join("Ryko.GodotHub")),
                beta: Paths::at(root.join("data").join("Ryko.GodotHub.Beta"), beta_config, root.join("cache").join("Ryko.GodotHub.Beta")),
                root,
            }
        }

        fn stable_data(&self) -> PathBuf {
            self.stable.app_data_dir().unwrap()
        }

        fn beta_data(&self) -> PathBuf {
            self.beta.app_data_dir().unwrap()
        }

        fn seed_stable(&self, download_dir: Option<&str>) -> String {
            let data = self.stable_data();
            fs::create_dir_all(data.join("godot-versions").join("4.4.1-stable")).unwrap();
            fs::write(data.join("godot-versions").join("4.4.1-stable").join("godot.exe"), b"engine").unwrap();
            fs::create_dir_all(data.join("bin")).unwrap();
            fs::write(data.join("bin").join("godothub.cmd"), b"shim").unwrap();
            fs::write(data.join("godot-versions.json"), b"[]").unwrap();
            fs::write(data.join("git-credentials"), b"secret").unwrap();
            fs::create_dir_all(self.stable.app_cache_dir().unwrap()).unwrap();
            fs::write(self.stable.app_cache_dir().unwrap().join("cache.bin"), b"cache").unwrap();
            let state = crate::workspace::read_state_in(&data);
            let workspace = crate::workspace::workspace_dir_in(&data, &state.active_id);
            let settings = crate::models::AppSettings {
                download_dir: download_dir.map(str::to_string),
                ..Default::default()
            };
            crate::settings::write_settings_to(&workspace, &settings).unwrap();
            state.active_id
        }

        fn snapshot(&self) -> BTreeMap<PathBuf, Vec<u8>> {
            fn walk(dir: &Path, out: &mut BTreeMap<PathBuf, Vec<u8>>) {
                if let Ok(entries) = fs::read_dir(dir) {
                    for entry in entries.flatten() {
                        let path = entry.path();
                        if path.is_dir() {
                            walk(&path, out);
                        } else {
                            out.insert(path.clone(), fs::read(&path).unwrap());
                        }
                    }
                }
            }
            let mut out = BTreeMap::new();
            walk(&self.stable_data(), &mut out);
            walk(&self.stable.app_config_dir().unwrap(), &mut out);
            walk(&self.stable.app_cache_dir().unwrap(), &mut out);
            out
        }
    }

    impl Drop for Layout {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }

    #[test]
    fn first_launch_copies_stable_data_without_versions_bin_or_cache() {
        let layout = Layout::new("fresh", false);
        let workspace_id = layout.seed_stable(None);
        let before = layout.snapshot();

        let result = import_on_first_launch(&layout.stable, &layout.beta).unwrap();

        assert!(result.imported);
        let beta = layout.beta_data();
        assert!(beta.join("godot-versions.json").is_file());
        assert!(beta.join("git-credentials").is_file());
        assert!(!beta.join("godot-versions").exists());
        assert!(!beta.join("bin").exists());
        assert!(!layout.beta.app_cache_dir().unwrap().exists());
        assert!(!staging(&beta).exists());
        let versions = layout.stable_data().join("godot-versions").to_string_lossy().into_owned();
        assert_eq!(result.shared_versions_dir.as_deref(), Some(versions.as_str()));
        let beta_settings =
            crate::settings::read_settings_from(&crate::workspace::workspace_dir_in(&beta, &workspace_id));
        assert_eq!(beta_settings.download_dir.as_deref(), Some(versions.as_str()));
        assert_eq!(layout.snapshot(), before);
    }

    #[test]
    fn a_custom_download_dir_is_kept() {
        let layout = Layout::new("custom", false);
        let workspace_id = layout.seed_stable(Some("D:/Godot"));
        let result = import_on_first_launch(&layout.stable, &layout.beta).unwrap();
        assert!(result.imported);
        assert_eq!(result.shared_versions_dir, None);
        let settings = crate::settings::read_settings_from(&crate::workspace::workspace_dir_in(
            &layout.beta_data(),
            &workspace_id,
        ));
        assert_eq!(settings.download_dir.as_deref(), Some("D:/Godot"));
    }

    #[test]
    fn an_existing_beta_dir_is_left_untouched() {
        let layout = Layout::new("existing", false);
        layout.seed_stable(None);
        fs::create_dir_all(layout.beta_data()).unwrap();
        fs::write(layout.beta_data().join("mine.txt"), b"beta").unwrap();

        let result = import_on_first_launch(&layout.stable, &layout.beta).unwrap();

        assert!(!result.imported);
        let entries: Vec<_> = fs::read_dir(layout.beta_data()).unwrap().flatten().map(|e| e.file_name()).collect();
        assert_eq!(entries, vec![std::ffi::OsString::from("mine.txt")]);
    }

    #[test]
    fn nothing_happens_without_stable_data() {
        let layout = Layout::new("empty", false);
        let result = import_on_first_launch(&layout.stable, &layout.beta).unwrap();
        assert!(!result.imported);
        assert!(!layout.beta_data().exists());
    }

    #[test]
    fn a_separate_config_dir_is_copied_too() {
        let layout = Layout::new("config", true);
        layout.seed_stable(None);
        let stable_config = layout.stable.app_config_dir().unwrap();
        fs::create_dir_all(&stable_config).unwrap();
        fs::write(stable_config.join(".window-state.json"), b"{}").unwrap();
        let before = layout.snapshot();

        import_on_first_launch(&layout.stable, &layout.beta).unwrap();

        assert!(layout.beta.app_config_dir().unwrap().join(".window-state.json").is_file());
        assert_eq!(layout.snapshot(), before);
    }

    #[test]
    fn reimport_replaces_the_beta_copy_and_keeps_stable_intact() {
        let layout = Layout::new("reimport", false);
        layout.seed_stable(None);
        import_on_first_launch(&layout.stable, &layout.beta).unwrap();
        fs::write(layout.beta_data().join("beta-only.txt"), b"x").unwrap();
        fs::write(layout.stable_data().join("new-in-stable.txt"), b"y").unwrap();
        let before = layout.snapshot();

        let result = reimport(&layout.stable, &layout.beta).unwrap();

        assert!(result.imported);
        assert!(!layout.beta_data().join("beta-only.txt").exists());
        assert!(layout.beta_data().join("new-in-stable.txt").is_file());
        assert_eq!(layout.snapshot(), before);
    }

    #[test]
    fn refuses_when_beta_and_stable_dirs_match() {
        let layout = Layout::new("same", false);
        layout.seed_stable(None);
        assert!(import_on_first_launch(&layout.stable, &layout.stable).is_err());
        assert!(reimport(&layout.stable, &layout.stable).is_err());
    }
}
