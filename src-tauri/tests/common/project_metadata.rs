use super::*;

struct Fixture(PathBuf);
impl Fixture {
    fn new(name: &str) -> Self {
        let path =
            std::env::temp_dir().join(format!("godothub-migrate-{name}-{}", std::process::id()));
        fs::create_dir_all(&path).unwrap();
        Self(path)
    }
}
impl Drop for Fixture {
    fn drop(&mut self) {
        fs::remove_dir_all(&self.0).unwrap();
    }
}

#[test]
fn migrates_both_files_without_changing_contents_and_can_repeat() {
    let f = Fixture::new("both");
    let identity = br#"{"id":"existing-id","category":"Games","extra":"keep"}"#;
    let pin = b"# Existing pin\n4.4-stable no-dotnet\n";
    fs::write(f.0.join(LEGACY_IDENTITY_FILE), identity).unwrap();
    fs::write(f.0.join(VERSION_FILE), pin).unwrap();
    migrate(&f.0).unwrap();
    let stored = directory(&f.0).join(IDENTITY_FILE);
    assert_eq!(fs::read(&stored).unwrap(), identity);
    assert_eq!(fs::read(version_file(&f.0)).unwrap(), pin);
    assert!(directory(&f.0).join(".gdignore").is_file());
    assert!(!f.0.join(LEGACY_IDENTITY_FILE).exists());
    assert!(!f.0.join(VERSION_FILE).exists());
    let modified = fs::metadata(&stored).unwrap().modified().unwrap();
    migrate(&f.0).unwrap();
    assert_eq!(fs::metadata(stored).unwrap().modified().unwrap(), modified);
    assert_eq!(
        crate::project_identity::read_project_identity(&f.0.to_string_lossy()).as_deref(),
        Some("existing-id")
    );
    assert_eq!(
        crate::project_identity::read_project_category(&f.0.to_string_lossy()).as_deref(),
        Some("Games")
    );
}

#[test]
fn conflicts_preserve_both_files_and_prefer_new_identity() {
    let f = Fixture::new("conflict");
    let dir = prepare(&f.0).unwrap();
    let old = br#"{"id":"old-id"}"#;
    let new = br#"{"id":"new-id"}"#;
    fs::write(f.0.join(LEGACY_IDENTITY_FILE), old).unwrap();
    fs::write(dir.join(IDENTITY_FILE), new).unwrap();
    fs::write(f.0.join(VERSION_FILE), "4.3-stable no-dotnet\n").unwrap();
    fs::write(version_file(&f.0), "4.4-stable no-dotnet\n").unwrap();
    migrate(&f.0).unwrap();
    assert_eq!(fs::read(f.0.join(LEGACY_IDENTITY_FILE)).unwrap(), old);
    assert_eq!(fs::read(dir.join(IDENTITY_FILE)).unwrap(), new);
    assert_eq!(
        fs::read_to_string(f.0.join(VERSION_FILE)).unwrap(),
        "4.3-stable no-dotnet\n"
    );
    assert_eq!(
        crate::project_identity::read_project_identity(&f.0.to_string_lossy()).as_deref(),
        Some("new-id")
    );
}

#[test]
fn failed_migration_leaves_legacy_files_readable() {
    let f = Fixture::new("blocked");
    fs::write(f.0.join(METADATA_DIR), "not a directory").unwrap();
    fs::write(
        f.0.join(LEGACY_IDENTITY_FILE),
        br#"{"id":"legacy-id","category":"Tools"}"#,
    )
    .unwrap();
    fs::write(f.0.join(VERSION_FILE), "4.4-stable no-dotnet\n").unwrap();
    assert!(migrate(&f.0).is_err());
    assert!(f.0.join(VERSION_FILE).is_file());
    assert_eq!(
        crate::project_identity::read_project_identity(&f.0.to_string_lossy()).as_deref(),
        Some("legacy-id")
    );
    assert!(!crate::project_identity::ensure_project_identity(
        &f.0.to_string_lossy(),
        "legacy-id",
        Some("Tools")
    ));
    assert!(f.0.join(LEGACY_IDENTITY_FILE).is_file());
}

#[test]
fn metadata_filter_does_not_hide_unrelated_project_json_assets() {
    for name in [METADATA_DIR, LEGACY_IDENTITY_FILE, VERSION_FILE] {
        assert!(is_metadata_entry(std::ffi::OsStr::new(name)));
    }
    assert!(!is_metadata_entry(std::ffi::OsStr::new("project.json")));
    assert!(!is_metadata_entry(std::ffi::OsStr::new(".gitignore")));
}

#[test]
fn duplicate_legacy_files_are_removed_only_when_contents_match() {
    let f = Fixture::new("duplicate");
    let dir = prepare(&f.0).unwrap();
    let identity = br#"{"id":"same-id"}"#;
    fs::write(f.0.join(LEGACY_IDENTITY_FILE), identity).unwrap();
    fs::write(dir.join(IDENTITY_FILE), identity).unwrap();
    migrate(&f.0).unwrap();
    assert!(!f.0.join(LEGACY_IDENTITY_FILE).exists());
    assert_eq!(fs::read(dir.join(IDENTITY_FILE)).unwrap(), identity);
}

#[test]
fn partially_migrated_projects_keep_identity_and_legacy_pin_if_pin_move_fails() {
    let f = Fixture::new("partial");
    prepare(&f.0).unwrap();
    fs::create_dir(version_file(&f.0)).unwrap();
    fs::write(f.0.join(LEGACY_IDENTITY_FILE), br#"{"id":"keep-id"}"#).unwrap();
    fs::write(f.0.join(VERSION_FILE), "4.4-stable no-dotnet\n").unwrap();
    assert!(migrate(&f.0).is_err());
    assert_eq!(
        crate::project_identity::read_project_identity(&f.0.to_string_lossy()).as_deref(),
        Some("keep-id")
    );
    assert_eq!(
        fs::read_to_string(f.0.join(VERSION_FILE)).unwrap(),
        "4.4-stable no-dotnet\n"
    );
}

#[cfg(windows)]
#[test]
fn metadata_folder_is_hidden_on_windows() {
    use std::os::windows::fs::MetadataExt;
    use windows_sys::Win32::Storage::FileSystem::FILE_ATTRIBUTE_HIDDEN;
    let f = Fixture::new("hidden");
    let dir = prepare(&f.0).unwrap();
    assert_ne!(
        fs::metadata(dir).unwrap().file_attributes() & FILE_ATTRIBUTE_HIDDEN,
        0
    );
}
