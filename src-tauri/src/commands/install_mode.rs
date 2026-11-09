
#[tauri::command]
pub async fn is_portable_install() -> bool {
    crate::lane::serial(godothub_core::install_mode::is_portable_install).await
}
