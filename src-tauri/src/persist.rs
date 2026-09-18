use serde::de::DeserializeOwned;
use serde::Serialize;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};

use crate::error::AppResult;

pub fn read_json<T: DeserializeOwned + Default>(path: &Path) -> T {
    read_json_opt(path).unwrap_or_default()
}

pub fn read_json_opt<T: DeserializeOwned>(path: &Path) -> Option<T> {
    let raw = fs::read_to_string(path).ok()?;
    serde_json::from_str(&raw).ok()
}

pub fn backup_path(path: &Path) -> PathBuf {
    sibling(path, ".bak")
}

fn sibling(path: &Path, suffix: &str) -> PathBuf {
    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_default();
    path.with_file_name(format!("{name}{suffix}"))
}

fn tmp_path(path: &Path) -> PathBuf {
    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_default();
    path.with_file_name(format!(".{name}.tmp"))
}

pub fn read_json_with_backup<T: DeserializeOwned + Default>(path: &Path) -> T {
    read_json_opt_with_backup(path).unwrap_or_default()
}

pub fn read_json_opt_with_backup<T: DeserializeOwned>(path: &Path) -> Option<T> {
    read_json_opt(path).or_else(|| read_json_opt(&backup_path(path)))
}

pub fn write_json_with_backup<T: Serialize>(path: &Path, data: &T) -> AppResult<()> {
    let json = serde_json::to_string_pretty(data)?;
    if let Ok(previous) = fs::read(path) {
        if !previous.is_empty() {
            let _ = write_bytes(&backup_path(path), &previous);
        }
    }
    write_bytes(path, json.as_bytes())
}

pub fn write_json<T: Serialize>(path: &Path, data: &T) -> AppResult<()> {
    let json = serde_json::to_string_pretty(data)?;
    write_bytes(path, json.as_bytes())
}

fn write_bytes(path: &Path, bytes: &[u8]) -> AppResult<()> {
    let tmp = tmp_path(path);
    {
        let mut file = File::create(&tmp)?;
        file.write_all(bytes)?;
        file.sync_all()?;
    }
    if let Err(e) = fs::rename(&tmp, path) {
        let _ = fs::remove_file(&tmp);
        return Err(e.into());
    }
    Ok(())
}

#[allow(dead_code)]
pub fn ensure_dir(dir: &Path) -> AppResult<()> {
    if !dir.exists() {
        fs::create_dir_all(dir)?;
    }
    Ok(())
}

#[cfg(test)]
#[path = "../tests/common/persist.rs"]
mod persist_common_tests;
