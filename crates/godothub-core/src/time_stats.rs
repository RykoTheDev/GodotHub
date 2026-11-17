//! Time tracking.
//!
//! Each project's history lives in its own folder, in
//! `<project>/.godothub/time_tracking.json`, stamped with the project id so a
//! copied folder (duplicate, template, vault) never inherits another
//! project's time. Every change is first queued in the workspace's
//! `time_tracking_pending.json` and then delivered to the project folder, so a
//! session that ends while the folder is unreachable (an unplugged drive) waits
//! there until the folder is back. Each change has an id the project file
//! remembers, which makes delivering twice harmless.
//!
//! The workspace's old `time_tracking.json` is read once into the queue and
//! never written again, so an older GodotHub still finds its data.
//!
//! `TimeStatsStore` remains the combined view used by the charts, backups and
//! settings export.

use crate::models::Project;
use crate::persist;
use crate::AppHandle;
use chrono::{Datelike, Duration};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SessionRecord {
    pub start_ms: u64,
    pub seconds: u64,
}

/// The combined history of a workspace, keyed by project id.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TimeStatsStore {
    #[serde(default)]
    pub schema_version: u32,
    #[serde(default)]
    pub projects: HashMap<String, Vec<SessionRecord>>,
    #[serde(default)]
    pub daily: HashMap<String, BTreeMap<String, u64>>,
}

impl persist::Versioned for TimeStatsStore {
    const VERSION: u32 = 1;
    fn migrate(mut value: serde_json::Value, _from: u32) -> serde_json::Value {
        // Older files stored the schema number under "version".
        if let serde_json::Value::Object(ref mut map) = value {
            if !map.contains_key("schema_version") {
                if let Some(old) = map.remove("version") {
                    map.insert("schema_version".into(), old);
                }
            }
        }
        value
    }
}

/// The workspace file older versions kept every project's history in.
const LEGACY_FILE: &str = "time_tracking.json";
/// Changes waiting for their project folder, per workspace.
const PENDING_FILE: &str = "time_tracking_pending.json";
/// The history file inside a project's `.godothub` folder.
const PROJECT_FILE: &str = "time_tracking.json";
const SESSION_RETENTION_MS: u64 = 30 * 24 * 60 * 60 * 1000;
const SESSION_LIMIT: usize = 200;
const APPLIED_LIMIT: usize = 256;

/// One project's history, stored in its folder.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ProjectTimeFile {
    #[serde(default)]
    pub schema_version: u32,
    #[serde(default)]
    pub project_id: String,
    #[serde(default)]
    pub sessions: Vec<SessionRecord>,
    #[serde(default)]
    pub daily: BTreeMap<String, u64>,
    /// Ids of the changes already applied, newest last.
    #[serde(default)]
    applied: Vec<String>,
}

impl persist::Versioned for ProjectTimeFile {
    const VERSION: u32 = 1;
}

impl ProjectTimeFile {
    fn empty(project_id: &str) -> Self {
        Self {
            schema_version: <Self as persist::Versioned>::VERSION,
            project_id: project_id.to_string(),
            ..Default::default()
        }
    }

    fn total_seconds(&self) -> u64 {
        let from_daily: u64 = self.daily.values().sum();
        let from_sessions: u64 = self.sessions.iter().map(|s| s.seconds).sum();
        from_daily.max(from_sessions)
    }

    fn is_empty(&self) -> bool {
        self.sessions.is_empty() && self.daily.is_empty()
    }

    /// Applies a change once; a change seen before is ignored.
    fn apply(&mut self, change: &Change) {
        if self.applied.iter().any(|id| id == &change.id) {
            return;
        }
        if change.replace {
            self.sessions.clear();
            self.daily.clear();
        }
        self.sessions.extend(change.sessions.iter().cloned());
        self.sessions.sort_by_key(|s| s.start_ms);
        let cutoff = crate::projects::epoch_ms().saturating_sub(SESSION_RETENTION_MS);
        self.sessions.retain(|s| s.start_ms >= cutoff);
        if self.sessions.len() > SESSION_LIMIT {
            let excess = self.sessions.len() - SESSION_LIMIT;
            self.sessions.drain(0..excess);
        }
        for (day, seconds) in &change.daily {
            *self.daily.entry(day.clone()).or_insert(0) += seconds;
        }
        self.applied.push(change.id.clone());
        if self.applied.len() > APPLIED_LIMIT {
            let excess = self.applied.len() - APPLIED_LIMIT;
            self.applied.drain(0..excess);
        }
    }
}

/// A change to one project's history: added time, or a replacement when
/// `replace` is set (clear, restore, import).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct Change {
    id: String,
    project_id: String,
    #[serde(default)]
    replace: bool,
    #[serde(default)]
    sessions: Vec<SessionRecord>,
    #[serde(default)]
    daily: BTreeMap<String, u64>,
}

impl Change {
    fn new(project_id: &str) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            project_id: project_id.to_string(),
            ..Default::default()
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct PendingStore {
    #[serde(default)]
    schema_version: u32,
    /// Set once the legacy workspace file has been copied into `changes`.
    #[serde(default)]
    legacy_imported: bool,
    #[serde(default)]
    changes: Vec<Change>,
    /// History of projects removed from the library, so the charts keep
    /// counting their time. Ignored while the id is registered again.
    #[serde(default)]
    retired: BTreeMap<String, RetiredHistory>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct RetiredHistory {
    #[serde(default)]
    sessions: Vec<SessionRecord>,
    #[serde(default)]
    daily: BTreeMap<String, u64>,
}

impl persist::Versioned for PendingStore {
    const VERSION: u32 = 1;
}

static FLUSH_LOCK: Mutex<()> = Mutex::new(());

fn pending_path(dir: &Path) -> PathBuf {
    dir.join(PENDING_FILE)
}

fn project_file_path(root: &Path) -> PathBuf {
    crate::project_metadata::directory(root).join(PROJECT_FILE)
}

/// Adds the legacy workspace history to the queue the first time it is seen.
/// The legacy file itself is left as it is. The change ids are fixed per
/// workspace and project, so reading this again never counts the history
/// twice, while the same folder listed in two workspaces gets both.
fn with_legacy(dir: &Path, mut pending: PendingStore) -> PendingStore {
    if pending.legacy_imported {
        return pending;
    }
    pending.legacy_imported = true;
    let legacy: TimeStatsStore = persist::load_json(&dir.join(LEGACY_FILE)).value;
    let workspace = dir.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
    let ids: BTreeSet<&String> = legacy.projects.keys().chain(legacy.daily.keys()).collect();
    let imported = ids.into_iter().map(|id| Change {
        id: format!("legacy-{workspace}-{id}"),
        project_id: id.clone(),
        replace: false,
        sessions: legacy.projects.get(id).cloned().unwrap_or_default(),
        daily: legacy.daily.get(id).cloned().unwrap_or_default(),
    });
    pending.changes.splice(0..0, imported);
    pending
}

fn read_pending(dir: &Path) -> PendingStore {
    with_legacy(dir, persist::load_json(&pending_path(dir)).value)
}

fn update_pending(dir: &Path, mutate: impl FnOnce(&mut PendingStore)) -> bool {
    persist::update_json::<PendingStore, _>(&pending_path(dir), |stored| {
        *stored = with_legacy(dir, std::mem::take(stored));
        mutate(stored);
    })
    .is_ok()
}

/// The history stored in a project folder, or an empty one when the file is
/// missing or belongs to another project (a copied folder).
fn read_project_file(root: &Path, project_id: &str) -> ProjectTimeFile {
    let file: ProjectTimeFile = persist::load_json(&project_file_path(root)).value;
    if file.project_id == project_id {
        file
    } else {
        ProjectTimeFile::empty(project_id)
    }
}

/// Writes a change into the project folder. Never creates a folder that is
/// gone; the change then stays queued.
fn deliver(root: &Path, change: &Change) -> bool {
    let Ok(metadata) = crate::project_metadata::prepare(root) else {
        return false;
    };
    ignore_in_git(&metadata);
    persist::update_json::<ProjectTimeFile, _>(&project_file_path(root), |file| {
        if file.project_id != change.project_id {
            *file = ProjectTimeFile::empty(&change.project_id);
        }
        file.apply(change);
    })
    .is_ok()
}

/// Keeps the time files out of Git in repositories that don't ignore
/// `.godothub/` already: they change after every session, and a clone would
/// otherwise carry one person's hours to everyone.
fn ignore_in_git(metadata: &Path) {
    let path = metadata.join(".gitignore");
    if path.exists() {
        return;
    }
    let _ = std::fs::write(
        &path,
        format!("# GodotHub time tracking is personal.\n{PROJECT_FILE}\n{PROJECT_FILE}.bak\n.{PROJECT_FILE}.tmp\n"),
    );
}

fn reachable_root<'a>(projects: &'a [Project], project_id: &str) -> Option<&'a Path> {
    projects
        .iter()
        .find(|p| p.id == project_id && !p.missing)
        .map(|p| Path::new(p.path.as_str()))
        .filter(|root| root.is_dir())
}

/// Delivers queued changes to the project folders that can be reached and
/// drops them from the queue. Changes for a folder that can't be reached stay,
/// in order, until a later call.
pub(crate) fn flush_pending_in(dir: &Path, projects: &[Project]) {
    let _guard = FLUSH_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let on_disk: PendingStore = persist::load_json(&pending_path(dir)).value;
    let newly_imported = !on_disk.legacy_imported;
    let pending = with_legacy(dir, on_disk);
    if pending.changes.is_empty() {
        if newly_imported && dir.join(LEGACY_FILE).is_file() {
            update_pending(dir, |_| {});
        }
        return;
    }
    let mut delivered: HashSet<String> = HashSet::new();
    let mut blocked: HashSet<String> = HashSet::new();
    for change in &pending.changes {
        if blocked.contains(&change.project_id) {
            continue;
        }
        match reachable_root(projects, &change.project_id) {
            Some(root) if deliver(root, change) => {
                delivered.insert(change.id.clone());
            }
            _ => {
                blocked.insert(change.project_id.clone());
            }
        }
    }
    if delivered.is_empty() && !newly_imported {
        return;
    }
    update_pending(dir, |stored| stored.changes.retain(|c| !delivered.contains(&c.id)));
}

fn submit_in(dir: &Path, projects: &[Project], changes: Vec<Change>) {
    if changes.is_empty() {
        return;
    }
    update_pending(dir, |stored| stored.changes.extend(changes));
    flush_pending_in(dir, projects);
}

fn submit(app: &AppHandle, changes: Vec<Change>) {
    let dir = crate::workspace::active_workspace_dir(app);
    submit_in(&dir, &crate::projects::read_projects(app), changes);
}

/// One project's history: what its folder holds plus anything still queued.
fn project_history(dir: &Path, root: Option<&Path>, project_id: &str) -> ProjectTimeFile {
    let mut file = match root {
        Some(root) => read_project_file(root, project_id),
        None => ProjectTimeFile::empty(project_id),
    };
    for change in read_pending(dir).changes.iter().filter(|c| c.project_id == project_id) {
        file.apply(change);
    }
    file
}

/// The combined history of every project in `projects`, plus queued changes
/// (which also cover projects no longer in the list). Projects flagged
/// missing are skipped without touching their folder.
pub(crate) fn read_stats_for(dir: &Path, projects: &[Project]) -> TimeStatsStore {
    let pending = read_pending(dir);
    let mut files: HashMap<String, ProjectTimeFile> = HashMap::new();
    for p in projects.iter().filter(|p| !p.missing) {
        files.insert(p.id.clone(), read_project_file(Path::new(&p.path), &p.id));
    }
    for (id, history) in &pending.retired {
        if !projects.iter().any(|p| &p.id == id) {
            let mut file = ProjectTimeFile::empty(id);
            file.sessions = history.sessions.clone();
            file.daily = history.daily.clone();
            files.insert(id.clone(), file);
        }
    }
    for change in &pending.changes {
        files
            .entry(change.project_id.clone())
            .or_insert_with(|| ProjectTimeFile::empty(&change.project_id))
            .apply(change);
    }
    let mut store = TimeStatsStore {
        schema_version: <TimeStatsStore as persist::Versioned>::VERSION,
        ..Default::default()
    };
    for (id, file) in files {
        if !file.sessions.is_empty() {
            store.projects.insert(id.clone(), file.sessions);
        }
        if !file.daily.is_empty() {
            store.daily.insert(id, file.daily);
        }
    }
    store
}

pub fn read_stats_from(dir: &Path) -> TimeStatsStore {
    read_stats_for(dir, &crate::projects::read_projects_from(dir))
}

pub fn read_stats(app: &AppHandle) -> TimeStatsStore {
    read_stats_from(&crate::workspace::active_workspace_dir(app))
}

/// Replaces the history of every project in `store` (backup restore, settings
/// import). Projects the store doesn't mention keep their history, so a backup
/// taken while a drive was unplugged never wipes that drive's projects.
pub fn write_stats_to(dir: &Path, store: &TimeStatsStore) {
    let ids: BTreeSet<&String> = store.projects.keys().chain(store.daily.keys()).collect();
    let changes = ids
        .into_iter()
        .map(|id| Change {
            replace: true,
            sessions: store.projects.get(id).cloned().unwrap_or_default(),
            daily: store.daily.get(id).cloned().unwrap_or_default(),
            ..Change::new(id)
        })
        .collect();
    submit_in(dir, &crate::projects::read_projects_from(dir), changes);
}

pub fn write_stats(app: &AppHandle, store: &TimeStatsStore) {
    write_stats_to(&crate::workspace::active_workspace_dir(app), store);
}

/// Replaces the history of the given projects (project stats import).
pub(crate) fn replace_project_stats(
    app: &AppHandle,
    entries: Vec<(String, Vec<SessionRecord>, BTreeMap<String, u64>)>,
) {
    let changes = entries
        .into_iter()
        .filter(|(_, sessions, daily)| !sessions.is_empty() || !daily.is_empty())
        .map(|(id, sessions, daily)| Change {
            replace: true,
            sessions,
            daily,
            ..Change::new(&id)
        })
        .collect();
    submit(app, changes);
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

fn add_to_daily(daily: &mut BTreeMap<String, u64>, start: chrono::DateTime<chrono::Local>, seconds: u64) {
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
        *daily.entry(date.format("%Y-%m-%d").to_string()).or_insert(0) += slice as u64;
        remaining -= slice;
        cursor = next;
    }
    if remaining > 0 {
        let date = cursor.date_naive().format("%Y-%m-%d").to_string();
        *daily.entry(date).or_insert(0) += remaining as u64;
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
    let heartbeat = ActivityHeartbeat {
        last_active_ms: now,
    };
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

/// The recorded time of the project in `root` with id `project_id`, used when
/// a folder is added (again) to the library.
pub fn total_seconds_for(app: &AppHandle, project_id: &str, root: &Path) -> u64 {
    let dir = crate::workspace::active_workspace_dir(app);
    project_history(&dir, Some(root).filter(|r| r.is_dir()), project_id).total_seconds()
}

/// Moves the history of `from_id` (whose folder is `from_root`) to `into_id`,
/// for worktrees folded into the project they belong to. The folded folder's
/// file is removed so adding that folder again doesn't count the time twice.
pub fn merge_project_stats(app: &AppHandle, from_id: &str, from_root: &Path, into_id: &str) {
    if from_id == into_id {
        return;
    }
    let dir = crate::workspace::active_workspace_dir(app);
    let stored = if from_root.is_dir() {
        read_project_file(from_root, from_id)
    } else {
        ProjectTimeFile::empty(from_id)
    };
    let had_history = !stored.is_empty();
    let moved = Change {
        sessions: stored.sessions,
        daily: stored.daily,
        ..Change::new(into_id)
    };
    let queued = update_pending(&dir, |pending| {
        for change in pending.changes.iter_mut().filter(|c| c.project_id == from_id) {
            change.project_id = into_id.to_string();
        }
        if !moved.sessions.is_empty() || !moved.daily.is_empty() {
            pending.changes.push(moved);
        }
    });
    if queued && had_history {
        let file = project_file_path(from_root);
        let _ = std::fs::remove_file(persist::backup_path(&file));
        let _ = std::fs::remove_file(file);
    }
    flush_pending_in(&dir, &crate::projects::read_projects(app));
}

/// Keeps the history of a project that is leaving the library (removed, or
/// its folder deleted) for the charts. Call it before the folder is deleted.
pub fn retire_project(app: &AppHandle, project_id: &str, root: &Path) {
    let file = if root.is_dir() {
        read_project_file(root, project_id)
    } else {
        ProjectTimeFile::empty(project_id)
    };
    let dir = crate::workspace::active_workspace_dir(app);
    update_pending(&dir, |pending| {
        pending.retired.insert(
            project_id.to_string(),
            RetiredHistory {
                sessions: file.sessions,
                daily: file.daily,
            },
        );
    });
}

pub fn record_session(app: &AppHandle, project_id: &str, start_ms: u64, seconds: u64) {
    if seconds == 0 {
        return;
    }
    let mut change = Change::new(project_id);
    change.sessions.push(SessionRecord { start_ms, seconds });
    if let Some(start) = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(start_ms as i64)
        .map(|t| t.with_timezone(&chrono::Local))
    {
        add_to_daily(&mut change.daily, start, seconds);
    }
    submit(app, vec![change]);
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

pub async fn get_activity(app: AppHandle, range: String) -> Vec<(String, u64)> {
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
                    let Some(start) =
                        chrono::DateTime::<chrono::Utc>::from_timestamp_millis(s.start_ms as i64)
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
                out.push((format!("{}:{:02}", today.format("%Y-%m-%d"), h), buckets[h]));
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

pub fn get_project_activity(app: AppHandle, project_id: String) -> Vec<(String, u64)> {
    let projects = crate::projects::read_projects(&app);
    let history = project_history(
        &crate::workspace::active_workspace_dir(&app),
        reachable_root(&projects, &project_id),
        &project_id,
    );
    let now = chrono::Local::now();
    let mut out: Vec<(String, u64)> = Vec::new();
    for offset in (0..7).rev() {
        let day = now - Duration::days(offset);
        let date = day.format("%Y-%m-%d").to_string();
        let total = history.daily.get(&date).copied().unwrap_or(0);
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

pub async fn get_time_insights(app: AppHandle) -> TimeInsights {
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
    let week_start_date = today - Duration::days(today.weekday().num_days_from_monday() as i64);

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
        let Some(start) = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(s.start_ms as i64)
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

/// Clears every project's history. Folders that can't be reached right now
/// are cleared when they come back.
pub fn clear_time_stats(app: AppHandle) -> Result<(), String> {
    let dir = crate::workspace::active_workspace_dir(&app);
    let projects = crate::projects::read_projects(&app);
    let cleared = update_pending(&dir, |pending| {
        pending.retired.clear();
        pending.changes = projects
            .iter()
            .map(|p| Change {
                replace: true,
                ..Change::new(&p.id)
            })
            .collect();
    });
    if !cleared {
        return Err("Couldn't clear the time tracking data".into());
    }
    flush_pending_in(&dir, &projects);

    crate::projects::update_projects(&app, |projects| {
        for p in projects.iter_mut() {
            p.total_time_seconds = 0;
            p.time_today_seconds = 0;
            p.time_week_seconds = 0;
            p.session_started_at_ms = None;
        }
    })
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(test)]
mod storage_tests {
    use super::*;
    use crate::Paths;
    use std::fs;
    use std::sync::Arc;

    struct NoEvents;
    impl crate::EventSink for NoEvents {
        fn emit(&self, _event: &str, _payload: &serde_json::value::RawValue) {}
    }
    struct NoHost;
    impl crate::Host for NoHost {
        fn show_main_window(&self) {}
        fn hide_main_window(&self) {}
        fn exit(&self, _code: i32) {}
        fn refresh_menus(&self) {}
    }

    struct Sandbox {
        root: PathBuf,
        app: AppHandle,
    }
    impl Drop for Sandbox {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }
    impl Sandbox {
        fn dir(&self) -> PathBuf {
            crate::workspace::active_workspace_dir(&self.app)
        }
        fn folder(&self, name: &str) -> PathBuf {
            let dir = self.root.join(name);
            fs::create_dir_all(&dir).unwrap();
            fs::write(dir.join("project.godot"), "[application]\n").unwrap();
            dir
        }
        fn register(&self, projects: &[(&str, &Path)]) -> Vec<Project> {
            let list: Vec<Project> = projects.iter().map(|(id, path)| project(id, path)).collect();
            crate::projects::write_projects(&self.app, &list).unwrap();
            list
        }
        fn pending(&self) -> PendingStore {
            persist::load_json(&pending_path(&self.dir())).value
        }
    }

    fn sandbox(name: &str) -> Sandbox {
        let root = std::env::temp_dir().join(format!("godothub-time-{name}-{}", uuid::Uuid::new_v4()));
        let data = root.join("data");
        fs::create_dir_all(&data).unwrap();
        let app = AppHandle::new(
            Paths::at(data.clone(), data, root.join("cache")),
            Arc::new(NoEvents),
            Arc::new(NoHost),
        );
        fs::create_dir_all(crate::workspace::active_workspace_dir(&app)).unwrap();
        Sandbox { root, app }
    }

    fn project(id: &str, path: &Path) -> Project {
        Project {
            id: id.into(),
            name: id.into(),
            path: crate::projects::native_path(&path.to_string_lossy()),
            godot_version: String::new(),
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
            missing: false,
        }
    }

    fn hour_ago() -> u64 {
        crate::projects::epoch_ms() - 60 * 60 * 1000
    }

    fn stored(root: &Path) -> Option<ProjectTimeFile> {
        persist::read_json_opt(&project_file_path(root))
    }

    fn total(store: &TimeStatsStore, id: &str) -> u64 {
        store.daily.get(id).map(|d| d.values().sum()).unwrap_or(0)
    }

    #[test]
    fn a_session_is_stored_in_the_project_folder() {
        let sb = sandbox("record");
        let game = sb.folder("game");
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 600);

        let file = stored(&game).expect("file in .godothub");
        assert_eq!(file.project_id, "game");
        assert_eq!(file.sessions.len(), 1);
        assert_eq!(file.total_seconds(), 600);
        assert!(sb.pending().changes.is_empty());
        assert!(!sb.dir().join(LEGACY_FILE).exists(), "no workspace history file is written");
        assert_eq!(total(&read_stats(&sb.app), "game"), 600);
    }

    #[test]
    fn legacy_history_moves_once_and_the_legacy_file_is_left_alone() {
        let sb = sandbox("legacy");
        let here = sb.folder("here");
        let gone = sb.root.join("unplugged");
        let projects = sb.register(&[("here", &here), ("gone", &gone)]);
        let mut legacy = TimeStatsStore::default();
        legacy.projects.insert("here".into(), vec![SessionRecord { start_ms: hour_ago(), seconds: 300 }]);
        legacy.daily.insert("here".into(), BTreeMap::from([("2026-01-02".to_string(), 300)]));
        legacy.daily.insert("gone".into(), BTreeMap::from([("2026-01-03".to_string(), 90)]));
        persist::write_json(&sb.dir().join(LEGACY_FILE), &legacy).unwrap();
        let before = fs::read(sb.dir().join(LEGACY_FILE)).unwrap();

        // Before any write, the combined view already includes the legacy data.
        assert_eq!(total(&read_stats(&sb.app), "here"), 300);

        flush_pending_in(&sb.dir(), &projects);
        flush_pending_in(&sb.dir(), &projects);

        let file = stored(&here).unwrap();
        assert_eq!(file.total_seconds(), 300, "delivered exactly once");
        assert_eq!(file.sessions.len(), 1);
        assert!(!gone.exists(), "an unreachable folder is never created");
        let pending = sb.pending();
        assert!(pending.legacy_imported);
        assert_eq!(pending.changes.len(), 1);
        assert_eq!(pending.changes[0].project_id, "gone");
        assert_eq!(fs::read(sb.dir().join(LEGACY_FILE)).unwrap(), before, "older versions still find their data");

        let combined = read_stats(&sb.app);
        assert_eq!(total(&combined, "here"), 300);
        assert_eq!(total(&combined, "gone"), 90);
    }

    #[test]
    fn a_delivery_interrupted_before_the_queue_is_trimmed_does_not_count_twice() {
        let sb = sandbox("interrupted");
        let game = sb.folder("game");
        let projects = sb.register(&[("game", &game)]);
        let mut change = Change::new("game");
        change.daily.insert("2026-01-02".into(), 120);
        update_pending(&sb.dir(), |p| p.changes.push(change.clone()));
        // The folder got the change, then the app stopped before trimming.
        assert!(deliver(&game, &change));

        assert_eq!(total(&read_stats(&sb.app), "game"), 120);
        flush_pending_in(&sb.dir(), &projects);
        assert_eq!(stored(&game).unwrap().total_seconds(), 120);
        assert!(sb.pending().changes.is_empty());
    }

    #[test]
    fn a_session_on_an_unplugged_drive_waits_and_lands_on_reconnect() {
        let sb = sandbox("unplug");
        let drive = sb.root.join("drive");
        let game = drive.join("game");
        fs::create_dir_all(&game).unwrap();
        fs::write(game.join("project.godot"), "[application]\n").unwrap();
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 60);

        let unplugged = sb.root.join("drive-away");
        fs::rename(&drive, &unplugged).unwrap();
        record_session(&sb.app, "game", hour_ago(), 30);
        assert!(!drive.exists(), "the folder is not recreated");
        assert_eq!(sb.pending().changes.len(), 1, "the session is kept");
        // A refresh while unplugged skips the folder and keeps the queue.
        crate::projects::list_projects_blocking(&sb.app);
        assert_eq!(sb.pending().changes.len(), 1);
        assert!(!drive.exists());

        fs::rename(&unplugged, &drive).unwrap();
        let listed = crate::projects::list_projects_blocking(&sb.app);
        assert!(listed.iter().all(|p| !p.missing));
        assert!(sb.pending().changes.is_empty());
        assert_eq!(stored(&game).unwrap().total_seconds(), 90);
    }

    #[test]
    fn a_copied_folder_does_not_inherit_time() {
        let sb = sandbox("copy");
        let original = sb.folder("original");
        sb.register(&[("original", &original)]);
        record_session(&sb.app, "original", hour_ago(), 500);

        let copy = sb.folder("copy");
        fs::create_dir_all(crate::project_metadata::directory(&copy)).unwrap();
        fs::copy(project_file_path(&original), project_file_path(&copy)).unwrap();
        sb.register(&[("original", &original), ("copy", &copy)]);

        assert_eq!(total_seconds_for(&sb.app, "copy", &copy), 0);
        assert_eq!(total_seconds_for(&sb.app, "original", &original), 500);
        assert_eq!(total(&read_stats(&sb.app), "copy"), 0);

        record_session(&sb.app, "copy", hour_ago(), 20);
        let file = stored(&copy).unwrap();
        assert_eq!(file.project_id, "copy");
        assert_eq!(file.total_seconds(), 20, "the copied history was replaced, not added to");
        assert_eq!(stored(&original).unwrap().total_seconds(), 500);
    }

    #[test]
    fn a_folder_added_again_keeps_its_time() {
        let sb = sandbox("readd");
        let game = sb.folder("game");
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 240);
        sb.register(&[]);
        assert_eq!(total_seconds_for(&sb.app, "game", &game), 240);
    }

    #[test]
    fn a_folded_worktree_moves_its_time_to_the_kept_project() {
        let sb = sandbox("merge");
        let main = sb.folder("main");
        let tree = sb.folder("tree");
        sb.register(&[("main", &main), ("tree", &tree)]);
        record_session(&sb.app, "main", hour_ago(), 100);
        record_session(&sb.app, "tree", hour_ago(), 30);
        record_session(&sb.app, "tree", hour_ago(), 20);
        sb.register(&[("main", &main)]);

        merge_project_stats(&sb.app, "tree", &tree, "main");
        assert_eq!(stored(&main).unwrap().total_seconds(), 150);
        assert!(stored(&tree).is_none(), "the folded folder no longer carries the time");
        assert_eq!(total_seconds_for(&sb.app, "tree", &tree), 0, "not even through the backup file");
        assert!(sb.pending().changes.is_empty());
    }

    #[test]
    fn clear_reaches_folders_that_come_back_later() {
        let sb = sandbox("clear");
        let here = sb.folder("here");
        let drive = sb.root.join("drive");
        let away = drive.join("away");
        fs::create_dir_all(&away).unwrap();
        fs::write(away.join("project.godot"), "[application]\n").unwrap();
        sb.register(&[("here", &here), ("away", &away)]);
        record_session(&sb.app, "here", hour_ago(), 10);
        record_session(&sb.app, "away", hour_ago(), 10);

        let unplugged = sb.root.join("drive-away");
        fs::rename(&drive, &unplugged).unwrap();
        clear_time_stats(sb.app.clone()).unwrap();
        assert!(stored(&here).unwrap().is_empty());
        assert!(read_stats(&sb.app).daily.is_empty());

        fs::rename(&unplugged, &drive).unwrap();
        crate::projects::list_projects_blocking(&sb.app);
        assert!(stored(&away).unwrap().is_empty());
        assert!(sb.pending().changes.is_empty());
    }

    #[test]
    fn restoring_a_backup_replaces_only_the_projects_it_contains() {
        let sb = sandbox("restore");
        let a = sb.folder("a");
        let b = sb.folder("b");
        sb.register(&[("a", &a), ("b", &b)]);
        record_session(&sb.app, "a", hour_ago(), 70);
        let backup = read_stats_from(&sb.dir());
        record_session(&sb.app, "a", hour_ago(), 5);
        record_session(&sb.app, "b", hour_ago(), 40);

        let mut only_a = backup.clone();
        only_a.daily.retain(|id, _| id == "a");
        only_a.projects.retain(|id, _| id == "a");
        write_stats_to(&sb.dir(), &only_a);

        assert_eq!(stored(&a).unwrap().total_seconds(), 70, "a is back to the backup");
        assert_eq!(stored(&b).unwrap().total_seconds(), 40, "b is not in the backup and keeps its time");
    }

    #[test]
    fn a_removed_project_still_counts_in_the_charts() {
        let sb = sandbox("remove");
        let game = sb.folder("game");
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 300);
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(crate::projects::remove_project(sb.app.clone(), "game".into(), false)).unwrap();
        assert_eq!(total(&read_stats(&sb.app), "game"), 300);
        assert_eq!(rt.block_on(get_time_insights(sb.app.clone())).total_seconds, 300);

        // Added again, the folder's own file is the history: counted once.
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 10);
        assert_eq!(total(&read_stats(&sb.app), "game"), 310);
    }

    #[test]
    fn the_time_files_stay_out_of_git() {
        let sb = sandbox("git");
        let game = sb.folder("game");
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 60);
        let ignore = fs::read_to_string(crate::project_metadata::directory(&game).join(".gitignore")).unwrap();
        assert!(ignore.lines().any(|l| l == "time_tracking.json"));
        assert!(ignore.lines().any(|l| l == "time_tracking.json.bak"));
    }

    #[test]
    fn the_same_folder_in_two_workspaces_gets_both_legacy_histories() {
        let sb = sandbox("two-workspaces");
        let game = sb.folder("game");
        let projects = vec![project("game", &game)];
        for (name, seconds) in [("one", 100u64), ("two", 40)] {
            let dir = sb.root.join("workspaces").join(name);
            fs::create_dir_all(&dir).unwrap();
            let mut legacy = TimeStatsStore::default();
            legacy.daily.insert("game".into(), BTreeMap::from([("2026-01-02".to_string(), seconds)]));
            persist::write_json(&dir.join(LEGACY_FILE), &legacy).unwrap();
            flush_pending_in(&dir, &projects);
        }
        assert_eq!(stored(&game).unwrap().total_seconds(), 140);
    }

    #[test]
    fn a_workspace_backup_round_trip_restores_the_project_files() {
        let sb = sandbox("backup");
        let game = sb.folder("game");
        sb.register(&[("game", &game)]);
        record_session(&sb.app, "game", hour_ago(), 80);
        let ws = crate::workspace::read_state(&sb.app).workspaces.into_iter().next().unwrap();
        let backup = crate::backup::build_workspace_backup_in(&sb.dir(), &ws);
        assert_eq!(serde_json::to_value(&backup).unwrap()["time_stats"]["daily"]["game"].as_object().map(|d| d.values().filter_map(|v| v.as_u64()).sum::<u64>()), Some(80));

        record_session(&sb.app, "game", hour_ago(), 15);
        crate::backup::apply_workspace_backup_in(&sb.dir(), backup).unwrap();
        assert_eq!(stored(&game).unwrap().total_seconds(), 80);
    }
}
