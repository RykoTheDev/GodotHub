use super::{alias_file_name, remove_existing_aliases, shim_script, ALIAS_CANDIDATES};
use std::fs;
use std::path::Path;

#[test]
fn shim_quotes_target_and_forwards_arguments() {
    let script = shim_script(Path::new(r"C:\Program Files\Godot\Godot.exe"));
    assert!(script.starts_with("@echo off\r\n"));
    assert!(script.contains("\"C:\\Program Files\\Godot\\Godot.exe\" %*"));
}

#[test]
fn alias_candidates_cover_the_platform_alias_name() {
    assert!(ALIAS_CANDIDATES.contains(&alias_file_name()));
}

#[test]
fn removing_aliases_clears_every_candidate_name() {
    let dir = std::env::temp_dir().join(format!(
        "godothub-alias-test-{}-{:?}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or_default()
    ));
    fs::create_dir_all(&dir).expect("failed to create temp alias dir");

    for name in ALIAS_CANDIDATES {
        fs::write(dir.join(name), b"x").expect("failed to create alias file");
    }

    remove_existing_aliases(&dir);

    for name in ALIAS_CANDIDATES {
        assert!(
            fs::symlink_metadata(dir.join(name)).is_err(),
            "alias {name} should have been removed"
        );
    }

    let _ = fs::remove_dir_all(&dir);
}
