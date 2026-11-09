use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::persist::{self, Versioned};
use crate::AppHandle;

const FILE_NAME: &str = "ui_prefs.json";

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct UiPrefs {
    #[serde(default)]
    pub schema_version: u32,
    #[serde(default)]
    pub migrated_from_local_storage: bool,
    #[serde(default)]
    pub values: Map<String, Value>,
}

impl Versioned for UiPrefs {
    const VERSION: u32 = 1;
}

fn prefs_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_data_dir()
        .map(|dir| dir.join(FILE_NAME))
        .map_err(|e| e.to_string())
}

fn read_in(path: &Path) -> UiPrefs {
    persist::load_json::<UiPrefs>(path).value
}

fn update_in(path: &Path, mutate: impl FnOnce(&mut UiPrefs)) -> Result<UiPrefs, String> {
    if let Some(dir) = path.parent() {
        persist::ensure_dir(dir).map_err(|e| e.to_string())?;
    }
    persist::update_json(path, mutate).map_err(|e| e.to_string())
}

fn import_in(path: &Path, values: Map<String, Value>) -> Result<UiPrefs, String> {
    update_in(path, |prefs| {
        if prefs.migrated_from_local_storage {
            return;
        }
        for (key, value) in values {
            prefs.values.entry(key).or_insert(value);
        }
        prefs.migrated_from_local_storage = true;
    })
}

pub fn get_ui_prefs(app: AppHandle) -> Result<UiPrefs, String> {
    Ok(read_in(&prefs_path(&app)?))
}

pub fn get_ui_pref(app: AppHandle, key: String) -> Result<Option<Value>, String> {
    Ok(read_in(&prefs_path(&app)?).values.get(&key).cloned())
}

pub fn set_ui_pref(app: AppHandle, key: String, value: Value) -> Result<(), String> {
    update_in(&prefs_path(&app)?, |prefs| {
        prefs.values.insert(key, value);
    })
    .map(|_| ())
}

pub fn remove_ui_pref(app: AppHandle, key: String) -> Result<(), String> {
    update_in(&prefs_path(&app)?, |prefs| {
        prefs.values.remove(&key);
    })
    .map(|_| ())
}

pub fn import_ui_prefs(app: AppHandle, values: Map<String, Value>) -> Result<UiPrefs, String> {
    import_in(&prefs_path(&app)?, values)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn temp_store(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("godothub-ui-prefs-{name}-{}", uuid::Uuid::new_v4()));
        dir.join(FILE_NAME)
    }

    fn values(pairs: &[(&str, Value)]) -> Map<String, Value> {
        pairs.iter().map(|(k, v)| (k.to_string(), v.clone())).collect()
    }

    #[test]
    fn missing_store_is_empty_and_not_migrated() {
        let path = temp_store("missing");
        let prefs = read_in(&path);
        assert!(!prefs.migrated_from_local_storage);
        assert!(prefs.values.is_empty());
    }

    #[test]
    fn set_get_and_remove_round_trip() {
        let path = temp_store("roundtrip");
        update_in(&path, |p| {
            p.values.insert("new_ui_sidebar_width".into(), json!("300"));
        })
        .unwrap();
        update_in(&path, |p| {
            p.values.insert("godothub_version_filters".into(), json!({"buildType": "mono"}));
        })
        .unwrap();
        let prefs = read_in(&path);
        assert_eq!(prefs.values.get("new_ui_sidebar_width"), Some(&json!("300")));
        assert_eq!(prefs.values.get("godothub_version_filters"), Some(&json!({"buildType": "mono"})));
        update_in(&path, |p| {
            p.values.remove("new_ui_sidebar_width");
        })
        .unwrap();
        assert_eq!(read_in(&path).values.get("new_ui_sidebar_width"), None);
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }

    #[test]
    fn import_runs_once_and_keeps_existing_values() {
        let path = temp_store("import");
        update_in(&path, |p| {
            p.values.insert("i18nextLng".into(), json!("fr-FR"));
        })
        .unwrap();

        let first = import_in(
            &path,
            values(&[("i18nextLng", json!("en-US")), ("new_ui_sidebar_collapsed", json!("1"))]),
        )
        .unwrap();
        assert!(first.migrated_from_local_storage);
        assert_eq!(first.values.get("i18nextLng"), Some(&json!("fr-FR")));
        assert_eq!(first.values.get("new_ui_sidebar_collapsed"), Some(&json!("1")));

        let second = import_in(&path, values(&[("godothub_vault_sort", json!("newest"))])).unwrap();
        assert_eq!(second.values.get("godothub_vault_sort"), None);
        assert_eq!(read_in(&path), second);
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }

    #[test]
    fn corrupt_store_falls_back_to_backup_or_defaults() {
        let path = temp_store("corrupt");
        std::fs::create_dir_all(path.parent().unwrap()).unwrap();
        std::fs::write(&path, "{ not json").unwrap();
        let prefs = read_in(&path);
        assert!(!prefs.migrated_from_local_storage);
        assert!(prefs.values.is_empty());
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }
}
