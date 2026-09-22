use crate::persist;
use chrono::{Datelike, Duration};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};
use std::sync::atomic::{AtomicU64, Ordering};
use tauri::AppHandle;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionRecord {
    pub start_ms: u64,
    pub seconds: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TimeStatsStore {
    #[serde(default)]
    pub version: u32,
    #[serde(default)]
    pub projects: HashMap<String, Vec<SessionRecord>>,
    #[serde(default)]
    pub daily: HashMap<String, BTreeMap<String, u64>>,
}

pub fn read_stats_from(dir: &std::path::Path) -> TimeStatsStore {
    persist::read_json(&dir.join("time_tracking.json"))
}

pub fn read_stats(app: &AppHandle) -> TimeStatsStore {
    read_stats_from(&crate::workspace::active_workspace_dir(app))
}

pub fn write_stats_to(dir: &std::path::Path, store: &TimeStatsStore) {
    let _ = persist::write_json(&dir.join("time_tracking.json"), store);
}

pub fn write_stats(app: &AppHandle, store: &TimeStatsStore) {
    write_stats_to(&crate::workspace::active_workspace_dir(app), store);
}

fn local_day_start(date: chrono::NaiveDate) -> Option<chrono::DateTime<chrono::Local>> {
    date.and_hms_opt(0, 0, 0)
        .and_then(|dt| dt.and_local_timezone(chrono::Local).earliest())
}

fn overlap_seconds(
    a_start: chrono::DateTime<chrono::Local>,
    a_end: chrono::DateTime<chrono::Local>,
    b_start: chrono::DateTime<chrono::Local>,
    b_end: chrono::DateTime<chrono::Local>,
) -> u64 {
    let start = a_start.max(b_start);
    let end = a_end.min(b_end);
    if end <= start {
        0
    } else {
        (end - start).num_seconds().max(0) as u64
    }
}

fn add_to_daily(
    store: &mut TimeStatsStore,
    project_id: &str,
    start: chrono::DateTime<chrono::Local>,
    seconds: u64,
) {
    let mut cursor = start;
    let mut remaining = seconds as i64;
    let mut guard = 0;
    while remaining > 0 && guard < 400 {
        guard += 1;
        let date = cursor.date_naive();
        let Some(next) = date.succ_opt().and_then(local_day_start) else {
            break;
        };
        let available = (next - cursor).num_seconds().max(1);
        let slice = remaining.min(available);
        *store
            .daily
            .entry(project_id.to_string())
            .or_default()
            .entry(date.format("%Y-%m-%d").to_string())
            .or_insert(0) += slice as u64;
        remaining -= slice;
        cursor = next;
    }
    if remaining > 0 {
        let date = cursor.date_naive().format("%Y-%m-%d").to_string();
        *store
            .daily
            .entry(project_id.to_string())
            .or_default()
            .entry(date)
            .or_insert(0) += remaining as u64;
    }
}

const ACTIVITY_WRITE_INTERVAL_MS: u64 = 20_000;
static LAST_ACTIVITY_WRITE: AtomicU64 = AtomicU64::new(0);

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct ActivityHeartbeat {
    #[serde(default)]
    last_active_ms: u64,
}

fn activity_file(dir: &std::path::Path) -> std::path::PathBuf {
    dir.join("time_activity.json")
}

pub fn touch_activity(app: &AppHandle) {
    let now = crate::projects::epoch_ms();
    let last = LAST_ACTIVITY_WRITE.load(Ordering::Relaxed);
    if now.saturating_sub(last) < ACTIVITY_WRITE_INTERVAL_MS {
        return;
    }
    LAST_ACTIVITY_WRITE.store(now, Ordering::Relaxed);
    let heartbeat = ActivityHeartbeat { last_active_ms: now };
    let _ = persist::write_json(
        &activity_file(&crate::workspace::active_workspace_dir(app)),
        &heartbeat,
    );
}

pub fn last_active_ms(app: &AppHandle) -> u64 {
    persist::read_json::<ActivityHeartbeat>(&activity_file(
        &crate::workspace::active_workspace_dir(app),
    ))
    .last_active_ms
}

pub fn record_session(app: &AppHandle, project_id: &str, start_ms: u64, seconds: u64) {
    if seconds == 0 {
        return;
    }
    let mut store = read_stats(app);
    let sessions = store.projects.entry(project_id.to_string()).or_default();
    sessions.push(SessionRecord { start_ms, seconds });
    let cutoff = crate::projects::epoch_ms().saturating_sub(30 * 24 * 60 * 60 * 1000);
    sessions.retain(|s| s.start_ms >= cutoff);
    if sessions.len() > 200 {
        sessions.drain(0..sessions.len() - 200);
    }
    if let Some(start) =
        chrono::DateTime::<chrono::Utc>::from_timestamp_millis(start_ms as i64)
            .map(|t| t.with_timezone(&chrono::Local))
    {
        add_to_daily(&mut store, project_id, start, seconds);
    }
    write_stats(app, &store);
}

fn days_in_month(year: i32, month: u32) -> u32 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => {
            if (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 {
                29
            } else {
                28
            }
        }
        _ => 0,
    }
}

#[tauri::command]
pub fn get_activity(app: AppHandle, range: String) -> Vec<(String, u64)> {
    let store = read_stats(&app);
    let now = chrono::Local::now();
    match range.as_str() {
        "daily" => {
            let today = now.date_naive();
            let mut buckets = [0u64; 24];

            let (Some(day_start), Some(day_end)) = (
                local_day_start(today),
                today.succ_opt().and_then(local_day_start),
            ) else {
                return (0..24)
                    .map(|h| (format!("{}:{:02}", today.format("%Y-%m-%d"), h), 0))
                    .collect();
            };

            for sessions in store.projects.values() {
                for s in sessions {
                    let Some(start) = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(
                        s.start_ms as i64,
                    )
                    .map(|t| t.with_timezone(&chrono::Local))
                    else {
                        continue;
                    };
                    let end = start + Duration::seconds(s.seconds as i64);
                    if end <= day_start || start >= day_end {
                        continue;
                    }
                    for h in 0..24i64 {
                        let h_start = day_start + Duration::hours(h);
                        let h_end = h_start + Duration::hours(1);
                        buckets[h as usize] += overlap_seconds(start, end, h_start, h_end);
                    }
                }
            }

            let mut out: Vec<(String, u64)> = Vec::with_capacity(24);
            for h in 0..24 {
                out.push((
                    format!("{}:{:02}", today.format("%Y-%m-%d"), h),
                    buckets[h],
                ));
            }
            out
        }
        "monthly" => {
            let mut out: Vec<(String, u64)> = Vec::new();
            let year = now.year();
            let month = now.month();
            let count = days_in_month(year, month);
            for day in 1..=count {
                let date = format!("{:04}-{:02}-{:02}", year, month, day);
                let mut total = 0u64;
                for by_project in store.daily.values() {
                    total += by_project.get(&date).copied().unwrap_or(0);
                }
                out.push((date, total));
            }
            out
        }
        "yearly" => {
            let mut out: Vec<(String, u64)> = Vec::new();
            let year = now.year();
            for month in 1..=12 {
                let key = format!("{:04}-{:02}", year, month);
                let mut total = 0u64;
                for by_project in store.daily.values() {
                    for (date, secs) in by_project {
                        if date.starts_with(&key) {
                            total += secs;
                        }
                    }
                }
                out.push((key, total));
            }
            out
        }
        _ => {
            let mut out: Vec<(String, u64)> = Vec::new();
            for offset in (0..7).rev() {
                let day = now - Duration::days(offset);
                let date = day.format("%Y-%m-%d").to_string();
                let mut total = 0u64;
                for by_project in store.daily.values() {
                    total += by_project.get(&date).copied().unwrap_or(0);
                }
                out.push((date, total));
            }
            out
        }
    }
}

#[tauri::command]
pub fn get_project_activity(app: AppHandle, project_id: String) -> Vec<(String, u64)> {
    let store = read_stats(&app);
    let now = chrono::Local::now();
    let mut out: Vec<(String, u64)> = Vec::new();
    for offset in (0..7).rev() {
        let day = now - Duration::days(offset);
        let date = day.format("%Y-%m-%d").to_string();
        let total = store
            .daily
            .get(&project_id)
            .and_then(|m| m.get(&date))
            .copied()
            .unwrap_or(0);
        out.push((date, total));
    }
    out
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct TimeInsights {
    pub total_seconds: u64,
    pub longest_streak_days: u32,
    pub current_streak_days: u32,
    pub most_productive_weekday: Option<u32>,
    pub this_month_seconds: u64,
    pub last_month_seconds: u64,
}

#[tauri::command]
pub fn get_time_insights(app: AppHandle) -> TimeInsights {
    let store = read_stats(&app);
    let now = chrono::Local::now();

    let mut by_date: std::collections::BTreeMap<chrono::NaiveDate, u64> =
        std::collections::BTreeMap::new();
    for by_project in store.daily.values() {
        for (date, secs) in by_project {
            if let Ok(d) = chrono::NaiveDate::parse_from_str(date, "%Y-%m-%d") {
                *by_date.entry(d).or_insert(0) += secs;
            }
        }
    }

    let mut total_seconds = 0u64;
    let mut weekday_totals = [0u64; 7];
    let mut this_month_seconds = 0u64;
    let mut last_month_seconds = 0u64;
    let (lm_year, lm_month) = if now.month() == 1 {
        (now.year() - 1, 12)
    } else {
        (now.year(), now.month() - 1)
    };
    for (d, secs) in &by_date {
        total_seconds += secs;
        weekday_totals[d.weekday().num_days_from_monday() as usize] += secs;
        if d.year() == now.year() && d.month() == now.month() {
            this_month_seconds += secs;
        }
        if d.year() == lm_year && d.month() == lm_month {
            last_month_seconds += secs;
        }
    }

    let mut most_productive_weekday = None;
    let mut best = 0u64;
    for (i, v) in weekday_totals.iter().enumerate() {
        if *v > best {
            best = *v;
            most_productive_weekday = Some(i as u32);
        }
    }

    let mut longest_streak_days = 0u32;
    let mut run = 0u32;
    let mut prev: Option<chrono::NaiveDate> = None;
    for (d, secs) in &by_date {
        if *secs == 0 {
            continue;
        }
        run = match prev {
            Some(p) if d.signed_duration_since(p).num_days() == 1 => run + 1,
            _ => 1,
        };
        prev = Some(*d);
        if run > longest_streak_days {
            longest_streak_days = run;
        }
    }

    let today = now.date_naive();
    let mut current_streak_days = 0u32;
    let mut cursor = if by_date.get(&today).copied().unwrap_or(0) > 0 {
        today
    } else {
        today - Duration::days(1)
    };
    while by_date.get(&cursor).copied().unwrap_or(0) > 0 {
        current_streak_days += 1;
        cursor = cursor - Duration::days(1);
    }

    TimeInsights {
        total_seconds,
        longest_streak_days,
        current_streak_days,
        most_productive_weekday,
        this_month_seconds,
        last_month_seconds,
    }
}

pub fn breakdown(
    store: &TimeStatsStore,
    project_id: &str,
    now: chrono::DateTime<chrono::Local>,
) -> (u64, u64) {
    let Some(sessions) = store.projects.get(project_id) else {
        return (0, 0);
    };
    let today = now.date_naive();
    let week_start_date =
        today - Duration::days(today.weekday().num_days_from_monday() as i64);

    let (Some(today_start), Some(day_end), Some(week_start)) = (
        local_day_start(today),
        today.succ_opt().and_then(local_day_start),
        local_day_start(week_start_date),
    ) else {
        return (0, 0);
    };

    let mut today_secs = 0u64;
    let mut week_secs = 0u64;
    for s in sessions {
        let Some(start) =
            chrono::DateTime::<chrono::Utc>::from_timestamp_millis(s.start_ms as i64)
                .map(|t| t.with_timezone(&chrono::Local))
        else {
            continue;
        };
        let end = start + Duration::seconds(s.seconds as i64);
        today_secs += overlap_seconds(start, end, today_start, day_end);
        week_secs += overlap_seconds(start, end, week_start, day_end);
    }
    (today_secs, week_secs)
}

#[tauri::command]
pub fn clear_time_stats(app: AppHandle) -> Result<(), String> {
    write_stats(&app, &TimeStatsStore::default());

    crate::projects::mutate_projects(&app, |projects| {
        let mut changed = false;
        for p in projects.iter_mut() {
            if p.total_time_seconds != 0 || p.time_today_seconds != 0 || p.time_week_seconds != 0 || p.session_started_at_ms.is_some() {
                p.total_time_seconds = 0;
                p.time_today_seconds = 0;
                p.time_week_seconds = 0;
                p.session_started_at_ms = None;
                changed = true;
            }
        }
        Ok(((), changed))
    })
}
