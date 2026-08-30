use crate::persist;
use chrono::{Datelike, Duration, Timelike};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};
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
        let date = start.format("%Y-%m-%d").to_string();
        *store
            .daily
            .entry(project_id.to_string())
            .or_default()
            .entry(date)
            .or_insert(0) += seconds;
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

            for sessions in store.projects.values() {
                for s in sessions {
                    let Some(start) = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(
                        s.start_ms as i64,
                    )
                    .map(|t| t.with_timezone(&chrono::Local))
                    else {
                        continue;
                    };
                    if start.date_naive() != today {
                        continue;
                    }
                    let start_secs =
                        start.hour() as u64 * 3600 + start.minute() as u64 * 60 + start.second() as u64;
                    let end_secs = start_secs + s.seconds;

                    for h in 0..24u64 {
                        let h_start = h * 3600;
                        let h_end = h_start + 3600;
                        let overlap_start = start_secs.max(h_start);
                        let overlap_end = end_secs.min(h_end);
                        if overlap_end > overlap_start {
                            buckets[h as usize] += overlap_end - overlap_start;
                        }
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
    let mut today = 0u64;
    let mut week = 0u64;
    for s in sessions {
        let Some(start) =
            chrono::DateTime::<chrono::Utc>::from_timestamp_millis(s.start_ms as i64)
                .map(|t| t.with_timezone(&chrono::Local))
        else {
            continue;
        };
        if start.date_naive() == now.date_naive() {
            today += s.seconds;
        }
        if start.iso_week() == now.iso_week() {
            week += s.seconds;
        }
    }
    (today, week)
}

#[tauri::command]
pub fn clear_time_stats(app: AppHandle) -> Result<(), String> {
    write_stats(&app, &TimeStatsStore::default());

    let mut projects = crate::projects::read_projects(&app);
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
    if changed {
        crate::projects::write_projects(&app, &projects).map_err(|e| e.to_string())?;
    }
    Ok(())
}
