use std::fs;
use std::path::Path;

use crate::project_metadata::{is_metadata_entry, LEGACY_FILES, METADATA_DIR};

fn prepare_destination(src: &Path, dst: &Path) -> Result<(), String> {
    let source = src.canonicalize().map_err(|error| error.to_string())?;
    fs::create_dir_all(dst).map_err(|error| error.to_string())?;
    let destination = dst.canonicalize().map_err(|error| error.to_string())?;
    if source.starts_with(&destination) || destination.starts_with(&source) {
        return Err("Source and destination folders must not overlap".into());
    }
    Ok(())
}

// Only call on managed template folders or copy destinations, never the source project.
pub(crate) fn remove_identity_files(dir: &Path) -> Result<(), String> {
    let metadata = dir.join(METADATA_DIR);
    if metadata.exists() {
        remove_dir_force(&metadata)?;
    }
    for name in LEGACY_FILES {
        match fs::remove_file(dir.join(name)) {
            Ok(()) => {}
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => return Err(error.to_string()),
        }
    }
    Ok(())
}

pub(crate) fn copy_dir(src: &Path, dst: &Path, skip_dirs: &[&str]) -> Result<(), String> {
    prepare_destination(src, dst)?;
    for entry in fs::read_dir(src).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let name = entry.file_name();
        let name_str = name.to_string_lossy().to_string();
        if is_metadata_entry(&name) || skip_dirs.iter().any(|d| name_str == *d) {
            continue;
        }
        let src_path = entry.path();
        let dst_path = dst.join(&name);
        if src_path.is_dir() {
            copy_dir(&src_path, &dst_path, skip_dirs)?;
        } else {
            fs::copy(&src_path, &dst_path).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

// Asset installs merge into existing projects, so preserve the destination's marker
// and project settings as well as ignoring any identity carried by the download.
pub(crate) fn merge_asset_into(src: &Path, dst: &Path) -> Result<(), String> {
    prepare_destination(src, dst)?;
    let skip_dirs: &[&str] = &[".godot", ".git", "node_modules"];
    let protect_project_file = dst.join("project.godot").is_file();
    for entry in fs::read_dir(src).map_err(|error| error.to_string())? {
        let entry = entry.map_err(|error| error.to_string())?;
        let name = entry.file_name();
        let name_str = name.to_string_lossy();
        if is_metadata_entry(&name)
            || skip_dirs.contains(&name_str.as_ref())
            || (protect_project_file && name_str == "project.godot")
        {
            continue;
        }
        let src_path = entry.path();
        let dst_path = dst.join(&name);
        if src_path.is_dir() {
            copy_dir(&src_path, &dst_path, skip_dirs)?;
        } else {
            fs::copy(&src_path, &dst_path).map_err(|error| error.to_string())?;
        }
    }
    Ok(())
}

pub(crate) fn mirror_dir(src: &Path, dst: &Path, skip_dirs: &[&str]) -> Result<(), String> {
    prepare_destination(src, dst)?;

    fn prune(src: &Path, dst: &Path, skip_dirs: &[&str]) -> Result<(), String> {
        prepare_destination(src, dst)?;
        let mut src_entries: std::collections::HashMap<String, bool> =
            std::collections::HashMap::new();
        for entry in fs::read_dir(src).map_err(|e| e.to_string())? {
            let entry = entry.map_err(|e| e.to_string())?;
            if is_metadata_entry(&entry.file_name()) {
                continue;
            }
            let name = entry.file_name().to_string_lossy().to_string();
            if skip_dirs.iter().any(|d| name == *d) {
                continue;
            }
            let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
            src_entries.insert(name, is_dir);
        }

        for entry in fs::read_dir(dst).map_err(|e| e.to_string())? {
            let entry = entry.map_err(|e| e.to_string())?;
            let name = entry.file_name().to_string_lossy().to_string();
            if is_metadata_entry(&entry.file_name()) {
                remove_dir_force(&entry.path())?;
                continue;
            }
            if name == "template.json" || skip_dirs.iter().any(|d| name == *d) {
                continue;
            }
            let dst_is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
            match src_entries.get(&name) {
                None => {
                    remove_dir_force(&entry.path())?;
                }
                Some(src_is_dir) if *src_is_dir != dst_is_dir => {
                    remove_dir_force(&entry.path())?;
                }
                Some(true) => {
                    prune(&src.join(&name), &entry.path(), skip_dirs)?;
                }
                _ => {}
            }
        }
        Ok(())
    }

    prune(src, dst, skip_dirs)?;
    copy_dir(src, dst, skip_dirs)
}

pub(crate) fn remove_dir_force(dir: &Path) -> Result<(), String> {
    #[allow(clippy::permissions_set_readonly_false)]
    fn clear_readonly(path: &Path) {
        if let Ok(meta) = fs::metadata(path) {
            let mut perms = meta.permissions();
            perms.set_readonly(false);
            let _ = fs::set_permissions(path, perms);
        }
    }

    fn walk(dir: &Path) -> Result<(), String> {
        let metadata = fs::symlink_metadata(dir).map_err(|error| error.to_string())?;
        if metadata.file_type().is_symlink() {
            #[cfg(windows)]
            {
                use std::os::windows::fs::MetadataExt;
                use windows_sys::Win32::Storage::FileSystem::FILE_ATTRIBUTE_DIRECTORY;
                if metadata.file_attributes() & FILE_ATTRIBUTE_DIRECTORY != 0 {
                    return fs::remove_dir(dir).map_err(|error| error.to_string());
                }
            }
            return fs::remove_file(dir).map_err(|error| error.to_string());
        }
        if dir.is_dir() {
            for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
                let entry = entry.map_err(|e| e.to_string())?;
                let path = entry.path();
                clear_readonly(&path);
                if path.is_dir() {
                    walk(&path)?;
                } else {
                    fs::remove_file(&path).map_err(|e| e.to_string())?;
                }
            }
            fs::remove_dir(dir).map_err(|e| e.to_string())
        } else {
            clear_readonly(dir);
            fs::remove_file(dir).map_err(|e| e.to_string())
        }
    }

    walk(dir)
}
