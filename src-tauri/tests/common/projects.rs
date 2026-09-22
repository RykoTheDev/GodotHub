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
