use tauri::AppHandle;
use tauri_plugin_dialog::DialogExt;

#[tauri::command]
pub async fn pick_folder(app: AppHandle) -> Option<String> {
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog().file().pick_folder(move |folder| {
        let _ = tx.send(folder);
    });
    rx.recv().ok().flatten().map(|p| p.to_string())
}

#[tauri::command]
pub async fn pick_save_path(app: AppHandle, default_name: String) -> Option<String> {
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .set_file_name(&default_name)
        .save_file(move |file| {
            let _ = tx.send(file);
        });
    rx.recv().ok().flatten().map(|p| p.to_string())
}

#[tauri::command]
pub async fn pick_data_file(app: AppHandle) -> Option<String> {
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .add_filter("JSON", &["json"])
        .pick_file(move |file| {
            let _ = tx.send(file);
        });
    rx.recv().ok().flatten().map(|p| p.to_string())
}

#[tauri::command]
pub async fn pick_file(app: AppHandle) -> Option<String> {
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .add_filter("Images", &["png", "svg", "jpg", "jpeg", "webp"])
        .pick_file(move |file| {
            let _ = tx.send(file);
        });
    rx.recv().ok().flatten().map(|p| p.to_string())
}

#[tauri::command]
pub async fn pick_executable(app: AppHandle) -> Option<String> {
    let (tx, rx) = std::sync::mpsc::channel();
    let dialog = app.dialog().file();
    #[cfg(target_os = "macos")]
    dialog.pick_folder(move |folder| {
        let _ = tx.send(folder);
    });
    #[cfg(not(target_os = "macos"))]
    dialog.pick_file(move |file| {
        let _ = tx.send(file);
    });
    rx.recv().ok().flatten().map(|p| p.to_string())
}
