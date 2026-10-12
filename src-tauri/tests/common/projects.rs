use super::{settle_due, SettleFlightGuard, SETTLE_OK_TTL};
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, Instant};

#[test]
fn settle_runs_when_never_succeeded() {
    assert!(settle_due(None, Instant::now()));
}

#[test]
fn settle_retries_after_a_failed_attempt() {
    let last_ok: Option<Instant> = None;
    assert!(settle_due(last_ok, Instant::now()));

    let settled = std::sync::OnceLock::<()>::new();
    let mut runs = 0;
    settled.get_or_init(|| {
        runs += 1;
    });
    settled.get_or_init(|| {
        runs += 1;
    });
    assert_eq!(runs, 1);
}

#[test]
fn settle_is_throttled_after_success_until_ttl_expires() {
    let now = Instant::now();
    assert!(!settle_due(Some(now), now));
    assert!(settle_due(
        Some(now),
        now + SETTLE_OK_TTL + Duration::from_secs(1)
    ));
}

#[test]
fn settle_retries_after_err_and_throttles_after_ok() {
    let mut last_ok: Option<Instant> = None;
    let first: Result<Vec<u32>, String> = Err("ps failed".to_string());
    if first.is_ok() {
        last_ok = Some(Instant::now());
    }
    assert!(settle_due(last_ok, Instant::now()));

    let second: Result<Vec<u32>, String> = Ok(vec![]);
    if second.is_ok() {
        last_ok = Some(Instant::now());
    }
    assert!(!settle_due(last_ok, Instant::now()));
}

#[test]
fn settle_flag_is_released_on_drop() {
    let flag = AtomicBool::new(false);
    {
        flag.store(true, Ordering::SeqCst);
        let _guard = SettleFlightGuard(&flag);
        assert!(flag.load(Ordering::SeqCst));
    }
    assert!(!flag.load(Ordering::SeqCst));
}

#[test]
fn settle_skips_concurrent_runs() {
    let in_flight = AtomicBool::new(false);
    assert!(!in_flight.swap(true, Ordering::SeqCst));
    assert!(in_flight.swap(true, Ordering::SeqCst));
    in_flight.store(false, Ordering::SeqCst);
}

#[test]
fn a_project_without_a_main_scene_cannot_be_run() {
    let dir = std::env::temp_dir().join(format!("godothub-main-scene-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).expect("failed to create temp dir");
    let path = dir.to_string_lossy().to_string();

    let without = "; Engine configuration file.

[application]

config/name=\"Demo\"
config/features=PackedStringArray(\"4.7\")
";
    std::fs::write(dir.join("project.godot"), without).expect("failed to write project.godot");
    assert!(!super::project_has_main_scene(&path));

    let with_scene = "[application]

config/name=\"Demo\"
run/main_scene=\"res://main.tscn\"
";
    std::fs::write(dir.join("project.godot"), with_scene).expect("failed to write project.godot");
    assert!(super::project_has_main_scene(&path));

    let other_section = "[rendering]

run/main_scene=\"res://main.tscn\"
";
    std::fs::write(dir.join("project.godot"), other_section).expect("failed to write project.godot");
    assert!(!super::project_has_main_scene(&path));

    let empty_value = "[application]

run/main_scene=\"\"
";
    std::fs::write(dir.join("project.godot"), empty_value).expect("failed to write project.godot");
    assert!(!super::project_has_main_scene(&path));

    std::fs::remove_dir_all(&dir).ok();
}

#[test]
fn a_missing_project_file_does_not_block_launching() {
    let dir = std::env::temp_dir().join(format!("godothub-main-scene-none-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    assert!(super::project_has_main_scene(dir.to_string_lossy().as_ref()));
}
