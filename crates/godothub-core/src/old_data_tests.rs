use std::path::{Path, PathBuf};
use std::sync::Arc;

use crate::{AppHandle, Channel, Paths};

const MAIN: &str = "6a0c4d1e-2b7f-4f3a-9d55-0e8b1c2a7f41";
const JAMS: &str = "9f1c2a7e-0d4b-4c55-9a77-2b8f3e1d6a10";

struct NoEvents;

impl crate::EventSink for NoEvents {
    fn emit(&self, _event: &str, _payload: &serde_json::value::RawValue) {}
}

struct NoHost;

impl crate::Host for NoHost {
    fn show_main_window(&self) {}
    fn hide_main_window(&self) {}
    fn exit(&self, _code: i32) {}
    fn refresh_menus(&self) {}
}

struct OldData {
    root: PathBuf,
    app: AppHandle,
}

impl Drop for OldData {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.root);
    }
}

fn copy_fixture(from: &Path, to: &Path, root: &str) {
    std::fs::create_dir_all(to).unwrap();
    for entry in std::fs::read_dir(from).unwrap().flatten() {
        let target = to.join(entry.file_name());
        if entry.path().is_dir() {
            copy_fixture(&entry.path(), &target, root);
        } else if entry.path().extension().is_some_and(|e| e == "json") {
            let text = std::fs::read_to_string(entry.path()).unwrap().replace("__ROOT__", root);
            std::fs::write(target, text).unwrap();
        } else {
            std::fs::copy(entry.path(), target).unwrap();
        }
    }
}

fn start(version: &str) -> OldData {
    let fixture = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/old-data").join(version);
    let root = std::env::temp_dir().join(format!("godothub-old-data-{version}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&root);
    let root_text = root.to_string_lossy().replace('\\', "/");
    copy_fixture(&fixture, &root, &root_text);
    let data = root.join("Ryko.GodotHub");
    let app = AppHandle::new(Channel::Stable, Paths::at(data.clone(), data, root.join("cache")), Arc::new(NoEvents), Arc::new(NoHost));
    crate::startup::initialize(&app);
    crate::templates::consolidate_legacy_templates(&app);
    OldData { root, app }
}

impl OldData {
    fn data(&self) -> PathBuf {
        self.root.join("Ryko.GodotHub")
    }

    fn workspace(&self, id: &str) -> PathBuf {
        crate::workspace::workspace_dir_in(&self.data(), id)
    }

    fn templates(&self) -> Vec<crate::models::ProjectTemplate> {
        tokio::runtime::Runtime::new().unwrap().block_on(crate::templates::list_templates(self.app.clone())).unwrap()
    }

    fn assert_workspaces_and_projects(&self) {
        let state = crate::workspace::read_state_in(&self.data());
        assert_eq!(state.active_id, JAMS);
        let names: Vec<_> = state.workspaces.iter().map(|w| w.name.as_str()).collect();
        assert_eq!(names, ["Main", "Game Jams"]);
        let jams = crate::projects::read_projects_from(&self.workspace(JAMS));
        let space = jams.iter().find(|p| p.id == "p-space").expect("Space Shooter kept");
        assert_eq!(space.name, "Space Shooter");
        assert!(space.pinned);
        assert_eq!(space.category.as_deref(), Some("c-jams"));
        assert!(space.path.ends_with("/projects/space-shooter"));
        assert_eq!(jams.iter().find(|p| p.id == "p-jam").map(|p| p.godot_version.as_str()), Some("4.3-stable"));
        assert_eq!(crate::projects::read_projects_from(&self.workspace(MAIN)).len(), 1);
        let categories = crate::categories::read_categories_from(&self.workspace(JAMS));
        assert_eq!(categories.iter().map(|c| c.name.as_str()).collect::<Vec<_>>()[0], "Jam Games");
    }

    fn assert_old_identifier_moved(&self) {
        let old = self.root.join("com.ryko.godothub");
        assert!(!old.exists() || std::fs::read_dir(&old).unwrap().next().is_none(), "old data folder still has files");
        assert!(self.data().join("workspaces.json").is_file());
    }
}

#[test]
fn first_public_release_v0_5_0() {
    let old = start("v0.5.0");
    old.assert_old_identifier_moved();
    old.assert_workspaces_and_projects();
    let space = crate::projects::read_projects_from(&old.workspace(JAMS)).into_iter().find(|p| p.id == "p-space").unwrap();
    assert_eq!(space.launch_arguments, "--verbose");

    let jams = crate::settings::read_settings_from(&old.workspace(JAMS));
    assert_eq!(jams.accent_color, "#3fb27f");
    assert_eq!(jams.theme_mode, "light");
    assert_eq!(jams.font_scale, 1.15);
    assert!(jams.minimize_to_tray);
    assert_eq!(jams.command_palette_keybind, "k");
    assert_eq!(jams.tray_recent_projects_count, 8);
    assert_eq!(jams.animation_intensity, "none", "Reduce motion must carry over");
    assert_eq!(crate::settings::read_settings_from(&old.workspace(MAIN)).animation_intensity, "full");

    let versions = crate::godot_versions::read_registry_at(&old.data());
    assert_eq!(versions.len(), 2);
    assert_eq!(versions.iter().find(|v| v.tag == "4.2.2-stable").and_then(|v| v.custom_name.as_deref()), Some("Main 4.2"));

    let templates = old.templates();
    let platformer = templates.iter().find(|t| t.id == "platformer").expect("shared template moved into the workspace");
    assert_eq!(platformer.name, "Platformer Starter");
    assert!(Path::new(&platformer.path).join("project.godot").is_file(), "{}", platformer.path);
    assert!(!old.data().join("templates").exists());
}

#[test]
fn per_workspace_versions_and_templates_v1_2_5() {
    let old = start("v1.2.5");
    old.assert_old_identifier_moved();
    old.assert_workspaces_and_projects();

    let jams = crate::settings::read_settings_from(&old.workspace(JAMS));
    assert_eq!(jams.language, "fr-FR");
    assert!(!jams.show_scrollbars);
    assert!(jams.use_os_decorations);
    assert_eq!(jams.directory_naming_convention, "kebab-case");
    assert_eq!(jams.animation_intensity, "none");

    let versions = crate::godot_versions::read_registry_at(&old.data());
    let mut tags: Vec<_> = versions.iter().map(|v| (v.tag.as_str(), v.is_mono)).collect();
    tags.sort();
    assert_eq!(tags, [("4.1.4-stable", false), ("4.2.2-stable", false), ("4.3-stable", true)], "per-workspace lists merged without duplicates");

    let kit = old.templates().into_iter().find(|t| t.id == "jam-kit").expect("workspace template kept");
    assert!(kit.path.contains("Ryko.GodotHub"), "template path follows the new data folder: {}", kit.path);
    assert!(Path::new(&kit.path).join("project.godot").is_file());
}

#[test]
fn last_release_on_the_old_identifier_v1_3_8() {
    let old = start("v1.3.8");
    old.assert_old_identifier_moved();
    old.assert_workspaces_and_projects();
    let jams = crate::settings::read_settings_from(&old.workspace(JAMS));
    assert_eq!(jams.animation_intensity, "subtle");
    assert_eq!(jams.language, "ja-JP");
    assert_eq!(crate::godot_versions::read_registry_at(&old.data()).len(), 2);
    let kit = old.templates().into_iter().find(|t| t.id == "jam-kit").unwrap();
    assert!(kit.path.contains("Ryko.GodotHub"), "{}", kit.path);
}

#[test]
fn new_identifier_with_tags_and_folders_v1_4_8() {
    let old = start("v1.4.8");
    old.assert_workspaces_and_projects();
    let jams = crate::projects::read_projects_from(&old.workspace(JAMS));
    let space = jams.iter().find(|p| p.id == "p-space").unwrap();
    assert_eq!(space.tags, ["jam", "shooter"]);
    assert_eq!(space.total_time_seconds, 5400);
    let categories = crate::categories::read_categories_from(&old.workspace(JAMS));
    let archive = categories.iter().find(|c| c.id == "c-old").unwrap();
    assert!(archive.hidden);
    assert_eq!(categories[0].folders.len(), 1);
    let settings = crate::settings::read_settings_from(&old.workspace(JAMS));
    assert_eq!(settings.language, "pt-BR");
    assert_eq!(settings.animation_intensity, "none");
    assert!(!old.root.join("com.ryko.godothub").exists());
}
