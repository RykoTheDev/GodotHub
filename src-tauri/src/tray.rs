use tauri::menu::{IsMenuItem, Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::tray::{MouseButton, MouseButtonState, TrayIcon, TrayIconBuilder, TrayIconEvent};
use tauri::{AppHandle, Manager};


pub struct TrayState(pub std::sync::Mutex<Option<TrayIcon>>);

pub fn show_main_window(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.set_focus();
    }
}

fn build_tray_menu(app: &AppHandle) -> Result<Menu<tauri::Wry>, tauri::Error> {
    let show_item = MenuItem::with_id(app, "show", "Show GodotHub", true, None::<&str>)?;
    let quit_item = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
    let sep1 = PredefinedMenuItem::separator(app)?;
    let sep2 = PredefinedMenuItem::separator(app)?;

    let recent = godothub_core::recent::recent_projects(&crate::core_handle(app));
    crate::recent_menu::refresh(app, recent.clone());

    let recent_submenu = if recent.is_empty() {
        let no_recent_item =
            MenuItem::with_id(app, "no_recent", "No recent projects", false, None::<&str>)?;
        Submenu::with_items(
            app,
            "Open Recent",
            true,
            &[&no_recent_item as &dyn IsMenuItem<_>],
        )?
    } else {
        let mut recent_items = Vec::new();
        for p in &recent {
            recent_items.push(MenuItem::with_id(app, &p.id, &p.label, true, None::<&str>)?);
        }
        let recent_refs: Vec<&dyn IsMenuItem<_>> = recent_items
            .iter()
            .map(|item| item as &dyn IsMenuItem<_>)
            .collect();
        Submenu::with_items(app, "Open Recent", true, &recent_refs)?
    };

    let mut menu_items: Vec<&dyn IsMenuItem<_>> = vec![
        &show_item as &dyn IsMenuItem<_>,
        &sep1 as &dyn IsMenuItem<_>,
    ];
    menu_items.push(&recent_submenu as &dyn IsMenuItem<_>);
    menu_items.push(&sep2 as &dyn IsMenuItem<_>);
    menu_items.push(&quit_item as &dyn IsMenuItem<_>);
    Menu::with_items(app, &menu_items)
}

pub fn setup_tray(app: &AppHandle) -> Result<(), tauri::Error> {
    let tray_menu = build_tray_menu(app)?;

    #[cfg(target_os = "macos")]
    let tray_icon = tauri::include_image!("./icons/trayTemplate.png");
    #[cfg(not(target_os = "macos"))]
    let tray_icon = app
        .default_window_icon()
        .cloned()
        .expect("no default window icon set");

    let tray = TrayIconBuilder::new()
        .icon(tray_icon)
        .icon_as_template(cfg!(target_os = "macos"))
        .menu(&tray_menu)
        .show_menu_on_left_click(false)
        .tooltip("GodotHub")
        .on_menu_event(|app, event| match event.id.as_ref() {
            "show" => show_main_window(app),
            "quit" => app.exit(0),
            "no_recent" => {}
            id => {
                tauri::async_runtime::spawn(godothub_core::projects::open_project(
                    crate::core_handle(app),
                    id.to_string(),
                    true,
                    None,
                ));
            }
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                show_main_window(tray.app_handle());
            }
        })
        .build(app)?;

    app.state::<TrayState>().0.lock().unwrap_or_else(std::sync::PoisonError::into_inner).replace(tray);
    Ok(())
}

#[tauri::command]
pub async fn refresh_tray_menu(app: AppHandle) -> Result<(), String> {
    crate::lane::serial(move || refresh_tray_menu_now(&app)).await
}

pub fn refresh_tray_menu_now(app: &AppHandle) -> Result<(), String> {
    let state = app.state::<TrayState>();
    let guard = state.0.lock().unwrap_or_else(std::sync::PoisonError::into_inner);
    if let Some(ref tray) = *guard {
        let new_menu = build_tray_menu(app).map_err(|e| e.to_string())?;
        tray.set_menu(Some(new_menu)).map_err(|e| e.to_string())?;
    }
    Ok(())
}
