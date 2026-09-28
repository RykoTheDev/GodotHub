use std::collections::{HashMap, VecDeque};
use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager};

use crate::godot_versions::LaunchedEditor;

const MAX_LINES: usize = 5000;
const MAX_LINE_BYTES: usize = 16 * 1024;
const MAX_LOG_BYTES: u64 = 8 * 1024 * 1024;
const TAIL_POLL_MS: u64 = 150;
const RESTORE_BYTES: u64 = 1024 * 1024;
const DRAIN_POLLS: u32 = 3;

static SESSIONS: AtomicU64 = AtomicU64::new(1);

fn next_session() -> u64 {
    SESSIONS.fetch_add(1, Ordering::Relaxed)
}

const TRACK_GRACE: Duration = Duration::from_secs(10);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum ConsoleStream {
    Stdout,
    #[allow(dead_code)]
    Stderr,
}

#[derive(Debug, Clone, Serialize)]
pub struct ConsoleLine {
    pub seq: u64,
    pub stream: ConsoleStream,
    pub text: String,
}

#[derive(Debug, Default)]
pub struct ConsoleEntry {
    lines: VecDeque<ConsoleLine>,
    next_seq: u64,
    running: bool,
    exit_code: Option<i32>,
    restored: bool,
    session: u64,
}

impl ConsoleEntry {
    fn push(&mut self, stream: ConsoleStream, text: String) {
        let seq = self.next_seq;
        self.next_seq += 1;
        self.lines.push_back(ConsoleLine { seq, stream, text });
        while self.lines.len() > MAX_LINES {
            self.lines.pop_front();
        }
    }
}

#[derive(Default)]
pub struct ConsoleBuffers(pub Arc<Mutex<HashMap<String, ConsoleEntry>>>);

#[derive(Debug, Clone, Serialize)]
pub struct ConsoleSnapshot {
    pub id: String,
    pub lines: Vec<ConsoleLine>,
    pub next_seq: u64,
    pub running: bool,
    pub exit_code: Option<i32>,
    pub restored: bool,
}

impl ConsoleSnapshot {
    fn empty(id: String) -> Self {
        Self {
            id,
            lines: Vec::new(),
            next_seq: 0,
            running: false,
            exit_code: None,
            restored: false,
        }
    }
}


fn log_dir(app: &AppHandle) -> PathBuf {
    crate::workspace::active_workspace_dir(app).join("console")
}

fn safe_id(id: &str) -> String {
    id.chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '-' || c == '_' {
                c
            } else {
                '_'
            }
        })
        .collect()
}

fn log_path(app: &AppHandle, id: &str) -> PathBuf {
    log_dir(app).join(format!("{}.log", safe_id(id)))
}


pub fn has_console_log(app: &AppHandle, id: &str) -> bool {
    log_path(app, id).is_file()
}


fn open_append(path: &Path) -> Result<File, String> {
    OpenOptions::new()
        .append(true)
        .open(path)
        .map_err(|e| format!("Failed to open the console log: {e}"))
}

fn normalize_line(bytes: &[u8]) -> String {
    let raw = String::from_utf8_lossy(bytes)
        .trim_end_matches(['\n', '\r'])
        .to_string();
    let mut text = if raw.contains('\r') {
        raw.rsplit('\r')
            .find(|part| !part.is_empty())
            .unwrap_or("")
            .to_string()
    } else {
        raw
    };
    if text.len() > MAX_LINE_BYTES {
        let mut end = MAX_LINE_BYTES;
        while end > 0 && !text.is_char_boundary(end) {
            end -= 1;
        }
        text.truncate(end);
        text.push('…');
    }
    text
}

fn split_lines(bytes: &[u8], keep_fragment: bool) -> Vec<String> {
    let mut lines = Vec::new();
    let mut start = 0usize;
    for (index, byte) in bytes.iter().enumerate() {
        if *byte == b'\n' {
            lines.push(normalize_line(&bytes[start..=index]));
            start = index + 1;
        }
    }
    if keep_fragment && start < bytes.len() {
        lines.push(normalize_line(&bytes[start..]));
    }
    lines
}

fn read_log_tail(path: &Path) -> (Vec<String>, u64) {
    let Ok(mut file) = File::open(path) else {
        return (Vec::new(), 0);
    };
    let Ok(len) = file.metadata().map(|meta| meta.len()) else {
        return (Vec::new(), 0);
    };
    let start = len.saturating_sub(RESTORE_BYTES);
    if file.seek(SeekFrom::Start(start.saturating_sub(1))).is_err() {
        return (Vec::new(), len);
    }
    let mut bytes = Vec::new();
    if file.read_to_end(&mut bytes).is_err() {
        return (Vec::new(), len);
    }
    let mut lines = split_lines(&bytes, true);
    if start > 0 && !lines.is_empty() {
        lines.remove(0);
    }
    if lines.len() > MAX_LINES {
        lines.drain(..lines.len() - MAX_LINES);
    }
    (lines, len)
}

struct LogTail {
    path: PathBuf,
    file: Option<File>,
    offset: u64,
    pending: Vec<u8>,
}

impl LogTail {
    fn new(path: PathBuf, offset: u64) -> Self {
        Self {
            path,
            file: None,
            offset,
            pending: Vec::new(),
        }
    }

    fn read_new_lines(&mut self) -> Vec<String> {
        if self.file.is_none() {
            match OpenOptions::new().read(true).write(true).open(&self.path) {
                Ok(file) => self.file = Some(file),
                Err(_) => return Vec::new(),
            }
        }
        let Some(file) = self.file.as_mut() else {
            return Vec::new();
        };
        let Ok(len) = file.metadata().map(|meta| meta.len()) else {
            return Vec::new();
        };

        if len < self.offset {
            self.offset = 0;
            self.pending.clear();
        }

        if len > self.offset {
            if file.seek(SeekFrom::Start(self.offset)).is_ok() {
                let mut chunk = [0u8; 8192];
                while self.offset < len {
                    let want = ((len - self.offset) as usize).min(chunk.len());
                    match file.read(&mut chunk[..want]) {
                        Ok(0) => break,
                        Ok(read) => {
                            self.pending.extend_from_slice(&chunk[..read]);
                            self.offset += read as u64;
                        }
                        Err(_) => break,
                    }
                }
            }
        }

        let mut lines = Vec::new();
        if let Some(last_newline) = self.pending.iter().rposition(|byte| *byte == b'\n') {
            lines = split_lines(&self.pending[..=last_newline], false);
            self.pending.drain(..=last_newline);
        }
        if self.pending.len() > MAX_LINE_BYTES {
            lines.push(normalize_line(&self.pending));
            self.pending.clear();
        }

        if len > MAX_LOG_BYTES && file.set_len(0).is_ok() {
            self.offset = 0;
            self.pending.clear();
        }
        lines
    }
}

fn watch_log(
    app: AppHandle,
    store: Arc<Mutex<HashMap<String, ConsoleEntry>>>,
    id: String,
    pid: Option<u32>,
    session: u64,
    mut tail: LogTail,
) {
    std::thread::spawn(move || {
        let started = std::time::Instant::now();
        let mut quiet = 0u32;
        let mut saw_tracked = false;
        loop {
            let lines = tail.read_new_lines();
            if lines.is_empty() {
                quiet += 1;
            } else {
                quiet = 0;
                if let Ok(mut map) = store.lock() {
                    if let Some(entry) = map.get_mut(&id) {
                        if entry.session == session {
                            for text in lines {
                                entry.push(ConsoleStream::Stdout, text);
                            }
                        }
                    }
                }
            }

            if crate::projects::tracked_pid(&app, &id).is_some() {
                saw_tracked = true;
            } else if saw_tracked {
                if quiet >= DRAIN_POLLS {
                    break;
                }
            } else if started.elapsed() >= TRACK_GRACE {
                break;
            }
            std::thread::sleep(Duration::from_millis(TAIL_POLL_MS));
        }

        let code = pid.and_then(crate::process::exit_code);
        if let Ok(mut map) = store.lock() {
            if let Some(entry) = map.get_mut(&id) {
                if entry.session == session {
                    entry.running = false;
                    entry.exit_code = code;
                }
            }
        }
        let _ = app.emit(
            "project:console-exit",
            serde_json::json!({ "id": id, "code": code }),
        );
    });
}

fn restore_console(app: &AppHandle, id: &str) {
    let path = log_path(app, id);
    if !path.is_file() {
        return;
    }
    let pid = crate::projects::tracked_pid(app, id);
    let (lines, offset) = read_log_tail(&path);
    let session = next_session();

    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return;
    };
    let store = state.0.clone();
    {
        let mut map = store.lock().unwrap();
        if map.contains_key(id) {
            return;
        }
        let mut entry = ConsoleEntry {
            running: pid.is_some(),
            restored: true,
            session,
            ..Default::default()
        };
        for text in lines {
            entry.push(ConsoleStream::Stdout, text);
        }
        map.insert(id.to_string(), entry);
    }

    if pid.is_some() {
        watch_log(
            app.clone(),
            store,
            id.to_string(),
            pid,
            session,
            LogTail::new(path, offset),
        );
    }
}

#[tauri::command]
pub fn get_project_console(app: AppHandle, id: String, since: Option<u64>) -> ConsoleSnapshot {
    let since = since.unwrap_or(0);
    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return ConsoleSnapshot::empty(id);
    };
    if !state.0.lock().unwrap().contains_key(&id) {
        restore_console(&app, &id);
    }
    let map = state.0.lock().unwrap();
    let Some(entry) = map.get(&id) else {
        return ConsoleSnapshot::empty(id);
    };
    ConsoleSnapshot {
        id,
        lines: entry
            .lines
            .iter()
            .filter(|line| line.seq >= since)
            .cloned()
            .collect(),
        next_seq: entry.next_seq,
        running: entry.running,
        exit_code: entry.exit_code,
        restored: entry.restored,
    }
}

#[tauri::command]
pub fn clear_project_console(app: AppHandle, id: String) {
    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return;
    };
    {
        let mut map = state.0.lock().unwrap();
        if let Some(entry) = map.get_mut(&id) {
            entry.lines.clear();
        }
    }
    if let Ok(file) = OpenOptions::new().write(true).open(log_path(&app, &id)) {
        let _ = file.set_len(0);
    }
}

pub fn forget_console(app: &AppHandle, id: &str) {
    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return;
    };
    {
        let mut map = state.0.lock().unwrap();
        map.remove(id);
    }
    let _ = std::fs::remove_file(log_path(app, id));
}

#[cfg(target_os = "windows")]
fn console_target(exe: &Path) -> Result<PathBuf, String> {
    crate::godot_versions::console_executable_for(exe)
        .ok_or_else(|| "This Godot build has no console executable".to_string())
}

#[cfg(not(target_os = "windows"))]
fn console_target(exe: &Path) -> Result<PathBuf, String> {
    if exe.exists() {
        Ok(exe.to_path_buf())
    } else {
        Err("Executable no longer exists at that path".to_string())
    }
}

pub fn spawn_in_app_console(
    app: &AppHandle,
    exe: &Path,
    args: &[String],
    id: &str,
) -> Result<LaunchedEditor, String> {
    let target = console_target(exe)?;
    let path = log_path(app, id);
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create the console log folder: {e}"))?;
    }
    File::create(&path).map_err(|e| format!("Failed to start the console log: {e}"))?;
    let log = open_append(&path)?;
    let errors = log
        .try_clone()
        .map_err(|e| format!("Failed to redirect console output: {e}"))?;

    let mut command = Command::new(&target);
    command
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::from(log))
        .stderr(Stdio::from(errors));

    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(crate::terminal::CREATE_NO_WINDOW);
    }

    crate::terminal::sanitize_child_env(&mut command);

    let child = command
        .spawn()
        .map_err(|e| format!("Failed to launch editor: {e}"))?;

    let pid = child.id();
    let session = next_session();

    if let Some(state) = app.try_state::<ConsoleBuffers>() {
        let store = state.0.clone();
        if let Ok(mut map) = store.lock() {
            map.insert(
                id.to_string(),
                ConsoleEntry {
                    running: true,
                    session,
                    ..Default::default()
                },
            );
        }
        watch_log(
            app.clone(),
            store,
            id.to_string(),
            Some(pid),
            session,
            LogTail::new(path, 0),
        );
    }

    Ok(LaunchedEditor {
        child,
        kill_tree: false,
        #[cfg(unix)]
        pid_file: None,
    })
}

#[cfg(test)]
#[path = "../tests/common/console.rs"]
mod console_common_tests;
