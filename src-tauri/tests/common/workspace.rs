use super::{read_state_in, recover_state, workspace_dir_in, write_state_in, META_FILE};
use crate::models::{Workspace, WorkspacesState};
use std::fs;
use std::path::{Path, PathBuf};

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

fn workspace(id: &str, name: &str) -> Workspace {
    Workspace {
        id: id.to_string(),
        name: name.to_string(),
        icon: "briefcase".to_string(),
        color: "#457ff2".to_string(),
        created_at: "2026-01-01T00:00:00+00:00".to_string(),
    }
}

fn write_settings(dir: &Path, setup_complete: bool) {
    fs::write(
        dir.join("settings.json"),
        format!("{{\n  \"setup_complete\": {setup_complete}\n}}\n"),
    )
    .expect("failed to write settings");
}

fn file_names(dir: &Path) -> Vec<String> {
    fs::read_dir(dir)
        .expect("failed to read dir")
        .flatten()
        .map(|e| e.file_name().to_string_lossy().to_string())
        .collect()
}

#[test]
fn fresh_install_creates_a_single_default_workspace() {
    let base = temp_dir("ws-fresh");

    let state = read_state_in(&base);

    assert_eq!(state.workspaces.len(), 1);
    assert_eq!(state.workspaces[0].name, "Default");
    assert_eq!(state.active_id, state.workspaces[0].id);
    assert!(base.join("workspaces.json").is_file());
    assert!(workspace_dir_in(&base, &state.active_id)
        .join(META_FILE)
        .is_file());

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn legacy_files_next_to_the_index_move_into_the_new_workspace() {
    let base = temp_dir("ws-legacy");
    fs::write(base.join("settings.json"), "{\"setup_complete\": true}").expect("write failed");

    let state = read_state_in(&base);

    let dir = workspace_dir_in(&base, &state.active_id);
    assert!(dir.join("settings.json").is_file());
    assert!(!base.join("settings.json").exists());

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn a_valid_index_is_left_alone() {
    let base = temp_dir("ws-valid");
    let state = WorkspacesState {
        workspaces: vec![workspace("only", "Mine")],
        active_id: "only".to_string(),
    };
    write_state_in(&base, &state).expect("write failed");

    assert_eq!(read_state_in(&base), state);

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn an_active_id_pointing_nowhere_is_repaired() {
    let base = temp_dir("ws-bad-active");
    let broken = WorkspacesState {
        workspaces: vec![workspace("only", "Mine")],
        active_id: "gone".to_string(),
    };
    write_state_in(&base, &broken).expect("write failed");

    let state = read_state_in(&base);

    assert_eq!(state.active_id, "only");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn rebuilds_the_library_from_disk_when_the_index_is_gone() {
    let base = temp_dir("ws-recover");
    let first = workspace_dir_in(&base, "first");
    let second = workspace_dir_in(&base, "second");
    write_settings(&first, false);
    write_settings(&second, true);
    fs::write(second.join("projects.json"), "[]").expect("failed to write projects");

    let state = read_state_in(&base);

    assert_eq!(state.workspaces.len(), 2);
    let names: Vec<&str> = state.workspaces.iter().map(|w| w.name.as_str()).collect();
    assert_eq!(names, vec!["Recovered 1", "Recovered 2"]);
    assert_eq!(state.active_id, "second");

    let again = read_state_in(&base);
    assert_eq!(again.workspaces, state.workspaces);
    assert_eq!(again.active_id, "second");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn recovery_uses_the_meta_file_when_a_workspace_has_one() {
    let base = temp_dir("ws-meta");
    let dir = workspace_dir_in(&base, "abc");
    fs::write(
        dir.join(META_FILE),
        serde_json::to_string(&workspace("abc", "My Space")).expect("serialize failed"),
    )
    .expect("failed to write meta");
    write_settings(&dir, true);

    let state = read_state_in(&base);

    assert_eq!(state.workspaces.len(), 1);
    assert_eq!(state.workspaces[0], workspace("abc", "My Space"));
    assert_eq!(state.active_id, "abc");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn a_truncated_index_falls_back_to_its_backup() {
    let base = temp_dir("ws-truncated");
    let original = WorkspacesState {
        workspaces: vec![workspace("ws-1", "Keep me")],
        active_id: "ws-1".to_string(),
    };
    write_state_in(&base, &original).expect("first write failed");
    write_state_in(
        &base,
        &WorkspacesState {
            workspaces: vec![workspace("ws-2", "Newer")],
            active_id: "ws-2".to_string(),
        },
    )
    .expect("second write failed");
    assert!(base.join("workspaces.json.bak").is_file());

    fs::write(base.join("workspaces.json"), "{\"workspaces\": [{").expect("truncation failed");

    let state = read_state_in(&base);

    assert_eq!(state.active_id, "ws-1");
    assert_eq!(state.workspaces[0].name, "Keep me");

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn an_unusable_index_is_kept_for_forensics() {
    let base = temp_dir("ws-forensics");
    let dir = workspace_dir_in(&base, "kept");
    write_settings(&dir, true);
    fs::write(base.join("workspaces.json"), "not json at all").expect("write failed");

    let state = read_state_in(&base);

    assert_eq!(state.active_id, "kept");
    let damaged = file_names(&base)
        .into_iter()
        .filter(|name| name.starts_with("workspaces.json.corrupt-"))
        .count();
    assert_eq!(damaged, 1, "the damaged index should be set aside");
    assert!(base.join("diagnostics.log").is_file());

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn folders_without_workspace_data_are_not_recovered() {
    let base = temp_dir("ws-empty-folders");
    workspace_dir_in(&base, "empty");

    assert!(recover_state(&base).is_none());

    let _ = fs::remove_dir_all(&base);
}

#[test]
fn recovery_pulls_legacy_files_into_the_recovered_workspace() {
    let base = temp_dir("ws-recover-legacy");
    let dir = workspace_dir_in(&base, "kept");
    fs::write(dir.join("projects.json"), "[]").expect("failed to write projects");
    // The real settings are still sitting next to the index, from before the
    // workspace layout existed.
    fs::write(base.join("settings.json"), "{\"setup_complete\": true}").expect("write failed");
    fs::write(base.join("workspaces.json"), "not json at all").expect("write failed");

    let state = read_state_in(&base);

    assert_eq!(state.active_id, "kept");
    assert!(
        workspace_dir_in(&base, "kept").join("settings.json").is_file(),
        "legacy settings should follow into the recovered workspace"
    );
    assert!(!base.join("settings.json").exists());

    let _ = fs::remove_dir_all(&base);
}
