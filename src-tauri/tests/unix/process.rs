use super::{parse_unix_process_output, RunningProcess};

#[test]
fn parses_ps_output() {
    assert_eq!(
        parse_unix_process_output("1234 Godot_v4 --path /tmp/game --editor\n"),
        vec![RunningProcess {
            pid: 1234,
            project_path: "/tmp/game".to_string(),
        }]
    );
}

#[test]
fn parses_multiple_processes_and_skips_unrelated_commands() {
    let processes = parse_unix_process_output(
        "101 launchd\n202 Godot --path /Users/test/one --editor\n303 godot-mono --path=/Users/test/two\n",
    );
    assert_eq!(
        processes,
        vec![
            RunningProcess {
                pid: 202,
                project_path: "/Users/test/one".to_string(),
            },
            RunningProcess {
                pid: 303,
                project_path: "/Users/test/two".to_string(),
            },
        ]
    );
}

#[test]
fn parses_quoted_paths() {
    assert_eq!(
        parse_unix_process_output("404 Godot --path \"/Users/test/game with spaces\" --editor\n"),
        vec![RunningProcess {
            pid: 404,
            project_path: "/Users/test/game with spaces".to_string(),
        }]
    );
}
