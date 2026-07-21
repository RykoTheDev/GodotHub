use crate::templates;
use notify::{Config, Event, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{channel, RecvTimeoutError};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter, Manager};

pub struct ActiveWatchers(pub Mutex<Vec<RecommendedWatcher>>);

fn create_debounced_watcher(
    app: AppHandle,
    path: PathBuf,
    debounce_duration: Duration,
    extra_delay: Duration,
    action: Arc<dyn Fn(AppHandle) + Send + Sync + 'static>,
    event_name: &'static str,
) -> Option<RecommendedWatcher> {
    let (tx, rx) = channel::<Result<Event, notify::Error>>();

    let mut watcher = match RecommendedWatcher::new(
        move |res: Result<Event, notify::Error>| {
            let _ = tx.send(res);
        },
        Config::default(),
    ) {
        Ok(w) => w,
        Err(e) => {
            eprintln!("[watcher] Failed to create watcher: {e}");
            return None;
        }
    };

    if let Err(e) = watcher.watch(&path, RecursiveMode::Recursive) {
        eprintln!("[watcher] Failed to watch '{}': {e}", path.display());
        return None;
    }

    let running = Arc::new(AtomicBool::new(true));
    let r = running.clone();

    std::thread::spawn(move || {
        let mut last_event = Instant::now();
        let mut pending = false;

        while r.load(Ordering::SeqCst) {
            match rx.recv_timeout(Duration::from_millis(500)) {
                Ok(Ok(event)) => {
                    match event.kind {
                        EventKind::Access(_)
                        | EventKind::Other
                        | EventKind::Any => continue,
                        _ => {
                            last_event = Instant::now();
                            pending = true;
                        }
                    }
                }
                Ok(Err(e)) => {
                    eprintln!("[watcher] Event error: {e}");
                }
                Err(RecvTimeoutError::Timeout) => {
                    if pending && last_event.elapsed() >= debounce_duration {
                        pending = false;
                        if !extra_delay.is_zero() {
                            std::thread::sleep(extra_delay);
                        }
                        let app = app.clone();
                        let action = action.clone();
                        std::thread::spawn(move || {
                            action(app.clone());
                            let _ = app.emit(event_name, ());
                        });
                    }
                }
                Err(RecvTimeoutError::Disconnected) => break,
            }
        }
    });

    Some(watcher)
}

fn create_debounced_multi_watcher(
    app: AppHandle,
    dirs: Vec<PathBuf>,
    debounce_duration: Duration,
    extra_delay: Duration,
    action: Arc<dyn Fn(AppHandle) + Send + Sync + 'static>,
    event_name: &'static str,
) -> Option<RecommendedWatcher> {
    if dirs.is_empty() {
        return None;
    }

    let (tx, rx) = channel::<Result<Event, notify::Error>>();

    let mut watcher = match RecommendedWatcher::new(
        move |res: Result<Event, notify::Error>| {
            let _ = tx.send(res);
        },
        Config::default(),
    ) {
        Ok(w) => w,
        Err(e) => {
            eprintln!("[watcher] Failed to create watcher: {e}");
            return None;
        }
    };

    for dir in &dirs {
        if dir.exists() {
            if let Err(e) = watcher.watch(dir, RecursiveMode::Recursive) {
                eprintln!("[watcher] Failed to watch '{}': {e}", dir.display());
            }
        }
    }

    let running = Arc::new(AtomicBool::new(true));
    let r = running.clone();

    std::thread::spawn(move || {
        let mut last_event = Instant::now();
        let mut pending = false;

        while r.load(Ordering::SeqCst) {
            match rx.recv_timeout(Duration::from_millis(500)) {
                Ok(Ok(event)) => {
                    match event.kind {
                        EventKind::Access(_)
                        | EventKind::Other
                        | EventKind::Any => continue,
                        _ => {
                            last_event = Instant::now();
                            pending = true;
                        }
                    }
                }
                Ok(Err(e)) => {
                    eprintln!("[watcher] Event error: {e}");
                }
                Err(RecvTimeoutError::Timeout) => {
                    if pending && last_event.elapsed() >= debounce_duration {
                        pending = false;
                        if !extra_delay.is_zero() {
                            std::thread::sleep(extra_delay);
                        }
                        let app = app.clone();
                        let action = action.clone();
                        std::thread::spawn(move || {
                            action(app.clone());
                            let _ = app.emit(event_name, ());
                        });
                    }
                }
                Err(RecvTimeoutError::Disconnected) => break,
            }
        }
    });

    Some(watcher)
}

pub fn start_template_watcher(app: AppHandle, scan_dir: PathBuf, debounce_ms: u64) {
    let watcher = create_debounced_watcher(
        app.clone(),
        scan_dir,
        Duration::from_millis(debounce_ms),
        Duration::from_millis(800),
        Arc::new(move |a| {
            let _ = templates::sync_templates_with_scan_dir(a);
        }) as Arc<dyn Fn(AppHandle) + Send + Sync + 'static>,
        "watcher:template-synced",
    );

    if let Some(w) = watcher {
        if let Some(state) = app.try_state::<ActiveWatchers>() {
            state.0.lock().unwrap().push(w);
        }
    }
}

pub fn start_project_watchers(app: AppHandle, dirs: Vec<PathBuf>, depth: u32, debounce_ms: u64) {
    let app_clone = app.clone();
    let watcher = create_debounced_multi_watcher(
        app,
        dirs,
        Duration::from_millis(debounce_ms),
        Duration::from_millis(1500),
        Arc::new(move |a: AppHandle| {
            let dirs: Vec<String> = a
                .try_state::<ActiveWatchers>()
                .and_then(|_| {
                    let s = crate::settings::read_settings(&a);
                    Some(s.project_scan_dirs.clone())
                })
                .unwrap_or_default();
            if !dirs.is_empty() {
                let result = crate::scan::scan_for_projects_blocking(
                    a.clone(),
                    dirs,
                    depth,
                );
                if let Err(e) = result {
                    eprintln!("[watcher] Project auto-scan failed: {e}");
                }
            }
        }) as Arc<dyn Fn(AppHandle) + Send + Sync + 'static>,
        "watcher:project-scan-done",
    );

    if let Some(w) = watcher {
        if let Some(state) = app_clone.try_state::<ActiveWatchers>() {
            state.0.lock().unwrap().push(w);
        }
    }
}

pub fn start_version_watchers(app: AppHandle, dirs: Vec<PathBuf>, depth: u32, debounce_ms: u64) {
    let app_clone = app.clone();
    let watcher = create_debounced_multi_watcher(
        app,
        dirs,
        Duration::from_millis(debounce_ms),
        Duration::from_millis(1500),
        Arc::new(move |a: AppHandle| {
            let dirs: Vec<String> = a
                .try_state::<ActiveWatchers>()
                .and_then(|_| {
                    let s = crate::settings::read_settings(&a);
                    Some(s.version_scan_dirs.clone())
                })
                .unwrap_or_default();
            if !dirs.is_empty() {
                let result = crate::scan::scan_for_versions_blocking(
                    a.clone(),
                    dirs,
                    depth,
                );
                if let Err(e) = result {
                    eprintln!("[watcher] Version auto-scan failed: {e}");
                }
            }
        }) as Arc<dyn Fn(AppHandle) + Send + Sync + 'static>,
        "watcher:version-scan-done",
    );

    if let Some(w) = watcher {
        if let Some(state) = app_clone.try_state::<ActiveWatchers>() {
            state.0.lock().unwrap().push(w);
        }
    }
}

#[tauri::command]
pub fn restart_watchers(app: AppHandle) -> Result<(), String> {
    if let Some(state) = app.try_state::<ActiveWatchers>() {
        state.0.lock().unwrap().clear();
    }

    let s = crate::settings::read_settings(&app);

    if s.auto_watch_project_dirs && !s.project_scan_dirs.is_empty() {
        let dirs: Vec<PathBuf> = s.project_scan_dirs.iter().map(|d| PathBuf::from(d)).collect();
        start_project_watchers(app.clone(), dirs, s.scan_depth, 2000);
    }
    if s.auto_watch_version_dirs && !s.version_scan_dirs.is_empty() {
        let dirs: Vec<PathBuf> = s.version_scan_dirs.iter().map(|d| PathBuf::from(d)).collect();
        start_version_watchers(app.clone(), dirs, s.scan_depth, 2000);
    }
    if s.auto_watch_template_dir {
        if let Some(ref tdir) = s.template_scan_dir {
            let dir = PathBuf::from(tdir);
            if dir.exists() {
                start_template_watcher(app.clone(), dir, 2000);
            }
        }
    }

    Ok(())
}
