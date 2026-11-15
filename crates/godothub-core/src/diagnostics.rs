use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, Once, OnceLock};

use regex::{Captures, Regex};

pub const LOG_FILE: &str = "godothub.log";
pub const OLD_LOG_FILE: &str = "godothub.old.log";
const MAX_BYTES: u64 = 512 * 1024;
const MAX_ENTRY_CHARS: usize = 4000;
const MAX_PENDING: usize = 50;

#[derive(Default)]
struct Log {
    dir: Option<PathBuf>,
    home: Option<String>,
    projects: Vec<String>,
    pending: Vec<String>,
    last: Option<String>,
    crash: Option<godothub_launcher::Crash>,
}

fn log() -> &'static Mutex<Log> {
    static LOG: OnceLock<Mutex<Log>> = OnceLock::new();
    LOG.get_or_init(|| {
        Mutex::new(Log {
            home: dirs::home_dir().map(|h| h.to_string_lossy().trim_end_matches(['\\', '/']).to_string()),
            ..Log::default()
        })
    })
}

fn lock() -> std::sync::MutexGuard<'static, Log> {
    log().lock().unwrap_or_else(|poisoned| poisoned.into_inner())
}

pub fn log_dir(data_dir: &Path) -> PathBuf {
    data_dir.join("logs")
}

pub fn init(data_dir: &Path) {
    let dir = log_dir(data_dir);
    let _ = std::fs::create_dir_all(&dir);
    let pending = {
        let mut log = lock();
        log.dir = Some(dir.clone());
        std::mem::take(&mut log.pending)
    };
    for line in pending {
        append(&dir, &line);
    }
}

pub fn set_project_roots(roots: impl IntoIterator<Item = String>) {
    let mut roots: Vec<String> = roots
        .into_iter()
        .map(|r| r.trim_end_matches(['\\', '/']).to_string())
        .filter(|r| r.len() > 3)
        .collect();
    roots.sort_by_key(|r| std::cmp::Reverse(r.len()));
    lock().projects = roots;
}

pub fn record(source: &str, message: &str) {
    let (dir, home, projects) = {
        let log = lock();
        (log.dir.clone(), log.home.clone(), log.projects.clone())
    };
    let mut text = scrub(message.trim(), &projects, home.as_deref());
    if text.chars().count() > MAX_ENTRY_CHARS {
        text = text.chars().take(MAX_ENTRY_CHARS).collect::<String>() + " [cut]";
    }
    let entry = format!("[{source}] {}", text.replace("\r\n", "\n").replace('\n', "\n    "));
    {
        let mut log = lock();
        if log.last.as_deref() == Some(entry.as_str()) {
            return;
        }
        log.last = Some(entry.clone());
    }
    let line = format!("{} {entry}\n", chrono::Local::now().format("%Y-%m-%d %H:%M:%S"));
    match dir {
        Some(dir) => append(&dir, &line),
        None => {
            let mut log = lock();
            if log.pending.len() < MAX_PENDING {
                log.pending.push(line);
            }
        }
    }
}

fn append(dir: &Path, line: &str) {
    let path = dir.join(LOG_FILE);
    let size = std::fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
    if size > 0 && size + line.len() as u64 > MAX_BYTES {
        let _ = std::fs::rename(&path, dir.join(OLD_LOG_FILE));
    }
    if let Ok(mut file) = std::fs::OpenOptions::new().create(true).append(true).open(&path) {
        let _ = file.write_all(line.as_bytes());
    }
}

pub fn tail(max_lines: usize) -> String {
    let Some(dir) = lock().dir.clone() else {
        return String::new();
    };
    tail_in(&dir, max_lines)
}

pub fn tail_in(dir: &Path, max_lines: usize) -> String {
    let read = |name: &str| std::fs::read_to_string(dir.join(name)).unwrap_or_default();
    let text = read(OLD_LOG_FILE) + &read(LOG_FILE);
    let lines: Vec<&str> = text.lines().collect();
    lines[lines.len().saturating_sub(max_lines)..].join("\n")
}

pub fn install_panic_hook() {
    static INSTALL: Once = Once::new();
    INSTALL.call_once(|| {
        let previous = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            let location = info.location().map(|l| format!(" at {}:{}", l.file(), l.line())).unwrap_or_default();
            let payload = info
                .payload()
                .downcast_ref::<&str>()
                .map(|s| s.to_string())
                .or_else(|| info.payload().downcast_ref::<String>().cloned())
                .unwrap_or_else(|| "unknown panic".to_string());
            let thread = std::thread::current().name().unwrap_or("unnamed").to_string();
            record("panic", &format!("thread '{thread}' panicked{location}: {payload}"));
            previous(info);
        }));
    });
}

pub fn describe_crash(crash: &godothub_launcher::Crash) -> String {
    let code = if crash.code < 0 || crash.code > 0xFFFF { format!("{:#010X}", crash.code as u32) } else { crash.code.to_string() };
    let mut text = format!("GodotHub {} closed unexpectedly (exit code {code})", crash.version);
    if let Some(previous) = &crash.rolled_back_to {
        text.push_str(&format!("; the launcher went back to {previous}"));
    }
    text
}

pub fn collect_launcher_crash() {
    let Some((layout, _)) = std::env::current_exe().ok().and_then(|exe| godothub_launcher::Layout::of_app_exe(&exe)) else {
        return;
    };
    if let Ok(Some(crash)) = layout.take_crash() {
        record("launcher", &describe_crash(&crash));
        lock().crash = Some(crash);
    }
}

pub fn take_crash_notice() -> Option<godothub_launcher::Crash> {
    lock().crash.take()
}

struct Rules {
    url_credentials: Regex,
    tokens: Regex,
    auth_header: Regex,
    key_values: Regex,
    gist_urls: Regex,
    gist_ids: Regex,
    hex_ids: Regex,
    emails: Regex,
    paths: Regex,
}

fn rules() -> &'static Rules {
    static RULES: OnceLock<Rules> = OnceLock::new();
    RULES.get_or_init(|| Rules {
        url_credentials: Regex::new(r"(?i)\b([a-z][a-z0-9+.-]*://)[^\s/@]+@").unwrap(),
        tokens: Regex::new(r"\b(?:gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,}|glpat-[A-Za-z0-9_-]{16,}|xox[abprs]-[A-Za-z0-9-]{10,})").unwrap(),
        auth_header: Regex::new(r"(?i)\b(bearer|basic|token)\s+[A-Za-z0-9._~+/=-]{8,}").unwrap(),
        key_values: Regex::new(
            r#"(?i)\b(access_token|refresh_token|token|password|passwd|pwd|secret|client_secret|api[_-]?key|authorization|credential)("?\s*[:=]\s*"?)[^\s"'&,;}]+"#,
        )
        .unwrap(),
        gist_urls: Regex::new(r"(?i)(gist\.github(?:usercontent)?\.com/(?:[A-Za-z0-9-]+/)?)[0-9a-f]{20,40}").unwrap(),
        gist_ids: Regex::new(r#"(?i)\b(gist[_ -]?id|gist)("?\s*[:=]?\s*"?)[0-9a-f]{20,40}\b"#).unwrap(),
        hex_ids: Regex::new(r"\b[0-9a-fA-F]{32}\b").unwrap(),
        emails: Regex::new(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}\b").unwrap(),
        paths: Regex::new(r#"(?:\b[A-Za-z]:[\\/]|\\\\[^\s\\/"'<>|]+[\\/]|~[\\/]|(?:^|[\s"'=(\[])/)[^\s"'<>|*?]*"#).unwrap(),
    })
}

fn last_component(path: &str) -> &str {
    path.trim_end_matches(['\\', '/']).rsplit(['\\', '/']).next().unwrap_or("")
}

fn shorten_path(found: &str) -> String {
    let lead: String = found.chars().take_while(|c| c.is_whitespace() || "\"'=([".contains(*c)).collect();
    let path = &found[lead.len()..];
    let name = last_component(path);
    if name.is_empty() || name.len() + 1 >= path.len() {
        return format!("{lead}<path>");
    }
    let separator = if path.contains('\\') { '\\' } else { '/' };
    format!("{lead}<path>{separator}{name}")
}

fn replace_ignoring_case(text: &str, needle: &str, with: &str) -> String {
    if needle.is_empty() {
        return text.to_string();
    }
    let pattern = Regex::new(&format!("(?i){}", regex::escape(needle))).unwrap();
    pattern.replace_all(text, regex::NoExpand(with)).into_owned()
}

pub fn scrub(text: &str, projects: &[String], home: Option<&str>) -> String {
    let r = rules();
    let mut out = r.url_credentials.replace_all(text, "$1<redacted>@").into_owned();
    out = r.tokens.replace_all(&out, "<token>").into_owned();
    out = r.auth_header.replace_all(&out, "$1 <token>").into_owned();
    out = r.key_values.replace_all(&out, "$1$2<redacted>").into_owned();
    out = r.gist_urls.replace_all(&out, "$1<gist>").into_owned();
    out = r.gist_ids.replace_all(&out, "$1$2<gist>").into_owned();
    out = r.hex_ids.replace_all(&out, "<id>").into_owned();
    out = r.emails.replace_all(&out, "<email>").into_owned();

    let mut kept = Vec::new();
    for (i, root) in projects.iter().enumerate() {
        let marker = format!("\u{1}{i}\u{1}");
        let next = replace_ignoring_case(&out, root, &marker);
        if next != out {
            kept.push((marker, root.clone()));
            out = next;
        }
    }
    if let Some(home) = home.filter(|h| h.len() > 3) {
        out = replace_ignoring_case(&out, home, "~");
    }
    out = r.paths.replace_all(&out, |c: &Captures| shorten_path(&c[0])).into_owned();
    for (marker, root) in kept {
        out = out.replace(&marker, &root);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn clean(text: &str) -> String {
        scrub(text, &["C:\\Users\\Ana\\Games\\Space Shooter".to_string(), "/home/ana/godot/tiles".to_string()], Some("C:\\Users\\Ana"))
    }

    #[test]
    fn tokens_and_credentials_are_removed() {
        let cases = [
            "push failed: https://ana:ghp_abcdefghijklmnopqrstuvwxyz0123@github.com/ana/game.git",
            "token ghp_ABCDEFGHIJKLMNOPQRSTUVWX0123 rejected",
            "github_pat_11ABCDEFG0123456789_abcdefghijklmnop expired",
            "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload.signature",
            "request with access_token=0123456789abcdefSECRET&x=1",
            r#"{"password": "hunter22", "user": "x"}"#,
            "glpat-abcdefghijklmnopqrst failed",
        ];
        for case in cases {
            let out = clean(case);
            for secret in ["ghp_", "github_pat_", "eyJhbGci", "0123456789abcdefSECRET", "hunter22", "glpat-", "ana:"] {
                assert!(!out.contains(secret), "{case} -> {out}");
            }
        }
    }

    #[test]
    fn gist_ids_and_emails_are_removed() {
        let id = "aa5a315d61ae9438b18d8f5d2ec6cd8b";
        for case in [
            format!("GET https://gist.github.com/ana/{id} returned 404"),
            format!("https://gist.githubusercontent.com/ana/{id}/raw/todos.json"),
            format!("sync gist_id: {id} failed"),
            format!("gist {id} is gone"),
            format!("\"gistId\":\"{id}\""),
        ] {
            assert!(!clean(&case).contains(id), "{case}");
        }
        assert!(!clean("author Ana <ana.dev@example.com>").contains("ana.dev@example.com"));
    }

    #[test]
    fn paths_outside_projects_lose_everything_but_the_file_name() {
        let out = clean(r"could not read C:\Users\Ana\AppData\Roaming\Ryko.GodotHub\git_auth.json");
        assert!(!out.contains("AppData") && !out.contains("Ana"), "{out}");
        assert!(out.contains("git_auth.json"), "{out}");
        let out = clean("failed to open /home/ana/.config/Ryko.GodotHub/settings.json: denied");
        assert!(!out.contains("/home/ana") && !out.contains(".config"), "{out}");
        assert!(out.contains("settings.json: denied"), "{out}");
        let out = clean(r"missing D:\Tools\Godot\Godot_v4.3-stable_win64.exe");
        assert!(!out.contains("Tools"), "{out}");
        assert!(out.contains("Godot_v4.3-stable_win64.exe"), "{out}");
    }

    #[test]
    fn paths_inside_projects_are_kept() {
        let out = clean(r"parse error in C:\Users\Ana\Games\Space Shooter\scenes\main.tscn line 4");
        assert!(out.contains(r"C:\Users\Ana\Games\Space Shooter\scenes\main.tscn"), "{out}");
        let out = clean("git status failed in /home/ana/godot/tiles/addons");
        assert!(out.contains("/home/ana/godot/tiles/addons"), "{out}");
    }

    #[test]
    fn plain_text_and_urls_survive() {
        let text = "Download failed: HTTP 503 from https://github.com/godotengine/godot/releases (attempt 2/3)";
        assert_eq!(clean(text), text);
        assert_eq!(clean("commit 9fceb02d0ae598e95dc970b74767f19372d61af8 not found"), "commit 9fceb02d0ae598e95dc970b74767f19372d61af8 not found");
    }

    #[test]
    fn crash_codes_read_like_windows_status_codes() {
        let crash = godothub_launcher::Crash { version: "1.6.0".into(), code: -1073741819, rolled_back_to: Some("1.5.9".into()) };
        assert_eq!(describe_crash(&crash), "GodotHub 1.6.0 closed unexpectedly (exit code 0xC0000005); the launcher went back to 1.5.9");
        let crash = godothub_launcher::Crash { version: "1.6.0".into(), code: 70, rolled_back_to: None };
        assert_eq!(describe_crash(&crash), "GodotHub 1.6.0 closed unexpectedly (exit code 70)");
    }

    #[test]
    fn the_log_rotates_and_the_tail_spans_both_files() {
        let dir = std::env::temp_dir().join(format!("godothub-diagnostics-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let line = format!("{}\n", "x".repeat(1000));
        for _ in 0..600 {
            append(&dir, &line);
        }
        append(&dir, "last line\n");
        let current = std::fs::metadata(dir.join(LOG_FILE)).unwrap().len();
        let old = std::fs::metadata(dir.join(OLD_LOG_FILE)).unwrap().len();
        assert!(current <= MAX_BYTES && old <= MAX_BYTES, "{current} {old}");
        let tail = tail_in(&dir, 3);
        assert_eq!(tail.lines().count(), 3);
        assert!(tail.ends_with("last line"));
        let _ = std::fs::remove_dir_all(&dir);
    }
}
