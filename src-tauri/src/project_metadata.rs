use std::fs;
use std::io;
use std::path::{Path, PathBuf};

pub const METADATA_DIR: &str = ".godothub";
pub const VERSION_FILE: &str = ".godotrc";
pub const LEGACY_IDENTITY_FILE: &str = ".godothub.json";
pub const IDENTITY_FILE: &str = "project.json";
pub const LEGACY_FILES: [&str; 4] = [
    LEGACY_IDENTITY_FILE,
    ".godothub.json.bak",
    "..godothub.json.tmp",
    VERSION_FILE,
];

pub fn directory(root: &Path) -> PathBuf {
    root.join(METADATA_DIR)
}

pub fn version_file(root: &Path) -> PathBuf {
    directory(root).join(VERSION_FILE)
}

pub fn ensure_gitignore(root: &Path, defaults: &str) -> io::Result<()> {
    use std::io::Write;
    let path = root.join(".gitignore");
    let contents = match fs::read_to_string(&path) {
        Ok(contents) => contents,
        Err(error) if error.kind() == io::ErrorKind::NotFound => {
            fs::write(&path, defaults)?;
            defaults.to_string()
        }
        Err(error) => return Err(error),
    };
    if contents
        .lines()
        .any(|line| matches!(line.trim(), ".godothub/" | "/.godothub/"))
    {
        return Ok(());
    }
    let mut file = fs::OpenOptions::new().append(true).open(path)?;
    if !contents.is_empty() && !contents.ends_with('\n') {
        writeln!(file)?;
    }
    writeln!(file, "\n# GodotHub project metadata\n.godothub/")
}

pub fn prepare(root: &Path) -> io::Result<PathBuf> {
    let dir = directory(root);
    fs::create_dir_all(&dir)?;
    match fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(dir.join(".gdignore"))
    {
        Ok(_) => {}
        Err(error) if error.kind() == io::ErrorKind::AlreadyExists => {}
        Err(error) => return Err(error),
    }
    hide(&dir);
    Ok(dir)
}

fn migrate_file(root: &Path, old_name: &str, new_name: &str) -> io::Result<()> {
    let old = root.join(old_name);
    if !old.is_file() {
        return Ok(());
    }
    let new = prepare(root)?.join(new_name);
    if new.exists() {
        // Prefer the new location, but retain conflicting legacy data for recovery.
        if fs::read(&old)? == fs::read(&new)? {
            fs::remove_file(old)?;
        }
        return Ok(());
    }
    fs::rename(old, &new)?;
    hide(&new);
    Ok(())
}

pub fn migrate(root: &Path) -> io::Result<()> {
    migrate_file(root, LEGACY_IDENTITY_FILE, IDENTITY_FILE)?;
    migrate_file(root, VERSION_FILE, VERSION_FILE)?;
    if directory(root).is_dir() {
        prepare(root)?;
    }
    Ok(())
}

pub fn is_metadata_entry(name: &std::ffi::OsStr) -> bool {
    name.to_str().is_some_and(|name| {
        name.eq_ignore_ascii_case(METADATA_DIR)
            || LEGACY_FILES
                .iter()
                .any(|entry| name.eq_ignore_ascii_case(entry))
    })
}

pub fn hide(path: &Path) {
    #[cfg(windows)]
    {
        use std::os::windows::{ffi::OsStrExt, fs::MetadataExt};
        use windows_sys::Win32::Storage::FileSystem::{SetFileAttributesW, FILE_ATTRIBUTE_HIDDEN};
        let Ok(metadata) = fs::metadata(path) else {
            return;
        };
        let attributes = metadata.file_attributes();
        if attributes & FILE_ATTRIBUTE_HIDDEN != 0 {
            return;
        }
        let wide_path: Vec<u16> = path.as_os_str().encode_wide().chain(Some(0)).collect();
        // Best effort; preserve other attributes and keep metadata usable if hiding fails.
        unsafe { SetFileAttributesW(wide_path.as_ptr(), attributes | FILE_ATTRIBUTE_HIDDEN) };
    }
    #[cfg(not(windows))]
    let _ = path; // Dot directory plus .gdignore hides metadata from Godot on Unix.
}
