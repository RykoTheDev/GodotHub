use crate::models::InstalledGodotVersion;
use crate::project_health::{setting, settings, strings, version, Setting};
use std::fs;
use std::path::{Path, PathBuf};

pub(crate) struct AndroidPreset {
    pub name: String,
    pub gradle_build: bool,
    pub release_keystore: Option<String>,
}

pub(crate) struct AndroidTarget {
    pub presets: Vec<AndroidPreset>,
    pub gradle_template: bool,
    pub hints: Vec<&'static str>,
}

impl AndroidTarget {
    pub fn targeted(&self) -> bool {
        !self.presets.is_empty() || self.gradle_template
    }
}

fn first_string(value: Option<&str>) -> Option<String> {
    value
        .and_then(|v| strings(v).into_iter().next())
        .filter(|v| !v.trim().is_empty())
}

fn is_true(value: Option<&str>) -> bool {
    value.is_some_and(|v| v.trim() == "true")
}

pub(crate) fn android_presets(presets_text: &str) -> Vec<AndroidPreset> {
    let fields = settings(presets_text);
    let mut sections: Vec<&str> = fields
        .iter()
        .filter(|f| f.key == "platform" && f.section.starts_with("preset.") && !f.section.ends_with(".options"))
        .filter(|f| strings(&f.value).first().is_some_and(|p| p == "Android"))
        .map(|f| f.section.as_str())
        .collect();
    sections.dedup();
    sections
        .into_iter()
        .map(|section| {
            let options = format!("{section}.options");
            AndroidPreset {
                name: first_string(setting(&fields, section, "name")).unwrap_or_else(|| section.to_string()),
                gradle_build: is_true(setting(&fields, &options, "gradle_build/use_gradle_build"))
                    || is_true(setting(&fields, &options, "custom_template/use_custom_build")),
                release_keystore: first_string(setting(&fields, &options, "keystore/release")),
            }
        })
        .collect()
}

pub(crate) fn detect(root: &Path, project: &[Setting], presets_text: &str) -> AndroidTarget {
    let mut hints = vec![];
    if first_string(setting(project, "rendering", "renderer/rendering_method")).as_deref() == Some("mobile") {
        hints.push("hint_mobile_renderer");
    }
    if setting(project, "rendering", "renderer/rendering_method.mobile").is_some() {
        hints.push("hint_mobile_renderer_override");
    }
    if is_true(setting(project, "rendering", "textures/vram_compression/import_etc2_astc")) {
        hints.push("hint_etc2_astc");
    }
    if setting(project, "display", "window/handheld/orientation").is_some() {
        hints.push("hint_orientation");
    }
    if is_true(setting(project, "input_devices", "pointing/emulate_touch_from_mouse")) {
        hints.push("hint_touch_emulation");
    }
    if root.join("android").join("plugins").is_dir() {
        hints.push("hint_android_plugins");
    }
    AndroidTarget {
        presets: android_presets(presets_text),
        gradle_template: root.join("android").join("build").join("build.gradle").is_file(),
        hints,
    }
}

#[cfg(windows)]
fn config_dir() -> Option<PathBuf> {
    std::env::var_os("APPDATA").map(|dir| PathBuf::from(dir).join("Godot"))
}

#[cfg(target_os = "macos")]
fn config_dir() -> Option<PathBuf> {
    std::env::var_os("HOME").map(|dir| {
        PathBuf::from(dir)
            .join("Library")
            .join("Application Support")
            .join("Godot")
    })
}

#[cfg(all(unix, not(target_os = "macos")))]
fn config_dir() -> Option<PathBuf> {
    if let Some(config) = std::env::var_os("XDG_CONFIG_HOME").filter(|v| !v.is_empty()) {
        return Some(PathBuf::from(config).join("godot"));
    }
    std::env::var_os("HOME").map(|dir| PathBuf::from(dir).join(".config").join("godot"))
}

fn editor_settings_dir(engine: Option<&InstalledGodotVersion>) -> Option<PathBuf> {
    if let Some(dir) = engine.and_then(|v| Path::new(&v.executable_path).parent()) {
        if dir.join("_sc_").is_file() || dir.join("._sc_").is_file() {
            return Some(dir.join("editor_data"));
        }
    }
    config_dir()
}

fn editor_settings(engine: Option<&InstalledGodotVersion>) -> Vec<Setting> {
    let Some(dir) = editor_settings_dir(engine) else {
        return vec![];
    };
    let Ok(entries) = fs::read_dir(&dir) else {
        return vec![];
    };
    let target = engine.and_then(|v| version(&v.tag));
    let mut candidates: Vec<(u8, std::time::SystemTime, PathBuf)> = entries
        .flatten()
        .filter_map(|entry| {
            let name = entry.file_name().to_string_lossy().to_string();
            let suffix = name.strip_prefix("editor_settings-")?.strip_suffix(".tres")?.to_string();
            let rank = match target {
                Some((major, minor)) if suffix == format!("{major}.{minor}") => 0,
                Some((major, _)) if suffix == major.to_string() => 1,
                Some((major, _)) if suffix.starts_with(&format!("{major}.")) => 2,
                Some(_) => 3,
                None => 2,
            };
            let modified = entry.metadata().and_then(|m| m.modified()).ok()?;
            Some((rank, modified, entry.path()))
        })
        .collect();
    candidates.sort_by(|a, b| a.0.cmp(&b.0).then(b.1.cmp(&a.1)));
    candidates
        .into_iter()
        .next()
        .and_then(|(_, _, path)| fs::read_to_string(path).ok())
        .map(|text| settings(&text))
        .unwrap_or_default()
}

fn editor_path(fields: &[Setting], key: &str) -> Option<PathBuf> {
    fields
        .iter()
        .find(|f| f.key == key)
        .and_then(|f| strings(&f.value).into_iter().next())
        .filter(|v| !v.trim().is_empty())
        .map(PathBuf::from)
}

fn env_path(names: &[&str]) -> Option<PathBuf> {
    names
        .iter()
        .filter_map(std::env::var_os)
        .find(|v| !v.is_empty())
        .map(PathBuf::from)
}

fn exe(name: &str) -> String {
    if cfg!(windows) {
        format!("{name}.exe")
    } else {
        name.to_string()
    }
}

fn java_home_from_path() -> Option<PathBuf> {
    let binary = exe("java");
    std::env::split_paths(&std::env::var_os("PATH")?)
        .map(|dir| dir.join(&binary))
        .find(|candidate| candidate.is_file())
        .and_then(|java| fs::canonicalize(java).ok())
        .and_then(|java| java.parent()?.parent().map(Path::to_path_buf))
}

pub(crate) enum Source {
    Editor,
    Environment,
}

pub(crate) struct Sdk {
    pub path: PathBuf,
    pub source: Source,
    pub missing: Vec<&'static str>,
}

pub(crate) struct Jdk {
    pub path: PathBuf,
    pub source: Source,
    pub major: Option<u32>,
    pub valid: bool,
}

pub(crate) struct Toolchain {
    pub sdk: Option<Sdk>,
    pub jdk: Option<Jdk>,
    pub debug_keystore: Option<PathBuf>,
}

fn java_major(home: &Path) -> Option<u32> {
    let release = fs::read_to_string(home.join("release")).ok()?;
    let raw = release
        .lines()
        .find_map(|line| line.strip_prefix("JAVA_VERSION="))?
        .trim()
        .trim_matches('"');
    let mut parts = raw.split(['.', '_', '+', '-']);
    let first: u32 = parts.next()?.parse().ok()?;
    if first == 1 {
        parts.next()?.parse().ok()
    } else {
        Some(first)
    }
}

pub(crate) fn toolchain(engine: Option<&InstalledGodotVersion>) -> Toolchain {
    let editor = editor_settings(engine);
    let sdk = editor_path(&editor, "export/android/android_sdk_path")
        .map(|p| (p, Source::Editor))
        .or_else(|| env_path(&["ANDROID_HOME", "ANDROID_SDK_ROOT"]).map(|p| (p, Source::Environment)))
        .map(|(path, source)| {
            let mut missing = vec![];
            if !path.is_dir() {
                missing.push("sdk_folder");
            } else {
                if !path.join("platform-tools").join(exe("adb")).is_file() {
                    missing.push("platform_tools");
                }
                let has_build_tools = fs::read_dir(path.join("build-tools"))
                    .map(|mut entries| entries.any(|e| e.is_ok_and(|e| e.path().is_dir())))
                    .unwrap_or(false);
                if !has_build_tools {
                    missing.push("build_tools");
                }
                if !path.join("cmdline-tools").is_dir() {
                    missing.push("cmdline_tools");
                }
            }
            Sdk { path, source, missing }
        });
    let jdk = editor_path(&editor, "export/android/java_sdk_path")
        .map(|p| (p, Source::Editor))
        .or_else(|| env_path(&["JAVA_HOME"]).map(|p| (p, Source::Environment)))
        .or_else(|| java_home_from_path().map(|p| (p, Source::Environment)))
        .map(|(path, source)| Jdk {
            valid: path.join("bin").join(exe("java")).is_file(),
            major: java_major(&path),
            path,
            source,
        });
    Toolchain {
        sdk,
        jdk,
        debug_keystore: editor_path(&editor, "export/android/debug_keystore"),
    }
}

pub(crate) fn required_jdk(engine: Option<&InstalledGodotVersion>) -> u32 {
    match engine.and_then(|v| version(&v.tag)) {
        Some((major, minor)) if major > 4 || (major == 4 && minor >= 2) => 17,
        _ => 11,
    }
}

pub(crate) fn resolve_keystore(root: &Path, value: &str) -> PathBuf {
    match value.strip_prefix("res://") {
        Some(relative) => root.join(relative),
        None => {
            let path = PathBuf::from(value);
            if path.is_absolute() {
                path
            } else {
                root.join(path)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_android_presets_and_their_options() {
        let text = r#"[preset.0]

name="Windows"
platform="Windows Desktop"

[preset.0.options]

[preset.1]

name="Phone"
platform="Android"

[preset.1.options]

gradle_build/use_gradle_build=true
keystore/release="res://release.keystore"
"#;
        let presets = android_presets(text);
        assert_eq!(presets.len(), 1);
        assert_eq!(presets[0].name, "Phone");
        assert!(presets[0].gradle_build);
        assert_eq!(presets[0].release_keystore.as_deref(), Some("res://release.keystore"));
    }

    #[test]
    fn mobile_renderer_is_only_a_hint() {
        let project = settings(
            "[rendering]\n\nrenderer/rendering_method=\"mobile\"\ntextures/vram_compression/import_etc2_astc=true\n",
        );
        let target = detect(Path::new("/nonexistent"), &project, "");
        assert!(!target.targeted());
        assert_eq!(target.hints, vec!["hint_mobile_renderer", "hint_etc2_astc"]);
    }

    #[test]
    fn reads_java_major_from_release_file() {
        let dir = std::env::temp_dir().join(format!("godothub-jdk-{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        fs::write(dir.join("release"), "JAVA_VERSION=\"17.0.9\"\n").unwrap();
        assert_eq!(java_major(&dir), Some(17));
        fs::write(dir.join("release"), "JAVA_VERSION=\"1.8.0_392\"\n").unwrap();
        assert_eq!(java_major(&dir), Some(8));
        let _ = fs::remove_dir_all(&dir);
    }
}
