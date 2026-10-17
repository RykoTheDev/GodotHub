use super::*;
use crate::project_identity;
use crate::project_metadata::{LEGACY_FILES as IDENTITY_FILES, METADATA_DIR};
fn marker(dir: &Path) -> PathBuf {
    project_identity::identity_file(&dir.to_string_lossy())
}
use std::path::PathBuf;

struct Fixture(PathBuf);

impl Fixture {
    fn new(name: &str) -> Self {
        let path = std::env::temp_dir().join(format!(
            "godothub-template-copy-{name}-{}",
            std::process::id()
        ));
        fs::create_dir_all(&path).unwrap();
        Self(path)
    }

    fn dir(&self, name: &str) -> PathBuf {
        let path = self.0.join(name);
        fs::create_dir_all(&path).unwrap();
        path
    }
}

impl Drop for Fixture {
    fn drop(&mut self) {
        fs::remove_dir_all(&self.0).unwrap();
    }
}

fn add_identity(dir: &Path, id: &str) {
    assert!(project_identity::write_project_identity(
        &dir.to_string_lossy(),
        id,
        Some("Games")
    ));
    for name in &IDENTITY_FILES[1..] {
        fs::write(dir.join(name), "stale identity backup").unwrap();
    }
}

fn assert_no_identity(dir: &Path) {
    assert!(!dir.join(METADATA_DIR).exists());
    for name in IDENTITY_FILES {
        assert!(
            !dir.join(name).exists(),
            "identity leaked: {}",
            dir.join(name).display()
        );
    }
}

#[test]
fn copying_excludes_identity_and_residue_at_every_depth_without_touching_source() {
    let f = Fixture::new("exclude");
    let source = f.dir("source");
    let nested = f.dir("source/nested");
    add_identity(&source, "source-id");
    add_identity(&nested, "nested-id");
    for name in [
        "project.godot",
        "scene.tscn",
        ".gitignore",
        ".godothub.json.example",
    ] {
        fs::write(source.join(name), name).unwrap();
    }
    let dest = f.0.join("template");
    copy_dir(&source, &dest, &[]).unwrap();
    assert_no_identity(&dest);
    assert_no_identity(&dest.join("nested"));
    for name in [
        "project.godot",
        "scene.tscn",
        ".gitignore",
        ".godothub.json.example",
    ] {
        assert_eq!(
            fs::read(source.join(name)).unwrap(),
            fs::read(dest.join(name)).unwrap()
        );
    }
    assert_eq!(
        project_identity::read_project_identity(&source.to_string_lossy()).as_deref(),
        Some("source-id")
    );
    assert_eq!(
        project_identity::read_project_identity(&nested.to_string_lossy()).as_deref(),
        Some("nested-id")
    );
    assert!(source.join(IDENTITY_FILES[1]).exists());
}

#[test]
fn older_templates_with_root_metadata_are_also_safe_to_copy() {
    let f = Fixture::new("legacy-template");
    let source = f.dir("legacy-template");
    for name in IDENTITY_FILES {
        fs::write(source.join(name), "legacy data").unwrap();
    }
    let dest = f.0.join("new-project");
    copy_dir(&source, &dest, &[]).unwrap();
    assert_no_identity(&dest);
    for name in IDENTITY_FILES {
        assert_eq!(
            fs::read_to_string(source.join(name)).unwrap(),
            "legacy data"
        );
    }
}

#[test]
fn old_templates_and_duplicates_cannot_propagate_source_identity_or_editor_cache() {
    let f = Fixture::new("fresh-projects");
    let template = f.dir("old-template");
    add_identity(&template, "original-id");
    fs::write(template.join("project.godot"), "project content").unwrap();
    for cache in [".git", ".godot"] {
        let dir = f.dir(&format!("old-template/{cache}"));
        fs::write(dir.join("cache"), "source cache").unwrap();
    }
    for id in ["new-project-a", "new-project-b"] {
        let dest = f.0.join(id);
        copy_dir(&template, &dest, &[".git", ".godot"]).unwrap();
        assert_no_identity(&dest);
        assert!(!dest.join(".git").exists());
        assert!(!dest.join(".godot").exists());
        assert!(project_identity::ensure_project_identity(
            &dest.to_string_lossy(),
            id,
            None
        ));
        assert_eq!(
            project_identity::read_project_identity(&dest.to_string_lossy()).as_deref(),
            Some(id)
        );
        assert_eq!(
            project_identity::read_project_category(&dest.to_string_lossy()),
            None
        );
    }
    assert_eq!(
        project_identity::read_project_identity(&template.to_string_lossy()).as_deref(),
        Some("original-id")
    );
}

#[test]
fn syncing_removes_stale_identities_even_when_source_still_contains_them() {
    let f = Fixture::new("sync");
    let source = f.dir("source");
    let nested = f.dir("source/nested");
    let dest = f.dir("template");
    let dest_nested = f.dir("template/nested");
    for dir in [&source, &nested, &dest, &dest_nested] {
        add_identity(dir, "old-id");
    }
    fs::write(source.join("scene.tscn"), "updated scene").unwrap();
    fs::write(dest.join("scene.tscn"), "old scene").unwrap();
    fs::write(dest.join("removed.tscn"), "stale asset").unwrap();
    fs::write(dest.join("template.json"), "template metadata").unwrap();
    mirror_dir(&source, &dest, &[]).unwrap();
    assert_no_identity(&dest);
    assert_no_identity(&dest_nested);
    assert_eq!(
        fs::read_to_string(dest.join("scene.tscn")).unwrap(),
        "updated scene"
    );
    assert_eq!(
        fs::read_to_string(dest.join("template.json")).unwrap(),
        "template metadata"
    );
    assert!(!dest.join("removed.tscn").exists());
    assert!(marker(&source).exists());
}

#[test]
fn cleaning_managed_template_removes_old_markers() {
    let f = Fixture::new("existing-destination");
    let source = f.dir("source");
    let dest = f.dir("template");
    add_identity(&dest, "stale-id");
    remove_identity_files(&dest).unwrap();
    copy_dir(&source, &dest, &[]).unwrap();
    assert_no_identity(&dest);
}

#[test]
fn asset_merge_preserves_project_and_nested_identities_and_configuration() {
    let f = Fixture::new("asset-merge");
    let source = f.dir("download");
    let dest = f.dir("project");
    let source_nested = f.dir("download/addons/test");
    let dest_nested = f.dir("project/addons/test");
    add_identity(&source, "download-id");
    add_identity(&source_nested, "download-nested-id");
    add_identity(&dest, "project-id");
    add_identity(&dest_nested, "nested-project-id");
    let original_marker = fs::read(marker(&dest)).unwrap();
    let original_nested_marker = fs::read(marker(&dest_nested)).unwrap();
    fs::write(source.join("project.godot"), "download settings").unwrap();
    fs::write(dest.join("project.godot"), "my project settings").unwrap();
    fs::write(source_nested.join("plugin.gd"), "new plugin").unwrap();
    merge_asset_into(&source, &dest).unwrap();
    assert_eq!(fs::read(marker(&dest)).unwrap(), original_marker);
    assert_eq!(
        fs::read(marker(&dest_nested)).unwrap(),
        original_nested_marker
    );
    assert_eq!(
        fs::read_to_string(dest.join("project.godot")).unwrap(),
        "my project settings"
    );
    assert_eq!(
        fs::read_to_string(dest_nested.join("plugin.gd")).unwrap(),
        "new plugin"
    );
    let fresh = f.0.join("new-project");
    merge_asset_into(&source, &fresh).unwrap();
    assert_no_identity(&fresh);
    assert_no_identity(&fresh.join("addons/test"));
    assert_eq!(
        fs::read_to_string(fresh.join("project.godot")).unwrap(),
        "download settings"
    );
}

#[test]
fn overlapping_folders_are_rejected_before_identity_or_assets_are_changed() {
    let f = Fixture::new("overlap");
    let source = f.dir("source");
    add_identity(&source, "source-id");
    fs::write(source.join("scene.tscn"), "keep").unwrap();
    for operation in [copy_dir, mirror_dir] {
        assert!(operation(&source, &source, &[]).is_err());
        assert!(operation(&source, &source.join("nested-destination"), &[]).is_err());
        assert!(operation(&source, &f.0, &[]).is_err());
    }
    assert_eq!(
        project_identity::read_project_identity(&source.to_string_lossy()).as_deref(),
        Some("source-id")
    );
    assert_eq!(
        fs::read_to_string(source.join("scene.tscn")).unwrap(),
        "keep"
    );
}
