use super::{mutate_projects_in, same_path};
use crate::models::Project;
use crate::persist;
use crate::FileLocks;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;

const WRITERS: usize = 4;
const PROJECTS_PER_WRITER: usize = 10;

fn temp_dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!(
        "godothub-{name}-{}-{:?}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or_default()
    ));
    fs::create_dir_all(&dir).expect("failed to create temp dir");
    dir
}

fn project(path: &str) -> Project {
    Project {
        id: path.to_string(),
        name: path.to_string(),
        path: path.to_string(),
        godot_version: "4.3-stable".to_string(),
        created_at: String::new(),
        last_opened: None,
        category: None,
        pinned: false,
        sort_order: 0,
        launch_arguments: String::new(),
        tags: vec![],
        total_time_seconds: 0,
        session_started_at_ms: None,
        time_today_seconds: 0,
        time_week_seconds: 0,
    }
}

fn register_projects(dir: &Path, locks: &FileLocks, prefix: &str) {
    for i in 0..PROJECTS_PER_WRITER {
        let path = format!("{prefix}-{i}");
        mutate_projects_in(dir, locks, |projects| {
            if !projects.iter().any(|p| same_path(&p.path, &path)) {
                projects.push(project(&path));
            }
            Ok(((), true))
        })
        .expect("registration failed");
    }
}

#[test]
fn concurrent_writers_keep_every_project() {
    let dir = temp_dir("projects-lock");
    let locks = Arc::new(FileLocks::default());

    let writers: Vec<_> = (0..WRITERS)
        .map(|writer| {
            let dir = dir.clone();
            let locks = Arc::clone(&locks);
            std::thread::spawn(move || register_projects(&dir, &locks, &format!("scan-{writer}")))
        })
        .collect();

    for writer in writers {
        writer.join().expect("writer thread panicked");
    }

    let stored: Vec<Project> = persist::read_json(&dir.join("projects.json"));
    let mut paths: Vec<String> = stored.into_iter().map(|p| p.path).collect();
    paths.sort();

    let expected: Vec<String> = (0..WRITERS)
        .flat_map(|writer| (0..PROJECTS_PER_WRITER).map(move |i| format!("scan-{writer}-{i}")))
        .collect();
    assert_eq!(paths, expected, "a concurrent registration was lost");

    let _ = fs::remove_dir_all(&dir);
}
