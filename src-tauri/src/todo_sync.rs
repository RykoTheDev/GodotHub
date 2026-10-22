use crate::models::{ProjectTodo, TodoArea, TodoClosure, TodoLink, TodoSource, TodoStatus};
use serde::Serialize;
use std::collections::HashMap;
use std::ffi::OsString;
use std::fs;
use std::path::{Component, Path, PathBuf};
use tauri::AppHandle;
use uuid::Uuid;

const COMMENT_EXTENSIONS: &[&str] = &["gd", "cs", "gdshader", "gdshaderinc"];
const RESOURCE_EXTENSIONS: &[&str] = &[
    "tscn", "scn", "tres", "res", "gd", "cs", "gdshader", "gdshaderinc",
];
const GODOT_OPENED_EXTENSIONS: &[&str] = &["tscn", "scn", "tres", "res"];
const SKIPPED_DIRS: &[&str] = &[
    ".godot", ".git", ".import", ".godothub", "addons", "bin", "obj", ".vs", ".vscode",
    ".idea", "node_modules",
];
const MAX_FILES: usize = 20_000;
const MAX_FILE_BYTES: u64 = 2_000_000;
const MAX_TITLE_CHARS: usize = 200;
const CLOSING_WORDS: &[&str] = &[
    "fix", "fixes", "fixed", "close", "closes", "closed", "resolve", "resolves", "resolved",
];

#[derive(Debug, Clone, PartialEq)]
pub(crate) struct FoundComment {
    pub tag: String,
    pub text: String,
    pub path: String,
    pub line: u32,
    pub key: String,
}

#[derive(Debug, Clone)]
pub(crate) struct CommitInfo {
    pub hash: String,
    pub time: i64,
    pub author: String,
    pub subject: String,
    pub body: String,
}

impl CommitInfo {
    fn message(&self) -> String {
        format!("{}\n{}", self.subject, self.body)
    }
}

#[derive(Debug, Default, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub(crate) struct CommentScanCounts {
    pub imported: usize,
    pub closed: usize,
    pub reopened: usize,
    pub updated: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TodoSyncResult {
    pub todos: Vec<ProjectTodo>,
    pub scanned: bool,
    pub imported: usize,
    pub closed: usize,
    pub reopened: usize,
    pub updated: usize,
    pub closed_by_commits: usize,
    pub git_available: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TodoCommit {
    pub hash: String,
    pub short_hash: String,
    pub subject: String,
    pub author: String,
    pub date: String,
    pub closes: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TodoGitActivity {
    pub is_repo: bool,
    pub current_branch: Option<String>,
    pub branches: Vec<String>,
    pub commits: Vec<TodoCommit>,
}

fn is_word_char(c: char) -> bool {
    c.is_alphanumeric() || c == '_'
}

fn has_comment_marker(before: &str) -> bool {
    let trimmed = before.trim_end();
    if trimmed.ends_with('#') || trimmed.ends_with("//") || trimmed.ends_with("/*") {
        return true;
    }
    let content = trimmed.trim_start();
    !content.is_empty() && content.chars().all(|c| c == '*')
}

pub(crate) fn parse_comment(line: &str) -> Option<(String, String)> {
    for tag in ["TODO", "FIXME"] {
        let mut search_from = 0;
        while let Some(offset) = line[search_from..].find(tag) {
            let start = search_from + offset;
            let end = start + tag.len();
            search_from = end;
            let before_ok = line[..start].chars().next_back().map_or(true, |c| !is_word_char(c));
            let after_ok = line[end..].chars().next().map_or(true, |c| !is_word_char(c));
            if !before_ok || !after_ok || !has_comment_marker(&line[..start]) {
                continue;
            }
            let mut rest = &line[end..];
            if rest.starts_with('(') {
                if let Some(close) = rest.find(')') {
                    rest = &rest[close + 1..];
                }
            }
            let text = rest
                .trim_start_matches(|c: char| c.is_whitespace() || c == ':' || c == '-')
                .trim_end()
                .trim_end_matches("*/")
                .trim_end()
                .to_string();
            return Some((tag.to_string(), text));
        }
    }
    None
}

fn normalized(text: &str) -> String {
    text.split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
        .to_lowercase()
}

pub(crate) fn comments_in_text(res_path: &str, contents: &str) -> Vec<FoundComment> {
    let mut seen: HashMap<String, usize> = HashMap::new();
    let mut found = Vec::new();
    for (index, line) in contents.lines().enumerate() {
        let Some((tag, text)) = parse_comment(line) else {
            continue;
        };
        let base = format!("{res_path}\u{1f}{tag}\u{1f}{}", normalized(&text));
        let occurrence = seen.entry(base.clone()).or_insert(0);
        *occurrence += 1;
        found.push(FoundComment {
            key: format!("{base}\u{1f}{occurrence}"),
            tag,
            text,
            path: res_path.to_string(),
            line: index as u32 + 1,
        });
    }
    found
}

fn should_skip_dir(path: &Path) -> bool {
    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().to_lowercase())
        .unwrap_or_default();
    SKIPPED_DIRS.contains(&name.as_str()) || path.join(".gdignore").exists()
}

fn has_extension(path: &Path, allowed: &[&str]) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|e| allowed.contains(&e.to_lowercase().as_str()))
        .unwrap_or(false)
}

fn res_path(root: &Path, file: &Path) -> Option<String> {
    let rel = file.strip_prefix(root).ok()?;
    let rel = rel.to_string_lossy().replace('\\', "/");
    Some(format!("res://{rel}"))
}

fn project_files(root: &Path, allowed: &[&str]) -> Vec<PathBuf> {
    let mut files = Vec::new();
    let mut stack = vec![root.to_path_buf()];
    while let Some(dir) = stack.pop() {
        let Ok(entries) = fs::read_dir(&dir) else {
            continue;
        };
        let mut entries: Vec<_> = entries.flatten().collect();
        entries.sort_by_key(|e| e.file_name());
        for entry in entries {
            let path = entry.path();
            let Ok(kind) = entry.file_type() else {
                continue;
            };
            if kind.is_symlink() {
                continue;
            }
            if kind.is_dir() {
                if !should_skip_dir(&path) {
                    stack.push(path);
                }
            } else if kind.is_file() && has_extension(&path, allowed) {
                files.push(path);
                if files.len() >= MAX_FILES {
                    return files;
                }
            }
        }
    }
    files.sort();
    files
}

pub(crate) fn scan_project_comments(root: &Path) -> Vec<FoundComment> {
    let mut found = Vec::new();
    for file in project_files(root, COMMENT_EXTENSIONS) {
        if fs::metadata(&file).map(|m| m.len() > MAX_FILE_BYTES).unwrap_or(true) {
            continue;
        }
        let Ok(bytes) = fs::read(&file) else {
            continue;
        };
        let Some(res) = res_path(root, &file) else {
            continue;
        };
        found.extend(comments_in_text(&res, &String::from_utf8_lossy(&bytes)));
    }
    found
}

fn comment_title(found: &FoundComment) -> String {
    if found.text.is_empty() {
        let file = found.path.rsplit('/').next().unwrap_or(&found.path);
        return format!("{} in {}:{}", found.tag, file, found.line);
    }
    let mut title: String = found.text.chars().take(MAX_TITLE_CHARS).collect();
    if found.text.chars().count() > MAX_TITLE_CHARS {
        title.push('…');
    }
    title
}

fn is_comment_todo(todo: &ProjectTodo) -> Option<&TodoSource> {
    todo.source.as_ref().filter(|s| s.kind == "comment")
}

fn closed_by_kind(todo: &ProjectTodo) -> Option<&str> {
    todo.closed_by.as_ref().map(|c| c.kind.as_str())
}

pub(crate) fn apply_comment_scan(
    todos: &mut Vec<ProjectTodo>,
    found: Vec<FoundComment>,
    now: &str,
) -> CommentScanCounts {
    let mut counts = CommentScanCounts::default();
    let mut remaining: Vec<Option<FoundComment>> = found.into_iter().map(Some).collect();
    let mut by_key: HashMap<String, usize> = HashMap::new();
    for (index, comment) in remaining.iter().enumerate() {
        if let Some(comment) = comment {
            by_key.entry(comment.key.clone()).or_insert(index);
        }
    }

    for todo in todos.iter_mut() {
        let Some(key) = is_comment_todo(todo).map(|s| s.key.clone()) else {
            continue;
        };
        match by_key.remove(&key).and_then(|i| remaining[i].take()) {
            Some(comment) => {
                let link = TodoLink {
                    path: comment.path.clone(),
                    line: Some(comment.line),
                };
                if todo.link.as_ref() != Some(&link) {
                    todo.link = Some(link);
                    counts.updated += 1;
                }
                if todo.status == TodoStatus::Done && closed_by_kind(todo) == Some("comment_removed") {
                    todo.status = TodoStatus::Todo;
                    todo.closed_by = None;
                    counts.reopened += 1;
                }
            }
            None => {
                if todo.status != TodoStatus::Done && closed_by_kind(todo) != Some("comment_removed") {
                    todo.status = TodoStatus::Done;
                    todo.closed_by = Some(TodoClosure {
                        kind: "comment_removed".into(),
                        commit: None,
                        subject: None,
                        at: now.to_string(),
                    });
                    counts.closed += 1;
                }
            }
        }
    }

    for comment in remaining.into_iter().flatten() {
        todos.push(ProjectTodo {
            id: Uuid::new_v4().to_string(),
            title: comment_title(&comment),
            status: TodoStatus::Todo,
            area: TodoArea::Programming,
            due_date: None,
            description: None,
            created_at: now.to_string(),
            number: None,
            link: Some(TodoLink {
                path: comment.path.clone(),
                line: Some(comment.line),
            }),
            source: Some(TodoSource {
                kind: "comment".into(),
                tag: comment.tag.clone(),
                key: comment.key.clone(),
            }),
            closed_by: None,
            priority: None,
            checklist: Vec::new(),
            completed_at: None,
        });
        counts.imported += 1;
    }
    counts
}

fn todo_refs(message: &str) -> Vec<(u32, bool)> {
    let lower = message.to_lowercase();
    let mut refs = Vec::new();
    let mut search_from = 0;
    while let Some(offset) = lower[search_from..].find("#todo-") {
        let start = search_from + offset;
        let digits_start = start + "#todo-".len();
        let digits: String = lower[digits_start..].chars().take_while(|c| c.is_ascii_digit()).collect();
        search_from = digits_start + digits.len();
        if digits.is_empty() {
            continue;
        }
        let Ok(number) = digits.parse::<u32>() else {
            continue;
        };
        let before = lower[..start].trim_end_matches(|c: char| c.is_whitespace() || c == ':');
        let word: String = before
            .chars()
            .rev()
            .take_while(|c| c.is_alphabetic())
            .collect::<Vec<_>>()
            .into_iter()
            .rev()
            .collect();
        refs.push((number, CLOSING_WORDS.contains(&word.as_str())));
    }
    refs
}

pub(crate) fn closing_refs(message: &str) -> Vec<u32> {
    todo_refs(message)
        .into_iter()
        .filter(|(_, closes)| *closes)
        .map(|(n, _)| n)
        .collect()
}

pub(crate) fn mentions(message: &str, number: u32) -> Option<bool> {
    let refs: Vec<bool> = todo_refs(message)
        .into_iter()
        .filter(|(n, _)| *n == number)
        .map(|(_, closes)| closes)
        .collect();
    if refs.is_empty() {
        None
    } else {
        Some(refs.contains(&true))
    }
}

fn timestamp(value: &str) -> Option<i64> {
    chrono::DateTime::parse_from_rfc3339(value)
        .ok()
        .map(|d| d.timestamp())
}

pub(crate) fn apply_git_closures(
    todos: &mut [ProjectTodo],
    commits: &[CommitInfo],
    now: &str,
) -> usize {
    let mut closed = 0;
    for commit in commits.iter().rev() {
        for number in closing_refs(&commit.message()) {
            let Some(todo) = todos.iter_mut().find(|t| t.number == Some(number)) else {
                continue;
            };
            if todo.status == TodoStatus::Done {
                continue;
            }
            if timestamp(&todo.created_at).is_some_and(|created| commit.time < created) {
                continue;
            }
            if let Some(previous) = todo.closed_by.as_ref().filter(|c| c.kind == "commit") {
                if previous.commit.as_deref() == Some(commit.hash.as_str()) {
                    continue;
                }
                if timestamp(&previous.at).is_some_and(|at| commit.time <= at) {
                    continue;
                }
            }
            todo.status = TodoStatus::Done;
            todo.closed_by = Some(TodoClosure {
                kind: "commit".into(),
                commit: Some(commit.hash.clone()),
                subject: Some(commit.subject.clone()),
                at: now.to_string(),
            });
            closed += 1;
        }
    }
    closed
}

pub(crate) fn parse_git_log(output: &str) -> Vec<CommitInfo> {
    output
        .split('\u{1e}')
        .filter_map(|record| {
            let record = record.trim_start_matches(['\n', '\r']);
            let mut fields = record.splitn(5, '\u{1f}');
            let hash = fields.next()?.trim().to_string();
            if hash.is_empty() {
                return None;
            }
            let time = fields.next()?.trim().parse().ok()?;
            let author = fields.next().unwrap_or("").to_string();
            let subject = fields.next().unwrap_or("").to_string();
            let body = fields.next().unwrap_or("").trim().to_string();
            Some(CommitInfo {
                hash,
                time,
                author,
                subject,
                body,
            })
        })
        .collect()
}

fn git_log(project_path: &str, all: bool, limit: u32) -> Option<Vec<CommitInfo>> {
    let limit = format!("-n{limit}");
    let mut args = vec!["log", limit.as_str(), "--format=%H%x1f%ct%x1f%an%x1f%s%x1f%b%x1e"];
    if all {
        args.push("--all");
    }
    crate::git_helpers::git_cmd(project_path, args)
        .ok()
        .map(|out| parse_git_log(&out))
}

fn project_path(app: &AppHandle, project_id: &str) -> Result<String, String> {
    crate::projects::read_projects(app)
        .into_iter()
        .find(|p| p.id == project_id)
        .map(|p| p.path)
        .ok_or_else(|| "Project not found".to_string())
}

#[tauri::command]
pub async fn sync_project_todos(
    app: AppHandle,
    project_id: String,
    scan_comments: bool,
) -> Result<TodoSyncResult, String> {
    tokio::task::spawn_blocking(move || {
        let path = project_path(&app, &project_id)?;
        let found = scan_comments.then(|| scan_project_comments(Path::new(&path)));
        let commits = git_log(&path, false, 500);
        let now = chrono::Utc::now().to_rfc3339();
        let dir = crate::project_todos::active_dir(&app);
        let (todos, (counts, closed_by_commits)) =
            crate::project_todos::edit_project_todos(&dir, &project_id, |todos, counter| {
                let counts = match found {
                    Some(found) => apply_comment_scan(todos, found, &now),
                    None => CommentScanCounts::default(),
                };
                crate::project_todos::ensure_numbers(todos, counter);
                let closed = commits
                    .as_ref()
                    .map(|c| apply_git_closures(todos, c, &now))
                    .unwrap_or(0);
                (counts, closed)
            })?;
        Ok(TodoSyncResult {
            todos,
            scanned: scan_comments,
            imported: counts.imported,
            closed: counts.closed,
            reopened: counts.reopened,
            updated: counts.updated,
            closed_by_commits,
            git_available: commits.is_some(),
        })
    })
    .await
    .map_err(|e| e.to_string())?
}

fn branch_mentions(name: &str, number: u32) -> bool {
    let lower = name.to_lowercase();
    let needle = format!("todo-{number}");
    let mut search_from = 0;
    while let Some(offset) = lower[search_from..].find(&needle) {
        let start = search_from + offset;
        let end = start + needle.len();
        search_from = end;
        let before_ok = lower[..start].chars().next_back().map_or(true, |c| !c.is_alphanumeric());
        let after_ok = lower[end..].chars().next().map_or(true, |c| !c.is_ascii_digit());
        if before_ok && after_ok {
            return true;
        }
    }
    false
}

#[tauri::command]
pub async fn todo_git_activity(
    app: AppHandle,
    project_id: String,
    number: u32,
) -> Result<TodoGitActivity, String> {
    tokio::task::spawn_blocking(move || {
        let path = project_path(&app, &project_id)?;
        let Some(commits) = git_log(&path, true, 2000) else {
            return Ok(TodoGitActivity {
                is_repo: false,
                current_branch: None,
                branches: Vec::new(),
                commits: Vec::new(),
            });
        };
        let current_branch = crate::git_helpers::git_cmd(&path, ["rev-parse", "--abbrev-ref", "HEAD"])
            .ok()
            .filter(|b| !b.is_empty() && b != "HEAD");
        let mut branches: Vec<String> =
            crate::git_helpers::git_cmd(&path, ["branch", "-a", "--format=%(refname:short)"])
                .map(|out| {
                    out.lines()
                        .map(str::trim)
                        .filter(|name| !name.is_empty() && branch_mentions(name, number))
                        .map(str::to_string)
                        .collect()
                })
                .unwrap_or_default();
        branches.dedup();
        let commits = commits
            .into_iter()
            .filter_map(|c| {
                let closes = mentions(&c.message(), number)?;
                let date = chrono::DateTime::from_timestamp(c.time, 0)
                    .map(|d| d.to_rfc3339())
                    .unwrap_or_default();
                Some(TodoCommit {
                    short_hash: c.hash.chars().take(7).collect(),
                    hash: c.hash,
                    subject: c.subject,
                    author: c.author,
                    date,
                    closes,
                })
            })
            .take(30)
            .collect();
        Ok(TodoGitActivity {
            is_repo: true,
            current_branch,
            branches,
            commits,
        })
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
pub async fn list_project_resources(app: AppHandle, project_id: String) -> Result<Vec<String>, String> {
    tokio::task::spawn_blocking(move || {
        let path = project_path(&app, &project_id)?;
        let root = Path::new(&path);
        Ok(project_files(root, RESOURCE_EXTENSIONS)
            .iter()
            .filter_map(|f| res_path(root, f))
            .take(5000)
            .collect())
    })
    .await
    .map_err(|e| e.to_string())?
}

pub(crate) fn resolve_res_path(root: &Path, res: &str) -> Result<PathBuf, String> {
    let rel = res
        .strip_prefix("res://")
        .ok_or_else(|| "Linked files must be res:// paths".to_string())?;
    let rel_path = Path::new(rel);
    if rel.is_empty()
        || rel_path
            .components()
            .any(|c| !matches!(c, Component::Normal(_)))
    {
        return Err("That path points outside the project".into());
    }
    Ok(root.join(rel_path))
}

fn editor_args(editor: &str, file: &Path, line: Option<u32>) -> Vec<OsString> {
    let name = Path::new(editor)
        .file_stem()
        .map(|s| s.to_string_lossy().to_lowercase())
        .unwrap_or_default();
    let file_arg = file.as_os_str().to_os_string();
    let Some(line) = line else {
        return vec![file_arg];
    };
    let at_line = OsString::from(format!("{}:{line}", file.display()));
    if ["code", "codium", "cursor", "windsurf"].iter().any(|n| name.contains(n)) {
        vec!["-g".into(), at_line]
    } else if name.contains("zed") || name.contains("subl") {
        vec![at_line]
    } else if ["rider", "idea", "webstorm", "clion", "fleet"].iter().any(|n| name.contains(n)) {
        vec!["--line".into(), line.to_string().into(), file_arg]
    } else {
        vec![file_arg]
    }
}

fn try_editor(editor: &str, file: &Path, line: Option<u32>) -> bool {
    let mut cmd = std::process::Command::new(editor);
    crate::terminal::sanitize_child_env(&mut cmd);
    cmd.args(editor_args(editor, file, line)).spawn().is_ok()
}

fn open_in_code_editor(app: &AppHandle, file: &Path, line: Option<u32>) -> Result<(), String> {
    let settings = crate::settings::read_settings(app);
    if let Some(editor) = settings.external_editor_path.as_deref().map(str::trim) {
        if !editor.is_empty() && try_editor(editor, file, line) {
            return Ok(());
        }
    }
    for editor in ["code", "rider", "idea", "code-insiders", "codium", "zed"] {
        if try_editor(editor, file, line) {
            return Ok(());
        }
    }
    #[cfg(target_os = "windows")]
    {
        let username = std::env::var("USERNAME").unwrap_or_default();
        let candidates = [
            format!("C:\\Users\\{username}\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe"),
            "C:\\Program Files\\Microsoft VS Code\\Code.exe".into(),
            "C:\\Program Files (x86)\\Microsoft VS Code\\Code.exe".into(),
        ];
        for candidate in candidates {
            if Path::new(&candidate).exists() && try_editor(&candidate, file, line) {
                return Ok(());
            }
        }
    }
    Err("No code editor found. Install VS Code, Rider or Zed, or set your editor in Settings.".into())
}

#[tauri::command]
pub fn open_todo_link(
    app: AppHandle,
    project_id: String,
    path: String,
    line: Option<u32>,
) -> Result<(), String> {
    let root = PathBuf::from(project_path(&app, &project_id)?);
    let file = resolve_res_path(&root, &path)?;
    if !file.exists() {
        return Err(format!("{path} no longer exists in this project"));
    }
    let godot_already_open = crate::projects::tracked_pid(&app, &project_id).is_some();
    let open_in_godot = |app: AppHandle| {
        if godot_already_open {
            return Err(format!(
                "Godot is already open for this project. Open {path} from Godot's FileSystem dock."
            ));
        }
        crate::projects::launch_project(app, project_id.clone(), true, None, Some(path.clone()))
    };
    if has_extension(&file, GODOT_OPENED_EXTENSIONS) {
        return open_in_godot(app);
    }
    match open_in_code_editor(&app, &file, line) {
        Ok(()) => Ok(()),
        Err(editor_error) => open_in_godot(app).map_err(|_| editor_error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::project_todos::tests::{temp_dir, todo};

    #[test]
    fn parses_todo_and_fixme_comments_in_every_language() {
        assert_eq!(parse_comment("    # TODO: add double jump"), Some(("TODO".into(), "add double jump".into())));
        assert_eq!(parse_comment("var x = 1 ## FIXME clamp this"), Some(("FIXME".into(), "clamp this".into())));
        assert_eq!(parse_comment("// TODO(ryko): wire up audio"), Some(("TODO".into(), "wire up audio".into())));
        assert_eq!(parse_comment("/* FIXME - leaks */"), Some(("FIXME".into(), "leaks".into())));
        assert_eq!(parse_comment("   * TODO handle null"), Some(("TODO".into(), "handle null".into())));
        assert_eq!(parse_comment("#TODO"), Some(("TODO".into(), String::new())));
        assert_eq!(parse_comment("var TODO_LIST = []"), None);
        assert_eq!(parse_comment("print(\"todo\") # nothing here"), None);
        assert_eq!(parse_comment("x = a * TODO"), None);
        assert_eq!(parse_comment("# TODOS are fine"), None);
    }

    #[test]
    fn repeated_identical_comments_get_distinct_keys() {
        let found = comments_in_text("res://a.gd", "# TODO: refactor\nfunc a():\n\tpass # TODO refactor\n");
        assert_eq!(found.len(), 2);
        assert_ne!(found[0].key, found[1].key);
        assert_eq!(found[1].line, 3);
    }

    #[test]
    fn scan_imports_updates_closes_and_reopens() {
        let now = "2026-10-22T10:00:00Z";
        let mut todos = vec![todo("manual", "Write design doc")];
        let first = comments_in_text("res://player.gd", "# TODO: add double jump\n# FIXME: clamp speed\n");
        let counts = apply_comment_scan(&mut todos, first, now);
        assert_eq!(counts.imported, 2);
        assert_eq!(todos.len(), 3);
        let jump = todos.iter().find(|t| t.title == "add double jump").unwrap();
        assert_eq!(jump.link.as_ref().unwrap().line, Some(1));
        assert_eq!(jump.source.as_ref().unwrap().tag, "TODO");

        let moved = comments_in_text("res://player.gd", "extends Node\n\n# TODO: add double jump\n");
        let counts = apply_comment_scan(&mut todos, moved, now);
        assert_eq!(counts, CommentScanCounts { imported: 0, closed: 1, reopened: 0, updated: 1 });
        let jump = todos.iter().find(|t| t.title == "add double jump").unwrap();
        assert_eq!(jump.link.as_ref().unwrap().line, Some(3));
        let clamp = todos.iter().find(|t| t.title == "clamp speed").unwrap();
        assert_eq!(clamp.status, TodoStatus::Done);
        assert_eq!(todos.iter().find(|t| t.id == "manual").unwrap().status, TodoStatus::Todo);

        let back = comments_in_text("res://player.gd", "# TODO: add double jump\n# FIXME: clamp speed\n");
        let counts = apply_comment_scan(&mut todos, back, now);
        assert_eq!(counts.reopened, 1);
        assert_eq!(todos.iter().find(|t| t.title == "clamp speed").unwrap().status, TodoStatus::Todo);
    }

    #[test]
    fn user_reopened_todo_is_not_closed_again_by_the_same_cause() {
        let now = "2026-10-22T10:00:00Z";
        let mut todos = Vec::new();
        apply_comment_scan(&mut todos, comments_in_text("res://a.gd", "# TODO: thing\n"), now);
        apply_comment_scan(&mut todos, Vec::new(), now);
        assert_eq!(todos[0].status, TodoStatus::Done);
        todos[0].status = TodoStatus::InProgress;
        let counts = apply_comment_scan(&mut todos, Vec::new(), now);
        assert_eq!(counts.closed, 0);
        assert_eq!(todos[0].status, TodoStatus::InProgress);
    }

    #[test]
    fn reads_closing_and_plain_references_from_commit_messages() {
        assert_eq!(closing_refs("Fixes #todo-3 and tidy up"), vec![3]);
        assert_eq!(closing_refs("closed: #TODO-12"), vec![12]);
        assert_eq!(closing_refs("Work on #todo-4"), Vec::<u32>::new());
        assert_eq!(closing_refs("Resolves #todo-5, fixes #todo-6"), vec![5, 6]);
        assert_eq!(mentions("Work on #todo-4", 4), Some(false));
        assert_eq!(mentions("Fix #todo-4", 4), Some(true));
        assert_eq!(mentions("Fix #todo-40", 4), None);
        assert!(branch_mentions("feature/todo-3-jump", 3));
        assert!(!branch_mentions("feature/todo-31", 3));
        assert!(!branch_mentions("mytodo-3", 3));
    }

    #[test]
    fn commits_close_todos_once_and_respect_creation_time() {
        let mut first = todo("a", "Jump");
        first.number = Some(1);
        first.created_at = "2026-10-01T00:00:00Z".into();
        let mut second = todo("b", "Music");
        second.number = Some(2);
        second.created_at = "2026-10-20T00:00:00Z".into();
        let mut todos = vec![first, second];
        let created_1 = timestamp("2026-10-01T00:00:00Z").unwrap();
        let commits = vec![
            CommitInfo { hash: "new".into(), time: created_1 + 100, author: "me".into(), subject: "Fixes #todo-1".into(), body: String::new() },
            CommitInfo { hash: "old".into(), time: created_1 + 10, author: "me".into(), subject: "fixes #todo-2".into(), body: String::new() },
        ];
        assert_eq!(apply_git_closures(&mut todos, &commits, "2026-10-22T00:00:00Z"), 1);
        assert_eq!(todos[0].status, TodoStatus::Done);
        assert_eq!(todos[0].closed_by.as_ref().unwrap().commit.as_deref(), Some("new"));
        assert_eq!(todos[1].status, TodoStatus::Todo);

        todos[0].status = TodoStatus::Todo;
        assert_eq!(apply_git_closures(&mut todos, &commits, "2026-10-22T00:00:00Z"), 0);
        assert_eq!(todos[0].status, TodoStatus::Todo);
    }

    #[test]
    fn parses_git_log_records() {
        let out = "abc\u{1f}100\u{1f}Ryko\u{1f}Fixes #todo-1\u{1f}body line\u{1e}\ndef\u{1f}50\u{1f}Ryko\u{1f}Init\u{1f}\u{1e}";
        let commits = parse_git_log(out);
        assert_eq!(commits.len(), 2);
        assert_eq!(commits[0].hash, "abc");
        assert_eq!(commits[0].body, "body line");
        assert_eq!(commits[1].time, 50);
    }

    #[test]
    fn scans_project_files_and_skips_ignored_folders() {
        let dir = temp_dir("scan");
        fs::create_dir_all(dir.join("scripts")).unwrap();
        fs::create_dir_all(dir.join("addons/plugin")).unwrap();
        fs::create_dir_all(dir.join(".godot")).unwrap();
        fs::create_dir_all(dir.join("ignored")).unwrap();
        fs::write(dir.join("scripts/player.gd"), "# TODO: jump\n").unwrap();
        fs::write(dir.join("scripts/Enemy.cs"), "// FIXME: aggro\n").unwrap();
        fs::write(dir.join("water.gdshader"), "// TODO foam\n").unwrap();
        fs::write(dir.join("addons/plugin/x.gd"), "# TODO: not mine\n").unwrap();
        fs::write(dir.join(".godot/cache.gd"), "# TODO: cache\n").unwrap();
        fs::write(dir.join("ignored/.gdignore"), "").unwrap();
        fs::write(dir.join("ignored/y.gd"), "# TODO: ignored\n").unwrap();
        fs::write(dir.join("notes.txt"), "# TODO: not code\n").unwrap();
        let mut paths: Vec<String> = scan_project_comments(&dir).into_iter().map(|c| c.path).collect();
        paths.sort();
        assert_eq!(paths, vec!["res://scripts/Enemy.cs", "res://scripts/player.gd", "res://water.gdshader"]);
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn res_paths_cannot_escape_the_project() {
        let root = Path::new("/game");
        assert_eq!(resolve_res_path(root, "res://scenes/main.tscn").unwrap(), root.join("scenes/main.tscn"));
        assert!(resolve_res_path(root, "res://../secret.txt").is_err());
        assert!(resolve_res_path(root, "/etc/passwd").is_err());
        assert!(resolve_res_path(root, "res://").is_err());
    }

    #[test]
    fn editor_arguments_target_the_line_when_supported() {
        let file = Path::new("player.gd");
        assert_eq!(editor_args("code", file, Some(12)), vec![OsString::from("-g"), OsString::from("player.gd:12")]);
        assert_eq!(editor_args("C:/Tools/zed.exe", file, Some(3)), vec![OsString::from("player.gd:3")]);
        assert_eq!(editor_args("rider64", file, Some(7)), vec![OsString::from("--line"), OsString::from("7"), OsString::from("player.gd")]);
        assert_eq!(editor_args("notepad", file, Some(7)), vec![OsString::from("player.gd")]);
        assert_eq!(editor_args("code", file, None), vec![OsString::from("player.gd")]);
    }
}
