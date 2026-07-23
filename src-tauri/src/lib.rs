mod categories;
mod changelog;
mod git;
mod godot_versions;
mod models;
mod news;
mod projects;
mod scan;
mod settings;
mod templates;
mod watcher;
mod workspace;

use tauri::menu::{IsMenuItem, Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::tray::{MouseButton, MouseButtonState, TrayIcon, TrayIconBuilder, TrayIconEvent};
use tauri::{Manager, WindowEvent};

struct TrayState(std::sync::Mutex<Option<TrayIcon>>);

#[tauri::command]
async fn pick_folder(app: tauri::AppHandle) -> Option<String> {
    use tauri_plugin_dialog::DialogExt;
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog().file().pick_folder(move |folder| {
        let _ = tx.send(folder);
    });
    rx.recv().ok().flatten().map(|p| p.to_string())
}

fn show_main_window(app: &tauri::AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.set_focus();
    }
}

fn build_tray_menu(app: &tauri::AppHandle<tauri::Wry>) -> Result<Menu<tauri::Wry>, tauri::Error> {
    use crate::models::Project;

    let show_item = MenuItem::with_id(app, "show", "Show GodotHub", true, None::<&str>)?;
    let quit_item = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
    let sep1 = PredefinedMenuItem::separator(app)?;
    let sep2 = PredefinedMenuItem::separator(app)?;

    let settings = crate::settings::read_settings(app);
    let count = settings.tray_recent_projects_count as usize;

    let projects = crate::projects::read_projects(app);
    let mut recent: Vec<&Project> = projects
        .iter()
        .filter(|p| p.last_opened.is_some())
        .collect();
    recent.sort_by(|a, b| {
        b.last_opened
            .as_deref()
            .unwrap()
            .cmp(a.last_opened.as_deref().unwrap())
    });
    let recent = recent.into_iter().take(count).collect::<Vec<_>>();

    if recent.is_empty() {
        Menu::with_items(app, &[&show_item, &sep1, &quit_item])
    } else {
        let mut recent_items = Vec::new();
        for p in &recent {
            let label = if p.name.len() > 48 {
                format!("{}…", &p.name[..47])
            } else {
                p.name.clone()
            };
            let item = MenuItem::with_id(app, &p.id, &label, true, None::<&str>)?;
            recent_items.push(item);
        }
        let recent_refs: Vec<&dyn IsMenuItem<_>> = recent_items
            .iter()
            .map(|item| item as &dyn IsMenuItem<_>)
            .collect();
        let recent_submenu = Submenu::with_items(app, "Open Recent", true, &recent_refs)?;
        let mut menu_items: Vec<&dyn IsMenuItem<_>> = vec![
            &show_item as &dyn IsMenuItem<_>,
            &sep1 as &dyn IsMenuItem<_>,
        ];
        menu_items.push(&recent_submenu as &dyn IsMenuItem<_>);
        menu_items.push(&sep2 as &dyn IsMenuItem<_>);
        menu_items.push(&quit_item as &dyn IsMenuItem<_>);
        Menu::with_items(app, &menu_items)
    }
}

#[tauri::command]
fn refresh_tray_menu(app: tauri::AppHandle) -> Result<(), String> {
    let state = app.state::<TrayState>();
    let guard = state.0.lock().unwrap();
    if let Some(ref tray) = *guard {
        let new_menu = build_tray_menu(&app).map_err(|e| e.to_string())?;
        tray.set_menu(Some(new_menu)).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            show_main_window(app);
        }))
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_prevent_default::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .setup(|app| {
            let handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                let s = settings::read_settings(&handle);
                if !s.project_scan_dirs.is_empty() {
                    drop(scan::scan_for_projects(
                        handle.clone(),
                        s.project_scan_dirs.clone(),
                        s.scan_depth,
                    ));
                }
                if !s.version_scan_dirs.is_empty() {
                    drop(scan::scan_for_versions(
                        handle.clone(),
                        s.version_scan_dirs.clone(),
                        s.scan_depth,
                    ));
                }
                if s.template_scan_dir.is_some() {
                    let _ = templates::sync_templates_with_scan_dir(handle.clone());
                }

                if s.auto_watch_project_dirs && !s.project_scan_dirs.is_empty() {
                    let dirs: Vec<std::path::PathBuf> = s.project_scan_dirs.iter().map(|d| std::path::PathBuf::from(d)).collect();
                    watcher::start_project_watchers(handle.clone(), dirs, s.scan_depth, 2000);
                }
                if s.auto_watch_version_dirs && !s.version_scan_dirs.is_empty() {
                    let dirs: Vec<std::path::PathBuf> = s.version_scan_dirs.iter().map(|d| std::path::PathBuf::from(d)).collect();
                    watcher::start_version_watchers(handle.clone(), dirs, s.scan_depth, 2000);
                }
                if s.auto_watch_template_dir {
                    if let Some(ref tdir) = s.template_scan_dir {
                        let dir = std::path::PathBuf::from(tdir);
                        if dir.exists() {
                            watcher::start_template_watcher(handle.clone(), dir, 2000);
                        }
                    }
                }
            });

            app.manage(watcher::ActiveWatchers(std::sync::Mutex::new(Vec::new())));

            app.manage(TrayState(std::sync::Mutex::new(None)));
            app.manage(projects::ActiveProcesses(std::sync::Mutex::new(
                std::collections::HashMap::new(),
            )));

            let tray_menu = build_tray_menu(app.handle())?;
            let tray = TrayIconBuilder::new()
                .icon(
                    app.default_window_icon()
                        .cloned()
                        .expect("no default window icon set"),
                )
                .menu(&tray_menu)
                .show_menu_on_left_click(false)
                .tooltip("GodotHub")
                .on_menu_event(|app, event| match event.id.as_ref() {
                    "show" => show_main_window(app),
                    "quit" => app.exit(0),
                    id => {
                        let _ = projects::open_project(
                            app.clone(),
                            id.to_string(),
                            true,
                        );
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

            app.state::<TrayState>().0.lock().unwrap().replace(tray);

            Ok(())
        })
        .on_window_event(|window, event| {
            if let WindowEvent::CloseRequested { api, .. } = event {
                if window.label() == "main"
                    && settings::read_settings(window.app_handle()).minimize_to_tray
                {
                    api.prevent_close();
                    let _ = window.hide();
                }
            }
        })
        .invoke_handler(tauri::generate_handler![
            godot_versions::fetch_available_godot_versions,
            godot_versions::download_godot_version,
            godot_versions::pause_download,
            godot_versions::resume_download,
            godot_versions::cancel_download,
            godot_versions::list_installed_godot_versions,
            godot_versions::rename_godot_version,
            godot_versions::delete_godot_version,
            godot_versions::import_version_zip,
            projects::list_projects,
            projects::create_project,
            projects::import_project,
            projects::remove_project,
            projects::update_project,
            projects::reorder_projects,
            projects::open_project,
            projects::open_project_folder,
            projects::open_in_editor,
            projects::get_project_icon,
            projects::get_project_size,
            projects::get_project_name,
            projects::validate_godot_folder,
            projects::stop_project,
            projects::pick_file,
            categories::list_categories,
            categories::create_category,
            categories::update_category,
            categories::rename_category,
            categories::delete_category,
            categories::reorder_categories,
            settings::get_settings,
            settings::update_settings,
            settings::reset_settings,
            settings::reset_app_data,
            settings::export_settings,
            settings::import_settings,
            workspace::list_workspaces,
            workspace::create_workspace,
            workspace::switch_workspace,
            workspace::update_workspace,
            workspace::delete_workspace,
            scan::scan_for_projects,
            scan::scan_for_versions,
            news::fetch_godot_news,
            scan::import_version,
            templates::list_templates,
            templates::save_project_as_template,
            templates::delete_template,
            templates::sync_templates_with_scan_dir,
            templates::get_template_preview,
            changelog::list_changelog_entries,
            changelog::add_changelog_entry,
            changelog::update_changelog_entry,
            changelog::delete_changelog_entry,
            git::clone_repo,
            git::get_git_status,
            git::batch_git_status,
            git::open_terminal,
            git::git_pull,
            git::git_fetch,
            git::git_push,
            git::git_log,
            git::git_log_entries,
            git::git_remote_url,
            git::git_list_branches,
            git::git_switch_branch,
            git::git_create_branch,
            git::git_delete_branch,
            git::git_stash_push,
            git::git_stash_list,
            git::git_stash_apply,
            git::git_stash_drop,
            git::git_changed_files,
            git::git_discard_changes,
            git::git_init,
            git::git_stage_file,
            git::git_unstage_file,
            git::git_commit,
            git::git_set_remote,
            git::git_remove_remote,
            git::git_file_diff,
            git::git_undo_commit,
            git::git_undo_pull,
            git::git_merge_conflict_files,
            git::git_resolve_conflict_ours,
            git::git_resolve_conflict_theirs,
            git::git_resolve_conflict_manual,
            git::git_abort_merge,
            git::git_is_merging,
            watcher::restart_watchers,
            refresh_tray_menu,
            pick_folder,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
