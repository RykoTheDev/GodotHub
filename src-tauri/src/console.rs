use std::collections::{HashMap, VecDeque};
use std::io::{BufRead, BufReader, Read};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::mpsc::Sender;
use std::sync::{Arc, Mutex};

use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager};

use crate::godot_versions::LaunchedEditor;

const MAX_LINES: usize = 5000;

const MAX_LINE_BYTES: usize = 16 * 1024;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum ConsoleStream {
    Stdout,
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
}

impl ConsoleSnapshot {
    fn empty(id: String) -> Self {
        Self {
            id,
            lines: Vec::new(),
            next_seq: 0,
            running: false,
            exit_code: None,
        }
    }
}

#[tauri::command]
pub fn get_project_console(app: AppHandle, id: String, since: Option<u64>) -> ConsoleSnapshot {
    let since = since.unwrap_or(0);
    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return ConsoleSnapshot::empty(id);
    };
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
    }
}

#[tauri::command]
pub fn clear_project_console(app: AppHandle, id: String) {
    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return;
    };
    let mut map = state.0.lock().unwrap();
    if let Some(entry) = map.get_mut(&id) {
        entry.lines.clear();
    }
}

pub fn forget_console(app: &AppHandle, id: &str) {
    let Some(state) = app.try_state::<ConsoleBuffers>() else {
        return;
    };
    let mut map = state.0.lock().unwrap();
    map.remove(id);
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

    let mut command = Command::new(&target);
    command
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());

    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(crate::terminal::CREATE_NO_WINDOW);
    }

    crate::terminal::sanitize_child_env(&mut command);

    let mut child = command
        .spawn()
        .map_err(|e| format!("Failed to launch editor: {e}"))?;

    let pid = child.id();
    let stdout = child.stdout.take();
    let stderr = child.stderr.take();

    let store = app.try_state::<ConsoleBuffers>().map(|state| state.0.clone());

    if let Some(store) = store {
        if let Ok(mut map) = store.lock() {
            map.insert(
                id.to_string(),
                ConsoleEntry {
                    running: true,
                    ..Default::default()
                },
            );
        }

        let (tx, rx) = std::sync::mpsc::channel::<(ConsoleStream, String)>();
        if let Some(stream) = stdout {
            spawn_reader(stream, tx.clone(), ConsoleStream::Stdout);
        }
        if let Some(stream) = stderr {
            spawn_reader(stream, tx.clone(), ConsoleStream::Stderr);
        }
        drop(tx);

        spawn_collector(app.clone(), store, id.to_string(), pid, rx);
    }

    Ok(LaunchedEditor {
        child,
        kill_tree: false,
        #[cfg(unix)]
        pid_file: None,
    })
}

fn spawn_reader<R: Read + Send + 'static>(
    stream: R,
    tx: Sender<(ConsoleStream, String)>,
    kind: ConsoleStream,
) {
    std::thread::spawn(move || {
        let mut reader = BufReader::new(stream);
        let mut buffer = Vec::new();
        loop {
            buffer.clear();
            match reader.read_until(b'\n', &mut buffer) {
                Ok(0) => break,
                Ok(_) => {
                    let raw = String::from_utf8_lossy(&buffer)
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
                    if tx.send((kind, text)).is_err() {
                        break;
                    }
                }
                Err(_) => break,
            }
        }
    });
}

fn spawn_collector(
    app: AppHandle,
    store: Arc<Mutex<HashMap<String, ConsoleEntry>>>,
    id: String,
    pid: u32,
    rx: std::sync::mpsc::Receiver<(ConsoleStream, String)>,
) {
    std::thread::spawn(move || {
        for (stream, text) in rx {
            if let Ok(mut map) = store.lock() {
                if let Some(entry) = map.get_mut(&id) {
                    entry.push(stream, text);
                }
            }
        }

        let code = crate::process::exit_code(pid);
        if let Ok(mut map) = store.lock() {
            if let Some(entry) = map.get_mut(&id) {
                entry.running = false;
                entry.exit_code = code;
            }
        }

        let _ = app.emit(
            "project:console-exit",
            serde_json::json!({ "id": id, "code": code }),
        );
    });
}
