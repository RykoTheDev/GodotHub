use serde::de::DeserializeOwned;
use serde::Serialize;
use serde_json::Value;
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};

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

pub(crate) fn write_bytes(path: &Path, bytes: &[u8]) -> AppResult<()> {
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

/// Outcome of loading a persisted store, so callers can tell a genuinely empty
/// store apart from a corrupt one and react (surface a warning, offer restore).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum LoadStatus {
    /// Neither the file nor its backup exist yet.
    Missing,
    /// The primary file parsed cleanly.
    Ok,
    /// The primary file was unusable; the value came from the `.bak` file.
    RecoveredFromBackup,
    /// Both the primary file and its backup failed to parse. The caller gets a
    /// default value and should surface this rather than treat it as empty.
    Corrupt,
}

pub struct Loaded<T> {
    pub value: T,
    pub status: LoadStatus,
}

/// A versioned store. Additions are handled by serde defaults; renames and
/// structural changes are handled by `migrate`, applied on load when the file's
/// `schema_version` is older than `VERSION`.
pub trait Versioned {
    const VERSION: u32;
    fn migrate(value: Value, _from: u32) -> Value {
        value
    }
}

/// Reads a file as JSON. `Ok(None)` means the file is absent; `Err` means it
/// exists but could not be read or parsed (corruption).
fn read_value(path: &Path) -> Result<Option<Value>, String> {
    match fs::read_to_string(path) {
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(e.to_string()),
        Ok(raw) => serde_json::from_str::<Value>(&raw)
            .map(Some)
            .map_err(|e| e.to_string()),
    }
}

fn finalize<T: DeserializeOwned + Versioned>(mut value: Value) -> Option<T> {
    let from = value
        .get("schema_version")
        .and_then(|v| v.as_u64())
        .unwrap_or(0) as u32;
    if from < T::VERSION {
        value = T::migrate(value, from);
    }
    if let Value::Object(ref mut map) = value {
        map.insert("schema_version".into(), Value::from(T::VERSION));
    }
    serde_json::from_value(value).ok()
}

/// Loads a versioned store, recovering from the `.bak` file when the primary is
/// corrupt and reporting exactly what happened via `LoadStatus`.
pub fn load_json<T: DeserializeOwned + Default + Versioned>(path: &Path) -> Loaded<T> {
    match read_value(path) {
        Ok(Some(value)) => {
            if let Some(value) = finalize::<T>(value) {
                return Loaded {
                    value,
                    status: LoadStatus::Ok,
                };
            }
            // Parsed as JSON but did not fit the type: treat like corruption.
        }
        Ok(None) => {
            if let Ok(Some(value)) = read_value(&backup_path(path)) {
                if let Some(value) = finalize::<T>(value) {
                    return Loaded {
                        value,
                        status: LoadStatus::RecoveredFromBackup,
                    };
                }
            }
            return Loaded {
                value: T::default(),
                status: LoadStatus::Missing,
            };
        }
        Err(_) => {}
    }

    if let Ok(Some(value)) = read_value(&backup_path(path)) {
        if let Some(value) = finalize::<T>(value) {
            return Loaded {
                value,
                status: LoadStatus::RecoveredFromBackup,
            };
        }
    }
    Loaded {
        value: T::default(),
        status: LoadStatus::Corrupt,
    }
}

fn file_lock(path: &Path) -> Arc<Mutex<()>> {
    static REGISTRY: OnceLock<Mutex<HashMap<PathBuf, Arc<Mutex<()>>>>> = OnceLock::new();
    let registry = REGISTRY.get_or_init(|| Mutex::new(HashMap::new()));
    // Key on the canonical parent directory plus the file name so the same file
    // maps to the same lock even before it exists on disk.
    let key = match path.parent() {
        Some(parent) => fs::canonicalize(parent)
            .unwrap_or_else(|_| parent.to_path_buf())
            .join(path.file_name().unwrap_or_default()),
        None => path.to_path_buf(),
    };
    let mut map = registry.lock().unwrap_or_else(|e| e.into_inner());
    map.entry(key)
        .or_insert_with(|| Arc::new(Mutex::new(())))
        .clone()
}

/// Serializes read-modify-write on a single store so concurrent writers (UI,
/// watcher, session-settle thread) cannot lose each other's updates. The current
/// value is read from disk under the lock, mutated, and written back atomically.
pub fn update_json<T, F>(path: &Path, mutate: F) -> AppResult<T>
where
    T: DeserializeOwned + Default + Serialize + Versioned,
    F: FnOnce(&mut T),
{
    let lock = file_lock(path);
    let _guard = lock.lock().unwrap_or_else(|e| e.into_inner());
    let mut value: T = load_json(path).value;
    mutate(&mut value);
    write_json_with_backup(path, &value)?;
    Ok(value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::Deserialize;

    #[derive(Serialize, Deserialize, Default, Debug, PartialEq)]
    struct Counter {
        #[serde(default)]
        schema_version: u32,
        #[serde(default)]
        n: u64,
    }
    impl Versioned for Counter {
        const VERSION: u32 = 1;
    }

    #[derive(Serialize, Deserialize, Default, Debug, PartialEq, Clone)]
    struct Proj {
        id: String,
    }
    #[derive(Serialize, Deserialize, Default, Debug, PartialEq)]
    struct ProjectStore {
        #[serde(default)]
        schema_version: u32,
        #[serde(default)]
        projects: Vec<Proj>,
    }
    impl Versioned for ProjectStore {
        const VERSION: u32 = 1;
        fn migrate(value: Value, _from: u32) -> Value {
            // Version 0 stored a bare array of projects.
            if value.is_array() {
                return serde_json::json!({ "schema_version": 1, "projects": value });
            }
            value
        }
    }

    fn scratch(tag: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!(
            "godothub-persist-test-{tag}-{}",
            std::process::id()
        ));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn missing_file_is_not_treated_as_corrupt() {
        let path = scratch("missing").join("x.json");
        let loaded = load_json::<Counter>(&path);
        assert_eq!(loaded.status, LoadStatus::Missing);
        assert_eq!(loaded.value, Counter::default());
    }

    #[test]
    fn corrupt_primary_recovers_from_backup() {
        let path = scratch("recover").join("c.json");
        write_json_with_backup(&path, &Counter { schema_version: 1, n: 42 }).unwrap();
        // Second write pushes the previous good value into the .bak file.
        write_json_with_backup(&path, &Counter { schema_version: 1, n: 43 }).unwrap();
        fs::write(&path, b"{ this is not json").unwrap();
        let loaded = load_json::<Counter>(&path);
        assert_eq!(loaded.status, LoadStatus::RecoveredFromBackup);
        assert_eq!(loaded.value.n, 42);
    }

    #[test]
    fn both_corrupt_reports_corrupt_not_silent_default() {
        let path = scratch("corrupt").join("c.json");
        fs::write(&path, b"garbage").unwrap();
        fs::write(&backup_path(&path), b"also garbage").unwrap();
        let loaded = load_json::<Counter>(&path);
        assert_eq!(loaded.status, LoadStatus::Corrupt);
    }

    #[test]
    fn concurrent_updates_do_not_lose_writes() {
        let path = scratch("concurrent").join("counter.json");
        write_json_with_backup(&path, &Counter { schema_version: 1, n: 0 }).unwrap();
        let threads = 16u64;
        let per_thread = 50u64;
        let mut handles = Vec::new();
        for _ in 0..threads {
            let path = path.clone();
            handles.push(std::thread::spawn(move || {
                for _ in 0..per_thread {
                    update_json::<Counter, _>(&path, |c| c.n += 1).unwrap();
                }
            }));
        }
        for h in handles {
            h.join().unwrap();
        }
        let final_n = load_json::<Counter>(&path).value.n;
        assert_eq!(final_n, threads * per_thread, "lost updates: got {final_n}");
    }

    #[test]
    fn migrates_bare_array_to_versioned_envelope() {
        let path = scratch("migrate").join("projects.json");
        fs::write(&path, br#"[{"id":"a"},{"id":"b"}]"#).unwrap();
        let loaded = load_json::<ProjectStore>(&path);
        assert_eq!(loaded.status, LoadStatus::Ok);
        assert_eq!(loaded.value.schema_version, 1);
        assert_eq!(loaded.value.projects.len(), 2);
        assert_eq!(loaded.value.projects[0].id, "a");
    }

    #[test]
    fn serde_default_fills_added_field() {
        let path = scratch("added").join("c.json");
        fs::write(&path, br#"{"schema_version":1}"#).unwrap();
        let loaded = load_json::<Counter>(&path);
        assert_eq!(loaded.status, LoadStatus::Ok);
        assert_eq!(loaded.value.n, 0);
    }
}
