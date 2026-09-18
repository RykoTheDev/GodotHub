use super::{migrate_app_data, IdentifierMigration};
use std::fs;
use std::path::{Path, PathBuf};

fn temp_dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!(
        "godothub-{name}-{}-{:?}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or_default()
    ));
    fs::create_dir_all(&dir).expect("failed to create temp dir");
    dir
}

fn file_names(dir: &Path) -> Vec<String> {
    let mut out: Vec<String> = fs::read_dir(dir)
        .expect("failed to read dir")
        .flatten()
        .map(|e| e.file_name().to_string_lossy().to_string())
        .collect();
    out.sort();
    out
}

#[test]
fn moves_everything_when_nothing_collides() {
    let base = temp_dir("migrate-clean");
    let old = base.join("old");
    let new = base.join("new");
    fs::create_dir_all(&old).expect("failed to create old dir");
    fs::create_dir_all(&new).expect("failed to create new dir");
    fs::write(old.join("settings.json"), "{}").expect("write failed");
    fs::write(old.join("projects.json"), "[]").expect("write failed");

    let result = migrate_app_data(&new, &old);

    assert_eq!(result.moved, 2);
    assert_eq!(result.kept, 0);
    assert_eq!(result.failed, 0);
    assert_eq!(file_names(&new), vec!["projects.json", "settings.json"]);
    assert!(
        file_names(&old).is_empty(),
        "the old folder should be drained"
    );

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn a_collision_keeps_the_old_copy_instead_of_destroying_it() {
    let base = temp_dir("migrate-collision");
    let old = base.join("old");
    let new = base.join("new");
    fs::create_dir_all(&old).expect("failed to create old dir");
    fs::create_dir_all(&new).expect("failed to create new dir");
    fs::write(old.join("settings.json"), "{\"old\":true}").expect("write failed");
    fs::write(new.join("settings.json"), "{\"new\":true}").expect("write failed");

    let result = migrate_app_data(&new, &old);

    assert_eq!(result.moved, 0);
    assert_eq!(result.kept, 1);
    assert_eq!(result.failed, 0);
    assert_eq!(file_names(&new), vec!["settings.json", "settings.json.legacy"]);
    assert_eq!(
        fs::read_to_string(new.join("settings.json")).expect("read failed"),
        "{\"new\":true}",
        "the current data must win"
    );
    assert_eq!(
        fs::read_to_string(new.join("settings.json.legacy")).expect("read failed"),
        "{\"old\":true}",
        "the older copy must survive"
    );

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn a_second_collision_does_not_overwrite_the_kept_copy() {
    let base = temp_dir("migrate-collision-twice");
    let old = base.join("old");
    let new = base.join("new");
    fs::create_dir_all(&old).expect("failed to create old dir");
    fs::create_dir_all(&new).expect("failed to create new dir");
    fs::write(new.join("settings.json"), "{\"new\":true}").expect("write failed");
    fs::write(new.join("settings.json.legacy"), "{\"first\":true}").expect("write failed");
    fs::write(old.join("settings.json"), "{\"second\":true}").expect("write failed");

    let result = migrate_app_data(&new, &old);

    assert_eq!(result.kept, 1);
    assert_eq!(
        file_names(&new),
        vec![
            "settings.json",
            "settings.json.legacy",
            "settings.json.legacy-1"
        ]
    );
    assert_eq!(
        fs::read_to_string(new.join("settings.json.legacy")).expect("read failed"),
        "{\"first\":true}",
        "an existing kept copy must not be clobbered"
    );
    assert_eq!(
        fs::read_to_string(new.join("settings.json.legacy-1")).expect("read failed"),
        "{\"second\":true}"
    );

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn a_missing_old_folder_is_a_no_op() {
    let base = temp_dir("migrate-missing");
    let new = base.join("new");
    fs::create_dir_all(&new).expect("failed to create new dir");

    let result = migrate_app_data(&new, &base.join("absent"));

    assert_eq!(result, IdentifierMigration::default());
    assert!(file_names(&new).is_empty());

    let _ = fs::remove_dir_all(&base);
}
