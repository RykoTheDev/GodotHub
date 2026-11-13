use std::io;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

pub const STATE_FILE: &str = "launcher.json";
pub const APP_DIR_PREFIX: &str = "app-";
const PARTIAL_SUFFIX: &str = ".partial";

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct State {
    pub current: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub previous: Option<String>,
    #[serde(default)]
    pub trial: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub failed: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Layout {
    root: PathBuf,
}

pub fn valid_version(version: &str) -> bool {
    !version.is_empty()
        && !version.starts_with('.')
        && version.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '+'))
}

fn invalid(message: impl Into<String>) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, message.into())
}

impl Layout {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn of_app_exe(exe: &Path) -> Option<(Self, String)> {
        let dir = exe.parent()?;
        let version = dir.file_name()?.to_str()?.strip_prefix(APP_DIR_PREFIX)?;
        let root = dir.parent()?;
        (valid_version(version) && root.join(STATE_FILE).is_file()).then(|| (Self::new(root), version.to_string()))
    }

    pub fn root(&self) -> &Path {
        &self.root
    }

    pub fn state_path(&self) -> PathBuf {
        self.root.join(STATE_FILE)
    }

    pub fn app_dir(&self, version: &str) -> PathBuf {
        self.root.join(format!("{APP_DIR_PREFIX}{version}"))
    }

    pub fn read_state(&self) -> io::Result<State> {
        let state: State = serde_json::from_str(&std::fs::read_to_string(self.state_path())?).map_err(|e| invalid(e.to_string()))?;
        if valid_version(&state.current) {
            Ok(state)
        } else {
            Err(invalid(format!("{STATE_FILE} names no valid current version")))
        }
    }

    pub fn write_state(&self, state: &State) -> io::Result<()> {
        let temp = self.root.join(format!("{STATE_FILE}.tmp"));
        std::fs::write(&temp, serde_json::to_vec_pretty(state).map_err(|e| invalid(e.to_string()))?)?;
        std::fs::rename(&temp, self.state_path())
    }

    pub fn stage<F>(&self, version: &str, exe_name: &str, populate: F) -> Result<(), String>
    where
        F: FnOnce(&Path) -> Result<(), String>,
    {
        if !valid_version(version) {
            return Err(format!("Invalid update version {version:?}"));
        }
        let state = self.read_state().map_err(|e| e.to_string())?;
        if state.current == version {
            return Err(format!("Version {version} is already installed"));
        }
        let partial = self.root.join(format!("{APP_DIR_PREFIX}{version}{PARTIAL_SUFFIX}"));
        let target = self.app_dir(version);
        if partial.exists() {
            std::fs::remove_dir_all(&partial).map_err(|e| e.to_string())?;
        }
        std::fs::create_dir_all(&partial).map_err(|e| e.to_string())?;
        let populated = populate(&partial).and_then(|()| {
            if partial.join(exe_name).is_file() {
                Ok(())
            } else {
                Err(format!("The update does not contain {exe_name}"))
            }
        });
        if let Err(error) = populated {
            let _ = std::fs::remove_dir_all(&partial);
            return Err(error);
        }
        if target.exists() {
            std::fs::remove_dir_all(&target).map_err(|e| e.to_string())?;
        }
        std::fs::rename(&partial, &target).map_err(|e| e.to_string())
    }

    pub fn activate(&self, version: &str) -> io::Result<()> {
        if !self.app_dir(version).is_dir() {
            return Err(io::Error::new(io::ErrorKind::NotFound, format!("Version {version} is not staged")));
        }
        let mut state = self.read_state()?;
        if state.current != version {
            state.previous = Some(std::mem::replace(&mut state.current, version.to_string()));
        }
        state.trial = true;
        if state.failed.as_deref() == Some(version) {
            state.failed = None;
        }
        self.write_state(&state)
    }

    pub fn confirm(&self, version: &str) -> io::Result<bool> {
        let mut state = self.read_state()?;
        if state.current != version {
            return Ok(false);
        }
        if state.trial {
            state.trial = false;
            self.write_state(&state)?;
        }
        self.remove_stale(&state);
        Ok(true)
    }

    pub fn rollback_after_failure(&self, version: &str) -> io::Result<Option<String>> {
        let mut state = self.read_state()?;
        if !state.trial || state.current != version {
            return Ok(None);
        }
        let Some(previous) = state.previous.clone().filter(|p| self.app_dir(p).is_dir()) else {
            return Ok(None);
        };
        state.failed = Some(std::mem::replace(&mut state.current, previous.clone()));
        state.previous = None;
        state.trial = false;
        self.write_state(&state)?;
        Ok(Some(previous))
    }

    fn remove_stale(&self, state: &State) {
        let keep: Vec<String> = [Some(&state.current), state.previous.as_ref()]
            .into_iter()
            .flatten()
            .map(|v| format!("{APP_DIR_PREFIX}{v}"))
            .collect();
        let Ok(entries) = std::fs::read_dir(&self.root) else {
            return;
        };
        for entry in entries.flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            let is_app_dir = name.starts_with(APP_DIR_PREFIX) && entry.file_type().is_ok_and(|t| t.is_dir());
            if is_app_dir && !keep.contains(&name) {
                let _ = std::fs::remove_dir_all(entry.path());
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct Root(PathBuf);

    impl Root {
        fn new(name: &str) -> Self {
            let path = std::env::temp_dir().join(format!("godothub-launcher-{name}-{}", std::process::id()));
            let _ = std::fs::remove_dir_all(&path);
            std::fs::create_dir_all(&path).unwrap();
            Self(path)
        }
    }

    impl Drop for Root {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.0);
        }
    }

    const EXE: &str = "GodotHub Beta.exe";

    fn installed(root: &Root, version: &str) -> Layout {
        let layout = Layout::new(&root.0);
        std::fs::create_dir_all(layout.app_dir(version)).unwrap();
        std::fs::write(layout.app_dir(version).join(EXE), version).unwrap();
        layout.write_state(&State { current: version.into(), ..State::default() }).unwrap();
        layout
    }

    fn payload(version: &'static str) -> impl FnOnce(&Path) -> Result<(), String> {
        move |dir| std::fs::write(dir.join(EXE), version).map_err(|e| e.to_string())
    }

    #[test]
    fn versions_must_be_plain_folder_names() {
        assert!(valid_version("0.3.0"));
        assert!(valid_version("1.0.0-beta.2+build.5"));
        for bad in ["", "..", "../x", "a/b", "a\\b", ".hidden", "1 0"] {
            assert!(!valid_version(bad), "{bad}");
        }
    }

    #[test]
    fn the_layout_is_found_from_the_app_executable() {
        let root = Root::new("detect");
        let layout = installed(&root, "0.2.0");
        let exe = layout.app_dir("0.2.0").join(EXE);
        assert_eq!(Layout::of_app_exe(&exe), Some((layout.clone(), "0.2.0".to_string())));
        assert_eq!(Layout::of_app_exe(&root.0.join(EXE)), None);
        std::fs::remove_file(layout.state_path()).unwrap();
        assert_eq!(Layout::of_app_exe(&exe), None);
    }

    #[test]
    fn an_update_is_staged_activated_confirmed_and_old_versions_are_pruned() {
        let root = Root::new("update");
        let layout = installed(&root, "0.1.0");
        layout.stage("0.2.0", EXE, payload("0.2.0")).unwrap();
        layout.activate("0.2.0").unwrap();
        layout.stage("0.3.0", EXE, payload("0.3.0")).unwrap();
        layout.activate("0.3.0").unwrap();
        let state = layout.read_state().unwrap();
        assert_eq!(state, State { current: "0.3.0".into(), previous: Some("0.2.0".into()), trial: true, failed: None });
        assert!(layout.confirm("0.3.0").unwrap());
        assert!(!layout.read_state().unwrap().trial);
        assert!(!layout.app_dir("0.1.0").exists());
        assert!(layout.app_dir("0.2.0").is_dir());
        assert!(layout.app_dir("0.3.0").is_dir());
        assert!(!layout.confirm("0.2.0").unwrap());
    }

    #[test]
    fn a_failed_stage_leaves_nothing_behind() {
        let root = Root::new("bad-stage");
        let layout = installed(&root, "0.1.0");
        let error = layout.stage("0.2.0", EXE, |_| Ok(())).unwrap_err();
        assert!(error.contains(EXE));
        assert!(layout.stage("0.2.0", EXE, |_| Err("broken download".into())).is_err());
        assert!(layout.stage("0.1.0", EXE, payload("0.1.0")).is_err());
        assert!(layout.stage("../escape", EXE, payload("x")).is_err());
        let names: Vec<_> = std::fs::read_dir(&root.0).unwrap().flatten().map(|e| e.file_name()).collect();
        assert_eq!(names.len(), 2);
        assert_eq!(layout.read_state().unwrap().current, "0.1.0");
    }

    #[test]
    fn a_version_that_fails_before_confirming_rolls_back_once() {
        let root = Root::new("rollback");
        let layout = installed(&root, "0.1.0");
        layout.stage("0.2.0", EXE, payload("0.2.0")).unwrap();
        layout.activate("0.2.0").unwrap();
        assert_eq!(layout.rollback_after_failure("0.2.0").unwrap(), Some("0.1.0".into()));
        let state = layout.read_state().unwrap();
        assert_eq!(state, State { current: "0.1.0".into(), previous: None, trial: false, failed: Some("0.2.0".into()) });
        assert_eq!(layout.rollback_after_failure("0.1.0").unwrap(), None);
        layout.activate("0.2.0").unwrap();
        assert_eq!(layout.read_state().unwrap().failed, None);
    }

    #[test]
    fn a_confirmed_version_never_rolls_back() {
        let root = Root::new("confirmed");
        let layout = installed(&root, "0.1.0");
        layout.stage("0.2.0", EXE, payload("0.2.0")).unwrap();
        layout.activate("0.2.0").unwrap();
        layout.confirm("0.2.0").unwrap();
        assert_eq!(layout.rollback_after_failure("0.2.0").unwrap(), None);
        assert_eq!(layout.read_state().unwrap().current, "0.2.0");
    }

    #[test]
    fn rollback_needs_the_previous_folder() {
        let root = Root::new("missing-previous");
        let layout = installed(&root, "0.1.0");
        layout.stage("0.2.0", EXE, payload("0.2.0")).unwrap();
        layout.activate("0.2.0").unwrap();
        std::fs::remove_dir_all(layout.app_dir("0.1.0")).unwrap();
        assert_eq!(layout.rollback_after_failure("0.2.0").unwrap(), None);
        assert_eq!(layout.read_state().unwrap().current, "0.2.0");
    }
}
