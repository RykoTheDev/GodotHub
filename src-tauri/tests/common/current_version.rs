use super::{
    alias_candidates_for, alias_file_name, alias_file_name_for, remove_alias_files,
    remove_existing_aliases, shim_script, validate_alias_name, ALIAS_CANDIDATES,
};
use std::fs;
use std::path::Path;

fn temp_alias_dir(label: &str) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!(
        "godothub-{label}-{}-{:?}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or_default()
    ));
    fs::create_dir_all(&dir).expect("failed to create temp alias dir");
    dir
}

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

#[test]
fn validation_accepts_ordinary_alias_names() {
    for name in ["godot-mono", "godot-next", "godot_4_5", "GodotSharp"] {
        assert_eq!(validate_alias_name(name).as_deref(), Ok(name));
    }
}

#[test]
fn validation_trims_surrounding_whitespace() {
    assert_eq!(
        validate_alias_name("  godot-beta  ").as_deref(),
        Ok("godot-beta")
    );
}

#[test]
fn validation_rejects_unsafe_names() {
    for name in [
        "",
        "   ",
        "../evil",
        "a/b",
        "a\\b",
        "C:godot",
        "godot.exe",
        "godot.CMD",
        "godot.",
        "godot ",
        ".",
        "..",
        "con",
        "NUL",
        "com1",
        "lpt9.txt",
    ] {
        assert!(
            validate_alias_name(name).is_err(),
            "{name:?} should be rejected"
        );
    }
}

#[test]
fn validation_keeps_godot_reserved_for_the_pin() {
    for name in ["Godot", "godot", "  GODOT  "] {
        assert!(
            validate_alias_name(name).is_err(),
            "{name:?} should stay reserved for the pinned alias"
        );
    }
}

#[test]
fn candidates_include_the_primary_and_shim_names() {
    let candidates = alias_candidates_for("godot-mono");
    assert!(candidates.contains(&alias_file_name_for("godot-mono")));
    assert!(candidates.contains(&"godot-mono.cmd".to_string()));
}

#[test]
fn removing_a_named_alias_leaves_other_aliases_alone() {
    let dir = temp_alias_dir("named-alias-removal");
    for name in ["godot-mono.exe", "godot-mono.cmd", "godot-mono", "Godot.exe"] {
        fs::write(dir.join(name), b"x").expect("failed to create alias file");
    }

    remove_alias_files(&dir, "godot-mono");

    for name in ["godot-mono.exe", "godot-mono.cmd", "godot-mono"] {
        assert!(
            fs::symlink_metadata(dir.join(name)).is_err(),
            "alias {name} should have been removed"
        );
    }
    assert!(
        fs::symlink_metadata(dir.join("Godot.exe")).is_ok(),
        "the pinned alias should be untouched"
    );

    let _ = fs::remove_dir_all(&dir);
}
