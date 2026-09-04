use super::{parse_windows_process_output, RunningProcess};

#[test]
fn parses_tab_output() {
    assert_eq!(
        parse_windows_process_output(
            "1234\tGodot_v4.exe --path \"D:\\Game Projects\\Demo\" --editor\r\n"
        ),
        vec![RunningProcess {
            pid: 1234,
            project_path: "D:\\Game Projects\\Demo".to_string(),
        }]
    );
}

#[test]
fn parses_wmic_list_output_in_either_order() {
    let processes = parse_windows_process_output(
        "CommandLine=Godot_v4.exe --path=\"D:\\Demo\"\r\nProcessId=4321\r\n\r\n",
    );
    assert_eq!(processes[0].pid, 4321);
    assert_eq!(processes[0].project_path, "D:\\Demo");
}

#[test]
fn skips_malformed_wmic_records() {
    let processes = parse_windows_process_output(
        "CommandLine=Godot --path D:\\Valid\r\nProcessId=700\r\n\r\nProcessId=not-a-pid\r\nCommandLine=Godot --path D:\\Ignored\r\n",
    );
    assert_eq!(
        processes,
        vec![RunningProcess {
            pid: 700,
            project_path: "D:\\Valid".to_string(),
        }]
    );
}
