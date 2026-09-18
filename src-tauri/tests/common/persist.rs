use super::{
    backup_path, read_json_opt, read_json_opt_with_backup, write_json, write_json_with_backup,
};
use serde_json::{json, Value};
use std::fs;
use std::path::PathBuf;

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

#[test]
fn write_json_round_trips_without_leaving_temp_files() {
    let dir = temp_dir("persist-round-trip");
    let path = dir.join("state.json");

    write_json(&path, &json!({ "value": 1 })).expect("write failed");
    assert_eq!(read_json_opt::<Value>(&path), Some(json!({ "value": 1 })));

    write_json(&path, &json!({ "value": 2 })).expect("overwrite failed");
    assert_eq!(read_json_opt::<Value>(&path), Some(json!({ "value": 2 })));

    let leftovers: Vec<String> = fs::read_dir(&dir)
        .expect("failed to read temp dir")
        .flatten()
        .map(|e| e.file_name().to_string_lossy().to_string())
        .filter(|name| name.ends_with(".tmp"))
        .collect();
    assert!(leftovers.is_empty(), "temp files left behind: {leftovers:?}");

    let _ = fs::remove_dir_all(&dir);
}

#[test]
fn backup_keeps_the_previous_contents() {
    let dir = temp_dir("persist-backup");
    let path = dir.join("settings.json");

    write_json_with_backup(&path, &json!({ "generation": 1 })).expect("write failed");
    write_json_with_backup(&path, &json!({ "generation": 2 })).expect("write failed");

    assert_eq!(read_json_opt::<Value>(&path), Some(json!({ "generation": 2 })));
    assert_eq!(
        read_json_opt::<Value>(&backup_path(&path)),
        Some(json!({ "generation": 1 }))
    );

    let _ = fs::remove_dir_all(&dir);
}

#[test]
fn reads_fall_back_to_the_backup_when_the_file_is_unusable() {
    let dir = temp_dir("persist-fallback");
    let path = dir.join("settings.json");

    write_json_with_backup(&path, &json!({ "generation": 1 })).expect("write failed");
    write_json_with_backup(&path, &json!({ "generation": 2 })).expect("write failed");

    fs::write(&path, b"{ \"generation\":").expect("truncation failed");
    assert_eq!(
        read_json_opt_with_backup::<Value>(&path),
        Some(json!({ "generation": 1 }))
    );

    fs::write(&path, b"").expect("truncation failed");
    assert_eq!(
        read_json_opt_with_backup::<Value>(&path),
        Some(json!({ "generation": 1 }))
    );

    let _ = fs::remove_dir_all(&dir);
}

#[test]
fn reads_without_a_file_or_backup_fall_back_to_default() {
    let dir = temp_dir("persist-default");
    let path = dir.join("missing.json");

    assert_eq!(read_json_opt_with_backup::<Value>(&path), None);
    assert_eq!(
        super::read_json_with_backup::<Value>(&path),
        Value::default()
    );

    let _ = fs::remove_dir_all(&dir);
}
