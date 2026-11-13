mod commands;
mod dialogs;
mod host;
mod lane;
mod recent_menu;
mod tray;

use tauri::{Manager, WindowEvent};

pub(crate) use host::core_handle;

#[tauri::command]
fn notify(app: tauri::AppHandle, title: String, body: String) {
    use tauri_plugin_notification::NotificationExt;
    let _ = app.notification().builder().title(title).body(body).show();
}

#[tauri::command]
fn get_os_username() -> Option<String> {
    godothub_core::system::get_os_username()
}

/// Called by the frontend once it has painted a frame. Confirms that the
/// accelerated WebKitGTK path draws on this machine, so the next launch does not
/// fall back to the software renderer.
#[tauri::command]
fn renderer_healthy() {
    godothub_core::renderer::mark_painted();
}

pub fn run_cli() -> Option<i32> {
    godothub_core::set_app_version(env!("CARGO_PKG_VERSION"));
    godothub_core::cli::dispatch(host::CHANNEL)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    godothub_core::set_app_version(env!("CARGO_PKG_VERSION"));
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, args, _cwd| {
            if !godothub_core::recent::open_from_args(&core_handle(app), &args) {
                tray::show_main_window(app);
            }
        }))
        .plugin(tauri_plugin_discord_rpc::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_prevent_default::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(
            tauri_plugin_window_state::Builder::default()
                .with_state_flags(
                    tauri_plugin_window_state::StateFlags::SIZE
                        | tauri_plugin_window_state::StateFlags::POSITION
                        | tauri_plugin_window_state::StateFlags::MAXIMIZED,
                )
                .build(),
        )
        .setup(|app| {
            let core = host::create(app.handle());
            app.manage(core.clone());
            godothub_core::startup::initialize(&core);

            #[cfg(not(target_os = "macos"))]
            {
                let settings = godothub_core::settings::read_settings(&core);
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.set_decorations(settings.use_os_decorations);
                }
            }

            tauri::async_runtime::spawn(godothub_core::startup::background_tasks(core.clone()));

            app.manage(tray::TrayState(std::sync::Mutex::new(None)));

            tray::setup_tray(app.handle())?;
            tray::show_main_window(app.handle());
            let launch_args: Vec<String> = std::env::args().collect();
            godothub_core::recent::open_from_args(&core, &launch_args);

            Ok(())
        })
        .on_window_event(|window, event| {
            if let WindowEvent::CloseRequested { api, .. } = event {
                if window.label() != "main" {
                    return;
                }

                {
                    use tauri_plugin_window_state::AppHandleExt as _;
                    let _ = window.app_handle().save_window_state(
                        tauri_plugin_window_state::StateFlags::SIZE
                            | tauri_plugin_window_state::StateFlags::POSITION
                            | tauri_plugin_window_state::StateFlags::MAXIMIZED,
                    );
                }

                #[cfg(target_os = "macos")]
                let keep_alive = true;
                #[cfg(not(target_os = "macos"))]
                let keep_alive =
                    godothub_core::settings::read_settings(&core_handle(window.app_handle())).minimize_to_tray;

                if keep_alive {
                    api.prevent_close();
                    let _ = window.hide();
                }
            }
        })
        .invoke_handler(tauri::generate_handler![
            commands::godot_versions::fetch_available_godot_versions,
            commands::godot_versions::open_versions_folder,
            commands::godot_versions::download_godot_version,
            commands::godot_versions::download_version_for_tag,
            commands::godot_versions::pause_download,
            commands::godot_versions::resume_download,
            commands::godot_versions::cancel_download,
            commands::godot_versions::reorder_download_queue,
            commands::godot_versions::list_installed_godot_versions,
            commands::godot_versions::rename_godot_version,
            commands::godot_versions::delete_godot_version,
            commands::godot_versions::open_godot_version,
            commands::godot_versions::test_github_token,
            commands::godot_versions::get_github_rate_limit,
            commands::discovery::scan_godot_recent_projects,
            commands::discovery::detect_godot_installs,
            commands::discovery::import_detected_install,
            commands::current_version::get_current_version,
            commands::current_version::set_current_version,
            commands::current_version::clear_current_version,
            commands::current_version::list_version_aliases,
            commands::current_version::create_version_aliases,
            commands::current_version::delete_version_alias,
            commands::git_auth::start_device_flow,
            commands::git_auth::poll_device_flow,
            commands::git_auth::get_git_auth_state,
            commands::git_auth::disconnect_git_auth,
            commands::git_auth::save_git_pat,
            commands::git_auth::remove_git_pat,
            commands::git_auth::create_remote_repo,
            commands::git_auth::list_user_repos,
            commands::git_auth::git_branch_protection,
            commands::git_auth::git_open_pull_request,
            commands::export_templates::get_export_templates_state,
            commands::export_templates::get_export_template_options,
            commands::export_templates::install_export_templates,
            commands::export_templates::cancel_export_templates_download,
            commands::export_templates::delete_export_templates,
            commands::export_templates::uninstall_export_template_files,
            commands::export_templates::open_export_templates_folder,
            commands::storage::get_storage_report,
            commands::storage::reclaim_storage,
            commands::projects::list_projects,
            commands::projects::get_projects_health,
            commands::projects::restore_projects_from_backup,
            commands::projects::create_project,
            commands::projects::duplicate_project,
            commands::projects::import_project,
            commands::projects::remove_project,
            commands::projects::update_project,
            commands::projects::reorder_projects,
            commands::projects::open_project,
            commands::projects::open_project_folder,
            commands::projects::open_in_editor,
            commands::projects::get_project_icon,
            commands::projects::get_project_size,
            commands::projects::get_project_file_tree,
            commands::projects::get_project_name,
            commands::projects::stop_project,
            commands::projects::list_running_projects,
            commands::projects::read_image_file,
            commands::projects::write_project_tags,
            commands::projects::export_project_stats,
            commands::projects::import_project_stats,
            commands::projects::reintroduce_dismissed_projects,
            commands::project_todos::list_project_todos,
            commands::project_todos::save_project_todos,
            commands::project_todos::list_open_todos,
            commands::todo_sync::sync_project_todos,
            commands::todo_sync::todo_git_activity,
            commands::todo_sync::list_project_resources,
            commands::todo_sync::open_todo_link,
            commands::cli_shim::cli_tool_status,
            commands::cli_shim::install_cli_tool,
            commands::cli_shim::uninstall_cli_tool,
            commands::project_health::diagnose_project,
            commands::project_health::fix_project_health,
            commands::console::get_project_console,
            commands::console::clear_project_console,
            commands::export_runner::get_project_export_presets,
            commands::export_runner::start_project_export,
            commands::export_runner::get_project_export,
            commands::export_runner::get_project_exports,
            commands::export_runner::cancel_project_export,
            commands::export_runner::open_export_artifact_folder,
            commands::time_stats::get_activity,
            commands::time_stats::get_project_activity,
            commands::time_stats::get_time_insights,
            commands::time_stats::clear_time_stats,
            commands::categories::list_categories,
            commands::categories::create_category,
            commands::categories::update_category,
            commands::categories::rename_category,
            commands::categories::delete_category,
            commands::categories::reorder_categories,
            commands::categories::add_category_folder,
            commands::categories::remove_category_folder,
            commands::settings::get_settings,
            commands::settings::update_settings,
            commands::settings::reset_settings,
            commands::settings::export_settings,
            commands::settings::import_settings,
            commands::settings::reset_app_data,
            commands::backup::export_workspace_backup,
            commands::backup::import_workspace_backup,
            commands::backup::export_app_backup,
            commands::backup::import_app_backup,
            commands::sync::gist_sync_push,
            commands::sync::gist_sync_pull,
            commands::sync::gist_sync_get_info,
            commands::sync::gist_sync_pull_by_url,
            commands::sync::gist_sync_fetch_backup,
            commands::sync::gist_sync_save_gist_url,
            commands::workspace::list_workspaces,
            commands::workspace::list_workspace_scan_dirs,
            commands::workspace::create_workspace,
            commands::workspace::switch_workspace,
            commands::workspace::update_workspace,
            commands::workspace::delete_workspace,
            commands::scan::scan_for_projects,
            commands::scan::scan_for_projects_with_info,
            commands::scan::scan_for_versions,
            commands::scan::import_version,
            commands::scan::add_custom_build,
            commands::news::fetch_godot_news,
            commands::templates::list_templates,
            commands::templates::save_project_as_template,
            commands::templates::delete_template,
            commands::templates::sync_templates_with_scan_dir,
            commands::templates::get_template_preview,
            commands::addons::list_project_addons,
            commands::addons::check_addon_updates,
            commands::addons::update_project_addon,
            commands::tool_runner::list_project_tools,
            commands::tool_runner::run_project_tool,
            commands::tool_runner::stop_project_tool,
            commands::ui_prefs::get_ui_prefs,
            commands::ui_prefs::get_ui_pref,
            commands::ui_prefs::set_ui_pref,
            commands::ui_prefs::remove_ui_pref,
            commands::ui_prefs::import_ui_prefs,
            commands::asset_library::search_asset_library,
            commands::asset_library::install_asset_as_template,
            commands::asset_library::install_asset,
            commands::asset_library::download_asset,
            commands::asset_library::search_asset_store,
            commands::asset_library::download_store_asset,
            commands::asset_library::install_store_asset,
            commands::asset_library::get_asset_library_categories,
            commands::vault::list_vault_items,
            commands::vault::save_to_vault,
            commands::vault::add_vault_item_to_projects,
            commands::vault::delete_vault_item,
            commands::vault::update_vault_item,
            commands::changelog::list_changelog_entries,
            commands::changelog::add_changelog_entry,
            commands::changelog::update_changelog_entry,
            commands::changelog::delete_changelog_entry,
            commands::changelog::list_git_tags,
            commands::changelog::generate_changelog_draft,
            commands::install_mode::is_portable_install,
            commands::mise::mise_status,
            commands::mise::mise_refresh_status,
            commands::mise::mise_sync_godot_versions,
            commands::mise::mise_install_godot_version,
            commands::mise::mise_uninstall_godot_version,
            commands::git::clone_repo,
            commands::git::get_git_status,
            commands::git::batch_git_status,
            commands::git::open_terminal,
            commands::git::git_pull,
            commands::git::git_fetch,
            commands::git::git_push,
            commands::git::git_log_entries,
            commands::git::git_list_remotes,
            commands::git::git_ahead_behind,
            commands::git::git_show_commit,
            commands::git::git_list_branches,
            commands::git::git_branch_publish,
            commands::git::git_switch_branch,
            commands::git::git_create_branch,
            commands::git::git_delete_branch,
            commands::git::git_stash_push,
            commands::git::git_stash_list,
            commands::git::git_stash_apply,
            commands::git::git_stash_show,
            commands::git::git_stash_pop,
            commands::git::git_stash_drop,
            commands::git::git_changed_files,
            commands::git::git_discard_changes,
            commands::git::git_discard_file,
            commands::git::git_init_project,
            commands::git::git_is_available,
            commands::git::git_stage_file,
            commands::git::git_unstage_file,
            commands::git::git_commit,
            commands::git::git_file_diff,
            commands::git::git_undo_commit,
            commands::git::git_undo_pull,
            commands::git::git_merge_conflict_files,
            commands::git::git_resolve_conflict_ours,
            commands::git::git_resolve_conflict_theirs,
            commands::git::git_resolve_conflict_manual,
            commands::git::git_abort_merge,
            commands::git::git_is_merging,
            commands::git::git_worktree_list,
            commands::git::git_worktree_switch,
            commands::git::git_worktree_add,
            commands::git::git_worktree_remove,
            commands::watcher::restart_watchers,
            commands::watcher::start_git_fs_watcher,
            commands::watcher::stop_git_fs_watcher,
            notify,
            renderer_healthy,
            get_os_username,
            dialogs::pick_folder,
            dialogs::pick_save_path,
            dialogs::pick_data_file,
            dialogs::pick_file,
            dialogs::pick_executable,
            tray::refresh_tray_menu,
        ])
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|_app, _event| {
            #[cfg(target_os = "macos")]
            if let tauri::RunEvent::Reopen { .. } = _event {
                tray::show_main_window(_app);
            }
        });
}

#[cfg(test)]
mod tests {
    use godothub_core::{Channel, Paths};
    use tauri::Manager;

    fn tauri_app() -> tauri::App<tauri::test::MockRuntime> {
        tauri::test::mock_builder()
            .build(tauri::generate_context!())
            .expect("failed to build the mock app")
    }

    #[test]
    fn stable_paths_match_tauri_path_resolution() {
        let app = tauri_app();
        let tauri_paths = app.path();
        let core = Paths::for_channel(Channel::Stable);
        assert_eq!(core.app_data_dir().ok(), tauri_paths.app_data_dir().ok());
        assert_eq!(core.app_config_dir().ok(), tauri_paths.app_config_dir().ok());
        assert_eq!(core.app_cache_dir().ok(), tauri_paths.app_cache_dir().ok());
        assert_eq!(core.download_dir().ok(), tauri_paths.download_dir().ok());
        assert_eq!(core.home_dir().ok(), tauri_paths.home_dir().ok());
    }

    #[test]
    fn stable_channel_matches_the_tauri_config() {
        let app = tauri_app();
        let config = app.config();
        let stable = Channel::Stable.info();
        assert_eq!(config.identifier, stable.identifier);
        assert_eq!(config.product_name.as_deref(), Some(stable.display_name));
        let updater = config.plugins.0.get("updater").expect("updater config");
        assert_eq!(updater["pubkey"].as_str(), stable.updater_public_keys.first().copied());
        assert_eq!(updater["endpoints"][0].as_str(), Some(stable.update_endpoint));
    }
}
