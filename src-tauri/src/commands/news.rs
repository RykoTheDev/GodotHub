use godothub_core::news::{NewsResponse};

#[tauri::command]
pub async fn fetch_godot_news(app: tauri::AppHandle) -> Result<NewsResponse, String> {
    let core = crate::core_handle(&app);
    godothub_core::news::fetch_godot_news(core).await
}
