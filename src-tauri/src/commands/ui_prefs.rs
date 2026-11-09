use godothub_core::ui_prefs::UiPrefs;
use serde_json::{Map, Value};

#[tauri::command]
pub async fn get_ui_prefs(app: tauri::AppHandle) -> Result<UiPrefs, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::ui_prefs::get_ui_prefs(core)).await
}

#[tauri::command]
pub async fn get_ui_pref(app: tauri::AppHandle, key: String) -> Result<Option<Value>, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::ui_prefs::get_ui_pref(core, key)).await
}

#[tauri::command]
pub async fn set_ui_pref(app: tauri::AppHandle, key: String, value: Value) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::ui_prefs::set_ui_pref(core, key, value)).await
}

#[tauri::command]
pub async fn remove_ui_pref(app: tauri::AppHandle, key: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::ui_prefs::remove_ui_pref(core, key)).await
}

#[tauri::command]
pub async fn import_ui_prefs(app: tauri::AppHandle, values: Map<String, Value>) -> Result<UiPrefs, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::ui_prefs::import_ui_prefs(core, values)).await
}
