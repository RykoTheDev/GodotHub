use godothub_core::models::{Category};

#[tauri::command]
pub async fn list_categories(app: tauri::AppHandle) -> Vec<Category> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::list_categories(core)).await
}

#[tauri::command]
pub async fn create_category(app: tauri::AppHandle, name: String, color: Option<String>) -> Result<Category, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::create_category(core, name, color)).await
}

#[tauri::command]
pub async fn update_category(app: tauri::AppHandle, id: String, name: Option<String>, color: Option<String>, hidden: Option<bool>) -> Result<Category, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::update_category(core, id, name, color, hidden)).await
}

#[tauri::command]
pub async fn rename_category(app: tauri::AppHandle, id: String, name: String) -> Result<Category, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::rename_category(core, id, name)).await
}

#[tauri::command]
pub async fn delete_category(app: tauri::AppHandle, id: String) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::delete_category(core, id)).await
}

#[tauri::command]
pub async fn reorder_categories(app: tauri::AppHandle, ordered_ids: Vec<String>) -> Result<(), String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::reorder_categories(core, ordered_ids)).await
}

#[tauri::command]
pub async fn add_category_folder(app: tauri::AppHandle, id: String, folder: String) -> Result<Category, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::add_category_folder(core, id, folder)).await
}

#[tauri::command]
pub async fn remove_category_folder(app: tauri::AppHandle, id: String, folder: String) -> Result<Category, String> {
    let core = crate::core_handle(&app);
    crate::lane::serial(move || godothub_core::categories::remove_category_folder(core, id, folder)).await
}
