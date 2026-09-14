use super::{
    alias_candidates_for, alias_file_name, alias_file_name_for, alias_is_usable, alias_needs_shim,
    create_alias, detect_method, remove_alias_files, remove_existing_aliases, shim_script,
    validate_alias_name, ALIAS_CANDIDATES,
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
fn mono_versions_need_a_launcher_script_on_windows() {
    assert_eq!(alias_needs_shim(true), cfg!(target_os = "windows"));
    assert!(
        !alias_needs_shim(false),
        "standard builds keep working from a link"
    );
}

#[test]
fn mono_aliases_never_leave_a_link_behind_on_windows() {
    let dir = temp_alias_dir("mono-alias");
    let target = dir.join(if cfg!(target_os = "windows") {
        "Godot_v4.5-stable_mono_win64.exe"
    } else {
        "Godot_v4.5-stable_mono_linux.x86_64"
    });
    fs::write(&target, b"exe").expect("failed to create target executable");

    let alias = dir.join(alias_file_name());
    let (method, path) = create_alias(&target, &alias, true).expect("alias should be created");

    assert!(path.is_file(), "the alias should exist: {path:?}");
    if alias_needs_shim(true) {
        assert_eq!(method, "shim");
        assert_eq!(detect_method(&path), "shim");
        assert!(
            fs::symlink_metadata(&alias).is_err(),
            "a link that cannot find GodotSharp must not be created"
        );
    } else {
        assert_eq!(method, "symlink");
    }

    let _ = fs::remove_dir_all(&dir);
}

#[test]
fn standard_aliases_still_prefer_a_link() {
    let dir = temp_alias_dir("standard-alias");
    let target = dir.join(if cfg!(target_os = "windows") {
        "Godot_v4.5-stable_win64.exe"
    } else {
        "Godot_v4.5-stable_linux.x86_64"
    });
    fs::write(&target, b"exe").expect("failed to create target executable");

    let (method, path) = create_alias(&target, &dir.join(alias_file_name()), false)
        .expect("alias should be created");

    assert!(path.is_file());
    assert_ne!(method, "shim", "standard builds should not need a launcher");

    let _ = fs::remove_dir_all(&dir);
}

#[test]
fn launcher_scripts_serve_mono_versions_but_links_do_not() {
    let dir = temp_alias_dir("usable-alias");
    let script = dir.join("godot-mono.cmd");
    fs::write(&script, b"@echo off\r\n").expect("failed to create shim");
    let link = dir.join("godot-mono.exe");
    fs::write(&link, b"exe").expect("failed to create link stand-in");

    assert!(alias_is_usable(&script, true));
    assert_eq!(alias_is_usable(&link, true), !alias_needs_shim(true));
    assert!(alias_is_usable(&link, false));

    let _ = fs::remove_dir_all(&dir);
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
