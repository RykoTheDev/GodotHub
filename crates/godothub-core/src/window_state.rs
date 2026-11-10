use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::AppHandle;

const FILE_NAME: &str = ".window-state.json";
const MAIN_WINDOW: &str = "main";

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct WindowState {
    pub width: u32,
    pub height: u32,
    pub x: i32,
    pub y: i32,
    pub maximized: bool,
}

fn state_file(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_config_dir()
        .map(|dir| dir.join(FILE_NAME))
        .map_err(|e| e.to_string())
}

fn read_root(path: &Path) -> Map<String, Value> {
    std::fs::read_to_string(path)
        .ok()
        .and_then(|raw| serde_json::from_str::<Value>(&raw).ok())
        .and_then(|value| match value {
            Value::Object(map) => Some(map),
            _ => None,
        })
        .unwrap_or_default()
}

pub fn load_from(path: &Path) -> Option<WindowState> {
    let entry = read_root(path).remove(MAIN_WINDOW)?;
    let state: WindowState = serde_json::from_value(entry).ok()?;
    (state.width > 0 && state.height > 0).then_some(state)
}

pub fn save_to(path: &Path, state: WindowState) -> Result<(), String> {
    let mut root = read_root(path);
    let mut entry = match root.remove(MAIN_WINDOW) {
        Some(Value::Object(map)) => map,
        _ => Map::new(),
    };
    entry.insert("width".into(), state.width.into());
    entry.insert("height".into(), state.height.into());
    entry.insert("maximized".into(), state.maximized.into());
    if !state.maximized || !entry.contains_key("x") {
        entry.insert("x".into(), state.x.into());
        entry.insert("y".into(), state.y.into());
    }
    if !state.maximized || !entry.contains_key("prev_x") {
        entry.insert("prev_x".into(), state.x.into());
        entry.insert("prev_y".into(), state.y.into());
    }
    entry.entry("visible").or_insert(true.into());
    entry.entry("decorated").or_insert(true.into());
    entry.entry("fullscreen").or_insert(false.into());
    root.insert(MAIN_WINDOW.into(), Value::Object(entry));
    if let Some(dir) = path.parent() {
        crate::persist::ensure_dir(dir).map_err(|e| e.to_string())?;
    }
    crate::persist::write_json(path, &Value::Object(root)).map_err(|e| e.to_string())
}

pub fn load_window_state(app: &AppHandle) -> Result<Option<WindowState>, String> {
    Ok(load_from(&state_file(app)?))
}

pub fn save_window_state(app: &AppHandle, state: WindowState) -> Result<(), String> {
    save_to(&state_file(app)?, state)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_file(name: &str) -> PathBuf {
        std::env::temp_dir()
            .join(format!("godothub-window-state-{name}-{}", uuid::Uuid::new_v4()))
            .join(FILE_NAME)
    }

    const TAURI_FILE: &str = r#"{
  "main": {
    "width": 1280,
    "height": 791,
    "x": 333,
    "y": 151,
    "prev_x": 333,
    "prev_y": 151,
    "maximized": false,
    "visible": true,
    "decorated": true,
    "fullscreen": false
  }
}"#;

    #[test]
    fn reads_the_tauri_window_state_file() {
        let path = temp_file("read");
        std::fs::create_dir_all(path.parent().unwrap()).unwrap();
        std::fs::write(&path, TAURI_FILE).unwrap();
        assert_eq!(
            load_from(&path),
            Some(WindowState { width: 1280, height: 791, x: 333, y: 151, maximized: false })
        );
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }

    #[test]
    fn missing_or_broken_files_have_no_state() {
        let path = temp_file("missing");
        assert_eq!(load_from(&path), None);
        std::fs::create_dir_all(path.parent().unwrap()).unwrap();
        std::fs::write(&path, "{ nope").unwrap();
        assert_eq!(load_from(&path), None);
        std::fs::write(&path, r#"{"main":{"width":0,"height":0,"x":0,"y":0,"maximized":false}}"#).unwrap();
        assert_eq!(load_from(&path), None);
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }

    #[test]
    fn saving_keeps_tauri_fields_and_other_windows() {
        let path = temp_file("save");
        std::fs::create_dir_all(path.parent().unwrap()).unwrap();
        let mut tauri: Value = serde_json::from_str(TAURI_FILE).unwrap();
        tauri["other"] = serde_json::json!({ "width": 10 });
        std::fs::write(&path, tauri.to_string()).unwrap();

        save_to(&path, WindowState { width: 1400, height: 800, x: 10, y: 20, maximized: false }).unwrap();

        let saved: Value = serde_json::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        assert_eq!(saved["main"]["width"], 1400);
        assert_eq!(saved["main"]["prev_x"], 10);
        assert_eq!(saved["main"]["decorated"], true);
        assert_eq!(saved["other"]["width"], 10);
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }

    #[test]
    fn maximizing_keeps_the_restored_position() {
        let path = temp_file("maximized");
        save_to(&path, WindowState { width: 1280, height: 720, x: 100, y: 50, maximized: false }).unwrap();
        save_to(&path, WindowState { width: 1920, height: 1040, x: 0, y: 0, maximized: true }).unwrap();
        let saved: Value = serde_json::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        assert_eq!(saved["main"]["maximized"], true);
        assert_eq!((saved["main"]["x"].as_i64(), saved["main"]["prev_x"].as_i64()), (Some(100), Some(100)));
        assert_eq!(load_from(&path).unwrap().width, 1920);
        let _ = std::fs::remove_dir_all(path.parent().unwrap());
    }
}
