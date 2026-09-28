use super::{normalize_line, read_log_tail, split_lines, LogTail, MAX_LINES, MAX_LINE_BYTES};
use std::fs;
use std::io::Write;
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

fn append(path: &Path, text: &str) {
    let mut file = fs::OpenOptions::new()
        .append(true)
        .open(path)
        .expect("failed to open log");
    file.write_all(text.as_bytes()).expect("failed to append");
}

#[test]
fn console_line_keeps_only_the_last_progress_rewrite() {
    assert_eq!(
        normalize_line(b"Loading 10%\rLoading 40%\rLoading 100%\r"),
        "Loading 100%"
    );
    assert_eq!(normalize_line(b"plain line\r\n"), "plain line");
}

#[test]
fn console_line_truncates_on_a_character_boundary() {
    let long = "é".repeat(MAX_LINE_BYTES);
    let line = normalize_line(long.as_bytes());
    assert!(line.ends_with('…'));
    assert!(line.len() <= MAX_LINE_BYTES + '…'.len_utf8());
    assert!(line.is_char_boundary(line.len() - '…'.len_utf8()));
}

#[test]
fn console_split_lines_handles_a_partial_trailing_line() {
    let bytes = b"one\ntwo\nthree";
    assert_eq!(split_lines(bytes, false), vec!["one", "two"]);
    assert_eq!(split_lines(bytes, true), vec!["one", "two", "three"]);
}

#[test]
fn console_restore_is_empty_without_a_log() {
    let dir = temp_dir("console-missing");
    let (lines, offset) = read_log_tail(&dir.join("nope.log"));
    assert!(lines.is_empty());
    assert_eq!(offset, 0);
}

#[test]
fn console_restore_reads_the_tail_and_skips_the_partial_first_line() {
    let dir = temp_dir("console-restore");
    let path = dir.join("run.log");
    let padding = "x".repeat(80);
    let mut file = fs::File::create(&path).expect("failed to create log");
    let total = 20_000;
    for index in 0..total {
        writeln!(file, "line-{index:05}-{padding}").expect("failed to write");
    }
    drop(file);

    let (lines, offset) = read_log_tail(&path);
    let len = fs::metadata(&path).expect("missing metadata").len();
    assert_eq!(offset, len);
    assert_eq!(lines.len(), MAX_LINES);
    assert!(lines
        .iter()
        .all(|line| line.starts_with("line-") && line.ends_with(&padding)));
    assert_eq!(
        lines.last().expect("no lines"),
        &format!("line-{:05}-{padding}", total - 1)
    );
}

#[test]
fn console_tail_reads_only_what_was_appended() {
    let dir = temp_dir("console-tail");
    let path = dir.join("run.log");
    fs::write(&path, "first\n").expect("failed to seed log");

    let mut tail = LogTail::new(path.clone(), 0);
    assert_eq!(tail.read_new_lines(), vec!["first"]);
    assert!(tail.read_new_lines().is_empty());

    append(&path, "incomplete");
    assert!(tail.read_new_lines().is_empty());
    append(&path, "-done\nsecond\n");
    assert_eq!(tail.read_new_lines(), vec!["incomplete-done", "second"]);

    append(&path, "progress 10%\rprogress 55%\rprogress 100%\n");
    assert_eq!(tail.read_new_lines(), vec!["progress 100%"]);

    fs::write(&path, "fresh start\n").expect("failed to truncate log");
    assert_eq!(tail.read_new_lines(), vec!["fresh start"]);
}

#[test]
fn console_tail_resumes_from_the_offset_it_was_handed() {
    let dir = temp_dir("console-offset");
    let path = dir.join("run.log");
    fs::write(&path, "old line\n").expect("failed to seed log");
    let len = fs::metadata(&path).expect("missing metadata").len();

    let mut tail = LogTail::new(path.clone(), len);
    assert!(tail.read_new_lines().is_empty());
    append(&path, "new line\n");
    assert_eq!(tail.read_new_lines(), vec!["new line"]);
}
