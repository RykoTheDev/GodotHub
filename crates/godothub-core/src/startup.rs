use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Mutex;

use crate::{
    asset_library, console, export_runner, git_helpers, godot_versions, identifier_migration, mise, projects, scan,
    settings, templates, watcher, AppHandle,
};

pub fn initialize(app: &AppHandle) {
    identifier_migration::migrate_identifier(app);

    if let Ok(dir) = app.path().app_data_dir() {
        git_helpers::set_credential_store(dir.join("git-credentials"));
    }

    app.manage(asset_library::AssetResponseCache::default());
    app.manage(watcher::ActiveWatchers(Mutex::new(Vec::new())));
    app.manage(watcher::GitWatcher(Mutex::new(None)));
    app.manage(watcher::AliasWatcher(Mutex::new(None)));

    watcher::start_alias_watcher(app.clone());

    godot_versions::migrate_registry_to_global(app);

    app.manage(projects::ActiveProcesses(Mutex::new(HashMap::new())));
    app.manage(console::ConsoleBuffers::default());
    app.manage(export_runner::ExportRuns::default());
}

pub async fn background_tasks(handle: AppHandle) {
    templates::consolidate_legacy_templates(&handle);
    let _ = tokio::task::spawn_blocking(crate::updater::remove_stale_temp_dirs).await;

    let s = settings::read_settings(&handle);

    if s.use_mise {
        let mise_handle = handle.clone();
        let _ = tokio::task::spawn_blocking(move || mise::sync_installed(&mise_handle)).await;
    }

    if s.setup_complete && s.auto_scan_on_startup {
        let scan_handle = handle.clone();
        let project_dirs = s.project_scan_dirs.clone();
        let version_dirs = s.version_scan_dirs.clone();
        let depth = s.scan_depth;
        let _ = tokio::task::spawn_blocking(move || {
            if !version_dirs.is_empty() {
                if let Err(e) = scan::scan_for_versions_blocking(scan_handle.clone(), version_dirs, depth) {
                    eprintln!("Startup version scan failed: {e}");
                }
            }
            if !project_dirs.is_empty() {
                if let Err(e) = scan::scan_for_projects_blocking(scan_handle, project_dirs, depth, false) {
                    eprintln!("Startup project scan failed: {e}");
                }
            }
        })
        .await;
    }

    if s.feature_enabled("templates") && s.template_scan_dir.is_some() {
        let _ = templates::sync_templates_with_scan_dir(handle.clone()).await;
    }

    if s.auto_watch_project_dirs && !s.project_scan_dirs.is_empty() {
        let dirs: Vec<PathBuf> = s.project_scan_dirs.iter().map(PathBuf::from).collect();
        watcher::start_project_watchers(handle.clone(), dirs, s.scan_depth, 2000);
    }
    if s.auto_watch_version_dirs && !s.version_scan_dirs.is_empty() {
        let dirs: Vec<PathBuf> = s.version_scan_dirs.iter().map(PathBuf::from).collect();
        watcher::start_version_watchers(handle.clone(), dirs, s.scan_depth, 2000);
    }
    if s.feature_enabled("templates") && s.auto_watch_template_dir {
        if let Some(ref tdir) = s.template_scan_dir {
            let dir = PathBuf::from(tdir);
            if dir.exists() {
                watcher::start_template_watcher(handle.clone(), dir, 2000);
            }
        }
    }
}
